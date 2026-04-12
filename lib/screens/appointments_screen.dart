import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/emergency_helper.dart';

import '../utils/refresh_mixin.dart';
import '../utils/role_helper.dart';
import 'create_appointment_screen.dart';
import 'appointment_detail_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  final int? seniorId;
  // userRole controls whether Add/Edit buttons are visible
  final String userRole;
  const AppointmentsScreen(
      {Key? key, this.seniorId, this.userRole = kRoleFamily})
      : super(key: key);

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with PeriodicRefreshMixin {
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
          // Sort appointments by date and time
          _appointments.sort((a, b) {
            int dateComp = (a['appointment_date'] ?? '').compareTo(b['appointment_date'] ?? '');
            if (dateComp != 0) return dateComp;
            return (a['appointment_time'] ?? '').compareTo(b['appointment_time'] ?? '');
          });
        }
      });
    }
  }

  Future<void> _triggerSOS(BuildContext context) async {
    await EmergencyHelper.triggerSOS(context, widget.seniorId);
  }

  Future<void> _editAppointment(Map<String, dynamic> appointment) async {
    final seniorId = widget.seniorId ?? await _apiService.getUserId();
    if (seniorId == null) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateAppointmentScreen(
          seniorId: seniorId,
          appointment: appointment,
        ),
      ),
    );

    if (result == true) {
      _loadAppointments(showLoading: false);
    }
  }

  Future<void> _deleteAppointment(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Appointment'),
        content: const Text('Are you sure you want to delete this appointment?'),
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
      final result = await _apiService.deleteAppointment(id);
      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Appointment deleted')),
          );
          _loadAppointments(showLoading: false);
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
        title: const Text('My Appointments', style: TextStyle(fontSize: 24)),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _appointments.isEmpty
              ? RefreshIndicator(
                  onRefresh: _loadAppointments,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.7,
                      alignment: Alignment.center,
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
                              label: const Text('Create Appointment',
                                  style: TextStyle(fontSize: 20)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 20),
                              ),
                            ),
                          const SizedBox(height: 48),
                        ],
                      ),
                    ),
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
              backgroundColor: Theme.of(context).primaryColor,
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
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AppointmentDetailScreen(
                  appointment: appointment,
                  userRole: widget.userRole,
                ),
              ),
            );
            if (mounted) _loadAppointments(showLoading: false);
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
                          color: Theme.of(context).primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.event,
                            color: Theme.of(context).primaryColor, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appointment['title'] ?? 'Appointment',
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatAppointmentType(
                                  appointment['appointment_type']),
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _buildStatusChip(appointment['status']),
                  ),
                ],
              ),
              const Divider(height: 30, thickness: 1),
              _buildInfoRow(
                  Icons.calendar_today, '${appointment['appointment_date']}'),
              const SizedBox(height: 12),
              _buildInfoRow(
                  Icons.access_time, _formatTo12Hour(appointment['appointment_time'])),
              if (appointment['location'] != null) ...[
                const SizedBox(height: 12),
                _buildInfoRow(Icons.location_on, appointment['location']),
              ],
              if (appointment['doctor_name'] != null) ...[
                const SizedBox(height: 12),
                _buildInfoRow(Icons.person, appointment['doctor_name']),
              ],
              if (canFamilyWrite(widget.userRole)) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                      onPressed: () => _editAppointment(appointment),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _deleteAppointment(appointment['id']),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
              ],
            ),
          ),
        ));
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
        color = Theme.of(context).primaryColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusText.toUpperCase(),
        style:
            TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  String _formatAppointmentType(String? type) {
    if (type == null) return 'General';
    return type
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
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
