import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:artist_dubai/core/di/injection_container.dart';
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
      'user_email': 'admin@artistdubai.com',
      'user_name': 'Super Admin',
      'is_admin': true,
      'has_completed_onboarding': true,
    });
    await sl.reset();
    await initDependencyInjection();
  });

  Widget buildTestHost(Widget child) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: child,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
    );
  }

  final testScreens = <String, Size>{
    'Compact Mobile (360x640)': const Size(360, 640),
    'Standard Mobile (390x844)': const Size(390, 844),
    'Tablet Portrait (768x1024)': const Size(768, 1024),
    'Desktop Web (1440x900)': const Size(1440, 900),
  };

  group('Universal Multi-Device Responsive Layout Audit', () {
    for (final entry in testScreens.entries) {
      final screenName = entry.key;
      final screenSize = entry.value;

      group('Screen Profile: $screenName', () {
        testWidgets('1. Splash Screen & Brand Intro ($screenName)', (tester) async {
          tester.view.physicalSize = screenSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(buildTestHost(const SplashScreenView()));
          await tester.pump(const Duration(milliseconds: 100));

          expect(tester.takeException(), isNull);
          expect(find.byType(SplashScreenView), findsOneWidget);
        });

        testWidgets('2. Onboarding Screen Carousel ($screenName)', (tester) async {
          tester.view.physicalSize = screenSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(buildTestHost(const OnboardingView()));
          await tester.pump(const Duration(milliseconds: 100));

          expect(tester.takeException(), isNull);
          expect(find.byType(OnboardingView), findsOneWidget);
        });

        testWidgets('3. Home Dashboard 8-Card Matrix ($screenName)', (tester) async {
          tester.view.physicalSize = screenSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(buildTestHost(const HomeView()));
          await tester.pump(const Duration(milliseconds: 100));

          expect(tester.takeException(), isNull);
          expect(find.byType(HomeView), findsOneWidget);
        });

        testWidgets('4. Artists Directory & Filter Bar ($screenName)', (tester) async {
          tester.view.physicalSize = screenSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(buildTestHost(const ArtistsView()));
          await tester.pump(const Duration(milliseconds: 100));

          expect(tester.takeException(), isNull);
          expect(find.byType(ArtistsView), findsOneWidget);
        });

        testWidgets('5. Artist Detail Profile & Portfolio Grid ($screenName)', (tester) async {
          tester.view.physicalSize = screenSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(buildTestHost(ArtistDetailView(artist: ArtistModel.mockArtists.first)));
          await tester.pump(const Duration(milliseconds: 100));

          expect(tester.takeException(), isNull);
          expect(find.byType(ArtistDetailView), findsOneWidget);
        });

        testWidgets('6. Create Artist Profile Multi-Step Form ($screenName)', (tester) async {
          tester.view.physicalSize = screenSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(buildTestHost(const CreateArtistProfileView()));
          await tester.pump(const Duration(milliseconds: 100));

          expect(tester.takeException(), isNull);
          expect(find.byType(CreateArtistProfileView), findsOneWidget);
        });

        testWidgets('7. Explore Categories 2-Column Grid ($screenName)', (tester) async {
          tester.view.physicalSize = screenSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(buildTestHost(const ExploreCategoriesView()));
          await tester.pump(const Duration(milliseconds: 100));

          expect(tester.takeException(), isNull);
          expect(find.byType(ExploreCategoriesView), findsOneWidget);
        });

        testWidgets('8. Category Detail Tab Switcher ($screenName)', (tester) async {
          tester.view.physicalSize = screenSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(buildTestHost(const CategoryDetailView()));
          await tester.pump(const Duration(milliseconds: 100));

          expect(tester.takeException(), isNull);
          expect(find.byType(CategoryDetailView), findsOneWidget);
        });

        testWidgets('9. Create Category Form ($screenName)', (tester) async {
          tester.view.physicalSize = screenSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(buildTestHost(const CreateCategoryView()));
          await tester.pump(const Duration(milliseconds: 100));

          expect(tester.takeException(), isNull);
          expect(find.byType(CreateCategoryView), findsOneWidget);
        });

        testWidgets('10. Art Events Directory ($screenName)', (tester) async {
          tester.view.physicalSize = screenSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(buildTestHost(const EventsView()));
          await tester.pump(const Duration(milliseconds: 100));

          expect(tester.takeException(), isNull);
          expect(find.byType(EventsView), findsOneWidget);
        });

        testWidgets('11. Event Detail View ($screenName)', (tester) async {
          tester.view.physicalSize = screenSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(buildTestHost(EventDetailView(event: ArtEventModel.mockEvents.first)));
          await tester.pump(const Duration(milliseconds: 100));

          expect(tester.takeException(), isNull);
          expect(find.byType(EventDetailView), findsOneWidget);
        });

        testWidgets('12. Create Art Event View ($screenName)', (tester) async {
          tester.view.physicalSize = screenSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(buildTestHost(const CreateArtEventView()));
          await tester.pump(const Duration(milliseconds: 100));

          expect(tester.takeException(), isNull);
          expect(find.byType(CreateArtEventView), findsOneWidget);
        });

        testWidgets('13. My Hosted Events View ($screenName)', (tester) async {
          tester.view.physicalSize = screenSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(buildTestHost(const MyEventsView()));
          await tester.pump(const Duration(milliseconds: 100));

          expect(tester.takeException(), isNull);
          expect(find.byType(MyEventsView), findsOneWidget);
        });

        testWidgets('14. Events Competition View ($screenName)', (tester) async {
          tester.view.physicalSize = screenSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(buildTestHost(const EventsCompetitionView()));
          await tester.pump(const Duration(milliseconds: 100));

          expect(tester.takeException(), isNull);
          expect(find.byType(EventsCompetitionView), findsOneWidget);
        });

        testWidgets('15. Event Photo Galleries View ($screenName)', (tester) async {
          tester.view.physicalSize = screenSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(buildTestHost(const EventPhotosView()));
          await tester.pump(const Duration(milliseconds: 100));

          expect(tester.takeException(), isNull);
          expect(find.byType(EventPhotosView), findsOneWidget);
        });

        testWidgets('16. Galleries Art Center Directory ($screenName)', (tester) async {
          tester.view.physicalSize = screenSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(buildTestHost(const GalleriesView()));
          await tester.pump(const Duration(milliseconds: 100));

          expect(tester.takeException(), isNull);
          expect(find.byType(GalleriesView), findsOneWidget);
        });

        testWidgets('17. Gallery Registration View ($screenName)', (tester) async {
          tester.view.physicalSize = screenSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(buildTestHost(const GalleryRegistrationView()));
          await tester.pump(const Duration(milliseconds: 100));

          expect(tester.takeException(), isNull);
          expect(find.byType(GalleryRegistrationView), findsOneWidget);
        });

        testWidgets('18. Government Portal View ($screenName)', (tester) async {
          tester.view.physicalSize = screenSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(buildTestHost(const GovernmentPortalView()));
          await tester.pump(const Duration(milliseconds: 100));

          expect(tester.takeException(), isNull);
          expect(find.byType(GovernmentPortalView), findsOneWidget);
        });

        testWidgets('19. Book Artist Form View ($screenName)', (tester) async {
          tester.view.physicalSize = screenSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(buildTestHost(const BookArtistView(artistName: 'Fatima Al Qasimi')));
          await tester.pump(const Duration(milliseconds: 100));

          expect(tester.takeException(), isNull);
          expect(find.byType(BookArtistView), findsOneWidget);
        });

        testWidgets('20. My Bookings & Tickets View ($screenName)', (tester) async {
          tester.view.physicalSize = screenSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(buildTestHost(const BookingsView()));
          await tester.pump(const Duration(milliseconds: 100));

          expect(tester.takeException(), isNull);
          expect(find.byType(BookingsView), findsOneWidget);
        });

        testWidgets('21. Booking Requests & Attendees View ($screenName)', (tester) async {
          tester.view.physicalSize = screenSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(buildTestHost(const BookingRequestsView()));
          await tester.pump(const Duration(milliseconds: 100));

          expect(tester.takeException(), isNull);
          expect(find.byType(BookingRequestsView), findsOneWidget);
        });

        testWidgets('22. Favorites & Bookmarks Catalog ($screenName)', (tester) async {
          tester.view.physicalSize = screenSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(buildTestHost(const FavoritesView()));
          await tester.pump(const Duration(milliseconds: 100));

          expect(tester.takeException(), isNull);
          expect(find.byType(FavoritesView), findsOneWidget);
        });

        testWidgets('23. User Profile Screen ($screenName)', (tester) async {
          tester.view.physicalSize = screenSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(buildTestHost(const ProfileView()));
          await tester.pump(const Duration(milliseconds: 100));

          expect(tester.takeException(), isNull);
          expect(find.byType(ProfileView), findsOneWidget);
        });

        testWidgets('24. Account Settings View ($screenName)', (tester) async {
          tester.view.physicalSize = screenSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(buildTestHost(const SettingsView()));
          await tester.pump(const Duration(milliseconds: 100));

          expect(tester.takeException(), isNull);
          expect(find.byType(SettingsView), findsOneWidget);
        });

        testWidgets('25. User Login View ($screenName)', (tester) async {
          tester.view.physicalSize = screenSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(buildTestHost(const LoginView()));
          await tester.pump(const Duration(milliseconds: 100));

          expect(tester.takeException(), isNull);
          expect(find.byType(LoginView), findsOneWidget);
        });

        testWidgets('26. User Register View ($screenName)', (tester) async {
          tester.view.physicalSize = screenSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(buildTestHost(const RegisterView()));
          await tester.pump(const Duration(milliseconds: 100));

          expect(tester.takeException(), isNull);
          expect(find.byType(RegisterView), findsOneWidget);
        });

        testWidgets('27. Admin Dashboard KPI & Management View ($screenName)', (tester) async {
          tester.view.physicalSize = screenSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(buildTestHost(const AdminDashboardView()));
          await tester.pump(const Duration(milliseconds: 100));

          expect(tester.takeException(), isNull);
          expect(find.byType(AdminDashboardView), findsOneWidget);
        });

        testWidgets('28. About Us View ($screenName)', (tester) async {
          tester.view.physicalSize = screenSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(buildTestHost(const AboutUsView()));
          await tester.pump(const Duration(milliseconds: 100));

          expect(tester.takeException(), isNull);
          expect(find.byType(AboutUsView), findsOneWidget);
        });

        testWidgets('29. Privacy Policy View ($screenName)', (tester) async {
          tester.view.physicalSize = screenSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(buildTestHost(const PrivacyPolicyView()));
          await tester.pump(const Duration(milliseconds: 100));

          expect(tester.takeException(), isNull);
          expect(find.byType(PrivacyPolicyView), findsOneWidget);
        });

        testWidgets('30. Terms & Conditions View ($screenName)', (tester) async {
          tester.view.physicalSize = screenSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(buildTestHost(const TermsView()));
          await tester.pump(const Duration(milliseconds: 100));

          expect(tester.takeException(), isNull);
          expect(find.byType(TermsView), findsOneWidget);
        });

        testWidgets('31. Coming Soon / Fallback View ($screenName)', (tester) async {
          tester.view.physicalSize = screenSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(buildTestHost(const ComingSoonView()));
          await tester.pump(const Duration(milliseconds: 100));

          expect(tester.takeException(), isNull);
          expect(find.byType(ComingSoonView), findsOneWidget);
        });
      });
    }
  });
}
