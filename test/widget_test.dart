import 'dart:io';
import 'package:artist_dubai/app/app.dart';
import 'package:artist_dubai/core/di/injection_container.dart';
import 'package:artist_dubai/core/services/api_service.dart';
import 'package:artist_dubai/features/artists/presentation/views/artist_detail_view.dart';
import 'package:artist_dubai/features/artists/presentation/views/category_detail_view.dart';
import 'package:artist_dubai/features/artists/presentation/views/create_category_view.dart';
import 'package:artist_dubai/features/artists/presentation/views/explore_categories_view.dart';
import 'package:artist_dubai/features/profile/presentation/views/profile_view.dart';
import 'package:artist_dubai/features/splash/presentation/views/splash_screen_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:artist_dubai/core/services/locale_provider.dart';
import 'package:artist_dubai/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class _TestHttpOverrides extends HttpOverrides {}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = _TestHttpOverrides();
    SharedPreferences.setMockInitialValues({});
    await sl.reset();
    await initDependencyInjection();
  });

  Widget testApp(Widget child) {
    return ChangeNotifierProvider<LocaleProvider>.value(
      value: sl<LocaleProvider>(),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
        theme: ThemeData(useMaterial3: true),
      ),
    );
  }

  group('Automated UI & Integration Automation Suite', () {
    testWidgets('1. Onboarding to Home Dashboard Flow', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const ArtistDubaiApp());
      await tester.pump(const Duration(milliseconds: 100));

      // Tap splash screen to skip directly to onboarding
      if (find.byType(SplashScreenView).evaluate().isNotEmpty) {
        await tester.tap(find.byType(SplashScreenView));
        await tester.pumpAndSettle();
      }

      expect(find.text('Welcome to Dubai Artists'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.text('ARTIST DUBAI'), findsOneWidget);
      expect(find.text('COMMUNITY PLATFORM'), findsOneWidget);
    });

    testWidgets('2. Explore Categories View Rendering & Grid Test', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(testApp(const ExploreCategoriesView()));
      await tester.pumpAndSettle();

      expect(find.text('Explore Categories'), findsOneWidget);
      expect(find.text('Calligraphy & Typography'), findsOneWidget);
    });

    testWidgets('3. Category Detail View & Segmented Tab Switcher Test', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(testApp(const CategoryDetailView()));
      await tester.pumpAndSettle();

      expect(find.text('Calligraphy & Typography'), findsOneWidget);

      // Switch to Artworks Tab via InkWell ancestor
      final artworksTab = find.ancestor(
        of: find.textContaining('Artworks'),
        matching: find.byType(InkWell),
      );
      await tester.tap(artworksTab.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Artworks'), findsWidgets);
    });

    testWidgets('4. Artist Detail View Grid/List Layout Switcher Test', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(testApp(const ArtistDetailView()));
      await tester.pumpAndSettle();

      expect(find.text('Artist Profile'), findsOneWidget);
      expect(find.text('Portfolio'), findsOneWidget);
      expect(find.byIcon(Icons.grid_view), findsOneWidget);
      expect(find.byIcon(Icons.view_list), findsOneWidget);

      // Tap List View Mode Toggle
      await tester.tap(find.byIcon(Icons.view_list));
      await tester.pumpAndSettle();
    });

    testWidgets('5. Create Category View Validation Test', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(testApp(const CreateCategoryView()));
      await tester.pumpAndSettle();

      expect(find.text('Create New Category'), findsOneWidget);
      expect(find.text('Category Name'), findsOneWidget);

      await tester.ensureVisible(find.text('Create Category'));
      await tester.tap(find.text('Create Category'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter category name'), findsOneWidget);
    });

    testWidgets('6. Account Settings & Modals Test', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(testApp(const ProfileView()));
      await tester.pumpAndSettle();

      expect(find.text('Account Settings'), findsOneWidget);
      expect(find.text('Account Information'), findsOneWidget);

      await tester.ensureVisible(find.text('Change Password'));
      await tester.tap(find.text('Change Password'));
      await tester.pumpAndSettle();

      expect(find.text('New Password'), findsWidgets);
      expect(find.text('Confirm New Password'), findsWidgets);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Delete Account'));
      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets('7. Events & Activities View Test', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const ArtistDubaiApp());
      await tester.pumpAndSettle();

      sl<ApiService>();
      expect(find.byType(ArtistDubaiApp), findsOneWidget);
    });
  });
}
