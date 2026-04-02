import 'package:flutter/material.dart';
import '../services/api_service.dart';
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
        title: Text('${widget.seniorName} - Care Log'),
        backgroundColor: const Color(0xFF2196F3),
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
                    ),
                  ),
                );
                if (result == true) {
                  _loadActivities();
                }
              },
              label: const Text('Log Activity'),
              icon: const Icon(Icons.add),
              backgroundColor: const Color(0xFF2196F3),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
        ],
      ),
    );
  }

  Widget _buildActivityCard(dynamic activity) {
    final DateTime timestamp =
    DateTime.parse(activity['timestamp']).toLocal();

    final String dateStr =
    DateFormat('MMM dd, yyyy - hh:mm a').format(timestamp);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DailyActivityDetailScreen(activity: activity),
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
            const SizedBox(height: 12),
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
              ],
            ),
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
      padding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
