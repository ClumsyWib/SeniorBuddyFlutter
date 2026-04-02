import 'package:flutter/material.dart';

class AppointmentDetailScreen extends StatelessWidget {
  final Map<String, dynamic> appointment;

  const AppointmentDetailScreen({Key? key, required this.appointment})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String title = appointment['title'] ?? 'Appointment';
    final String date = appointment['appointment_date'] ?? 'N/A';
    final String time = appointment['appointment_time'] ?? 'N/A';
    final String location = appointment['location'] ?? 'Not specified';
    final String doctor = appointment['doctor_name'] ?? 'Not specified';
    final String type = (appointment['appointment_type'] ?? 'General').toString();
    final String status = (appointment['status'] ?? 'Scheduled').toString();
    final String notes = appointment['notes'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        backgroundColor: _getStatusColor(status),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _getStatusColor(status),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.calendar_today, size: 60, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Cards
                  _buildSectionTitle('Basic Info'),
                  _buildDetailCard([
                    _buildDetailRow(Icons.category, 'Type', type),
                    _buildDetailRow(Icons.calendar_month, 'Date', date),
                    _buildDetailRow(Icons.access_time, 'Time', time),
                  ]),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('Location & Contact'),
                  _buildDetailCard([
                    _buildDetailRow(Icons.location_on, 'Location', location),
                    _buildDetailRow(Icons.person, 'Doctor', doctor),
                  ]),

                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSectionTitle('Notes'),
                    _buildDetailCard([
                      _buildDetailRow(Icons.notes, 'Additional Info', notes),
                    ]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  Widget _buildDetailCard(List<Widget> children) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28, color: Colors.blue),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      case 'scheduled': return Colors.blue;
      default: return Colors.orange;
    }
  }
}
