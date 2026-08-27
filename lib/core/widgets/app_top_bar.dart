import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/routes/route_names.dart';
import '../di/injection_container.dart';
import '../services/storage_service.dart';

enum TopBarMenuItem {
  accountSettings,
  createArtistProfile,
  myBookings,
  myEvents,
  privacyPolicy,
  termsConditions,
  signIn,
  signOut,
  settings,
}

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({super.key, this.backgroundColor = const Color(0xFFFAFAFA)});

  final Color backgroundColor;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1.0);

  bool get _isLoggedIn {
    try {
      return sl<StorageService>().getBool('is_logged_in') ?? false;
    } catch (_) {
      return false;
    }
  }

  void _onMenuItemSelected(BuildContext context, TopBarMenuItem item) async {
    switch (item) {
      case TopBarMenuItem.accountSettings:
        context.push(RouteNames.settings);
        break;
      case TopBarMenuItem.createArtistProfile:
        context.push(RouteNames.artistRegistration);
        break;
      case TopBarMenuItem.myBookings:
        context.push(RouteNames.bookings);
        break;
      case TopBarMenuItem.myEvents:
        context.push(RouteNames.myEvents);
        break;
      case TopBarMenuItem.privacyPolicy:
        context.push(RouteNames.privacyPolicy);
        break;
      case TopBarMenuItem.termsConditions:
        context.push(RouteNames.termsConditions);
        break;
      case TopBarMenuItem.signIn:
        context.push(RouteNames.login);
        break;
      case TopBarMenuItem.signOut:
        try {
          final storage = sl<StorageService>();
          await storage.setBool('is_logged_in', false);
        } catch (_) {}
        if (context.mounted) {
          context.go(RouteNames.home);
        }
        break;
      case TopBarMenuItem.settings:
        context.push(RouteNames.settings);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = _isLoggedIn;

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
            decoration: const BoxDecoration(shape: BoxShape.circle),
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
        if (loggedIn) ...[
          // Notification Bell with Badge 3
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_none,
                  color: Color(0xFF1E1E1E),
                  size: 24,
                ),
                onPressed: () {},
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE53935),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: const Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),

          // User Avatar Circle "V"
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFF5E227A),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                'V',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],

        // Popup Menu (Matching Screenshot media_1787726981939.png)
        PopupMenuButton<TopBarMenuItem>(
          icon: const Icon(Icons.more_vert, color: Color(0xFF1E1E1E), size: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
            side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
          ),
          color: Colors.white,
          elevation: 8,
          offset: const Offset(0, 48),
          onSelected: (item) => _onMenuItemSelected(context, item),
          itemBuilder:
              (BuildContext context) => <PopupMenuEntry<TopBarMenuItem>>[
                if (loggedIn) ...[
                  // User Header inside Popup (vivek / vivek@gmail.com)
                  PopupMenuItem<TopBarMenuItem>(
                    enabled: false,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'vivek',
                            style: TextStyle(
                              color: Color(0xFF1E1E1E),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'vivek@gmail.com',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const PopupMenuDivider(height: 1),
                  const PopupMenuItem<TopBarMenuItem>(
                    value: TopBarMenuItem.accountSettings,
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 18,
                          color: Color(0xFF1E1E1E),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Account Settings',
                          style: TextStyle(
                            fontSize: 14.5,
                            color: Color(0xFF1E1E1E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem<TopBarMenuItem>(
                    value: TopBarMenuItem.createArtistProfile,
                    child: Row(
                      children: [
                        Icon(
                          Icons.palette_outlined,
                          size: 18,
                          color: Color(0xFF1E1E1E),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Create Artist Profile',
                          style: TextStyle(
                            fontSize: 14.5,
                            color: Color(0xFF1E1E1E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem<TopBarMenuItem>(
                    value: TopBarMenuItem.myBookings,
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: Color(0xFF1E1E1E),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'My Bookings',
                          style: TextStyle(
                            fontSize: 14.5,
                            color: Color(0xFF1E1E1E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem<TopBarMenuItem>(
                    value: TopBarMenuItem.myEvents,
                    child: Row(
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 18,
                          color: Color(0xFF1E1E1E),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'My Events',
                          style: TextStyle(
                            fontSize: 14.5,
                            color: Color(0xFF1E1E1E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(height: 1),
                ],

                const PopupMenuItem<TopBarMenuItem>(
                  value: TopBarMenuItem.privacyPolicy,
                  child: Row(
                    children: [
                      Icon(
                        Icons.help_outline,
                        size: 18,
                        color: Color(0xFF1E1E1E),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Privacy Policy',
                        style: TextStyle(
                          fontSize: 14.5,
                          color: Color(0xFF1E1E1E),
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem<TopBarMenuItem>(
                  value: TopBarMenuItem.termsConditions,
                  child: Row(
                    children: [
                      Icon(
                        Icons.settings_outlined,
                        size: 18,
                        color: Color(0xFF1E1E1E),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Terms & Conditions',
                        style: TextStyle(
                          fontSize: 14.5,
                          color: Color(0xFF1E1E1E),
                        ),
                      ),
                    ],
                  ),
                ),

                if (loggedIn) ...[
                  const PopupMenuDivider(height: 1),
                  const PopupMenuItem<TopBarMenuItem>(
                    value: TopBarMenuItem.signOut,
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 18, color: Color(0xFF1E1E1E)),
                        SizedBox(width: 10),
                        Text(
                          'Sign Out',
                          style: TextStyle(
                            fontSize: 14.5,
                            color: Color(0xFF1E1E1E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const PopupMenuItem<TopBarMenuItem>(
                    value: TopBarMenuItem.signIn,
                    child: Row(
                      children: [
                        Icon(Icons.login, size: 18, color: Color(0xFF1E1E1E)),
                        SizedBox(width: 10),
                        Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 14.5,
                            color: Color(0xFF1E1E1E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem<TopBarMenuItem>(
                    value: TopBarMenuItem.settings,
                    child: Row(
                      children: [
                        Icon(
                          Icons.settings_outlined,
                          size: 18,
                          color: Color(0xFF1E1E1E),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Settings',
                          style: TextStyle(
                            fontSize: 14.5,
                            color: Color(0xFF1E1E1E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1.0),
        child: Divider(height: 1.0, thickness: 1.0, color: Color(0xFF1E1E1E)),
      ),
    );
  }
}
