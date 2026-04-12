import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  Future<void> _launchUrl(String urlString, BuildContext context) async {
    try {
      final Uri url = Uri.parse(urlString);
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch application')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error launching application')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support', style: TextStyle(fontSize: 24)),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Contact Us',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildContactCard(
            context,
            Icons.email,
            'Email',
            'support@seniorcare.com',
            () => _launchUrl('mailto:support@seniorcare.com', context),
          ),
          _buildContactCard(
            context,
            Icons.phone,
            'Phone',
            '+1 (555) 123-4567',
            () => _launchUrl('tel:+15551234567', context),
          ),
          _buildContactCard(
            context,
            Icons.location_on,
            'Address',
            '123 Care Street, City, State',
            () => _launchUrl(
                'https://maps.google.com/?q=123+Care+Street', context),
          ),
          const SizedBox(height: 32),
          const Text('FAQs',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildFAQ('How do I create an appointment?',
              'Click the green + button on the home screen.'),
          _buildFAQ('How do I contact my caretaker?',
              'Go to Connect tab and view your caretaker details.'),
        ],
      ),
    );
  }

  Widget _buildContactCard(
      BuildContext context, IconData icon, String title, String value, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          leading: Icon(icon, size: 32, color: Theme.of(context).primaryColor),
          title: Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          subtitle: Text(value, style: const TextStyle(fontSize: 16)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        ),
      ),
    );
  }

  Widget _buildFAQ(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(question,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(answer, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
