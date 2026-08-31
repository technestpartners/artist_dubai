import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/storage_service.dart';

class SplashScreenView extends StatefulWidget {
  const SplashScreenView({super.key});

  @override
  State<SplashScreenView> createState() => _SplashScreenViewState();
}

class _SplashScreenViewState extends State<SplashScreenView>
    with TickerProviderStateMixin {
  late final AnimationController _mainController;
  late final AnimationController _pulseController;
  late final AnimationController _floatController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subtitleFade;
  late final Animation<double> _footerFade;
  late final Animation<Offset> _footerSlide;
  late final Animation<double> _outwardExpansion;

  Timer? _navigationTimer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    // 1. Main Entrance Timeline (1400ms)
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // 2. Pulse / Aura Loop Controller (2000ms)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // 3. Floating Ambient Loop (3000ms)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    // Logo entrance: Elastic scale & fade (0.0 -> 0.6)
    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // Outward expansion of ambient icons/rings (0.1 -> 0.8)
    _outwardExpansion = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.1, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // Title Entrance (0.4 -> 0.8)
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 0.75, curve: Curves.easeIn),
      ),
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // Subtitle Entrance (0.55 -> 0.9)
    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.55, 0.9, curve: Curves.easeIn),
      ),
    );

    // Footer "Hosted by Nizar Fahem" Entrance (0.65 -> 1.0)
    _footerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.65, 1.0, curve: Curves.easeIn),
      ),
    );

    _footerSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.65, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _mainController.forward();

    // Auto navigate after 2.8 seconds
    _navigationTimer = Timer(const Duration(milliseconds: 2800), _navigateToNext);
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _mainController.dispose();
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _navigateToNext() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    try {
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
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: GestureDetector(
        onTap: _navigateToNext,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF5E227A), // Signature Dubai Royal Purple
                Color(0xFF4A154B),
                Color(0xFF380E39),
                Color(0xFF230724),
              ],
              stops: [0.0, 0.4, 0.7, 1.0],
            ),
          ),
          child: SafeArea(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _mainController,
                _pulseController,
                _floatController,
              ]),
              builder: (context, child) {
                final pulse = _pulseController.value;
                final floatOffset = math.sin(_floatController.value * 2 * math.pi) * 5;

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // 1. Ambient Expanding Radiant Rings (representing outward expansion arrows)
                    Positioned(
                      top: size.height * 0.22,
                      child: Opacity(
                        opacity: _logoFade.value * (0.3 + 0.2 * pulse),
                        child: Transform.scale(
                          scale: 0.8 + (_outwardExpansion.value * 0.4) + (pulse * 0.1),
                          child: Container(
                            width: 260,
                            height: 260,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFFFD700).withValues(alpha: 0.25),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6A2777).withValues(alpha: 0.5),
                                  blurRadius: 40,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 2. Outward Expanding Art Particles / Icons (Outward arrows effect)
                    ..._buildExpandingArtElements(size),

                    // 3. Main Center Column (Logo + Title + Subtitle)
                    Column(
                      children: [
                        const Spacer(flex: 2),

                        // Logo Container with Elastic Scale + Floating
                        Transform.translate(
                          offset: Offset(0, floatOffset),
                          child: Transform.scale(
                            scale: _logoScale.value,
                            child: Opacity(
                              opacity: _logoFade.value,
                              child: Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.35),
                                      blurRadius: 24,
                                      offset: const Offset(0, 10),
                                    ),
                                    BoxShadow(
                                      color: const Color(0xFF6A2777).withValues(alpha: 0.6),
                                      blurRadius: 30,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Image.asset(
                                    'assets/images/artist-dubai-logo-26Kex3Rz.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // App Title "ARTIST DUBAI"
                        SlideTransition(
                          position: _titleSlide,
                          child: FadeTransition(
                            opacity: _titleFade,
                            child: const Text(
                              'ARTIST DUBAI',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 2.2,
                                shadows: [
                                  Shadow(
                                    color: Colors.black45,
                                    blurRadius: 12,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 6),

                        // Subtitle "COMMUNITY PLATFORM"
                        FadeTransition(
                          opacity: _subtitleFade,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                                width: 1,
                              ),
                            ),
                            child: const Text(
                              'COMMUNITY PLATFORM',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFFFD700), // Elegant Gold Accent
                                letterSpacing: 3.0,
                              ),
                            ),
                          ),
                        ),

                        const Spacer(flex: 3),

                        // 4. Bottom "Hosted by Nizar Fahem" (Matching Screenshot Annotation)
                        SlideTransition(
                          position: _footerSlide,
                          child: FadeTransition(
                            opacity: _footerFade,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Hosted by',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                const Text(
                                  'Nizar Fahem',
                                  style: TextStyle(
                                    fontSize: 16.5,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.1,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black38,
                                        blurRadius: 6,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // 4 Outward Expanding Accent Indicators (Matching the 4 Red Arrows in the screenshot)
  List<Widget> _buildExpandingArtElements(Size size) {
    final expansion = _outwardExpansion.value;
    final opacity = (_logoFade.value * 0.85).clamp(0.0, 1.0);
    final distance = 110 * expansion;

    final corners = [
      // Top-Left (Palette)
      Offset(-distance, -distance * 0.8),
      // Top-Right (Theater Mask)
      Offset(distance, -distance * 0.8),
      // Bottom-Left (Music / Trumpet)
      Offset(-distance, distance * 0.8),
      // Bottom-Right (Movie Camera)
      Offset(distance, distance * 0.8),
    ];

    final icons = [
      Icons.palette_outlined,
      Icons.theater_comedy_outlined,
      Icons.music_note_outlined,
      Icons.videocam_outlined,
    ];

    return List.generate(4, (index) {
      return Positioned(
        top: size.height * 0.28 + corners[index].dy,
        child: Transform.translate(
          offset: Offset(corners[index].dx, 0),
          child: Opacity(
            opacity: opacity,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
                border: Border.all(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                icons[index],
                size: 18,
                color: const Color(0xFFFFD700).withValues(alpha: 0.8),
              ),
            ),
          ),
        ),
      );
    });
  }
}
