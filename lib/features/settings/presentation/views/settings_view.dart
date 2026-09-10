import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/live_sync_service.dart';
import '../../../../core/services/locale_provider.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_cached_image.dart';
import '../../../../core/widgets/app_top_bar.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  String _userName = '';
  String _userEmail = '';
  String _memberSince = '';
  Map<String, dynamic>? _artistProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final storage = sl<StorageService>();
    final email = storage.getString('user_email') ?? '';
    final name = storage.getString('user_name') ?? '';
    final createdAt = storage.getString('user_created_at');

    setState(() {
      _userEmail = email;
      _userName = name.isNotEmpty ? name : 'User';
      _memberSince = _formatMemberSince(createdAt);
    });

    if (email.isNotEmpty) {
      try {
        final profile = await sl<ApiService>().getUserProfile(email);
        if (profile != null && mounted) {
          final serverName = profile['full_name'] as String? ?? name;
          final serverEmail = profile['email'] as String? ?? email;
          final serverCreatedAt = profile['created_at'] as String?;
          final artist = profile['artist_profile'] as Map<String, dynamic>?;

          setState(() {
            _userName = serverName;
            _userEmail = serverEmail;
            if (serverCreatedAt != null && serverCreatedAt.isNotEmpty) {
              _memberSince = _formatMemberSince(serverCreatedAt);
            }
            _artistProfile = artist;
          });

          // Sync storage
          await storage.setString('user_name', _userName);
          await storage.setString('user_email', _userEmail);
          if (serverCreatedAt != null) {
            await storage.setString('user_created_at', serverCreatedAt);
          }
        }
      } catch (_) {}
    }
  }

  String _formatMemberSince(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      return 'Recently Joined';
    }
    try {
      final dt = DateTime.tryParse(dateStr.replaceAll(' ', 'T'));
      if (dt != null) {
        const months = [
          'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December'
        ];
        return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
      }
    } catch (_) {}
    return dateStr;
  }

  void _onSignOut() async {
    try {
      final storage = sl<StorageService>();
      await storage.clearAuthSession();
      sl<LiveSyncService>().notifyAuthChanged(false);
    } catch (_) {}
    if (mounted) {
      context.go(RouteNames.home);
    }
  }

  void _showChangePasswordDialog() {
    final l10n = AppLocalizations.of(context);
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isUpdating = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 440),
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.changePasswordTitle,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E1E1E),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => Navigator.pop(dialogContext),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.changePasswordSubtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.newPassword,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E1E1E),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: newPasswordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: l10n.newPasswordHint,
                            hintStyle: const TextStyle(fontSize: 13.5, color: Color(0xFF94A3B8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF5E227A), width: 1.8),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.length < 6) {
                              return l10n.passwordMinLength;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l10n.confirmNewPassword,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E1E1E),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: confirmPasswordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: l10n.confirmNewPasswordHint,
                            hintStyle: const TextStyle(fontSize: 13.5, color: Color(0xFF94A3B8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF5E227A), width: 1.8),
                            ),
                          ),
                          validator: (val) {
                            if (val != newPasswordController.text) {
                              return l10n.passwordsDoNotMatch;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF1E1E1E),
                                side: const BorderSide(color: Color(0xFF1E1E1E), width: 1.2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                              child: Text(l10n.cancel, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6A2777),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                elevation: 0,
                              ),
                              onPressed: isUpdating
                                  ? null
                                  : () async {
                                      if (formKey.currentState?.validate() ?? false) {
                                        setDialogState(() => isUpdating = true);
                                        final messenger = ScaffoldMessenger.of(context);
                                        final success = await sl<ApiService>().changePassword(
                                          email: _userEmail,
                                          newPassword: newPasswordController.text.trim(),
                                        );
                                        setDialogState(() => isUpdating = false);

                                        if (dialogContext.mounted) {
                                          Navigator.pop(dialogContext);
                                        }

                                        if (mounted) {
                                          messenger.hideCurrentSnackBar();
                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                success
                                                    ? l10n.passwordUpdatedSuccess
                                                    : l10n.passwordUpdateFailed,
                                              ),
                                              backgroundColor:
                                                  success ? const Color(0xFF5E227A) : const Color(0xFFEF4444),
                                              behavior: SnackBarBehavior.floating,
                                              duration: const Duration(milliseconds: 2000),
                                            ),
                                          );
                                        }
                                      }
                                    },
                              child: isUpdating
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(l10n.updatePassword, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteAccountDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 440),
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.deleteAccountTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.deleteAccountBody,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(l10n.deleteAccountItem1, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.5)),
                      Text(l10n.deleteAccountItem2, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.5)),
                      Text(l10n.deleteAccountItem3, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.5)),
                      Text(l10n.deleteAccountItem4, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.5)),
                      Text(l10n.deleteAccountItem5, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.5)),
                      Text(l10n.deleteAccountItem6, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.5)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      Navigator.pop(dialogContext);
                      await sl<ApiService>().deleteAccount(_userEmail);
                      _onSignOut();
                      if (mounted) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.accountDeletedSuccess),
                            backgroundColor: const Color(0xFFEF4444),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(milliseconds: 2000),
                          ),
                        );
                      }
                    },
                    child: Text(l10n.yesDeleteMyAccount, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1E1E1E),
                      side: const BorderSide(color: Color(0xFF1E1E1E), width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(l10n.cancel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final storage = sl<StorageService>();
    final isLoggedIn = storage.getBool('is_logged_in') ?? false;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF6B1C9B),
      appBar: const AppTopBar(backgroundColor: Colors.white),
      body: SafeArea(
        child: Column(
          children: [
            // "Account Settings" Sub-Header with Back Arrow & Home Action
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.18),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(RouteNames.home);
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      l10n.accountSettings,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => context.go(RouteNames.home),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.home_outlined, color: Colors.white, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            l10n.home,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main Body Scrollable List
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF6B1C9B),
                backgroundColor: Colors.white,
                onRefresh: _loadUserProfile,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  children: [
                    // ── Card 0: Language Preference ─────────────────────────
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.language, size: 22, color: Color(0xFF1E1E1E)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  l10n.language,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E1E1E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.languageSubtitle,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 16),
                          Consumer<LocaleProvider>(
                            builder: (context, localeProvider, _) {
                              final isArabic = localeProvider.isArabic;
                              return Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => localeProvider.setLocale(const Locale('en')),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                        decoration: BoxDecoration(
                                          color: !isArabic ? const Color(0xFFF3E8FF) : const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: !isArabic ? const Color(0xFF5E227A) : const Color(0xFFE2E8F0),
                                            width: !isArabic ? 1.8 : 1.0,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Text('🇬🇧', style: TextStyle(fontSize: 18)),
                                            const SizedBox(width: 8),
                                            Text(
                                              l10n.english,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: !isArabic ? FontWeight.bold : FontWeight.w500,
                                                color: !isArabic ? const Color(0xFF5E227A) : const Color(0xFF1E1E1E),
                                              ),
                                            ),
                                            if (!isArabic) ...[
                                              const SizedBox(width: 6),
                                              const Icon(Icons.check_circle, size: 16, color: Color(0xFF5E227A)),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => localeProvider.setLocale(const Locale('ar')),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                        decoration: BoxDecoration(
                                          color: isArabic ? const Color(0xFFF3E8FF) : const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: isArabic ? const Color(0xFF5E227A) : const Color(0xFFE2E8F0),
                                            width: isArabic ? 1.8 : 1.0,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Text('🇦🇪', style: TextStyle(fontSize: 18)),
                                            const SizedBox(width: 8),
                                            Text(
                                              l10n.arabic,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: isArabic ? FontWeight.bold : FontWeight.w500,
                                                color: isArabic ? const Color(0xFF5E227A) : const Color(0xFF1E1E1E),
                                              ),
                                            ),
                                            if (isArabic) ...[
                                              const SizedBox(width: 6),
                                              const Icon(Icons.check_circle, size: 16, color: Color(0xFF5E227A)),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (!isLoggedIn)
                      // Unauthenticated State Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              l10n.pleaseSignIn,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 15, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => context.push(RouteNames.login),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5E227A),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                              child: Text(l10n.signIn, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      // Card 1: Account Information (Dynamic from MySQL)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.person_outline, size: 22, color: Color(0xFF1E1E1E)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    l10n.accountInformation,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E1E1E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.accountInformationSubtitle,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 20),
                            _buildAccountField(l10n.email, _userEmail.isNotEmpty ? _userEmail : l10n.noEmailProvided),
                            const SizedBox(height: 16),
                            _buildAccountField(l10n.memberSince, _memberSince.isNotEmpty ? _memberSince : l10n.recentlyJoined),
                            const SizedBox(height: 16),
                            _buildAccountField(l10n.fullName, _userName.isNotEmpty ? _userName : 'User'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Card 2: Artist Profile (Dynamic from MySQL)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.palette_outlined, size: 22, color: Color(0xFF1E1E1E)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    l10n.artistProfile,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E1E1E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _artistProfile != null
                                  ? l10n.artistProfileSubtitle
                                  : l10n.artistProfileCreateSubtitle,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 20),
                            if (_artistProfile != null) ...[
                              // Active Artist Profile View
                              Row(
                                children: [
                                  ClipOval(
                                    child: Container(
                                      width: 56,
                                      height: 56,
                                      color: const Color(0xFFF3E8FF),
                                      child: _artistProfile!['avatar_url'] != null && _artistProfile!['avatar_url'].toString().isNotEmpty
                                          ? AppCachedImage(
                                              imageUrl: _artistProfile!['avatar_url'].toString(),
                                              width: 56,
                                              height: 56,
                                              fit: BoxFit.cover,
                                              errorWidget: const Icon(Icons.person, color: Color(0xFF6A2777), size: 28),
                                            )
                                          : const Icon(Icons.person, color: Color(0xFF6A2777), size: 28),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _artistProfile!['name']?.toString() ?? _userName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1E1E1E),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _artistProfile!['category']?.toString() ?? 'Contemporary Art',
                                          style: const TextStyle(fontSize: 13, color: Color(0xFF6A2777), fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _artistProfile!['location']?.toString() ?? 'Dubai, UAE',
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 42,
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF5E227A),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        onPressed: () {
                                          context.push(
                                            RouteNames.artistRegistration,
                                            extra: {
                                              'isEditing': true,
                                              'artistId': _artistProfile!['id']?.toString(),
                                            },
                                          );
                                        },
                                        icon: const Icon(Icons.edit_outlined, size: 16),
                                        label: Text(l10n.editProfile, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: SizedBox(
                                      height: 42,
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFF5E227A),
                                          side: const BorderSide(color: Color(0xFF5E227A), width: 1.2),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        onPressed: () => context.push(RouteNames.artists),
                                        icon: const Icon(Icons.visibility_outlined, size: 18),
                                        label: Text(l10n.viewDirectory, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              // No Artist Profile View
                              Center(
                                child: Column(
                                  children: [
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF1F5F9),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.palette_outlined, size: 28, color: Color(0xFF475569)),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      l10n.noArtistProfile,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E1E1E),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        l10n.noArtistProfileBody,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF64748B),
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF5E227A),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      ),
                                      onPressed: () => context.push(RouteNames.artistRegistration),
                                      child: Text(
                                        l10n.createArtistProfile,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Card 3: Account Actions
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.shield_outlined, size: 22, color: Color(0xFF1E1E1E)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    l10n.accountActions,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E1E1E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.accountActionsSubtitle,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 20),

                            // Button 1: Change Password
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF1E1E1E),
                                  side: const BorderSide(color: Color(0xFF1E1E1E), width: 1.2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  backgroundColor: const Color(0xFFFAFAFC),
                                ),
                                onPressed: _showChangePasswordDialog,
                                icon: const Icon(Icons.vpn_key_outlined, size: 18, color: Colors.black),
                                label: Text(
                                  l10n.changePassword,
                                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Button 2: Sign Out
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF1E1E1E),
                                  side: const BorderSide(color: Color(0xFF1E1E1E), width: 1.2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  backgroundColor: const Color(0xFFFAFAFC),
                                ),
                                onPressed: _onSignOut,
                                icon: const Icon(Icons.logout, size: 18, color: Colors.black),
                                label: Text(
                                  l10n.signOut,
                                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Button 3: Delete Account
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEF4444),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: _showDeleteAccountDialog,
                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.black),
                                label: Text(
                                  l10n.deleteAccount,
                                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Note box
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Text(
                                l10n.deleteAccountNote,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF64748B),
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Artist Dubai · v1.0.0',
                          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: -1),
    );
  }

  Widget _buildAccountField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: Color(0xFF1E1E1E)),
        ),
      ],
    );
  }
}
