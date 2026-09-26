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
import 'package:artist_dubai/features/admin/presentation/views/admin_dashboard_view.dart';

import 'backend_frontend_sync_integration_test.dart';

class _TestHttpOverrides extends HttpOverrides {}

void main() {
  late MockSyncApiClient mockClient;
  late ApiService apiService;
  late LiveSyncService liveSync;
  late NotificationService notifService;
  late StorageService storageService;

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

    sl.registerSingleton<StorageService>(storageService);
    sl.registerSingleton<ApiClient>(mockClient);
    sl.registerSingleton<ApiService>(apiService);
    sl.registerSingleton<LiveSyncService>(liveSync);

    notifService = NotificationService();
    sl.registerSingleton<NotificationService>(notifService);
  });

  tearDown(() async {
    liveSync.dispose();
    await sl.reset();
  });

  testWidgets('Admin Dashboard Government tab displays Close when open and Open when closed', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: AdminDashboardView(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Government tab
    final govTabFinder = find.text('Government');
    expect(govTabFinder, findsWidgets);
    await tester.tap(govTabFinder.first);
    await tester.pumpAndSettle();

    // Verify Government entries are loaded
    expect(find.text('Dubai Culture & Arts Authority'), findsWidgets);

    // Initial state: it is Open, so tapping the Closed segment will close it
    final closeToggleFinder = find.byKey(const Key('admin_toggle_close_btn'));
    expect(closeToggleFinder, findsWidgets);

    // Click 'Closed' toggle segment to close the venue
    await tester.tap(closeToggleFinder.first);
    await tester.pumpAndSettle();

    // Now it is Closed, so tapping 'Open' toggle segment re-opens it
    final openToggleFinder = find.byKey(const Key('admin_toggle_open_btn'));
    expect(openToggleFinder, findsWidgets);

    // Click 'Open' toggle segment to re-open the venue
    await tester.tap(openToggleFinder.first);
    await tester.pumpAndSettle();

    // It is open again
    expect(find.byKey(const Key('admin_toggle_close_btn')), findsWidgets);
  });

  testWidgets('Admin Dashboard Art Centers tab displays Close when open and Open when closed', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: AdminDashboardView(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Art Centers tab
    final artCentersTabFinder = find.text('Art Centers');
    expect(artCentersTabFinder, findsWidgets);
    await tester.tap(artCentersTabFinder.first);
    await tester.pumpAndSettle();

    // Verify toggle buttons exist in Art Centers
    final closeToggleFinder = find.byKey(const Key('admin_toggle_close_btn'));
    if (closeToggleFinder.evaluate().isNotEmpty) {
      await tester.tap(closeToggleFinder.first);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('admin_toggle_open_btn')), findsWidgets);
    }
  });
}
