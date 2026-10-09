import 'package:flutter/material.dart';
import 'package:artist_dubai/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/live_sync_service.dart';
import '../../../../core/services/locale_provider.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/data_translator.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_cached_image.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../chat/data/chat_service.dart';
import '../../../chat/domain/models/listing_plan_model.dart';

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
  String _chatPlan = 'Basic (Free)';
  int _chatAllowance = 10;
  List<Map<String, dynamic>> _purchasedPlans = [];
  List<ListingPlanItem> _availableListingPlans = [];

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
    final chatService = sl<ChatService>();
    final localPlan = chatService.getChatPlanName();
    final localAllowance = chatService.getMaxMonthlyAllowance();

    setState(() {
      _userEmail = email;
      _userName = name.isNotEmpty ? name : 'User';
      _memberSince = _formatMemberSince(createdAt);
      _chatPlan = localPlan;
      _chatAllowance = localAllowance;
    });

    if (email.isNotEmpty) {
      try {
        final profile = await sl<ApiService>().getUserProfile(email);
        if (profile != null && mounted) {
          final serverName = profile['full_name'] as String? ?? name;
          final serverEmail = profile['email'] as String? ?? email;
          final serverCreatedAt = profile['created_at'] as String?;
          final artist = profile['artist_profile'] as Map<String, dynamic>?;
          final serverChatPlan = profile['chat_plan']?.toString() ?? localPlan;
          final serverChatAllowance = int.tryParse(profile['chat_max_allowance']?.toString() ?? '') ?? localAllowance;

          List<Map<String, dynamic>> plans = [];
          if (profile['purchased_plans'] is List) {
            plans = (profile['purchased_plans'] as List)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
          }

          // Fetch user_plans directly from our dedicated user_plans API
          try {
            final directPlans = await sl<ApiService>().getUserPlans(email: email);
            for (final dp in directPlans) {
              final dpId = dp['id'];
              final dpName = dp['plan_name']?.toString() ?? '';
              final alreadyExists = plans.any((p) =>
                  (dpId != null && p['id'] != null && p['id'].toString() == dpId.toString()) ||
                  (p['plan_name'] == dpName && p['start_date'] == dp['start_date']));
              if (!alreadyExists) {
                plans.insert(0, dp);
              }
            }
          } catch (_) {}

          // Check if events have any publishing plans for this user
          try {
            final events = await sl<ApiService>().getEvents();
            for (final ev in events) {
              final evEmail = (ev.organizerEmail ?? '').trim().toLowerCase();
              if (evEmail == email.trim().toLowerCase() && ev.publishingPlan != null && ev.publishingPlan!.isNotEmpty) {
                final alreadyExists = plans.any((p) => p['item_title'] == ev.title);
                if (!alreadyExists) {
                  final planCapitalized = '${ev.publishingPlan![0].toUpperCase()}${ev.publishingPlan!.substring(1)}';
                    plans.add({
                      'id': int.tryParse(ev.id) ?? 0,
                      'plan_name': '$planCapitalized Plan',
                      'plan_type': 'Event Publishing',
                      'item_title': ev.title,
                      'price': (ev.publishingAmount != null && ev.publishingAmount!.isNotEmpty)
                          ? ev.publishingAmount!
                          : (ev.price.isNotEmpty ? ev.price : 'Free'),
                      'billing_cycle': ev.publishingPlan ?? 'Listing',
                      'status': (ev.paymentStatus ?? 'active').toLowerCase() == 'paid' ? 'Active' : 'Active',
                      'start_date': ev.formattedDate.isNotEmpty ? ev.formattedDate : ev.dateTime,
                    });
                  }
                }
              }
            } catch (_) {}

          // Fetch database listing plans created by Admin
          List<ListingPlanItem> dbListingPlans = [];
          try {
            dbListingPlans = await sl<ApiService>().getListingPlans();
          } catch (_) {}

          setState(() {
            _userName = serverName;
            _userEmail = serverEmail;
            if (serverCreatedAt != null && serverCreatedAt.isNotEmpty) {
              _memberSince = _formatMemberSince(serverCreatedAt);
            }
            _artistProfile = artist;
            _chatPlan = serverChatPlan;
            _chatAllowance = serverChatAllowance;
            _purchasedPlans = plans;
            if (dbListingPlans.isNotEmpty) {
              _availableListingPlans = dbListingPlans;
            }
          });

          // Sync storage
          await storage.setString('user_name', _userName);
          await storage.setString('user_email', _userEmail);
          final serverRole = (profile['role'] as String? ?? '').toLowerCase();
          final isServerAdmin = serverRole.contains('admin') ||
              profile['is_admin'] == true ||
              _userEmail.toLowerCase().contains('admin') ||
              _userEmail.toLowerCase().trim() == 'admin@artistdubai.com';
          if (serverRole.isNotEmpty) {
            await storage.setString('user_role', serverRole);
          }
          await storage.setBool('is_admin', isServerAdmin);
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
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
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
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
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
    final storedAdmin = storage.getBool('is_admin') ?? false;
    final storedRole = (storage.getString('user_role') ?? '').toLowerCase();
    final lowerEmail = _userEmail.toLowerCase().trim();
    final isAdmin = storedAdmin ||
        storedRole.contains('admin') ||
        lowerEmail.contains('admin') ||
        lowerEmail == 'admin@artistdubai.com' ||
        lowerEmail == 'admin@dubaiart.ae';
    final l10n = AppLocalizations.of(context);
    final rh = ResponsiveHelper.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: const Color(0xFF6B1C9B),
      appBar: const AppTopBar(backgroundColor: Colors.white),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: rh.contentMaxWidth),
            child: Column(
          children: [
            // "Account Settings" Sub-Header with Back Arrow & Home Action
            Container(
              padding: EdgeInsets.symmetric(horizontal: rh.horizontalPadding, vertical: 8),
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
                  padding: EdgeInsets.symmetric(horizontal: rh.horizontalPadding, vertical: rh.verticalPadding),
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
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
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
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
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
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (isAdmin) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFD8B4FE), width: 1.5),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x126A2777),
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF6A2777), Color(0xFF9333EA)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.admin_panel_settings_rounded, size: 22, color: Colors.white),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isArabic ? 'لوحة تحكم المسؤول' : 'Admin Control Center',
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFAF5FF),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFFD8B4FE)),
                                        ),
                                        child: Text(
                                          isArabic ? 'صلاحيات المشرف مفعلة' : 'Executive Administrator Role',
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF7E22CE),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              isArabic
                                  ? 'وصول كامل لإدارة الفنانين والفعاليات والمعارض والمستخدمين والإعدادات.'
                                  : 'Full access to manage Artists, Events, Galleries, Users, Masters, and System Configuration.',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6A2777),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.dashboard_customize_rounded, size: 18),
                                label: Text(
                                  isArabic ? 'فتح لوحة تحكم المسؤول' : 'Open Admin Dashboard',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                onPressed: () => context.push(RouteNames.adminDashboard),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
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
                                const SizedBox(width: 12),
                                OutlinedButton.icon(
                                  onPressed: () => context.push(RouteNames.adminDashboard),
                                  icon: const Icon(Icons.admin_panel_settings_outlined, size: 16, color: Color(0xFF6A2777)),
                                  label: Text(
                                    isArabic ? 'بوابة المسؤول' : 'Admin Portal',
                                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF6A2777)),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFFD8B4FE)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                ),
                              ],
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

                      // Card: Purchased Plans & Subscriptions
                      _buildPurchasedPlansCard(rh, l10n),
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
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          isArabic
                              ? '${l10n.appName} · الإصدار 1.0.0'
                              : '${l10n.appName} · v1.0.0',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.85),
                            letterSpacing: isArabic ? 0.0 : 0.4,
                          ),
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

  Widget _buildPurchasedPlansCard(ResponsiveHelper rh, AppLocalizations l10n) {
    final hasPurchasedPlans = _purchasedPlans.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              const Icon(Icons.workspace_premium_rounded, size: 22, color: Color(0xFF5E227A)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Purchased Plans & Subscriptions'.trData(context),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: hasPurchasedPlans ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasPurchasedPlans ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                      size: 13,
                      color: hasPurchasedPlans ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasPurchasedPlans ? 'ACTIVE'.trData(context) : 'NO PLANS'.trData(context),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: hasPurchasedPlans ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Review your active platform membership, published events, and gallery packages'.trData(context),
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 18),

          if (!hasPurchasedPlans) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.workspace_premium_outlined, size: 26, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No Active Plans'.trData(context),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'You do not have any purchased membership or publishing plans. Explore our listing packages to promote your art, exhibitions, or galleries.'
                        .trData(context),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
                  ),
                ],
              ),
            ),
          ] else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _purchasedPlans.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final p = _purchasedPlans[index];
                final title = p['item_title']?.toString() ?? p['plan_name']?.toString() ?? 'Listing Package';
                final planName = p['plan_name']?.toString() ?? 'Publishing Plan';
                final price = p['price']?.toString() ?? 'Paid';
                final status = (p['status']?.toString() ?? 'Active').trim();
                final isExpired = p['is_expired'] == true ||
                    (p['days_left'] != null && (p['days_left'] as num) <= 0) ||
                    status.toLowerCase() == 'expired';
                final isCancelled = status.toLowerCase() == 'cancelled';
                final isActive = !isExpired && !isCancelled &&
                    (status.toLowerCase() == 'active' || status.toLowerCase() == 'paid');
                final daysLeft = p['days_left']?.toString();
                final expiryDate = p['expiry_date']?.toString().split(' ').first ?? '';
                final startDate = p['start_date']?.toString().split(' ').first ?? '';
                final paymentMethod = p['payment_method']?.toString() ?? '';
                final features = p['features'] is List
                    ? (p['features'] as List).map((f) => f.toString()).toList()
                    : <String>[];
                final itemType = (p['item_type'] ?? 'artist').toString().toLowerCase();

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive ? const Color(0xFFC7D2FE) : const Color(0xFFE2E8F0),
                      width: isActive ? 1.4 : 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isActive ? const Color(0xFFEDE9FE) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              itemType.contains('gallery')
                                  ? Icons.apartment_outlined
                                  : (itemType.contains('event')
                                      ? Icons.celebration_outlined
                                      : Icons.brush_outlined),
                              color: const Color(0xFF5E227A),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E1E1E),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$planName • $price',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF5E227A),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFFDCFCE7)
                                  : (isExpired ? const Color(0xFFFEE2E2) : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              (isActive ? 'ACTIVE' : (isExpired ? 'EXPIRED' : status)).toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isActive
                                    ? const Color(0xFF16A34A)
                                    : (isExpired ? const Color(0xFFDC2626) : const Color(0xFF64748B)),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Expiry & Validity info
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isActive ? Icons.timer_outlined : Icons.event_busy_outlined,
                              size: 14,
                              color: isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                isActive && daysLeft != null
                                    ? '$daysLeft days remaining'.trData(context) +
                                        (expiryDate.isNotEmpty ? ' (until $expiryDate)' : '')
                                    : (isExpired
                                        ? 'Expired on $expiryDate'.trData(context)
                                        : 'Registered: $startDate'.trData(context)),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: isActive ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                                ),
                              ),
                            ),
                            if (paymentMethod.isNotEmpty)
                              Text(
                                paymentMethod,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Features summary if present
                      if (features.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: features.take(3).map((f) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check, size: 10, color: Color(0xFF5E227A)),
                                  const SizedBox(width: 3),
                                  Text(
                                    f.trData(context),
                                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF475569)),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      // Actions: Renew / Extend & Cancel
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 34,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF5E227A),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                                onPressed: () {
                                  context.push(
                                    RouteNames.planPayment,
                                    extra: {
                                      'isPlanPurchase': true,
                                      'itemType': itemType,
                                      'planName': planName,
                                      'planPeriod': p['billing_cycle'] ?? '30-Day Listing',
                                      'planAmount': price,
                                      'amount': price,
                                      'features': features,
                                    },
                                  ).then((_) => _loadUserProfile());
                                },
                                icon: const Icon(Icons.refresh_rounded, size: 14),
                                label: Text(
                                  'Renew / Extend'.trData(context),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                          if (isActive && p['id'] != null && p['id'] != 0) ...[
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 34,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFEF4444),
                                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                                onPressed: () => _confirmCancelPlan(p),
                                child: Text(
                                  'Cancel'.trData(context),
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],

          const SizedBox(height: 18),

          // Action Buttons: Browse Plans & Change Membership
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
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    onPressed: () => context.push(RouteNames.listingPlans).then((_) => _loadUserProfile()),
                    icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                    label: Text(
                      'Browse All Plans'.trData(context),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    onPressed: _showUpgradeMembershipSheet,
                    icon: const Icon(Icons.tune_rounded, size: 16),
                    label: Text(
                      'Change Plan'.trData(context),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmCancelPlan(Map<String, dynamic> plan) {
    final planId = plan['id'];
    final planName = plan['plan_name']?.toString() ?? 'Plan';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Cancel Subscription?'.trData(context),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          'Are you sure you want to cancel $planName? You will maintain access until your remaining period ends.'.trData(context),
          style: const TextStyle(fontSize: 13.5, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Keep Plan'.trData(context),
              style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final id = int.tryParse(planId?.toString() ?? '') ?? 0;
              if (id > 0) {
                await sl<ApiService>().cancelUserPlan(
                  planId: id,
                  email: _userEmail,
                );
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$planName has been cancelled.'.trData(context)),
                    backgroundColor: const Color(0xFFEF4444),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                _loadUserProfile();
              }
            },
            child: Text(
              'Confirm Cancel'.trData(context),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showUpgradeMembershipSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Choose Your Plan'.trData(context),
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
                          onPressed: () => Navigator.pop(bottomSheetContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Upgrade your account to unlock higher messaging limits (current allowance: $_chatAllowance/mo).'
                          .trData(context),
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 16),
                    Builder(
                      builder: (context) {
                        // Build active plan options combining baseline memberships and database listing plans
                        final List<Map<String, dynamic>> planTiles = [];

                        // 1. Core Platform Plans
                        planTiles.add({
                          'title': 'Basic (Free)',
                          'price': 'Free Forever'.trData(context),
                          'messages': '10 Inquiries / Month'.trData(context),
                          'badge': 'Standard'.trData(context),
                          'allowance': 10,
                          'amount': 'Free',
                          'period': 'Free Forever',
                          'item_type': 'artist',
                          'features': ['10 Monthly Inquiries', 'Directory Browsing', 'Basic Profile'],
                        });
                        planTiles.add({
                          'title': 'Pro Artist',
                          'price': 'AED 99 / Month'.trData(context),
                          'messages': '50 Inquiries / Month'.trData(context),
                          'badge': 'Popular'.trData(context),
                          'allowance': 50,
                          'amount': 'AED 99',
                          'period': 'Monthly Plan (30 Days)',
                          'item_type': 'artist',
                          'features': [
                            '50 Monthly Artist Inquiries',
                            'Verified Dubai Art Directory Profile',
                            'Direct Collector & Curator Messaging'
                          ],
                        });
                        planTiles.add({
                          'title': 'VIP Unlimited',
                          'price': 'AED 299 / Month'.trData(context),
                          'messages': 'Unlimited Inquiries'.trData(context),
                          'badge': 'Best Value'.trData(context),
                          'allowance': 9999,
                          'amount': 'AED 299',
                          'period': 'Monthly Plan (30 Days)',
                          'item_type': 'artist',
                          'features': [
                            'Unlimited Monthly Inquiries',
                            'VIP Featured Artist Placement',
                            'Priority Support & Curated Connections'
                          ],
                        });

                        // 2. Dynamically add active Admin Master listing plans from MySQL
                        for (final lp in _availableListingPlans) {
                          if (!lp.isActive) continue;
                          final alreadyIncluded = planTiles.any((p) => (p['title'] as String).toLowerCase() == lp.title.toLowerCase());
                          if (!alreadyIncluded) {
                            final priceLabel = lp.price.contains('AED') ? lp.price : '${lp.price} AED';
                            planTiles.add({
                              'title': lp.title,
                              'price': '$priceLabel / ${lp.badge}'.trData(context),
                              'messages': lp.description.isNotEmpty ? lp.description.trData(context) : 'Listing Package'.trData(context),
                              'badge': lp.badge.isNotEmpty ? lp.badge.trData(context) : 'Listing'.trData(context),
                              'allowance': 50,
                              'amount': priceLabel,
                              'period': lp.badge.isNotEmpty ? lp.badge : '30-Day Listing',
                              'item_type': lp.itemType,
                              'features': lp.features,
                            });
                          }
                        }

                        return ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.55,
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              children: planTiles.map((pt) {
                                final title = pt['title'] as String;
                                final price = pt['price'] as String;
                                final messages = pt['messages'] as String;
                                final badge = pt['badge'] as String;
                                final isCurrent = _chatPlan.toLowerCase() == title.toLowerCase();

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10.0),
                                  child: _buildPlanOptionTile(
                                    title: title,
                                    price: price,
                                    messages: messages,
                                    badge: badge,
                                    isCurrent: isCurrent,
                                    onSelect: () => _handleSelectDynamicPlan(pt, bottomSheetContext),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(bottomSheetContext);
                        context.push(RouteNames.listingPlans).then((_) => _loadUserProfile());
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF5E227A),
                        side: const BorderSide(color: Color(0xFF5E227A), width: 1.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.view_carousel_outlined, size: 18),
                      label: Text(
                        'Browse Event & Gallery Listing Plans'.trData(context),
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleSelectDynamicPlan(Map<String, dynamic> planData, BuildContext sheetCtx) async {
    Navigator.pop(sheetCtx);
    final String planName = planData['title'] as String;
    final int maxAllowance = (planData['allowance'] as num?)?.toInt() ?? 50;

    if (planName.toLowerCase() == _chatPlan.toLowerCase()) return;

    if (planName == 'Basic (Free)' || (planData['amount']?.toString().toLowerCase().contains('free') ?? false)) {
      final success = await sl<ChatService>().upgradePlan(
        planName: planName,
        maxAllowance: maxAllowance,
      );
      if (mounted && success) {
        setState(() {
          _chatPlan = planName;
          _chatAllowance = maxAllowance;
        });
        _loadUserProfile();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Plan updated to $planName successfully!'.trData(context)),
            backgroundColor: const Color(0xFF5E227A),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // For paid plans, redirect directly to PlanPaymentView for professional checkout
    final featuresList = planData['features'] is List
        ? (planData['features'] as List).map((e) => e.toString()).toList()
        : <String>[];

    context.push(
      RouteNames.planPayment,
      extra: {
        'isPlanPurchase': true,
        'itemType': planData['item_type'] ?? 'artist',
        'planName': planName,
        'planPeriod': planData['period'] ?? 'Monthly Plan (30 Days)',
        'planAmount': planData['amount'] ?? planData['price'] ?? 'AED 99',
        'amount': planData['amount'] ?? planData['price'] ?? 'AED 99',
        'features': featuresList,
      },
    ).then((_) => _loadUserProfile());
  }

  Future<void> _handleSelectPlan(String planName, int maxAllowance, BuildContext sheetCtx) async {
    _handleSelectDynamicPlan({
      'title': planName,
      'allowance': maxAllowance,
      'item_type': 'artist',
      'amount': planName == 'Pro Artist' ? 'AED 99' : (planName == 'VIP Unlimited' ? 'AED 299' : 'Free'),
      'period': 'Monthly Plan (30 Days)',
      'features': planName == 'Pro Artist'
          ? [
              '50 Monthly Artist Inquiries',
              'Verified Dubai Art Directory Profile',
              'Direct Collector & Curator Messaging'
            ]
          : [
              'Unlimited Monthly Inquiries',
              'VIP Featured Artist Placement',
              'Priority Support & Curated Connections'
            ],
    }, sheetCtx);
  }

  Widget _buildPlanOptionTile({
    required String title,
    required String price,
    required String messages,
    required String badge,
    required bool isCurrent,
    required VoidCallback onSelect,
  }) {
    return InkWell(
      onTap: isCurrent ? null : onSelect,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isCurrent ? const Color(0xFFF3E8FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent ? const Color(0xFF5E227A) : const Color(0xFFE2E8F0),
            width: isCurrent ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isCurrent ? const Color(0xFF5E227A) : const Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCurrent ? Icons.check : Icons.star_border_rounded,
                color: isCurrent ? Colors.white : const Color(0xFF64748B),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isCurrent ? const Color(0xFF5E227A) : const Color(0xFF1E1E1E),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isCurrent ? const Color(0xFF5E227A) : const Color(0xFF64748B),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    messages,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E1E1E)),
                ),
                if (isCurrent)
                  Text(
                    'Current'.trData(context),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
