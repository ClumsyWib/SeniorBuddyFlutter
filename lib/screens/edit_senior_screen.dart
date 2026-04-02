import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class EditSeniorScreen extends StatefulWidget {
  final Map<String, dynamic> senior;
  const EditSeniorScreen({Key? key, required this.senior}) : super(key: key);

  @override
  State<EditSeniorScreen> createState() => _EditSeniorScreenState();
}

class _EditSeniorScreenState extends State<EditSeniorScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _medicalInfoController;
  late TextEditingController _medicalConditionsController;
  late TextEditingController _allergiesController;
  late TextEditingController _routineController;
  late TextEditingController _mobilityController;
  late TextEditingController _careLevelController;
  late TextEditingController _doctorController;
  late TextEditingController _doctorPhoneController;
  late TextEditingController _emergencyContactController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;

  String _gender = 'Male';
  bool _isSaving = false;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.senior['name'] ?? '');
    _ageController = TextEditingController(text: widget.senior['age']?.toString() ?? '');
    
    // Normalize gender to match dropdown items (Male, Female, Other)
    String genderRaw = (widget.senior['gender'] ?? 'Male').toString().trim().toLowerCase();
    if (genderRaw == 'female') {
      _gender = 'Female';
    } else if (genderRaw == 'other') {
      _gender = 'Other';
    } else {
      _gender = 'Male';
    }

    _medicalInfoController = TextEditingController(text: widget.senior['medical_info'] ?? '');
    _medicalConditionsController = TextEditingController(text: widget.senior['medical_conditions'] ?? '');
    _allergiesController = TextEditingController(text: widget.senior['allergies'] ?? '');
    _routineController = TextEditingController(text: widget.senior['daily_routine'] ?? '');
    _mobilityController = TextEditingController(text: widget.senior['mobility_status'] ?? '');
    _careLevelController = TextEditingController(text: widget.senior['care_level'] ?? '');
    _doctorController = TextEditingController(text: widget.senior['primary_doctor'] ?? '');
    _doctorPhoneController = TextEditingController(text: widget.senior['doctor_phone'] ?? '');
    _emergencyContactController = TextEditingController(text: widget.senior['emergency_contact'] ?? '');
    _addressController = TextEditingController(text: widget.senior['address'] ?? '');
    _cityController = TextEditingController(text: widget.senior['city'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _medicalInfoController.dispose();
    _medicalConditionsController.dispose();
    _allergiesController.dispose();
    _routineController.dispose();
    _mobilityController.dispose();
    _careLevelController.dispose();
    _doctorController.dispose();
    _doctorPhoneController.dispose();
    _emergencyContactController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final Map<String, dynamic> data = {
        'name': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text) ?? 0,
        'gender': _gender,
        'medical_info': _medicalInfoController.text.trim(),
        'medical_conditions': _medicalConditionsController.text.trim(),
        'allergies': _allergiesController.text.trim(),
        'daily_routine': _routineController.text.trim(),
        'mobility_status': _mobilityController.text.trim(),
        'care_level': _careLevelController.text.trim(),
        'primary_doctor': _doctorController.text.trim(),
        'doctor_phone': _doctorPhoneController.text.trim(),
        'emergency_contact': _emergencyContactController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
      };

      // Photo upload is now handled in updateSeniorProfile
      final result = await _apiService.updateSeniorProfile(widget.senior['id'], data, photoFile: _imageFile);

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Senior profile updated!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception(result['error'] ?? 'Failed to update');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF43A047);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Senior Profile'),
        backgroundColor: primaryColor,
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Section
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : (widget.senior['photo'] != null
                          ? NetworkImage(widget.senior['photo']) as ImageProvider
                          : null),
                      child: (_imageFile == null && widget.senior['photo'] == null)
                          ? const Icon(Icons.person, size: 60, color: Colors.grey)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: primaryColor,
                        radius: 18,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              _buildSectionTitle('Basic Information'),
              const SizedBox(height: 16),
              _buildTextField(_nameController, 'Full Name', Icons.person_outline),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField(_ageController, 'Age', Icons.calendar_today, keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        prefixIcon: const Icon(Icons.wc_outlined, color: Colors.grey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                      onChanged: (val) => setState(() => _gender = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              _buildSectionTitle('Medical Details'),
              const SizedBox(height: 16),
              _buildTextField(_medicalInfoController, 'Health Summary', Icons.summarize_outlined, maxLines: 2),
              const SizedBox(height: 16),
              _buildTextField(_medicalConditionsController, 'Medical Conditions', Icons.medical_services_outlined, maxLines: 2),
              const SizedBox(height: 16),
              _buildTextField(_allergiesController, 'Allergies', Icons.warning_amber_outlined),
              const SizedBox(height: 16),
              _buildTextField(_emergencyContactController, 'Emergency Contact Phone', Icons.emergency_outlined, keyboardType: TextInputType.phone),
              const SizedBox(height: 32),

              _buildSectionTitle('Location & Contact'),
              const SizedBox(height: 16),
              _buildTextField(_cityController, 'City', Icons.location_city_outlined),
              const SizedBox(height: 16),
              _buildTextField(_addressController, 'Full Address', Icons.home_outlined, maxLines: 2),
              const SizedBox(height: 32),

              _buildSectionTitle('Healthcare Providers'),
              const SizedBox(height: 16),
              _buildTextField(_doctorController, 'Primary Doctor Name', Icons.person_add_alt_1_outlined),
              const SizedBox(height: 16),
              _buildTextField(_doctorPhoneController, 'Doctor Phone Number', Icons.phone_callback_outlined, keyboardType: TextInputType.phone),
              const SizedBox(height: 32),

              _buildSectionTitle('Daily Care'),
              const SizedBox(height: 16),
              _buildTextField(_routineController, 'Daily Routine', Icons.schedule_outlined, maxLines: 2),
              const SizedBox(height: 16),
              _buildTextField(_mobilityController, 'Mobility Status', Icons.directions_walk_outlined),
              const SizedBox(height: 16),
              _buildTextField(_careLevelController, 'Care Level', Icons.health_and_safety_outlined),
              
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _saveProfile,
                  child: const Text('Save Changes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
    );
  }
}
