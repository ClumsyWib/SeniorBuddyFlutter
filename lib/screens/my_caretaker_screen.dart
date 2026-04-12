import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/role_helper.dart';
import '../screens/caretaker_detail_screen.dart';
import '../services/api_service.dart';

class MyCaretakerScreen extends StatefulWidget {
  final VoidCallback onDataChanged;
  final int? seniorId;
  // userRole controls visibility of Assign Caretaker button
  final String userRole;

  const MyCaretakerScreen({
    Key? key,
    required this.onDataChanged,
    this.seniorId,
    this.userRole = kRoleFamily,
  }) : super(key: key);

  @override
  State<MyCaretakerScreen> createState() => _MyCaretakerScreenState();
}

class _MyCaretakerScreenState extends State<MyCaretakerScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _caretaker;
  List<dynamic> _availableCaretakers = [];
  bool _isLoadingAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadCaretaker();
  }

  Future<void> _loadCaretaker() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _apiService.getMyCaretaker(seniorId: widget.seniorId);

    if (mounted) {
      if (result['success'] == true && result['data'] != null) {
        setState(() {
          _isLoading = false;
          _caretaker = Map<String, dynamic>.from(result['data'] as Map);
        });
        widget.onDataChanged();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage =
              result['error']?.toString() ?? 'No caretaker assigned yet.';
        });
        if (canFamilyWrite(widget.userRole)) {
          _loadAvailableCaretakers();
        }
      }
    }
  }

  Future<void> _loadAvailableCaretakers() async {
    setState(() => _isLoadingAvailable = true);
    final result = await _apiService.getAvailableCaretakers();
    if (mounted) {
      setState(() {
        _isLoadingAvailable = false;
        // Safely cast to List<dynamic> to avoid type errors
        _availableCaretakers = result['success'] == true
            ? (result['data'] as List<dynamic>? ?? [])
            : [];
      });
    }
  }

  /// Shows a dialog to assign a caretaker — only visible to Family Members.
  Future<void> _showAssignCaretakerDialog() async {
    final result = await _apiService.getAvailableCaretakers();
    if (!mounted) return;

    final List<dynamic> caretakers = result['success'] == true
        ? (result['data'] as List<dynamic>? ?? [])
        : [];

    if (caretakers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No available caretakers found.'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign Caretaker',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: caretakers.length,
            itemBuilder: (_, i) {
              final ct = caretakers[i];
              final user = ct['user'] ?? {};
              final fullName = user['full_name'] ?? ct['caretaker_name'] ?? user['username'] ?? 'Caretaker';
              
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(fullName),
                subtitle: Text(user['username']?.toString() ?? ''),
                onTap: () async {
                  Navigator.pop(ctx);
                  if (widget.seniorId == null) return;

                  final int caretakerId =
                      int.tryParse(user['id']?.toString() ?? '0') ?? 0;

                  final assignResult = await _apiService.createCareAssignment(
                    seniorId: widget.seniorId!,
                    caretakerId: caretakerId,
                  );

                  if (!mounted) return;

                  if (assignResult['success'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Caretaker assigned successfully!'),
                          backgroundColor: Colors.green),
                    );
                    _loadCaretaker();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Failed: ${assignResult['error']}'),
                          backgroundColor: Colors.red),
                    );
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Caretaker Assignment', style: TextStyle(fontSize: 24)),
        backgroundColor: Theme.of(context).primaryColor,
        actions: canFamilyWrite(widget.userRole)
            ? [
                IconButton(
                  icon: const Icon(Icons.person_add),
                  tooltip: 'Assign Caretaker',
                  onPressed: _showAssignCaretakerDialog,
                ),
              ]
            : null,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null || _caretaker == null) {
      if (canFamilyWrite(widget.userRole)) {
        return _buildAvailableCaretakersList();
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'No caretaker assigned.',
              style: const TextStyle(fontSize: 20, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadCaretaker,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Card(
            elevation: 6,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CaretakerDetailScreen(
                      caretaker: _caretaker!,
                      // Fix applied here: Passing the required seniorId, defaulting to 0 if null
                      seniorId: widget.seniorId ?? 0,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                      child: Icon(Icons.person,
                          size: 70, color: Theme.of(context).primaryColor),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _caretaker!['name']?.toString() ?? 'Unknown',
                      style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _caretaker!['specialization']?.toString() ?? 'Caregiver',
                      style:
                          const TextStyle(fontSize: 18, color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          '${_caretaker!['rating']?.toString() ?? '0.0'} / 5.0',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildInfoRow(Icons.work, 'Experience',
                        _caretaker!['experience']?.toString() ?? 'N/A'),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.schedule, 'Schedule',
                        _caretaker!['schedule']?.toString() ?? 'Flexible'),
                    const SizedBox(height: 24),
                    const Text(
                      'Tap for more details',
                      style: TextStyle(fontSize: 16, color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _makePhoneCall(_caretaker?['phone']?.toString()),
                  icon: const Icon(Icons.phone, size: 24),
                  label: const Text('Call', style: TextStyle(fontSize: 20)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _sendSMS(_caretaker?['phone']?.toString()),
                  icon: const Icon(Icons.message, size: 24),
                  label: const Text('Message', style: TextStyle(fontSize: 20)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 14, color: Colors.black54)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  String _formatPhone(String phone) {
    return phone.replaceAll(RegExp(r'[^\d+]'), '');
  }

  Future<void> _makePhoneCall(String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No phone number available for this caretaker.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    final formattedUrl = _formatPhone(phone);
    final Uri phoneUri = Uri(scheme: 'tel', path: formattedUrl);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not open phone dialer.'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _sendSMS(String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No phone number available for this caretaker.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    final formattedUrl = _formatPhone(phone);
    final Uri smsUri = Uri(scheme: 'sms', path: formattedUrl);
    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        await launchUrl(smsUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not open SMS app.'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildAvailableCaretakersList() {
    if (_isLoadingAvailable) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_availableCaretakers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No caretakers available.',
                style: TextStyle(fontSize: 20, color: Colors.black54)),
            const SizedBox(height: 24),
            ElevatedButton(
                onPressed: _loadAvailableCaretakers,
                child: const Text('Refresh List')),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Select a Caretaker to Assign',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _availableCaretakers.length,
            itemBuilder: (context, index) {
              final ct = _availableCaretakers[index];
              final user = ct['user'] ?? {};
              final fullName = user['full_name'] ?? ct['caretaker_name'] ?? user['username'] ?? 'Caretaker';
              
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Icon(Icons.person, color: Theme.of(context).primaryColor),
                  ),
                  title: Text(fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle:
                      Text(ct['specialization']?.toString() ?? 'Caregiver'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      final user = ct['user'] ?? {};
                      final caretakerId =
                          int.tryParse(user['id']?.toString() ?? '0') ?? 0;
                      _assignCaretaker(caretakerId);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Assign'),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _assignCaretaker(int caretakerId) async {
    if (widget.seniorId == null) return;

    setState(() => _isLoading = true);
    final assignResult = await _apiService.createCareAssignment(
      seniorId: widget.seniorId!,
      caretakerId: caretakerId,
    );

    if (mounted) {
      if (assignResult['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Caretaker assigned successfully!'),
              backgroundColor: Colors.green),
        );
        _loadCaretaker();
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed: ${assignResult['error']}'),
              backgroundColor: Colors.red),
        );
      }
    }
  }
}
