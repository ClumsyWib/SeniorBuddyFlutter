import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EditAppointmentScreen extends StatefulWidget {
  final Map<String, dynamic> appointment;

  const EditAppointmentScreen({Key? key, required this.appointment})
      : super(key: key);

  @override
  State<EditAppointmentScreen> createState() => _EditAppointmentScreenState();
}

class _EditAppointmentScreenState extends State<EditAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _doctorController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedType = 'doctor';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  bool _isLoading = false;

  int? get _appointmentId {
    final id = widget.appointment['id'];
    if (id is int) return id;
    if (id is String) return int.tryParse(id);
    return null;
  }

  static String _formatDateDisplay(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  static String _formatTime12hr(TimeOfDay t) {
    final h24 = t.hour;
    final h12 = h24 == 0 ? 12 : (h24 > 12 ? h24 - 12 : h24);
    final m = t.minute.toString().padLeft(2, '0');
    final ampm = h24 < 12 ? 'AM' : 'PM';
    return '$h12:$m $ampm';
  }

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.appointment['title']?.toString() ?? '';
    _locationController.text = widget.appointment['location']?.toString() ?? '';
    _doctorController.text = widget.appointment['doctor_name']?.toString() ?? '';
    _descriptionController.text = widget.appointment['description']?.toString() ?? '';
    _selectedType = widget.appointment['appointment_type']?.toString() ?? 'doctor';

    final dateStr = widget.appointment['appointment_date']?.toString();
    if (dateStr != null && dateStr.isNotEmpty) {
      final parts = dateStr.split('-');
      if (parts.length >= 3) {
        _selectedDate = DateTime(
          int.tryParse(parts[0]) ?? DateTime.now().year,
          int.tryParse(parts[1]) ?? DateTime.now().month,
          int.tryParse(parts[2]) ?? DateTime.now().day,
        );
      }
    }
    final timeStr = widget.appointment['appointment_time']?.toString();
    if (timeStr != null && timeStr.isNotEmpty) {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        _selectedTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 10,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _doctorController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveAppointment() async {
    if (!_formKey.currentState!.validate() || _appointmentId == null) return;
    setState(() => _isLoading = true);

    final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    final timeStr = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}:00';

    final result = await _apiService.updateAppointment(_appointmentId!, 
      title: _titleController.text.trim(),
      appointmentType: _selectedType,
      appointmentDate: dateStr,
      appointmentTime: timeStr,
      location: _locationController.text.trim(),
      doctorName: _doctorController.text.trim().isEmpty ? null : _doctorController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment updated'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, result['data']);
      return;
    }
    final err = result['error'];
    final msg = err is Map ? (err['detail'] ?? err['message'] ?? 'Update failed').toString() : err.toString();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Appointment'),
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
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title', prefixIcon: Icon(Icons.title)),
                  validator: (v) => v == null || v.isEmpty ? 'Enter title' : null,
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: const InputDecoration(labelText: 'Type', prefixIcon: Icon(Icons.category)),
                  items: const [
                    DropdownMenuItem(value: 'doctor', child: Text('Doctor Visit')),
                    DropdownMenuItem(value: 'medicine', child: Text('Medicine Checkup')),
                    DropdownMenuItem(value: 'therapy', child: Text('Therapy Session')),
                    DropdownMenuItem(value: 'checkup', child: Text('Regular Checkup')),
                    DropdownMenuItem(value: 'emergency', child: Text('Emergency')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (v) => setState(() => _selectedType = v ?? 'doctor'),
                ),
                const SizedBox(height: 20),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today, color: Color(0xFF4CAF50)),
                  title: const Text('Date'),
                  subtitle: Text(_formatDateDisplay(_selectedDate)),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (d != null) setState(() => _selectedDate = d);
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time, color: Color(0xFF4CAF50)),
                  title: const Text('Time'),
                  subtitle: Text(_formatTime12hr(_selectedTime)),
                  onTap: () async {
                    final t = await showTimePicker(context: context, initialTime: _selectedTime);
                    if (t != null) setState(() => _selectedTime = t);
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'Location', prefixIcon: Icon(Icons.location_on)),
                  validator: (v) => v == null || v.isEmpty ? 'Enter location' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _doctorController,
                  decoration: const InputDecoration(labelText: 'Doctor (optional)', prefixIcon: Icon(Icons.person)),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Notes (optional)', prefixIcon: Icon(Icons.notes)),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveAppointment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Changes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
