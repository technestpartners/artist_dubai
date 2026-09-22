import 'dart:async';
import 'package:flutter/material.dart';
import 'package:artist_dubai/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../app/routes/route_names.dart';
import '../di/injection_container.dart';
import '../services/live_sync_service.dart';
import '../services/storage_service.dart';
import '../utils/responsive_helper.dart';

class AppBottomNavBar extends StatefulWidget {
  const AppBottomNavBar({super.key, this.currentIndex = 0});

  final int currentIndex;

  @override
  State<AppBottomNavBar> createState() => _AppBottomNavBarState();
}

class _AppBottomNavBarState extends State<AppBottomNavBar> {
  StreamSubscription<bool>? _authSub;

  bool get _isLoggedIn {
    try {
      return sl<StorageService>().getBool('is_logged_in') ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _authSub = sl<LiveSyncService>().authStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  void _onTabSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(RouteNames.home);
        break;
      case 1:
        context.go(RouteNames.artists);
        break;
      case 2:
        context.go(RouteNames.events);
        break;
      case 3:
        context.go(RouteNames.login);
        break;
    }
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData selectedIcon,
    required IconData unselectedIcon,
    required String label,
    required VoidCallback onTap,
  }) {
    final rh = ResponsiveHelper.of(context);
    final isSelected = widget.currentIndex == index;
    final color = isSelected ? Colors.white : Colors.white.withValues(alpha: 0.72);
    final isCompact = rh.isCompact;

    return Expanded(
      child: Center(
        child: Tooltip(
          message: label,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              splashColor: Colors.white.withValues(alpha: 0.15),
              highlightColor: Colors.transparent,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                constraints: BoxConstraints(
                  minWidth: isCompact ? 36 : 50,
                  maxWidth: isCompact ? 54 : 68,
                  minHeight: rh.isShortScreen ? 40 : 46,
                  maxHeight: rh.isShortScreen ? 44 : 48,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 3 : 8,
                  vertical: isCompact || rh.isShortScreen ? 2 : 3,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.20)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: isSelected
                      ? Border.all(
                          color: Colors.white.withValues(alpha: 0.28),
                          width: 1.0,
                        )
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isSelected ? selectedIcon : unselectedIcon,
                      color: color,
                      size: isCompact ? 18 : 20,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: color,
                        fontSize: isCompact ? 9.0 : 10.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        letterSpacing: isCompact ? -0.1 : 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rh = ResponsiveHelper.of(context);
    final loggedIn = _isLoggedIn;
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      top: false,
      child: Container(
        height: rh.isShortScreen ? 72 : 90,
        padding: EdgeInsets.only(
          left: rh.isCompact ? 8.0 : rh.horizontalPadding,
          right: rh.isCompact ? 8.0 : rh.horizontalPadding,
          bottom: rh.isShortScreen ? 6.0 : 20.0,
          top: 4.0,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: rh.bottomNavMaxWidth,
            ),
            child: Container(
              height: rh.isShortScreen ? 54 : 64,
              padding: EdgeInsets.symmetric(
                horizontal: rh.isCompact ? 8 : 16,
                vertical: rh.isShortScreen ? 3 : 6,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF3E0A58),
                    Color(0xFF240436),
                  ],
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.26),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.50),
                    offset: const Offset(0, 8),
                    blurRadius: 24,
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: const Color(0xFF7B1FA2).withValues(alpha: 0.25),
                    offset: const Offset(0, 2),
                    blurRadius: 10,
                    spreadRadius: -1,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildNavItem(
                    context: context,
                    index: 0,
                    selectedIcon: Icons.home_rounded,
                    unselectedIcon: Icons.home_outlined,
                    label: l10n.home,
                    onTap: () => _onTabSelected(context, 0),
                  ),
                  _buildNavItem(
                    context: context,
                    index: 1,
                    selectedIcon: Icons.people_rounded,
                    unselectedIcon: Icons.people_outline_rounded,
                    label: l10n.artists,
                    onTap: () => _onTabSelected(context, 1),
                  ),
                  _buildNavItem(
                    context: context,
                    index: 2,
                    selectedIcon: Icons.calendar_month_rounded,
                    unselectedIcon: Icons.calendar_today_outlined,
                    label: l10n.events,
                    onTap: () => _onTabSelected(context, 2),
                  ),
                  if (!loggedIn)
                    _buildNavItem(
                      context: context,
                      index: 3,
                      selectedIcon: Icons.login_rounded,
                      unselectedIcon: Icons.login,
                      label: l10n.signIn,
                      onTap: () => _onTabSelected(context, 3),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
