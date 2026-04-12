import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../utils/role_helper.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const EditProfileScreen({Key? key, required this.userData}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  // Common User Fields
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _zipController;
  late TextEditingController _dobController;
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyPhoneController;

  // Role-Specific Fields
  Map<String, dynamic>? _roleProfileData;
  late TextEditingController _caretakerExperienceController;
  late TextEditingController _caretakerSkillsController;
  late TextEditingController _caretakerRateController;
  late TextEditingController _caretakerBioController;
  late TextEditingController _caretakerSpecializationController;
  String _caretakerAvailabilityStatus = 'Full-time';
  bool _caretakerIsAvailable = true;

  late TextEditingController _volunteerSkillsController;
  late TextEditingController _volunteerBioController;
  late TextEditingController _volunteerSpecializationController;
  String _volunteerAvailabilityStatus = 'Part-time';
  bool _volunteerIsAvailable = true;

  late TextEditingController _seniorAgeController;
  late TextEditingController _seniorMedicalController;
  late TextEditingController _seniorAllergiesController;
  late TextEditingController _seniorRoutineController;
  late TextEditingController _seniorMobilityController;
  late TextEditingController _seniorCareLevelController;
  late TextEditingController _seniorDoctorController;
  late TextEditingController _seniorDoctorPhoneController;
  String _seniorGender = 'Male';

  bool _isSaving = false;
  bool _isLoadingRoleData = false;
  File? _imageFile;
  DateTime? _selectedDate;
  late String _userRole;

  @override
  void initState() {
    super.initState();
    _userRole = widget.userData['user_type'] ?? kRoleFamily;

    // Initialize common controllers
    _firstNameController =
        TextEditingController(text: widget.userData['first_name'] ?? '');
    _lastNameController =
        TextEditingController(text: widget.userData['last_name'] ?? '');
    _emailController =
        TextEditingController(text: widget.userData['email'] ?? '');
    _phoneController =
        TextEditingController(text: widget.userData['phone_number'] ?? '');
    _addressController =
        TextEditingController(text: widget.userData['address'] ?? '');
    _cityController =
        TextEditingController(text: widget.userData['city'] ?? '');
    _stateController =
        TextEditingController(text: widget.userData['state'] ?? '');
    _zipController =
        TextEditingController(text: widget.userData['zip_code'] ?? '');
    _dobController =
        TextEditingController(text: widget.userData['date_of_birth'] ?? '');
    _emergencyNameController = TextEditingController(
        text: widget.userData['emergency_contact_name'] ?? '');
    _emergencyPhoneController = TextEditingController(
        text: widget.userData['emergency_contact_phone'] ?? '');

    // Initialize role-specific controllers
    _caretakerExperienceController = TextEditingController();
    _caretakerSkillsController = TextEditingController();
    _caretakerRateController = TextEditingController();
    _caretakerBioController = TextEditingController();
    _caretakerSpecializationController = TextEditingController();

    _seniorAgeController = TextEditingController();
    _seniorMedicalController = TextEditingController();
    _seniorAllergiesController = TextEditingController();
    _seniorRoutineController = TextEditingController();
    _seniorMobilityController = TextEditingController();
    _seniorCareLevelController = TextEditingController();
    _seniorDoctorController = TextEditingController();
    _seniorDoctorPhoneController = TextEditingController();

    _volunteerSkillsController = TextEditingController();
    _volunteerBioController = TextEditingController();
    _volunteerSpecializationController = TextEditingController();

    if (widget.userData['date_of_birth'] != null) {
      try {
        _selectedDate = DateTime.parse(widget.userData['date_of_birth']);
      } catch (_) {}
    }

    _loadRoleProfile();
  }

  Future<void> _loadRoleProfile() async {
    if (_userRole == kRoleFamily) return;

    if (mounted) setState(() => _isLoadingRoleData = true);

    try {
      Map<String, dynamic> result = {'success': false};

      if (_userRole == kRoleCaretaker) {
        result = await _apiService.getCaretakerProfile();
        if (result['success']) {
          _roleProfileData = result['data'];
          _caretakerExperienceController.text =
              _roleProfileData?['experience_years']?.toString() ?? '0';
          _caretakerSkillsController.text = _roleProfileData?['skills'] ?? '';
          _caretakerRateController.text =
              _roleProfileData?['hourly_rate']?.toString() ?? '0.00';
          _caretakerBioController.text = _roleProfileData?['bio'] ?? '';
          _caretakerSpecializationController.text =
              _roleProfileData?['specialization'] ?? '';
          _caretakerAvailabilityStatus =
              _roleProfileData?['availability_status'] ?? 'Full-time';
          _caretakerIsAvailable = _roleProfileData?['is_available'] ?? true;
        }
      } else if (_userRole == kRoleSenior) {
        // Seniors might not have a "me" profile directly if using family token,
        // but let's assume getSeniorProfile works if we have the senior_id from storage.
        final seniorId = await _apiService.getSeniorId();
        if (seniorId != null) {
          result = await _apiService.getSeniorProfile(seniorId);
          if (result['success']) {
            _roleProfileData = result['data'];
            _firstNameController.text = _roleProfileData?['name'] ?? '';
            _seniorAgeController.text =
                _roleProfileData?['age']?.toString() ?? '';
            _seniorGender = _roleProfileData?['gender'] ?? 'Male';
            _seniorMedicalController.text =
                _roleProfileData?['medical_conditions'] ?? '';
            _seniorAllergiesController.text =
                _roleProfileData?['allergies'] ?? '';
            _seniorRoutineController.text =
                _roleProfileData?['daily_routine'] ?? '';
            _seniorMobilityController.text =
                _roleProfileData?['mobility_status'] ?? '';
            _seniorCareLevelController.text =
                _roleProfileData?['care_level'] ?? '';
            _seniorDoctorController.text =
                _roleProfileData?['primary_doctor'] ?? '';
            _seniorDoctorPhoneController.text =
                _roleProfileData?['doctor_phone'] ?? '';
          }
        }
      } else if (_userRole == kRoleVolunteer) {
        result = await _apiService.getVolunteerProfile();
        if (result['success']) {
          _roleProfileData = result['data'];
          _volunteerSkillsController.text = _roleProfileData?['skills'] ?? '';
          _volunteerBioController.text = _roleProfileData?['bio'] ?? '';
          _volunteerSpecializationController.text =
              _roleProfileData?['specialization'] ?? '';
          _volunteerAvailabilityStatus =
              _roleProfileData?['availability_status'] ?? 'Part-time';
          _volunteerIsAvailable = _roleProfileData?['is_available'] ?? true;
        }
      }
    } finally {
      if (mounted) setState(() => _isLoadingRoleData = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _dobController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();

    _caretakerExperienceController.dispose();
    _caretakerSkillsController.dispose();
    _caretakerRateController.dispose();
    _caretakerBioController.dispose();
    _caretakerSpecializationController.dispose();

    _seniorAgeController.dispose();
    _seniorMedicalController.dispose();
    _seniorAllergiesController.dispose();
    _seniorRoutineController.dispose();
    _seniorMobilityController.dispose();
    _seniorCareLevelController.dispose();
    _seniorDoctorController.dispose();
    _seniorDoctorPhoneController.dispose();

    _volunteerSkillsController.dispose();
    _volunteerBioController.dispose();
    _volunteerSpecializationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // 1. Update general user profile (All roles except Senior)
      if (_userRole != kRoleSenior) {
        final result = await _apiService.updateProfile(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          zipCode: _zipController.text.trim(),
          dateOfBirth: _dobController.text.trim(),
          emergencyContactName: _emergencyNameController.text.trim(),
          emergencyContactPhone: _emergencyPhoneController.text.trim(),
        );

        if (!result['success']) {
          throw Exception(result['error'] ?? 'Failed to update user profile');
        }
      }

      // 2. Update role-specific profile
      if (_userRole == kRoleCaretaker) {
        final cResult = await _apiService.updateCaretakerProfile({
          'experience_years':
              int.tryParse(_caretakerExperienceController.text) ?? 0,
          'skills': _caretakerSkillsController.text.trim(),
          'hourly_rate': double.tryParse(_caretakerRateController.text) ?? 0.0,
          'is_available': _caretakerIsAvailable,
          'bio': _caretakerBioController.text.trim(),
          'specialization': _caretakerSpecializationController.text.trim(),
          'availability_status': _caretakerAvailabilityStatus,
        });
        if (!cResult['success']) {
          throw Exception(
              cResult['error'] ?? 'Failed to update caretaker details');
        }
      } else if (_userRole == kRoleVolunteer) {
        final vResult = await _apiService.updateVolunteerProfile({
          'skills': _volunteerSkillsController.text.trim(),
          'is_available': _volunteerIsAvailable,
          'bio': _volunteerBioController.text.trim(),
          'specialization': _volunteerSpecializationController.text.trim(),
          'availability_status': _volunteerAvailabilityStatus,
        });
        if (!vResult['success']) {
          throw Exception(
              vResult['error'] ?? 'Failed to update volunteer details');
        }
      } else if (_userRole == kRoleSenior && _roleProfileData != null) {
        final seniorId = _roleProfileData!['id'];
        final sResult = await _apiService.updateSeniorProfile(seniorId, {
          'name': _firstNameController.text
              .trim(), // Senior name comes from the 'Full Name' field we mapped to _firstNameController
          'age': int.tryParse(_seniorAgeController.text) ?? 0,
          'gender': _seniorGender,
          'medical_conditions': _seniorMedicalController.text.trim(),
          'allergies': _seniorAllergiesController.text.trim(),
          'daily_routine': _seniorRoutineController.text.trim(),
          'mobility_status': _seniorMobilityController.text.trim(),
          'care_level': _seniorCareLevelController.text.trim(),
          'primary_doctor': _seniorDoctorController.text.trim(),
          'doctor_phone': _seniorDoctorPhoneController.text.trim(),
        });
        if (!sResult['success']) {
          throw Exception(
              sResult['error'] ?? 'Failed to update senior details');
        }
      }

      // 3. Update photo if selected (only if it's a User profile, Seniors handled via senior profile photo if implemented, but here we use User profile_picture if available)
      if (_imageFile != null) {
        if (_userRole != kRoleSenior) {
          final photoResult =
              await _apiService.updateProfilePicture(_imageFile!.path);
          if (!photoResult['success']) {
            throw Exception(photoResult['error'] ?? 'Failed to upload photo');
          }
        }
        // Note: For Senior photo, we might need a separate endpoint if SeniorProfile has its own image field.
        // Currently, SeniorProfile doesn't seem to have one, they use the family's assets or placeholders.
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: (_isSaving || _isLoadingRoleData)
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Profile Photo
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!)
                                : (widget.userData['profile_picture'] != null
                                    ? NetworkImage(
                                            widget.userData['profile_picture'])
                                        as ImageProvider
                                    : null),
                            child: (_imageFile == null &&
                                    widget.userData['profile_picture'] == null)
                                ? const Icon(Icons.person,
                                    size: 60, color: Colors.grey)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              backgroundColor: primaryColor,
                              radius: 18,
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt,
                                    size: 18, color: Colors.white),
                                onPressed: _pickImage,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 1. Personal Information (Base User Fields)
                    // HIDDEN FOR SENIORS - strictly follow Django SeniorProfile
                    if (_userRole != kRoleSenior) ...[
                      _buildSectionTitle('Personal Information'),
                      const SizedBox(height: 16),
                      _buildTextField(_firstNameController, 'First Name',
                          Icons.person_outline),
                      const SizedBox(height: 16),
                      _buildTextField(_lastNameController, 'Last Name',
                          Icons.person_outline),
                      const SizedBox(height: 16),
                      _buildTextField(_emailController, 'Email Address',
                          Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 16),
                      _buildTextField(_phoneController, 'Phone Number',
                          Icons.phone_outlined,
                          keyboardType: TextInputType.phone),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () => _selectDate(context),
                        child: IgnorePointer(
                          child: _buildTextField(_dobController,
                              'Date of Birth', Icons.cake_outlined),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // 2. Role-Specific Info
                    if (_userRole == kRoleCaretaker) ...[
                      _buildSectionTitle('Caretaker Details'),
                      const SizedBox(height: 16),
                      _buildTextField(_caretakerSpecializationController,
                          'Specialization', Icons.workspace_premium_outlined),
                      const SizedBox(height: 16),
                      _buildTextField(_caretakerExperienceController,
                          'Experience (Years)', Icons.history,
                          keyboardType: TextInputType.number),
                      const SizedBox(height: 16),
                      _buildTextField(_caretakerRateController,
                          'Hourly Rate ()', Icons.payments_outlined,
                          keyboardType: TextInputType.number),
                      const SizedBox(height: 16),
                      _buildTextField(_caretakerSkillsController, 'Skills',
                          Icons.psychology_outlined),
                      const SizedBox(height: 16),
                      _buildTextField(_caretakerBioController, 'Biography',
                          Icons.description_outlined,
                          maxLines: 4),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _caretakerAvailabilityStatus,
                        decoration: InputDecoration(
                          labelText: 'Availability Status',
                          prefixIcon: const Icon(Icons.event_available,
                              color: Colors.grey),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          fillColor: Colors.grey[50],
                          filled: true,
                        ),
                        items: ['Full-time', 'Part-time', 'Contract']
                            .map((s) =>
                                DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _caretakerAvailabilityStatus = val!),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('Available for Work',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: const Text('Toggle your working status'),
                        value: _caretakerIsAvailable,
                        activeColor: primaryColor,
                        onChanged: (val) =>
                            setState(() => _caretakerIsAvailable = val),
                      ),
                      const SizedBox(height: 32),
                    ],

                    if (_userRole == kRoleVolunteer) ...[
                      _buildSectionTitle('Volunteer Details'),
                      const SizedBox(height: 16),
                      _buildTextField(
                          _volunteerSpecializationController,
                          'Specialization/Role',
                          Icons.workspace_premium_outlined),
                      const SizedBox(height: 16),
                      _buildTextField(_volunteerSkillsController, 'Skills',
                          Icons.psychology_outlined),
                      const SizedBox(height: 16),
                      _buildTextField(_volunteerBioController, 'Biography',
                          Icons.description_outlined,
                          maxLines: 4),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _volunteerAvailabilityStatus,
                        decoration: InputDecoration(
                          labelText: 'Availability',
                          prefixIcon: const Icon(Icons.event_available,
                              color: Colors.grey),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          fillColor: Colors.grey[50],
                          filled: true,
                        ),
                        items: ['Full-time', 'Part-time', 'Flexible']
                            .map((s) =>
                                DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _volunteerAvailabilityStatus = val!),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('Active Volunteer',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: const Text('Toggle availability'),
                        value: _volunteerIsAvailable,
                        activeColor: primaryColor,
                        onChanged: (val) =>
                            setState(() => _volunteerIsAvailable = val),
                      ),
                      const SizedBox(height: 32),
                    ],

                    if (_userRole == kRoleSenior) ...[
                      _buildSectionTitle('Senior Profile'),
                      const SizedBox(height: 16),
                      _buildTextField(
                          _firstNameController,
                          'Full Name',
                          Icons
                              .person_outline), // Using firstName field for Senior name
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                              child: _buildTextField(_seniorAgeController,
                                  'Age', Icons.calendar_today,
                                  keyboardType: TextInputType.number)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _seniorGender,
                              decoration: InputDecoration(
                                labelText: 'Gender',
                                prefixIcon: const Icon(Icons.wc_outlined,
                                    color: Colors.grey),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                fillColor: Colors.grey[50],
                                filled: true,
                              ),
                              items: ['Male', 'Female', 'Other']
                                  .map((g) => DropdownMenuItem(
                                      value: g, child: Text(g)))
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _seniorGender = val!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(_seniorMedicalController,
                          'Medical Conditions', Icons.medical_services_outlined,
                          maxLines: 2),
                      const SizedBox(height: 16),
                      _buildTextField(_seniorAllergiesController, 'Allergies',
                          Icons.warning_amber_outlined),
                      const SizedBox(height: 16),
                      _buildTextField(_seniorRoutineController, 'Daily Routine',
                          Icons.schedule_outlined,
                          maxLines: 2),
                      const SizedBox(height: 16),
                      _buildTextField(_seniorMobilityController,
                          'Mobility Status', Icons.directions_walk_outlined),
                      const SizedBox(height: 16),
                      _buildTextField(_seniorCareLevelController, 'Care Level',
                          Icons.health_and_safety_outlined),
                      const SizedBox(height: 16),
                      _buildTextField(_seniorDoctorController, 'Primary Doctor',
                          Icons.person_add_alt_1_outlined),
                      const SizedBox(height: 16),
                      _buildTextField(_seniorDoctorPhoneController,
                          'Doctor Phone', Icons.phone_callback_outlined,
                          keyboardType: TextInputType.phone),
                      const SizedBox(height: 32),
                    ],

                    // 3. Address & Emergency (User Fields)
                    if (_userRole != kRoleSenior) ...[
                      _buildSectionTitle('Contact Details'),
                      const SizedBox(height: 16),
                      _buildTextField(_addressController, 'Address',
                          Icons.location_on_outlined),
                      const SizedBox(height: 16),
                      _buildTextField(_cityController, 'City',
                          Icons.location_city_outlined),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                              child: _buildTextField(_stateController, 'State',
                                  Icons.map_outlined)),
                          const SizedBox(width: 16),
                          Expanded(
                              child: _buildTextField(_zipController, 'Zip Code',
                                  Icons.pin_drop_outlined,
                                  keyboardType: TextInputType.number)),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _buildSectionTitle('Emergency Contact'),
                      const SizedBox(height: 16),
                      _buildTextField(_emergencyNameController, 'Contact Name',
                          Icons.contact_emergency_outlined),
                      const SizedBox(height: 16),
                      _buildTextField(_emergencyPhoneController,
                          'Contact Phone', Icons.phone_callback_outlined,
                          keyboardType: TextInputType.phone),
                      const SizedBox(height: 32),
                    ],

                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        onPressed: _saveProfile,
                        child: const Text('Save Changes',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Color _getRoleColor() {
    switch (_userRole) {
      case kRoleFamily:
        return const Color(0xFF43A047);
      case kRoleCaretaker:
        return const Color(0xFF1976D2);
      case kRoleSenior:
        return const Color(0xFF8E24AA);
      case kRoleVolunteer:
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF43A047);
    }
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E)),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {TextInputType? keyboardType, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (val) =>
          (val == null || val.isEmpty) ? 'Please enter $label' : null,
    );
  }
}
