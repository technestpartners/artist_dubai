import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/routes/app_router.dart';
import '../../app/routes/route_names.dart';
import '../../core/di/injection_container.dart';
import '../../core/services/storage_service.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({super.key, this.currentIndex = 0});

  final int currentIndex;

  void _onTabSelected(BuildContext context, int index) {
    // 1. Pop any open dialogs, bottom sheets, or imperatively pushed routes back to root
    try {
      AppRouter.rootNavigatorKey.currentState?.popUntil((route) => route.isFirst);
    } catch (_) {
      try {
        while (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      } catch (_) {}
    }

    final isLoggedIn = sl<StorageService>().getBool('is_logged_in') ?? false;

    switch (index) {
      case 0:
        context.go(RouteNames.home);
        break;
      case 1:
        context.go(RouteNames.artists);
        break;
      case 2:
        if (!isLoggedIn) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          context.push(RouteNames.login);
        } else {
          context.go(RouteNames.events);
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Color(0xFF6A2777),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: _buildNavItem(
                context: context,
                index: 0,
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                tooltip: 'Home',
              ),
            ),
            Expanded(
              child: _buildNavItem(
                context: context,
                index: 1,
                icon: Icons.people_outline,
                activeIcon: Icons.people,
                tooltip: 'Artists',
              ),
            ),
            Expanded(
              child: _buildNavItem(
                context: context,
                index: 2,
                icon: Icons.calendar_today_outlined,
                activeIcon: Icons.calendar_today,
                tooltip: 'Events',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String tooltip,
  }) {
    final isSelected = currentIndex == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onTabSelected(context, index),
        child: Center(
          child: Tooltip(
            message: tooltip,
            child: Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? Colors.white : const Color(0xFFE2D6F5),
              size: index == 2 ? 24 : 28,
            ),
          ),
        ),
      ),
    );
  }
}
