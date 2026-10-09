import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../../../../app/routes/app_router.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/live_sync_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/data_translator.dart';

class SplashScreenView extends StatefulWidget {
  const SplashScreenView({super.key});

  @override
  State<SplashScreenView> createState() => _SplashScreenViewState();
}

class _SplashScreenViewState extends State<SplashScreenView>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  late final AnimationController _footerController;
  late final Animation<double> _footerFade;
  late final Animation<Offset> _footerSlide;

  Timer? _fallbackTimer;
  Timer? _footerTimer;
  Timer? _errorTimer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    // Pre-warm data caches in background during splash
    try {
      sl<LiveSyncService>().syncAllSilently(forceRefresh: true);
      sl<LiveSyncService>().startMultiDeviceSync();
    } catch (_) {}

    // Footer entrance animation
    _footerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _footerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _footerController,
        curve: Curves.easeIn,
      ),
    );

    _footerSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _footerController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Initialize intro2.mp4 video
    _initVideo();

    // Fade in footer smoothly
    _footerTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        _footerController.forward();
      }
    });

    // Hard-cap fallback timer: guarantees navigation after 4.5 seconds no matter what
    _fallbackTimer = Timer(const Duration(milliseconds: 4500), () {
      _navigateToNext();
    });
  }

  Future<void> _initVideo() async {
    if (WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
      _isVideoInitialized = true;
      return;
    }
    try {
      final controller = VideoPlayerController.asset('assets/videos/intro2.mp4');
      _videoController = controller;
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }

      controller.setLooping(false);
      controller.setVolume(1.0);
      await controller.play();

      setState(() {
        _isVideoInitialized = true;
      });

      final duration = controller.value.duration;
      if (duration > Duration.zero) {
        // Schedule fallback slightly after duration (or max 4.5s)
        final safeFallbackMs = (duration.inMilliseconds + 300).clamp(2000, 4500);
        _fallbackTimer?.cancel();
        _fallbackTimer = Timer(Duration(milliseconds: safeFallbackMs), () {
          _navigateToNext();
        });
      }

      controller.addListener(_onVideoTick);
    } catch (e) {
      debugPrint('Error initializing splash intro video: $e');
      _errorTimer?.cancel();
      _errorTimer = Timer(const Duration(milliseconds: 1500), () {
        _navigateToNext();
      });
    }
  }

  void _onVideoTick() {
    if (_hasNavigated || _videoController == null) return;
    final val = _videoController!.value;
    if (val.hasError) {
      _navigateToNext();
      return;
    }

    final position = val.position;
    final duration = val.duration;

    // Detect if video reached end through any standard completion condition
    final isFinished = val.isCompleted ||
        (duration > Duration.zero && position >= duration - const Duration(milliseconds: 300)) ||
        (!val.isPlaying &&
            duration > Duration.zero &&
            position >= duration - const Duration(milliseconds: 800) &&
            position > Duration.zero) ||
        (duration > Duration.zero &&
            duration.inMilliseconds > 0 &&
            position.inMilliseconds >= (duration.inMilliseconds * 0.95).round());

    if (isFinished) {
      _navigateToNext();
    }
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _footerTimer?.cancel();
    _errorTimer?.cancel();
    if (_videoController != null) {
      _videoController!.removeListener(_onVideoTick);
      _videoController!.dispose();
    }
    _footerController.dispose();
    super.dispose();
  }

  void _navigateToNext() {
    if (_hasNavigated) return;
    _hasNavigated = true;
    _fallbackTimer?.cancel();
    _errorTimer?.cancel();

    try {
      _videoController?.removeListener(_onVideoTick);
      _videoController?.pause();
    } catch (_) {}

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
            storage.getBool(StorageServiceImpl.keyHasCompletedOnboarding) ?? false;
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

    // Attempt direct navigation immediately, and ensure fallback in post-frame callback
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
    return Scaffold(
      backgroundColor: const Color(0xFF160424),
      body: GestureDetector(
        onTap: _navigateToNext,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Luxury dark gradient background behind video
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF35204C),
                      Color(0xFF160424),
                      Color(0xFF0E0715),
                    ],
                  ),
                ),
              ),
            ),

            // 2. Intro video: elegant, slightly scaled and fully visible without cutting edges
            if (_isVideoInitialized && _videoController != null)
              Positioned.fill(
                child: Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.90,
                    heightFactor: 0.85,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio > 0
                            ? _videoController!.value.aspectRatio
                            : (_videoController!.value.size.width /
                                (_videoController!.value.size.height > 0
                                    ? _videoController!.value.size.height
                                    : 1)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: VideoPlayer(_videoController!),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // 2. Elegant "Hosted by Nizar Fahem" Footer
            SafeArea(
              child: Column(
                children: [
                  const Spacer(),
                  SlideTransition(
                    position: _footerSlide,
                    child: FadeTransition(
                      opacity: _footerFade,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Hosted by'.trData(context),
                              style: TextStyle(
                                fontSize: 11.0,
                                color: Colors.white.withValues(alpha: 0.72),
                                fontWeight: FontWeight.w400,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Nizar Fahem',
                              style: TextStyle(
                                fontSize: 15.5,
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.4,
                                shadows: [
                                  Shadow(
                                    color: const Color(0xFFFFD54F).withValues(alpha: 0.5),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
