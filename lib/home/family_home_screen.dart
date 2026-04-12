import 'package:flutter/material.dart';
import 'package:senior_care_app/services/notification_service.dart';
import '../screens/role_selection_screen.dart';
import '../services/api_service.dart';
import '../utils/role_helper.dart';
import '../utils/refresh_mixin.dart';
import '../utils/style_utils.dart';
import '../screens/add_senior_screen.dart';
import '../screens/senior_detail_screen.dart';
import '../screens/medicines_screen.dart';
import '../screens/appointments_screen.dart';
import '../screens/health_records_screen.dart';
import '../screens/vitals_tracker_screen.dart';
import '../screens/doctors_screen.dart';
import '../screens/emergency_contacts_screen.dart';
import '../screens/caretaker_selection_screen.dart';
import '../screens/care_assignment_detail_screen.dart';
import '../screens/daily_activity_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/help_support_screen.dart';
import '../screens/help_request_screens.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_links_widget.dart';
import '../screens/notifications_screen.dart';
import '../screens/buddy_chat_screen.dart';
import '../services/dynamic_theme_service.dart';
import 'package:provider/provider.dart';

/// Family Dashboard — Refactored with Bottom Navigation and Professional Styling
class FamilyHomeScreen extends StatefulWidget {
  const FamilyHomeScreen({Key? key}) : super(key: key);

  @override
  State<FamilyHomeScreen> createState() => _FamilyHomeScreenState();
}

class _FamilyHomeScreenState extends State<FamilyHomeScreen>
    with PeriodicRefreshMixin {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _seniors = [];
  Map<String, dynamic>? _userData;
  String _userName = 'Family Member';
  int _selectedIndex = 0;

  // ── Theme Overrides from style_utils ──────────────────────────────────
  final Color _primary = AppColors.familyPrimary;
  final Color _accent = AppColors.familyAccent;
  final Color _bg = AppColors.bgSoft;

  @override
  Future<void> onRefresh() async {
    await _loadData();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DynamicThemeService>().setRole(kRoleFamily);
      NotificationService().updateToken();
    });
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
          if (_userName.isEmpty)
            _userName = _userData?['username'] ?? 'Family Member';
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
        scrolledUnderElevation: 0,
        backgroundColor: _primary,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppGradients.mainGradient(_primary, _accent),
          ),
        ),
        title: Text(
          _appBarTitle,
          style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 20),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
        ],
      ),

      // ── Body ──────────────────────────────────────────────────────────────
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primary))
          : _buildTabContent(),

      // ── Navigation ────────────────────────────────────────────────────────
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        indicatorColor: _primary.withOpacity(0.12),
        backgroundColor: Colors.white,
        elevation: 10,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: _primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: const Icon(Icons.psychology_outlined),
            selectedIcon: Icon(Icons.psychology, color: _primary),
            label: 'Buddy AI',
          ),
          NavigationDestination(
            icon: const Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view, color: _primary),
            label: 'Features',
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: _primary),
            label: 'Profile',
          ),
        ],
      ),

      // ── FAB ──────────────────────────────────────────────────────────────
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddSeniorScreen()),
                );
                if (result == true) _loadData();
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Senior',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              elevation: 4,
            )
          : null,
    );
  }

  String get _appBarTitle {
    switch (_selectedIndex) {
      case 0: return 'Family Dashboard';
      case 1: return 'Buddy AI';
      case 2: return 'Quick Features';
      case 3: return 'My Profile';
      default: return 'Dashboard';
    }
  }

  Widget _buildTabContent() {
    switch (_selectedIndex) {
      case 0: return _buildHomeTab();
      case 1: return const BuddyChatScreen();
      case 2: return _buildFeaturesTab();
      case 3: return _buildProfileTab();
      default: return _buildHomeTab();
    }
  }

  // ─────────────────────────────── TABS ────────────────────────────────────

  Widget _buildHomeTab() {
    return RefreshIndicator(
      color: _primary,
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeRow(),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.people_outline, color: _primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'My Seniors',
                  style: AppTextStyles.h2,
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
            style: AppTextStyles.h1,
          ),
          const SizedBox(height: 4),
          const Text(
            'Select a feature to manage your senior\'s care.',
            style: AppTextStyles.bodySub,
          ),
          const SizedBox(height: 18),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.3,
            children: [
              _buildFeatureTile(
                  'Medicines',
                  Icons.medication_outlined,
                  const Color(0xFFE53935),
                  () => _navigateToFeature('medicines')),
              _buildFeatureTile(
                  'Appointments',
                  Icons.calendar_today_outlined,
                  const Color(0xFF1E88E5),
                  () => _navigateToFeature('appointments')),
              _buildFeatureTile('Vitals', Icons.monitor_heart_outlined,
                  const Color(0xFFEF6C00), () => _navigateToFeature('vitals')),
              _buildFeatureTile('My Doctors', Icons.medical_services_outlined,
                  const Color(0xFF00897B), () => _navigateToFeature('doctors')),
              _buildFeatureTile(
                  'Emergency Contacts',
                  Icons.contact_emergency_outlined,
                  const Color(0xFF8E24AA),
                  () => _navigateToFeature('emergency')),
              _buildFeatureTile(
                  'Caretaker',
                  Icons.health_and_safety_outlined,
                  const Color(0xFF00ACC1),
                  () => _navigateToFeature('caretaker')),
              _buildFeatureTile(
                  'Activity Reports',
                  Icons.assignment_turned_in_outlined,
                  const Color(0xFF3949AB),
                  () => _navigateToFeature('activity')),
              _buildFeatureTile(
                  'Help Requests',
                  Icons.volunteer_activism_outlined,
                  Colors.orange,
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
                  MaterialPageRoute(
                      builder: (_) =>
                          EditProfileScreen(userData: _userData ?? {})),
                );
                if (updated == true) _loadData();
              },
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit Profile'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primary,
                side: BorderSide(color: _primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 20),

          ProfileLinksWidget(
            onLogout: _handleLogout,
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
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Close', style: TextStyle(color: _primary))),
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
      title: Text(title,
          style: TextStyle(
              fontSize: 17,
              color: textColor ?? Colors.black87,
              fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }

  // ─────────────────────────────── HELPERS ─────────────────────────────────

  /// Gradient welcome card with CircleAvatar.
  Widget _buildWelcomeRow() {
    final initials = _userName.isNotEmpty
        ? _userName
            .trim()
            .split(' ')
            .map((p) => p.isNotEmpty ? p[0].toUpperCase() : '')
            .take(2)
            .join()
        : 'F';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        gradient: AppGradients.mainGradient(_primary, _accent),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.35),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: _primary.withOpacity(0.1),
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _primary,
                ),
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
                  style: AppTextStyles.h2.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage care for your seniors below.',
                  style: AppTextStyles.bodySub.copyWith(color: Colors.white.withOpacity(0.85)),
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
      padding: const EdgeInsets.all(40),
      decoration: AppDecoration.cardDecoration(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.people_outline, size: 52, color: _primary.withOpacity(0.5)),
          ),
          const SizedBox(height: 20),
          const Text('No seniors registered', style: AppTextStyles.h2),
          const SizedBox(height: 8),
          Text('Tap the "+" button below to add a senior.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySub),
        ],
      ),
    );
  }

  /// Senior card with avatar, name, age/gender, and chevron.
  Widget _buildSeniorCard(dynamic senior) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: AppDecoration.cardDecoration(shadowOpacity: 0.05),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    SeniorDetailScreen(senior: senior, userRole: kRoleFamily)),
          );
          _loadData();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: _primary.withOpacity(0.2), width: 1.5),
                  image: senior['photo'] != null
                      ? DecorationImage(
                          image: NetworkImage(
                              '${senior['photo']}?v=${DateTime.now().millisecondsSinceEpoch}'),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: senior['photo'] == null
                    ? Icon(Icons.person_rounded, size: 32, color: _primary)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      senior['name'] ?? 'Senior Name',
                      style: AppTextStyles.h2.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Age: ${senior['age']}  •  ${senior['gender'] ?? ''}',
                      style: AppTextStyles.bodySub,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.chevron_right_rounded,
                    size: 20, color: _primary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Feature tile card for the 2-column grid.
  Widget _buildFeatureTile(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: AppDecoration.cardDecoration(shadowOpacity: 0.05),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMain.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
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
        const SnackBar(
            content: Text('Please add a senior first.'),
            backgroundColor: Colors.orange),
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
        title: const Text('Select Senior',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _seniors.length,
            itemBuilder: (_, i) {
              final s = _seniors[i];
              return ListTile(
                leading: const CircleAvatar(
                    backgroundColor: Color(0xFF4CAF50),
                    child: Icon(Icons.person, color: Colors.white)),
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
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))
        ],
      ),
    );
  }

  Future<void> _openFeatureForSenior(String feature, dynamic senior) async {
    switch (feature) {
      case 'medicines':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => MedicinesScreen(
                    seniorId: senior['id'], userRole: kRoleFamily)));
        break;
      case 'appointments':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => AppointmentsScreen(
                    seniorId: senior['id'], userRole: kRoleFamily)));
        break;
      case 'vitals':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => VitalsTrackerScreen(
                    seniorId: senior['id'], userRole: kRoleFamily)));
        break;
      case 'doctors':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => DoctorsScreen(
                    seniorId: senior['id'], userRole: kRoleFamily)));
        break;
      case 'emergency':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => EmergencyContactsScreen(
                    onDataChanged: () {},
                    seniorId: senior['id'],
                    userRole: kRoleFamily)));
        break;
      case 'caretaker':
        final assignmentsResult = await ApiService().getCareAssignments();
        if (assignmentsResult['success']) {
          final assignments = assignmentsResult['data'] as List;
          final assignment = assignments.firstWhere(
            (a) => a['senior'] == senior['id'],
            orElse: () => null,
          );

          if (assignment != null) {
            final caretakerInfo = await ApiService().getList(
                'care-assignments/my_caretaker/?senior=${senior['id']}');
            if (caretakerInfo['success']) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CareAssignmentDetailScreen(
                    assignment: {
                      ...caretakerInfo['raw'],
                      'assignment_id': assignment['id'],
                    },
                  ),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      CaretakerSelectionScreen(seniorId: senior['id']),
                ),
              );
            }
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    CaretakerSelectionScreen(seniorId: senior['id']),
              ),
            );
          }
        }
        break;
      case 'activity':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => DailyActivityScreen(
                      seniorId: senior['id'],
                      seniorName: senior['name'] ?? 'Senior',
                      userRole: kRoleFamily,
                    )));
        break;
      case 'help_requests':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    HelpRequestListScreen(userRole: kRoleFamily, seniorId: senior['id'])));
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
