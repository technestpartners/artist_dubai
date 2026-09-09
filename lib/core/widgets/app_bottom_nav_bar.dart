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
        if (_isLoggedIn) {
          context.go(RouteNames.events);
        } else {
          context.push(RouteNames.login);
        }
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
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(minWidth: minConstraint, minHeight: minConstraint),
                    icon: Icon(
                      widget.currentIndex == 0 ? Icons.home_rounded : Icons.home_outlined,
                      color: widget.currentIndex == 0 ? Colors.white : Colors.white70,
                      size: iconSize,
                    ),
                    onPressed: () => _onTabSelected(context, 0),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(minWidth: minConstraint, minHeight: minConstraint),
                    icon: Icon(
                      widget.currentIndex == 1 ? Icons.people_rounded : Icons.people_outline_rounded,
                      color: widget.currentIndex == 1 ? Colors.white : Colors.white70,
                      size: iconSize,
                    ),
                    onPressed: () => _onTabSelected(context, 1),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(minWidth: minConstraint, minHeight: minConstraint),
                    icon: Icon(
                      !loggedIn
                          ? (widget.currentIndex == 2 ? Icons.login_rounded : Icons.login)
                          : (widget.currentIndex == 2 ? Icons.calendar_month_rounded : Icons.calendar_today_outlined),
                      color: widget.currentIndex == 2 ? Colors.white : Colors.white70,
                      size: !loggedIn ? iconSize : eventsIconSize,
                    ),
                    tooltip: !loggedIn ? 'Log In / Sign Up' : 'Art Events',
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
