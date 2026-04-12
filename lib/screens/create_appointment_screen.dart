import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CreateAppointmentScreen extends StatefulWidget {
  final int seniorId;
  final Map<String, dynamic>? appointment; // If provided, we are in Edit Mode

  const CreateAppointmentScreen({Key? key, required this.seniorId, this.appointment})
      : super(key: key);

  @override
  State<CreateAppointmentScreen> createState() =>
      _CreateAppointmentScreenState();
}

class _CreateAppointmentScreenState extends State<CreateAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedType = 'doctor';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;
  bool _isEditMode = false;

  // Doctor dropdown state
  List<dynamic> _doctors = [];
  bool _isDoctorsLoading = true;
  int? _selectedDoctorId; // Use int ID to avoid Map equality issues

  @override
  void initState() {
    super.initState();
    _loadDoctors();

    if (widget.appointment != null) {
      _isEditMode = true;
      _titleController.text = widget.appointment!['title'] ?? '';
      _selectedType = widget.appointment!['appointment_type'] ?? 'doctor';
      _locationController.text = widget.appointment!['location'] ?? '';
      _descriptionController.text = widget.appointment!['description'] ?? '';

      if (widget.appointment!['appointment_date'] != null) {
        _selectedDate =
            DateTime.tryParse(widget.appointment!['appointment_date']) ??
                DateTime.now();
      }

      if (widget.appointment!['appointment_time'] != null) {
        final timeParts = widget.appointment!['appointment_time'].split(':');
        if (timeParts.length >= 2) {
          _selectedTime = TimeOfDay(
            hour: int.parse(timeParts[0]),
            minute: int.parse(timeParts[1]),
          );
        }
      }

      // We might not have the doctor ID directly, but let's try to match it once doctors load
    }
  }

  Future<void> _loadDoctors() async {
    setState(() => _isDoctorsLoading = true);
    final result = await _apiService.getDoctors(seniorId: widget.seniorId);
    if (mounted) {
      setState(() {
        if (result['success']) {
          _doctors = result['data'];
          
          // If in edit mode, try to find the doctor if doctor_name is provided
          if (_isEditMode && widget.appointment!['doctor_name'] != null) {
             final docName = widget.appointment!['doctor_name'].toString().replaceFirst('Dr. ', '');
             final matchedDoc = _doctors.firstWhere(
               (d) => (d['name'] ?? '').toString().contains(docName),
               orElse: () => null,
             );
             if (matchedDoc != null) {
               _selectedDoctorId = matchedDoc['id'];
             }
          }
        }
        _isDoctorsLoading = false;
      });
    }
  }

  /// Indian 12-hour format: e.g. 10:30 AM, 2:45 PM
  static String formatTime12hr(TimeOfDay t) {
    final h24 = t.hour;
    final h12 = h24 == 0 ? 12 : (h24 > 12 ? h24 - 12 : h24);
    final m = t.minute.toString().padLeft(2, '0');
    final ampm = h24 < 12 ? 'AM' : 'PM';
    return '$h12:$m $ampm';
  }

  /// DD/MM/YYYY for date display
  static String formatDateDisplay(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createAppointment() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Format date and time for Django
      final dateStr =
          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      final timeStr =
          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}:00';

      print('🔵 Creating appointment...');
      print('   Senior ID: ${widget.seniorId}');
      print('   Date: $dateStr');
      print('   Time: $timeStr');

      String? doctorName;
      if (_selectedDoctorId != null) {
        final doc = _doctors.firstWhere(
          (d) => d['id'] == _selectedDoctorId,
          orElse: () => null,
        );
        if (doc != null) doctorName = 'Dr. ${doc['name']}';
      }

      final result = _isEditMode
          ? await _apiService.updateAppointment(
              widget.appointment!['id'],
              title: _titleController.text,
              appointmentType: _selectedType,
              appointmentDate: dateStr,
              appointmentTime: timeStr,
              location: _locationController.text,
              doctorName: doctorName,
              description: _descriptionController.text.isEmpty
                  ? null
                  : _descriptionController.text,
            )
          : await _apiService.createAppointment(
              seniorId: widget.seniorId,
              title: _titleController.text,
              appointmentType: _selectedType,
              appointmentDate: dateStr,
              appointmentTime: timeStr,
              location: _locationController.text,
              doctorName: doctorName,
              description: _descriptionController.text.isEmpty
                  ? null
                  : _descriptionController.text,
            );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result['success']) {
          final modeStr = _isEditMode ? 'updated' : 'created';
          print('🟢 Appointment $modeStr successfully!');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Appointment $modeStr successfully!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          Navigator.pop(context, true); // Return true to indicate success
        } else {
          print('🔴 Failed to create appointment: ${result['error']}');

          String errorMessage = 'Failed to create appointment. ';
          if (result['error'] is Map) {
            final errors = result['error'] as Map;
            errors.forEach((key, value) {
              if (value is List) {
                errorMessage += '${value.join(", ")} ';
              } else {
                errorMessage += '$value ';
              }
            });
          } else {
            errorMessage += result['error'].toString();
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Appointment' : 'Create Appointment'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),

                // Appointment Title
                TextFormField(
                  controller: _titleController,
                  style: const TextStyle(fontSize: 18),
                  decoration: const InputDecoration(
                    labelText: 'Appointment Title',
                    labelStyle: TextStyle(fontSize: 18),
                    hintText: 'e.g., Doctor Checkup',
                    prefixIcon: Icon(Icons.title, size: 28),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter appointment title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Appointment Type
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  style: const TextStyle(fontSize: 18, color: Colors.black87),
                  decoration: const InputDecoration(
                    labelText: 'Appointment Type',
                    labelStyle: TextStyle(fontSize: 18),
                    prefixIcon: Icon(Icons.category, size: 28),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'doctor', child: Text('Doctor Visit')),
                    DropdownMenuItem(
                        value: 'medicine', child: Text('Medicine Checkup')),
                    DropdownMenuItem(
                        value: 'therapy', child: Text('Therapy Session')),
                    DropdownMenuItem(
                        value: 'checkup', child: Text('Regular Checkup')),
                    DropdownMenuItem(
                        value: 'emergency', child: Text('Emergency')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                    });
                  },
                ),
                const SizedBox(height: 20),

                // Date Selection (default: today; display DD/MM/YYYY)
                Card(
                  elevation: 2,
                  child: ListTile(
                    leading: Icon(Icons.calendar_today,
                        size: 28, color: Theme.of(context).primaryColor),
                    title: const Text('Date',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      formatDateDisplay(_selectedDate),
                      style:
                          const TextStyle(fontSize: 18, color: Colors.black87),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 20),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          _selectedDate = date;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Time Selection (default: current time; display 12-hour e.g. 10:30 AM)
                Card(
                  elevation: 2,
                  child: ListTile(
                    leading: Icon(Icons.access_time,
                        size: 28, color: Theme.of(context).primaryColor),
                    title: const Text('Time',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      formatTime12hr(_selectedTime),
                      style:
                          const TextStyle(fontSize: 18, color: Colors.black87),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 20),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime,
                      );
                      if (time != null) {
                        setState(() {
                          _selectedTime = time;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Doctor Name Selection (Scrollable List, shows 3 items)
                const Text(
                  'Select Doctor (Optional)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                _isDoctorsLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Container(
                        height: 180, // Height for approx 3 items
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade50,
                        ),
                        child: _doctors.isEmpty
                            ? const Center(child: Text('No doctors available'))
                            : Scrollbar(
                                thumbVisibility: true,
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  itemCount: _doctors.length + 1,
                                  itemBuilder: (context, index) {
                                    if (index == 0) {
                                      // "No Doctor" option
                                      return RadioListTile<int?>(
                                        title: const Text('-- No Doctor --', style: TextStyle(color: Colors.grey)),
                                        value: null,
                                        groupValue: _selectedDoctorId,
                                        onChanged: (val) {
                                          setState(() => _selectedDoctorId = val);
                                        },
                                        activeColor: Theme.of(context).primaryColor,
                                        controlAffinity: ListTileControlAffinity.trailing,
                                        visualDensity: VisualDensity.compact,
                                      );
                                    }

                                    final doctor = _doctors[index - 1];
                                    final id = doctor['id'] as int;
                                    final name = doctor['name'] ?? '';
                                    final specialty = doctor['specialty'] ?? 'General';

                                    return RadioListTile<int?>(
                                      title: Text('Dr. $name', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text(specialty),
                                      value: id,
                                      groupValue: _selectedDoctorId,
                                      onChanged: (val) {
                                        setState(() {
                                          _selectedDoctorId = val;
                                          if (val != null) {
                                            final address = doctor['clinic_address'] ?? '';
                                            if (address.isNotEmpty) {
                                              _locationController.text = address;
                                            }
                                          }
                                        });
                                      },
                                      activeColor: Theme.of(context).primaryColor,
                                      controlAffinity: ListTileControlAffinity.trailing,
                                      visualDensity: VisualDensity.compact,
                                    );
                                  },
                                ),
                              ),
                      ),
                const SizedBox(height: 20),

                // Location (auto-filled when doctor is selected)
                TextFormField(
                  controller: _locationController,
                  style: const TextStyle(fontSize: 18),
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    labelStyle: TextStyle(fontSize: 18),
                    hintText: 'e.g., City Hospital, Room 302',
                    prefixIcon: Icon(Icons.location_on, size: 28),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter location';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Description (Optional)
                TextFormField(
                  controller: _descriptionController,
                  style: const TextStyle(fontSize: 18),
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    labelStyle: TextStyle(fontSize: 18),
                    hintText: 'Add any additional notes...',
                    prefixIcon: Icon(Icons.notes, size: 28),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 40),

                // Create Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _createAppointment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                      : Text(
                          _isEditMode ? 'Save Changes' : 'Create Appointment',
                          style: const TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
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
