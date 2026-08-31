import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/di/injection_container.dart';
import '../../core/services/storage_service.dart';
import '../../features/about_us/presentation/views/about_us_view.dart';
import '../../features/admin/presentation/views/admin_dashboard_view.dart';
import '../../features/artists/domain/models/artist_model.dart';
import '../../features/artists/presentation/views/artist_detail_view.dart';
import '../../features/artists/presentation/views/artists_view.dart';
import '../../features/artists/presentation/views/category_detail_view.dart';
import '../../features/artists/presentation/views/create_artist_profile_view.dart';
import '../../features/artists/presentation/views/create_category_view.dart';
import '../../features/artists/presentation/views/explore_categories_view.dart';
import '../../features/auth/presentation/views/login_view.dart';
import '../../features/auth/presentation/views/register_view.dart';
import '../../features/bookings/presentation/views/book_artist_view.dart';
import '../../features/bookings/presentation/views/bookings_view.dart';
import '../../features/bookings/presentation/views/booking_requests_view.dart';
import '../../features/events/domain/models/art_event_model.dart';
import '../../features/events/presentation/views/create_art_event_view.dart';
import '../../features/events/presentation/views/event_photos_view.dart';
import '../../features/events/presentation/views/events_view.dart';
import '../../features/favorites/presentation/views/favorites_view.dart';
import '../../features/events/presentation/views/my_events_view.dart';
import '../../features/events/presentation/views/events_competition_view.dart';
import '../../features/galleries/presentation/views/galleries_view.dart';
import '../../features/galleries/presentation/views/gallery_registration_view.dart';
import '../../features/government/presentation/views/government_portal_view.dart';
import '../../features/home/presentation/views/home_view.dart';
import '../../features/legal/presentation/views/privacy_policy_view.dart';
import '../../features/legal/presentation/views/terms_view.dart';
import '../../features/onboarding/presentation/views/onboarding_view.dart';
import '../../features/placeholder/presentation/views/coming_soon_view.dart';
import '../../features/profile/presentation/views/profile_view.dart';
import '../../features/settings/presentation/views/settings_view.dart';
import 'route_names.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  AppRouter._();

  static String get initialLocation {
    try {
      final storage = sl<StorageService>();
      final hasCompleted =
          storage.getBool(StorageServiceImpl.keyHasCompletedOnboarding) ??
          false;
      return hasCompleted ? RouteNames.home : RouteNames.onboarding;
    } catch (_) {
      return RouteNames.onboarding;
    }
  }

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: RouteNames.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingView(),
      ),
      GoRoute(
        path: RouteNames.home,
        name: 'home',
        builder: (context, state) => const HomeView(),
      ),
      GoRoute(
        path: RouteNames.aboutUs,
        name: 'aboutUs',
        builder: (context, state) => const AboutUsView(),
      ),
      GoRoute(
        path: RouteNames.artists,
        name: 'artists',
        builder: (context, state) => const ArtistsView(),
      ),
      GoRoute(
        path: RouteNames.artistDetail,
        name: 'artistDetail',
        builder:
            (context, state) =>
                ArtistDetailView(artist: state.extra as ArtistModel?),
      ),
      GoRoute(
        path: RouteNames.government,
        name: 'government',
        builder: (context, state) => const GovernmentPortalView(),
      ),
      GoRoute(
        path: RouteNames.events,
        name: 'events',
        builder: (context, state) => const EventsView(),
      ),
      GoRoute(
        path: RouteNames.myEvents,
        name: 'myEvents',
        builder: (context, state) => const MyEventsView(),
      ),
      GoRoute(
        path: RouteNames.favorites,
        name: 'favorites',
        builder: (context, state) => const FavoritesView(),
      ),
      GoRoute(
        path: RouteNames.eventsCompetition,
        name: 'eventsCompetition',
        builder: (context, state) => const EventsCompetitionView(),
      ),
      GoRoute(
        path: RouteNames.galleries,
        name: 'galleries',
        builder: (context, state) => const GalleriesView(),
      ),
      GoRoute(
        path: RouteNames.eventsPhotos,
        name: 'eventsPhotos',
        builder: (context, state) => const EventPhotosView(),
      ),
      GoRoute(
        path: RouteNames.galleryRegistration,
        name: 'galleryRegistration',
        builder: (context, state) => const GalleryRegistrationView(),
      ),
      GoRoute(
        path: RouteNames.bookings,
        name: 'bookings',
        builder: (context, state) => const BookingsView(),
      ),
      GoRoute(
        path: RouteNames.bookingRequests,
        name: 'bookingRequests',
        builder: (context, state) => const BookingRequestsView(),
      ),
      GoRoute(
        path: RouteNames.bookArtist,
        name: 'bookArtist',
        builder: (context, state) => const BookArtistView(),
      ),
      GoRoute(
        path: RouteNames.createArtEvent,
        name: 'createArtEvent',
        builder:
            (context, state) =>
                CreateArtEventView(event: state.extra as ArtEventModel?),
      ),
      GoRoute(
        path: RouteNames.profile,
        name: 'profile',
        builder: (context, state) => const ProfileView(),
      ),
      GoRoute(
        path: RouteNames.settings,
        name: 'settings',
        builder: (context, state) => const SettingsView(),
      ),
      GoRoute(
        path: RouteNames.login,
        name: 'login',
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: RouteNames.register,
        name: 'register',
        builder: (context, state) => const RegisterView(),
      ),
      GoRoute(
        path: RouteNames.artistRegistration,
        name: 'artistRegistration',
        builder: (context, state) => const CreateArtistProfileView(),
      ),
      GoRoute(
        path: RouteNames.privacyPolicy,
        name: 'privacyPolicy',
        builder: (context, state) => const PrivacyPolicyView(),
      ),
      GoRoute(
        path: RouteNames.termsConditions,
        name: 'termsConditions',
        builder: (context, state) => const TermsView(),
      ),
      GoRoute(
        path: RouteNames.categories,
        name: 'categories',
        builder: (context, state) => const ExploreCategoriesView(),
      ),
      GoRoute(
        path: RouteNames.categoryDetail,
        name: 'categoryDetail',
        builder: (context, state) => const CategoryDetailView(),
      ),
      GoRoute(
        path: RouteNames.createCategory,
        name: 'createCategory',
        builder: (context, state) => const CreateCategoryView(),
      ),
      GoRoute(
        path: RouteNames.adminDashboard,
        name: 'adminDashboard',
        builder: (context, state) => const AdminDashboardView(),
      ),
    ],
    errorBuilder: (context, state) => const ComingSoonView(),
  );
}
