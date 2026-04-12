import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../screens/chat_screen.dart';
import 'api_service.dart';
import '../main.dart';
import '../screens/emergency_detail_screen.dart';
import '../screens/daily_activity_screen.dart';
import '../screens/help_request_screens.dart';
import '../screens/medicines_screen.dart';
import '../screens/appointments_screen.dart';
import '../screens/vitals_tracker_screen.dart';
import '../utils/role_helper.dart';
import 'json_converter.dart';


@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("📩 Background message: ${message.messageId}");

  // Required to show data-only payloads robustly in Android background
  final FlutterLocalNotificationsPlugin localNotifs =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings =
      InitializationSettings(android: androidSettings);

  await localNotifs.initialize(initSettings);

  // 🔔 Force create the channel in the background isolate
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'emergency_channel_high',
    'Emergency Alerts',
    description: 'Critical emergency notifications',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  await localNotifs
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  final title = message.data['title'] ?? 'Emergency Notification';
  final body = message.data['body'] ?? 'You have a new alert.';
  final type = message.data['type'] ?? '';

  print("📢 Background notification showing: $title");

  if (type == 'emergency') {
    await localNotifs.show(
      911,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'emergency_channel_high',
          'Emergency Alerts',
          channelDescription: 'Critical emergency notifications',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
          color: const Color(0xFFD32F2F),
          styleInformation: BigTextStyleInformation(body),
        ),
      ),
      payload: JsonConverter.encode(message.data),
    );

  } else {
    // Normal handling
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'emergency_channel_high',
      'Emergency Alerts',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    await localNotifs.show(
      message.hashCode,
      title,
      body,
      const NotificationDetails(android: androidPlatformChannelSpecifics),
      payload: JsonConverter.encode(message.data),
    );
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  FirebaseMessaging? _fcm;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final ApiService _apiService = ApiService();
  
  // 🔔 Stream for in-app UI updates
  static final StreamController<Map<String, dynamic>> onMessageStream = StreamController.broadcast();

  bool _isInitialized = false;
  bool _isFirebaseAvailable = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    /// 🔹 Initialize Firebase
    try {
      await Firebase.initializeApp();
      _fcm = FirebaseMessaging.instance;
      _isFirebaseAvailable = true;
    } catch (e) {
      print('⚠️ Firebase not available: $e');
      _isFirebaseAvailable = false;
    }

    /// 🔹 1. Request Permission
    if (_isFirebaseAvailable && _fcm != null) {
      try {
        NotificationSettings settings = await _fcm!.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          print('✅ Permission granted');
        } else {
          print('❌ Permission denied');
        }
      } catch (e) {
        print('⚠️ Permission error: $e');
      }
    }

    /// 🔹 2. Local Notification Setup
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          final data = JsonConverter.decode(details.payload!);
          handleMessageNavigation(data);
        }
      },
    );

    /// 🔹 3. Android Channel
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'emergency_channel_high',
        'Emergency Alerts',
        description: 'Critical emergency notifications',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    /// 🔹 4. Firebase Listeners
    if (_isFirebaseAvailable && _fcm != null) {
      try {
        // Foreground Listener
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Background Message Handler (Registered once here)
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

        // Token Refresh Listener
        _fcm!.onTokenRefresh.listen((newToken) async {
          debugPrint("📱 FCM Token Refreshed: $newToken");
          await _apiService.registerDeviceToken(newToken);
        });

        /// App opened from terminated
        RemoteMessage? initialMessage = await _fcm!.getInitialMessage();
        if (initialMessage != null) {
          debugPrint("🚀 Opened from terminated state via FCM");
          // Handle initial message navigation after build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            handleMessageNavigation(initialMessage.data);
          });
        }

        /// App opened from background
        FirebaseMessaging.onMessageOpenedApp.listen((message) {
          debugPrint("📲 Opened from background via FCM");
          handleMessageNavigation(message.data);
        });
      } catch (e) {
        debugPrint('⚠️ Listener error: $e');
      }
    }

    _isInitialized = true;

    // 🔥 Re-sync token with backend to ensure isSeniorDevice flag matches current mode
    await updateToken();
  }

  /// 🔹 Save FCM Token
  Future<void> updateToken() async {
    if (!_isFirebaseAvailable || _fcm == null) return;

    try {
      String? token = await _fcm!.getToken();
      bool isSenior = await _apiService.isSeniorMode();

      if (token != null) {
        print("📱 FCM Token ($isSenior): $token");
        await _apiService.registerDeviceToken(token, isSeniorDevice: isSenior);
      }
    } catch (e) {
      print("❌ Token error: $e");
    }
  }

  /// 🔹 Foreground Notification
  void _handleForegroundMessage(RemoteMessage message) {
    print("📩 Foreground message received");

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = notification?.android;

    final title = notification?.title ??
        message.data['title'] ??
        'Emergency Notification';
    final body =
        notification?.body ?? message.data['body'] ?? 'You have a new alert.';

    print("📢 Foreground notification received for Tab: $title");
    
    // 🚨 Silence SOS alerts for Seniors (They shouldn't see alerts about themselves)
    final type = message.data['type'] ?? '';
    RoleHelper.getCurrentRole().then((role) {
      if (role == kRoleSenior && type == 'emergency') {
        print("🔇 Silencing SOS alert for Senior user");
        return;
      }

      // 🚨 Add to stream for in-app UI updates
      onMessageStream.add({'title': title, 'body': body, 'data': message.data});
      
      // 🔔 Show the physical notification bar entry
      showNotification(
        title: title,
        body: body,
        data: message.data,
      );
    });
  }

  /// 🔹 Show a local notification manually
  Future<void> showNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final type = data?['type'] ?? '';

    if (type == 'emergency') {
      await _localNotifications.show(
        911,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'emergency_channel_high',
            'Emergency Alerts',
            channelDescription: 'Critical emergency notifications',
            importance: Importance.max,
            priority: Priority.high,
            fullScreenIntent: true,
            color: const Color(0xFFD32F2F),
            styleInformation: BigTextStyleInformation(body),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: data != null ? JsonConverter.encode(data) : null,
      );
    } else {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'emergency_channel_high',
        'Emergency Alerts',
        channelDescription: 'Critical emergency notifications',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        fullScreenIntent: true,
      );
      
      await _localNotifications.show(
        DateTime.now().millisecond,
        title,
        body,
        NotificationDetails(
          android: androidPlatformChannelSpecifics,
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: data != null ? JsonConverter.encode(data) : null,
      );
    }
  }

  /// 🔹 Handle navigation based on notification data
  Future<void> handleMessageNavigation(Map<String, dynamic> data) async {
    print("🚀 Handling navigation for data: $data");
    final type = data['type'] ?? data['notification_type'];
    final seniorId = int.tryParse(data['senior_id']?.toString() ?? '');
    
    // 🔥 Fetch current role asynchronously
    final role = await RoleHelper.getCurrentRole();
    
    if (type == 'emergency' || type == 'sos') {
      final alertId = int.tryParse(data['alert_id']?.toString() ?? '');
      final sId = seniorId ?? int.tryParse(data['senior_id']?.toString() ?? '');
      
      if (sId != null) {
        SeniorCareApp.navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => EmergencyDetailScreen(
              seniorId: sId,
              alertId: alertId,
            ),
          ),
        );
      }
    } else if ((type == 'activity' || type == 'daily_activity') && seniorId != null) {
      SeniorCareApp.navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => DailyActivityScreen(
            seniorId: seniorId,
            seniorName: data['senior_name'] ?? 'Senior Care Log',
            userRole: role,
          ),
        ),
      );
    } else if (type == 'help_request_new' || type == 'help_request') {
      SeniorCareApp.navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => HelpRequestListScreen(
            userRole: role,
          ),
        ),
      );
    } else if (type == 'health_alert' && seniorId != null) {
      SeniorCareApp.navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => VitalsTrackerScreen(
            seniorId: seniorId,
            userRole: role,
          ),
        ),
      );
    } else if (type == 'medicine' && seniorId != null) {
      SeniorCareApp.navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => MedicinesScreen(
            seniorId: seniorId,
            userRole: role,
          ),
        ),
      );
    } else if (type == 'appointment' && seniorId != null) {
      SeniorCareApp.navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => AppointmentsScreen(
            seniorId: seniorId,
            userRole: role,
          ),
        ),
      );
    } else if (type == 'chat') {
      final otherUserId = int.tryParse(data['other_user_id']?.toString() ?? '');
      final helpRequestId = int.tryParse(data['help_request_id']?.toString() ?? '');
      final otherName = data['other_user_name'] ?? 'Chat';

      if (otherUserId != null) {
        SeniorCareApp.navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              otherUserId: otherUserId,
              otherUserName: otherName,
              helpRequestId: helpRequestId,
            ),
          ),
        );
      }
    }
  }

  /// 🔹 Schedule Local Notifications for Medicines
  Future<void> scheduleLocalMedicineReminders(List<dynamic> medicines) async {
    // 1. Clear all existing medicine notifications to avoid duplicates/stale data
    // Usually, we use a range of IDs for medicines to avoid clearing SOS or other alerts.
    // Let's assume medicine IDs range from 1000 to 2000.
    for (int i = 1000; i <= 1100; i++) {
      await _localNotifications.cancel(i);
    }

    if (medicines.isEmpty) return;

    int notificationId = 1000;
    for (var med in medicines) {
      if (med['is_active'] == false || med['status'] == 'taken') continue;

      final name = med['medicine_name'] ?? 'Medicine';
      final dosage = med['dosage'] ?? '';
      final timeStr = med['time_of_day'] ?? ''; // Expecting something like "08:00"

      if (timeStr.contains(':')) {
        try {
          final parts = timeStr.split(':');
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);

          // Schedule daily
          await _scheduleDailyNotification(
            id: notificationId++,
            title: '💊 Medicine Reminder',
            body: 'It\'s time for $name ($dosage)',
            hour: hour,
            minute: minute,
            payload: JsonConverter.encode({
              'type': 'medicine',
              'senior_id': med['senior'].toString(),
            }),
          );
        } catch (e) {
          debugPrint("⚠️ Error scheduling med $name: $e");
        }
      }
      
      if (notificationId > 1100) break; // Limit reached
    }
  }

  Future<void> _scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    await _localNotifications.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'medicine_reminders',
          'Medicine Reminders',
          channelDescription: 'Daily medication alerts',
          importance: Importance.max,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
    // Note: In real app, use tz.TZDateTime for precision and repeating
    print("📅 Scheduled local reminder for $hour:$minute (Mocked with immediate display for demo)");
  }
}
