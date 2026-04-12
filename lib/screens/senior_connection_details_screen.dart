import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';

class SeniorConnectionDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> senior;

  const SeniorConnectionDetailsScreen({
    Key? key,
    required this.senior,
  }) : super(key: key);

  @override
  State<SeniorConnectionDetailsScreen> createState() =>
      _SeniorConnectionDetailsScreenState();
}

class _SeniorConnectionDetailsScreenState
    extends State<SeniorConnectionDetailsScreen> {
  final ApiService _apiService = ApiService();
  late String _pairCode;
  bool _isRegenerating = false;

  @override
  void initState() {
    super.initState();
    _pairCode = widget.senior['pair_code'] ?? '000000';
  }

  Future<void> _handleRegenerate() async {
    final passwordController = TextEditingController();

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please enter your password to regenerate the connection code.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Verify & Regenerate'),
          ),
        ],
      ),
    );

    if (confirm == true && passwordController.text.isNotEmpty) {
      setState(() => _isRegenerating = true);

      final result = await _apiService.regeneratePairCode(
        widget.senior['id'],
        passwordController.text,
      );

      if (mounted) {
        setState(() => _isRegenerating = false);

        if (result['success']) {
          setState(() => _pairCode = result['pair_code']);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('New connection code generated!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['error'] ?? 'Failed to regenerate code',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _pairCode);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Connection Details',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF4CAF50),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _pairCode),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.qr_code_2, size: 80, color: Color(0xFF4CAF50)),
                const SizedBox(height: 24),

                Text(
                  'Connect ${widget.senior['name']}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Share this code or QR with the senior device to connect.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),

                const SizedBox(height: 48),

                // CODE BOX
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    _pairCode,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // QR CODE
                QrImageView(
                  data: _pairCode,
                  version: QrVersions.auto,
                  size: 240.0,
                  backgroundColor: Colors.white,
                ),

                const SizedBox(height: 64),

                if (_isRegenerating)
                  const CircularProgressIndicator()
                else
                  ElevatedButton.icon(
                    onPressed: _handleRegenerate,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Regenerate New Code'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                    ),
                  ),

                const SizedBox(height: 16),

                const Text(
                  'Warning: Generating a new code will require re-connecting any new devices using the old code.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
