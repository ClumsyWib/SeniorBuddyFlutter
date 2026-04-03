import 'package:flutter/material.dart';
import 'package:senior_care_app/screens/role_selection_screen.dart';
import '../services/api_service.dart';
import '../utils/role_helper.dart';
import '../screens/senior_detail_screen.dart';
import '../screens/daily_activity_screen.dart';
import '../screens/vitals_tracker_screen.dart';
import '../screens/medicines_screen.dart';
import '../screens/appointments_screen.dart';
import '../screens/emergency_contacts_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/buddy_chat_screen.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_links_widget.dart';

/// Caretaker Dashboard
///
/// Visible features:
///   Daily Activity (add) | Vitals Tracker (add) | Medicine Schedule (view)
///   Appointments (view)  | Emergency Contacts (view)
class CaretakerHomeScreen extends StatefulWidget {
  const CaretakerHomeScreen({Key? key}) : super(key: key);

  @override
  State<CaretakerHomeScreen> createState() => _CaretakerHomeScreenState();
}

class _CaretakerHomeScreenState extends State<CaretakerHomeScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _seniors = [];
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _caretakerProfile;
  String _userName = 'Caretaker';
  int _selectedIndex = 0;

  // ── Palette ──────────────────────────────────────────────────────────────
  static const Color _blue1 = Color(0xFF2196F3);
  static const Color _bg = Color(0xFFF0F7FF);
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);
    
    // Load all data in parallel
    final results = await Future.wait([
      _apiService.getCurrentUser(),
      _apiService.getSeniors(),
      _apiService.getCaretakerProfile(),
    ]);

    if (mounted) {
      setState(() {
        // User data
        if (results[0]['success']) {
          _userData = results[0]['data'];
          final firstName = _userData?['first_name'] ?? '';
          final lastName = _userData?['last_name'] ?? '';
          _userName = '$firstName $lastName'.trim();
          if (_userName.isEmpty) _userName = _userData?['username'] ?? 'Caretaker';
        }

        // Assigned Seniors
        if (results[1]['success']) {
          _seniors = results[1]['data'];
        }

        // Caretaker Profile
        if (results[2]['success']) {
          _caretakerProfile = results[2]['data'];
        }

        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,

      // ── AppBar ────────────────────────────────────────────────────────────
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _blue1,
        title: Text(
          _appBarTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        automaticallyImplyLeading: false,
        actions: null,
      ),

      // ── Body ──────────────────────────────────────────────────────────────
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: _blue1))
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
        destinations: const [
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


  String get _appBarTitle {
    switch (_selectedIndex) {
      case 0: return 'Caretaker Dashboard';
      case 1: return 'Caretaker Tools';
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
      color: _blue1,
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, $_userName! 👋',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Manage care for your assigned seniors.',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Assigned Seniors', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: _loadData, 
                  child: const Text('Refresh', style: TextStyle(color: _blue1))
                ),
              ],
            ),
            const SizedBox(height: 16),
            
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
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────── FEATURES TAB ──────────────────────────────

  Widget _buildFeaturesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Caretaker Tools', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Select a feature to record or view senior care data.',
              style: TextStyle(fontSize: 15, color: Colors.grey)),
          const SizedBox(height: 24),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.0,
            children: [
              _buildFeatureTile(
                'Daily Activity',
                Icons.assignment_turned_in,
                Colors.blue,
                '+ Add care log',
                () => _navigateToFeature('activity'),
              ),
              _buildFeatureTile(
                'Vitals Tracker',
                Icons.monitor_heart,
                const Color(0xFFE91E63),
                '+ Record vitals',
                () => _navigateToFeature('vitals'),
              ),
              _buildFeatureTile(
                'Medicines',
                Icons.medication,
                Colors.redAccent,
                'View schedule',
                () => _navigateToFeature('medicines'),
              ),
              _buildFeatureTile(
                'Appointments',
                Icons.calendar_today,
                Colors.blueAccent,
                'View upcoming',
                () => _navigateToFeature('appointments'),
              ),
              _buildFeatureTile(
                'Emergency',
                Icons.contact_emergency,
                Colors.orange,
                'Contact info',
                () => _navigateToFeature('emergency'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ────────────────────────────── PROFILE TAB ───────────────────────────────

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          ProfileHeader(
            userData: _userData,
            userRole: kRoleCaretaker,
          ),
          const SizedBox(height: 28),
          
          // Edit Profile Button
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
                foregroundColor: _blue1,
                side: const BorderSide(color: _blue1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (_caretakerProfile != null) ...[
            _buildProfileSection('Professional Info', [
              _buildProfileDataRow(Icons.history, 'Experience', '${_caretakerProfile!['experience_years']} Years'),
              _buildProfileDataRow(Icons.psychology_outlined, 'Skills', _caretakerProfile!['skills'] ?? 'General Care'),
              _buildProfileDataRow(Icons.payments_outlined, 'Hourly Rate', '\$${_caretakerProfile!['hourly_rate']}/hr'),
            ]),
            const SizedBox(height: 16),
            _buildProfileSection('Verification & Status', [
              _buildProfileDataRow(
                Icons.verified_user_outlined, 
                'Background Check', 
                _caretakerProfile!['background_check_completed'] == true ? 'Completed' : 'Pending',
                valueColor: _caretakerProfile!['background_check_completed'] == true ? Colors.green : Colors.orange,
              ),
              _buildProfileDataRow(
                Icons.event_available, 
                'Currently Available', 
                _caretakerProfile!['is_available'] == true ? 'Yes' : 'No',
                valueColor: _caretakerProfile!['is_available'] == true ? Colors.green : Colors.red,
              ),
            ]),
          ],

          const SizedBox(height: 24),
          
          ProfileLinksWidget(
            onLogout: _handleLogout,
            primaryColor: _blue1,
          ),
          const SizedBox(height: 30),
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
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _blue1),
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

  Widget _buildProfileDataRow(IconData icon, String label, String value, {Color? valueColor}) {
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
                  value.isEmpty || value == ',' ? 'N/A' : value,
                  style: TextStyle(
                    fontSize: 15, 
                    fontWeight: FontWeight.w600, 
                    color: valueColor ?? const Color(0xFF2D3142)
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────── HELPERS ─────────────────────────────────

  /// Navigate to a feature. Picks senior automatically if only one, else shows picker.
  void _navigateToFeature(String feature) {
    if (_seniors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No assigned seniors found.'), backgroundColor: Colors.orange),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Select Senior', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _seniors.length,
            itemBuilder: (_, i) {
              final s = _seniors[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _blue1.withOpacity(0.1), 
                  child: const Icon(Icons.person, color: _blue1)
                ),
                title: Text(s['name'] ?? 'Senior', style: const TextStyle(fontWeight: FontWeight.w600)),
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
      case 'activity':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => DailyActivityScreen(
            seniorId: senior['id'],
            seniorName: senior['name'] ?? 'Senior',
            userRole: kRoleCaretaker,
          )));
        break;
      case 'vitals':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => VitalsTrackerScreen(seniorId: senior['id'], userRole: kRoleCaretaker)));
        break;
      case 'medicines':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => MedicinesScreen(seniorId: senior['id'], userRole: kRoleCaretaker)));
        break;
      case 'appointments':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => AppointmentsScreen(seniorId: senior['id'], userRole: kRoleCaretaker)));
        break;
      case 'emergency':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => EmergencyContactsScreen(onDataChanged: () {}, seniorId: senior['id'], userRole: kRoleCaretaker)));
        break;
    }
  }

  Widget _buildEmptySeniors() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(Icons.assignment_ind_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('No seniors assigned', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('You will see your assigned seniors here once added by a family member.', 
              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildSeniorCard(dynamic senior) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SeniorDetailScreen(senior: senior, userRole: kRoleCaretaker)),
          );
          _loadData();
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _blue1.withOpacity(0.1), 
                  shape: BoxShape.circle,
                  image: senior['photo'] != null
                      ? DecorationImage(
                          image: NetworkImage('${senior['photo']}?v=${DateTime.now().millisecondsSinceEpoch}'),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: senior['photo'] == null 
                    ? const Icon(Icons.person, size: 35, color: _blue1)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(senior['name'] ?? 'Senior Name',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Age: ${senior['age']} | ${senior['gender'] ?? 'Not specified'}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureTile(String title, IconData icon, Color color, String subtitle, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
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
                decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 10),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              const SizedBox(height: 4),
              Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
