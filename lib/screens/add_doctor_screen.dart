import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AddDoctorScreen extends StatefulWidget {
  final int seniorId;
  const AddDoctorScreen({Key? key, required this.seniorId}) : super(key: key);

  @override
  State<AddDoctorScreen> createState() => _AddDoctorScreenState();
}

class _AddDoctorScreenState extends State<AddDoctorScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  final _nameController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _specialtyController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await _apiService.createDoctor(
      seniorId: widget.seniorId,
      name: _nameController.text.trim(),
      specialty: _specialtyController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      clinicAddress: _addressController.text.trim(),
      notes: _notesController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Doctor added successfully!'), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: ${result['error'] ?? 'Unknown'}'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Doctor', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2196F3),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Doctor Information',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2196F3)),
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person,
                  validator: (v) => v!.isEmpty ? 'Please enter doctor name' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _specialtyController,
                  label: 'Specialty (e.g. Cardiologist)',
                  icon: Icons.stars,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _addressController,
                  label: 'Clinic Address',
                  icon: Icons.location_on,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _notesController,
                  label: 'Additional Notes',
                  icon: Icons.note,
                  maxLines: 3,
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Doctor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF2196F3)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }
}
