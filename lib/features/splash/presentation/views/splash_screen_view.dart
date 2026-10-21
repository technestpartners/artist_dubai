import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/app_router.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/live_sync_service.dart';
import '../../../../core/services/storage_service.dart';

/// Consistent alias matching the `<feature>_view` naming convention.
typedef SplashView = SplashScreenView;

class SplashScreenView extends StatefulWidget {
  const SplashScreenView({super.key});

  static const String splashImagePath = 'assets/images/splash_screen_art.png';
  static const String splashTallPath = 'assets/images/splash_screen_art_tall.png';
  static const String splashModernPath = 'assets/images/splash_screen_art_modern.png';
  static const String splashStandardPath = 'assets/images/splash_screen_art_standard.png';
  static const String splashTabletPath = 'assets/images/splash_screen_art_tablet.png';
  static const String splashWidePath = 'assets/images/splash_screen_art_wide.png';
  static const String splashFoldInnerPath = 'assets/images/splash_screen_art_fold_inner.png';
  static const String splashFoldCoverPath = 'assets/images/splash_screen_art_fold_cover.png';

  /// Resolves the optimal splash artwork tailored to the device screen aspect ratio,
  /// including foldable unfolded main displays and flip/fold ultra-tall cover screens.
  static String resolveSplashAsset(Size size) {
    if (size.height <= 0 || size.width <= 0) return splashImagePath;
    final ratio = size.width / size.height;

    if (ratio >= 1.25) {
      // Landscape / Desktop / Web screens (16:9, 16:10, ultrawide)
      return splashWidePath;
    } else if (ratio >= 0.78) {
      // Foldable Inner / Unfolded Main Displays (Square / near-square 1:1, 4:3.55, 6:5)
      // e.g. Samsung Galaxy Z Fold 4/5/6 (2176x1812), Pixel Fold, OnePlus Open
      return splashFoldInnerPath;
    } else if (ratio >= 0.60) {
      // Tablets, iPads, Foldables in tablet portrait mode (3:4, 10:16)
      return splashTabletPath;
    } else if (ratio >= 0.52) {
      // Standard classic smartphones (9:16 = 0.5625)
      return splashStandardPath;
    } else if (ratio >= 0.455) {
      // Modern flagship smartphones (9:19.5 = 0.4615, iPhone 12/13/14/15/16, Pixel 7/8)
      return splashModernPath;
    } else if (ratio >= 0.42) {
      // Ultra-tall modern smartphones (9:20 = 0.45, Galaxy S21-S24)
      return splashTallPath;
    } else {
      // Ultra-narrow Foldable Cover Screens (Galaxy Z Fold 22:9 / 23.1:9, ratio ~0.39-0.41)
      // and Flip phones unfolded (Galaxy Z Flip 5/6, Razr 22:9 = 0.409)
      return splashFoldCoverPath;
    }
  }

  @override
  State<SplashScreenView> createState() => _SplashScreenViewState();
}

class _SplashScreenViewState extends State<SplashScreenView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  Timer? _navigationTimer;
  bool _hasNavigated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-cache the optimal splash variant for seamless instant rendering
    final asset = SplashScreenView.resolveSplashAsset(MediaQuery.sizeOf(context));
    precacheImage(AssetImage(asset), context).catchError((_) {});
    precacheImage(const AssetImage(SplashScreenView.splashImagePath), context).catchError((_) {});
  }

  @override
  void initState() {
    super.initState();

    // 1. Setup smooth entrance animation matching brand aesthetics
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _scaleAnimation = Tween<double>(begin: 0.97, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animController.forward();

    // 2. Pre-warm data caches in background during splash after first frame is drawn
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        sl<LiveSyncService>().syncAllSilently(forceRefresh: true);
      } catch (_) {}
    });

    // 3. Splash dwell timer: auto-proceed after 2 seconds (or tap anywhere to skip immediately)
    _navigationTimer = Timer(const Duration(milliseconds: 2100), () {
      _navigateToNext();
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _navigateToNext() {
    if (_hasNavigated) return;
    _hasNavigated = true;
    _navigationTimer?.cancel();

    void performNavigation() {
      try {
        final deepLink = AppRouter.initialDeepLink;
        // Check for genuine external deep link (avoiding splash / root / empty)
        if (deepLink != null &&
            deepLink.isNotEmpty &&
            deepLink != RouteNames.splash &&
            deepLink != RouteNames.root &&
            deepLink != '/' &&
            deepLink != '/splash' &&
            !deepLink.startsWith('/artist_dubai')) {
          if (mounted) {
            context.go(deepLink);
          } else {
            AppRouter.router.go(deepLink);
          }
          return;
        }

        final storage = sl<StorageService>();
        final hasCompleted =
            storage.getBool(StorageServiceImpl.keyHasCompletedOnboarding) ??
            false;
        final target = hasCompleted ? RouteNames.home : RouteNames.onboarding;

        if (mounted) {
          context.go(target);
        } else {
          AppRouter.router.go(target);
        }
      } catch (e) {
        debugPrint('Splash redirect navigation error: $e');
        try {
          if (mounted) {
            context.go(RouteNames.home);
          } else {
            AppRouter.router.go(RouteNames.home);
          }
        } catch (_) {
          AppRouter.router.go(RouteNames.home);
        }
      }
    }

    try {
      performNavigation();
    } catch (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        performNavigation();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final splashAsset = SplashScreenView.resolveSplashAsset(MediaQuery.sizeOf(context));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF160230),
        body: GestureDetector(
          onTap: _navigateToNext,
          behavior: HitTestBehavior.opaque,
          child: SizedBox.expand(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Image.asset(
                  splashAsset,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.high,
                  gaplessPlayback: true,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      SplashScreenView.splashImagePath,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      alignment: Alignment.center,
                      filterQuality: FilterQuality.high,
                      gaplessPlayback: true,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
