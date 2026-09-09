import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/app.dart';
import 'core/di/injection_container.dart';
import 'core/services/live_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait by default
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Dependency Injection
  await initDependencyInjection();

  // Start Real-Time Multi-Device Database Live Sync
  sl<LiveSyncService>().startMultiDeviceSync();

  // Run Root Application
  runApp(const ArtistDubaiApp());
}
