import 'package:flutter/material.dart';
import 'package:senior_care_app/services/notification_service.dart';
import '../screens/role_selection_screen.dart';
import '../services/api_service.dart';
import '../utils/role_helper.dart';
import '../utils/refresh_mixin.dart';
import '../utils/style_utils.dart';
import '../screens/senior_detail_screen.dart';
import '../screens/daily_activity_screen.dart';
import '../screens/vitals_tracker_screen.dart';
import '../screens/medicines_screen.dart';
import '../screens/appointments_screen.dart';
import '../screens/emergency_contacts_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_links_widget.dart';
import '../screens/notifications_screen.dart';
import '../screens/buddy_chat_screen.dart';
import '../services/dynamic_theme_service.dart';
import 'package:provider/provider.dart';

/// Caretaker Dashboard — Premium UI & Auto-Refresh
class CaretakerHomeScreen extends StatefulWidget {
  const CaretakerHomeScreen({Key? key}) : super(key: key);

  @override
  State<CaretakerHomeScreen> createState() => _CaretakerHomeScreenState();
}

class _CaretakerHomeScreenState extends State<CaretakerHomeScreen>
    with PeriodicRefreshMixin {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _seniors = [];
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _caretakerProfile;
  String _userName = 'Caretaker';
  int _selectedIndex = 0;

  // ── Palette from StyleUtils ──────────────────────────────────────────
  final Color _primary = AppColors.caretakerPrimary;
  final Color _accent = AppColors.caretakerAccent;
  final Color _bg = AppColors.bgSoft;

  @override
  Future<void> onRefresh() => _loadData();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DynamicThemeService>().setRole(kRoleCaretaker);
      NotificationService().updateToken();
    });
    _loadData();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      _apiService.getCurrentUser(),
      _apiService.getSeniors(),
      _apiService.getCaretakerProfile(),
    ]);

    if (mounted) {
      setState(() {
        if (results[0]['success']) {
          _userData = results[0]['data'];
          final firstName = _userData?['first_name'] ?? '';
          final lastName = _userData?['last_name'] ?? '';
          _userName = '$firstName $lastName'.trim();
          if (_userName.isEmpty) _userName = _userData?['username'] ?? 'Caretaker';
        }
        if (results[1]['success']) _seniors = results[1]['data'];
        if (results[2]['success']) _caretakerProfile = results[2]['data'];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primary))
          : _buildTabContent(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
      backgroundColor: Colors.white,
      elevation: 10,
      indicatorColor: _primary.withOpacity(0.12),
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home, color: _primary),
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
    );
  }

  String get _appBarTitle {
    switch (_selectedIndex) {
      case 0: return 'Caretaker Dashboard';
      case 1: return 'Buddy AI';
      case 2: return 'Caretaker Tools';
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

  // ────────────────────────────── HOME TAB ────────────────────────────────

  Widget _buildHomeTab() {
    return RefreshIndicator(
      color: _primary,
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Welcome Card ──────────────────────────────────────
            Container(
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
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.health_and_safety, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome, $_userName! 👋',
                            style: AppTextStyles.h2.copyWith(color: Colors.white)),
                        const SizedBox(height: 4),
                        Text('Manage care for your assigned seniors.',
                            style: AppTextStyles.bodySub.copyWith(color: Colors.white.withOpacity(0.8))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Assigned Seniors Header ────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                    const Text('Assigned Seniors', style: AppTextStyles.h2),
                  ],
                ),
                TextButton.icon(
                  onPressed: onRefresh,
                  icon: Icon(Icons.refresh, size: 18, color: _primary),
                  label: Text('Sync', style: TextStyle(color: _primary, fontWeight: FontWeight.bold)),
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
                    itemBuilder: (context, index) => _buildSeniorCard(_seniors[index]),
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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Caretaker Tools', style: AppTextStyles.h1),
          const SizedBox(height: 6),
          const Text('Select a feature to record or view senior care data.', style: AppTextStyles.bodySub),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.0,
            children: [
              _buildFeatureTile('Daily Activity', Icons.assignment_turned_in_outlined, Colors.blue, '+ Add log', () => _navigateToFeature('activity')),
              _buildFeatureTile('Vitals Tracker', Icons.monitor_heart_outlined, const Color(0xFFE91E63), '+ Record', () => _navigateToFeature('vitals')),
              _buildFeatureTile('Medicines', Icons.medication_outlined, Colors.redAccent, 'Schedule', () => _navigateToFeature('medicines')),
              _buildFeatureTile('Appointments', Icons.calendar_today_outlined, Colors.indigo, 'Upcoming', () => _navigateToFeature('appointments')),
              _buildFeatureTile('Emergency', Icons.contact_emergency_outlined, Colors.orange, 'Contact info', () => _navigateToFeature('emergency')),

            ],
          ),
        ],
      ),
    );
  }

  // ────────────────────────────── PROFILE TAB ───────────────────────────────

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          ProfileHeader(userData: _userData, userRole: kRoleCaretaker),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => EditProfileScreen(userData: _userData ?? {})),
                );
                if (updated == true) onRefresh();
              },
              icon: const Icon(Icons.edit_outlined, size: 20),
              label: const Text('Edit Profile'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primary,
                side: BorderSide(color: _primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (_caretakerProfile != null) ...[
            _buildProfileSection('Professional Info', [
              _buildProfileDataRow(Icons.history, 'Experience',
                  '${_caretakerProfile!['experience_years']} Years'),
              _buildProfileDataRow(Icons.psychology_outlined, 'Skills',
                  _caretakerProfile!['skills'] ?? 'General Care'),
              _buildProfileDataRow(Icons.payments_outlined, 'Hourly Rate',
                  '\$${_caretakerProfile!['hourly_rate']}/hr'),
            ]),
          ],

          const SizedBox(height: 32),
          ProfileLinksWidget(onLogout: _handleLogout),
          const SizedBox(height: 40),
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
          padding: const EdgeInsets.only(bottom: 10, left: 4),
          child: Text(title.toUpperCase(),
              style: AppTextStyles.labelPremium.copyWith(color: _primary)),
        ),
        Container(
          decoration: AppDecoration.cardDecoration(shadowOpacity: 0.05),
          padding: const EdgeInsets.all(16),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildProfileDataRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: _primary.withOpacity(0.6)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.bodySub.copyWith(fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty || value == ',' ? 'N/A' : value,
                  style: AppTextStyles.bodyMain.copyWith(
                      fontWeight: FontWeight.w600,
                      color: valueColor ?? AppColors.textMain),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────── HELPERS ─────────────────────────────────

  void _navigateToFeature(String feature) {
    if (_seniors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No assigned seniors found.'),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.people_outline, color: _primary),
            const SizedBox(width: 12),
            const Text('Select Senior', style: AppTextStyles.h2),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _seniors.length,
            itemBuilder: (_, i) {
              final s = _seniors[i];
              return ListTile(
                leading: CircleAvatar(
                    backgroundColor: _primary.withOpacity(0.1),
                    child: Icon(Icons.person, color: _primary)),
                title: Text(s['name'] ?? 'Senior', style: AppTextStyles.bodyMain.copyWith(fontWeight: FontWeight.bold)),
                subtitle: Text('Age: ${s['age']}', style: AppTextStyles.bodySub),
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
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: _primary)))
        ],
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
            builder: (_) => EmergencyContactsScreen(
                onDataChanged: () {},
                seniorId: senior['id'],
                userRole: kRoleCaretaker)));
        break;
    }
  }

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
            child: Icon(Icons.assignment_ind_outlined, size: 52, color: _primary.withOpacity(0.5)),
          ),
          const SizedBox(height: 20),
          const Text('No seniors assigned', style: AppTextStyles.h2),
          const SizedBox(height: 8),
          const Text(
              'You will see your assigned seniors here once added by a family member.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySub),
        ],
      ),
    );
  }

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
                    SeniorDetailScreen(senior: senior, userRole: kRoleCaretaker)),
          );
          onRefresh();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                    ? Icon(Icons.person, size: 32, color: _primary)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(senior['name'] ?? 'Senior Name',
                        style: AppTextStyles.h2.copyWith(fontSize: 18)),
                    const SizedBox(height: 4),
                    Text('Age: ${senior['age']} | ${senior['gender'] ?? 'Not specified'}',
                        style: AppTextStyles.bodySub),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.chevron_right_rounded, size: 20, color: _primary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureTile(
      String title, IconData icon, Color color, String subtitle, VoidCallback onTap) {
    return Container(
      decoration: AppDecoration.cardDecoration(shadowOpacity: 0.05),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 10),
              Text(title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMain.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySub.copyWith(fontSize: 11, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

