import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CaretakerDetailScreen extends StatefulWidget {
  final Map<String, dynamic> caretaker;
  final int seniorId;

  const CaretakerDetailScreen({
    Key? key,
    required this.caretaker,
    required this.seniorId,
  }) : super(key: key);

  @override
  State<CaretakerDetailScreen> createState() => _CaretakerDetailScreenState();
}

class _CaretakerDetailScreenState extends State<CaretakerDetailScreen> {
  final ApiService _apiService = ApiService();
  bool _isAssigning = false;

  Future<void> _handleAssign() async {
    setState(() => _isAssigning = true);
    final user =
        widget.caretaker['user'] ?? {}; // Use 'user' instead of 'user_details'
    final caretakerId = user['id'];

    if (caretakerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Caretaker ID not found.')),
      );
      setState(() => _isAssigning = false);
      return;
    }

    final result = await _apiService.assignCaretaker(
      seniorId: widget.seniorId,
      caretakerId: caretakerId,
    );

    if (mounted) {
      setState(() => _isAssigning = false);
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Caretaker assigned successfully!'),
              backgroundColor: Colors.green),
        );
        // Navigate back to senior detail or home
        Navigator.pop(context); // Pop detail
        Navigator.pop(context); // Pop selection
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to assign: ${result['error']}'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user =
        widget.caretaker['user'] ?? {}; // Use 'user' instead of 'user_details'
    final name = user['full_name'] ?? user['username'] ?? 'Caretaker';
    final photo = user['profile_picture']; // Use user's profile picture

    return Scaffold(
      appBar: AppBar(
        title: const Text('Caretaker Profile',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white,
                        backgroundImage:
                            photo != null ? NetworkImage(photo) : null,
                        child: photo == null
                            ? Icon(Icons.person,
                                size: 60, color: Theme.of(context).primaryColor)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        name,
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.caretaker['specialization'] ??
                            'Professional Caretaker',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatColumn(
                          'Rating',
                          widget.caretaker['rating']?.toString() ?? '0.0',
                          Icons.star,
                          Colors.amber),
                      _buildStatColumn(
                          'Experience',
                          '${widget.caretaker['experience_years'] ?? 0} Years',
                          Icons.work,
                          Colors.blue),
                      _buildStatColumn(
                          'Availability',
                          widget.caretaker['availability_status'] ??
                              'Full-time',
                          Icons.event_available,
                          Colors.green),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Bio Section
                  _buildSectionTitle('Biography'),
                  const SizedBox(height: 8),
                  Text(
                    widget.caretaker['bio'] ?? 'No biography provided.',
                    style: const TextStyle(
                        fontSize: 16, height: 1.5, color: Colors.black87),
                  ),
                  const SizedBox(height: 32),

                  // Skills Section
                  _buildSectionTitle('Specializations & Skills'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (widget.caretaker['skills'] as String?)
                            ?.split(',')
                            .where((s) => s.trim().isNotEmpty)
                            .map((s) => _buildSkillChip(s.trim()))
                            .toList() ??
                        [
                          _buildSkillChip('First Aid'),
                          _buildSkillChip('Nursing Care'),
                          _buildSkillChip('Elder Care'),
                        ],
                  ),
                  const SizedBox(height: 48),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isAssigning ? null : _handleAssign,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isAssigning
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Assign to Senior',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
          fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
    );
  }

  Widget _buildSkillChip(String label) {
    return Chip(
      label: Text(label),
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.05),
      side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.2)),
    );
  }
}
