import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/text_scale_provider.dart';
import 'privacy_policy_screen.dart';
import 'security_settings_screen.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiService _apiService = ApiService();
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'en';

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'hi', 'name': 'Hindi'},
    {'code': 'gu', 'name': 'Gujarati'},
    {'code': 'ta', 'name': 'Tamil'},
    {'code': 'te', 'name': 'Telugu'},
    {'code': 'mr', 'name': 'Marathi'},
    {'code': 'pa', 'name': 'Punjabi'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _selectedLanguage = prefs.getString('preferred_language') ?? 'en';
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
          backgroundColor: Theme.of(context).primaryColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _changeLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferred_language', code);
    
    // Attempt to sync with backend
    await _apiService.updateLanguage(code);

    setState(() {
      _selectedLanguage = code;
    });

    if (mounted) {
      final langName = _languages.firstWhere((l) => l['code'] == code)['name'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Language updated to $langName')),
      );
    }
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Language',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _languages.length,
              itemBuilder: (ctx, index) {
                final lang = _languages[index];
                final isSelected = _selectedLanguage == lang['code'];
                return ListTile(
                  title: Text(lang['name']!),
                  trailing: isSelected 
                      ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    if (!isSelected) _changeLanguage(lang['code']!);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close',
                  style: TextStyle(color: Theme.of(context).primaryColor)),
            ),
          ],
        );
      },
    );
  }

  void _showTextSizeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return _TextSizeDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textScaleProvider = context.watch<TextScaleProvider>();
    final currentSizeName = textScaleProvider.currentOption.label;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontSize: 24)),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: SwitchListTile(
              secondary: Icon(Icons.notifications,
                  size: 32, color: Theme.of(context).primaryColor),
              title: const Text('Notifications',
                  style: TextStyle(fontSize: 20)),
              subtitle: const Text('Manage notification preferences',
                  style: TextStyle(fontSize: 16)),
              value: _notificationsEnabled,
              activeThumbColor: Theme.of(context).primaryColor,
              onChanged: _toggleNotifications,
            ),
          ),
          _buildSettingTile(
            icon: Icons.language,
            title: 'Language',
            subtitle: _languages.firstWhere((l) => l['code'] == _selectedLanguage)['name']!,
            onTap: _showLanguageDialog,
          ),
          // ── Text Size Option ──────────────────────────────────────
          if (textScaleProvider.isSeniorMode)
            _buildSettingTile(
              icon: Icons.text_fields,
              title: 'Text Size',
              subtitle: currentSizeName,
              onTap: _showTextSizeDialog,
            ),
          _buildSettingTile(
            icon: Icons.security,
            title: 'Privacy & Security',
            subtitle: 'Manage your privacy settings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const PrivacyPolicyScreen()),
              );
            },
          ),
          _buildSettingTile(
            icon: Icons.lock_person,
            title: 'Security Settings',
            subtitle: '2FA & Login Security',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SecuritySettingsScreen()),
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
        leading: Icon(icon, size: 32, color: Theme.of(context).primaryColor),
        title: Text(title, style: const TextStyle(fontSize: 20)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 16)),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Dialog for selecting text size with a live preview.
// ─────────────────────────────────────────────────────────────────────────────
class _TextSizeDialog extends StatefulWidget {
  @override
  State<_TextSizeDialog> createState() => _TextSizeDialogState();
}

class _TextSizeDialogState extends State<_TextSizeDialog> {
  late TextSizeLevel _selectedLevel;

  @override
  void initState() {
    super.initState();
    _selectedLevel =
        context.read<TextScaleProvider>().currentLevel;
  }

  @override
  Widget build(BuildContext context) {
    final options = TextScaleProvider.textSizeOptions;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.text_fields, color: Theme.of(context).primaryColor, size: 28),
          SizedBox(width: 10),
          Text(
            'Text Size',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
        ],
      ),
      // ConstrainedBox prevents the dialog from growing beyond screen bounds
      // when Extra Large text is active, eliminating the pixel overflow error.
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.65,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Preview Box ───────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Theme.of(context).primaryColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PREVIEW',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Cap preview scale at 1.25 to keep the dialog readable
                    MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        textScaler: TextScaler.linear(
                          options
                              .firstWhere((o) => o.level == _selectedLevel)
                              .scaleFactor
                              .clamp(0.85, 1.25),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good Morning! 👋',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Today\'s medicine reminder:\nMetformin 500mg at 8:00 AM',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Select a Size',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 10),
              // ── Size Option Buttons ───────────────────────────────
              // Wrap in MediaQuery to prevent globally scaled text from
              // inflating the option tiles and causing overflow
              MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(1.0),
                ),
                child: Column(
                  children: options.map((option) {
                    final isSelected = _selectedLevel == option.level;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TextSizeOptionTile(
                        option: option,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() => _selectedLevel = option.level);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      actionsPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.grey),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text('Cancel',
              style: TextStyle(color: Colors.grey, fontSize: 16)),
        ),
        ElevatedButton(
          onPressed: () {
            context
                .read<TextScaleProvider>()
                .setTextSizeLevel(_selectedLevel);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Text size set to '
                  '${TextScaleProvider.textSizeOptions.firstWhere((o) => o.level == _selectedLevel).label}',
                  style: const TextStyle(fontSize: 16),
                ),
                backgroundColor: Theme.of(context).primaryColor,
                duration: const Duration(seconds: 2),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('Apply', style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Individual option row inside the text size dialog.
// ─────────────────────────────────────────────────────────────────────────────
class _TextSizeOptionTile extends StatelessWidget {
  final TextSizeOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _TextSizeOptionTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.12)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon badge showing "A-", "A", "A+", "A++"
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                option.icon,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black54,
                  fontWeight: FontWeight.bold,
                  fontSize: option.icon.length > 2 ? 11 : 14,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Flexible prevents text from overflowing the tile at any scale
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.black87,
                    ),
                  ),
                  Text(
                    '${(option.scaleFactor * 100).toStringAsFixed(0)}% scale',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle,
                  color: Theme.of(context).primaryColor, size: 26),
          ],
        ),
      ),
    );
  }
}
