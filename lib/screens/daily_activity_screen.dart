import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/emergency_helper.dart';

import '../utils/role_helper.dart';
import 'add_activity_screen.dart';
import 'package:intl/intl.dart';
import 'daily_activity_detail_screen.dart';

class DailyActivityScreen extends StatefulWidget {
  final int seniorId;
  final String seniorName;
  // userRole controls whether the 'Log Activity' button is shown
  final String userRole;

  const DailyActivityScreen({
    Key? key,
    required this.seniorId,
    required this.seniorName,
    this.userRole = kRoleCaretaker,
  }) : super(key: key);

  @override
  State<DailyActivityScreen> createState() => _DailyActivityScreenState();
}

class _DailyActivityScreenState extends State<DailyActivityScreen> {
  final ApiService _apiService = ApiService();

  List<dynamic> _activities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() {
      _isLoading = true;
    });

    final result = await _apiService.getDailyActivities(widget.seniorId);

    if (result['success'] == true) {
      setState(() {
        _activities = result['data'] ?? [];
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${result['error']}')),
        );
      }
    }
  }

  Future<void> _triggerSOS(BuildContext context) async {
    await EmergencyHelper.triggerSOS(context, widget.seniorId);
  }

  Future<void> _deleteActivity(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Log'),
        content: const Text('Are you sure you want to delete this log entry?'),
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
      final result = await _apiService.deleteDailyActivity(id);
      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Log entry deleted')),
          );
          _loadActivities();
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
        title: Text('${widget.seniorName} - Care Log'),
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
          : RefreshIndicator(
              onRefresh: _loadActivities,
              child: _activities.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _activities.length,
                      itemBuilder: (context, index) {
                        final activity = _activities[index];
                        return _buildActivityCard(activity);
                      },
                    ),
            ),
      // Only Caretakers can log activities
      floatingActionButton: canCaretakerWrite(widget.userRole)
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddActivityScreen(
                      seniorId: widget.seniorId,
                      seniorName: widget.seniorName,
                      roleColor: Theme.of(context).primaryColor,
                    ),
                  ),
                );
                if (result == true) {
                  _loadActivities();
                }
              },
              label: const Text('Log Activity'),
              icon: const Icon(Icons.add),
              backgroundColor: Theme.of(context).primaryColor,
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No activities logged yet',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Tap the button below to log a care activity.'),
            const SizedBox(height: 48), // Padding for pull
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(dynamic activity) {
    final DateTime timestamp = DateTime.parse(activity['timestamp']).toLocal();

    final String dateStr =
        DateFormat('MMM dd, yyyy - hh:mm a').format(timestamp);

    return Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 3,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  DailyActivityDetailScreen(activity: activity),
            ),
          ),
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTypeChip(activity['activity_type'] ?? 'other'),
                    Text(
                      dateStr,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (activity['notes'] != null &&
                    activity['notes'].toString().isNotEmpty)
                  Text(
                    activity['notes'],
                    style: const TextStyle(fontSize: 16),
                  ),
                Row(
                  children: [
                    const Icon(Icons.person_outline,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Logged by: ${activity['caretaker_name'] ?? 'Unknown'}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    if (!(canFamilyWrite(widget.userRole) ||
                        widget.userRole == kRoleCaretaker))
                      const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
                if (canFamilyWrite(widget.userRole) ||
                    widget.userRole == kRoleCaretaker) ...[
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _deleteActivity(activity['id']),
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red, size: 20),
                        label: const Text('Delete',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ));
  }

  Widget _buildTypeChip(String type) {
    Color chipColor;
    IconData icon;

    switch (type) {
      case 'meal':
        chipColor = Colors.orange;
        icon = Icons.restaurant;
        break;

      case 'medicine':
        chipColor = Colors.red;
        icon = Icons.medication;
        break;

      case 'exercise':
        chipColor = Colors.green;
        icon = Icons.directions_run;
        break;

      case 'hygiene':
        chipColor = Colors.blue;
        icon = Icons.clean_hands;
        break;

      case 'mood':
        chipColor = Colors.purple;
        icon = Icons.emoji_emotions;
        break;

      case 'rest':
        chipColor = Colors.indigo;
        icon = Icons.bed;
        break;

      default:
        chipColor = Colors.grey;
        icon = Icons.assignment;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chipColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: chipColor),
          const SizedBox(width: 6),
          Text(
            type.toUpperCase(),
            style: TextStyle(
              color: chipColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
