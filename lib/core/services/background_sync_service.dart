// ignore_for_file: unreachable_from_main
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../constants/api_endpoints.dart';
import 'local_notification_service.dart';

/// Top-level background execution dispatcher required by Workmanager.
/// Runs in a dedicated background isolate even when the app is completely closed or killed.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');
      if (email == null || email.trim().isEmpty) {
        return true;
      }

      final cleanEmail = email.trim().toLowerCase();
      final url =
          '${ApiEndpoints.baseUrl}/${ApiEndpoints.notifications}&email=${Uri.encodeComponent(cleanEmail)}';

      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      final response = await dio.get(url);
      if (response.statusCode == 200 && response.data != null) {
        Map<String, dynamic> data = {};
        if (response.data is Map<String, dynamic>) {
          data = response.data as Map<String, dynamic>;
        } else if (response.data is String) {
          data = jsonDecode(response.data as String) as Map<String, dynamic>;
        }

        final notificationsData =
            (data['data'] != null && data['data'] is Map<String, dynamic>)
                ? (data['data']['notifications'] as List<dynamic>?)
                : (data['notifications'] as List<dynamic>?);

        if (notificationsData == null || notificationsData.isEmpty) {
          return true;
        }

        final alertedList =
            prefs.getStringList('alerted_notification_ids') ?? <String>[];
        final alertedIds = alertedList.toSet();

        final fln = FlutterLocalNotificationsPlugin();
        const androidInit = AndroidInitializationSettings(
          '@mipmap/ic_launcher',
        );
        const darwinInit = DarwinInitializationSettings();
        const initSettings = InitializationSettings(
          android: androidInit,
          iOS: darwinInit,
        );
        await fln.initialize(settings: initSettings);

        for (final item in notificationsData) {
          if (item is! Map<String, dynamic>) continue;
          final isRead =
              item['is_read'] == true ||
              item['is_read'] == 1 ||
              item['is_read'] == '1';
          if (isRead) continue;

          final id = item['id']?.toString() ?? '0';
          if (!alertedIds.contains(id)) {
            alertedIds.add(id);

            final title = item['title'] as String? ?? 'Artist Dubai';
            final body = item['body'] as String? ?? 'You have a new update';
            final route = item['route'] as String?;

            const androidDetails = AndroidNotificationDetails(
              LocalNotificationService.channelId,
              LocalNotificationService.channelName,
              channelDescription: LocalNotificationService.channelDescription,
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

            const notifDetails = NotificationDetails(
              android: androidDetails,
              iOS: darwinDetails,
            );

            await fln.show(
              id:
                  int.tryParse(id) ??
                  (DateTime.now().millisecondsSinceEpoch ~/ 1000).abs(),
              title: title,
              body: body,
              notificationDetails: notifDetails,
              payload: route,
            );
          }
        }

        final updatedList = alertedIds.toList();
        if (updatedList.length > 200) {
          updatedList.removeRange(0, updatedList.length - 200);
        }
        await prefs.setStringList('alerted_notification_ids', updatedList);
      }
    } catch (e) {
      debugPrint('Background notification sync error: $e');
    }
    return Future.value(true);
  });
}

/// Manages background tasks so that notifications arrive even when the app is completely closed.
class BackgroundSyncService {
  static const String periodicTaskName =
      'com.imbu.DubaiArtists.backgroundNotificationSync';
  static const String taskIdentifier = 'backgroundNotificationSyncTask';
  static bool _isInitialized = false;

  /// Initializes Workmanager and registers a periodic background worker (every 15 minutes).
  static Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      // Workmanager is supported on Android and iOS physical/virtual devices
      if (!kIsWeb) {
        await Workmanager().initialize(callbackDispatcher);

        await Workmanager().registerPeriodicTask(
          periodicTaskName,
          taskIdentifier,
          frequency: const Duration(minutes: 15),
          constraints: Constraints(networkType: NetworkType.connected),
          existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
        );
        _isInitialized = true;
      }
    } catch (e) {
      debugPrint('BackgroundSyncService initialization error: $e');
    }
  }

  /// Triggers an immediate one-off background check when app transitions to paused / closed.
  static Future<void> scheduleImmediateBackgroundCheck() async {
    if (kIsWeb) return;
    try {
      await Workmanager().registerOneOffTask(
        'com.imbu.DubaiArtists.oneOffSync_${DateTime.now().millisecondsSinceEpoch}',
        taskIdentifier,
        constraints: Constraints(networkType: NetworkType.connected),
        initialDelay: const Duration(seconds: 10),
      );
    } catch (_) {}
  }
}
