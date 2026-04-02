import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/role_helper.dart';
import 'chat_screen.dart';

class HelpRequestListScreen extends StatefulWidget {
  final String userRole;
  final String? initialFilter;
  const HelpRequestListScreen({Key? key, required this.userRole, this.initialFilter}) : super(key: key);

  @override
  State<HelpRequestListScreen> createState() => _HelpRequestListScreenState();
}

class _HelpRequestListScreenState extends State<HelpRequestListScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _requests = [];
  String _currentFilter = 'pending';

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter != null) {
      _currentFilter = widget.initialFilter!;
    }
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    Map<String, dynamic> result;
    if (widget.userRole == kRoleFamily) {
      result = await _api.getMyHelpRequests();
    } else {
      result = await _api.getHelpRequests(status: _currentFilter == 'all' ? null : _currentFilter);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success']) {
          _requests = result['data'];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isVolunteer = widget.userRole == kRoleVolunteer;

    return Scaffold(
      appBar: AppBar(
        title: Text(isVolunteer ? 'Help Requests' : 'My Help Requests'),
        backgroundColor: isVolunteer ? Colors.orange : Colors.green,
      ),
      body: Column(
        children: [
          if (isVolunteer)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              // FIX: Added SingleChildScrollView to prevent horizontal overflow
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterButton('Pending', 'pending'),
                    const SizedBox(width: 8),
                    _filterButton('My Accepted', 'accepted'),
                    const SizedBox(width: 8),
                    _filterButton('Completed', 'completed'),
                    const SizedBox(width: 8),
                    _filterButton('All', 'all'),
                  ],
                ),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _requests.isEmpty
                ? const Center(child: Text('No requests found.'))
                : ListView.builder(
              itemCount: _requests.length,
              itemBuilder: (context, index) {
                final req = _requests[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(req['title'] ?? 'No Title', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text(
                          req['description']?.isNotEmpty == true 
                              ? "Message: ${req['description']}" 
                              : "No additional message",
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        Text('Senior: ${req['senior_name']}', style: const TextStyle(fontSize: 12)),
                        Text('Status: ${req['status']}', style: TextStyle(color: _getStatusColor(req['status']), fontWeight: FontWeight.bold)),
                      ],
                    ),
                    trailing: _buildActionButtons(req),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: widget.userRole == kRoleFamily
          ? FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateHelpRequestScreen()),
          );
          if (result == true) _loadRequests();
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      )
          : null,
    );
  }

  Widget _filterButton(String label, String value) {
    bool isSelected = _currentFilter == value;
    return ElevatedButton(
      onPressed: () {
        setState(() => _currentFilter = value);
        _loadRequests();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.orange : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.black,
      ),
      child: Text(label),
    );
  }

  Widget? _buildActionButtons(dynamic req) {
    String status = req['status'];
    List<Widget> buttons = [];

    // Chat Button (only if accepted or later)
    if (status != 'pending') {
      buttons.add(
        IconButton(
          icon: const Icon(Icons.chat, color: Colors.blue),
          onPressed: () {
            bool isMeFamily = widget.userRole == kRoleFamily;
            int otherId = isMeFamily 
                ? (req['assigned_volunteer'] is Map ? req['assigned_volunteer']['id'] : req['assigned_volunteer'] as int)
                : (req['created_by'] is Map ? req['created_by']['id'] : req['created_by'] as int);
            String otherName = isMeFamily ? (req['volunteer_name'] ?? 'Volunteer') : (req['created_by_name'] ?? 'Family');
            Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(otherUserId: otherId, otherUserName: otherName)));
          },
        ),
      );
    }

    if (widget.userRole == kRoleVolunteer) {
      if (status == 'pending') {
        buttons.add(
          ElevatedButton(
            onPressed: () => _handleAction(req['id'], 'accept'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Accept'),
          ),
        );
      } else if (status == 'accepted') {
        buttons.add(
          ElevatedButton(
            onPressed: () => _handleAction(req['id'], 'complete'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Complete'),
          ),
        );
      }
    } else if (widget.userRole == kRoleFamily) {
      if (status == 'completed') {
        buttons.add(
          ElevatedButton(
            onPressed: () => _handleAction(req['id'], 'verify'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Verify'),
          ),
        );
      } else if (status == 'verified') {
        buttons.add(
          ElevatedButton(
            onPressed: () => _showRatingDialog(req),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: const Text('Rate'),
          ),
        );
      }
    }

    return Row(mainAxisSize: MainAxisSize.min, children: buttons);
  }

  void _showRatingDialog(dynamic req) {
    int volunteerId = req['assigned_volunteer'];
    String volunteerName = req['volunteer_name'] ?? 'Volunteer';
    int helpRequestId = req['id'];
    int seniorId = req['senior'];
    int selectedRating = 5;
    final feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Rate $volunteerName'),
          content: Column(
            mainAxisSize: MainAxisSize.min, // Keeps dialog compact
            children: [
              // FIX: Replaced Row with Wrap and IconButton with GestureDetector
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 4.0, // Small gap between stars
                children: List.generate(5, (index) => GestureDetector(
                  onTap: () => setState(() => selectedRating = index + 1),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0), // Smaller, controlled padding
                    child: Icon(
                        index < selectedRating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32 // Slightly larger icon since we removed the button shell
                    ),
                  ),
                )),
              ),
              const SizedBox(height: 16), // Space between stars and text field
              TextField(
                  controller: feedbackController,
                  decoration: const InputDecoration(
                    labelText: 'Feedback (Optional)',
                    border: OutlineInputBorder(), // Optional: makes the text field look cleaner
                  )
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                final result = await _api.giveRating(
                  volunteerId, 
                  selectedRating, 
                  feedbackController.text,
                  helpRequestId: helpRequestId,
                  seniorId: seniorId,
                );
                Navigator.pop(ctx);
                if (result['success']) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thank you for your rating!')));
                }
              },
              child: const Text('SUBMIT'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(int id, String action) async {
    Map<String, dynamic> result;
    if (action == 'accept') result = await _api.acceptHelpRequest(id);
    else if (action == 'complete') result = await _api.completeHelpRequest(id);
    else if (action == 'verify') result = await _api.verifyHelpRequest(id);
    else return;

    if (result['success']) {
      _loadRequests();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${result['error']}')));
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.grey;
      case 'accepted': return Colors.orange;
      case 'completed': return Colors.blue;
      case 'verified': return Colors.green;
      default: return Colors.black;
    }
  }
}

class CreateHelpRequestScreen extends StatefulWidget {
  const CreateHelpRequestScreen({Key? key}) : super(key: key);

  @override
  State<CreateHelpRequestScreen> createState() => _CreateHelpRequestScreenState();
}

class _CreateHelpRequestScreenState extends State<CreateHelpRequestScreen> {
  final ApiService _api = ApiService();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  int? _selectedSeniorId;
  List<dynamic> _seniors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSeniors();
  }

  Future<void> _loadSeniors() async {
    final result = await _api.getSeniors();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success']) {
          _seniors = result['data'];
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedSeniorId == null || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    final result = await _api.createHelpRequest(
      seniorId: _selectedSeniorId!,
      title: _titleController.text,
      description: _descController.text,
    );

    if (result['success']) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${result['error']}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Help Request'), backgroundColor: Colors.green),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<int>(
              value: _selectedSeniorId,
              items: _seniors.map((s) => DropdownMenuItem<int>(
                value: s['id'],
                child: Text(s['name'] ?? 'Senior'),
              )).toList(),
              onChanged: (val) => setState(() => _selectedSeniorId = val),
              decoration: const InputDecoration(labelText: 'Select Senior'),
            ),
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title / Subject')),
            TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Detailed Message'), maxLines: 5),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(double.infinity, 50)),
              child: const Text('Submit Request', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}