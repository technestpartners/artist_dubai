import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/about_us/presentation/views/about_us_view.dart';
import '../../features/admin/presentation/views/admin_dashboard_view.dart';
import '../../features/admin/presentation/views/admin_recycle_bin_view.dart';
import '../../features/artists/domain/models/artist_model.dart';
import '../../features/artists/presentation/views/artist_detail_view.dart';
import '../../features/artists/presentation/views/artists_view.dart';
import '../../features/artists/presentation/views/category_detail_view.dart';
import '../../features/artists/presentation/views/create_artist_profile_view.dart';
import '../../features/artists/presentation/views/create_category_view.dart';
import '../../features/artists/presentation/views/explore_categories_view.dart';
import '../../features/auth/presentation/views/login_view.dart';
import '../../features/auth/presentation/views/register_view.dart';
import '../../features/events/domain/models/art_event_model.dart';
import '../../features/events/presentation/views/create_art_event_view.dart';
import '../../features/events/presentation/views/event_detail_view.dart';
import '../../features/events/presentation/views/event_photos_view.dart';
import '../../features/events/presentation/views/events_view.dart';
import '../../features/favorites/presentation/views/favorites_view.dart';
import '../../features/events/presentation/views/my_events_view.dart';
import '../../features/galleries/presentation/views/galleries_view.dart';
import '../../features/galleries/presentation/views/gallery_registration_view.dart';
import '../../features/government/presentation/views/government_portal_view.dart';
import '../../features/home/presentation/views/home_view.dart';
import '../../features/legal/presentation/views/privacy_policy_view.dart';
import '../../features/legal/presentation/views/terms_view.dart';
import '../../features/onboarding/presentation/views/onboarding_view.dart';
import '../../features/payment/presentation/views/plan_payment_view.dart';
import '../../features/profile/presentation/views/profile_view.dart';
import '../../features/settings/presentation/views/settings_view.dart';
import '../../features/splash/presentation/views/splash_screen_view.dart';
import 'route_names.dart';

class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

  static String? parseDeepLink(Uri uri) {
    // 1. Direct query parameter inspection (e.g. ?artist=18, ?event=5, ?artwork=10)
    final artistId = uri.queryParameters['artist'] ?? uri.queryParameters['artist_id'];
    final artworkId = uri.queryParameters['artwork'] ?? uri.queryParameters['artwork_id'];
    if (artistId != null && artistId.isNotEmpty) {
      if (artworkId != null && artworkId.isNotEmpty) {
        return '/artist/$artistId?artwork=$artworkId';
      }
      return '/artist/$artistId';
    }
    if (artworkId != null && artworkId.isNotEmpty) {
      final aId = uri.queryParameters['artist_id'] ?? uri.queryParameters['artist'];
      if (aId != null && aId.isNotEmpty) {
        return '/artist/$aId?artwork=$artworkId';
      }
      return '/artworks?id=$artworkId';
    }
    final eventId = uri.queryParameters['event'] ?? uri.queryParameters['event_id'];
    if (eventId != null && eventId.isNotEmpty) {
      return '/event-detail?id=$eventId';
    }
    final galleryId = uri.queryParameters['gallery'] ?? uri.queryParameters['gallery_id'];
    if (galleryId != null && galleryId.isNotEmpty) {
      return '/galleries?id=$galleryId';
    }
    final profileId = uri.queryParameters['profile'] ?? uri.queryParameters['user_id'];
    if (profileId != null && profileId.isNotEmpty) {
      return RouteNames.profile;
    }

    // 2. Hash fragment inspection (e.g. #/artist/18)
    var frag = uri.fragment;
    if (frag.isNotEmpty) {
      if (!frag.startsWith('/')) frag = '/$frag';
      if (frag != '/' && frag != '/splash' && frag != '/home' && frag != '/onboarding') {
        return frag;
      }
    }

    // 3. Custom scheme inspection (e.g. artistdubai://artist/18 or artistdubai://event/55)
    if (uri.scheme == 'artistdubai') {
      final host = uri.host;
      final p = uri.path;
      final query = uri.hasQuery ? '?${uri.query}' : '';
      if (host.isNotEmpty) {
        if (host == 'artist' || host == 'artists') {
          if (p.isNotEmpty && p != '/') {
            return '/artist${p.startsWith('/') ? p : '/$p'}$query';
          }
          return RouteNames.artists;
        }
        if (host == 'event' || host == 'events') {
          final id = p.replaceAll('/', '').trim();
          if (id.isNotEmpty) {
            return '/event-detail?id=$id';
          }
          return RouteNames.events;
        }
        if (host == 'gallery' || host == 'galleries') {
          final id = p.replaceAll('/', '').trim();
          if (id.isNotEmpty) {
            return '/galleries?id=$id';
          }
          return RouteNames.galleries;
        }
        if (host == 'artwork' || host == 'artworks') {
          final id = p.replaceAll('/', '').trim();
          if (id.isNotEmpty) {
            return '/artworks?id=$id';
          }
          return '/artworks';
        }
        if (host == 'profile') {
          return RouteNames.profile;
        }
        return '/$host$p$query';
      }
    }

    // 4. Standard path inspection (e.g. /artist/18)
    final path = uri.path;
    if (path.isNotEmpty && path != '/' && !path.endsWith('index.html')) {
      if (path.contains('share.php') || path.contains('share')) {
        return null;
      }
      final query = uri.hasQuery ? '?${uri.query}' : '';
      return '$path$query';
    }

    return null;
  }

  static String? get initialDeepLink {
    try {
      if (kIsWeb) {
        return parseDeepLink(Uri.base);
      } else {
        final defaultRoute = WidgetsBinding.instance.platformDispatcher.defaultRouteName;
        if (defaultRoute.isNotEmpty && defaultRoute != '/' && defaultRoute != '/splash') {
          final uri = Uri.tryParse(defaultRoute);
          if (uri != null) {
            return parseDeepLink(uri);
          }
        }
      }
    } catch (_) {}
    return null;
  }

  static String get initialLocation => initialDeepLink ?? RouteNames.splash;

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
    redirect: (context, state) {
      final parsed = parseDeepLink(state.uri);
      if (parsed != null && parsed != state.matchedLocation && parsed != state.uri.toString()) {
        return parsed;
      }
      return null;
    },
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
          child: ArtistDetailView(
            artist: state.extra as ArtistModel?,
            artistId: state.pathParameters['id'],
            initialArtworkId: state.uri.queryParameters['artwork'] ?? state.uri.queryParameters['artwork_id'],
          ),
        ),
      ),
      GoRoute(
        path: '/artists/:id',
        redirect: (context, state) => '/artist/${state.pathParameters['id']}',
      ),
      GoRoute(
        path: '/artist',
        redirect: (context, state) {
          final id = state.uri.queryParameters['id'] ?? state.uri.queryParameters['artist'];
          if (id != null && id.isNotEmpty) {
            return '/artist/$id';
          }
          return RouteNames.artists;
        },
      ),
      GoRoute(
        path: '/event/:id',
        redirect: (context, state) => '/event-detail?id=${state.pathParameters['id']}',
      ),
      GoRoute(
        path: '/events/:id',
        redirect: (context, state) => '/event-detail?id=${state.pathParameters['id']}',
      ),
      GoRoute(
        path: '/artworks',
        redirect: (context, state) {
          final artistId = state.uri.queryParameters['artist_id'] ?? state.uri.queryParameters['artist'];
          final artworkId = state.uri.queryParameters['id'] ?? state.uri.queryParameters['artwork'];
          if (artistId != null && artistId.isNotEmpty) {
            if (artworkId != null && artworkId.isNotEmpty) {
              return '/artist/$artistId?artwork=$artworkId';
            }
            return '/artist/$artistId';
          }
          return RouteNames.artists;
        },
      ),
      GoRoute(
        path: '/artwork/:id',
        redirect: (context, state) => '/artworks?id=${state.pathParameters['id']}',
      ),
      GoRoute(
        path: '/artworks/:id',
        redirect: (context, state) => '/artworks?id=${state.pathParameters['id']}',
      ),
      GoRoute(
        path: '/api.php',
        redirect: (context, state) => parseDeepLink(state.uri) ?? RouteNames.home,
      ),
      GoRoute(
        path: '/api/api.php',
        redirect: (context, state) => parseDeepLink(state.uri) ?? RouteNames.home,
      ),
      GoRoute(
        path: '/share.php',
        redirect: (context, state) => parseDeepLink(state.uri) ?? RouteNames.home,
      ),
      GoRoute(
        path: '/api/share.php',
        redirect: (context, state) => parseDeepLink(state.uri) ?? RouteNames.home,
      ),
      GoRoute(
        path: '/share',
        redirect: (context, state) => parseDeepLink(state.uri) ?? RouteNames.home,
      ),
      GoRoute(
        path: '/api/share',
        redirect: (context, state) => parseDeepLink(state.uri) ?? RouteNames.home,
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
          child: const EventsView(initialTabIndex: 1),
        ),
      ),
      GoRoute(
        path: RouteNames.galleries,
        name: 'galleries',
        pageBuilder: (context, state) => _buildSlidePage(
          context: context,
          state: state,
          child: GalleriesView(
            initialGalleryId: state.uri.queryParameters['id'] ?? state.uri.queryParameters['gallery'],
          ),
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
        path: RouteNames.createArtEvent,
        name: 'createArtEvent',
        pageBuilder: (context, state) {
          ArtEventModel? event;
          bool isCalendar = false;
          bool fromAdmin = false;

          if (state.extra is ArtEventModel) {
            event = state.extra as ArtEventModel;
          } else if (state.extra is Map) {
            final map = state.extra as Map;
            if (map['event'] is ArtEventModel) {
              event = map['event'] as ArtEventModel;
            }
            if (map['isCalendar'] == true) {
              isCalendar = true;
            }
            if (map['fromAdmin'] == true) {
              fromAdmin = true;
            }
          }
          if (state.uri.queryParameters['mode'] == 'calendar') {
            isCalendar = true;
          }
          if (state.uri.queryParameters['fromAdmin'] == 'true' || state.uri.queryParameters['admin'] == '1') {
            fromAdmin = true;
          }

          return _buildSlidePage(
            context: context,
            state: state,
            child: CreateArtEventView(
              event: event,
              isCalendar: isCalendar,
              fromAdmin: fromAdmin,
              showBottomBar: !fromAdmin && !isCalendar,
            ),
          );
        },
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
        pageBuilder: (context, state) {
          final role = state.extra is String
              ? state.extra as String
              : (state.uri.queryParameters['role'] ?? 'user');
          return _buildSlidePage(
            context: context,
            state: state,
            child: RegisterView(initialRole: role),
          );
        },
      ),
      GoRoute(
        path: RouteNames.artistRegistration,
        name: 'artistRegistration',
        pageBuilder: (context, state) {
          bool fromAdmin = false;
          bool isEditing = false;
          ArtistModel? artist;
          String? artistId;

          if (state.extra is Map) {
            final map = state.extra as Map;
            if (map['fromAdmin'] == true) fromAdmin = true;
            if (map['isEditing'] == true) isEditing = true;
            if (map['artist'] is ArtistModel) artist = map['artist'] as ArtistModel;
            if (map['artistId'] != null) artistId = map['artistId'].toString();
          }
          if (state.uri.queryParameters['fromAdmin'] == 'true') {
            fromAdmin = true;
          }
          if (state.uri.queryParameters['isEditing'] == 'true') {
            isEditing = true;
          }
          if (state.uri.queryParameters['artistId'] != null) {
            artistId = state.uri.queryParameters['artistId'];
          }

          return _buildSlidePage(
            context: context,
            state: state,
            child: CreateArtistProfileView(
              fromAdmin: fromAdmin,
              isEditing: isEditing,
              artist: artist,
              artistId: artistId,
            ),
          );
        },
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
        path: RouteNames.adminRecycleBin,
        name: 'adminRecycleBin',
        pageBuilder: (context, state) => _buildSlidePage(
          context: context,
          state: state,
          child: const AdminRecycleBinView(),
        ),
      ),
      GoRoute(
        path: RouteNames.eventDetail,
        name: 'eventDetail',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          ArtEventModel? event;
          String? eventId = state.uri.queryParameters['id'];
          if (state.extra is ArtEventModel) {
            event = state.extra as ArtEventModel;
          } else if (state.extra is Map) {
            final map = state.extra as Map;
            if (map['event'] is ArtEventModel) {
              event = map['event'] as ArtEventModel;
            } else if (map['event'] is Map<String, dynamic>) {
              event = ArtEventModel.fromJson(map['event'] as Map<String, dynamic>);
            }
            if (map['id'] != null) {
              eventId = map['id'].toString();
            }
          } else if (state.extra is String) {
            eventId = state.extra as String;
          }
          if ((eventId == null || eventId.isEmpty) && event != null) {
            eventId = event.id;
          }
          return _buildSlidePage(
            context: context,
            state: state,
            child: EventDetailView(event: event, eventId: eventId),
          );
        },
      ),
      GoRoute(
        path: RouteNames.planPayment,
        name: 'planPayment',
        pageBuilder: (context, state) {
          final extra = state.extra is Map<String, dynamic>
              ? state.extra as Map<String, dynamic>
              : (state.extra is Map ? Map<String, dynamic>.from(state.extra as Map) : <String, dynamic>{});
          return _buildSlidePage(
            context: context,
            state: state,
            child: PlanPaymentView(args: extra),
          );
        },
      ),
    ],
    errorBuilder: (context, state) {
      final target = parseDeepLink(state.uri);
      if (target != null) {
        if (target.startsWith('/artist/')) {
          final afterArtist = target.substring('/artist/'.length);
          final artistId = afterArtist.split('?').first;
          final uri = Uri.tryParse(target) ?? state.uri;
          final artworkId = uri.queryParameters['artwork'] ?? uri.queryParameters['artwork_id'];
          return ArtistDetailView(
            artistId: artistId.isNotEmpty ? artistId : null,
            initialArtworkId: artworkId,
          );
        }
        if (target.startsWith('/event-detail')) {
          final uri = Uri.tryParse(target) ?? state.uri;
          final eventId = uri.queryParameters['id'] ?? uri.queryParameters['event'] ?? uri.queryParameters['event_id'];
          return EventDetailView(eventId: eventId);
        }
        if (target.startsWith('/galleries')) {
          final uri = Uri.tryParse(target) ?? state.uri;
          final galleryId = uri.queryParameters['id'] ?? uri.queryParameters['gallery'] ?? uri.queryParameters['gallery_id'];
          return GalleriesView(initialGalleryId: galleryId);
        }
        if (target.startsWith('/artworks')) {
          final uri = Uri.tryParse(target) ?? state.uri;
          final artworkId = uri.queryParameters['id'] ?? uri.queryParameters['artwork'];
          final artistId = uri.queryParameters['artist_id'] ?? uri.queryParameters['artist'];
          if (artistId != null && artistId.isNotEmpty) {
            return ArtistDetailView(artistId: artistId, initialArtworkId: artworkId);
          }
          return const ArtistsView();
        }
        if (target == RouteNames.profile) {
          return const ProfileView();
        }
        if (target == RouteNames.events) {
          return const EventsView();
        }
        if (target == RouteNames.artists) {
          return const ArtistsView();
        }
      }
      return const HomeView();
    },
  );
}
