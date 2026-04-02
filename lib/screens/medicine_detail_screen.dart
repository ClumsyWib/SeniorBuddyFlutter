import 'package:flutter/material.dart';

class MedicineDetailScreen extends StatelessWidget {
  final Map<String, dynamic> medicine;

  const MedicineDetailScreen({Key? key, required this.medicine})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isActive = medicine['is_active'] ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Details', style: TextStyle(fontSize: 24)),
        backgroundColor: const Color(0xFFE53935),
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
                        color: const Color(0xFFE53935).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.medication,
                        size: 60,
                        color: Color(0xFFE53935),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      medicine['medicine_name'] ?? 'Medicine',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.green.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Text(
                        isActive ? 'ACTIVE' : 'INACTIVE',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.green : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Dosage Information Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dosage Information',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    _buildDetailRow(
                      Icons.medical_services,
                      'Dosage',
                      medicine['dosage'] ?? 'N/A',
                    ),
                    if (medicine['frequency'] != null) ...[
                      const Divider(height: 32),
                      _buildDetailRow(
                        Icons.schedule,
                        'Frequency',
                        _formatText(medicine['frequency']),
                      ),
                    ],
                    if (medicine['time_of_day'] != null) ...[
                      const Divider(height: 32),
                      _buildDetailRow(
                        Icons.access_time,
                        'Time of Day',
                        _formatText(medicine['time_of_day']),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Schedule Card
            if (medicine['start_date'] != null || medicine['end_date'] != null)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Schedule',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      if (medicine['start_date'] != null)
                        _buildDetailRow(
                          Icons.calendar_today,
                          'Start Date',
                          _formatDate(medicine['start_date']),
                        ),
                      if (medicine['start_date'] != null && medicine['end_date'] != null)
                        const Divider(height: 32),
                      if (medicine['end_date'] != null)
                        _buildDetailRow(
                          Icons.event,
                          'End Date',
                          _formatDate(medicine['end_date']),
                        ),
                    ],
                  ),
                ),
              ),

            if (medicine['start_date'] != null || medicine['end_date'] != null)
              const SizedBox(height: 16),

            // Instructions Card
            if (medicine['instructions'] != null &&
                medicine['instructions'].toString().trim().isNotEmpty)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Special Instructions',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      _buildDetailRow(
                        Icons.info_outline,
                        'Instructions',
                        medicine['instructions'].toString(),
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
        Icon(icon, size: 28, color: const Color(0xFFE53935)),
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

  String _formatText(String? text) {
    if (text == null) return 'N/A';
    return text
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty
        ? word
        : '${word[0].toUpperCase()}${word.length > 1 ? word.substring(1) : ''}')
        .join(' ');
  }

  String _formatDate(String? date) {
    if (date == null) return 'N/A';
    try {
      final parts = date.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}'; // DD/MM/YYYY
      }
    } catch (e) {
      // If parsing fails, return as-is
    }
    return date;
  }
}