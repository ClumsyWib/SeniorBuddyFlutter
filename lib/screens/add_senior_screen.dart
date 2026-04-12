import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';

class AddSeniorScreen extends StatefulWidget {
  const AddSeniorScreen({Key? key}) : super(key: key);

  @override
  State<AddSeniorScreen> createState() => _AddSeniorScreenState();
}

class _AddSeniorScreenState extends State<AddSeniorScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _medicalConditionsController = TextEditingController();
  final _allergiesController = TextEditingController();

  String _selectedGender = 'other';
  String _selectedMobility = 'independent';
  String _selectedCareLevel = 'minimal';

  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final result = await _apiService.createSenior(
      name: _nameController.text.trim(),
      age: int.tryParse(_ageController.text.trim()) ?? 0,
      gender: _selectedGender,
      medicalConditions: _medicalConditionsController.text.trim(),
      allergies: _allergiesController.text.trim(),
      mobilityStatus: _selectedMobility,
      careLevel: _selectedCareLevel,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      print('🔵 Senior Creation Result: $result');
      if (result['success']) {
        final data = result['data'];
        if (data != null && data['pair_code'] != null) {
          _showSuccessDialog(data);
        } else {
          print('🔴 Success but data/pair_code missing: $data');
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Saved but connection code missing!'),
              backgroundColor: Colors.orange));
          Navigator.pop(context, true); // Refresh list anyway
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed: ${result['error'] ?? 'Unknown'}'),
            backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Senior',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                      labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
                  validator: (v) => v!.isEmpty ? 'Please enter name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Age', prefixIcon: Icon(Icons.cake)),
                  validator: (v) => v!.isEmpty ? 'Please enter age' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: const InputDecoration(
                      labelText: 'Gender', prefixIcon: Icon(Icons.transgender)),
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('Male')),
                    DropdownMenuItem(value: 'female', child: Text('Female')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (v) => setState(() => _selectedGender = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedMobility,
                  decoration: const InputDecoration(
                      labelText: 'Mobility Status',
                      prefixIcon: Icon(Icons.directions_walk)),
                  items: const [
                    DropdownMenuItem(
                        value: 'independent', child: Text('Independent')),
                    DropdownMenuItem(
                        value: 'needs_assistance',
                        child: Text('Needs Assistance')),
                    DropdownMenuItem(
                        value: 'wheelchair', child: Text('Wheelchair')),
                    DropdownMenuItem(
                        value: 'bedridden', child: Text('Bedridden')),
                  ],
                  onChanged: (v) => setState(() => _selectedMobility = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCareLevel,
                  decoration: const InputDecoration(
                      labelText: 'Care Level',
                      prefixIcon: Icon(Icons.health_and_safety)),
                  items: const [
                    DropdownMenuItem(value: 'minimal', child: Text('Minimal')),
                    DropdownMenuItem(
                        value: 'moderate', child: Text('Moderate')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
                    DropdownMenuItem(value: '24_7', child: Text('24/7')),
                  ],
                  onChanged: (v) => setState(() => _selectedCareLevel = v!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _medicalConditionsController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'Medical Conditions (Optional)',
                      prefixIcon: Icon(Icons.medical_information)),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _allergiesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'Allergies (Optional)',
                      prefixIcon: Icon(Icons.warning)),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Senior',
                          style: TextStyle(fontSize: 18)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(Map<String, dynamic> seniorData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Senior Added Successfully!'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Share this code with the senior:'),
              const SizedBox(height: 16),
              Text(
                seniorData['pair_code'] ?? '000000',
                style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                    color: Color(0xFF4CAF50)),
              ),
              const SizedBox(height: 24),
              const Text('OR Scan this QR Code:'),
              const SizedBox(height: 16),
              Center(
                child: QrImageView(
                  data: seniorData['pair_code'] ?? '000000',
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, true); // Go back to dashboard
            },
            child: const Text('DONE',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
