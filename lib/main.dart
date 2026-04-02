import 'package:flutter/material.dart';
import 'screens/role_selection_screen.dart';
import 'screens/senior_connection_screen.dart';
import 'home/senior_home_screen.dart';
import 'home/family_home_screen.dart';
import 'home/caretaker_home_screen.dart';
import 'home/volunteer_home_screen.dart';
import 'services/api_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SeniorCareApp());
}

class SeniorCareApp extends StatelessWidget {
  const SeniorCareApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Senior Buddy',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const StartupScreen(),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4CAF50),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.white,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
        headlineMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.black87),
        titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black87),
        bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
        bodyMedium: TextStyle(fontSize: 14, color: Colors.black87),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 2,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
      ),
    );
  }
}

class StartupScreen extends StatelessWidget {
  const StartupScreen({Key? key}) : super(key: key);

  Future<Widget> _initializeApp() async {
    final apiService = ApiService();

    try {
      bool isSeniorMode = await apiService.isSeniorMode();
      String? token = await apiService.getToken();

      // 👴 Senior Mode
      if (isSeniorMode) {
        if (token != null) {
          return const SeniorHomeScreen();
        } else {
          return const SeniorConnectionScreen();
        }
      }

      // 👨‍👩‍👧 Other Users
      if (token != null) {
        final userResult = await apiService.getCurrentUser();

        if (userResult['success'] == true && userResult['data'] != null) {
          final data = userResult['data'];

          final userType = data['user_type'] ?? '';
          final isSuperuser = data['is_superuser'] == true;
          final isStaff = data['is_staff'] == true;

          if (userType == 'caretaker') {
            return const CaretakerHomeScreen();
          } else if (userType == 'volunteer') {
            return const VolunteerHomeScreen();
          } else if (userType == 'family') {
            return const FamilyHomeScreen();
          }
        }

        // ❌ Invalid token → clear
        await apiService.clearStorage();
      }

      return const RoleSelectionScreen();
    } catch (e) {
      debugPrint("Startup Error: $e");
      return const RoleSelectionScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _initializeApp(),
      builder: (context, snapshot) {
        // 🔄 Loading Screen
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // ❌ Error fallback
        if (snapshot.hasError || !snapshot.hasData) {
          return const RoleSelectionScreen();
        }

        // ✅ Navigate
        return snapshot.data!;
      },
    );
  }
}