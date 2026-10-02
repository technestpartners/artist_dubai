import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/app_router.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/live_sync_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/data_translator.dart';
import '../../../../core/utils/responsive_helper.dart';

class SplashScreenView extends StatefulWidget {
  const SplashScreenView({super.key});

  @override
  State<SplashScreenView> createState() => _SplashScreenViewState();
}

class _SplashScreenViewState extends State<SplashScreenView>
    with TickerProviderStateMixin {
  late final AnimationController _mainController;
  late final AnimationController _pulseController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoRotate;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subtitleFade;
  late final Animation<Offset> _subtitleSlide;
  late final Animation<double> _footerFade;
  late final Animation<Offset> _footerSlide;

  Timer? _navigationTimer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    // Pre-warm data caches in background during splash animation for instant 0ms loads
    try {
      sl<LiveSyncService>().syncAllSilently(forceRefresh: true);
      sl<LiveSyncService>().startMultiDeviceSync();
    } catch (_) {}

    // Main entrance sequence (2.2 seconds)
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    // Continuous pulse effect for logo glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // 1. Logo Sequence (0ms -> 700ms)
    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.35, curve: Curves.elasticOut),
      ),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.25, curve: Curves.easeIn),
      ),
    );

    _logoRotate = Tween<double>(begin: -0.05, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
      ),
    );

    // 2. Title "ARTIST DUBAI" Reveal (300ms -> 900ms)
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.25, 0.55, curve: Curves.easeIn),
      ),
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.25, 0.55, curve: Curves.easeOutCubic),
      ),
    );

    // 3. Subtitle "COMMUNITY PLATFORM" (500ms -> 1100ms)
    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 0.7, curve: Curves.easeIn),
      ),
    );

    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    // 4. Footer "Hosted by Nizar Fahem" (700ms -> 1400ms)
    _footerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.55, 0.85, curve: Curves.easeIn),
      ),
    );

    _footerSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.55, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _mainController.forward();

    // Auto transition after exactly 4 seconds
    _navigationTimer = Timer(const Duration(milliseconds: 4000), () {
      if (mounted) _navigateToNext();
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _mainController.stop();
    _mainController.dispose();
    _pulseController.stop();
    _pulseController.dispose();
    super.dispose();
  }

  void _navigateToNext() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    _navigationTimer?.cancel();

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
    final rh = ResponsiveHelper.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF160424),
      body: GestureDetector(
        onTap: _navigateToNext,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Luxury Ambient Gradient Background
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.0, -0.2),
                    radius: 1.15,
                    colors: const [
                      Color(0xFF2C0B47),
                      Color(0xFF160424),
                      Color(0xFF0D0216),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),

            // 2. Foreground Content in SafeArea
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final logoSize = rh.isDesktop
                      ? 300.0
                      : rh.isTablet
                          ? 270.0
                          : (constraints.maxHeight * 0.34).clamp(210.0, 260.0);

                  return Column(
                    children: [
                      const Spacer(flex: 3),

                      // 1. Animated Central Logo with Swirling Neon Aura (GIF)
                      AnimatedBuilder(
                        animation: Listenable.merge([_mainController, _pulseController]),
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _logoRotate.value,
                            child: Transform.scale(
                              scale: _logoScale.value,
                              child: Opacity(
                                opacity: _logoFade.value,
                                child: SizedBox(
                                  width: logoSize,
                                  height: logoSize,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Central Brand Medallion Logo (rendered below aura)
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFD03BF7).withValues(alpha: 0.45),
                                              blurRadius: 24,
                                              spreadRadius: 4,
                                            ),
                                            BoxShadow(
                                              color: const Color(0xFFFFB300).withValues(alpha: 0.30),
                                              blurRadius: 36,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: Image.asset(
                                          'assets/images/header_logo.png',
                                          width: logoSize * 0.58,
                                          height: logoSize * 0.58,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                      // Swirling Neon Energy Ring (GIF) with BlendMode.screen
                                      // Black background becomes invisible; only neon glow shows
                                      Image.asset(
                                        'assets/images/splash_bg.gif',
                                        width: logoSize,
                                        height: logoSize,
                                        fit: BoxFit.contain,
                                        color: Colors.white,
                                        colorBlendMode: BlendMode.screen,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 28),

                      // 2. Staggered Animated Typography
                      SlideTransition(
                        position: _titleSlide,
                        child: FadeTransition(
                          opacity: _titleFade,
                          child: Text(
                            'ARTIST DUBAI',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: rh.adaptiveFont(27),
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 4.5,
                              shadows: const [
                                Shadow(
                                  color: Color(0xFFD03BF7),
                                  blurRadius: 18,
                                  offset: Offset(0, 0),
                                ),
                                Shadow(
                                  color: Color(0xFFFFB300),
                                  blurRadius: 28,
                                  offset: Offset(0, 2),
                                ),
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      SlideTransition(
                        position: _subtitleSlide,
                        child: FadeTransition(
                          opacity: _subtitleFade,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 28,
                                height: 1.5,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.transparent, Color(0xFFFFD54F)],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'COMMUNITY PLATFORM',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: rh.adaptiveFont(12),
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFF3E5F5),
                                    letterSpacing: 4.0,
                                    shadows: [
                                      Shadow(
                                        color: const Color(0xFFFFD54F)
                                            .withValues(alpha: 0.5),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                width: 28,
                                height: 1.5,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFFFFD54F), Colors.transparent],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(flex: 3),

                      const SizedBox(height: 24),

                      // 4. Animated "Hosted by Nizar Fahem" Luxury Footer
                      SlideTransition(
                        position: _footerSlide,
                        child: FadeTransition(
                          opacity: _footerFade,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xFFFFD54F).withValues(alpha: 0.28),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
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
                                    fontSize: 11.5,
                                    color: Colors.white.withValues(alpha: 0.72),
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Nizar Fahem',
                                  style: TextStyle(
                                    fontSize: 16.5,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.4,
                                    shadows: [
                                      Shadow(
                                        color: const Color(0xFFFFD54F)
                                            .withValues(alpha: 0.45),
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

                      const SizedBox(height: 28),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
