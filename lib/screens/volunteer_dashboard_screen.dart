import 'package:flutter/material.dart';
import '../services/api_service.dart';

class VolunteerDashboardScreen extends StatefulWidget {
  const VolunteerDashboardScreen({Key? key}) : super(key: key);

  @override
  State<VolunteerDashboardScreen> createState() =>
      _VolunteerDashboardScreenState();
}

class _VolunteerDashboardScreenState extends State<VolunteerDashboardScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final result = await _api.getVolunteerDashboard();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success']) {
          _stats = result['data'];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Volunteer Dashboard')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildStatCard(
                        'Accepted Tasks',
                        '${_stats['accepted_tasks'] ?? 0}',
                        Icons.list_alt,
                        Colors.orange),
                    _buildStatCard(
                        'Completed Tasks',
                        '${_stats['completed_tasks'] ?? 0}',
                        Icons.check_circle,
                        Colors.green),
                    _buildStatCard(
                        'Emergencies Handled',
                        '${_stats['emergencies_handled'] ?? 0}',
                        Icons.emergency,
                        Colors.red),
                    _buildStatCard(
                        'Average Rating',
                        '${(_stats['average_rating'] ?? 0.0).toStringAsFixed(1)} ★',
                        Icons.star,
                        Colors.blue),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontSize: 16, color: Colors.grey)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
