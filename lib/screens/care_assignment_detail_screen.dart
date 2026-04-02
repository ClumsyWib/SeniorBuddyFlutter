import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CareAssignmentDetailScreen extends StatelessWidget {
  final Map<String, dynamic> assignment;

  const CareAssignmentDetailScreen({Key? key, required this.assignment})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final photoUrl = assignment['photo'];
    final name = assignment['name'] ?? 'Unknown Caretaker';
    final phone = assignment['phone'] ?? 'N/A';
    final specialization = assignment['specialization'] ?? 'General Care';
    final rating = assignment['rating'] ?? 0.0;
    final experience = assignment['experience'] ?? 'N/A';
    final schedule = assignment['schedule'] ?? 'N/A';
    final startDate = assignment['start_date'] ?? 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Caretaker Details', style: TextStyle(fontSize: 24)),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card with Photo
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.2),
                        shape: BoxShape.circle,
                        image: photoUrl != null
                            ? DecorationImage(
                                image: NetworkImage(photoUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: photoUrl == null
                          ? const Icon(
                              Icons.person,
                              size: 80,
                              color: Colors.teal,
                            )
                          : null,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 24),
                        const SizedBox(width: 4),
                        Text(
                          rating.toString(),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '($experience Exp)',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Professional Details Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Professional Details',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    _buildDetailRow(
                      Icons.work,
                      'Specialization',
                      specialization,
                    ),
                    const Divider(height: 32),
                    _buildDetailRow(
                      Icons.schedule,
                      'Schedule',
                      schedule,
                    ),
                    const Divider(height: 32),
                    _buildDetailRow(
                      Icons.calendar_today,
                      'Assigned Since',
                      startDate,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Contact Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Contact Caretaker',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    _buildDetailRow(
                      Icons.phone,
                      'Phone',
                      phone,
                      onTap: () => _launchURL('tel:$phone'),
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

  Widget _buildDetailRow(IconData icon, String label, String value, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28, color: Colors.teal),
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
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: onTap != null ? Colors.blue : Colors.black87,
                    decoration: onTap != null ? TextDecoration.underline : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
