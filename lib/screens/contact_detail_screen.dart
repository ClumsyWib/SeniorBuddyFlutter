import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactDetailScreen extends StatelessWidget {
  final Map<String, dynamic> contact;

  const ContactDetailScreen({Key? key, required this.contact}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isPrimary = contact['is_primary'] ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Details', style: TextStyle(fontSize: 24)),
        backgroundColor: const Color(0xFFE53935),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile Section
            CircleAvatar(
              radius: 60,
              backgroundColor: const Color(0xFFE53935).withOpacity(0.2),
              child: Text(
                contact['name']?[0] ?? 'C',
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFFE53935)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              contact['name'] ?? 'Contact',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (isPrimary)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'PRIMARY CONTACT',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange),
                ),
              ),
            const SizedBox(height: 32),

            // Details Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildDetailRow(Icons.family_restroom, 'Relationship', contact['relationship'] ?? 'N/A'),
                    const Divider(height: 32),
                    _buildDetailRow(Icons.phone, 'Phone', contact['phone'] ?? 'N/A'),
                    if (contact['email'] != null) ...[
                      const Divider(height: 32),
                      _buildDetailRow(Icons.email, 'Email', contact['email']),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _makePhoneCall(context, contact['phone']),
                    icon: const Icon(Icons.phone, size: 24),
                    label: const Text('Call', style: TextStyle(fontSize: 20)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _sendSMS(context, contact['phone']),
                    icon: const Icon(Icons.message, size: 24),
                    label: const Text('Message', style: TextStyle(fontSize: 20)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 28, color: const Color(0xFFE53935)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 16, color: Colors.black54)),
              const SizedBox(height: 6),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  String _formatPhone(String phone) {
    // Remove everything that isn't a digit or +
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    // If it doesn't start with +, you can prepend your country code. e.g. +91
    if (!cleaned.startsWith('+') && cleaned.isNotEmpty) {
      cleaned = '+91$cleaned'; // Change +91 to your desired default country code
    }
    return cleaned;
  }

  Future<void> _makePhoneCall(BuildContext context, String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No phone number available for this contact.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final formattedUrl = _formatPhone(phone);
    final Uri phoneUri = Uri(scheme: 'tel', path: formattedUrl);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open phone dialer.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _sendSMS(BuildContext context, String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No phone number available for this contact.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final formattedUrl = _formatPhone(phone);
    final Uri smsUri = Uri(scheme: 'sms', path: formattedUrl);
    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        await launchUrl(smsUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open SMS app.'), backgroundColor: Colors.red),
        );
      }
    }
  }
}