import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artist_dubai/features/ai/presentation/views/ai_art_guide_view.dart';
import 'package:artist_dubai/core/di/injection_container.dart';
import 'package:artist_dubai/core/services/storage_service.dart';
import 'package:artist_dubai/core/services/api_service.dart';
import 'package:artist_dubai/core/services/live_sync_service.dart';
import 'package:artist_dubai/core/services/notification_service.dart';
import 'package:artist_dubai/core/services/locale_provider.dart';
import 'package:artist_dubai/core/network/api_client.dart';
import 'package:artist_dubai/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'backend_frontend_sync_integration_test.dart';

class _TestHttpOverrides extends HttpOverrides {}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = _TestHttpOverrides();
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});

    await sl.reset();
    final prefs = await SharedPreferences.getInstance();
    final storageService = StorageServiceImpl(
      prefs: prefs,
      secureStorage: const FlutterSecureStorage(),
    );
    final mockClient = MockSyncApiClient();
    final apiService = ApiService(mockClient);
    final liveSync = LiveSyncService(apiService);
    final localeProvider = LocaleProvider();

    sl.registerSingleton<StorageService>(storageService);
    sl.registerSingleton<ApiClient>(mockClient);
    sl.registerSingleton<ApiService>(apiService);
    sl.registerSingleton<LiveSyncService>(liveSync);
    sl.registerSingleton<LocaleProvider>(localeProvider);
    sl.registerSingleton<NotificationService>(NotificationService());
  });

  tearDown(() async {
    if (sl.isRegistered<LiveSyncService>()) {
      sl<LiveSyncService>().dispose();
    }
    await sl.reset();
  });

  testWidgets('Global Art Guide renders new Title & Subtitle in English and Arabic', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final localeProvider = sl<LocaleProvider>();

    // 1. English Mode
    await tester.pumpWidget(
      ChangeNotifierProvider<LocaleProvider>.value(
        value: localeProvider,
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en'), Locale('ar')],
          locale: Locale('en'),
          home: AiArtGuideView(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify English Title & Subhead
    expect(find.text('Global Art Guide'), findsWidgets);
    expect(
      find.text('Discover artists, art history, and cultural origins in Dubai, across the UAE, and worldwide.'),
      findsOneWidget,
    );
    expect(find.text('GLOBAL ART GUIDE'), findsOneWidget);

    // 2. Arabic Mode
    localeProvider.setLocale(const Locale('ar'));
    await tester.pumpWidget(
      ChangeNotifierProvider<LocaleProvider>.value(
        value: localeProvider,
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en'), Locale('ar')],
          locale: Locale('ar'),
          home: AiArtGuideView(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Arabic Title & Subhead
    expect(find.text('دليل الفن العالمي'), findsWidgets);
    expect(
      find.text('اكتشف الفنانين وتاريخ الفن والأصول الثقافية في دبي وفي جميع أنحاء الإمارات وحول العالم.'),
      findsOneWidget,
    );
  });
}
