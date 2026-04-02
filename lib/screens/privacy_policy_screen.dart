import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy', style: TextStyle(fontSize: 24)),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Policy',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Last updated: February 2026',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 32),
            _buildSection(
              '1. Information We Collect',
              'We collect information you provide directly to us, including your name, email, phone number, and health information.',
            ),
            _buildSection(
              '2. How We Use Your Information',
              'We use the information we collect to provide, maintain, and improve our services, and to communicate with you.',
            ),
            _buildSection(
              '3. Information Sharing',
              'We do not share your personal information with third parties except as described in this privacy policy.',
            ),
            _buildSection(
              '4. Data Security',
              'We take reasonable measures to help protect your personal information from loss, theft, misuse, and unauthorized access.',
            ),
            _buildSection(
              '5. Your Rights',
              'You have the right to access, update, or delete your personal information at any time.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(fontSize: 18, height: 1.5),
          ),
        ],
      ),
    );
  }
}