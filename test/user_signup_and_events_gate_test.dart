import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:artist_dubai/core/di/injection_container.dart';
import 'package:artist_dubai/features/auth/presentation/views/register_view.dart';
import 'package:artist_dubai/features/events/presentation/views/events_view.dart';
import 'package:artist_dubai/features/galleries/presentation/views/galleries_view.dart';

class _TestHttpOverrides extends HttpOverrides {}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = _TestHttpOverrides();
  });

  group('User Sign Up & Auth Gate Tests', () {
    testWidgets('RegisterView renders Art Lover tab by default and switches roles', (tester) async {
      SharedPreferences.setMockInitialValues({'is_logged_in': false});
      await sl.reset();
      await initDependencyInjection();

      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterView(initialRole: 'user'),
        ),
      );
      await tester.pump();

      // Verify Art Lover mode is active
      expect(find.text('Art Lover'), findsOneWidget);
      expect(find.text('Artist / Creator'), findsOneWidget);
      expect(find.text('Sign Up as Art Lover'), findsOneWidget);
      expect(find.text('Sign Up & Access Events'), findsOneWidget);

      // Tap on Artist / Creator
      await tester.tap(find.text('Artist / Creator'));
      await tester.pump();

      expect(find.text("Join Dubai's Artist Community"), findsOneWidget);
      expect(find.text('Create Artist Account'), findsOneWidget);
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
  });
}
