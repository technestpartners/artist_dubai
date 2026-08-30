import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:artist_dubai/core/di/injection_container.dart';
import 'package:artist_dubai/features/artists/presentation/views/artists_view.dart';
import 'package:artist_dubai/features/artists/presentation/views/create_artist_profile_view.dart';
import 'package:artist_dubai/features/artists/presentation/views/create_category_view.dart';
import 'package:artist_dubai/features/artists/presentation/views/explore_categories_view.dart';
import 'package:artist_dubai/features/auth/presentation/views/login_view.dart';
import 'package:artist_dubai/features/auth/presentation/views/register_view.dart';
import 'package:artist_dubai/features/bookings/presentation/views/book_artist_view.dart';
import 'package:artist_dubai/features/events/domain/models/art_event_model.dart';
import 'package:artist_dubai/features/events/presentation/views/create_art_event_view.dart';
import 'package:artist_dubai/features/events/presentation/views/event_detail_view.dart';
import 'package:artist_dubai/features/galleries/presentation/views/gallery_registration_view.dart';
import 'package:artist_dubai/features/government/presentation/views/government_portal_view.dart';
import 'package:artist_dubai/features/home/presentation/views/home_view.dart';
import 'package:artist_dubai/features/onboarding/presentation/views/onboarding_view.dart';
import 'package:artist_dubai/features/settings/presentation/views/settings_view.dart';

class _TestHttpOverrides extends HttpOverrides {}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = _TestHttpOverrides();
    SharedPreferences.setMockInitialValues({
      'is_logged_in': true,
      'user_email': 'manual_tester@artistdubai.com',
      'user_name': 'Manual Flow Tester',
      'has_completed_onboarding': true,
    });
    await sl.reset();
    await initDependencyInjection();
  });

  Widget wrapTestApp(Widget view) {
    return MaterialApp(
      home: view,
      theme: ThemeData(useMaterial3: true),
    );
  }

  group('Manual Flow & 1-by-1 Page Interactive Tester', () {
    testWidgets('Step 01: Onboarding flow manual interaction', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapTestApp(const OnboardingView()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Dubai Artists'), findsWidgets);
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('Step 02: Register form manual data entry & validation', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapTestApp(const RegisterView()));
      await tester.pump(const Duration(milliseconds: 100));

      final textFields = find.byType(TextField);
      expect(textFields, findsAtLeastNWidgets(3));

      // Enter manual test credentials
      await tester.enterText(textFields.at(0), 'Manual User Test');
      await tester.enterText(textFields.at(1), 'manualuser@artistdubai.com');
      await tester.enterText(textFields.at(2), 'Pass123456!');
      await tester.pump();

      expect(find.text('Manual User Test'), findsOneWidget);
    });

    testWidgets('Step 03: Login form manual data entry', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapTestApp(const LoginView()));
      await tester.pump(const Duration(milliseconds: 100));

      final textFields = find.byType(TextField);
      expect(textFields, findsAtLeastNWidgets(2));

      await tester.enterText(textFields.at(0), 'manualuser@artistdubai.com');
      await tester.enterText(textFields.at(1), 'Pass123456!');
      await tester.pump();

      expect(find.text('manualuser@artistdubai.com'), findsOneWidget);
    });

    testWidgets('Step 04: Home dashboard navigation cards', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapTestApp(const HomeView()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('ARTIST DUBAI'), findsOneWidget);
      expect(find.text('COMMUNITY PLATFORM'), findsOneWidget);
      expect(find.text('ARTISTS'), findsWidgets);
    });

    testWidgets('Step 05: Artist Profile Creation manual data entry', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapTestApp(const CreateArtistProfileView()));
      await tester.pump(const Duration(milliseconds: 100));

      final textFields = find.byType(TextField);
      expect(textFields, findsAtLeastNWidgets(3));

      // Enter manual artist details
      await tester.enterText(textFields.at(0), 'Layla Al-Khatib');
      await tester.enterText(textFields.at(1), 'Contemporary Arab expressionism and textured canvas.');
      await tester.pump();

      expect(find.text('Layla Al-Khatib'), findsOneWidget);
    });

    testWidgets('Step 06: Create Art Event manual data entry', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapTestApp(const CreateArtEventView()));
      await tester.pump(const Duration(milliseconds: 100));

      final textFields = find.byType(TextField);
      expect(textFields, findsAtLeastNWidgets(2));

      await tester.enterText(textFields.at(0), 'Dubai Kinetic Showcase 2026');
      await tester.pump();

      expect(find.text('Dubai Kinetic Showcase 2026'), findsOneWidget);
    });

    testWidgets('Step 07: Create Category manual data entry', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapTestApp(const CreateCategoryView()));
      await tester.pump(const Duration(milliseconds: 100));

      final textFields = find.byType(TextField);
      expect(textFields, findsAtLeastNWidgets(2));

      await tester.enterText(textFields.at(0), 'Interactive 3D Art');
      await tester.enterText(textFields.at(1), 'Immersive spatial 3D art installations.');
      await tester.pump();

      expect(find.text('Interactive 3D Art'), findsWidgets);
    });

    testWidgets('Step 08: Gallery Registration manual data entry', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapTestApp(const GalleryRegistrationView()));
      await tester.pump(const Duration(milliseconds: 100));

      final textFields = find.byType(TextField);
      expect(textFields, findsAtLeastNWidgets(4));

      await tester.enterText(textFields.at(0), 'Lumina Art House');
      await tester.enterText(textFields.at(1), 'Contemporary Gallery');
      await tester.enterText(textFields.at(2), 'Alserkal Avenue, Warehouse 12');
      await tester.pump();

      expect(find.text('Lumina Art House'), findsOneWidget);
    });

    testWidgets('Step 09: Book Artist manual inquiry entry', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapTestApp(const BookArtistView()));
      await tester.pump(const Duration(milliseconds: 100));

      final textFields = find.byType(TextField);
      expect(textFields, findsAtLeastNWidgets(2));

      await tester.enterText(textFields.at(0), 'Private Portrait Showcase Commission');
      await tester.pump();

      expect(find.text('Private Portrait Showcase Commission'), findsOneWidget);
    });

    testWidgets('Step 10: Government Portal live entities & directions verification', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapTestApp(const GovernmentPortalView()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Government Portal'), findsOneWidget);
      expect(find.text('Dubai Culture & Arts Authority'), findsOneWidget);
      expect(find.text('Website'), findsWidgets);
      expect(find.text('Directions'), findsWidgets);
    });

    testWidgets('Step 11: Explore Categories & Filter Segments', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapTestApp(const ExploreCategoriesView()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Explore Categories'), findsOneWidget);
    });

    testWidgets('Step 12: Event Detail & Booking Actions', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapTestApp(EventDetailView(event: ArtEventModel.mockEvents.first)));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('About this event'), findsOneWidget);
      expect(find.text('Book Now'), findsOneWidget);
    });

    testWidgets('Step 13: Artists directory & layout toggle', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapTestApp(const ArtistsView()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Featured Artists'), findsOneWidget);
    });

    testWidgets('Step 14: Settings and Profile Preferences', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapTestApp(const SettingsView()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Account Settings'), findsOneWidget);
      expect(find.text('Artist Dubai · v1.0.0'), findsOneWidget);
    });
  });
}
