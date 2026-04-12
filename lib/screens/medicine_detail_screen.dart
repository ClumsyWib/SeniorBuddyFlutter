import 'package:flutter/material.dart';
import '../services/api_service.dart';

class MedicineDetailScreen extends StatefulWidget {
  final Map<String, dynamic> medicine;
  final String userRole;

  const MedicineDetailScreen({
    Key? key,
    required this.medicine,
    this.userRole = 'senior', // Default to senior for safety
  }) : super(key: key);

  @override
  State<MedicineDetailScreen> createState() => _MedicineDetailScreenState();
}

class _MedicineDetailScreenState extends State<MedicineDetailScreen> {
  final ApiService _apiService = ApiService();
  late Map<String, dynamic> _currentMedicine;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _currentMedicine = Map<String, dynamic>.from(widget.medicine);
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _isUpdating = true);
    final result = await _apiService.updateMedicineStatus(
      _currentMedicine['id'],
      {'status': status},
    );

    if (mounted) {
      setState(() => _isUpdating = false);
      if (result['success']) {
        setState(() {
          _currentMedicine = result['data'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Medicine marked as $status')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update status')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _currentMedicine['is_active'] ?? false;
    final String currentStatus = (_currentMedicine['status'] ?? 'pending').toString();
    final String? lastActionDate = _currentMedicine['last_action_date'];
    final String todayDate = DateTime.now().toIso8601String().split('T')[0];
    
    // Reset status to pending if not updated today (matches backend logic)
    final String effectiveStatus = (lastActionDate == todayDate) ? currentStatus : 'pending';
    final bool isActionedToday = (lastActionDate == todayDate) && (effectiveStatus == 'taken' || effectiveStatus == 'missed');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Details', style: TextStyle(fontSize: 24)),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.medication,
                        size: 60,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _currentMedicine['medicine_name'] ?? 'Medicine',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.green.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Text(
                            isActive ? 'ACTIVE' : 'INACTIVE',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isActive ? Colors.green : Colors.grey,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _getStatusColor(currentStatus).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Text(
                            currentStatus.toUpperCase(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(currentStatus),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            if (widget.userRole == 'senior' && !isActionedToday) ...[
              if (_isUpdating)
                const Center(child: CircularProgressIndicator())
              else
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width > 400 ? (MediaQuery.of(context).size.width - 64) / 2 : double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _updateStatus('taken'),
                        icon: const Icon(Icons.check_circle_outline, size: 28),
                        label: const Text('Mark Taken',
                            style: TextStyle(fontSize: 18)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width > 400 ? (MediaQuery.of(context).size.width - 64) / 2 : double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _updateStatus('missed'),
                        icon: const Icon(Icons.cancel_outlined, size: 28),
                        label: const Text('Mark Missed',
                            style: TextStyle(fontSize: 18)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              const Text(
                'Tracking will reset tomorrow morning.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ] else if (isActionedToday) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (effectiveStatus == 'taken' ? Colors.green : Colors.red).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: effectiveStatus == 'taken' ? Colors.green : Colors.red, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      effectiveStatus == 'taken' ? Icons.check_circle : Icons.error_outline,
                      color: effectiveStatus == 'taken' ? Colors.green : Colors.red,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          effectiveStatus == 'taken' ? 'LATEST DOSE: TAKEN' : 'LATEST DOSE: MISSED',
                          style: TextStyle(
                            color: effectiveStatus == 'taken' ? Colors.green[800] : Colors.red[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Status recorded for today. Reappears tomorrow.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            ],

            // Dosage Information Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dosage Information',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    _buildDetailRow(
                      Icons.medical_services,
                      'Dosage',
                      _currentMedicine['dosage'] ?? 'N/A',
                    ),
                    if (_currentMedicine['frequency'] != null) ...[
                      const Divider(height: 32),
                      _buildDetailRow(
                        Icons.schedule,
                        'Frequency',
                        _formatText(_currentMedicine['frequency']),
                      ),
                    ],
                    if (_currentMedicine['time_of_day'] != null) ...[
                      const Divider(height: 32),
                      _buildDetailRow(
                        Icons.access_time,
                        'Time: ${_formatTo12Hour(_currentMedicine['time_of_day'])}',
                        _formatText(_currentMedicine['time_of_day']),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Schedule Card
            if (_currentMedicine['start_date'] != null || _currentMedicine['end_date'] != null)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Schedule',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      if (_currentMedicine['start_date'] != null)
                        _buildDetailRow(
                          Icons.calendar_today,
                          'Start Date',
                          _formatDate(_currentMedicine['start_date']),
                        ),
                      if (_currentMedicine['start_date'] != null &&
                          _currentMedicine['end_date'] != null)
                        const Divider(height: 32),
                      if (_currentMedicine['end_date'] != null)
                        _buildDetailRow(
                          Icons.event,
                          'End Date',
                          _formatDate(_currentMedicine['end_date']),
                        ),
                    ],
                  ),
                ),
              ),

            if (_currentMedicine['start_date'] != null || _currentMedicine['end_date'] != null)
              const SizedBox(height: 16),

            // Instructions Card
            if (_currentMedicine['instructions'] != null &&
                _currentMedicine['instructions'].toString().trim().isNotEmpty)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Special Instructions',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      _buildDetailRow(
                        Icons.info_outline,
                        'Instructions',
                        _currentMedicine['instructions'].toString(),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 28, color: Theme.of(context).primaryColor),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'taken': return Colors.green;
      case 'missed': return Colors.orange;
      default: return Colors.blue;
    }
  }

  String _formatText(String? text) {
    if (text == null) return 'N/A';
    return text
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.length > 1 ? word.substring(1) : ''}')
        .join(' ');
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

  String _formatDate(String? date) {
    if (date == null) return 'N/A';
    try {
      final parts = date.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}'; // DD/MM/YYYY
      }
    } catch (e) {
      // If parsing fails, return as-is
    }
    return date;
  }
}
