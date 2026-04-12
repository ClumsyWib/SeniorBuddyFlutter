import 'package:flutter/material.dart';
import 'package:senior_care_app/utils/style_utils.dart';
import '../utils/role_helper.dart';

/// Provides role-based colors and themes for the entire application.
class DynamicThemeService extends ChangeNotifier {
  String _currentRole = kRoleSenior;

  String get currentRole => _currentRole;

  /// Update the current role and notify listeners to rebuild with the new theme.
  void setRole(String role) {
    if (_currentRole == role) return;
    _currentRole = role;
    notifyListeners();
  }

  /// Returns the primary brand color for the current role.
  Color get primaryColor {
    switch (_currentRole) {
      case kRoleSenior:
        return AppColors.seniorPrimary;
      case kRoleFamily:
        return AppColors.familyPrimary;
      case kRoleCaretaker:
        return AppColors.caretakerPrimary;
      case kRoleVolunteer:
        return AppColors.volunteerPrimary;
      default:
        return AppColors.seniorPrimary;
    }
  }

  /// Returns the secondary gradient color for the current role.
  Color get gradientColor {
    switch (_currentRole) {
      case kRoleSenior:
        return AppColors.seniorAccent;
      case kRoleFamily:
        return AppColors.familyAccent;
      case kRoleCaretaker:
        return AppColors.caretakerAccent;
      case kRoleVolunteer:
        return AppColors.volunteerAccent;
      default:
        return AppColors.seniorAccent;
    }
  }

  /// Returns a background color tint for the current role.
  Color get backgroundColor {
    switch (_currentRole) {
      case kRoleSenior:
        return const Color(0xFFF5F3FF); // Very light violet
      case kRoleFamily:
        return const Color(0xFFECFDF5); // Very light emerald
      case kRoleCaretaker:
        return const Color(0xFFEFF6FF); // Very light blue
      case kRoleVolunteer:
        return const Color(0xFFFFFBEB); // Very light amber
      default:
        return const Color(0xFFF5F3FF);
    }
  }

  /// Generates a standard gradient based on the current role.
  LinearGradient get roleGradient {
    return LinearGradient(
      colors: [primaryColor, gradientColor],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// Accessibility: Ensures text/icons on primary theme colors are always white.
  Color get contrastColor => Colors.white;
}
