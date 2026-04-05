import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/role_helper.dart';
import '../screens/medicines_screen.dart';
import '../screens/appointments_screen.dart';
import '../screens/vitals_tracker_screen.dart';
import '../screens/daily_activity_screen.dart';
import '../screens/emergency_contacts_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/role_selection_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_links_widget.dart';
import '../screens/medicine_detail_screen.dart';
import '../screens/appointment_detail_screen.dart';
import '../screens/contact_detail_screen.dart';
import '../screens/buddy_chat_screen.dart';

/// Senior Dashboard
///
/// Seniors are READ-ONLY users. They can VIEW:
///   Medicine reminders | Appointment reminders | Vitals summary
///   Daily Activity summary | Emergency contacts
///
/// NO Add / Edit buttons are shown anywhere.
class SeniorHomeScreen extends StatefulWidget {
  const SeniorHomeScreen({Key? key}) : super(key: key);

  @override
  State<SeniorHomeScreen> createState() => _SeniorHomeScreenState();
}

class _SeniorHomeScreenState extends State<SeniorHomeScreen> {
  static const Color _green1 = Color(0xFF43A047);
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _userName = 'Senior';
  int? _seniorId;
  int _selectedIndex = 0;
  Map<String, dynamic>? _seniorProfile;
  Map<String, dynamic>? _userData; // Added for ProfileHeader and EditProfileScreen

  // Quick-preview data
  List<dynamic> _medicines = [];
  List<dynamic> _appointments = [];
  List<dynamic> _contacts = [];

  // ── Palette ──────────────────────────────────────────────────────────────
  static const Color _purple1 = Color(0xFF9C27B0);
  static const Color _bg = Color(0xFFF9F5FF);
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);

    // Get senior ID from prefs if in senior mode
    _seniorId = await _apiService.getSeniorId();
    print('DEBUG: SeniorHomeScreen loaded with seniorId: $_seniorId');

    final userResult = await _apiService.getCurrentUser();
    if (userResult['success']) {
      _userData = userResult['data']; // Store user data
      final firstName = _userData!['first_name'] ?? '';
      final lastName = _userData!['last_name'] ?? '';
      _userName = '$firstName $lastName'.trim();
      if (_userName.isEmpty) _userName = _userData!['username'] ?? 'Senior';
      
      // If we don't have a seniorId from prefs, try to get it from user data (fallback)
      _seniorId ??= _userData!['id'];
    }

    // Load preview data + profile in parallel
    final results = await Future.wait([
      _apiService.getMedicines(seniorId: _seniorId),
      _apiService.getUpcomingAppointments(seniorId: _seniorId),
      _apiService.getEmergencyContacts(seniorId: _seniorId),
      _seniorId != null ? _apiService.getSeniorProfile(_seniorId!) : Future.value({'success': false}),
    ]);

    if (mounted) {
      setState(() {
        if (results[0]['success'] == true) _medicines = results[0]['data'] ?? [];
        if (results[1]['success'] == true) _appointments = results[1]['data'] ?? [];
        if (results[2]['success'] == true) _contacts = results[2]['data'] ?? [];
        if (results[3]['success'] == true) _seniorProfile = results[3]['data'];
        _isLoading = false;
      });
    }
  }

  Future<void> _triggerEmergency() async {
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
      final result = await _apiService.triggerVolunteerEmergency(_seniorId);
      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Emergency Alert Sent! Volunteers are being notified.'), backgroundColor: Colors.red));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${result['error']}')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,

      // ── AppBar ────────────────────────────────────────────────────────────
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _purple1,
        title: Text(
          _appBarTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        automaticallyImplyLeading: false,
        actions: null,
      ),

      // ── Body ──────────────────────────────────────────────────────────────
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: _purple1))
          : _buildTabContent(),

      // ── Navigation ────────────────────────────────────────────────────────
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) {
          if (idx == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const BuddyChatScreen()));
            return;
          }
          setState(() => _selectedIndex = idx >= 1 ? idx - 1 : idx);
        },
        indicatorColor: _green1.withOpacity(0.15),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: _green1),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy, color: Color(0xFF1565C0)),
            label: 'Buddy',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view, color: _green1),
            label: 'Features',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: _green1),
            label: 'Profile',
          ),
        ],
      ),
    );
  }


  String get _appBarTitle {
    switch (_selectedIndex) {
      case 0: return 'My Care Dashboard';
      case 1: return 'Care Features';
      case 2: return 'My Profile';
      default: return 'Dashboard';
    }
  }

  Widget _buildTabContent() {
    switch (_selectedIndex) {
      case 0: return _buildHomeTab();
      case 1: return _buildFeaturesTab();
      case 2: return _buildProfileTab();
      default: return _buildHomeTab();
    }
  }

  // ────────────────────────────── HOME TAB ────────────────────────────────

  Widget _buildHomeTab() {
    return RefreshIndicator(
      color: _purple1,
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Text('Hello, ${_seniorProfile?['name'] ?? _userName}! 👋',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
            const SizedBox(height: 6),
            const Text('Here is your care overview for today.',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 24),

            // 🆘 SOS Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _triggerEmergency(),
                icon: const Icon(Icons.warning_amber_rounded, size: 30, color: Colors.white),
                label: const Text('SOS - EMERGENCY', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // View-only notice banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE7F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.visibility, color: _purple1),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You are in view-only mode. Your caretaker and family manage your care records.',
                      style: TextStyle(fontSize: 14, color: Color(0xFF6A1B9A)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Medicine Reminders Preview ───────────────────────────
            _buildSectionHeader('Medicine Reminders', Icons.medication, Colors.red),
            const SizedBox(height: 10),
            _medicines.isEmpty
                ? _buildEmptyCard('No medicines currently scheduled.')
                : Column(
                    children: _medicines.take(3).map((m) => _buildMedicineCard(m)).toList(),
                  ),

            const SizedBox(height: 24),

            // ── Upcoming Appointments Preview ────────────────────────
            _buildSectionHeader('Upcoming Appointments', Icons.calendar_today, Colors.blue),
            const SizedBox(height: 10),
            _appointments.isEmpty
                ? _buildEmptyCard('No upcoming appointments.')
                : Column(
                    children: _appointments.take(3).map((a) => _buildAppointmentCard(a)).toList(),
                  ),

            const SizedBox(height: 24),

            // ── Emergency Contacts Preview ───────────────────────────
            _buildSectionHeader('Emergency Contacts', Icons.contact_emergency, Colors.orange),
            const SizedBox(height: 10),
            _contacts.isEmpty
                ? _buildEmptyCard('No emergency contacts added.')
                : Column(
                    children: _contacts.take(3).map((c) => _buildContactCard(c)).toList(),
                  ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────── FEATURES TAB ──────────────────────────────

  Widget _buildFeaturesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Care Features', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('View your medical records and care details.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.25,
            children: [
              _buildViewTile('Medicines', Icons.medication, Colors.red, () {
                if (_seniorId != null) {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => MedicinesScreen(seniorId: _seniorId, userRole: kRoleSenior)));
                }
              }),
              _buildViewTile('Appointments', Icons.calendar_today, Colors.blue, () {
                if (_seniorId != null) {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => AppointmentsScreen(seniorId: _seniorId, userRole: kRoleSenior)));
                }
              }),
              _buildViewTile('Vitals', Icons.monitor_heart, const Color(0xFFE91E63), () {
                if (_seniorId != null) {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => VitalsTrackerScreen(seniorId: _seniorId!, userRole: kRoleSenior)));
                }
              }),
              _buildViewTile('Daily Activity', Icons.assignment_turned_in, Colors.indigo, () {
                if (_seniorId != null) {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => DailyActivityScreen(
                      seniorId: _seniorId!,
                      seniorName: _userName,
                      userRole: kRoleSenior,
                    )));
                }
              }),
              _buildViewTile('Emergency', Icons.contact_emergency, Colors.orange, () {
                if (_seniorId != null) {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => EmergencyContactsScreen(
                      onDataChanged: () {},
                      seniorId: _seniorId,
                      userRole: kRoleSenior,
                    )));
                }
              }),
            ],
          ),
        ],
      ),
    );
  }

  // ────────────────────────────── PROFILE TAB ───────────────────────────────

  Widget _buildProfileTab() {
    const primaryColor = Color(0xFF43A047);
    const redAccent = Color(0xFFD32F2F);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // 👴 Large Profile Photo
          CircleAvatar(
            radius: 80,
            backgroundColor: Colors.white,
            backgroundImage: _seniorProfile?['photo'] != null
                ? NetworkImage(_seniorProfile!['photo'])
                : null,
            child: _seniorProfile?['photo'] == null
                ? const Icon(Icons.person, size: 100, color: _purple1)
                : null,
          ),
          const SizedBox(height: 24),

          // 👴 Name (Large Bold)
          Text(
            _seniorProfile?['name'] ?? _userName,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
          ),
          const Text(
            'Role: Senior',
            style: TextStyle(fontSize: 22, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 40),

          // 🟢 Info Card 1 (Personal Info - Green Theme)
          _buildLargeInfoCard(
            title: 'Personal Info',
            icon: Icons.person_outline,
            color: const Color(0xFFE8F5E9),
            titleColor: const Color(0xFF2E7D32),
            items: [
              _buildLargeInfoRow('Age', '${_seniorProfile?['age'] ?? '-'} years'),
              _buildLargeInfoRow('Gender', _seniorProfile?['gender'] ?? 'Not set'),
              _buildLargeInfoRow('City', _seniorProfile?['city'] ?? 'Not set'),
              _buildLargeInfoRow('Address', _seniorProfile?['address'] ?? 'Not set'),
            ],
          ),
          const SizedBox(height: 24),

          // 🔴 Info Card 2 (Health & Emergency - Red Theme)
          _buildLargeInfoCard(
            title: 'Health & Safety',
            icon: Icons.health_and_safety_outlined,
            color: const Color(0xFFFFEBEE),
            titleColor: redAccent,
            items: [
              _buildLargeInfoRow('Medical Info', _seniorProfile?['medical_info'] ?? 'No info'),
              _buildLargeInfoRow('Emergency', _seniorProfile?['emergency_contact'] ?? 'No contact'),
            ],
          ),
          
          const SizedBox(height: 48),
          
          // Logout Section
          ProfileLinksWidget(
            onLogout: _handleLogout,
            primaryColor: _purple1,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildLargeInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> items,
    required Color color,
    required Color titleColor,
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
            value.isEmpty ? 'Not set' : value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  void _handleLogout() async {
    await _apiService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildProfileSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _purple1),
          ),
        ),
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.withOpacity(0.1)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileDataRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[400]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? 'N/A' : value,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF2D3142)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────── HELPERS ─────────────────────────────────

  Widget _buildViewTile(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildEmptyCard(String message) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(message, style: const TextStyle(color: Colors.grey, fontSize: 15)),
      ),
    );
  }

  Widget _buildMedicineCard(dynamic m) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      child: ListTile(
        leading: const Icon(Icons.medication, color: Colors.red),
        title: Text(m['medicine_name'] ?? 'Medicine', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${m['dosage'] ?? ''} • ${m['frequency'] ?? ''}'),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MedicineDetailScreen(medicine: m))),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: (m['is_active'] == true ? Colors.green : Colors.grey).withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(m['is_active'] == true ? 'Active' : 'Inactive',
              style: TextStyle(color: m['is_active'] == true ? Colors.green : Colors.grey, fontSize: 12)),
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(dynamic a) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      child: ListTile(
        leading: const Icon(Icons.event, color: Colors.blue),
        title: Text(a['title'] ?? 'Appointment', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${a['appointment_date'] ?? ''} at ${a['appointment_time'] ?? ''}'),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AppointmentDetailScreen(appointment: a))),
      ),
    );
  }

  Widget _buildContactCard(dynamic c) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      child: ListTile(
        leading: const Icon(Icons.person, color: Colors.orange),
        title: Text(c['name'] ?? 'Contact', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${c['relationship'] ?? ''} • ${c['phone'] ?? ''}'),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ContactDetailScreen(contact: c))),
      ),
    );
  }
}
