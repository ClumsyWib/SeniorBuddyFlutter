import 'package:flutter/material.dart';
import '../services/api_service.dart';

class VolunteerEmergencyAlertsScreen extends StatefulWidget {
  const VolunteerEmergencyAlertsScreen({Key? key}) : super(key: key);

  @override
  State<VolunteerEmergencyAlertsScreen> createState() => _VolunteerEmergencyAlertsScreenState();
}

class _VolunteerEmergencyAlertsScreenState extends State<VolunteerEmergencyAlertsScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _alerts = [];
  String _currentFilter = 'active'; // 'active' or 'handled'

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() => _isLoading = true);
    final result = await _api.getVolunteerEmergencies(status: _currentFilter);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success']) {
          _alerts = result['data'];
        }
      });
    }
  }

  Future<void> _acceptAlert(int id) async {
    final result = await _api.acceptVolunteerEmergency(id);
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Emergency Accepted!')));
      _loadAlerts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Emergency Alerts', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.red,
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            onTap: (index) {
              setState(() {
                _currentFilter = index == 0 ? 'active' : 'handled';
              });
              _loadAlerts();
            },
            tabs: const [
              Tab(text: 'ACTIVE'),
              Tab(text: 'PAST'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _alerts.isEmpty
                ? Center(child: Text('No ${_currentFilter == 'active' ? 'active' : 'past'} emergencies.', style: const TextStyle(fontSize: 18, color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _alerts.length,
                    itemBuilder: (context, index) {
                      final alert = _alerts[index];
                      bool isPast = _currentFilter == 'handled';
                      return Card(
                        color: isPast ? Colors.grey[50] : Colors.red[50],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: isPast ? Colors.grey : Colors.red, width: 2),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(isPast ? Icons.history : Icons.warning_amber_rounded, color: isPast ? Colors.grey : Colors.red, size: 30),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${isPast ? 'PASSED: ' : 'EMERGENCY: '}${alert['senior_name']}',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isPast ? Colors.grey[700] : Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Time: ${alert['created_at']}'),
                              if (!isPast) ...[
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => _acceptAlert(alert['id']),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    minimumSize: const Size(double.infinity, 50),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('I AM RESPONDING', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
