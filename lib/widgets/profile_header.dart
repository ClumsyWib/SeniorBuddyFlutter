import 'package:flutter/material.dart';
import '../utils/role_helper.dart';

class ProfileHeader extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final String userRole;

  const ProfileHeader({
    Key? key,
    required this.userData,
    required this.userRole,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String fullName = _getFullName();
    final String? profilePicture = userData?['profile_picture'];
    final String initials = _getInitials(fullName);
    final Color roleColor = _getRoleColor();

    return Column(
      children: [
        // Premium Header Card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Avatar Section with Background shape
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: roleColor.withOpacity(0.08),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                        bottomLeft: Radius.circular(60),
                        bottomRight: Radius.circular(60),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 56,
                        backgroundColor: roleColor.withOpacity(0.1),
                        backgroundImage: profilePicture != null ? NetworkImage(profilePicture) : null,
                        child: profilePicture == null
                            ? Text(
                                initials,
                                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: roleColor),
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 70), // Offset for avatar

              // Name & Role Title
              Text(
                fullName,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: roleColor.withOpacity(0.9),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getRoleDisplay(),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),

              // Stats Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _buildStats(context),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildStats(BuildContext context) {
    if (userRole == kRoleCaretaker) {
      final rating = userData?['caretaker_profile']?['rating']?.toString() ?? '0.00';
      final exp = '${userData?['caretaker_profile']?['experience_years'] ?? 0}+ Years';
      final avail = userData?['caretaker_profile']?['availability_status'] ?? 'Full-time';
      
      return [
        _buildStatItem('Rating', rating, Icons.star, Colors.amber),
        _buildStatItem('Experience', exp, Icons.work, Colors.blue),
        _buildStatItem('Availability', avail, Icons.event_available, Colors.green),
      ];
    } else if (userRole == kRoleVolunteer) {
       final rating = userData?['volunteer_profile']?['rating']?.toString() ?? '0.00';
       final exp = userData?['volunteer_profile']?['availability_status'] ?? 'Part-time';
       final hours = '${userData?['volunteer_profile']?['total_hours']?.toInt() ?? 0} Hrs';
       
       return [
        _buildStatItem('Rating', rating, Icons.star, Colors.amber),
        _buildStatItem('Status', exp, Icons.event_available, Colors.green),
        _buildStatItem('Impact', hours, Icons.favorite, Colors.red),
      ];
    } else if (userRole == kRoleSenior) {
       final age = '${userData?['senior_profile']?['age'] ?? '-'}';
       final gender = userData?['senior_profile']?['gender'] ?? '-';
       final level = userData?['senior_profile']?['care_level'] ?? '-';
       
       return [
        _buildStatItem('Age', age, Icons.cake, Colors.orange),
        _buildStatItem('Gender', gender, Icons.wc, Colors.blue),
        _buildStatItem('Care Level', level, Icons.health_and_safety, Colors.teal),
      ];
    }
    
    // Default stats for Family or others
    return [
      _buildStatItem('Role', 'Family', Icons.people, Colors.green),
      _buildStatItem('Seniors', 'Managed', Icons.favorite, Colors.red),
      _buildStatItem('City', userData?['city'] ?? 'My City', Icons.location_on, Colors.blue),
    ];
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  String _getFullName() {
    if (userData == null) return 'User';
    final fn = userData?['first_name'] ?? '';
    final ln = userData?['last_name'] ?? '';
    final name = '$fn $ln'.trim();
    return name.isNotEmpty ? name : (userData?['username'] ?? 'User');
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Color _getRoleColor() {
    switch (userRole) {
      case kRoleFamily:    return const Color(0xFF43A047); // Green
      case kRoleCaretaker: return const Color(0xFF1976D2); // Blue
      case kRoleSenior:    return const Color(0xFF8E24AA); // Purple
      case kRoleVolunteer: return const Color(0xFFF59E0B); // Amber
      default:             return Colors.grey;
    }
  }

  String _getRoleDisplay() {
    switch (userRole) {
      case kRoleFamily:    return 'Family Member';
      case kRoleCaretaker: return 'Professional Caretaker';
      case kRoleSenior:    return 'Senior User';
      case kRoleVolunteer: return 'Volunteer';
      default:             return userRole.toUpperCase();
    }
  }
}
