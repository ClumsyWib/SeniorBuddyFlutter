import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/refresh_mixin.dart';
import '../utils/role_helper.dart';
import 'medicine_detail_screen.dart';
import 'add_medicine_screen.dart';

class MedicinesScreen extends StatefulWidget {
  final int? seniorId;
  // userRole controls whether Add/Edit buttons are visible
  final String userRole;
  const MedicinesScreen({Key? key, this.seniorId, this.userRole = kRoleFamily}) : super(key: key);

  @override
  State<MedicinesScreen> createState() => _MedicinesScreenState();
}

class _MedicinesScreenState extends State<MedicinesScreen> with PeriodicRefreshMixin {
  final ApiService _apiService = ApiService();
  List<dynamic> _medicines = [];
  bool _isLoading = true;

  @override
  Future<void> onRefresh() => _loadMedicines();

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  Future<void> _loadMedicines({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoading = true);

    final result = await _apiService.getMedicines(seniorId: widget.seniorId);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success']) {
          _medicines = result['data'];
        }
      });
    }
  }

  Future<void> _openAddMedicine() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => AddMedicineScreen(seniorId: widget.seniorId)),
    );
    if (result == true && mounted) _loadMedicines(showLoading: false);
  }

  Future<void> _triggerSOS(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Trigger Emergency?'),
        content: const Text('This will alert all volunteers to assist you. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('YES, ALERT VOLUNTEERS', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await _apiService.triggerVolunteerEmergency(widget.seniorId);
      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Emergency Alert Sent!'), backgroundColor: Colors.red));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${result['error']}')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Medicines', style: TextStyle(fontSize: 24)),
        backgroundColor: const Color(0xFFE53935),
        actions: widget.userRole == kRoleSenior 
          ? [
              IconButton(
                icon: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
                onPressed: () => _triggerSOS(context),
                tooltip: 'SOS EMERGENCY',
              ),
            ]
          : null,
      ),
      // Only Family Members can add medicines
      floatingActionButton: canFamilyWrite(widget.userRole)
          ? FloatingActionButton.extended(
              onPressed: _openAddMedicine,
              backgroundColor: const Color(0xFFE53935),
              icon: const Icon(Icons.add, size: 28),
              label: const Text('Add medicine', style: TextStyle(fontSize: 18)),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _medicines.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medication_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            const Text(
              'No medicines found',
              style: TextStyle(fontSize: 24, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            const Text(
              'Add medicines in Django admin',
              style: TextStyle(fontSize: 18, color: Colors.black38),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadMedicines,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _medicines.length + 1,
          itemBuilder: (context, index) {
            if (index == _medicines.length) {
              return Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                child: Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your medicines are managed by your care team. Changes in Django admin appear here. Pull down to refresh.',
                            style: TextStyle(fontSize: 14, color: Colors.blue.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return _buildMedicineCard(_medicines[index] as Map<String, dynamic>);
          },
        ),
      ),
    );
  }

  Widget _buildMedicineCard(Map<String, dynamic> medicine) {
    final isActive = medicine['is_active'] ?? false;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MedicineDetailScreen(medicine: medicine),
            ),
          );
          if (mounted) _loadMedicines(showLoading: false);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.medication, color: Color(0xFFE53935), size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicine['medicine_name'] ?? 'Medicine',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        medicine['dosage'] ?? '',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive ? 'ACTIVE' : 'INACTIVE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 30, thickness: 1),
            _buildInfoRow(Icons.schedule, 'Frequency: ${medicine['frequency'] ?? 'N/A'}'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.access_time, 'Time: ${medicine['time_of_day'] ?? 'N/A'}'),
            if (medicine['instructions'] != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(Icons.info, medicine['instructions']),
            ],
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 18, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}