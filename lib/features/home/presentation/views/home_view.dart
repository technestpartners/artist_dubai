import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:artist_dubai/l10n/app_localizations.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/live_sync_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../domain/models/menu_card_item.dart';
import '../widgets/home_footer_widget.dart';
import '../widgets/home_header_widget.dart';
import '../widgets/menu_card_widget.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
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
    _authSub = sl<LiveSyncService>().authStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  List<MenuCardItem> get _effectiveItems {
    final base = MenuCardItem.items;
    final loggedIn = _isLoggedIn;
    return base.map((item) {
      if (item.routeName == '/login' || item.routeName == '/logout') {
        if (loggedIn) {
          return const MenuCardItem(
            title: 'LOGOUT',
            imagePath: 'assets/images/login-portal.png',
            routeName: '/logout',
          );
        } else {
          return const MenuCardItem(
            title: 'LOGIN',
            imagePath: 'assets/images/login-portal.png',
            routeName: '/login',
          );
        }
      }
      return item;
    }).toList();
  }

  void _onCardTap(BuildContext context, MenuCardItem item) {
    if (item.routeName == '/logout' || (_isLoggedIn && item.routeName == '/login')) {
      _showLogoutDialog(context);
      return;
    }
    context.push(item.routeName);
  }

  void _showLogoutDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    String userName = '';
    String userEmail = '';
    try {
      final storage = sl<StorageService>();
      userName = storage.getString('user_name') ?? '';
      userEmail = storage.getString('user_email') ?? '';
    } catch (_) {}

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          title: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF6B1C9B).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFF6B1C9B),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  l10n.signOut,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (userEmail.isNotEmpty || userName.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF6B1C9B).withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFF6B1C9B),
                        child: Text(
                          (userName.isNotEmpty
                                  ? userName[0]
                                  : (userEmail.isNotEmpty ? userEmail[0] : 'U'))
                              .toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (userName.isNotEmpty)
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.5,
                                  color: Color(0xFF1E1E1E),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (userEmail.isNotEmpty)
                              Text(
                                userEmail,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Text(
                isAr
                    ? 'هل أنت متأكد أنك تريد تسجيل الخروج من حسابك؟'
                    : 'Are you sure you want to log out of your account?',
                style: const TextStyle(
                  fontSize: 14.5,
                  color: Color(0xFF4A4A4A),
                  height: 1.35,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: Text(
                isAr ? 'إلغاء' : 'Cancel',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14.5,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  final storage = sl<StorageService>();
                  await storage.clearAuthSession();
                  sl<LiveSyncService>().notifyAuthChanged(false);
                } catch (_) {}
                if (mounted) {
                  setState(() {});
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isAr ? 'تم تسجيل الخروج بنجاح' : 'Logged out successfully',
                      ),
                      backgroundColor: const Color(0xFF6B1C9B),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text(
                l10n.signOut,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rh = ResponsiveHelper.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF6B1C9B), // Top vibrant purple
              Color(0xFF58209B), // Mid royal purple
              Color(0xFF4D249E), // Bottom rich purple
            ],
            stops: [0.0, 0.48, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = rh.horizontalPadding;
              final gap = rh.isWide
                  ? 12.0
                  : (constraints.maxHeight * 0.009).clamp(5.0, 10.0);

              // Tablet/Desktop/Fold: 2 rows × 5 cols  |  Mobile: 5 rows × 2 cols
              final rowCount = rh.isWide ? 2 : 5;
              final colCount = rh.isWide ? 5 : 2;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Top Header
                  const HomeHeaderWidget(),
                  SizedBox(height: gap * 0.3),

                  // 2. Adaptive Grid — fills remaining screen height perfectly
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: rh.contentMaxWidth),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                          child: _buildGrid(context, rowCount, colCount, gap),
                        ),
                      ),
                    ),
                  ),

                  // 3. Bottom Footer
                  const HomeFooterWidget(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    int rowCount,
    int colCount,
    double gap,
  ) {
    final items = _effectiveItems;
    return Column(
      children: [
        for (int row = 0; row < rowCount; row++) ...[
          Expanded(
            child: Row(
              children: [
                for (int col = 0; col < colCount; col++) ...[
                  if (col > 0) SizedBox(width: gap),
                  Expanded(
                    child: _buildCard(context, items, row * colCount + col),
                  ),
                ],
              ],
            ),
          ),
          if (row < rowCount - 1) SizedBox(height: gap),
        ],
      ],
    );
  }

  Widget _buildCard(BuildContext context, List<MenuCardItem> items, int idx) {
    if (idx >= items.length) return const SizedBox.expand();
    final item = items[idx];
    return MenuCardWidget(
      item: item,
      onTap: () => _onCardTap(context, item),
    );
  }
}
