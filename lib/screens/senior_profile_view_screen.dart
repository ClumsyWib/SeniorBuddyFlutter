import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SeniorProfileViewScreen extends StatefulWidget {
  const SeniorProfileViewScreen({Key? key}) : super(key: key);

  @override
  State<SeniorProfileViewScreen> createState() => _SeniorProfileViewScreenState();
}

class _SeniorProfileViewScreenState extends State<SeniorProfileViewScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _seniorData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _apiService.getSeniorProfileMe();
      if (result['success']) {
        setState(() {
          _seniorData = result['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['error']?.toString() ?? 'Failed to load profile';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Connection error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF43A047);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : _error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error', textAlign: TextAlign.center, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _fetchProfile, child: const Text('Retry', style: TextStyle(fontSize: 20))),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Large Profile Photo
            CircleAvatar(
              radius: 80,
              backgroundColor: Colors.grey[200],
              backgroundImage: _seniorData?['photo'] != null
                  ? NetworkImage(_seniorData!['photo'])
                  : null,
              child: _seniorData?['photo'] == null
                  ? const Icon(Icons.person, size: 100, color: Colors.grey)
                  : null,
            ),
            const SizedBox(height: 24),

            // Senior Name
            Text(
              _seniorData?['name'] ?? 'Unknown',
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const Text(
              'Role: Senior',
              style: TextStyle(fontSize: 22, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 40),

            // Info Card
            _buildInfoCard(
              title: 'Personal Info',
              icon: Icons.person_search,
              items: [
                _buildLargeInfoRow('Age', '${_seniorData?['age'] ?? '-'} years'),
                _buildLargeInfoRow('Gender', _seniorData?['gender'] ?? 'Unknown'),
                _buildLargeInfoRow('City', _seniorData?['city'] ?? 'Not set'),
                _buildLargeInfoRow('Address', _seniorData?['address'] ?? 'Not set'),
              ],
            ),
            const SizedBox(height: 24),

            // Health Section
            _buildInfoCard(
              title: 'Health & Safety',
              icon: Icons.health_and_safety,
              color: Colors.red[50]!,
              titleColor: Colors.red[900]!,
              items: [
                _buildLargeInfoRow('Medical Info', _seniorData?['medical_info'] ?? 'No info'),
                _buildLargeInfoRow('Emergency', _seniorData?['emergency_contact'] ?? 'No contact'),
              ],
            ),
            const SizedBox(height: 40),

            const Text(
              'Contact your family member to update your information.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> items,
    Color color = const Color(0xFFF1F8E9),
    Color titleColor = const Color(0xFF2E7D32),
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: titleColor, size: 32),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: titleColor),
                ),
              ],
            ),
            const Divider(height: 32, thickness: 1.5),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildLargeInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
