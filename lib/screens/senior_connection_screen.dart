import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:senior_care_app/screens/role_selection_screen.dart';
import '../services/api_service.dart';
import '../home/senior_home_screen.dart';

class SeniorConnectionScreen extends StatefulWidget {
  const SeniorConnectionScreen({Key? key}) : super(key: key);

  @override
  State<SeniorConnectionScreen> createState() => _SeniorConnectionScreenState();
}

class _SeniorConnectionScreenState extends State<SeniorConnectionScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  bool _isScanning = false;

  Future<void> _connect(String code) async {
    if (code.length != 6) return;

    setState(() => _isLoading = true);
    final result = await _apiService.connectSenior(code);

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success']) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const SeniorHomeScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Invalid code. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect to Family'),
        backgroundColor: const Color(0xFF9C27B0),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Switch Role',
          onPressed: () async {
            await _apiService.clearStorage();
            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                (route) => false,
              );
            }
          },
        ),
      ),
      body: _isScanning ? _buildScanner() : _buildManualEntry(),
    );
  }

  Widget _buildManualEntry() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.link, size: 80, color: Color(0xFF9C27B0)),
          const SizedBox(height: 24),
          const Text(
            'Enter Connection Code',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Ask your family member for the 6-digit code shown on their screen.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 40),
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 8),
            decoration: InputDecoration(
              counterText: '',
              hintText: '000000',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => _connect(_codeController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9C27B0),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Connect', style: TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(height: 24),
          const Text('OR', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => setState(() => _isScanning = true),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan QR Code'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9C27B0),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        MobileScanner(
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              final String? code = barcode.rawValue;
              if (code != null && code.length == 6) {
                setState(() => _isScanning = false);
                _connect(code);
                break;
              }
            }
          },
        ),
        Positioned(
          top: 40,
          left: 20,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 30),
            onPressed: () => setState(() => _isScanning = false),
          ),
        ),
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        const Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: Text(
            'Scan the QR code on your family\'s phone',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
