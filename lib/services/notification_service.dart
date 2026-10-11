import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';
import '../screens/task_form_screen.dart';
import 'task_service.dart';

/// Runs in its own isolate when a message arrives in background/terminated state.
/// Firebase shows the system notification itself, so we only need to init Firebase.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Background message: ${message.messageId}');
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  // Two channels so that notification importance can depend on task priority.
  static const AndroidNotificationChannel _defaultChannel = AndroidNotificationChannel(
    'task_default_channel',
    'Task Notifications',
    description: 'Normal priority task notifications',
    importance: Importance.high,
  );
  static const AndroidNotificationChannel _highChannel = AndroidNotificationChannel(
    'task_high_channel',
    'High Priority Tasks',
    description: 'Urgent task notifications',
    importance: Importance.max,
  );

  Future<void> init() async {
    // 1. Permissions (iOS + Android 13+)
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // 2. Local notifications setup
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _local.initialize(
      settings,
      // User tapped a LOCAL notification (shown while app was in foreground)
      onDidReceiveNotificationResponse: (response) => _openTask(response.payload),
    );

    final androidImpl = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.createNotificationChannel(_defaultChannel);
    await androidImpl?.createNotificationChannel(_highChannel);

    // 3. FOREGROUND: FCM does not show anything -> create a local notification
    FirebaseMessaging.onMessage.listen(_showLocalNotification);

    // 4. BACKGROUND: user tapped the notification Firebase displayed
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _openTask(m.data['taskId']));

    // 5. TERMINATED: app was launched by tapping a notification
    final initial = await _fcm.getInitialMessage();
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openTask(initial.data['taskId']));
    }

    // Token
    final token = await _fcm.getToken();
    debugPrint('FCM TOKEN: $token');
    _fcm.onTokenRefresh.listen(_saveToken);
  }

  Future<String?> getToken() => _fcm.getToken();

  /// Save the device token under the signed-in user (call after login).
  Future<void> saveTokenForCurrentUser() async {
    final token = await _fcm.getToken();
    if (token != null) await _saveToken(token);
  }

  Future<void> _saveToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({'fcmToken': token, 'email': user.email}, SetOptions(merge: true));
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final title = message.notification?.title ?? message.data['title'] ?? 'New Task';
    final body = message.notification?.body ?? message.data['body'] ?? '';
    final taskId = message.data['taskId'] as String?;
    final isHigh = (message.data['priority'] ?? '').toString().toLowerCase() == 'high';

    final channel = isHigh ? _highChannel : _defaultChannel;
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: channel.importance,
        priority: isHigh ? Priority.max : Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(),
    );

    await _local.show(
      message.hashCode,
      isHigh ? '🔥 $title' : title,
      body,
      details,
      payload: taskId, // used when the user taps the local notification
    );
  }

  /// Opens the Task List, and the exact task if a taskId was sent.
  Future<void> _openTask(String? taskId) async {
    final nav = navigatorKey.currentState;
    if (nav == null || FirebaseAuth.instance.currentUser == null) return;

    nav.popUntil((route) => route.isFirst); // back to Task List
    if (taskId == null || taskId.isEmpty) return;

    final task = await TaskService().getById(taskId);
    if (task != null) {
      nav.push(MaterialPageRoute(builder: (_) => TaskFormScreen(task: task)));
    }
  }
}
