import 'package:flutter/material.dart';
import 'package:senior_care_app/services/notification_service.dart';
import '../services/api_service.dart';
import '../screens/settings_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_links_widget.dart';
import '../utils/role_helper.dart';
import '../utils/refresh_mixin.dart';
import '../utils/style_utils.dart';
import '../screens/role_selection_screen.dart';
import '../screens/help_request_screens.dart';
import '../screens/buddy_chat_screen.dart';
import '../screens/volunteer_proof_screen.dart';
import '../screens/notifications_screen.dart';
import '../services/dynamic_theme_service.dart';
import 'package:provider/provider.dart';

/// Volunteer Dashboard — Premium UI & Auto-Refresh
class VolunteerHomeScreen extends StatefulWidget {
  const VolunteerHomeScreen({Key? key}) : super(key: key);

  @override
  State<VolunteerHomeScreen> createState() => _VolunteerHomeScreenState();
}

class _VolunteerHomeScreenState extends State<VolunteerHomeScreen>
    with PeriodicRefreshMixin {
  final ApiService _api = ApiService();

  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _isLoadingTasks = false;

  Map<String, dynamic>? _userData;
  String _userName = 'Volunteer';
  List<dynamic> _tasks = [];
  List<dynamic> _leaderboard = [];
  Map<String, dynamic> _dashboardStats = {};

  // ── Palette from StyleUtils ──────────────────────────────────────────
  final Color _primary = AppColors.volunteerPrimary;
  final Color _accent = AppColors.volunteerAccent;
  final Color _bg = AppColors.bgSoft;

  @override
  Future<void> onRefresh() => _loadAll();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DynamicThemeService>().setRole(kRoleVolunteer);
      NotificationService().updateToken();
    });
    _loadAll();
  }

  Future<void> _loadAll() async {
    final userResult = await _api.getCurrentUser();
    if (mounted) {
      setState(() {
        if (userResult['success'] == true) {
          _userData = userResult['data'];
          final fn = _userData?['first_name'] ?? '';
          final ln = _userData?['last_name'] ?? '';
          _userName = '$fn $ln'.trim();
          if (_userName.isEmpty) _userName = _userData?['username'] ?? 'Volunteer';
        }
        _isLoading = false;
      });
    }

    await Future.wait([
      _loadTasks(),
      _loadDashboardStats(),
      _loadLeaderboard(),
    ]);
  }

  Future<void> _loadLeaderboard() async {
    final result = await _api.getVolunteerLeaderboard();
    if (mounted && result['success'] == true) {
      setState(() => _leaderboard = result['data'] ?? []);
    }
  }

  Future<void> _loadDashboardStats() async {
    final result = await _api.getVolunteerDashboard();
    if (mounted) {
      if (result['success'] == true) {
        setState(() {
          _dashboardStats = result['data'] ?? {};
        });
      }
    }
  }

  Future<void> _loadTasks() async {
    if (mounted) setState(() => _isLoadingTasks = true);
    final result = await _api.getTasks();
    if (mounted) {
      setState(() {
        _isLoadingTasks = false;
        if (result['success'] == true) {
          _tasks = result['data'] ?? [];
        }
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
          : _buildBody(),
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
      onDestinationSelected: (i) => setState(() => _selectedIndex = i),
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
            icon: const Icon(Icons.volunteer_activism_outlined),
            selectedIcon: Icon(Icons.volunteer_activism, color: _primary),
            label: 'Services',
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
      case 1:
        return 'Buddy AI';
      case 2:
        return 'Volunteer Services';
      case 3:
        return 'My Profile';
      default:
        return 'Volunteer Dashboard';
    }
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0: return _buildHomeTab();
      case 1: return const BuddyChatScreen();
      case 2: return _buildVolunteerServicesTab();
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
            // Welcome banner
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
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.volunteer_activism, size: 30, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome, $_userName! 👋',
                            style: AppTextStyles.h2.copyWith(color: Colors.white)),
                        const SizedBox(height: 4),
                        Text('Thank you for your service to seniors!',
                            style: AppTextStyles.bodySub.copyWith(color: Colors.white.withOpacity(0.8))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Dashboard Stats
            const Text('Your Impact Overview', style: AppTextStyles.h2),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.1,
              children: [
                _miniStatCard('Pending', '${_dashboardStats['pending_tasks'] ?? 0}', Colors.purple, () async {
                  await Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const HelpRequestListScreen(userRole: kRoleVolunteer, initialFilter: 'pending')));
                  onRefresh();
                }),
                _miniStatCard('Accepted', '${_dashboardStats['accepted_tasks'] ?? 0}', Colors.orange, () async {
                  await Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const HelpRequestListScreen(userRole: kRoleVolunteer, initialFilter: 'accepted')));
                  onRefresh();
                }),
                _miniStatCard('Completed', '${_dashboardStats['completed_tasks'] ?? 0}', Colors.green, () async {
                  await Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const HelpRequestListScreen(userRole: kRoleVolunteer, initialFilter: 'completed')));
                  onRefresh();
                }),
                _miniStatCard('Average Rating', '${(double.tryParse(_dashboardStats['average_rating']?.toString() ?? '0.0') ?? 0.0).toStringAsFixed(1)} ★',
                    Colors.blue, () => _showRatingDetails()),
              ],
            ),
            const SizedBox(height: 32),

            // Service Log Card
            const Text('Professional Impact', style: AppTextStyles.h2),
            const SizedBox(height: 16),
            _proofOfServiceCard(),
            const SizedBox(height: 32),

            // Honor Roll (Leaderboard)
            if (_leaderboard.isNotEmpty) ...[
              const Text('Honor Roll — Top Volunteers', style: AppTextStyles.h2),
              const SizedBox(height: 16),
              _buildLeaderboard(),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }

  Widget _miniStatCard(String label, String value, Color color, VoidCallback onTap) {
    return Container(
      decoration: AppDecoration.cardDecoration(shadowOpacity: 0.05),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 30,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(value, style: AppTextStyles.h2.copyWith(fontSize: 18, color: color)),
                      Text(label, style: AppTextStyles.labelPremium.copyWith(fontSize: 10, color: AppColors.textSub)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRatingDetails() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Rating & Feedback', style: AppTextStyles.h2),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${(double.tryParse(_dashboardStats['average_rating']?.toString() ?? '0.0') ?? 0.0).toStringAsFixed(1)} / 5.0',
              style: AppTextStyles.h1.copyWith(fontSize: 36, color: Colors.blue),
            ),
            const SizedBox(height: 12),
            const Text('Based on family feedback for your services.', textAlign: TextAlign.center, style: AppTextStyles.bodySub),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Close', style: TextStyle(color: _primary))),
        ],
      ),
    );
  }

  // ─────────────────────────── VOLUNTEER SERVICES TAB ──────────────────────────

  Widget _buildVolunteerServicesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Available Services', style: AppTextStyles.h1),
          const SizedBox(height: 6),
          const Text('Manage requests and respond to emergencies.', style: AppTextStyles.bodySub),
          const SizedBox(height: 24),
          _largeServiceCard(
            'Find Help Requests',
            'View and accept requests from seniors who need assistance.',
            Icons.search,
            Colors.blue,
            () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpRequestListScreen(userRole: kRoleVolunteer)));
            },
          ),
          const SizedBox(height: 16),
          // Buddy AI was removed and moved to the primary bottom navigation tab.
        ],
      ),
    );
  }

  Widget _largeServiceCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: AppDecoration.cardDecoration(shadowOpacity: 0.05),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.h2.copyWith(fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: AppTextStyles.bodySub),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.4)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureTile(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.black45),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // TASKS TAB
  // ══════════════════════════════════════════════════════════════════

  Widget _buildTasksTab() {
    return RefreshIndicator(
      color: _accent,
      onRefresh: _loadTasks,
      child: _isLoadingTasks
          ? Center(child: CircularProgressIndicator(color: _accent))
          : _tasks.isEmpty
              ? Center(
                  child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.task_outlined,
                        size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text('No tasks assigned yet',
                        style:
                            TextStyle(fontSize: 18, color: Colors.grey[500])),
                    const SizedBox(height: 8),
                    Text('Tasks will appear here once assigned.',
                        style:
                            TextStyle(fontSize: 14, color: Colors.grey[400])),
                  ],
                ))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tasks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _buildTaskCard(_tasks[i]),
                ),
    );
  }

  Widget _buildTaskCard(dynamic task) {
    final String status = task['status'] ?? 'assigned';
    final bool isDone = status == 'completed';
    final Color statusColor = isDone ? Colors.green : _accent;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: statusColor, width: 4)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task['title'] ?? 'Task',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                        fontSize: 10,
                        color: statusColor,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (task['senior_name'] != null) ...[
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.elderly, size: 15, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Senior: ${task['senior_name']}',
                    style:
                        const TextStyle(fontSize: 13, color: Colors.black54)),
              ]),
            ],
            if (task['scheduled_date'] != null) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.calendar_today, size: 15, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Date: ${task['scheduled_date']}',
                    style:
                        const TextStyle(fontSize: 13, color: Colors.black54)),
              ]),
            ],
            ],

        ),
      ),
    );
  }

  // ────────────────────────────── PROFILE TAB ───────────────────────────────

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          ProfileHeader(userData: _userData, userRole: kRoleVolunteer),
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
                if (updated == true) onRefresh();
              },
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit Profile'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primary,
                side: BorderSide(color: _primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Contact info card
          if (_userData != null)
            _infoCard('Account Details', [
              _infoRow(Icons.phone_outlined, 'Phone',
                  _userData!['phone_number']?.isNotEmpty == true ? _userData!['phone_number'] : 'Not set'),
              _infoRow(Icons.location_on_outlined, 'City',
                  _userData!['city']?.isNotEmpty == true ? _userData!['city'] : 'Not set'),
              _infoRow(Icons.calendar_today_outlined, 'Member Since', _formatDate(_userData!['created_at'])),
            ]),

          const SizedBox(height: 24),
          ProfileLinksWidget(onLogout: _handleLogout),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _handleLogout() async {
    await _api.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
        (route) => false,
      );
    }
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  String _formatDate(dynamic dateVal) {
    if (dateVal == null || dateVal.toString().isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(dateVal.toString());
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateVal.toString();
    }
  }

  Widget _infoCard(String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 4),
          child: Text(title.toUpperCase(), style: AppTextStyles.labelPremium.copyWith(color: _primary)),
        ),
        Container(
          decoration: AppDecoration.cardDecoration(shadowOpacity: 0.05),
          padding: const EdgeInsets.all(16),
          child: Column(children: rows),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
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
                  value.isEmpty ? 'N/A' : value,
                  style: AppTextStyles.bodyMain.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _proofOfServiceCard() {
    return Container(
      decoration: AppDecoration.cardDecoration(shadowOpacity: 0.08),
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => VolunteerProofOfServiceScreen(primaryColor: _primary),
          ));
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.verified_outlined, color: Colors.green, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Service Portfolio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    const SizedBox(height: 4),
                    Text('View your total impact and service proof.', style: AppTextStyles.bodySub.copyWith(fontSize: 13)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: _primary.withOpacity(0.4)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboard() {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _leaderboard.length,
        itemBuilder: (context, index) {
          final v = _leaderboard[index];
          final bool isTop = index < 3;
          final Color medalColor = index == 0 ? Colors.amber : (index == 1 ? Colors.grey : Colors.brown[300]!);

          return Container(
            width: 130,
            margin: const EdgeInsets.only(right: 12, bottom: 8),
            decoration: AppDecoration.cardDecoration(shadowOpacity: 0.05),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: _primary.withOpacity(0.1),
                      backgroundImage: v['profile_picture'] != null
                          ? NetworkImage(v['profile_picture'])
                          : null,
                      child: v['profile_picture'] == null
                          ? Text(v['username'][0].toUpperCase(),
                              style: TextStyle(
                                  color: _primary, fontWeight: FontWeight.bold))
                          : null,
                    ),
                    if (isTop)
                      Positioned(
                        bottom: -4,
                        right: -4,
                        child: Icon(Icons.stars, color: medalColor, size: 24),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  v['full_name'] ?? 'Volunteer',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 12, color: Colors.green),
                    const SizedBox(width: 4),
                    Text('${v['completed_tasks']} tasks', style: const TextStyle(fontSize: 11, color: AppColors.textSub)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class VolunteerTasksScreen extends StatelessWidget {
  final List<dynamic> tasks;
  const VolunteerTasksScreen({Key? key, required this.tasks}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: tasks.isEmpty
          ? const Center(child: Text('No tasks assigned yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return VolunteerTasksItem(task: task);
              },
            ),
    );
  }
}

class VolunteerTasksItem extends StatelessWidget {
  final dynamic task;
  const VolunteerTasksItem({Key? key, required this.task}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String status = task['status'] ?? 'assigned';
    final bool isDone = status == 'completed';
    final Color statusColor = isDone ? Colors.green : Theme.of(context).primaryColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16, top: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: statusColor, width: 4)),
        ),
        child: ListTile(
          title: Text(task['title'] ?? 'Task',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${task['senior_name']} • ${task['scheduled_date']}'),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
