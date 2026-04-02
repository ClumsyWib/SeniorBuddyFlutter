import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/refresh_mixin.dart';
import '../utils/role_helper.dart';
import 'contact_detail_screen.dart';
import 'add_contact_screen.dart';

class EmergencyContactsScreen extends StatefulWidget {
  final VoidCallback onDataChanged;
  final int? seniorId;
  // userRole controls whether the Add Contact button is shown
  final String userRole;

  const EmergencyContactsScreen({Key? key, required this.onDataChanged, this.seniorId, this.userRole = kRoleFamily})
      : super(key: key);

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> with PeriodicRefreshMixin {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = true;

  @override
  Future<void> onRefresh() => _loadContacts();

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);

    final result = await _apiService.getEmergencyContacts(seniorId: widget.seniorId);
    if (mounted) {
      if (result['success'] == true && result['data'] != null) {
        final list = result['data'] as List<dynamic>;
        setState(() {
          _isLoading = false;
          _contacts = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        });
        widget.onDataChanged();
        return;
      }
      // Fallback: sample data when Django endpoint not yet available
      setState(() {
        _isLoading = false;
        _contacts = [
          {
            'id': 1,
            'name': 'Dr. Sarah Johnson',
            'relationship': 'Family Doctor',
            'phone': '+1 (555) 123-4567',
            'email': 'dr.johnson@hospital.com',
            'is_primary': true,
          },
          {
            'id': 2,
            'name': 'John Smith',
            'relationship': 'Son',
            'phone': '+1 (555) 987-6543',
            'email': 'john.smith@email.com',
            'is_primary': false,
          },
        ];
      });
    }
  }

  Future<void> _triggerSOS(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Trigger Emergency?'),
        content: const Text('This will alert all volunteers to assist you. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('YES, ALERT VOLUNTEERS', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await _apiService.triggerVolunteerEmergency(widget.seniorId);
      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Emergency Alert Sent!'), backgroundColor: Colors.red));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${result['error']}')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts', style: TextStyle(fontSize: 24)),
        backgroundColor: const Color(0xFFE53935),
        actions: widget.userRole == kRoleSenior 
          ? [
              IconButton(
                icon: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
                onPressed: () => _triggerSOS(context),
                tooltip: 'SOS EMERGENCY',
              ),
            ]
          : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _contacts.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        onRefresh: _loadContacts,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _contacts.length,
          itemBuilder: (context, index) {
            final contact = _contacts[index];
            return _buildContactCard(contact);
          },
        ),
      ),
      // Only Family Members can add emergency contacts
      floatingActionButton: canFamilyWrite(widget.userRole)
          ? FloatingActionButton.extended(
              onPressed: _addContact,
              backgroundColor: const Color(0xFFE53935),
              icon: const Icon(Icons.add, size: 28),
              label: const Text('Add Contact', style: TextStyle(fontSize: 18)),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.contact_emergency, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 20),
          const Text('No emergency contacts yet', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildContactCard(Map<String, dynamic> contact) {
    final isPrimary = contact['is_primary'] ?? false;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ContactDetailScreen(contact: contact),
            ),
          );
          _loadContacts();
          widget.onDataChanged();
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFFE53935).withOpacity(0.2),
                child: Text(
                  contact['name']?[0] ?? 'C',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFE53935)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            contact['name'] ?? 'Contact',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (isPrimary)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'PRIMARY',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      contact['relationship'] ?? '',
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 16, color: Colors.black54),
                        const SizedBox(width: 6),
                        Text(
                          contact['phone'] ?? '',
                          style: const TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addContact() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddContactScreen(seniorId: widget.seniorId),
      ),
    );

    if (result == true) {
      _loadContacts();
      widget.onDataChanged();
    }
  }
}