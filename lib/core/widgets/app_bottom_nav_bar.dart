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
  // Deep rich royal purple for floating capsule
  static const Color _barBg = Color(0xFF52116E);
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
    final isSelected = widget.currentIndex == index;
    final color = isSelected ? Colors.white : Colors.white.withValues(alpha: 0.75);

    return Expanded(
      child: Center(
        child: Tooltip(
          message: label,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              splashColor: Colors.white.withValues(alpha: 0.15),
              highlightColor: Colors.transparent,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.20)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isSelected ? selectedIcon : unselectedIcon,
                      color: color,
                      size: 21,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        letterSpacing: 0.1,
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

    return SafeArea(
      top: false,
      child: Container(
        height: 88,
        padding: const EdgeInsets.only(
          left: 20.0,
          right: 20.0,
          bottom: 18.0,
          top: 4.0,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: rh.isWide ? 500.0 : double.infinity,
            ),
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _barBg,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.38),
                    offset: const Offset(0, 6),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: const Color(0xFF6B1C9B).withValues(alpha: 0.25),
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
                    label: 'Home',
                    onTap: () => _onTabSelected(context, 0),
                  ),
                  _buildNavItem(
                    context: context,
                    index: 1,
                    selectedIcon: Icons.people_rounded,
                    unselectedIcon: Icons.people_outline_rounded,
                    label: 'Artists',
                    onTap: () => _onTabSelected(context, 1),
                  ),
                  _buildNavItem(
                    context: context,
                    index: 2,
                    selectedIcon: Icons.calendar_month_rounded,
                    unselectedIcon: Icons.calendar_today_outlined,
                    label: 'Events',
                    onTap: () => _onTabSelected(context, 2),
                  ),
                  if (!loggedIn)
                    _buildNavItem(
                      context: context,
                      index: 3,
                      selectedIcon: Icons.login_rounded,
                      unselectedIcon: Icons.login,
                      label: 'Login',
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
