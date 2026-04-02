import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/role_helper.dart';
import 'medicines_screen.dart';
import 'appointments_screen.dart';
import 'health_records_screen.dart';
import 'emergency_contacts_screen.dart';
import 'my_caretaker_screen.dart';
import 'doctors_screen.dart';
import 'vitals_tracker_screen.dart';
import 'daily_activity_screen.dart';
import 'daily_activity_detail_screen.dart';
import 'vital_record_detail_screen.dart';
import 'doctor_detail_screen.dart';
import 'care_assignment_detail_screen.dart';
import 'senior_connection_details_screen.dart';
import 'caretaker_selection_screen.dart';
import 'edit_senior_screen.dart';

class SeniorDetailScreen extends StatefulWidget {
  final Map<String, dynamic> senior;
  final String userRole;

  const SeniorDetailScreen({
    Key? key,
    required this.senior,
    this.userRole = kRoleFamily,
  }) : super(key: key);

  @override
  State<SeniorDetailScreen> createState() => _SeniorDetailScreenState();
}

class _SeniorDetailScreenState extends State<SeniorDetailScreen> {
  late String _currentPairCode;

  @override
  void initState() {
    super.initState();
    _currentPairCode = widget.senior['pair_code'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final Color headerColor = widget.userRole == kRoleCaretaker
        ? const Color(0xFF2196F3)
        : const Color(0xFF4CAF50);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.senior['name'] ?? 'Senior Details',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: headerColor,
        actions: [
          if (widget.userRole == kRoleFamily)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditSeniorScreen(senior: widget.senior),
                  ),
                );
                if (result == true) {
                  // Refresh data if needed, or just pop and reload parent
                  if (mounted) Navigator.pop(context, true);
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: headerColor,
                  backgroundImage: widget.senior['photo'] != null
                      ? NetworkImage('${widget.senior['photo']}?v=${DateTime.now().millisecondsSinceEpoch}')
                      : null,
                  child: widget.senior['photo'] == null
                      ? const Icon(Icons.person, size: 50, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.senior['name'] ?? 'Unknown',
                        style: const TextStyle(
                            fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Age: ${widget.senior['age'] ?? '-'} | ${widget.senior['gender'] ?? ''}',
                        style: const TextStyle(
                            fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            /// MEDICAL INFO
            const Text('Medical Info',
                style:
                TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow('Conditions',
                        widget.senior['medical_conditions'] ?? 'None'),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                        'Allergies', widget.senior['allergies'] ?? 'None'),
                    const SizedBox(height: 8),
                    _buildInfoRow('Mobility',
                        widget.senior['mobility_status'] ?? 'Unknown'),
                    const SizedBox(height: 8),
                    _buildInfoRow('Care Level',
                        widget.senior['care_level'] ?? 'Unknown'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            /// CONNECTION
            if (widget.userRole == kRoleFamily) ...[
              const Text('Connection',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              _buildActionCard(
                context,
                title: 'Connection Details (QR/Code)',
                icon: Icons.qr_code,
                color: Colors.green,
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SeniorConnectionDetailsScreen(
                        senior: {
                          ...widget.senior,
                          'pair_code': _currentPairCode,
                        },
                      ),
                    ),
                  );

                  if (result != null && result is String) {
                    setState(() {
                      _currentPairCode = result;
                    });
                  }
                },
              ),

              const SizedBox(height: 20),
            ],

            /// MANAGEMENT
            const Text('Management',
                style:
                TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            _buildActionCard(
              context,
              title: 'Medicines',
              icon: Icons.medication,
              color: Colors.redAccent,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MedicinesScreen(
                    seniorId: widget.senior['id'],
                    userRole: widget.userRole,
                  ),
                ),
              ),
            ),

            _buildActionCard(
              context,
              title: 'Appointments',
              icon: Icons.calendar_today,
              color: Colors.blueAccent,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AppointmentsScreen(
                    seniorId: widget.senior['id'],
                    userRole: widget.userRole,
                  ),
                ),
              ),
            ),

            _buildActionCard(
              context,
              title: 'Daily Activity',
              icon: Icons.assignment_turned_in,
              color: Colors.blue,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DailyActivityScreen(
                    seniorId: widget.senior['id'],
                    seniorName:
                    widget.senior['name'] ?? 'Senior',
                    userRole: widget.userRole,
                  ),
                ),
              ),
            ),

            if (canFamilyWrite(widget.userRole))
              _buildActionCard(
                context,
                title: 'Health Records',
                icon: Icons.history,
                color: Colors.pinkAccent,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HealthRecordsScreen(
                      onDataChanged: () {},
                      seniorId: widget.senior['id'],
                      userRole: widget.userRole,
                    ),
                  ),
                ),
              ),

            _buildActionCard(
              context,
              title: 'Vital Records',
              icon: Icons.monitor_heart,
              color: Colors.red,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VitalsTrackerScreen(
                    seniorId: widget.senior['id'],
                    userRole: widget.userRole,
                  ),
                ),
              ),
            ),

            _buildActionCard(
              context,
              title: 'My Doctors',
              icon: Icons.medical_services,
              color: Colors.blue,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DoctorsScreen(
                    seniorId: widget.senior['id'],
                    userRole: widget.userRole,
                  ),
                ),
              ),
            ),

            _buildActionCard(
              context,
              title: 'Emergency Contacts',
              icon: Icons.contact_emergency,
              color: Colors.orange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EmergencyContactsScreen(
                    onDataChanged: () {},
                    seniorId: widget.senior['id'],
                    userRole: widget.userRole,
                  ),
                ),
              ),
            ),

            if (widget.userRole != kRoleCaretaker)
              _buildActionCard(
                context,
                title: 'Care Assignment',
                icon: Icons.health_and_safety,
                color: Colors.teal,
                onTap: () async {
                  final result = await ApiService().getCareAssignments();
                  if (result['success']) {
                    final assignments = result['data'] as List;
                    final assignment = assignments.firstWhere(
                      (a) => a['senior'] == widget.senior['id'],
                      orElse: () => null,
                    );

                    if (assignment != null) {
                      final caretakerInfo = await ApiService()
                          .getList('care-assignments/my_caretaker/?senior=${widget.senior['id']}');
                      if (caretakerInfo['success']) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CareAssignmentDetailScreen(
                              assignment: caretakerInfo['raw'],
                            ),
                          ),
                        );
                      } else {
                        // If my_caretaker fails but assignment exists, it's a fallback to selection
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CaretakerSelectionScreen(seniorId: widget.senior['id']),
                          ),
                        );
                      }
                    } else {
                      // No assignment found, go to selection screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CaretakerSelectionScreen(seniorId: widget.senior['id']),
                        ),
                      );
                    }
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.grey)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  Widget _buildActionCard(
      BuildContext context, {
        required String title,
        required IconData icon,
        required Color color,
        required VoidCallback onTap,
      }) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}