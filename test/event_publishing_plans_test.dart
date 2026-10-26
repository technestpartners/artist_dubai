import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:artist_dubai/features/events/presentation/views/create_art_event_view.dart';
import 'package:artist_dubai/core/di/injection_container.dart';
import 'package:artist_dubai/core/services/storage_service.dart';
import 'package:artist_dubai/core/services/api_service.dart';
import 'package:artist_dubai/core/services/live_sync_service.dart';
import 'package:artist_dubai/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:artist_dubai/core/network/api_client.dart';
import 'package:artist_dubai/core/services/notification_service.dart';
import 'package:artist_dubai/core/services/locale_provider.dart';
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

  testWidgets('CreateArtEventView renders Paid Event Publishing plans & benefits', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final localeProvider = sl<LocaleProvider>();
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
          home: Scaffold(body: CreateArtEventView(fromAdmin: true)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final plansHeader = find.textContaining('Paid Event Publishing');
    await tester.scrollUntilVisible(
      plansHeader,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    // Verify Title & Subhead
    expect(find.textContaining('Paid Event Publishing'), findsOneWidget);
    expect(find.textContaining('Choose Your Plan'), findsOneWidget);
    expect(find.textContaining('curated maps and event calendars'), findsOneWidget);

    // Verify Exclusive Benefits Banner
    expect(find.textContaining('Exclusive Benefits:'), findsOneWidget);
    expect(find.textContaining('Enjoy your first 3 months free.'), findsOneWidget);

    // Verify the 3 plans
    expect(find.text('3 Months'), findsOneWidget);
    expect(find.text('AED 2,000'), findsWidgets);

    expect(find.text('6 Months'), findsOneWidget);
    expect(find.text('AED 3,000'), findsWidgets);

    expect(find.text('12 Months'), findsOneWidget);
    expect(find.text('AED 5,000'), findsWidgets);
  });
}
