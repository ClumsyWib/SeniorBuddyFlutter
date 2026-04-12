import 'package:flutter/material.dart';
import 'package:senior_care_app/services/notification_service.dart';
import '../services/api_service.dart';
import '../utils/role_helper.dart';
import '../utils/refresh_mixin.dart';
import '../utils/style_utils.dart';
import '../screens/medicines_screen.dart';
import '../screens/appointments_screen.dart';
import '../screens/vitals_tracker_screen.dart';
import '../screens/daily_activity_screen.dart';
import '../screens/emergency_contacts_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/role_selection_screen.dart';
import '../widgets/profile_links_widget.dart';
import '../screens/medicine_detail_screen.dart';
import '../screens/appointment_detail_screen.dart';
import '../screens/contact_detail_screen.dart';
import '../screens/buddy_chat_screen.dart';
import '../utils/emergency_helper.dart';
import '../services/dynamic_theme_service.dart';
import 'package:provider/provider.dart';

/// Senior Dashboard — Premium UI & Auto-Refresh
class SeniorHomeScreen extends StatefulWidget {
  const SeniorHomeScreen({Key? key}) : super(key: key);

  @override
  State<SeniorHomeScreen> createState() => _SeniorHomeScreenState();
}

class _SeniorHomeScreenState extends State<SeniorHomeScreen>
    with SingleTickerProviderStateMixin, PeriodicRefreshMixin {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _userName = 'Senior';
  int? _seniorId;
  int _selectedIndex = 0;
  Map<String, dynamic>? _seniorProfile;
  Map<String, dynamic>? _userData;

  // ── Palette from StyleUtils ──────────────────────────────────────────
  final Color _primary = AppColors.seniorPrimary;
  final Color _accent = AppColors.seniorAccent;
  final Color _bg = AppColors.bgSoft;

  // Quick-preview data
  List<dynamic> _medicines = [];
  List<dynamic> _appointments = [];
  List<dynamic> _contacts = [];

  // SOS pulse animation
  late AnimationController _sosController;
  late Animation<double> _sosScale;

  @override
  Future<void> onRefresh() => _loadData();

  @override
  void initState() {
    super.initState();
    _sosController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _sosScale = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _sosController, curve: Curves.easeInOut),
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DynamicThemeService>().setRole(kRoleSenior);
      NotificationService().updateToken();
    });
    _loadData();
  }

  @override
  void dispose() {
    _sosController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    _seniorId = await _apiService.getSeniorId();
    final userResult = await _apiService.getCurrentUser();
    if (userResult['success']) {
      if (mounted) {
        setState(() {
          _userData = userResult['data'];
          final firstName = _userData!['first_name'] ?? '';
          final lastName = _userData!['last_name'] ?? '';
          _userName = '$firstName $lastName'.trim();
          if (_userName.isEmpty) _userName = _userData!['username'] ?? 'Senior';
          _seniorId ??= _userData!['id'];
        });
      }
    }

    final results = await Future.wait([
      _apiService.getMedicines(seniorId: _seniorId),
      _apiService.getUpcomingAppointments(seniorId: _seniorId),
      _apiService.getEmergencyContacts(seniorId: _seniorId),
      (_seniorId != null)
          ? _apiService.getSeniorProfile(_seniorId!)
          : Future.value({'success': false}),
    ]);

    if (mounted) {
      setState(() {
        if (results[0]['success'] == true) {
          _medicines = results[0]['data'] ?? [];
          _medicines.sort((a, b) {
            final dateA = (a['start_date'] ?? '').toString();
            final dateB = (b['start_date'] ?? '').toString();
            int dateComp = dateA.compareTo(dateB);
            if (dateComp != 0) return dateComp;

            final order = ['morning', 'noon', 'afternoon', 'evening', 'night'];
            final timeA = (a['time_of_day'] ?? '').toString().toLowerCase();
            final timeB = (b['time_of_day'] ?? '').toString().toLowerCase();
            final idxA = order.indexOf(timeA);
            final idxB = order.indexOf(timeB);
            if (idxA != -1 && idxB != -1) return idxA.compareTo(idxB);
            if (idxA != -1) return -1;
            if (idxB != -1) return 1;
            return timeA.compareTo(timeB);
          });
        }
        if (results[1]['success'] == true) {
          _appointments = results[1]['data'] ?? [];
          _appointments.sort((a, b) {
            int dateComp = (a['appointment_date'] ?? '').compareTo(b['appointment_date'] ?? '');
            if (dateComp != 0) return dateComp;
            return (a['appointment_time'] ?? '').compareTo(b['appointment_time'] ?? '');
          });
        }
        if (results[2]['success'] == true) _contacts = results[2]['data'] ?? [];
        if (results[3]['success'] == true) _seniorProfile = results[3]['data'];
        _isLoading = false;
      });
    }
  }

  Future<void> _triggerEmergency() async {
    await EmergencyHelper.triggerSOS(context, _seniorId);
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
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotificationsScreen()),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
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
    );
  }

  String get _appBarTitle {
    switch (_selectedIndex) {
      case 0: return 'My Care Dashboard';
      case 1: return 'Buddy AI';
      case 2: return 'Care Features';
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
            // ── Greeting ──────────────────────────────────────────
            Text(
              'Hello, ${_seniorProfile?['name'] ?? _userName}! 👋',
              style: AppTextStyles.h1.copyWith(fontSize: 26),
            ),
            const SizedBox(height: 4),
            Text(
              'Here is your care overview for today.',
              style: AppTextStyles.bodySub,
            ),
            const SizedBox(height: 24),

            // ── SOS Button (pulsing) ──────────────────────────────
            AnimatedBuilder(
              animation: _sosScale,
              builder: (context, child) => Transform.scale(
                scale: _sosScale.value,
                child: child,
              ),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD32F2F), Color(0xFFFF5252)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.40),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _triggerEmergency,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              size: 32, color: Colors.white),
                          const SizedBox(width: 12),
                          Text(
                            'SOS — EMERGENCY',
                            style: AppTextStyles.h2.copyWith(
                                color: Colors.white,
                                letterSpacing: 1.2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── Medicine Reminders ────────────────────────────────
            _buildSectionHeader('Medicine Reminders', Icons.medication_outlined, _primary,
                onViewMore: () {
              if (_seniorId != null) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => MedicinesScreen(
                            seniorId: _seniorId, userRole: kRoleSenior)));
              }
            }),
            const SizedBox(height: 12),
            _medicines.isEmpty
                ? _buildEmptyCard('No medicines currently scheduled.', Icons.medication_outlined, _primary)
                : Column(
                    children: [
                      ..._medicines.take(3).map((m) => _buildMedicineCard(m, _primary)).toList(),
                    ],
                  ),
            const SizedBox(height: 28),

            // ── Upcoming Appointments ─────────────────────────────
            _buildSectionHeader('Upcoming Appointments', Icons.event_outlined, _primary,
                onViewMore: () {
              if (_seniorId != null) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => AppointmentsScreen(
                            seniorId: _seniorId, userRole: kRoleSenior)));
              }
            }),
            const SizedBox(height: 12),
            _appointments.isEmpty
                ? _buildEmptyCard('No upcoming appointments.', Icons.event_outlined, _primary)
                : Column(
                    children: [
                      ..._appointments.take(3).map((a) => _buildAppointmentCard(a, _primary)).toList(),
                    ],
                  ),
            const SizedBox(height: 28),

            // ── Emergency Contacts ────────────────────────────────
            _buildSectionHeader('Emergency Contacts', Icons.contact_emergency_outlined, _primary,
                onViewMore: () {
              if (_seniorId != null) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => EmergencyContactsScreen(
                              onDataChanged: () {},
                              seniorId: _seniorId,
                              userRole: kRoleSenior,
                            )));
              }
            }),
            const SizedBox(height: 12),
            _contacts.isEmpty
                ? _buildEmptyCard('No emergency contacts added.', Icons.contact_emergency_outlined, _primary)
                : Column(
                    children: [
                      ..._contacts.take(3).map((c) => _buildContactCard(c)).toList(),
                    ],
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
          const Text('Care Features', style: AppTextStyles.h1),
          const SizedBox(height: 6),
          const Text('View your medical records and care details.', style: AppTextStyles.bodySub),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: [
              _buildViewTile('Medicines', Icons.medication_outlined, _primary, () {
                if (_seniorId != null) {
                  Navigator.push(context, MaterialPageRoute(
                      builder: (_) => MedicinesScreen(seniorId: _seniorId, userRole: kRoleSenior)));
                }
              }),
              _buildViewTile('Appointments', Icons.calendar_today_outlined, _primary, () {
                if (_seniorId != null) {
                  Navigator.push(context, MaterialPageRoute(
                      builder: (_) => AppointmentsScreen(seniorId: _seniorId, userRole: kRoleSenior)));
                }
              }),
              _buildViewTile('Vitals', Icons.monitor_heart_outlined, _primary, () {
                if (_seniorId != null) {
                  Navigator.push(context, MaterialPageRoute(
                      builder: (_) => VitalsTrackerScreen(seniorId: _seniorId!, userRole: kRoleSenior)));
                }
              }),
              _buildViewTile('Daily Activity', Icons.directions_run_outlined, _primary, () {
                if (_seniorId != null) {
                  Navigator.push(context, MaterialPageRoute(
                      builder: (_) => DailyActivityScreen(
                            seniorId: _seniorId!,
                            seniorName: _userName,
                            userRole: kRoleSenior,
                          )));
                }
              }),

              _buildViewTile('Emergency', Icons.contact_emergency_outlined, _primary, () {
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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          // ── Avatar ──────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [_primary.withOpacity(0.3), _primary.withOpacity(0.1)],
              ),
              boxShadow: [
                BoxShadow(
                  color: _primary.withOpacity(0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 70,
              backgroundColor: Colors.white,
              backgroundImage: _seniorProfile?['photo'] != null
                  ? NetworkImage(_seniorProfile!['photo'])
                  : null,
              child: _seniorProfile?['photo'] == null
                  ? Icon(Icons.person, size: 80, color: _primary)
                  : null,
            ),
          ),
          const SizedBox(height: 20),

          // ── Name ────────────────────────────────────────────────
          Text(
            _seniorProfile?['name'] ?? _userName,
            textAlign: TextAlign.center,
            style: AppTextStyles.h1.copyWith(fontSize: 30),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Senior Citizen',
              style: AppTextStyles.labelPremium.copyWith(color: _primary),
            ),
          ),
          const SizedBox(height: 32),
 
          // ── Personal Info Card ────────────────────────────────
          _buildLargeInfoCard(
            title: 'Personal Info',
            icon: Icons.person_outline,
            color: _primary.withOpacity(0.04),
            titleColor: _primary,
            items: [
              _buildLargeInfoRow('Age', '${_seniorProfile?['age'] ?? '-'} years', Icons.cake_outlined),
              _buildLargeInfoRow('Gender', _seniorProfile?['gender'] ?? 'Not set', Icons.wc_outlined),
              _buildLargeInfoRow('City', _seniorProfile?['city'] ?? 'Not set', Icons.location_city_outlined),
              _buildLargeInfoRow('Address', _seniorProfile?['address'] ?? 'Not set', Icons.home_outlined),
            ],
          ),
          const SizedBox(height: 20),
 
          // ── Health & Safety Card ──────────────────────────────
          _buildLargeInfoCard(
            title: 'Health & Safety',
            icon: Icons.health_and_safety_outlined,
            color: Colors.red.withOpacity(0.04),
            titleColor: Colors.red,
            items: [
              _buildLargeInfoRow('Medical Info', _seniorProfile?['medical_conditions'] ?? 'No info', Icons.medical_information_outlined),
              _buildLargeInfoRow('Allergies', _seniorProfile?['allergies'] ?? 'None', Icons.warning_amber_outlined),
            ],
          ),
          const SizedBox(height: 36),

          ProfileLinksWidget(
            onLogout: _handleLogout,
            showSettings: false,
            showSecurity: false,
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
    return Container(
      decoration: AppDecoration.cardDecoration(color: color, shadowOpacity: 0),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: titleColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: titleColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.h2.copyWith(color: titleColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: titleColor.withOpacity(0.1)),
            const SizedBox(height: 16),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildLargeInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.textSub.withOpacity(0.6)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: AppTextStyles.labelPremium.copyWith(color: AppColors.textSub, fontSize: 10),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? 'Not set' : value,
                  style: AppTextStyles.bodyMain.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
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

  // ────────────────────────────── HELPERS ─────────────────────────────────

  Widget _buildViewTile(String title, IconData icon, Color color, VoidCallback onTap) {
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMain.copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color, {VoidCallback? onViewMore}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(title, style: AppTextStyles.h2.copyWith(fontSize: 18)),
        ),
        if (onViewMore != null)
          TextButton(
            onPressed: onViewMore,
            child: Text('View All', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
      ],
    );
  }

  Widget _buildEmptyCard(String message, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppDecoration.cardDecoration(shadowOpacity: 0.04),
      child: Row(
        children: [
          Icon(icon, color: color.withOpacity(0.4), size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(message, style: AppTextStyles.bodySub),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineCard(dynamic m, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppDecoration.cardDecoration(shadowOpacity: 0.05),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.medication_rounded, color: primaryColor, size: 24),
        ),
        title: Text(m['medicine_name'] ?? 'Medicine', style: AppTextStyles.bodyMain.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Text('${m['dosage'] ?? ''} • ${m['frequency'] ?? ''}', style: AppTextStyles.bodySub),
        onTap: () async {
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => MedicineDetailScreen(medicine: m, userRole: kRoleSenior)));
          _loadData();
        },
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: _bg, shape: BoxShape.circle),
          child: Icon(Icons.chevron_right_rounded, color: primaryColor, size: 20),
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(dynamic a, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppDecoration.cardDecoration(shadowOpacity: 0.05),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.calendar_today_rounded, color: primaryColor, size: 24),
        ),
        title: Text(a['title'] ?? 'Appointment', style: AppTextStyles.bodyMain.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Text('${a['appointment_date']} at ${a['appointment_time']}', style: AppTextStyles.bodySub),
        onTap: () async {
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => AppointmentDetailScreen(appointment: a, userRole: kRoleSenior)));
          _loadData();
        },
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: _bg, shape: BoxShape.circle),
          child: Icon(Icons.chevron_right_rounded, color: primaryColor, size: 20),
        ),
      ),
    );
  }

  Widget _buildContactCard(dynamic c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppDecoration.cardDecoration(shadowOpacity: 0.05),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.person, color: _primary, size: 24),
        ),
        title: Text(c['name'] ?? 'Contact',
            style: AppTextStyles.bodyMain.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Text('${c['relationship'] ?? ''} • ${c['phone'] ?? ''}',
            style: AppTextStyles.bodySub),
        trailing: Icon(Icons.call_outlined, color: _primary, size: 22),
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ContactDetailScreen(contact: c))),
      ),
    );
  }

  String _formatTo12Hour(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return 'N/A';
    try {
      // Handles HH:mm:ss or HH:mm
      final parts = timeStr.split(':');
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      final period = hour >= 12 ? 'PM' : 'AM';
      hour = hour % 12;
      if (hour == 0) hour = 12;
      final minuteStr = minute.toString().padLeft(2, '0');
      return '$hour:$minuteStr $period';
    } catch (e) {
      return timeStr;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'taken':
      case 'completed':
        return Colors.green;
      case 'missed':
      case 'cancelled':
        return Colors.red;
      case 'scheduled':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }
}
