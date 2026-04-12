import 'package:shared_preferences/shared_preferences.dart';

/// ------------------------------------------------------------------------
/// FILE: role_helper.dart
/// PURPOSE: Provides role constants and a helper to fetch the current user's
/// role. Used by all feature screens to decide whether to show Add/Edit buttons.
/// ------------------------------------------------------------------------

// Role constants — must match Django's User.user_type choices exactly
const String kRoleFamily = 'family';
const String kRoleCaretaker = 'caretaker';
const String kRoleSenior = 'senior';
const String kRoleVolunteer = 'volunteer';

/// Returns true if [role] is allowed to add/edit Medicines, Appointments,
/// Health Records, Doctors, Emergency Contacts, or Caretaker Assignments.
bool canFamilyWrite(String role) => role == kRoleFamily;

/// Returns true if [role] is allowed to add/edit Daily Activity or Vitals.
bool canCaretakerWrite(String role) => role == kRoleCaretaker;

/// Returns true if [role] is completely view-only (Senior).
bool isViewOnly(String role) => role == kRoleSenior;

/// 🆕 Helper to get the role from storage
class RoleHelper {
  static Future<String> getCurrentRole() async {
    final prefs = await SharedPreferences.getInstance();
    // Prioritize Senior Mode check
    if (prefs.getBool('is_senior_mode') == true) return kRoleSenior;
    return prefs.getString('user_type') ?? kRoleFamily;
  }
}
