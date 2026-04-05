import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../screens/settings_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_links_widget.dart';
import '../utils/role_helper.dart';
import '../screens/role_selection_screen.dart';
import '../screens/help_request_screens.dart';
import '../screens/volunteer_emergency_screens.dart';
import '../screens/volunteer_dashboard_screen.dart';

/// VolunteerHomeScreen — Full 3-tab dashboard
///   0. Home  (welcome card + quick stats + task preview)
///   1. Tasks (full task list)
///   2. Profile (volunteer info + logout)
class VolunteerHomeScreen extends StatefulWidget {
  const VolunteerHomeScreen({Key? key}) : super(key: key);

  @override
  State<VolunteerHomeScreen> createState() => _VolunteerHomeScreenState();
}

class _VolunteerHomeScreenState extends State<VolunteerHomeScreen> {
  final ApiService _api = ApiService();

  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _isLoadingTasks = false;

  Map<String, dynamic>? _userData;
  String _userName = 'Volunteer';
  List<dynamic> _tasks = [];
  Map<String, dynamic> _dashboardStats = {};

  static const Color _amber     = Color(0xFFF59E0B);
  static const Color _amberDark = Color(0xFFD97706);
  static const Color _bg        = Color(0xFFFFFBF0);

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    if (mounted) setState(() => _isLoading = true);
    final userResult = await _api.getCurrentUser();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (userResult['success'] == true) {
          _userData = userResult['data'];
          final fn = _userData?['first_name'] ?? '';
          final ln = _userData?['last_name'] ?? '';
          _userName = '$fn $ln'.trim();
          if (_userName.isEmpty)
            _userName = _userData?['username'] ?? 'Volunteer';
        }
      });
    }

    // Load remaining data in parallel
    Future.wait([
      _loadTasks(),
      _loadDashboardStats(),
    ]);
  }

  Future<void> _loadDashboardStats() async {
    print('🔵 Loading volunteer dashboard stats...');
    final result = await _api.getVolunteerDashboard();
    if (mounted) {
      if (result['success'] == true) {
        print('🟢 Dashboard stats loaded: ${result['data']}');
        setState(() {
          _dashboardStats = result['data'] ?? {};
        });
      } else {
        print('🔴 Failed to load dashboard stats: ${result['error']}');
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

  // ─────────────────────────────── BUILD ───────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _amber,
        title: Text(_appBarTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _amber))
          : _buildBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) {
          setState(() => _selectedIndex = i);
        },
        indicatorColor: _amber.withOpacity(0.15),
        destinations: [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: _amber),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.volunteer_activism_outlined),
              selectedIcon: Icon(Icons.volunteer_activism, color: _amber),
              label: 'Services'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: _amber),
              label: 'Profile'),
        ],
      ),
    );
  }

  String get _appBarTitle {
    switch (_selectedIndex) {
      case 1:  return 'Volunteer Services';
      case 2:  return 'My Profile';
      default: return 'Volunteer Dashboard';
    }
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:  return _buildHomeTab();
      case 1:  return _buildVolunteerServicesTab();
      case 2:  return _buildProfileTab();
      default: return _buildHomeTab();
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // HOME TAB
  // ══════════════════════════════════════════════════════════════════

  Widget _buildHomeTab() {
    final pending   = _tasks.where((t) => (t['status'] ?? '') == 'assigned').length;
    final completed = _tasks.where((t) => (t['status'] ?? '') == 'completed').length;

    return RefreshIndicator(
      color: _amber,
      onRefresh: _loadAll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [_amber, _amberDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: _amber.withOpacity(0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 6))
                ],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.volunteer_activism, size: 32, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome, $_userName! 👋',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        const SizedBox(height: 4),
                        const Text('Thank you for your service to seniors!',
                            style: TextStyle(fontSize: 13, color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Dashboard Stats (Replacing Overview and Upcoming Tasks)
            const Text('Your Performance',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.1,
              children: [
                _miniStatCard('Pending', '${_dashboardStats['pending_tasks'] ?? 0}', Colors.purple, () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpRequestListScreen(userRole: kRoleVolunteer, initialFilter: 'pending')));
                  _loadAll();
                }),
                _miniStatCard('Accepted', '${_dashboardStats['accepted_tasks'] ?? 0}', Colors.orange, () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpRequestListScreen(userRole: kRoleVolunteer, initialFilter: 'accepted')));
                  _loadAll();
                }),
                _miniStatCard('Completed', '${_dashboardStats['completed_tasks'] ?? 0}', Colors.green, () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpRequestListScreen(userRole: kRoleVolunteer, initialFilter: 'completed')));
                  _loadAll();
                }),
                _miniStatCard('Emergencies', '${_dashboardStats['emergencies_handled'] ?? 0}', Colors.red, () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const VolunteerEmergencyAlertsScreen()));
                  _loadAll();
                }),
                _miniStatCard('Rating', '${(double.tryParse(_dashboardStats['average_rating']?.toString() ?? '0.0') ?? 0.0).toStringAsFixed(1)} ★', Colors.blue, () {
                  _showRatingDetails();
                }),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _miniStatCard(String label, String value, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 30,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                  Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRatingDetails() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rating & Feedback'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${(double.tryParse(_dashboardStats['average_rating']?.toString() ?? '0.0') ?? 0.0).toStringAsFixed(1)} / 5.0',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 8),
            const Text('Based on family feedback.', style: TextStyle(color: Colors.black54)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // VOLUNTEER SERVICES TAB
  // ══════════════════════════════════════════════════════════════════

  Widget _buildVolunteerServicesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Available Services',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Manage requests and respond to emergencies.',
              style: TextStyle(fontSize: 14, color: Colors.black54)),
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
          _largeServiceCard(
            'Emergency Alerts',
            'Respond to urgent emergency calls from seniors nearby.',
            Icons.emergency,
            Colors.red,
            () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const VolunteerEmergencyAlertsScreen()));
            },
          ),
        ],
      ),
    );
  }

  Widget _largeServiceCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
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
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black26),
          ],
        ),
      ),
    );
  }

  Widget _featureTile(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
      color: _amber,
      onRefresh: _loadTasks,
      child: _isLoadingTasks
          ? const Center(child: CircularProgressIndicator(color: _amber))
          : _tasks.isEmpty
              ? Center(
                  child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.task_outlined, size: 80, color: Colors.grey[300]),
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
    final Color statusColor = isDone ? Colors.green : _amber;

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
            if (task['ngo_name'] != null) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.business, size: 15, color: Colors.grey),
                const SizedBox(width: 4),
                Text('NGO: ${task['ngo_name']}',
                    style:
                        const TextStyle(fontSize: 13, color: Colors.black54)),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // PROFILE TAB
  // ══════════════════════════════════════════════════════════════════

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          ProfileHeader(
            userData: _userData,
            userRole: kRoleVolunteer,
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
                if (updated == true) _loadAll();
              },
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit Profile'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _amber,
                side: const BorderSide(color: _amber),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Contact info card
          if (_userData != null)
            _infoCard('Contact Details', [
              _infoRow(Icons.phone_outlined, 'Phone',
                  _userData!['phone_number']?.isNotEmpty == true
                      ? _userData!['phone_number']
                      : 'Not set'),
              _infoRow(Icons.location_on_outlined, 'City',
                  _userData!['city']?.isNotEmpty == true
                      ? _userData!['city']
                      : 'Not set'),
              _infoRow(Icons.calendar_today_outlined, 'Member Since',
                  _formatDate(_userData!['created_at'])),
            ]),

          const SizedBox(height: 24),
          
          ProfileLinksWidget(
            onLogout: _handleLogout,
            primaryColor: _amber,
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  Widget _infoCard(String title, List<Widget> rows) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.grey.withOpacity(0.12))),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _amberDark)),
            ),
            const Divider(height: 16),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: _amber, size: 20),
      title: Text(label,
          style: const TextStyle(fontSize: 12, color: Colors.black45)),
      subtitle: Text(value.isEmpty ? 'N/A' : value,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black87)),
    );
  }

  Widget _emptyCard(String msg) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.grey.withOpacity(0.12))),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.task_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(msg,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 15)),
          ],
        ),
      ),
    );
  }

  void _handleLogout() async {
    await _api.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
          (r) => false);
    }
  }

  String _formatDate(dynamic val) {
    if (val == null || val.toString().isEmpty) return '—';
    try {
      final dt = DateTime.parse(val.toString()).toLocal();
      const months = [
        'Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return val.toString();
    }
  }
}

class VolunteerTasksScreen extends StatelessWidget {
  final List<dynamic> tasks;
  const VolunteerTasksScreen({Key? key, required this.tasks}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF59E0B),
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
    final Color statusColor = isDone ? Colors.green : const Color(0xFFF59E0B);

    return Card(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16, top: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: statusColor, width: 4)),
        ),
        child: ListTile(
          title: Text(task['title'] ?? 'Task', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${task['senior_name']} • ${task['scheduled_date']}'),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
