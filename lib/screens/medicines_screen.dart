import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/emergency_helper.dart';

import '../utils/refresh_mixin.dart';
import '../utils/role_helper.dart';
import 'medicine_detail_screen.dart';
import 'add_medicine_screen.dart';
import '../services/notification_service.dart';

class MedicinesScreen extends StatefulWidget {
  final int? seniorId;
  // userRole controls whether Add/Edit buttons are visible
  final String userRole;
  const MedicinesScreen({Key? key, this.seniorId, this.userRole = kRoleFamily})
      : super(key: key);

  @override
  State<MedicinesScreen> createState() => _MedicinesScreenState();
}

class _MedicinesScreenState extends State<MedicinesScreen>
    with PeriodicRefreshMixin {
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
          
          // 🔥 Automatically schedule local reminders for the senior
          if (widget.userRole == kRoleSenior) {
            NotificationService().scheduleLocalMedicineReminders(_medicines);
          }

          // Sort medicines by Date and Time of Day
          _medicines.sort((a, b) {
            // 1. Sort by start_date ASC
            final dateA = (a['start_date'] ?? '').toString();
            final dateB = (b['start_date'] ?? '').toString();
            int dateComp = dateA.compareTo(dateB);
            if (dateComp != 0) return dateComp;

            // 2. Sort by Time of Day
            final order = ['morning', 'noon', 'afternoon', 'evening', 'night'];
            final timeA = (a['time_of_day'] ?? '').toString().toLowerCase();
            final timeB = (b['time_of_day'] ?? '').toString().toLowerCase();
            
            final idxA = order.indexOf(timeA);
            final idxB = order.indexOf(timeB);
            
            if (idxA != -1 && idxB != -1) return idxA.compareTo(idxB);
            if (idxA != -1) return -1;
            if (idxB != -1) return 1;
            return timeA.compareTo(timeB);
          });
        }
      });
    }
  }

  Future<void> _openAddMedicine() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (context) => AddMedicineScreen(seniorId: widget.seniorId)),
    );
    if (result == true && mounted) _loadMedicines(showLoading: false);
  }

  Future<void> _triggerSOS(BuildContext context) async {
    await EmergencyHelper.triggerSOS(context, widget.seniorId);
  }

  Future<void> _openEditMedicine(Map<String, dynamic> medicine) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddMedicineScreen(
          seniorId: widget.seniorId,
          medicine: medicine,
        ),
      ),
    );
    if (result == true && mounted) _loadMedicines(showLoading: false);
  }

  Future<void> _deleteMedicine(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Medicine'),
        content: const Text('Are you sure you want to delete this medicine?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await _apiService.deleteMedicine(id);
      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Medicine deleted')),
          );
          _loadMedicines(showLoading: false);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to delete: ${result['error']}'),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Medicines', style: TextStyle(fontSize: 24)),
        backgroundColor: Theme.of(context).primaryColor,
        actions: widget.userRole == kRoleSenior
            ? [
                IconButton(
                  icon: const Icon(Icons.warning_amber_rounded,
                      color: Colors.white, size: 28),
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
              backgroundColor: Theme.of(context).primaryColor,
              icon: const Icon(Icons.add, size: 28),
              label: const Text('Add medicine', style: TextStyle(fontSize: 18)),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _medicines.isEmpty
              ? RefreshIndicator(
                  onRefresh: _loadMedicines,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.7,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.medication_outlined,
                              size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 20),
                          const Text(
                            'No medicines found',
                            style: TextStyle(fontSize: 24, color: Colors.black54),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Medicines are managed by your care team',
                            style: TextStyle(fontSize: 18, color: Colors.black38),
                          ),
                          const SizedBox(height: 48),
                        ],
                      ),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadMedicines,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _medicines.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _medicines.length) {
                        final Color roleColor = Theme.of(context).primaryColor;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 24),
                          child: Card(
                            color: roleColor.withOpacity(0.08),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                    color: roleColor.withOpacity(0.12))),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      color: roleColor, size: 28),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Your medicines are managed by your care team. Changes in Django admin appear here. Pull down to refresh.',
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: roleColor.withOpacity(0.8),
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                      return _buildMedicineCard(
                          _medicines[index] as Map<String, dynamic>);
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
              builder: (context) => MedicineDetailScreen(
                medicine: medicine,
                userRole: widget.userRole,
              ),
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
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.medication,
                            color: Color(0xFFE53935), size: 32),
                      ),
                      const SizedBox(width: 16),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              medicine['medicine_name'] ?? 'Medicine',
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              medicine['dosage'] ?? '',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.green.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.2),
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
                        if (isActive && medicine['status'] != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(medicine['status'].toString()).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              medicine['status'].toString().toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(medicine['status'].toString()),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (canFamilyWrite(widget.userRole)) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit_outlined, color: Theme.of(context).primaryColor),
                      onPressed: () => _openEditMedicine(medicine),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _deleteMedicine(medicine['id']),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
              const Divider(height: 16, thickness: 1),
              _buildInfoRow(Icons.schedule,
                  'Frequency: ${medicine['frequency'] ?? 'N/A'}'),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.access_time,
                  'Time: ${_formatTo12Hour(medicine['time_of_day'])}'),
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

  String _formatTo12Hour(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return 'N/A';
    try {
      // Handles HH:mm:ss or HH:mm
      final parts = timeStr.split(':');
      if (parts.length < 2) return timeStr;
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      final period = hour >= 12 ? 'PM' : 'AM';
      hour = hour % 12;
      if (hour == 0) hour = 12;
      final minuteStr = minute.toString().padLeft(2, '0');
      return '$hour:$minuteStr $period';
    } catch (e) {
      return timeStr;
    }
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'taken': return Colors.green;
      case 'missed': return Colors.orange;
      default: return Colors.blue;
    }
  }
}
