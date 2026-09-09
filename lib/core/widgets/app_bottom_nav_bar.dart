import 'dart:async';
import 'package:flutter/material.dart';
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
  static const Color _barBg = Color(0xFF531666);
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
    required String tooltip,
    required double iconSize,
    required double minConstraint,
  }) {
    final isSelected = widget.currentIndex == index;
    final color = isSelected ? Colors.white : Colors.white.withValues(alpha: 0.80);

    return Tooltip(
      message: tooltip,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(minWidth: minConstraint, minHeight: minConstraint),
        icon: Icon(
          isSelected ? selectedIcon : unselectedIcon,
          color: color,
          size: iconSize,
        ),
        onPressed: () => _onTabSelected(context, index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rh = ResponsiveHelper.of(context);
    final barHeight = rh.bottomNavHeight;
    final iconSize = rh.bottomNavIconSize;
    final eventsIconSize = rh.isWide ? iconSize - 1 : 24.0;
    final minConstraint = rh.isWide ? 60.0 : 54.0;
    final loggedIn = _isLoggedIn;

    return Container(
      decoration: BoxDecoration(
        color: _barBg,
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.18),
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: barHeight,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: rh.contentMaxWidth),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildNavItem(
                    context: context,
                    index: 0,
                    selectedIcon: Icons.home_rounded,
                    unselectedIcon: Icons.home_outlined,
                    tooltip: 'Home',
                    iconSize: iconSize,
                    minConstraint: minConstraint,
                  ),
                  _buildNavItem(
                    context: context,
                    index: 1,
                    selectedIcon: Icons.people_rounded,
                    unselectedIcon: Icons.people_outline_rounded,
                    tooltip: 'Artists',
                    iconSize: iconSize,
                    minConstraint: minConstraint,
                  ),
                  _buildNavItem(
                    context: context,
                    index: 2,
                    selectedIcon: Icons.calendar_month_rounded,
                    unselectedIcon: Icons.calendar_today_outlined,
                    tooltip: 'Events',
                    iconSize: eventsIconSize,
                    minConstraint: minConstraint,
                  ),
                  if (!loggedIn)
                    _buildNavItem(
                      context: context,
                      index: 3,
                      selectedIcon: Icons.login_rounded,
                      unselectedIcon: Icons.login,
                      tooltip: 'Login / Sign Up',
                      iconSize: iconSize,
                      minConstraint: minConstraint,
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
