import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/routes/route_names.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({super.key, this.currentIndex = 0});

  final int currentIndex;

  static const Color _barBg = Color(0xFF531666);

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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      color: _barBg,
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(
                currentIndex == 0 ? Icons.home_rounded : Icons.home_outlined,
                color: currentIndex == 0 ? Colors.white : Colors.white70,
                size: 24,
              ),
              onPressed: () => _onTabSelected(context, 0),
            ),
            IconButton(
              icon: Icon(
                currentIndex == 1 ? Icons.people_rounded : Icons.people_outline_rounded,
                color: currentIndex == 1 ? Colors.white : Colors.white70,
                size: 24,
              ),
              onPressed: () => _onTabSelected(context, 1),
            ),
            IconButton(
              icon: Icon(
                currentIndex == 2 ? Icons.calendar_month_rounded : Icons.calendar_today_outlined,
                color: currentIndex == 2 ? Colors.white : Colors.white70,
                size: 22,
              ),
              onPressed: () => _onTabSelected(context, 2),
            ),
          ],
        ),
      ),
    );
  }
}

