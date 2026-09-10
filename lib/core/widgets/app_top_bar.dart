import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../app/routes/route_names.dart';
import '../di/injection_container.dart';
import '../services/api_service.dart';
import '../services/live_sync_service.dart';
import '../services/locale_provider.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../utils/responsive_helper.dart';
import 'notifications_panel.dart';

enum TopBarMenuItem {
  adminDashboard,
  accountSettings,
  createArtistProfile,
  editArtistProfile,
  myFavorites,
  myEvents,
  privacyPolicy,
  termsConditions,
  signIn,
  signOut,
  settings,
}

class AppTopBar extends StatefulWidget implements PreferredSizeWidget {
  const AppTopBar({super.key, this.backgroundColor = Colors.white});

  final Color backgroundColor;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1.0);

  @override
  State<AppTopBar> createState() => _AppTopBarState();
}

class _AppTopBarState extends State<AppTopBar> {
  final GlobalKey _bellKey = GlobalKey();
  bool _hasArtistProfile = false;
  String? _myArtistId;
  StreamSubscription? _artistsSub;
  StreamSubscription? _authSub;

  @override
  void initState() {
    super.initState();
    _loadArtistProfile();
    _artistsSub = sl<LiveSyncService>().artistsStream.listen((_) {
      if (mounted) _loadArtistProfile();
    });
    _authSub = sl<LiveSyncService>().authStream.listen((_) {
      if (mounted) _loadArtistProfile();
    });
  }

  @override
  void dispose() {
    _artistsSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }

  void _loadArtistProfile() async {
    try {
      final storage = sl<StorageService>();
      final email = (storage.getString('user_email') ?? '').trim();
      final cachedHas = storage.getBool('has_artist_profile') ?? false;
      final cachedId = storage.getString('artist_profile_id');
      if (mounted) {
        setState(() {
          _hasArtistProfile = _isLoggedIn && email.isNotEmpty && cachedHas && (cachedId != null && cachedId.isNotEmpty);
          _myArtistId = _hasArtistProfile ? cachedId : null;
        });
      }

      if (_isLoggedIn && email.isNotEmpty) {
        final artist = await sl<ApiService>().getMyArtistProfile();
        if (mounted) {
          setState(() {
            _hasArtistProfile = artist != null;
            _myArtistId = artist?.id;
          });
        }
      } else if (mounted) {
        setState(() {
          _hasArtistProfile = false;
          _myArtistId = null;
        });
      }
    } catch (_) {}
  }

  bool get _isLoggedIn {
    try {
      return sl<StorageService>().getBool('is_logged_in') ?? false;
    } catch (_) {
      return false;
    }
  }

  void _onMenuItemSelected(BuildContext context, TopBarMenuItem item) async {
    switch (item) {
      case TopBarMenuItem.adminDashboard:
        context.push(RouteNames.adminDashboard);
        break;
      case TopBarMenuItem.accountSettings:
        context.push(RouteNames.settings);
        break;
      case TopBarMenuItem.createArtistProfile:
        context.push(RouteNames.artistRegistration);
        break;
      case TopBarMenuItem.editArtistProfile:
        String? artistId = _myArtistId;
        if (artistId == null || artistId.isEmpty) {
          try {
            artistId = sl<StorageService>().getString('artist_profile_id');
          } catch (_) {}
        }
        context.push(
          RouteNames.artistRegistration,
          extra: {
            'isEditing': true,
            'artistId': artistId,
          },
        );
        break;
      case TopBarMenuItem.myFavorites:
        context.push(RouteNames.favorites);
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
          await storage.clearAuthSession();
          sl<LiveSyncService>().notifyAuthChanged(false);
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
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);

    // Read dynamic user info from storage
    String userName = 'User';
    String userEmail = '';
    String avatarLetter = 'U';
    bool isAdmin = false;
    try {
      final storage = sl<StorageService>();
      isAdmin = storage.getBool('is_admin') ?? false;
      userName = storage.getString('user_name') ?? 'User';
      userEmail = storage.getString('user_email') ?? '';
      if (userName.isNotEmpty) {
        avatarLetter = userName[0].toUpperCase();
      }
    } catch (_) {}

    final rh = ResponsiveHelper.of(context);
    final logoSize = rh.appBarLogoSize;
    final brandFontSize = rh.isWide ? 16.0 : 14.0;
    final avatarSize = rh.appBarAvatarSize;

    return AppBar(
      backgroundColor: widget.backgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      centerTitle: false,
      titleSpacing: rh.isWide ? 20.0 : 12.0,
      title: InkWell(
        onTap: () => context.go(RouteNames.home),
        borderRadius: BorderRadius.circular(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Circular Logo Badge — scales with screen class
            Container(
              width: logoSize,
              height: logoSize,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/header_logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/images/header_logo.png',
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Brand Titles
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Artist',
                  style: TextStyle(
                    color: const Color(0xFF1E1E1E),
                    fontSize: brandFontSize,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                Text(
                  'Dubai',
                  style: TextStyle(
                    color: const Color(0xFF1E1E1E),
                    fontSize: brandFontSize,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        // ── Language Toggle Button ──────────────────────────────────────────
        Consumer<LocaleProvider>(
          builder: (context, localeProvider, _) {
            final isArabic = localeProvider.isArabic;
            return Tooltip(
              message: isArabic ? 'Switch to English' : 'التبديل إلى العربية',
              child: InkWell(
                onTap: () => localeProvider.toggleLocale(),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5E227A).withValues(alpha: 0.08),
                    border: Border.all(color: const Color(0xFF5E227A), width: 1.4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.language, size: 15, color: Color(0xFF5E227A)),
                      const SizedBox(width: 4),
                      Text(
                        isArabic ? 'English' : 'عربي',
                        style: const TextStyle(
                          color: Color(0xFF5E227A),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 2),

        if (loggedIn) ...[
          // Dynamic Notification Bell with live unread badge
          ListenableBuilder(
            listenable: sl<NotificationService>(),
            builder: (context, _) {
              final unreadCount = sl<NotificationService>().unreadCount;

              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    key: _bellKey,
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: Color(0xFF1E1E1E),
                      size: 24,
                    ),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    onPressed: () => showNotificationsPanel(context, _bellKey),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Center(
                          child: Text(
                            unreadCount > 9 ? '9+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              height: 1.0,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 2),

          // User Avatar Circle (dynamic first letter) - Tap opens Account Settings
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (loggedIn) {
                context.push(RouteNames.settings);
              } else {
                context.push(RouteNames.login);
              }
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Tooltip(
                message: l10n?.accountSettings ?? 'Account Settings',
                child: Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: const BoxDecoration(
                    color: Color(0xFF5E227A),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      avatarLetter,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: rh.isWide ? 16.0 : 14.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 2),
        ],

        // Popup Menu — wrapped in Builder so itemBuilder can call AppLocalizations.of(context)
        Builder(
          builder: (ctx) {
            final menuL10n = AppLocalizations.of(ctx);
            return PopupMenuButton<TopBarMenuItem>(
              icon: const Icon(Icons.more_vert, color: Color(0xFF1E1E1E), size: 22),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
                side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
              ),
              color: Colors.white,
              elevation: 8,
              offset: const Offset(0, 48),
              onSelected: (item) => _onMenuItemSelected(ctx, item),
              itemBuilder: (BuildContext context) => <PopupMenuEntry<TopBarMenuItem>>[
                if (loggedIn) ...[
                  // User Header inside Popup (dynamic from storage)
                  PopupMenuItem<TopBarMenuItem>(
                    enabled: false,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              color: Color(0xFF1E1E1E),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            userEmail,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const PopupMenuDivider(height: 1),
                  if (isAdmin) ...[
                    PopupMenuItem<TopBarMenuItem>(
                      value: TopBarMenuItem.adminDashboard,
                      child: Row(
                        children: const [
                          Icon(
                            Icons.admin_panel_settings_outlined,
                            size: 18,
                            color: Color(0xFF6A2777),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Admin Dashboard',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6A2777),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  PopupMenuItem<TopBarMenuItem>(
                    value: TopBarMenuItem.accountSettings,
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline, size: 18, color: Color(0xFF1E1E1E)),
                        const SizedBox(width: 10),
                        Text(
                          menuL10n.accountSettings,
                          style: const TextStyle(fontSize: 14.5, color: Color(0xFF1E1E1E)),
                        ),
                      ],
                    ),
                  ),
                  if (_hasArtistProfile)
                    PopupMenuItem<TopBarMenuItem>(
                      value: TopBarMenuItem.editArtistProfile,
                      child: Row(
                        children: [
                          const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF1E1E1E)),
                          const SizedBox(width: 10),
                          Text(
                            menuL10n.editProfile,
                            style: const TextStyle(fontSize: 14.5, color: Color(0xFF1E1E1E)),
                          ),
                        ],
                      ),
                    )
                  else
                    PopupMenuItem<TopBarMenuItem>(
                      value: TopBarMenuItem.createArtistProfile,
                      child: Row(
                        children: [
                          const Icon(Icons.palette_outlined, size: 18, color: Color(0xFF1E1E1E)),
                          const SizedBox(width: 10),
                          Text(
                            menuL10n.createArtistProfile,
                            style: const TextStyle(fontSize: 14.5, color: Color(0xFF1E1E1E)),
                          ),
                        ],
                      ),
                    ),
                  PopupMenuItem<TopBarMenuItem>(
                    value: TopBarMenuItem.myEvents,
                    child: Row(
                      children: [
                        const Icon(Icons.event_outlined, size: 18, color: Color(0xFF1E1E1E)),
                        const SizedBox(width: 10),
                        Text(
                          menuL10n.myEvents,
                          style: const TextStyle(fontSize: 14.5, color: Color(0xFF1E1E1E)),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(height: 1),
                ],

                PopupMenuItem<TopBarMenuItem>(
                  value: TopBarMenuItem.privacyPolicy,
                  child: Row(
                    children: [
                      const Icon(Icons.help_outline, size: 18, color: Color(0xFF1E1E1E)),
                      const SizedBox(width: 10),
                      Text(
                        menuL10n.privacyPolicy,
                        style: const TextStyle(fontSize: 14.5, color: Color(0xFF1E1E1E)),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<TopBarMenuItem>(
                  value: TopBarMenuItem.termsConditions,
                  child: Row(
                    children: [
                      const Icon(Icons.settings_outlined, size: 18, color: Color(0xFF1E1E1E)),
                      const SizedBox(width: 10),
                      Text(
                        menuL10n.termsAndConditions,
                        style: const TextStyle(fontSize: 14.5, color: Color(0xFF1E1E1E)),
                      ),
                    ],
                  ),
                ),

                if (loggedIn) ...[
                  const PopupMenuDivider(height: 1),
                  PopupMenuItem<TopBarMenuItem>(
                    value: TopBarMenuItem.signOut,
                    child: Row(
                      children: [
                        const Icon(Icons.logout, size: 18, color: Color(0xFF1E1E1E)),
                        const SizedBox(width: 10),
                        Text(
                          menuL10n.signOut,
                          style: const TextStyle(fontSize: 14.5, color: Color(0xFF1E1E1E)),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  PopupMenuItem<TopBarMenuItem>(
                    value: TopBarMenuItem.signIn,
                    child: Row(
                      children: [
                        const Icon(Icons.login, size: 18, color: Color(0xFF1E1E1E)),
                        const SizedBox(width: 10),
                        Text(
                          menuL10n.signIn,
                          style: const TextStyle(fontSize: 14.5, color: Color(0xFF1E1E1E)),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<TopBarMenuItem>(
                    value: TopBarMenuItem.settings,
                    child: Row(
                      children: [
                        const Icon(Icons.settings_outlined, size: 18, color: Color(0xFF1E1E1E)),
                        const SizedBox(width: 10),
                        Text(
                          menuL10n.settings,
                          style: const TextStyle(fontSize: 14.5, color: Color(0xFF1E1E1E)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1.0),
        child: Divider(height: 1.0, thickness: 1.0, color: Color(0xFF1E1E1E)),
      ),
    );
  }
}
