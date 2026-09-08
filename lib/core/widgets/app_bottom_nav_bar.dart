import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/routes/route_names.dart';
import '../utils/responsive_helper.dart';

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
    final rh = ResponsiveHelper.of(context);
    final barHeight = rh.bottomNavHeight;
    final iconSize = rh.bottomNavIconSize;
    final eventsIconSize = rh.isWide ? iconSize - 1 : 24.0;
    final minConstraint = rh.isWide ? 60.0 : 54.0;

    return Container(
      color: _barBg,
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
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(minWidth: minConstraint, minHeight: minConstraint),
                    icon: Icon(
                      currentIndex == 0 ? Icons.home_rounded : Icons.home_outlined,
                      color: currentIndex == 0 ? Colors.white : Colors.white70,
                      size: iconSize,
                    ),
                    onPressed: () => _onTabSelected(context, 0),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(minWidth: minConstraint, minHeight: minConstraint),
                    icon: Icon(
                      currentIndex == 1 ? Icons.people_rounded : Icons.people_outline_rounded,
                      color: currentIndex == 1 ? Colors.white : Colors.white70,
                      size: iconSize,
                    ),
                    onPressed: () => _onTabSelected(context, 1),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(minWidth: minConstraint, minHeight: minConstraint),
                    icon: Icon(
                      currentIndex == 2 ? Icons.calendar_month_rounded : Icons.calendar_today_outlined,
                      color: currentIndex == 2 ? Colors.white : Colors.white70,
                      size: eventsIconSize,
                    ),
                    onPressed: () => _onTabSelected(context, 2),
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
