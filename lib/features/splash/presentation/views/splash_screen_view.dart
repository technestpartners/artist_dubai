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
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _footerController.forward();
      }
    });

    // Fallback timer: transitions after 5.5s in case video encounters any issue
    _fallbackTimer = Timer(const Duration(milliseconds: 5500), () {
      if (mounted) _navigateToNext();
    });
  }

  Future<void> _initVideo() async {
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

      controller.addListener(() {
        if (!mounted || _hasNavigated) return;
        final position = controller.value.position;
        final duration = controller.value.duration;
        if (duration > Duration.zero && position >= duration - const Duration(milliseconds: 200)) {
          _navigateToNext();
        }
      });
    } catch (e) {
      debugPrint('Error initializing splash intro video: $e');
      Timer(const Duration(milliseconds: 2500), () {
        if (mounted) _navigateToNext();
      });
    }
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _videoController?.dispose();
    _footerController.dispose();
    super.dispose();
  }

  void _navigateToNext() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    _fallbackTimer?.cancel();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final deepLink = AppRouter.initialDeepLink;
        if (deepLink != null && deepLink.isNotEmpty) {
          context.go(deepLink);
          return;
        }

        final storage = sl<StorageService>();
        final hasCompleted =
            storage.getBool(StorageServiceImpl.keyHasCompletedOnboarding) ?? false;
        if (hasCompleted) {
          context.go(RouteNames.home);
        } else {
          context.go(RouteNames.onboarding);
        }
      } catch (_) {
        context.go(RouteNames.home);
      }
    });
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
            // 1. Full-screen intro2 video
            if (_isVideoInitialized && _videoController != null)
              Positioned.fill(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _videoController!.value.size.width,
                    height: _videoController!.value.size.height,
                    child: VideoPlayer(_videoController!),
                  ),
                ),
              )
            else
              // Fallback dark gradient while video prepares
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF160424),
                        Color(0xFF2C0B47),
                        Color(0xFF10021C),
                      ],
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
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFFFFD54F).withValues(alpha: 0.30),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
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
