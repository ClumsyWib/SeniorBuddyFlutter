import 'package:flutter/material.dart';
import '../screens/settings_screen.dart';
import '../screens/help_support_screen.dart';

class ProfileLinksWidget extends StatelessWidget {
  final VoidCallback onLogout;
  final Color? primaryColor;

  const ProfileLinksWidget({
    Key? key,
    required this.onLogout,
    this.primaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color themeColor = primaryColor ?? Theme.of(context).primaryColor;

    return Column(
      children: [
        _buildProfileOption(
          context,
          icon: Icons.settings_outlined,
          title: 'Settings',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
          color: themeColor,
        ),
        _buildProfileOption(
          context,
          icon: Icons.info_outline,
          title: 'About App',
          onTap: () => _showInfoDialog(
            context,
            'About App',
            'Senior Buddy v1.0.0\nA companion for your loved ones.',
          ),
          color: themeColor,
        ),
        _buildProfileOption(
          context,
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy Policy',
          onTap: () => _showInfoDialog(
            context,
            'Privacy Policy',
            'Your data is safe with us. We do not share your information with third parties.',
          ),
          color: themeColor,
        ),
        _buildProfileOption(
          context,
          icon: Icons.description_outlined,
          title: 'Terms & Conditions',
          onTap: () => _showInfoDialog(
            context,
            'Terms & Conditions',
            'By using this app, you agree to our terms of service.',
          ),
          color: themeColor,
        ),
        _buildProfileOption(
          context,
          icon: Icons.help_outline,
          title: 'Help & Support',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
          ),
          color: themeColor,
        ),
        const Divider(height: 40),
        _buildProfileOption(
          context,
          icon: Icons.logout,
          title: 'Logout',
          onTap: onLogout,
          textColor: Colors.red,
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildProfileOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    required Color color,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textColor ?? const Color(0xFF1A1A2E),
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
