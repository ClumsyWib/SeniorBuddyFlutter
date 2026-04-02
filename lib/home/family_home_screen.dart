import 'package:flutter/material.dart';
import 'package:senior_care_app/screens/role_selection_screen.dart';
import '../services/api_service.dart';
import '../utils/role_helper.dart';
import '../utils/refresh_mixin.dart';
import '../screens/add_senior_screen.dart';
import '../screens/senior_detail_screen.dart';
import '../screens/medicines_screen.dart';
import '../screens/appointments_screen.dart';
import '../screens/health_records_screen.dart';
import '../screens/vitals_tracker_screen.dart';
import '../screens/doctors_screen.dart';
import '../screens/emergency_contacts_screen.dart';
import '../screens/my_caretaker_screen.dart';
import '../screens/daily_activity_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/help_support_screen.dart';
import '../screens/help_request_screens.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_links_widget.dart';
import '../utils/role_helper.dart';

/// Family Dashboard — Refactored with Bottom Navigation
class FamilyHomeScreen extends StatefulWidget {
  const FamilyHomeScreen({Key? key}) : super(key: key);

  @override
  State<FamilyHomeScreen> createState() => _FamilyHomeScreenState();
}

class _FamilyHomeScreenState extends State<FamilyHomeScreen> with PeriodicRefreshMixin {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _seniors = [];
  Map<String, dynamic>? _userData;
  String _userName = 'Family Member';
  int _selectedIndex = 0;

  // ── Palette ──────────────────────────────────────────────────────────────
  static const Color _green1 = Color(0xFF43A047);
  static const Color _green2 = Color(0xFF1DE9B6);
  static const Color _bg = Color(0xFFF5F7FA);
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<void> onRefresh() async {
    await _loadData();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userResult = await _apiService.getCurrentUser();
    if (userResult['success']) {
      if (mounted) {
        setState(() {
          _userData = userResult['data'];
          final firstName = _userData?['first_name'] ?? '';
          final lastName = _userData?['last_name'] ?? '';
          _userName = '$firstName $lastName'.trim();
          if (_userName.isEmpty) _userName = _userData?['username'] ?? 'Family Member';
        });
      }
    }

    final seniorsResult = await _apiService.getSeniors();
    if (seniorsResult['success']) {
      if (mounted) {
        setState(() {
          _seniors = seniorsResult['data'];
        });
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // ─────────────────────────────── BUILD ───────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,

      // ── AppBar ────────────────────────────────────────────────────────────
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _green1,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_green1, _green2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          _appBarTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
            letterSpacing: 0.4,
          ),
        ),
        automaticallyImplyLeading: false,
      ),

      // ── Body ──────────────────────────────────────────────────────────────
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: _green1))
          : _buildTabContent(),

      // ── Navigation ────────────────────────────────────────────────────────
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        indicatorColor: _green1.withOpacity(0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: _green1),
            label: 'Home',
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

      // ── FAB (Only on Home tab) ────────────────────────────────────────────
      floatingActionButton: _selectedIndex == 0 ? FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddSeniorScreen()),
          );
          if (result == true) _loadData();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Senior', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _green1,
        foregroundColor: Colors.white,
        elevation: 4,
      ) : null,
    );
  }

  String get _appBarTitle {
    switch (_selectedIndex) {
      case 0: return 'Family Dashboard';
      case 1: return 'Quick Features';
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

  // ─────────────────────────────── TABS ────────────────────────────────────

  Widget _buildHomeTab() {
    return RefreshIndicator(
      color: _green1,
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeRow(),
            const SizedBox(height: 24),
            const Text(
              'My Seniors',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 12),
            _seniors.isEmpty
                ? _buildEmptySeniors()
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _seniors.length,
                    itemBuilder: (context, index) {
                      final senior = _seniors[index];
                      return _buildSeniorCard(senior);
                    },
                  ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Care Management',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 4),
          Text(
            'Select a feature to manage your senior\'s care.',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 18),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.15,
            children: [
              _buildFeatureTile('Medicines', Icons.medication_outlined, const Color(0xFFE53935),
                  () => _navigateToFeature('medicines')),
              _buildFeatureTile('Appointments', Icons.calendar_today_outlined, const Color(0xFF1E88E5),
                  () => _navigateToFeature('appointments')),
              _buildFeatureTile('Vitals', Icons.monitor_heart_outlined, const Color(0xFFEF6C00),
                  () => _navigateToFeature('vitals')),
              _buildFeatureTile('My Doctors', Icons.medical_services_outlined, const Color(0xFF00897B),
                  () => _navigateToFeature('doctors')),
              _buildFeatureTile('Emergency Contacts', Icons.contact_emergency_outlined, const Color(0xFF8E24AA),
                  () => _navigateToFeature('emergency')),
              _buildFeatureTile('Caretaker', Icons.health_and_safety_outlined, const Color(0xFF00ACC1),
                  () => _navigateToFeature('caretaker')),
              _buildFeatureTile('Activity Reports', Icons.assignment_turned_in_outlined, const Color(0xFF3949AB),
                  () => _navigateToFeature('activity')),
              _buildFeatureTile('Help Requests', Icons.volunteer_activism_outlined, Colors.orange,
                  () => _navigateToFeature('help_requests')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          ProfileHeader(
            userData: _userData,
            userRole: kRoleFamily,
          ),
          const SizedBox(height: 28),
          
          // Edit Profile
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditProfileScreen(userData: _userData ?? {})),
                );
                if (updated == true) _loadData();
              },
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit Profile'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF43A047),
                side: const BorderSide(color: Color(0xFF43A047)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          ProfileLinksWidget(
            onLogout: _handleLogout,
            primaryColor: const Color(0xFF43A047),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: _green1))),
        ],
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.black87),
      title: Text(title, style: TextStyle(fontSize: 17, color: textColor ?? Colors.black87, fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }

  // ─────────────────────────────── HELPERS ─────────────────────────────────

  /// Gradient welcome card with CircleAvatar.
  Widget _buildWelcomeRow() {
    final initials = _userName.isNotEmpty
        ? _userName.trim().split(' ').map((p) => p.isNotEmpty ? p[0].toUpperCase() : '').take(2).join()
        : 'F';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_green1, _green2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _green1.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withOpacity(0.25),
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $_userName!',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Manage care for your seniors below.',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Empty state for seniors list.
  Widget _buildEmptySeniors() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('No seniors registered',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF444455))),
          const SizedBox(height: 6),
          Text('Tap the "+" button below to add a senior.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[500])),
        ],
      ),
    );
  }

  /// Senior card with avatar, name, age/gender, and chevron.
  Widget _buildSeniorCard(dynamic senior) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SeniorDetailScreen(senior: senior, userRole: kRoleFamily)),
          );
          _loadData();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                  border: Border.all(color: _green1.withOpacity(0.3), width: 1.5),
                  image: senior['photo'] != null
                      ? DecorationImage(
                          image: NetworkImage('${senior['photo']}?v=${DateTime.now().millisecondsSinceEpoch}'),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: senior['photo'] == null 
                    ? const Icon(Icons.person_rounded, size: 30, color: _green1)
                    : null,
              ),
              const SizedBox(width: 14),
              // Name & details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      senior['name'] ?? 'Senior Name',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Age: ${senior['age']}  •  ${senior['gender'] ?? ''}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              // Chevron
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chevron_right_rounded, size: 20, color: _green1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Feature tile card for the 2-column grid.
  Widget _buildFeatureTile(String title, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1A1A2E)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────── NAVIGATION ───────────────────────────────────

  /// Navigate to a feature. If only one senior – go directly; otherwise ask which senior.
  void _navigateToFeature(String feature) {
    if (_seniors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a senior first.'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (_seniors.length == 1) {
      _openFeatureForSenior(feature, _seniors[0]);
    } else {
      _showSeniorPickerDialog(feature);
    }
  }

  void _showSeniorPickerDialog(String feature) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Select Senior', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _seniors.length,
            itemBuilder: (_, i) {
              final s = _seniors[i];
              return ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFF4CAF50), child: Icon(Icons.person, color: Colors.white)),
                title: Text(s['name'] ?? 'Senior'),
                subtitle: Text('Age: ${s['age']}'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openFeatureForSenior(feature, s);
                },
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))],
      ),
    );
  }

  void _openFeatureForSenior(String feature, dynamic senior) {
    switch (feature) {
      case 'medicines':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => MedicinesScreen(seniorId: senior['id'], userRole: kRoleFamily)));
        break;
      case 'appointments':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => AppointmentsScreen(seniorId: senior['id'], userRole: kRoleFamily)));
        break;
      case 'health_records':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => HealthRecordsScreen(onDataChanged: () {}, seniorId: senior['id'], userRole: kRoleFamily)));
        break;
      case 'vitals':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => VitalsTrackerScreen(seniorId: senior['id'], userRole: kRoleFamily)));
        break;
      case 'doctors':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => DoctorsScreen(seniorId: senior['id'], userRole: kRoleFamily)));
        break;
      case 'emergency':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => EmergencyContactsScreen(onDataChanged: () {}, seniorId: senior['id'], userRole: kRoleFamily)));
        break;
      case 'caretaker':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => MyCaretakerScreen(onDataChanged: () {}, seniorId: senior['id'], userRole: kRoleFamily)));
        break;
      case 'activity':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => DailyActivityScreen(
            seniorId: senior['id'],
            seniorName: senior['name'] ?? 'Senior',
            userRole: kRoleFamily,
          )));
        break;
      case 'help_requests':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => const HelpRequestListScreen(userRole: kRoleFamily)));
        break;
    }
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
}