import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AppointmentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> appointment;
  final String userRole;

  const AppointmentDetailScreen({
    Key? key,
    required this.appointment,
    this.userRole = 'senior', // Default to senior for safety
  }) : super(key: key);

  @override
  State<AppointmentDetailScreen> createState() => _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  final ApiService _apiService = ApiService();
  late Map<String, dynamic> _currentAppointment;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _currentAppointment = Map<String, dynamic>.from(widget.appointment);
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _isUpdating = true);
    final result = await _apiService.updateAppointmentStatus(
      _currentAppointment['id'],
      status,
    );

    if (mounted) {
      setState(() => _isUpdating = false);
      if (result['success']) {
        setState(() {
          _currentAppointment = result['data'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Appointment marked as $status')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update status')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = _currentAppointment['title'] ?? 'Appointment';
    final String date = _currentAppointment['appointment_date'] ?? 'N/A';
    final String time = _currentAppointment['appointment_time'] ?? 'N/A';
    final String location = _currentAppointment['location'] ?? 'Not specified';
    final String doctor = _currentAppointment['doctor_name'] ?? 'Not specified';
    final String type =
        (_currentAppointment['appointment_type'] ?? 'General').toString();
    final String status = (_currentAppointment['status'] ?? 'Scheduled').toString();
    final String notes = _currentAppointment['notes'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        backgroundColor: status.toLowerCase() == 'scheduled' || status.toLowerCase() == 'confirmed'
            ? Theme.of(context).primaryColor
            : _getStatusColor(status),
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
                color: status.toLowerCase() == 'scheduled' || status.toLowerCase() == 'confirmed'
                    ? Theme.of(context).primaryColor
                    : _getStatusColor(status),
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
                    child: const Icon(Icons.calendar_today,
                        size: 60, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
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
                  // Action Buttons
                  if (widget.userRole == 'senior') ...[
                    if (_isUpdating)
                      const Center(child: CircularProgressIndicator())
                    else if (status.toLowerCase() == 'scheduled' || status.toLowerCase() == 'confirmed')
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width > 400 ? (MediaQuery.of(context).size.width - 64) / 2 : double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _updateStatus('completed'),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Complete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width > 400 ? (MediaQuery.of(context).size.width - 64) / 2 : double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _updateStatus('cancelled'),
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Cancel'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                if (status.toLowerCase() == 'scheduled' || status.toLowerCase() == 'confirmed')
                  const SizedBox(height: 24),
                  ],

                  // Info Cards
                  _buildSectionTitle('Basic Info'),
                  _buildDetailCard([
                    _buildDetailRow(Icons.category, 'Type', type),
                    _buildDetailRow(Icons.calendar_month, 'Date', date),
                    _buildDetailRow(Icons.access_time, 'Time', _formatTo12Hour(time)),
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
        style: const TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
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
          Icon(icon, size: 28, color: Theme.of(context).primaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'scheduled':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  String _formatTo12Hour(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return 'N/A';
    try {
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
}
