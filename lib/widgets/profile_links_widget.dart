import 'package:flutter/material.dart';
import '../screens/settings_screen.dart';
import '../screens/help_support_screen.dart';
import '../screens/security_settings_screen.dart';

class ProfileLinksWidget extends StatelessWidget {
  final VoidCallback onLogout;
  final Color? primaryColor;
  final bool showSettings;
  final bool showSecurity;

  const ProfileLinksWidget({
    Key? key,
    required this.onLogout,
    this.primaryColor,
    this.showSettings = true,
    this.showSecurity = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color themeColor = primaryColor ?? Theme.of(context).primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Options Card ───────────────────────────────────────────
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              if (showSettings)
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
              if (showSettings) const Divider(height: 1, indent: 16, endIndent: 16),
              if (showSecurity)
                _buildProfileOption(
                  context,
                  icon: Icons.lock_person_outlined,
                  title: 'Security Settings',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SecuritySettingsScreen()),
                  ),
                  color: themeColor,
                ),
              if (showSecurity) const Divider(height: 1, indent: 16, endIndent: 16),
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
              const Divider(height: 1, indent: 16, endIndent: 16),
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
              const Divider(height: 1, indent: 16, endIndent: 16),
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
              const Divider(height: 1, indent: 16, endIndent: 16),
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
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Logout Button ──────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded, size: 20),
            label: const Text('Log Out',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFEBEE),
              foregroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Colors.redAccent, width: 1)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
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
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textColor ?? const Color(0xFF1A1C2E),
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey[400]),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
