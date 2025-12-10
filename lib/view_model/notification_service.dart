import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/utils.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
    showLog('✅ Notification service initialized');
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    showLog('📱 Notification tapped: ${response.payload}');
    // Navigation will be handled by the app when it detects the task is complete
  }

  /// Show notification when video generation is complete
  Future<void> showVideoCompleteNotification({
    required String title,
    required bool isSuccess,
  }) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'video_generation',
      'Video Generation',
      channelDescription: 'Notifications for video generation completion',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final notificationTitle = isSuccess
        ? '✅ Video Ready!'
        : '❌ Generation Failed';

    final notificationBody = isSuccess
        ? 'Your "$title" video has been generated successfully!'
        : 'Failed to generate "$title" video. Please try again.';

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      notificationTitle,
      notificationBody,
      notificationDetails,
      payload: title,
    );

    showLog('📬 Notification shown: $notificationTitle');
  }

  /// Request notification permissions (for iOS)
  Future<bool> requestPermissions() async {
    if (!_initialized) await initialize();

    final result = await _notifications
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    return result ?? true;
  }
}