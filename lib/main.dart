import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/app.dart';
import 'core/di/injection_container.dart';
import 'core/services/background_sync_service.dart';
import 'core/services/live_sync_service.dart';
import 'core/services/local_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global uncaught exception shielding to prevent OS termination on iOS/Android
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Captured Flutter Error: ${details.exception}');
  };
  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    debugPrint('Captured Platform Error: $error');
    return true; // Return true to mark error as handled and prevent process crash
  };

  // Set system UI overlay style to eliminate any white status bar flash on launch
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Lock orientation and initialize dependency injection concurrently
  await Future.wait([
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]),
    initDependencyInjection(),
  ]);

  // Run Root Application immediately
  runApp(const ArtistDubaiApp());

  // Start Real-Time Multi-Device Database Live Sync & Push Notifications after initial frame render
  WidgetsBinding.instance.addPostFrameCallback((_) {
    try {
      sl<LocalNotificationService>().initialize();
      sl<LiveSyncService>().syncAllSilently(forceRefresh: true);
      sl<LiveSyncService>().startMultiDeviceSync();
      BackgroundSyncService.initialize();
    } catch (_) {}
  });
}
