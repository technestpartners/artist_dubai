import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/routes/route_names.dart';
import '../../core/di/injection_container.dart';
import '../../core/services/storage_service.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({super.key, this.currentIndex = 0});

  final int currentIndex;

  void _onTabSelected(BuildContext context, int index) {
    String matchedLocation = '';
    try {
      matchedLocation = GoRouterState.of(context).matchedLocation;
    } catch (_) {}

    final isLoggedIn = sl<StorageService>().getBool('is_logged_in') ?? false;

    switch (index) {
      case 0:
        if (matchedLocation != RouteNames.home) {
          context.go(RouteNames.home);
        }
        break;
      case 1:
        if (matchedLocation != RouteNames.artists) {
          context.go(RouteNames.artists);
        }
        break;
      case 2:
        if (!isLoggedIn) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          context.push(RouteNames.login);
        } else if (matchedLocation != RouteNames.events) {
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
