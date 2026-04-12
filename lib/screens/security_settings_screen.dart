import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';
import '../utils/style_utils.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({Key? key}) : super(key: key);

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final ApiService _api = ApiService();
  bool _is2faEnabled = false;
  bool _isLoading = false;
  String? _otpUri;
  final _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    setState(() => _isLoading = true);
    final result = await _api.getCurrentUser();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success']) {
          _is2faEnabled = result['data']['is_2fa_enabled'] ?? false;
        }
      });
    }
  }

  Future<void> _setup2FA() async {
    setState(() => _isLoading = true);
    final result = await _api.setup2FA();
    setState(() => _isLoading = false);

    if (result['success']) {
      setState(() {
        _otpUri = result['data']['otpauth_uri'];
      });
      _showSetupDialog();
    } else {
      _showError(result['error']);
    }
  }

  String _extractSecret(String uriString) {
    if (uriString.isEmpty) return 'Loading...';
    try {
      Uri uri = Uri.parse(uriString);
      return uri.queryParameters['secret'] ?? 'No secret found';
    } catch (e) {
      return 'Invalid Content';
    }
  }

  void _showSetupDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Setup Authenticator'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('1. Scan this QR code in your Authenticator app (Google Authenticator, Authy, etc.)'),
                const SizedBox(height: 20),
                Center(
                  child: QrImageView(
                    data: _otpUri ?? '',
                    version: QrVersions.auto,
                    size: 200.0,
                  ),
                ),
                const Text('2. Or enter this secret key manually:'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _extractSecret(_otpUri ?? ''),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 20),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _extractSecret(_otpUri ?? '')));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Secret key copied!'), duration: Duration(seconds: 2)),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text('3. Finally, enter the 6-digit code from the app:'),
                const SizedBox(height: 10),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 4),
                  decoration: const InputDecoration(counterText: ''),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () async {
                final result = await _api.enable2FA(_otpController.text);
                if (result['success']) {
                  setState(() => _is2faEnabled = true);
                  Navigator.pop(context);
                  _showSuccess('2FA Enabled Successfully!');
                  _otpController.clear();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result['error'])),
                  );
                }
              },
              child: const Text('VERIFY & ENABLE'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _disable2FA() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable 2FA?'),
        content: const Text('This will make your account less secure.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('DISABLE', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final result = await _api.disable2FA();
      setState(() => _isLoading = false);
      if (result['success']) {
        setState(() => _is2faEnabled = false);
        _showSuccess('2FA Disabled.');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.success));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      appBar: AppBar(
        title: const Text('Security Settings', style: TextStyle(color: AppColors.textMain)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textMain),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Two-Factor Authentication', style: AppTextStyles.h2),
                const SizedBox(height: 8),
                const Text(
                  'Add an extra layer of security to your account by requiring a code from an Authenticator app when you log in.',
                  style: AppTextStyles.bodySub,
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppDecoration.cardDecoration(),
                  child: Row(
                    children: [
                      Icon(
                        _is2faEnabled ? Icons.verified_user : Icons.gpp_maybe,
                        color: _is2faEnabled ? AppColors.success : Colors.orange,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _is2faEnabled ? '2FA is Enabled' : '2FA is Disabled',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              _is2faEnabled ? 'Your account is protected.' : 'Level up your security.',
                              style: AppTextStyles.bodySub,
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _is2faEnabled,
                        onChanged: (val) {
                          if (val) {
                            _setup2FA();
                          } else {
                            _disable2FA();
                          }
                        },
                        activeColor: AppColors.familyPrimary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
