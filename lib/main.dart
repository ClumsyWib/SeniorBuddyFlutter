import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'screens/role_selection_screen.dart';
import 'screens/senior_connection_screen.dart';

import 'home/senior_home_screen.dart';
import 'home/family_home_screen.dart';
import 'home/caretaker_home_screen.dart';
import 'home/volunteer_home_screen.dart';

import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'services/text_scale_provider.dart';
import 'services/dynamic_theme_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// 🔥 Initialize Firebase
  await Firebase.initializeApp();


  /// 🔔 Initialize Notifications
  try {
    await NotificationService().initialize();
    debugPrint("🟢 Notifications Initialized");
  } catch (e) {
    debugPrint("🔴 Notifications Init Error: $e");
  }


  /// 📏 Load text scale
  final textScaleProvider = TextScaleProvider();
  await textScaleProvider.loadSettings();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<TextScaleProvider>.value(value: textScaleProvider),
        ChangeNotifierProvider<DynamicThemeService>(create: (_) => DynamicThemeService()),
      ],
      child: const SeniorCareApp(),
    ),
  );
}

class SeniorCareApp extends StatelessWidget {
  const SeniorCareApp({Key? key}) : super(key: key);

  // 🔔 Global key for notification-based navigation
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<DynamicThemeService>();

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Senior Buddy',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(themeService.primaryColor),
      themeMode: ThemeMode.light, // ☀️ Explicitly enforce light mode

      builder: (context, child) {
        final provider = context.watch<TextScaleProvider>();
        final textScaleFactor =
        provider.isSeniorMode ? provider.textScaleFactor : 1.0;

        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScaleFactor),
          ),
          child: child!,
        );
      },
      home: const StartupScreen(),
    );
  }

  ThemeData _buildTheme(Color seedColor) {
    final baseTextTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        primary: seedColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      textTheme: baseTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: seedColor,
        foregroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: seedColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 3,
        shadowColor: Colors.black.withOpacity(0.10),
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class StartupScreen extends StatelessWidget {
  const StartupScreen({Key? key}) : super(key: key);

  Future<Widget> _initializeApp(BuildContext context) async {
    final apiService = ApiService();

    try {
      bool isSeniorMode = await apiService.isSeniorMode();

      if (context.mounted) {
        Provider.of<TextScaleProvider>(context, listen: false)
            .setSeniorMode(isSeniorMode);
      }

      String? token = await apiService.getToken();

      if (isSeniorMode) {
        return token != null
            ? const SeniorHomeScreen()
            : const SeniorConnectionScreen();
      }

      if (token != null) {
        final userResult = await apiService.getCurrentUser();

        if (userResult['success'] == true &&
            userResult['data'] != null) {
          final userType = userResult['data']['user_type'] ?? '';

          switch (userType) {
            case 'caretaker':
              return const CaretakerHomeScreen();
            case 'volunteer':
              return const VolunteerHomeScreen();
            case 'family':
              return const FamilyHomeScreen();
          }
        }

        await apiService.clearStorage();
      }

      return const RoleSelectionScreen();
    } catch (e) {
      debugPrint("❌ Startup Error: $e");
      return const RoleSelectionScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _initializeApp(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const RoleSelectionScreen();
        }

        return snapshot.data!;
      },
    );
  }
}