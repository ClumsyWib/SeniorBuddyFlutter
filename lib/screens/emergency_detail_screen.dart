import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class EmergencyDetailScreen extends StatefulWidget {
  final int seniorId;
  final int? alertId;

  const EmergencyDetailScreen({
    Key? key,
    required this.seniorId,
    this.alertId,
  }) : super(key: key);

  @override
  State<EmergencyDetailScreen> createState() => _EmergencyDetailScreenState();
}

class _EmergencyDetailScreenState extends State<EmergencyDetailScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _senior;
  Map<String, dynamic>? _alert;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final results = await Future.wait([
      _apiService.getSeniorProfile(widget.seniorId),
      if (widget.alertId != null)
        _apiService.getList('emergency-alerts/${widget.alertId}/')
      else
        Future.value({'success': false}),
    ]);

    if (mounted) {
      setState(() {
        if (results[0]['success']) _senior = results[0]['data'];
        if (results.length > 1 && results[1]['success']) _alert = results[1]['raw'];
        _isLoading = false;
      });
    }
  }

  Future<void> _openMap(double lat, double lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callPhone(String phone) async {
    // Sanitize: Only keep numbers and +
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.isEmpty) return;
    
    final url = 'tel:$cleanPhone';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final alertTime = _alert?['alert_time'] != null 
        ? DateFormat('hh:mm a, MMM dd').format(DateTime.parse(_alert!['alert_time']).toLocal())
        : 'Unknown time';

    return Scaffold(
      appBar: AppBar(
        title: const Text('EMERGENCY DETAILS'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🚨 Header Alert Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 60, color: Colors.red),
                        const SizedBox(height: 10),
                        const Text(
                          'EMERGENCY ALERT',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        Text(
                          'Triggered at $alertTime',
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // 👴 Senior Info
                  const Text('SENIOR IN NEED', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundImage: _senior?['photo'] != null ? NetworkImage(_senior!['photo']) : null,
                      child: _senior?['photo'] == null ? const Icon(Icons.person, size: 30) : null,
                    ),
                    title: Text(_senior?['name'] ?? 'Unknown Senior', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    subtitle: Text('Age: ${_senior?['age'] ?? 'N/A'} • ${_senior?['medical_conditions'] ?? 'No conditions listed'}'),
                  ),
                  const SizedBox(height: 24),

                  // 📍 Location
                  if (_alert?['latitude'] != null) ...[
                    const Text('LAST KNOWN LOCATION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[100]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.blue, size: 30),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'GPS Location available. Tap below to view on Map.',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _openMap(_alert!['latitude'], _alert!['longitude']),
                      icon: const Icon(Icons.map),
                      label: const Text('VIEW ON GOOGLE MAPS'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ] else ...[
                    const Text('LOCATION NOT AVAILABLE', style: TextStyle(color: Colors.grey)),
                  ],
                  
                  const SizedBox(height: 30),
                  
                   // 📞 Actions
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                final phone = _senior?['emergency_contact'] ?? '';
                                if (phone.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('No emergency contact number available for this senior.')),
                                  );
                                  return;
                                }
                                _callPhone(phone);
                              },
                              icon: const Icon(Icons.call),
                              label: const Text('CALL CONTACT'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                                minimumSize: const Size(double.infinity, 56),
                              ),
                            ),
                            if (_senior?['emergency_contact'] != null && _senior!['emergency_contact'].toString().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'Number: ${_senior!['emergency_contact']}',
                                  style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.green),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}
