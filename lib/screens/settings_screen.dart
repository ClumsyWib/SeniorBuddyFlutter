import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'privacy_policy_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() {
      _notificationsEnabled = value;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value ? 'Notifications enabled' : 'Notifications disabled',
            style: const TextStyle(fontSize: 16),
          ),
          backgroundColor: const Color(0xFF4CAF50),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Language', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('English', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.check, color: Color(0xFF4CAF50)),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                title: const Text('Hindi', style: TextStyle(color: Colors.grey)),
                subtitle: const Text('Coming Soon'),
                onTap: () {},
              ),
              ListTile(
                title: const Text('Spanish', style: TextStyle(color: Colors.grey)),
                subtitle: const Text('Coming Soon'),
                onTap: () {},
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Color(0xFF4CAF50))),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontSize: 24)),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: SwitchListTile(
              secondary: const Icon(Icons.notifications, size: 32, color: Color(0xFF4CAF50)),
              title: const Text('Notifications', style: TextStyle(fontSize: 20)),
              subtitle: const Text('Manage notification preferences', style: TextStyle(fontSize: 16)),
              value: _notificationsEnabled,
              activeColor: const Color(0xFF4CAF50),
              onChanged: _toggleNotifications,
            ),
          ),
          _buildSettingTile(
            icon: Icons.language,
            title: 'Language',
            subtitle: 'English',
            onTap: _showLanguageDialog,
          ),
          _buildSettingTile(
            icon: Icons.security,
            title: 'Privacy & Security',
            subtitle: 'Manage your privacy settings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
              );
            },
          ),
          
          const SizedBox(height: 40),
          const Center(
            child: Text(
              'Senior Care App\nVersion 1.0.0',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, size: 32, color: const Color(0xFF4CAF50)),
        title: Text(title, style: const TextStyle(fontSize: 20)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 16)),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}