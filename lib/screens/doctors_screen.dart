import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/role_helper.dart';
import 'add_doctor_screen.dart';
import 'doctor_detail_screen.dart';

class DoctorsScreen extends StatefulWidget {
  final int seniorId;
  // userRole controls whether the Add Doctor button is shown
  final String userRole;
  const DoctorsScreen({Key? key, required this.seniorId, this.userRole = kRoleFamily}) : super(key: key);

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _doctors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    setState(() => _isLoading = true);
    final result = await _apiService.getDoctors(seniorId: widget.seniorId);
    if (mounted) {
      setState(() {
        if (result['success']) {
          _doctors = result['data'];
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Doctors', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2196F3),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDoctors,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _doctors.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _doctors.length,
                  itemBuilder: (context, index) {
                    final doctor = _doctors[index];
                    return _buildDoctorCard(doctor);
                  },
                ),
      // Only Family Members can add doctors
      floatingActionButton: canFamilyWrite(widget.userRole)
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddDoctorScreen(seniorId: widget.seniorId),
                  ),
                );
                if (result == true) _loadDoctors();
              },
              label: const Text('Add Doctor'),
              icon: const Icon(Icons.add),
              backgroundColor: const Color(0xFF2196F3),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.medical_services_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No doctors added yet',
            style: TextStyle(fontSize: 20, color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text('Keep track of your medical professionals here.'),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(dynamic doctor) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DoctorDetailScreen(doctor: doctor),
          ),
        ),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  radius: 30,
                  child: const Icon(Icons.person, size: 35, color: Color(0xFF2196F3)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dr. ${doctor['name']}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        doctor['specialty'] ?? 'General Practitioner',
                        style: TextStyle(fontSize: 16, color: Colors.blue[700], fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.phone, doctor['phone'] ?? 'No phone'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.location_on, doctor['clinic_address'] ?? 'No address'),
            if (doctor['notes'] != null && doctor['notes'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.note, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        doctor['notes'],
                        style: TextStyle(color: Colors.grey[800], fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ));
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
