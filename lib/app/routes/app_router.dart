import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
import '../../features/events/presentation/views/event_detail_view.dart';
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
import '../../features/splash/presentation/views/splash_screen_view.dart';
import 'route_names.dart';

class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

  static String get initialLocation => RouteNames.splash;

  static Page<dynamic> _buildFadePage({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
  }) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: child,
        );
      },
    );
  }

  static Page<dynamic> _buildSlidePage({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
  }) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 240),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.05, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: child,
          ),
        );
      },
    );
  }

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: RouteNames.splash,
        name: 'splash',
        pageBuilder: (context, state) => _buildFadePage(
          context: context,
          state: state,
          child: const SplashScreenView(),
        ),
      ),
      GoRoute(
        path: RouteNames.onboarding,
        name: 'onboarding',
        pageBuilder: (context, state) => _buildSlidePage(
          context: context,
          state: state,
          child: const OnboardingView(),
        ),
      ),
      GoRoute(
        path: RouteNames.home,
        name: 'home',
        pageBuilder: (context, state) => _buildFadePage(
          context: context,
          state: state,
          child: const HomeView(),
        ),
      ),
      GoRoute(
        path: RouteNames.aboutUs,
        name: 'aboutUs',
        pageBuilder: (context, state) => _buildSlidePage(
          context: context,
          state: state,
          child: const AboutUsView(),
        ),
      ),
      GoRoute(
        path: RouteNames.artists,
        name: 'artists',
        pageBuilder: (context, state) => _buildFadePage(
          context: context,
          state: state,
          child: const ArtistsView(),
        ),
      ),
      GoRoute(
        path: RouteNames.artistDetail,
        name: 'artistDetail',
        pageBuilder: (context, state) => _buildSlidePage(
          context: context,
          state: state,
          child: ArtistDetailView(artist: state.extra as ArtistModel?),
        ),
      ),
      GoRoute(
        path: RouteNames.government,
        name: 'government',
        pageBuilder: (context, state) => _buildSlidePage(
          context: context,
          state: state,
          child: const GovernmentPortalView(),
        ),
      ),
      GoRoute(
        path: RouteNames.events,
        name: 'events',
        pageBuilder: (context, state) => _buildFadePage(
          context: context,
          state: state,
          child: const EventsCompetitionView(),
        ),
      ),
      GoRoute(
        path: RouteNames.artEvents,
        name: 'artEvents',
        pageBuilder: (context, state) => _buildSlidePage(
          context: context,
          state: state,
          child: const EventsView(),
        ),
      ),
      GoRoute(
        path: RouteNames.myEvents,
        name: 'myEvents',
        pageBuilder: (context, state) => _buildSlidePage(
          context: context,
          state: state,
          child: const MyEventsView(),
        ),
      ),
      GoRoute(
        path: RouteNames.favorites,
        name: 'favorites',
        pageBuilder: (context, state) => _buildSlidePage(
          context: context,
          state: state,
          child: const FavoritesView(),
        ),
      ),
      GoRoute(
        path: RouteNames.eventsCompetition,
        name: 'eventsCompetition',
        pageBuilder: (context, state) => _buildSlidePage(
          context: context,
          state: state,
          child: const EventsCompetitionView(),
        ),
      ),
      GoRoute(
        path: RouteNames.galleries,
        name: 'galleries',
        pageBuilder: (context, state) => _buildSlidePage(
          context: context,
          state: state,
          child: const GalleriesView(),
        ),
      ),
      GoRoute(
        path: RouteNames.eventsPhotos,
        name: 'eventsPhotos',
        pageBuilder: (context, state) => _buildSlidePage(
          context: context,
          state: state,
          child: const EventPhotosView(),
        ),
      ),
      GoRoute(
        path: RouteNames.galleryRegistration,
        name: 'galleryRegistration',
        pageBuilder: (context, state) => _buildSlidePage(
          context: context,
          state: state,
          child: const GalleryRegistrationView(),
        ),
      ),
      GoRoute(
        path: RouteNames.bookings,
        name: 'bookings',
        pageBuilder: (context, state) => _buildSlidePage(
          context: context,
          state: state,
          child: const BookingsView(),
        ),
      ),
      GoRoute(
        path: RouteNames.bookingRequests,
        name: 'bookingRequests',
        pageBuilder: (context, state) => _buildSlidePage(
          context: context,
          state: state,
          child: const BookingRequestsView(),
        ),
      ),
      GoRoute(
        path: RouteNames.bookArtist,
        name: 'bookArtist',
        pageBuilder: (context, state) => _buildSlidePage(
          context: context,
          state: state,
          child: BookArtistView(artistName: state.extra as String?),
        ),
      ),
      GoRoute(
        path: RouteNames.createArtEvent,
        name: 'createArtEvent',
        pageBuilder: (context, state) => _buildSlidePage(
          context: context,
          state: state,
          child: CreateArtEventView(event: state.extra as ArtEventModel?),
        ),
      ),
      GoRoute(
        path: RouteNames.profile,
        name: 'profile',
        pageBuilder: (context, state) => _buildSlidePage(
          context: context,
          state: state,
          child: const ProfileView(),
        ),
      ),
      GoRoute(
        path: RouteNames.settings,
        name: 'settings',
        pageBuilder: (context, state) => _buildSlidePage(
          context: context,
          state: state,
          child: const SettingsView(),
        ),
      ),
      GoRoute(
        path: RouteNames.login,
        name: 'login',
        pageBuilder: (context, state) => _buildSlidePage(
          context: context,
          state: state,
          child: const LoginView(),
        ),
      ),
      GoRoute(
        path: RouteNames.register,
        name: 'register',
        pageBuilder: (context, state) => _buildSlidePage(
          context: context,
          state: state,
          child: const RegisterView(),
        ),
      ),
      GoRoute(
        path: RouteNames.artistRegistration,
        name: 'artistRegistration',
        pageBuilder: (context, state) => _buildSlidePage(
          context: context,
          state: state,
          child: const CreateArtistProfileView(),
        ),
      ),
      GoRoute(
        path: RouteNames.privacyPolicy,
        name: 'privacyPolicy',
        pageBuilder: (context, state) => _buildSlidePage(
          context: context,
          state: state,
          child: const PrivacyPolicyView(),
        ),
      ),
      GoRoute(
        path: RouteNames.termsConditions,
        name: 'termsConditions',
        pageBuilder: (context, state) => _buildSlidePage(
          context: context,
          state: state,
          child: const TermsView(),
        ),
      ),
      GoRoute(
        path: RouteNames.categories,
        name: 'categories',
        pageBuilder: (context, state) => _buildSlidePage(
          context: context,
          state: state,
          child: const ExploreCategoriesView(),
        ),
      ),
      GoRoute(
        path: RouteNames.categoryDetail,
        name: 'categoryDetail',
        pageBuilder: (context, state) => _buildSlidePage(
          context: context,
          state: state,
          child: const CategoryDetailView(),
        ),
      ),
      GoRoute(
        path: RouteNames.createCategory,
        name: 'createCategory',
        pageBuilder: (context, state) => _buildSlidePage(
          context: context,
          state: state,
          child: const CreateCategoryView(),
        ),
      ),
      GoRoute(
        path: RouteNames.adminDashboard,
        name: 'adminDashboard',
        pageBuilder: (context, state) => _buildSlidePage(
          context: context,
          state: state,
          child: const AdminDashboardView(),
        ),
      ),
      GoRoute(
        path: RouteNames.eventDetail,
        name: 'eventDetail',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => _buildSlidePage(
          context: context,
          state: state,
          child: EventDetailView(event: state.extra as ArtEventModel),
        ),
      ),
    ],
    errorBuilder: (context, state) => const ComingSoonView(),
  );
}
