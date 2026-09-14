import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:artist_dubai/core/di/injection_container.dart';
import 'package:artist_dubai/core/services/locale_provider.dart';
import 'package:artist_dubai/features/events/domain/models/art_event_model.dart';
import 'package:artist_dubai/features/events/presentation/views/events_view.dart';
import 'package:artist_dubai/features/events/presentation/views/event_detail_view.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class _TestHttpOverrides extends HttpOverrides {}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = _TestHttpOverrides();
    SharedPreferences.setMockInitialValues({'is_logged_in': false});
    await sl.reset();
    await initDependencyInjection();
  });

  Widget buildTestableWidget(Widget child) {
    return ChangeNotifierProvider<LocaleProvider>(
      create: (_) => LocaleProvider(),
      child: MaterialApp(
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
        home: child,
      ),
    );
  }

  group('Events Screen Layout & Theme Tests', () {
    testWidgets('EventsView renders What\'s On header, filter pills, and bottom nav in Artist Dubai theme', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const EventsView()));
      await tester.pumpAndSettle();

      // 1. Header elements
      expect(find.text("What's On"), findsOneWidget);
      expect(find.text('Search Events'), findsOneWidget);

      // 2. Date Filter Pills
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('This Week'), findsOneWidget);
      expect(find.text('Custom Dates'), findsOneWidget);

      // 3. Featured section and See All
      expect(find.text('Featured'), findsOneWidget);
      expect(find.text('SEE ALL'), findsOneWidget);

      // 4. Secondary Filter Chips
      expect(find.text('Date'), findsOneWidget);
      expect(find.text('Price'), findsNothing);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Sort By'), findsOneWidget);

      // Verify no 'Buy Tickets' button on event cards
      expect(find.text('Buy Tickets'), findsNothing);
    });

    testWidgets('Tapping SEE ALL switches to Search Results view with filter options', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const EventsView()));
      await tester.pumpAndSettle();

      // Tap SEE ALL
      await tester.tap(find.text('SEE ALL'));
      await tester.pumpAndSettle();

      // Search Results
      expect(find.text('Search Results'), findsOneWidget);
    });

    testWidgets('EventDetailView renders hero, purple date/time, expandable description, location, map, and no ticket buttons', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final sample = ArtEventModel.mockEvents.firstWhere((e) => e.title.contains('Ultra Trail'));

      await tester.pumpWidget(buildTestableWidget(EventDetailView(event: sample)));
      await tester.pumpAndSettle();

      // Title & Date/Time
      expect(find.text('Ultra Trail Dubai 2026'), findsOneWidget);
      expect(find.text('06:00 AM • 27 Nov - 29 Nov'), findsOneWidget);

      // Location
      expect(find.text('Hatta Wadi Hub, located off the Dubai-Hatta road, Dubai'), findsOneWidget);

      // Read More
      expect(find.text('Read More'), findsOneWidget);

      // Map labels
      expect(find.text('Hatta Wadi Hub'), findsWidgets);
      expect(find.text('Google'), findsOneWidget);
      expect(find.text('Open Directions'), findsOneWidget);
      expect(find.text('Birds lake'), findsNothing);

      // Confirm "BUY TICKETS" is completely removed
      expect(find.text('BUY TICKETS'), findsNothing);
      expect(find.text('Buy Tickets'), findsNothing);

      // Top Actions: Favorite, Share
      expect(find.byIcon(Icons.favorite_border), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.ios_share), findsOneWidget);
    });

    testWidgets('EventDetailView formats date/time without duplicate time strings', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Event 5 has both dateTime: 'Today • 09:00 AM - 06:00 PM' and timeRange: '09:00 AM - 06:00 PM'
      final event5 = ArtEventModel.mockEvents.firstWhere((e) => e.id == '5');
      await tester.pumpWidget(buildTestableWidget(EventDetailView(event: event5)));
      await tester.pumpAndSettle();

      // Must display clean non-duplicated schedule
      expect(find.text('Today • 09:00 AM - 06:00 PM'), findsWidgets);
      // Ensure the buggy duplicated string does NOT exist anywhere
      expect(find.text('09:00 AM - 06:00 PM • Today • 09:00 AM - 06:00 PM'), findsNothing);
      // Ensure price badge ('Free') is removed from similar event cards
      expect(find.text('Free'), findsNothing);
    });
    testWidgets('Category filter properly filters events including Arabic Calligraphy', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const EventsView()));
      await tester.pumpAndSettle();

      // Tap on Category filter chip
      await tester.tap(find.text('Category'));
      await tester.pumpAndSettle();

      // Select 'Arabic Calligraphy' from modal sheet
      final calligraphyTile = find.widgetWithText(ListTile, 'Arabic Calligraphy');
      expect(calligraphyTile, findsOneWidget);
      await tester.tap(calligraphyTile);
      await tester.pumpAndSettle();

      // Verify active badge shows 'Arabic Calligraphy'
      expect(find.widgetWithText(GestureDetector, 'Arabic Calligraphy'), findsWidgets);

      // Verify matching Arabic Calligraphy event is visible
      expect(find.text('Dubai International Arabic Calligraphy Biennale'), findsOneWidget);

      // Tap Clear All
      await tester.tap(find.text('Clear All'));
      await tester.pumpAndSettle();

      // Should return to What's On hub with Featured
      expect(find.text('Featured'), findsOneWidget);
    });

    testWidgets('Quick date filter pills and search bar work properly', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const EventsView()));
      await tester.pumpAndSettle();

      // Tap 'Today' pill
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();

      // Verify Search Results view is active
      expect(find.text('Search Results'), findsOneWidget);
      expect(find.text('Today'), findsWidgets);

      // Enter search query
      await tester.enterText(find.byType(TextField), 'Biennale');
      await tester.pumpAndSettle();

      // Verify filtered search result is displayed
      expect(find.text('Dubai International Arabic Calligraphy Biennale'), findsOneWidget);

      // Clear search via clear icon
      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pumpAndSettle();
    });
  });
}
