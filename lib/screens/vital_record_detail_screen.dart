import 'package:flutter/material.dart';

class VitalRecordDetailScreen extends StatelessWidget {
  final Map<String, dynamic> record;

  const VitalRecordDetailScreen({Key? key, required this.record})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Vital Record Details', style: TextStyle(fontSize: 24)),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '${record['record_date']}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Recorded at: ${_formatTo12Hour(record['record_time'])}',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'By: ${record['recorded_by_name'] ?? 'Unknown'}',
                      style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Measurements Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Measurements',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    if (record['blood_pressure'] != null &&
                        record['blood_pressure'].toString().isNotEmpty) ...[
                      _buildDetailRow(context, Icons.favorite, 'Blood Pressure',
                          record['blood_pressure']),
                      const Divider(height: 32),
                    ],
                    if (record['heart_rate'] != null) ...[
                      _buildDetailRow(context, Icons.monitor_heart, 'Heart Rate',
                          '${record['heart_rate']} bpm'),
                      const Divider(height: 32),
                    ],
                    if (record['temperature'] != null) ...[
                      _buildDetailRow(context, Icons.thermostat, 'Temperature',
                          '${record['temperature']} °C'),
                      const Divider(height: 32),
                    ],
                    if (record['blood_sugar'] != null) ...[
                      _buildDetailRow(context, Icons.bloodtype, 'Blood Sugar',
                          '${record['blood_sugar']} mg/dL'),
                      const Divider(height: 32),
                    ],
                    if (record['weight'] != null) ...[
                      _buildDetailRow(context, Icons.monitor_weight, 'Weight',
                          '${record['weight']} kg'),
                      const Divider(height: 32),
                    ],
                    if (record['oxygen_level'] != null) ...[
                      _buildDetailRow(context, Icons.air, 'Oxygen Level (SpO2)',
                          '${record['oxygen_level']}%'),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 28, color: Theme.of(context).primaryColor),
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
