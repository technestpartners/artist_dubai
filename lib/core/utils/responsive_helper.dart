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

  /// Compact / narrow screen (e.g. Galaxy Z Fold outer cover screen ~320-340dp,
  /// Galaxy Z Flip outer display ~280-340dp).
  bool get isCompact => width < 360.0;

  /// Foldable unfolded inner display (width 560-900dp with near-square aspect ratio 0.7-1.45).
  bool get isFold =>
      width >= 560.0 &&
      width < 900.0 &&
      (height / width >= 0.70 && height / width <= 1.45);

  /// Short height viewport (e.g. tabletop / Flex Mode when half-folded,
  /// landscape orientation, or small flip cover screens).
  bool get isShortScreen => height < 560.0;

  // ── Layout helpers ─────────────────────────────────────────────────────────

  /// Horizontal padding that grows with screen width, while remaining compact on flip/fold outer screens.
  double get horizontalPadding {
    if (isDesktop) return 40.0;
    if (isTablet) return 24.0;
    if (isCompact) return 8.0;
    return (width * 0.04).clamp(12.0, 20.0);
  }

  /// Vertical padding between sections.
  double get verticalPadding {
    if (isDesktop) return 32.0;
    if (isTablet) return 24.0;
    return 16.0;
  }

  /// Spacing between major sections on a page.
  double get sectionSpacing {
    if (isDesktop) return 48.0;
    if (isTablet) return 36.0;
    return 24.0;
  }

  /// Maximum content width — centres content on large screens and foldables.
  double get contentMaxWidth {
    if (isDesktop) return 1100.0;
    if (isTablet) return isFold ? 680.0 : 800.0;
    return double.infinity;
  }

  /// Optimal maximum width for floating bottom navigation bar.
  /// Constrained to 480-540dp on foldables and tablets for ergonomic thumb reach.
  double get bottomNavMaxWidth {
    if (isDesktop) return 560.0;
    if (isTablet) return isFold ? 480.0 : 540.0;
    return double.infinity;
  }

  /// Max width for dialogs/modals.
  double get dialogMaxWidth {
    if (isDesktop) return 560.0;
    if (isTablet) return 480.0;
    return double.infinity;
  }

  /// Number of columns for list grids (Artists, Events).
  int get gridCrossAxisCount {
    if (isDesktop) return 3;
    if (isTablet) return 2;
    return 1;
  }

  /// Number of columns for photo/gallery grids.
  int get photoGridCrossAxisCount {
    if (isDesktop) return 4;
    if (isTablet) return 3;
    return 2;
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

  // ── Sizing helpers ─────────────────────────────────────────────────────────

  /// Standard button height.
  double get buttonHeight {
    if (isDesktop) return 56.0;
    if (isTablet) return 52.0;
    return 48.0;
  }

  /// Card border radius.
  double get cardBorderRadius {
    if (isDesktop) return 16.0;
    if (isTablet) return 14.0;
    return 12.0;
  }

  /// Standard list item / tile height.
  double get listItemHeight {
    if (isDesktop) return 76.0;
    if (isTablet) return 70.0;
    return 64.0;
  }

  /// Avatar / profile image size.
  double get avatarSize {
    if (isDesktop) return 110.0;
    if (isTablet) return 96.0;
    return 84.0;
  }

  /// Onboarding illustration height.
  double get onboardingImageHeight {
    if (isDesktop) return 400.0;
    if (isTablet) return 320.0;
    return (height * 0.38).clamp(200.0, 300.0);
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
    if (isDesktop) return 1.15;
    if (isTablet) return 1.06;
    if (isCompact) return 0.90;
    return 1.0;
  }

  double adaptiveFont(double base) {
    return (base * fontScaleFactor).clamp(base * 0.80, base * 1.35);
  }

  /// Responsive font sizing helper: smoothly scales [base] font size relative to screen size,
  /// ensuring text remains legible and never cuts across small or wide displays.
  double sp(double base) {
    final factor = (width / 390.0).clamp(0.85, 1.25);
    return (base * factor * fontScaleFactor).clamp(base * 0.80, base * 1.35);
  }

  // ── Image heights ──────────────────────────────────────────────────────────

  /// Artist / Event card banner image height.
  double get cardBannerHeight {
    if (isDesktop) return 220.0;
    if (isTablet) return 200.0;
    if (isCompact) return 145.0;
    return 165.0;
  }

  /// Hero / detail banner image height.
  double get heroBannerHeight {
    if (isDesktop) return 340.0;
    if (isTablet) return 280.0;
    if (isCompact) return 180.0;
    return 220.0;
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  double get bottomNavHeight {
    if (isDesktop) return 78.0;
    if (isTablet) return 72.0;
    if (isShortScreen) return 56.0;
    return 68.0;
  }

  double get bottomNavIconSize {
    if (isDesktop) return 30.0;
    if (isTablet) return 28.0;
    if (isCompact) return 22.0;
    return 26.0;
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────

  double get appBarLogoSize {
    if (isDesktop) return 44.0;
    if (isTablet) return 40.0;
    if (isCompact) return 30.0;
    return 36.0;
  }

  double get appBarAvatarSize {
    if (isDesktop) return 36.0;
    if (isTablet) return 33.0;
    if (isCompact) return 26.0;
    return 30.0;
  }
}

// ── ResponsiveWrapper ───────────────────────────────────────────────────────

/// Wraps [child] with centred, max-width content and horizontal padding.
///
/// Drop this around any page body to get consistent responsive margins:
/// ```dart
/// ResponsiveWrapper(child: Column(...))
/// ```
class ResponsiveWrapper extends StatelessWidget {
  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.addHorizontalPadding = true,
    this.addVerticalPadding = false,
  });

  final Widget child;
  final bool addHorizontalPadding;
  final bool addVerticalPadding;

  @override
  Widget build(BuildContext context) {
    final rh = ResponsiveHelper.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: rh.contentMaxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: addHorizontalPadding ? rh.horizontalPadding : 0,
            vertical: addVerticalPadding ? rh.verticalPadding : 0,
          ),
          child: child,
        ),
      ),
    );
  }
}
