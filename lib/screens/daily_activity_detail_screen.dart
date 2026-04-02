import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DailyActivityDetailScreen extends StatelessWidget {
  final Map<String, dynamic> activity;

  const DailyActivityDetailScreen({Key? key, required this.activity})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DateTime timestamp = DateTime.parse(activity['timestamp']).toLocal();
    final String dateStr = DateFormat('MMM dd, yyyy').format(timestamp);
    final String timeStr = DateFormat('hh:mm a').format(timestamp);
    final String type = (activity['activity_type'] ?? 'other').toString().toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Details', style: TextStyle(fontSize: 24)),
        backgroundColor: _getTypeColor(type),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _getTypeColor(type).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getTypeIcon(type),
                        size: 60,
                        color: _getTypeColor(type),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      type.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Logged by: ${activity['caretaker_name'] ?? 'Unknown'}',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Time & Date Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Timing',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    _buildDetailRow(
                      Icons.calendar_today,
                      'Date',
                      dateStr,
                    ),
                    const Divider(height: 32),
                    _buildDetailRow(
                      Icons.access_time,
                      'Time',
                      timeStr,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notes Card
            if (activity['notes'] != null &&
                activity['notes'].toString().trim().isNotEmpty)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Activity Notes',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      _buildDetailRow(
                        Icons.notes,
                        'Notes',
                        activity['notes'].toString(),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 28, color: Colors.blue),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'meal': return Colors.orange;
      case 'medicine': return Colors.red;
      case 'exercise': return Colors.green;
      case 'hygiene': return Colors.blue;
      case 'mood': return Colors.purple;
      case 'rest': return Colors.indigo;
      default: return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'meal': return Icons.restaurant;
      case 'medicine': return Icons.medication;
      case 'exercise': return Icons.directions_run;
      case 'hygiene': return Icons.clean_hands;
      case 'mood': return Icons.emoji_emotions;
      case 'rest': return Icons.bed;
      default: return Icons.assignment;
    }
  }
}
