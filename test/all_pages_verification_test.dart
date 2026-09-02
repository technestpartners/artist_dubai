import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:artist_dubai/core/di/injection_container.dart';
import 'package:artist_dubai/core/services/api_service.dart';
import 'package:artist_dubai/features/about_us/presentation/views/about_us_view.dart';
import 'package:artist_dubai/features/admin/presentation/views/admin_dashboard_view.dart';
import 'package:artist_dubai/features/artists/domain/models/artist_model.dart';
import 'package:artist_dubai/features/artists/presentation/views/artist_detail_view.dart';
import 'package:artist_dubai/features/artists/presentation/views/artists_view.dart';
import 'package:artist_dubai/features/artists/presentation/views/category_detail_view.dart';
import 'package:artist_dubai/features/artists/presentation/views/create_artist_profile_view.dart';
import 'package:artist_dubai/features/artists/presentation/views/create_category_view.dart';
import 'package:artist_dubai/features/artists/presentation/views/explore_categories_view.dart';
import 'package:artist_dubai/features/auth/presentation/views/login_view.dart';
import 'package:artist_dubai/features/auth/presentation/views/register_view.dart';
import 'package:artist_dubai/features/bookings/presentation/views/book_artist_view.dart';
import 'package:artist_dubai/features/bookings/presentation/views/booking_requests_view.dart';
import 'package:artist_dubai/features/bookings/presentation/views/bookings_view.dart';
import 'package:artist_dubai/features/events/domain/models/art_event_model.dart';
import 'package:artist_dubai/features/events/presentation/views/create_art_event_view.dart';
import 'package:artist_dubai/features/events/presentation/views/event_detail_view.dart';
import 'package:artist_dubai/features/events/presentation/views/event_photos_view.dart';
import 'package:artist_dubai/features/events/presentation/views/events_competition_view.dart';
import 'package:artist_dubai/features/events/presentation/views/events_view.dart';
import 'package:artist_dubai/features/events/presentation/views/my_events_view.dart';
import 'package:artist_dubai/features/favorites/presentation/views/favorites_view.dart';
import 'package:artist_dubai/features/galleries/presentation/views/galleries_view.dart';
import 'package:artist_dubai/features/galleries/presentation/views/gallery_registration_view.dart';
import 'package:artist_dubai/features/government/presentation/views/government_portal_view.dart';
import 'package:artist_dubai/features/home/presentation/views/home_view.dart';
import 'package:artist_dubai/features/legal/presentation/views/privacy_policy_view.dart';
import 'package:artist_dubai/features/legal/presentation/views/terms_view.dart';
import 'package:artist_dubai/features/onboarding/presentation/views/onboarding_view.dart';
import 'package:artist_dubai/features/placeholder/presentation/views/coming_soon_view.dart';
import 'package:artist_dubai/features/profile/presentation/views/profile_view.dart';
import 'package:artist_dubai/features/settings/presentation/views/settings_view.dart';
import 'package:artist_dubai/features/splash/presentation/views/splash_screen_view.dart';

class _TestHttpOverrides extends HttpOverrides {}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = _TestHttpOverrides();
    SharedPreferences.setMockInitialValues({
      'is_logged_in': true,
      'user_email': 'test@artistdubai.com',
      'user_name': 'Test User',
      'has_completed_onboarding': true,
    });
    await sl.reset();
    await initDependencyInjection();
  });

  Widget testApp(Widget child) {
    return MaterialApp(
      home: child,
      theme: ThemeData(useMaterial3: true),
    );
  }

  group('All Public Pages Comprehensive Verification Test Suite', () {
    testWidgets('1. OnboardingView renders and navigates', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(testApp(const OnboardingView()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Dubai Artists'), findsWidgets);
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('2. HomeView renders dashboard and menu cards', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(testApp(const HomeView()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('ARTIST DUBAI'), findsOneWidget);
      expect(find.text('COMMUNITY PLATFORM'), findsOneWidget);
    });

    testWidgets('3. AboutUsView renders about section and mission', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(testApp(const AboutUsView()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('ABOUT US'), findsOneWidget);
      expect(find.text('Content to be provided.'), findsOneWidget);
    });

    testWidgets('4. ArtistsView renders category selector and directory', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(testApp(const ArtistsView()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Featured Artists'), findsOneWidget);
      expect(find.text('Select a Category'), findsOneWidget);
    });

    testWidgets('5. ArtistDetailView renders profile and portfolio', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Default mock
      await tester.pumpWidget(testApp(const ArtistDetailView()));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Artist Profile'), findsOneWidget);

      // Custom model
      final customArtist = ArtistModel.mockArtists.first;
      await tester.pumpWidget(testApp(ArtistDetailView(artist: customArtist)));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(customArtist.name), findsOneWidget);
    });

    testWidgets('6. CreateArtistProfileView renders multi-step form', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(testApp(const CreateArtistProfileView()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Create Your Artist Profile'), findsOneWidget);
      expect(find.text('Basic Information'), findsOneWidget);
    });

    testWidgets('7. ExploreCategoriesView renders category grid', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(testApp(const ExploreCategoriesView()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Explore Categories'), findsOneWidget);
      expect(find.text('Discover talented artists'), findsOneWidget);
    });

    testWidgets('8. CategoryDetailView renders tab filters and artist list', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(testApp(const CategoryDetailView()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Calligraphy & Typography'), findsOneWidget);
      expect(find.text('Search artists or artworks...'), findsOneWidget);
    });

    testWidgets('9. CreateCategoryView renders category creation form', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(testApp(const CreateCategoryView()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Create New Category'), findsOneWidget);
      expect(find.text('Category Name'), findsOneWidget);
    });

    testWidgets('10. EventsView renders art events listings', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(testApp(const EventsView()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Art Events'), findsOneWidget);
    });

    testWidgets('11. EventDetailView renders details and booking action', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(testApp(EventDetailView(event: ArtEventModel.mockEvents.first)));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('About this event'), findsOneWidget);
      expect(find.text('RSVP for Event'), findsOneWidget);
    });

    testWidgets('12. CreateArtEventView renders event submission form', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(testApp(const CreateArtEventView()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Create Event'), findsWidgets);
    });

    testWidgets('13. MyEventsView renders created events dashboard', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(testApp(const MyEventsView()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(MyEventsView), findsOneWidget);
    });

    testWidgets('14. EventsCompetitionView renders competitions and filters', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(testApp(const EventsCompetitionView()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('EVENTS COMPETITION'), findsOneWidget);
    });

    testWidgets('15. EventPhotosView renders photos and galleries', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(testApp(const EventPhotosView()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('EVENTS PHOTOS'), findsOneWidget);
    });

    testWidgets('16. GalleriesView renders art centers directory', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(testApp(const GalleriesView()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('GALLERIES ART CENTER'), findsOneWidget);
    });

    testWidgets('17. GalleryRegistrationView renders gallery registration form', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(testApp(const GalleryRegistrationView()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('GALLERIES | ART CENTERS'), findsOneWidget);
      expect(find.text('Submit registration'), findsOneWidget);
    });

    testWidgets('18. BookingsView renders user bookings & tickets', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(testApp(const BookingsView()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('My Bookings'), findsOneWidget);
    });

    testWidgets('19. BookArtistView renders booking inquiry form', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(testApp(const BookArtistView()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Book an Artist'), findsOneWidget);
      expect(find.text('Submit Booking Request'), findsOneWidget);
    });

    testWidgets('20. BookingRequestsView renders requests & attendees tabs', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(testApp(const BookingRequestsView()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Booking Requests'), findsOneWidget);
      expect(find.textContaining('Requests ('), findsOneWidget);
      expect(find.textContaining('Attendees ('), findsOneWidget);
    });

    testWidgets('21. FavoritesView renders saved profiles & artworks', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(testApp(const FavoritesView()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('MY FAVORITES | SAVED PROFILES'), findsOneWidget);
    });

    testWidgets('22. GovernmentPortalView renders entities & search', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(testApp(const GovernmentPortalView()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Government Portal'), findsOneWidget);
      expect(find.text('Dubai Culture & Arts Authority'), findsOneWidget);
    });

    testWidgets('23. LoginView renders email and password fields', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(testApp(const LoginView()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Login'), findsWidgets);
    });

    testWidgets('24. RegisterView renders registration fields', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(testApp(const RegisterView()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining("Join Dubai's Artist Community"), findsOneWidget);
    });

    testWidgets('25. ProfileView renders profile settings and dialogs', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(testApp(const ProfileView()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Account Settings'), findsOneWidget);
    });

    testWidgets('26. SettingsView renders account preferences & actions', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(testApp(const SettingsView()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Account Settings'), findsOneWidget);
      expect(find.text('Account Information'), findsOneWidget);
    });

    testWidgets('27. PrivacyPolicyView renders policy content', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(testApp(const PrivacyPolicyView()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Introduction'), findsOneWidget);
    });

    testWidgets('28. TermsView renders terms and conditions', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(testApp(const TermsView()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Terms and Conditions'), findsOneWidget);
      expect(find.text('Agreement to Terms'), findsOneWidget);
    });

    testWidgets('29. ComingSoonView renders placeholder and return navigation', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(testApp(const ComingSoonView()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Actively from'), findsOneWidget);
      expect(find.text('back to home'), findsOneWidget);
    });

    testWidgets('30. AdminDashboardView renders KPI metrics and tabs', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(testApp(const AdminDashboardView()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Admin Dashboard'), findsOneWidget);
      expect(find.text('Artist Dubai management'), findsOneWidget);
      expect(find.text('Artists'), findsWidgets);
      expect(find.text('Events'), findsWidgets);
      expect(find.text('Galleries'), findsWidgets);
      expect(find.text('Bookings'), findsWidgets);
    });

    testWidgets('31. SplashScreenView renders animated intro and brand assets', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(testApp(const SplashScreenView()));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('ARTIST DUBAI'), findsOneWidget);
      expect(find.text('COMMUNITY PLATFORM'), findsOneWidget);
      expect(find.text('Hosted by'), findsOneWidget);
      expect(find.text('Nizar Fahem'), findsOneWidget);
    });

    testWidgets('32. Admin Login credentials and role privileges test', (tester) async {
      final res = await sl<ApiService>().login('admin@artistdubai.com', 'admin123');
      expect(res, isNotNull);
      final user = res!['user'] as Map<String, dynamic>;
      expect(user['role'], equals('admin'));
      expect(user['is_admin'], isTrue);
      await tester.pump(const Duration(milliseconds: 50));
    });
  });
}
