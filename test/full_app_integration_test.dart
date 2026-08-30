import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:artist_dubai/core/di/injection_container.dart';
import 'package:artist_dubai/features/auth/presentation/views/login_view.dart';
import 'package:artist_dubai/features/auth/presentation/views/register_view.dart';
import 'package:artist_dubai/features/events/presentation/views/events_view.dart';
import 'package:artist_dubai/features/events/presentation/views/create_art_event_view.dart';
import 'package:artist_dubai/features/bookings/presentation/views/book_artist_view.dart';
import 'package:artist_dubai/features/bookings/presentation/views/bookings_view.dart';
import 'package:artist_dubai/features/government/presentation/views/government_portal_view.dart';
import 'package:artist_dubai/features/about_us/presentation/views/about_us_view.dart';

class _TestHttpOverrides extends HttpOverrides {}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = _TestHttpOverrides();
    SharedPreferences.setMockInitialValues({});
    await sl.reset();
    await initDependencyInjection();
  });

  group('Full App Feature & Integration UI Test Suite', () {
    testWidgets('1. Login View rendering test', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: LoginView()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Login'), findsWidgets);
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('2. Register View rendering & input test', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: RegisterView()));
      await tester.pumpAndSettle();

      expect(find.textContaining("Join Dubai's Artist Community"), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(4));
    });

    testWidgets('3. Events View & Event Card Interaction', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: EventsView()));
      await tester.pumpAndSettle();

      expect(find.text('Art Events'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('4. Create Art Event Form Rendering Test', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: CreateArtEventView()));
      await tester.pumpAndSettle();

      expect(find.text('Create Art Event'), findsOneWidget);
      expect(find.text('Create Event'), findsOneWidget);
    });

    testWidgets('5. Bookings View & Create Booking Form Test', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: BookingsView()));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('My Bookings'), findsOneWidget);

      await tester.pumpWidget(const MaterialApp(home: BookArtistView()));
      await tester.pumpAndSettle();

      expect(find.text('Book an Artist'), findsOneWidget);
      expect(find.text('Submit Booking Request'), findsOneWidget);
    });

    testWidgets('6. Government Portal View & Filtering', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: GovernmentPortalView()));
      await tester.pumpAndSettle();

      expect(find.text('Government Portal'), findsOneWidget);
      expect(find.text('Dubai Culture & Arts Authority'), findsOneWidget);
    });

    testWidgets('7. About Us View rendering test', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: AboutUsView()));
      expect(find.text('ABOUT US'), findsOneWidget);
    });
  });
}
