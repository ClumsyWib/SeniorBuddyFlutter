import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AddMedicineScreen extends StatefulWidget {
  final int? seniorId;
  const AddMedicineScreen({Key? key, this.seniorId}) : super(key: key);

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();

  String _selectedFrequency = 'daily';
  String _selectedTimeOfDay = 'morning';
  final _instructionsController = TextEditingController();

  DateTime? _startDate = DateTime.now();
  DateTime? _endDate;

  bool _isActive = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? (_startDate ?? DateTime.now()).add(const Duration(days: 30)),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Get senior ID
    final seniorId = widget.seniorId ?? await _apiService.getUserId();
    if (seniorId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login again', style: TextStyle(fontSize: 18)),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    // Format dates for Django (YYYY-MM-DD)
    String? startDateStr;
    String? endDateStr;

    if (_startDate != null) {
      startDateStr = '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}';
    }

    if (_endDate != null) {
      endDateStr = '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}';
    }

    print('🔵 Creating medicine...');
    print('   Senior ID: $seniorId');
    print('   Name: ${_nameController.text}');
    print('   Start Date: $startDateStr');
    print('   End Date: $endDateStr');

    final result = await _apiService.createMedicine(
      seniorId: seniorId,
      medicineName: _nameController.text.trim(),
      dosage: _dosageController.text.trim(),
      frequency: _selectedFrequency,
      timeOfDay: _selectedTimeOfDay,
      instructions: _instructionsController.text.trim().isEmpty
          ? null
          : _instructionsController.text.trim(),
      startDate: startDateStr,
      endDate: endDateStr,
      isActive: _isActive,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      print('🟢 Medicine added successfully!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medicine added successfully!', style: TextStyle(fontSize: 18)),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context, true);
      return;
    }

    // Handle error
    print('🔴 Failed to add medicine: ${result['error']}');
    final err = result['error'];
    String msg = 'Failed to add medicine';

    if (err is Map) {
      final details = <String>[];
      err.forEach((key, value) {
        if (value is List) {
          for (var item in value) {
            details.add('$key: $item');
          }
        } else {
          details.add('$key: $value');
        }
      });
      msg = details.join('\n');
    } else {
      msg = err.toString();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontSize: 16)),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Medicine', style: TextStyle(fontSize: 24)),
        backgroundColor: const Color(0xFFE53935),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),

                // Medicine Name
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(fontSize: 20),
                  decoration: const InputDecoration(
                    labelText: 'Medicine Name',
                    labelStyle: TextStyle(fontSize: 18),
                    prefixIcon: Icon(Icons.medication, size: 28),
                    hintText: 'e.g., Aspirin, Metformin',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Please enter medicine name'
                      : null,
                ),
                const SizedBox(height: 20),

                // Dosage
                TextFormField(
                  controller: _dosageController,
                  style: const TextStyle(fontSize: 20),
                  decoration: const InputDecoration(
                    labelText: 'Dosage',
                    labelStyle: TextStyle(fontSize: 18),
                    prefixIcon: Icon(Icons.medical_services, size: 28),
                    hintText: 'e.g., 500mg, 1 tablet, 5ml',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Please enter dosage'
                      : null,
                ),
                const SizedBox(height: 20),

                // Frequency Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedFrequency,
                  style: const TextStyle(fontSize: 20, color: Colors.black87),
                  decoration: const InputDecoration(
                    labelText: 'How Often',
                    labelStyle: TextStyle(fontSize: 18),
                    prefixIcon: Icon(Icons.schedule, size: 28),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'daily', child: Text('Once Daily')),
                    DropdownMenuItem(value: 'twice_daily', child: Text('Twice Daily')),
                    DropdownMenuItem(value: 'three_times_daily', child: Text('Three Times Daily')),
                    DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                    DropdownMenuItem(value: 'as_needed', child: Text('As Needed')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedFrequency = value);
                  },
                ),
                const SizedBox(height: 20),

                // Time of Day Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedTimeOfDay,
                  style: const TextStyle(fontSize: 20, color: Colors.black87),
                  decoration: const InputDecoration(
                    labelText: 'When to Take',
                    labelStyle: TextStyle(fontSize: 18),
                    prefixIcon: Icon(Icons.access_time, size: 28),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'morning', child: Text('Morning')),
                    DropdownMenuItem(value: 'afternoon', child: Text('Afternoon')),
                    DropdownMenuItem(value: 'evening', child: Text('Evening')),
                    DropdownMenuItem(value: 'night', child: Text('Night')),
                    DropdownMenuItem(value: 'with_meals', child: Text('With Meals')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedTimeOfDay = value);
                  },
                ),
                const SizedBox(height: 20),

                // Start Date
                Card(
                  elevation: 2,
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today, size: 28, color: Color(0xFFE53935)),
                    title: const Text('Start Date', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      _startDate == null
                          ? 'Tap to select start date'
                          : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
                      style: const TextStyle(fontSize: 18, color: Colors.black87),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 20),
                    onTap: _pickStartDate,
                  ),
                ),
                const SizedBox(height: 16),

                // End Date
                Card(
                  elevation: 2,
                  child: ListTile(
                    leading: const Icon(Icons.event, size: 28, color: Color(0xFFE53935)),
                    title: const Text('End Date (Optional)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      _endDate == null
                          ? 'Tap to select end date'
                          : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                      style: const TextStyle(fontSize: 18, color: Colors.black87),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 20),
                    onTap: _pickEndDate,
                  ),
                ),
                const SizedBox(height: 20),

                // Instructions
                TextFormField(
                  controller: _instructionsController,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 18),
                  decoration: const InputDecoration(
                    labelText: 'Special Instructions (Optional)',
                    labelStyle: TextStyle(fontSize: 18),
                    prefixIcon: Icon(Icons.info_outline, size: 28),
                    hintText: 'e.g., Take with food, avoid alcohol',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),

                // Active Switch
                Card(
                  elevation: 2,
                  child: SwitchListTile(
                    title: const Text('Active', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Currently taking this medicine', style: TextStyle(fontSize: 16)),
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                    activeColor: const Color(0xFFE53935),
                  ),
                ),
                const SizedBox(height: 32),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                      : const Text(
                    'Add Medicine',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}