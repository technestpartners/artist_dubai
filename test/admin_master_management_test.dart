import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:artist_dubai/core/di/injection_container.dart';
import 'package:artist_dubai/features/admin/presentation/views/admin_dashboard_view.dart';
import 'package:artist_dubai/features/artists/presentation/views/create_artist_profile_view.dart';

class _TestHttpOverrides extends HttpOverrides {}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = _TestHttpOverrides();
    SharedPreferences.setMockInitialValues({
      'is_logged_in': true,
      'user_email': 'admin@artistdubai.com',
      'user_name': 'Admin User',
      'user_role': 'admin',
    });
    await sl.reset();
    await initDependencyInjection();
  });

  testWidgets('Admin Masters tab renders Categories and Experience Levels with CRUD', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: AdminDashboardView(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Masters tab button exists
    final mastersTabFinder = find.text('Masters');
    expect(mastersTabFinder, findsWidgets);

    // Tap the Masters tab
    await tester.tap(mastersTabFinder.first);
    await tester.pumpAndSettle();

    // Verify Master subtabs
    expect(find.textContaining('Categories'), findsWidgets);
    expect(find.textContaining('Levels'), findsWidgets);
    expect(find.textContaining('Locations'), findsWidgets);

    // Verify action button
    expect(find.text('New Category'), findsOneWidget);

    // Switch to Experience Levels subtab
    final expTabFinder = find.textContaining('Levels');
    await tester.tap(expTabFinder.first);
    await tester.pumpAndSettle();

    expect(find.text('New Level'), findsOneWidget);

    // Switch to Locations subtab
    final locTabFinder = find.textContaining('Locations');
    await tester.tap(locTabFinder.first);
    await tester.pumpAndSettle();

    expect(find.text('New Location'), findsOneWidget);
  });

  testWidgets('CreateArtistProfileView renders Location as a dropdown with Dubai, UAE default', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: CreateArtistProfileView()),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Location label exists
    expect(find.text('Location *'), findsOneWidget);

    // Verify Dubai, UAE is selected and displayed
    expect(find.text('Dubai, UAE'), findsWidgets);

    // Verify DropdownButtonFormField widgets exist
    final dropdownFinder = find.byType(DropdownButtonFormField<String>);
    expect(dropdownFinder, findsWidgets);
  });
}
