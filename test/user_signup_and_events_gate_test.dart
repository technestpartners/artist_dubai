import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:artist_dubai/core/di/injection_container.dart';
import 'package:artist_dubai/core/widgets/app_bottom_nav_bar.dart';
import 'package:artist_dubai/core/services/storage_service.dart';
import 'package:artist_dubai/core/services/live_sync_service.dart';
import 'package:artist_dubai/features/auth/presentation/views/register_view.dart';
import 'package:artist_dubai/features/events/presentation/views/events_view.dart';
import 'package:artist_dubai/features/events/presentation/views/event_photos_view.dart';
import 'package:artist_dubai/features/events/presentation/views/events_competition_view.dart';
import 'package:artist_dubai/features/galleries/presentation/views/galleries_view.dart';

class _TestHttpOverrides extends HttpOverrides {}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = _TestHttpOverrides();
  });

  group('User Sign Up & Auth Gate Tests', () {
    testWidgets('RegisterView renders clean account registration form without role switcher', (tester) async {
      SharedPreferences.setMockInitialValues({'is_logged_in': false});
      await sl.reset();
      await initDependencyInjection();

      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterView(),
        ),
      );
      await tester.pump();

      // Verify clean registration form
      expect(find.text("Join Dubai's Artist Community"), findsOneWidget);
      expect(find.text('Free access to explore Dubai art events, exhibitions & galleries.'), findsOneWidget);
      expect(find.text('Sign Up & Access Events'), findsOneWidget);
      expect(find.text('Art Lover'), findsNothing);
      expect(find.text('Artist / Creator'), findsNothing);
    });

    testWidgets('EventsView shows auth gate when user is not logged in', (tester) async {
      SharedPreferences.setMockInitialValues({'is_logged_in': false});
      await sl.reset();
      await initDependencyInjection();

      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: EventsView(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Explore Dubai Art Events'), findsOneWidget);
      expect(find.text('Sign Up as Art Lover (Free Access)'), findsOneWidget);
      expect(find.text('Already have an account? Sign In'), findsOneWidget);
    });

    testWidgets('GalleriesView shows auth gate when user is not logged in', (tester) async {
      SharedPreferences.setMockInitialValues({'is_logged_in': false});
      await sl.reset();
      await initDependencyInjection();

      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: GalleriesView(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Explore Dubai Galleries'), findsOneWidget);
      expect(find.text('Sign Up as Art Lover (Free Access)'), findsOneWidget);
      expect(find.text('Already have an account? Sign In'), findsOneWidget);
    });

    testWidgets('EventPhotosView shows auth gate when user is not logged in', (tester) async {
      SharedPreferences.setMockInitialValues({'is_logged_in': false});
      await sl.reset();
      await initDependencyInjection();

      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: EventPhotosView(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Explore Dubai Event Photos'), findsOneWidget);
      expect(find.text('Sign Up as Art Lover (Free Access)'), findsOneWidget);
      expect(find.text('Already have an account? Sign In'), findsOneWidget);
    });

    testWidgets('EventsCompetitionView shows auth gate when user is not logged in', (tester) async {
      SharedPreferences.setMockInitialValues({'is_logged_in': false});
      await sl.reset();
      await initDependencyInjection();

      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: EventsCompetitionView(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Explore Art Competitions'), findsOneWidget);
      expect(find.text('Sign Up as Art Lover (Free Access)'), findsOneWidget);
      expect(find.text('Already have an account? Sign In'), findsOneWidget);
    });

    testWidgets('AppBottomNavBar shows 4 options (Home, Artists, Events, Login) when logged out, and 3 when logged in', (tester) async {
      SharedPreferences.setMockInitialValues({'is_logged_in': false});
      await sl.reset();
      await initDependencyInjection();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            bottomNavigationBar: AppBottomNavBar(currentIndex: 0),
          ),
        ),
      );
      await tester.pump();

      // Logged out: all 4 options are present (Home, Artists, Events/Calendar, Login)
      expect(find.byIcon(Icons.home_rounded), findsOneWidget);
      expect(find.byIcon(Icons.people_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
      expect(find.byIcon(Icons.login), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Artists'), findsOneWidget);
      expect(find.text('Events'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);

      // Now simulate logged in
      final storage = sl<StorageService>();
      await storage.setBool('is_logged_in', true);
      sl<LiveSyncService>().notifyAuthChanged(true);
      await tester.pumpAndSettle();

      // Logged in: 3 options (Home, Artists, Events/Calendar), Login is hidden
      expect(find.byIcon(Icons.home_rounded), findsOneWidget);
      expect(find.byIcon(Icons.people_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Artists'), findsOneWidget);
      expect(find.text('Events'), findsOneWidget);
      expect(find.text('Login'), findsNothing);
      expect(find.byIcon(Icons.login), findsNothing);
    });
  });
}
