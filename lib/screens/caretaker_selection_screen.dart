import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'caretaker_detail_screen.dart';

class CaretakerSelectionScreen extends StatefulWidget {
  final int seniorId;
  const CaretakerSelectionScreen({Key? key, required this.seniorId})
      : super(key: key);

  @override
  State<CaretakerSelectionScreen> createState() =>
      _CaretakerSelectionScreenState();
}

class _CaretakerSelectionScreenState extends State<CaretakerSelectionScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _caretakers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCaretakers();
  }

  Future<void> _loadCaretakers() async {
    setState(() => _isLoading = true);
    final result = await _apiService.getCaretakerProfiles();
    print('🔵 DEBUG: getCaretakerProfiles result: $result');
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success']) {
          _caretakers = result['data'];
          _errorMessage = null;
          print('🔵 DEBUG: Caretakers count: ${_caretakers.length}');
        } else {
          _errorMessage =
              result['error']?.toString() ?? 'Failed to load caretakers';
          print('🔴 DEBUG: getCaretakerProfiles failed: $_errorMessage');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Caretaker',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 80, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style:
                              const TextStyle(fontSize: 18, color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadCaretakers,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : _caretakers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_search,
                              size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text('No caretakers available',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _caretakers.length,
                      itemBuilder: (context, index) {
                        final caretaker = _caretakers[index];
                        final user = caretaker['user'] ??
                            {}; // Use 'user' instead of 'user_details'
                        final name = user['full_name'] ??
                            user['username'] ??
                            'Caretaker';
                        final photo = user[
                            'profile_picture']; // Use user's profile picture

                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.teal.withOpacity(0.1),
                              backgroundImage:
                                  photo != null ? NetworkImage(photo) : null,
                              child: photo == null
                                  ? const Icon(Icons.person,
                                      size: 30, color: Colors.teal)
                                  : null,
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(caretaker['specialization'] ??
                                    'Professional Caretaker'),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.star,
                                        size: 16, color: Colors.amber),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${caretaker['rating'] ?? '4.5'}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.work,
                                        size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                        '${caretaker['experience_years'] ?? '0'} Years'),
                                  ],
                                ),
                              ],
                            ),
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 18),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CaretakerDetailScreen(
                                    caretaker: caretaker,
                                    seniorId: widget.seniorId,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}
