import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/emergency_helper.dart';

import '../utils/role_helper.dart';
import 'vital_record_detail_screen.dart';

class VitalsTrackerScreen extends StatefulWidget {
  final int seniorId;
  // userRole controls whether the vitals entry form is shown
  final String userRole;

  const VitalsTrackerScreen(
      {Key? key, required this.seniorId, this.userRole = kRoleCaretaker})
      : super(key: key);

  @override
  State<VitalsTrackerScreen> createState() => _VitalsTrackerScreenState();
}

class _VitalsTrackerScreenState extends State<VitalsTrackerScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  final _bpController = TextEditingController();
  final _hrController = TextEditingController();
  final _tempController = TextEditingController();
  final _sugarController = TextEditingController();
  final _weightController = TextEditingController();
  final _oxygenController = TextEditingController();

  List<dynamic> _records = [];

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  @override
  void dispose() {
    _bpController.dispose();
    _hrController.dispose();
    _tempController.dispose();
    _sugarController.dispose();
    _weightController.dispose();
    _oxygenController.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);

    final result =
        await _apiService.getHealthRecords(seniorId: widget.seniorId);

    if (!mounted) return;

    setState(() {
      if (result['success']) {
        _records = result['data'];
      }
      _isLoading = false;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final result = await _apiService.createHealthRecord(
      seniorId: widget.seniorId,
      bloodPressure: _bpController.text.trim(),
      heartRate: int.tryParse(_hrController.text.trim()),
      temperature: double.tryParse(_tempController.text.trim()),
      bloodSugar: int.tryParse(_sugarController.text.trim()),
      weight: double.tryParse(_weightController.text.trim()),
      oxygenLevel: int.tryParse(_oxygenController.text.trim()),
    );

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Record saved successfully'),
          backgroundColor: Colors.green,
        ),
      );

      _bpController.clear();
      _hrController.clear();
      _tempController.clear();
      _sugarController.clear();
      _weightController.clear();
      _oxygenController.clear();

      _loadRecords();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save record'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _triggerSOS(BuildContext context) async {
    await EmergencyHelper.triggerSOS(context, widget.seniorId);
  }

  Future<void> _deleteRecord(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text('Are you sure you want to delete this vital record?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await _apiService.deleteHealthRecord(id);
      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Record deleted')),
          );
          _loadRecords();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to delete: ${result['error']}'),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vitals Tracker',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).primaryColor,
        actions: widget.userRole == kRoleSenior
            ? [
                IconButton(
                  icon: const Icon(Icons.warning_amber_rounded,
                      color: Colors.white, size: 28),
                  onPressed: () => _triggerSOS(context),
                  tooltip: 'SOS EMERGENCY',
                ),
              ]
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRecords,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Only Caretakers can record vitals
                  if (canCaretakerWrite(widget.userRole)) _buildAddRecordCard(),
                  if (canCaretakerWrite(widget.userRole))
                    const SizedBox(height: 24),
                  if (!canCaretakerWrite(widget.userRole))
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Card(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(Icons.visibility, color: Theme.of(context).primaryColor),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Vitals are recorded by the caretaker. You can view history below.',
                                  style: TextStyle(
                                      fontSize: 15, color: Theme.of(context).primaryColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const Text(
                    'History',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _records.isEmpty
                      ? const Text('No records yet.')
                      : _buildRecordsList(),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildAddRecordCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                'Add New Vitals',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildVitalsField(
                      _bpController,
                      'BP (120/80)',
                      Icons.favorite,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildVitalsField(
                      _hrController,
                      'HR (bpm)',
                      Icons.monitor_heart,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildVitalsField(
                      _tempController,
                      'Temp °C',
                      Icons.thermostat,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildVitalsField(
                      _sugarController,
                      'Sugar',
                      Icons.bloodtype,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildVitalsField(
                      _weightController,
                      'Weight (kg)',
                      Icons.monitor_weight,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildVitalsField(
                      _oxygenController,
                      'SpO2 (%)',
                      Icons.air,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Save Measurements',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVitalsField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildRecordsList() {
    return Column(
      children: _records.map((record) {
        return _buildRecordItem(record);
      }).toList(),
    );
  }

  Widget _buildRecordItem(dynamic record) {
    return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VitalRecordDetailScreen(record: record),
            ),
          ),
          child: ListTile(
            title: Text(
              "${record['record_date']} at ${_formatTo12Hour(record['record_time'])}",
            ),
            subtitle: Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (record['blood_pressure'] != null &&
                    record['blood_pressure'].toString().isNotEmpty)
                  _buildMetricChip(
                    Icons.favorite,
                    record['blood_pressure'],
                    Colors.red,
                  ),
                if (record['blood_sugar'] != null)
                  _buildMetricChip(
                    Icons.water_drop,
                    "${record['blood_sugar']} mg/dL",
                    Colors.orange,
                  ),
                if (record['heart_rate'] != null)
                  _buildMetricChip(
                    Icons.monitor_heart,
                    "${record['heart_rate']} bpm",
                    Colors.pink,
                  ),
              ],
            ),
            trailing: (canFamilyWrite(widget.userRole) ||
                    widget.userRole == kRoleCaretaker)
                ? IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteRecord(record['id']),
                    tooltip: 'Delete',
                  )
                : const Icon(Icons.arrow_forward_ios, size: 20),
          ),
        ));
  }

  String _formatTo12Hour(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return 'N/A';
    try {
      final parts = timeStr.split(':');
      if (parts.length < 2) return timeStr;
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      final period = hour >= 12 ? 'PM' : 'AM';
      hour = hour % 12;
      if (hour == 0) hour = 12;
      final minuteStr = minute.toString().padLeft(2, '0');
      return '$hour:$minuteStr $period';
    } catch (e) {
      return timeStr;
    }
  }

  Widget _buildMetricChip(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
