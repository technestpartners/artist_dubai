import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/routes/route_names.dart';

import '../../core/di/injection_container.dart';
import '../../core/services/storage_service.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({super.key, this.currentIndex = 0});

  final int currentIndex;

  void _onTabSelected(BuildContext context, int index) {
    if (index == currentIndex) return;

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
      decoration: const BoxDecoration(color: Color(0xFF6A2777)),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(
                Icons.home_outlined,
                color:
                    currentIndex == 0 ? Colors.white : const Color(0xFFE2D6F5),
                size: 28,
              ),
              onPressed: () => _onTabSelected(context, 0),
            ),
            IconButton(
              icon: Icon(
                Icons.people_outline,
                color:
                    currentIndex == 1 ? Colors.white : const Color(0xFFE2D6F5),
                size: 28,
              ),
              onPressed: () => _onTabSelected(context, 1),
            ),
            IconButton(
              icon: Icon(
                Icons.calendar_today_outlined,
                color:
                    currentIndex == 2 ? Colors.white : const Color(0xFFE2D6F5),
                size: 24,
              ),
              onPressed: () => _onTabSelected(context, 2),
            ),
          ],
        ),
      ),
    );
  }
}
