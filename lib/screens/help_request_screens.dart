import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/role_helper.dart';
import 'chat_screen.dart';

class HelpRequestListScreen extends StatefulWidget {
  final String userRole;
  final String? initialFilter;
  final int? seniorId;
  const HelpRequestListScreen({
    Key? key,
    required this.userRole,
    this.initialFilter,
    this.seniorId,
  }) : super(key: key);

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
      result = await _api.getHelpRequests(
          status: _currentFilter == 'all' ? null : _currentFilter);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success']) {
          List<dynamic> data = result['data'];
          
          // Filter by Senior if provided from dashboard
          if (widget.seniorId != null) {
            data = data.where((req) {
              dynamic sData = req['senior'];
              int sid = (sData is Map) ? sData['id'] : (sData as int? ?? 0);
              return sid == widget.seniorId;
            }).toList();
          }
          
          _requests = data;
        }
      });
    }
  }

  static const Color _primary = Color(0xFF3F51B5);
  static const Color _accent = Color(0xFF7E57C2);

  @override
  Widget build(BuildContext context) {
    bool isVolunteer = widget.userRole == kRoleVolunteer;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: Text(isVolunteer ? 'Help Requests' : 'My Help Requests',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        elevation: 0,
        backgroundColor: _primary,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_primary, _accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (isVolunteer)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                ? const Center(child: CircularProgressIndicator(color: _primary))
                : _requests.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadRequests,
                        color: _primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _requests.length,
                          itemBuilder: (context, index) {
                            final req = _requests[index];
                            return _buildRequestCard(req);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: widget.userRole == kRoleFamily
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CreateHelpRequestScreen()),
                );
                if (result == true) _loadRequests();
              },
              backgroundColor: _primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('New Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.volunteer_activism_outlined, size: 80, color: _primary.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text('No requests found.', style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildRequestCard(dynamic req) {
    return Card(
      elevation: 3,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      req['title'] ?? 'No Title',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
                    ),
                  ),
                  _statusBadge(req['status']),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                req['description']?.isNotEmpty == true
                    ? req['description']
                    : "No additional message",
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text('Senior: ${req['senior_name']}', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                  const Spacer(),
                  if (_buildActionButtons(req) != null) _buildActionButtons(req)!,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
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
          icon: const Icon(Icons.chat_bubble_outline, color: _accent, size: 20),
          onPressed: () {
            bool isMeFamily = widget.userRole == kRoleFamily;
            dynamic volunteerData = req['assigned_volunteer'];
            int otherId;
            if (isMeFamily) {
              otherId = volunteerData is Map ? volunteerData['id'] : volunteerData as int;
            } else {
              dynamic createdByData = req['created_by'];
              otherId = createdByData is Map ? createdByData['id'] : createdByData as int;
            }
            
            String otherName = isMeFamily
                ? (req['volunteer_name'] ?? 'Volunteer')
                : (req['created_by_name'] ?? 'Family');
                
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ChatScreen(
                          otherUserId: otherId,
                          otherUserName: otherName,
                          helpRequestId: req['id'],
                        )));
          },
        ),
      );
    }

    if (widget.userRole == kRoleVolunteer) {
      if (status == 'pending') {
        buttons.add(
          TextButton(
            onPressed: () => _handleAction(req['id'], 'accept'),
            child: const Text('Accept', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          ),
        );
      } else if (status == 'accepted') {
        buttons.add(
          TextButton(
            onPressed: () => _handleAction(req['id'], 'complete'),
            child: const Text('Complete', style: TextStyle(color: _primary, fontWeight: FontWeight.bold)),
          ),
        );
      }
    } else if (widget.userRole == kRoleFamily) {
      if (status == 'completed') {
        buttons.add(
          ElevatedButton(
            onPressed: () => _handleAction(req['id'], 'verify'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Verify'),
          ),
        );
      } else if (status == 'verified' && req['is_rated'] != true) {
        buttons.add(
          ElevatedButton(
            onPressed: () => _showRatingDialog(req),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black87,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Rate'),
          ),
        );
      }
    }

    return Row(mainAxisSize: MainAxisSize.min, children: buttons);
  }

  void _showRatingDialog(dynamic req) {
    dynamic volunteerData = req['assigned_volunteer'];
    int volunteerId = volunteerData is Map ? volunteerData['id'] : volunteerData as int;
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
                children: List.generate(
                    5,
                    (index) => GestureDetector(
                          onTap: () =>
                              setState(() => selectedRating = index + 1),
                          child: Padding(
                            padding: const EdgeInsets.all(
                                4.0), // Smaller, controlled padding
                            child: Icon(
                                index < selectedRating
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size:
                                    32 // Slightly larger icon since we removed the button shell
                                ),
                          ),
                        )),
              ),
              const SizedBox(height: 16), // Space between stars and text field
              TextField(
                  controller: feedbackController,
                  decoration: const InputDecoration(
                    labelText: 'Feedback (Optional)',
                    border:
                        OutlineInputBorder(), // Optional: makes the text field look cleaner
                  )),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                if (selectedRating == 0) return;
                
                final result = await _api.giveRating(
                  volunteerId,
                  selectedRating,
                  feedbackController.text,
                  helpRequestId: helpRequestId,
                  seniorId: seniorId,
                );
                
                if (result['success']) {
                  Navigator.pop(ctx);
                  _loadRequests();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Thank you for your rating!')));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Failed: ${result['error'] ?? 'Unknown error'}')));
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
    if (action == 'accept')
      result = await _api.acceptHelpRequest(id);
    else if (action == 'complete')
      result = await _api.completeHelpRequest(id);
    else if (action == 'verify')
      result = await _api.verifyHelpRequest(id);
    else
      return;

    if (result['success']) {
      _loadRequests();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: ${result['error']}')));
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.grey;
      case 'accepted':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'verified':
        return Colors.green;
      default:
        return Colors.black;
    }
  }
}

class CreateHelpRequestScreen extends StatefulWidget {
  const CreateHelpRequestScreen({Key? key}) : super(key: key);

  @override
  State<CreateHelpRequestScreen> createState() =>
      _CreateHelpRequestScreenState();
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
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields')));
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: ${result['error']}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF3F51B5);
    const Color accent = Color(0xFF7E57C2);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: const Text('Create Help Request',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        elevation: 0,
        backgroundColor: primary,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primary, accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Senior in Need',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _selectedSeniorId,
                    items: _seniors
                        .map((s) => DropdownMenuItem<int>(
                              value: s['id'],
                              child: Text(s['name'] ?? 'Senior'),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedSeniorId = val),
                    decoration: InputDecoration(
                      hintText: 'Select a senior',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Request Title',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Help with groceries',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Detailed Message',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Describe what kind of help is needed...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [primary, accent]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Submit Request',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
