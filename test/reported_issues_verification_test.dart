import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:artist_dubai/core/di/injection_container.dart';
import 'package:artist_dubai/core/network/api_client.dart';
import 'package:artist_dubai/core/services/api_service.dart';
import 'package:artist_dubai/core/services/live_sync_service.dart';
import 'package:artist_dubai/core/services/notification_service.dart';
import 'package:artist_dubai/core/services/storage_service.dart';
import 'package:artist_dubai/core/services/locale_provider.dart';
import 'package:artist_dubai/features/admin/presentation/views/admin_dashboard_view.dart';
import 'package:artist_dubai/features/galleries/presentation/views/gallery_registration_view.dart';
import 'package:artist_dubai/features/events/presentation/views/create_art_event_view.dart';
import 'package:artist_dubai/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:artist_dubai/app/app.dart';

import 'backend_frontend_sync_integration_test.dart';

class _TestHttpOverrides extends HttpOverrides {}

void main() {
  late MockSyncApiClient mockClient;
  late ApiService apiService;
  late LiveSyncService liveSync;
  late NotificationService notifService;
  late StorageService storageService;
  late LocaleProvider localeProvider;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = _TestHttpOverrides();
    SharedPreferences.setMockInitialValues({
      'is_logged_in': true,
      'user_email': 'admin@artistdubai.com',
      'user_name': 'Dubai Art Administrator',
      'is_admin': true,
    });

    await sl.reset();
    final prefs = await SharedPreferences.getInstance();
    storageService = StorageServiceImpl(
      prefs: prefs,
      secureStorage: const FlutterSecureStorage(),
    );
    mockClient = MockSyncApiClient();
    apiService = ApiService(mockClient);
    liveSync = LiveSyncService(apiService);
    localeProvider = LocaleProvider();

    sl.registerSingleton<StorageService>(storageService);
    sl.registerSingleton<ApiClient>(mockClient);
    sl.registerSingleton<ApiService>(apiService);
    sl.registerSingleton<LiveSyncService>(liveSync);
    sl.registerSingleton<LocaleProvider>(localeProvider);

    notifService = NotificationService();
    sl.registerSingleton<NotificationService>(notifService);
  });

  tearDown(() async {
    liveSync.dispose();
    await sl.reset();
  });

  testWidgets('Issue 1: Admin Dashboard Art Centers & Government display Open action when closed and Close action when open', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: AdminDashboardView(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Check Government tab
    final govTabFinder = find.text('Government');
    expect(govTabFinder, findsWidgets);
    await tester.tap(govTabFinder.first);
    await tester.pumpAndSettle();

    // Verify initial open state: has 'Close' toggle segment
    final closeToggleFinder = find.byKey(const Key('admin_toggle_close_btn'));
    expect(closeToggleFinder, findsWidgets);

    // Tap 'Closed' toggle segment to close the venue
    await tester.tap(closeToggleFinder.first);
    await tester.pumpAndSettle();

    // Now tapping 'Open' toggle segment will re-open
    final openToggleFinder = find.byKey(const Key('admin_toggle_open_btn'));
    expect(openToggleFinder, findsWidgets);

    // Tap 'Open' toggle segment to open the venue
    await tester.tap(openToggleFinder.first);
    await tester.pumpAndSettle();

    // It is open again
    expect(find.byKey(const Key('admin_toggle_close_btn')), findsWidgets);
  });

  testWidgets('Issue 3 & 4: Gallery Registration error messages update with language and upload photo icon is visible', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    Locale currentLocale = const Locale('en');

    Widget buildApp() {
      return ChangeNotifierProvider<LocaleProvider>.value(
        value: localeProvider,
        child: MaterialApp(
          locale: currentLocale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('ar'),
          ],
          home: const GalleryRegistrationView(),
        ),
      );
    }

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Issue 4: Verify upload photo icon is visible with correct icon
    expect(find.byIcon(Icons.add_photo_alternate_rounded), findsWidgets);
    expect(find.text('Upload Photo'), findsWidgets);

    // Scroll to submit button and trigger validation
    final submitFinder = find.byType(ElevatedButton);
    await tester.ensureVisible(submitFinder.last);
    await tester.tap(submitFinder.last);
    await tester.pumpAndSettle();

    // In English mode, verify English validation messages
    expect(find.text('Please enter gallery name'), findsWidgets);
    expect(find.text('Please enter email'), findsWidgets);

    // Switch locale to Arabic
    currentLocale = const Locale('ar');
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Issue 3: In Arabic mode, verify validation messages changed to Arabic!
    expect(find.text('الرجاء إدخال اسم المعرض'), findsWidgets);
    expect(find.text('الرجاء إدخال البريد الإلكتروني'), findsWidgets);

    // Switch locale back to English
    currentLocale = const Locale('en');
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Verify messages switched back to English
    expect(find.text('Please enter gallery name'), findsWidgets);
    expect(find.text('Please enter email'), findsWidgets);
  });

  testWidgets('Issue 2: Create Art Event view rejects submission when End Date is earlier than Start Date', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

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
          supportedLocales: [
            Locale('en'),
            Locale('ar'),
          ],
          home: CreateArtEventView(fromAdmin: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final allTextFormFields = tester.widgetList<TextFormField>(find.byType(TextFormField)).toList();
    allTextFormFields[0].controller!.text = 'Dubai Art Festival 2026';
    allTextFormFields[2].controller!.text = '25-09-2026 18:00';
    // Set End Date earlier than Start Date (e.g. 23-09-2026 18:00 as shown in defect screenshot 3)
    allTextFormFields[3].controller!.text = '23-09-2026 18:00';
    await tester.pumpAndSettle();

    // Scroll to submit button and tap
    final submitButton = find.widgetWithText(ElevatedButton, 'Create Event');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    // Verify error snackbar is displayed rejecting earlier end date
    expect(find.text('End date and time must be on or after the start date and time'), findsOneWidget);
  });

  testWidgets('Session persistence on lock/unlock: didPushRouteInformation intercepts root route without resetting navigation', (tester) async {
    await tester.pumpWidget(const ArtistDubaiApp());
    await tester.pump();

    final appState = tester.state(find.byType(ArtistDubaiApp)) as WidgetsBindingObserver;

    // Simulate Android OS pushing root route on device unlock/resume
    final result = await appState.didPushRouteInformation(RouteInformation(uri: Uri.parse('/')));
    // Must return true (handled) so GoRouter is not reset to HomeView/Splash
    expect(result, isTrue);

    // Simulate empty URI
    final emptyResult = await appState.didPushRouteInformation(RouteInformation(uri: Uri.parse('')));
    expect(emptyResult, isTrue);
  });
}
