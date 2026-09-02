import 'package:flutter/material.dart';
import '../core/constants/app_strings.dart';
import '../core/di/injection_container.dart';
import '../core/services/live_sync_service.dart';
import 'app_theme.dart';
import 'routes/app_router.dart';

class ArtistDubaiApp extends StatefulWidget {
  const ArtistDubaiApp({super.key});

  @override
  State<ArtistDubaiApp> createState() => _ArtistDubaiAppState();
}

class _ArtistDubaiAppState extends State<ArtistDubaiApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Start continuous multi-device live sync heartbeat across all active user devices
    try {
      sl<LiveSyncService>().startMultiDeviceSync(interval: const Duration(seconds: 12));
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // User returned to the app: immediately sync latest changes made from other devices
      try {
        sl<LiveSyncService>().syncAllSilently(forceRefresh: true);
        sl<LiveSyncService>().startMultiDeviceSync(interval: const Duration(seconds: 12));
      } catch (_) {}
    } else if (state == AppLifecycleState.paused) {
      // Pause multi-device sync when app is backgrounded to preserve device battery
      try {
        sl<LiveSyncService>().stopMultiDeviceSync();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    try {
      sl<LiveSyncService>().stopMultiDeviceSync();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: AppRouter.router,
    );
  }
}
