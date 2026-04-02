import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AddContactScreen extends StatefulWidget {
  final int? seniorId;
  const AddContactScreen({Key? key, this.seniorId}) : super(key: key);

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isPrimary = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Emergency Contact', style: TextStyle(fontSize: 24)),
        backgroundColor: const Color(0xFFE53935),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                style: const TextStyle(fontSize: 20),
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person, size: 28),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _relationshipController,
                style: const TextStyle(fontSize: 20),
                decoration: const InputDecoration(
                  labelText: 'Relationship',
                  hintText: 'e.g., Son, Daughter, Doctor',
                  prefixIcon: Icon(Icons.family_restroom, size: 28),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 20),
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone, size: 28),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(fontSize: 20),
                decoration: const InputDecoration(
                  labelText: 'Email (Optional)',
                  prefixIcon: Icon(Icons.email, size: 28),
                ),
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                title: const Text('Primary Contact', style: TextStyle(fontSize: 20)),
                subtitle: const Text('This will be called first in emergencies'),
                value: _isPrimary,
                onChanged: (value) => setState(() => _isPrimary = value),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveContact,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Contact', style: TextStyle(fontSize: 22)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveContact() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final apiService = ApiService();
      final result = await apiService.createEmergencyContact(
        name: _nameController.text.trim(),
        relationship: _relationshipController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        isPrimary: _isPrimary,
        seniorId: widget.seniorId,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (result['success'] == true) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contact added!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add contact: ${result['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _relationshipController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}