import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/routes/route_names.dart';

enum TopBarMenuItem {
  privacyPolicy,
  termsConditions,
  signIn,
  settings,
}

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    this.backgroundColor = const Color(0xFFFAFAFA),
  });

  final Color backgroundColor;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1.0);

  void _onMenuItemSelected(BuildContext context, TopBarMenuItem item) {
    switch (item) {
      case TopBarMenuItem.privacyPolicy:
        context.push(RouteNames.privacyPolicy);
        break;
      case TopBarMenuItem.termsConditions:
        context.push(RouteNames.termsConditions);
        break;
      case TopBarMenuItem.signIn:
        context.push(RouteNames.login);
        break;
      case TopBarMenuItem.settings:
        context.push(RouteNames.settings);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      centerTitle: false,
      titleSpacing: 16.0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circular Logo Badge
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/header_logo.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/images/artist-dubai-logo-26Kex3Rz.png',
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Brand Titles
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Artist',
                style: TextStyle(
                  color: Color(0xFF1E1E1E),
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
              Text(
                'Dubai',
                style: TextStyle(
                  color: Color(0xFF1E1E1E),
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        PopupMenuButton<TopBarMenuItem>(
          icon: const Icon(
            Icons.more_vert,
            color: Color(0xFF1E1E1E),
            size: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.0),
            side: const BorderSide(color: Color(0xFF1E1E1E), width: 1.0),
          ),
          color: Colors.white,
          elevation: 6,
          offset: const Offset(0, 48),
          onSelected: (item) => _onMenuItemSelected(context, item),
          itemBuilder: (BuildContext context) => <PopupMenuEntry<TopBarMenuItem>>[
            const PopupMenuItem<TopBarMenuItem>(
              value: TopBarMenuItem.privacyPolicy,
              child: Text(
                'Privacy Policy',
                style: TextStyle(
                  color: Color(0xFF1E1E1E),
                  fontSize: 14.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const PopupMenuItem<TopBarMenuItem>(
              value: TopBarMenuItem.termsConditions,
              child: Text(
                'Terms & Conditions',
                style: TextStyle(
                  color: Color(0xFF1E1E1E),
                  fontSize: 14.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const PopupMenuItem<TopBarMenuItem>(
              value: TopBarMenuItem.signIn,
              child: Text(
                'Sign In',
                style: TextStyle(
                  color: Color(0xFF1E1E1E),
                  fontSize: 14.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const PopupMenuItem<TopBarMenuItem>(
              value: TopBarMenuItem.settings,
              child: Text(
                'Settings',
                style: TextStyle(
                  color: Color(0xFF1E1E1E),
                  fontSize: 14.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1.0),
        child: Divider(
          height: 1.0,
          thickness: 1.0,
          color: Color(0xFF1E1E1E),
        ),
      ),
    );
  }
}
