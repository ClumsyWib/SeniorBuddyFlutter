import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/refresh_mixin.dart';
import '../utils/role_helper.dart';
import 'create_appointment_screen.dart';
import 'appointment_detail_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  final int? seniorId;
  // userRole controls whether Add/Edit buttons are visible
  final String userRole;
  const AppointmentsScreen({Key? key, this.seniorId, this.userRole = kRoleFamily}) : super(key: key);

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> with PeriodicRefreshMixin {
  final ApiService _apiService = ApiService();
  List<dynamic> _appointments = [];
  bool _isLoading = true;

  @override
  Future<void> onRefresh() => _loadAppointments();

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoading = true);

    final result = await _apiService.getAppointments(seniorId: widget.seniorId);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success']) {
          _appointments = result['data'];
        }
      });
    }
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
        title: const Text('My Appointments', style: TextStyle(fontSize: 24)),
        backgroundColor: const Color(0xFF4CAF50),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _appointments.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            const Text(
              'No appointments yet',
              style: TextStyle(fontSize: 24, color: Colors.black54),
            ),
            const SizedBox(height: 30),
            // Only Family Members can create appointments
            if (canFamilyWrite(widget.userRole))
              ElevatedButton.icon(
                onPressed: _createAppointment,
                icon: const Icon(Icons.add, size: 28),
                label: const Text('Create Appointment', style: TextStyle(fontSize: 20)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                ),
              ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadAppointments,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _appointments.length,
          itemBuilder: (context, index) {
            final appointment = _appointments[index];
            return _buildAppointmentCard(appointment);
          },
        ),
      ),
      // Only Family Members can create appointments
      floatingActionButton: canFamilyWrite(widget.userRole)
          ? FloatingActionButton.extended(
              onPressed: _createAppointment,
              backgroundColor: const Color(0xFF4CAF50),
              icon: const Icon(Icons.add, size: 28),
              label: const Text('New', style: TextStyle(fontSize: 18)),
            )
          : null,
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AppointmentDetailScreen(appointment: appointment),
            ),
          );
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
                    color: const Color(0xFF4CAF50).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.event, color: Color(0xFF4CAF50), size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment['title'] ?? 'Appointment',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatAppointmentType(appointment['appointment_type']),
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 30, thickness: 1),
            _buildInfoRow(Icons.calendar_today, '${appointment['appointment_date']}'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.access_time, '${appointment['appointment_time']}'),
            if (appointment['location'] != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(Icons.location_on, appointment['location']),
            ],
            if (appointment['doctor_name'] != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(Icons.person, appointment['doctor_name']),
            ],
            const SizedBox(height: 16),
            _buildStatusChip(appointment['status']),
          ],
        ),
      ),
    ));
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
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

  Widget _buildStatusChip(String? status) {
    final statusText = status ?? 'scheduled';
    Color color;

    switch (statusText.toLowerCase()) {
      case 'completed':
        color = Colors.green;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusText.toUpperCase(),
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  String _formatAppointmentType(String? type) {
    if (type == null) return 'General';
    return type.replaceAll('_', ' ').split(' ').map((word) =>
    word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  Future<void> _createAppointment() async {
    final userId = widget.seniorId ?? await _apiService.getUserId();

    if (userId == null) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateAppointmentScreen(seniorId: userId),
      ),
    );

    if (result == true) {
      _loadAppointments(showLoading: false);
    }
  }
}