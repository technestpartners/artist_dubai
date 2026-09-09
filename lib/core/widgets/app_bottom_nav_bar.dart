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
  static const Color _barBg = Color(0xFF5E127E);
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
    try {
      _authSub = sl<LiveSyncService>().authStream.listen((_) {
        if (mounted) setState(() {});
      });
    } catch (_) {}
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
        context.push(RouteNames.login);
        break;
    }
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    final isSelected = widget.currentIndex == index;
    final color = isSelected ? Colors.white : Colors.white.withValues(alpha: 0.72);

    return Tooltip(
      message: tooltip ?? label,
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
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.20)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
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
      child: SizedBox(
        height: 76,
        child: Padding(
          padding: const EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            bottom: 8.0,
            top: 4.0,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: rh.isWide ? 520.0 : double.infinity,
              ),
              child: Container(
                height: 64,
              decoration: BoxDecoration(
                color: _barBg,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    offset: const Offset(0, 4),
                    blurRadius: 16,
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
                    icon: widget.currentIndex == 0
                        ? Icons.home_rounded
                        : Icons.home_outlined,
                    label: 'Home',
                    onTap: () => _onTabSelected(context, 0),
                  ),
                  _buildNavItem(
                    context: context,
                    index: 1,
                    icon: widget.currentIndex == 1
                        ? Icons.people_rounded
                        : Icons.people_outline_rounded,
                    label: 'Artists',
                    onTap: () => _onTabSelected(context, 1),
                  ),
                  _buildNavItem(
                    context: context,
                    index: 2,
                    icon: widget.currentIndex == 2
                        ? Icons.calendar_month_rounded
                        : Icons.calendar_today_outlined,
                    label: 'Events',
                    onTap: () => _onTabSelected(context, 2),
                  ),
                  if (!loggedIn)
                    _buildNavItem(
                      context: context,
                      index: 3,
                      icon: widget.currentIndex == 3
                          ? Icons.login_rounded
                          : Icons.login,
                      label: 'Login',
                      tooltip: 'Log In / Sign Up',
                      onTap: () => _onTabSelected(context, 3),
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
}
