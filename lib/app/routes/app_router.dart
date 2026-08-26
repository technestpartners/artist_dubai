import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/di/injection_container.dart';
import '../../core/services/storage_service.dart';
import '../../features/about_us/presentation/views/about_us_view.dart';
import '../../features/artists/presentation/views/artists_view.dart';
import '../../features/auth/presentation/views/login_view.dart';
import '../../features/auth/presentation/views/register_view.dart';
import '../../features/events/presentation/views/events_view.dart';
import '../../features/government/presentation/views/government_portal_view.dart';
import '../../features/home/presentation/views/home_view.dart';
import '../../features/legal/presentation/views/privacy_policy_view.dart';
import '../../features/legal/presentation/views/terms_view.dart';
import '../../features/onboarding/presentation/views/onboarding_view.dart';
import '../../features/placeholder/presentation/views/coming_soon_view.dart';
import 'route_names.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  AppRouter._();

  static String get initialLocation {
    try {
      final storage = sl<StorageService>();
      final hasCompleted = storage.getBool(StorageServiceImpl.keyHasCompletedOnboarding) ?? false;
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
        path: RouteNames.government,
        name: 'government',
        builder: (context, state) => const GovernmentPortalView(),
      ),
      GoRoute(
        path: RouteNames.eventsCompetition,
        name: 'eventsCompetition',
        builder: (context, state) => const EventsView(),
      ),
      GoRoute(
        path: RouteNames.galleries,
        name: 'galleries',
        builder: (context, state) => const ComingSoonView(),
      ),
      GoRoute(
        path: RouteNames.eventsPhotos,
        name: 'eventsPhotos',
        builder: (context, state) => const ComingSoonView(),
      ),
      GoRoute(
        path: RouteNames.galleryRegistration,
        name: 'galleryRegistration',
        builder: (context, state) => const ComingSoonView(),
      ),
      GoRoute(
        path: RouteNames.bookings,
        name: 'bookings',
        builder: (context, state) => const ComingSoonView(),
      ),
      GoRoute(
        path: RouteNames.profile,
        name: 'profile',
        builder: (context, state) => const ComingSoonView(),
      ),
      GoRoute(
        path: RouteNames.settings,
        name: 'settings',
        builder: (context, state) => const ComingSoonView(),
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
        builder: (context, state) => const RegisterView(),
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
    ],
    errorBuilder: (context, state) => const ComingSoonView(),
  );
}
