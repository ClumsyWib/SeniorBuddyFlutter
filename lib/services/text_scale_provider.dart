import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Defines the text size levels available to the user.
enum TextSizeLevel {
  small,
  medium,
  large,
  extraLarge,
}

/// Holds configuration for each text size level.
class TextSizeOption {
  final TextSizeLevel level;
  final String label;
  final double scaleFactor;
  final String icon; // A-, A, A+, A++

  const TextSizeOption({
    required this.level,
    required this.label,
    required this.scaleFactor,
    required this.icon,
  });
}

class TextScaleProvider extends ChangeNotifier {
  static const String _prefKey = 'senior_text_scale_level';

  /// Available text size options
  static const List<TextSizeOption> textSizeOptions = [
    TextSizeOption(
      level: TextSizeLevel.small,
      label: 'Small',
      scaleFactor: 0.85,
      icon: 'A-',
    ),
    TextSizeOption(
      level: TextSizeLevel.medium,
      label: 'Medium',
      scaleFactor: 1.0,
      icon: 'A',
    ),
    TextSizeOption(
      level: TextSizeLevel.large,
      label: 'Large',
      scaleFactor: 1.25,
      icon: 'A+',
    ),
    TextSizeOption(
      level: TextSizeLevel.extraLarge,
      label: 'Extra Large',
      scaleFactor: 1.5,
      icon: 'A++',
    ),
  ];

  TextSizeLevel _currentLevel = TextSizeLevel.medium;
  bool _isSeniorMode = false;

  TextSizeLevel get currentLevel => _currentLevel;
  bool get isSeniorMode => _isSeniorMode;

  /// Enable/disable text scaling globally based on the current role.
  void setSeniorMode(bool value) {
    if (_isSeniorMode == value) return;
    _isSeniorMode = value;
    notifyListeners();
  }

  double get textScaleFactor {
    return textSizeOptions
        .firstWhere((o) => o.level == _currentLevel)
        .scaleFactor;
  }

  TextSizeOption get currentOption {
    return textSizeOptions.firstWhere((o) => o.level == _currentLevel);
  }

  /// Load saved preference from SharedPreferences.
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIndex = prefs.getInt(_prefKey);
      if (savedIndex != null &&
          savedIndex >= 0 &&
          savedIndex < TextSizeLevel.values.length) {
        _currentLevel = TextSizeLevel.values[savedIndex];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ TextScaleProvider loadSettings error: $e');
    }
  }

  /// Update the text scale level and persist to SharedPreferences.
  Future<void> setTextSizeLevel(TextSizeLevel level) async {
    if (_currentLevel == level) return;
    _currentLevel = level;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefKey, level.index);
    } catch (e) {
      debugPrint('❌ TextScaleProvider setTextSizeLevel error: $e');
    }
  }

  /// Reset senior mode and text scaling to default.
  void reset() {
    _isSeniorMode = false;
    _currentLevel = TextSizeLevel.medium;
    notifyListeners();
  }
}
