import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import '../../app/routes/app_router.dart';
import '../di/injection_container.dart';
import 'storage_service.dart';

/// Comprehensive Local & Push Notification Service for Artist Dubai.
/// Delivers native OS status bar alerts, heads-up notifications, and
/// interactive in-app banners without requiring Firebase Cloud Messaging.
class LocalNotificationService {
  static const String channelId = 'artist_dubai_channel';
  static const String channelName = 'Artist Dubai Notifications';
  static const String channelDescription =
      'Real-time alerts for artist messages, bookings, and exhibitions';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Initialize native notification channels and response handlers
  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    try {
      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      _isInitialized = true;
    } catch (e) {
      debugPrint('LocalNotificationService initialization error: $e');
    }

    // Auto-request permission if not requested before
    try {
      final storage = sl<StorageService>();
      final alreadyAsked = storage.getBool('notifications_permission_asked') ?? false;
      if (!alreadyAsked) {
        await requestPermissions();
        await storage.setBool('notifications_permission_asked', true);
      }
    } catch (_) {}
  }

  /// Request runtime permissions on Android 13+ and iOS
  Future<bool> requestPermissions() async {
    try {
      // Android 13+ (API 33+)
      final androidImplementation = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidImplementation != null) {
        final granted = await androidImplementation.requestNotificationsPermission();
        return granted ?? false;
      }

      // iOS
      final iosImplementation = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (iosImplementation != null) {
        final granted = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
    return false;
  }

  /// Handle tap on system notification
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.trim().isNotEmpty) {
      handleNotificationNavigation(payload.trim());
    }
  }

  /// Navigate to route specified in notification payload
  void handleNotificationNavigation(String route) {
    final navContext = AppRouter.rootNavigatorKey.currentContext;
    if (navContext != null) {
      try {
        GoRouter.of(navContext).push(route);
      } catch (_) {
        try {
          Navigator.of(navContext).pushNamed(route);
        } catch (_) {}
      }
    }
  }

  /// Show a native system notification with sound and heads-up banner
  Future<void> showNotification({
    int? id,
    required String title,
    required String body,
    String? payload,
    String type = 'general',
  }) async {
    final notifId = id ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000).abs();

    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      color: Color(0xFF5E227A),
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    try {
      await _plugin.show(
        id: notifId,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }

    // Also trigger in-app floating banner if app is currently in foreground
    showInAppBanner(
      title: title,
      body: body,
      payload: payload,
      type: type,
    );
  }

  /// Show a floating in-app banner for active foreground sessions
  void showInAppBanner({
    required String title,
    required String body,
    String? payload,
    String type = 'general',
  }) {
    final navContext = AppRouter.rootNavigatorKey.currentContext;
    if (navContext == null) return;

    try {
      final messenger = ScaffoldMessenger.maybeOf(navContext);
      if (messenger == null) return;

      IconData icon = Icons.notifications_active_outlined;
      Color iconColor = const Color(0xFF6A2777);
      Color bgColor = const Color(0xFF1E1E2E);

      final t = type.toLowerCase();
      if (t.contains('message') || t.contains('chat')) {
        icon = Icons.chat_bubble_outline_rounded;
        iconColor = const Color(0xFF10B981);
      } else if (t.contains('booking') || t.contains('rsvp')) {
        icon = Icons.calendar_month_outlined;
        iconColor = const Color(0xFF6A2777);
      } else if (t.contains('event')) {
        icon = Icons.celebration_outlined;
        iconColor = const Color(0xFFD97706);
      }

      messenger.showSnackBar(
        SnackBar(
          elevation: 6,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF334155), width: 1),
          ),
          duration: const Duration(seconds: 4),
          content: InkWell(
            onTap: () {
              messenger.hideCurrentSnackBar();
              if (payload != null && payload.trim().isNotEmpty) {
                handleNotificationNavigation(payload.trim());
              }
            },
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (payload != null && payload.trim().isNotEmpty) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Color(0xFF94A3B8),
                    size: 14,
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    } catch (_) {}
  }
}
