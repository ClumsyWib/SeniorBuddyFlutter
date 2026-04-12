import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../utils/refresh_mixin.dart';
import '../utils/role_helper.dart';
import '../utils/style_utils.dart';
import 'dart:async';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with PeriodicRefreshMixin, SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  StreamSubscription? _notifSubscription;
  String _currentRole = kRoleFamily;
  Color _roleColor = AppColors.familyPrimary;
  String _userName = 'User';

  @override
  void initState() {
    super.initState();
    _initRole();
    _loadData();
    
    _notifSubscription = NotificationService.onMessageStream.stream.listen((event) {
       _loadData(); 
    });
  }

  Future<void> _initRole() async {
    final role = await RoleHelper.getCurrentRole();
    final userResult = await _apiService.getCurrentUser();
    
    if (mounted) {
      setState(() {
        _currentRole = role;
        _roleColor = _getRoleColor(role);
        if (userResult['success']) {
          _userName = userResult['data']['first_name'] ?? userResult['data']['username'] ?? 'User';
        }
      });
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case kRoleSenior: return AppColors.seniorPrimary;
      case kRoleFamily: return AppColors.familyPrimary;
      case kRoleCaretaker: return AppColors.caretakerPrimary;
      case kRoleVolunteer: return AppColors.volunteerPrimary;
      default: return const Color(0xFF2C3E50);
    }
  }

  @override
  void dispose() {
    _notifSubscription?.cancel();
    super.dispose();
  }

  @override
  Future<void> onRefresh() async {
    await _loadData();
  }

  Future<void> _loadData() async {
    final result = await _apiService.getNotifications();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success']) {
          _notifications = result['data'];
        }
      });
    }
  }

  Future<void> _markAsRead(int id) async {
    await _apiService.markNotificationRead(id);
    _loadData();
  }

  Future<void> _deleteNotification(int id) async {
    final result = await _apiService.deleteNotification(id);
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Notification deleted',
                style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.green),
      );
    }
    _loadData();
  }

  List<dynamic> _getFilteredNotifications(String category) {
    if (_notifications.isEmpty) return [];

    // 🚨 ROLE-BASED FILTER: Seniors ONLY see Medicine and Appointments
    if (_currentRole == kRoleSenior) {
      return _notifications.where((n) {
        final type = n['notification_type'];
        return type == 'medicine' || type == 'appointment';
      }).toList();
    }

    if (category == 'all') {
      return _notifications;
    } else if (category == 'updates' || category == 'reminders') {
      return _notifications.where((n) => n['notification_type'] != 'emergency').toList();
    } else if (category == 'emergency') {
      return _notifications.where((n) => n['notification_type'] == 'emergency').toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _getTabsForRole();
    
    // If only 1 tab (Volunteer), we don't need DefaultTabController/TabBar
    if (tabs.length <= 1) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: Text(_currentRole == kRoleSenior ? 'My Reminders' : 'Help Requests',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: _roleColor,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildNotificationList(_currentRole == kRoleSenior ? 'reminders' : 'all'),
      );
    }

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: Text(_currentRole == kRoleSenior ? 'My Notifications' : 'Notifications',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: _roleColor,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            isScrollable: tabs.length > 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
            tabs: tabs.map((t) => Tab(text: t['label'])).toList(),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: tabs.map((t) => _buildNotificationList(t['category'])).toList(),
              ),
      ),
    );
  }

  List<Map<String, dynamic>> _getTabsForRole() {
    switch (_currentRole) {
      case kRoleSenior:
        return [
          {'label': '📅 Reminders', 'category': 'reminders'},
        ];
      case kRoleVolunteer:
        return [
          {'label': '🤝 Help Requests', 'category': 'all'}, // SOS removed for volunteers
        ];
      case kRoleFamily:
      case kRoleCaretaker:
      default:
        return [
          {'label': 'All', 'category': 'all'},
          {'label': '🚨 SOS', 'category': 'emergency'},
          {'label': '📋 Updates', 'category': 'updates'},
        ];
    }
  }

  Widget _buildNotificationList(String category) {
    final filtered = _getFilteredNotifications(category);

    if (filtered.isEmpty) {
      return _buildEmptyState(category);
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final notif = filtered[index];
          final isRead = notif['is_read'] ?? false;
          final type = notif['notification_type'] ?? 'info';
          final metadata = notif['metadata'] ?? {};
          final seniorName = metadata['senior_name'];
          
          String title = notif['title'] ?? 'Notification';
          String message = notif['message'] ?? '';

          // Personalize for Senior
          if (_currentRole == kRoleSenior) {
             title = title.replaceAll('Emergency Alert!', 'Your Emergency Alert');
             title = title.replaceAll('SOS EMERGENCY!', 'YOUR SOS ALERT');
             title = title.replaceAll('New Appointment Scheduled', 'Your New Appointment');
             
             // Message rephrasing
             if (seniorName != null && message.contains(seniorName)) {
                message = message.replaceAll('for $seniorName', 'for you');
                message = message.replaceAll('$seniorName has', 'you have');
                message = message.replaceAll('EMERGENCY ALERT for $seniorName', 'EMERGENCY ALERT for you');
             }
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: isRead ? 1 : 4,
            shadowColor: type == 'emergency' ? Colors.red.withOpacity(0.3) : Colors.black12,
            color: isRead ? Colors.white : (type == 'emergency' ? const Color(0xFFFFEBEE) : const Color(0xFFE3F2FD)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: isRead ? BorderSide.none : BorderSide(color: type == 'emergency' ? Colors.red.withOpacity(0.2) : Colors.blue.withOpacity(0.2)),
            ),
            child: ListTile(
              onTap: () {
                final Map<String, dynamic> navData = Map<String, dynamic>.from(metadata);
                navData['notification_type'] = notif['notification_type'];
                navData['related_id'] = notif['related_id'];
                
                NotificationService().handleMessageNavigation(navData);
                if (!isRead) _markAsRead(notif['id']);
              },
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: _buildLeadingIcon(type, isRead),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (type == 'emergency')
                    const Icon(Icons.warning, color: Colors.red, size: 20),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text(message,
                      style: const TextStyle(fontSize: 14, color: Colors.black87)),
                  if (seniorName != null && _currentRole != kRoleSenior) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _roleColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Senior: $seniorName',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _roleColor,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(notif['created_at']),
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              trailing: Wrap(
                spacing: 4,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                direction: Axis.vertical,
                children: [
                   if (!isRead)
                    GestureDetector(
                      onTap: () => _markAsRead(notif['id']),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.check, color: Colors.blue, size: 20),
                      ),
                    ),
                   GestureDetector(
                      onTap: () => _deleteNotification(notif['id']),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeadingIcon(String type, bool isRead) {
    IconData iconData;
    Color color;

    switch (type) {
      case 'emergency':
        iconData = Icons.emergency;
        color = Colors.red;
        break;
      case 'medicine':
        iconData = Icons.medication;
        color = Colors.orange;
        break;
      case 'appointment':
        iconData = Icons.event;
        color = Colors.blue;
        break;
      case 'chat':
        iconData = Icons.chat;
        color = Colors.green;
        break;
      case 'activity':
        iconData = Icons.directions_run;
        color = Colors.purple;
        break;
      default:
        iconData = Icons.notifications;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: color, size: 24),
    );
  }

  Widget _buildEmptyState(String category) {
    String message = 'No notifications yet';
    if (category == 'emergency') message = 'No emergency alerts';
    else if (category == 'updates' || category == 'reminders') message = 'No care updates';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(message,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54)),
          const SizedBox(height: 8),
          const Text('You will see alerts and updates here.',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  String _formatDate(String? dtString) {
    if (dtString == null) return '';
    try {
      final dt = DateTime.parse(dtString).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} at ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dtString;
    }
  }
}
