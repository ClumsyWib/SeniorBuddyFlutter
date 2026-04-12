import 'package:flutter/material.dart';

/// Centralized Design System for Senior Buddy
/// This ensures a professional, premium, and cohesive look across all screens.

class AppColors {
  // Main Role Palettes (Premium & Professional)
  static const Color seniorPrimary = Color(0xFF7C3AED); // Deep Violet
  static const Color seniorAccent = Color(0xFF9F67FF);  // Light Violet
  
  static const Color familyPrimary = Color(0xFF059669); // Emerald Green
  static const Color familyAccent = Color(0xFF34D399);  // Light Emerald
  
  static const Color caretakerPrimary = Color(0xFF2563EB); // Royal Blue
  static const Color caretakerAccent = Color(0xFF60A5FA);  // Light Blue
  
  static const Color volunteerPrimary = Color(0xFFD97706); // Rich Amber
  static const Color volunteerAccent = Color(0xFFFBBF24);  // Golden Amber

  // General Colors
  static const Color bgSoft = Color(0xFFF8F9FE);
  static const Color textMain = Color(0xFF1A1C2E);
  static const Color textSub = Color(0xFF6A6C7E);
  static const Color white = Colors.white;
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
}

class AppGradients {
  static LinearGradient mainGradient(Color primary, Color accent) {
    return LinearGradient(
      colors: [primary, accent],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}

class AppDecoration {
  static BoxDecoration cardDecoration({
    Color color = Colors.white,
    double radius = 16,
    double shadowOpacity = 0.08,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(shadowOpacity),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration sectionDecoration() {
    return BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.grey.withOpacity(0.1)),
    );
  }
}

class AppTextStyles {
  static const TextStyle h1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textMain,
    letterSpacing: 0.5,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textMain,
  );

  static const TextStyle bodyMain = TextStyle(
    fontSize: 16,
    color: AppColors.textMain,
  );

  static const TextStyle bodySub = TextStyle(
    fontSize: 14,
    color: AppColors.textSub,
  );

  static const TextStyle labelPremium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.1,
  );
}
