import 'dart:io';
import 'package:artist_dubai/app/app.dart';
import 'package:artist_dubai/core/di/injection_container.dart';
import 'package:artist_dubai/features/artists/presentation/views/explore_categories_view.dart';
import 'package:artist_dubai/features/bookings/presentation/views/book_artist_view.dart';
import 'package:artist_dubai/features/events/domain/models/art_event_model.dart';
import 'package:artist_dubai/features/events/presentation/views/event_detail_view.dart';
import 'package:artist_dubai/features/government/presentation/views/government_portal_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestHttpOverrides extends HttpOverrides {}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = _TestHttpOverrides();
    SharedPreferences.setMockInitialValues({});
    await sl.reset();
    await initDependencyInjection();
  });

  group('Responsive Layouts & Logic Edge Case Test Suite', () {
    testWidgets('1. Mobile Responsive Render Test (360x740)', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const ArtistDubaiApp());
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Dubai Artists'), findsOneWidget);
    });

    testWidgets('2. Tablet Responsive Render Test (768x1024)', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: ExploreCategoriesView()));
      await tester.pumpAndSettle();

      expect(find.text('Explore Categories'), findsOneWidget);
      expect(find.text('Calligraphy & Typography'), findsOneWidget);
    });

    testWidgets('3. Desktop/Web Responsive Render Test (1440x900)', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: EventDetailView(event: ArtEventModel.mockEvents.first),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('About this event'), findsOneWidget);
      expect(find.text('Book Now'), findsOneWidget);
      expect(find.text('Discover More Talented Artists'), findsOneWidget);
    });

    testWidgets('4. Government Portal Open/Closed Logic & Search Filter Test', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: GovernmentPortalView()));
      await tester.pumpAndSettle();

      expect(find.text('Government Portal'), findsOneWidget);
      expect(find.text('Dubai Culture & Arts Authority'), findsOneWidget);
    });

    testWidgets('5. Book Artist View Form Input & Budget Dropdown Logic Test', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(home: BookArtistView(artistName: 'Fatima Al Qasimi')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Book an Artist'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Submit Booking Request'), findsOneWidget);
    });
  });
}
