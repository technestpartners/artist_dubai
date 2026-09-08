import 'package:flutter/material.dart';

/// Screen-size breakpoints used throughout the app.
enum ScreenClass { mobile, tablet, desktop }

/// A centralized responsive utility.
///
/// Usage:
/// ```dart
/// final h = ResponsiveHelper.of(context);
/// double pad = h.horizontalPadding;
/// bool isWide = h.isTablet;
/// double scaled = h.scale(56); // scales relative to 390dp baseline
/// ```
class ResponsiveHelper {
  ResponsiveHelper._({
    required this.width,
    required this.height,
    required this.screenClass,
  });

  final double width;
  final double height;
  final ScreenClass screenClass;

  // ── Factory ────────────────────────────────────────────────────────────────

  static ResponsiveHelper of(BuildContext context) {
    final mq = MediaQuery.sizeOf(context);
    return ResponsiveHelper._(
      width: mq.width,
      height: mq.height,
      screenClass: _classify(mq.width),
    );
  }

  static ScreenClass _classify(double w) {
    if (w >= 1200) return ScreenClass.desktop;
    if (w >= 600) return ScreenClass.tablet;
    return ScreenClass.mobile;
  }

  // ── Convenience booleans ───────────────────────────────────────────────────

  bool get isMobile => screenClass == ScreenClass.mobile;
  bool get isTablet => screenClass == ScreenClass.tablet;
  bool get isDesktop => screenClass == ScreenClass.desktop;
  bool get isWide => !isMobile; // tablet OR desktop

  // ── Layout helpers ─────────────────────────────────────────────────────────

  /// Horizontal padding that grows with screen width.
  double get horizontalPadding {
    if (isDesktop) return 40.0;
    if (isTablet) return 24.0;
    return (width * 0.04).clamp(12.0, 20.0);
  }

  /// Maximum content width — centres content on large screens.
  double get contentMaxWidth {
    if (isDesktop) return 1100.0;
    if (isTablet) return 800.0;
    return double.infinity;
  }

  /// Number of columns for list grids (Artists, Events).
  int get gridCrossAxisCount {
    if (isDesktop) return 3;
    if (isTablet) return 2;
    return 1;
  }

  /// Number of columns for the home menu card grid.
  int get menuGridCrossAxisCount {
    if (isDesktop) return 4;
    if (isTablet) return 4;
    return 2; // 4 rows × 2 cols on mobile
  }

  /// Number of card rows in home menu grid.
  int get menuGridRowCount {
    if (isWide) return 2;
    return 4;
  }

  // ── Scaling helpers ────────────────────────────────────────────────────────

  /// Linearly scales [value] from the 390dp baseline.
  double scale(double value) {
    return (value * width / 390.0).clamp(value * 0.75, value * 2.0);
  }

  /// Clamps [value] between [min] and [max] — convenience wrapper.
  double clamp(double value, double min, double max) => value.clamp(min, max);

  // ── Typography ─────────────────────────────────────────────────────────────

  double get fontScaleFactor {
    if (isDesktop) return 1.18;
    if (isTablet) return 1.08;
    return 1.0;
  }

  double adaptiveFont(double base) {
    return (base * fontScaleFactor).clamp(base * 0.85, base * 1.5);
  }

  // ── Image heights ──────────────────────────────────────────────────────────

  /// Artist / Event card banner image height.
  double get cardBannerHeight {
    if (isDesktop) return 220.0;
    if (isTablet) return 200.0;
    return 165.0;
  }

  /// Hero / detail banner image height.
  double get heroBannerHeight {
    if (isDesktop) return 340.0;
    if (isTablet) return 280.0;
    return 220.0;
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  double get bottomNavHeight {
    if (isDesktop) return 78.0;
    if (isTablet) return 72.0;
    return 68.0;
  }

  double get bottomNavIconSize {
    if (isDesktop) return 30.0;
    if (isTablet) return 28.0;
    return 26.0;
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────

  double get appBarLogoSize {
    if (isDesktop) return 44.0;
    if (isTablet) return 40.0;
    return 36.0;
  }

  double get appBarAvatarSize {
    if (isDesktop) return 36.0;
    if (isTablet) return 33.0;
    return 30.0;
  }
}
