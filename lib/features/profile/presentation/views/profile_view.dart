import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/live_sync_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_cached_image.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/utils/share_helper.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/utils/data_translator.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  String _userName = '';
  String _userEmail = '';
  String _memberSince = '';
  Map<String, dynamic>? _artistProfile;
  List<Map<String, dynamic>> _userActivePlans = [];
  StreamSubscription<List<dynamic>>? _liveSub;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _liveSub = sl<LiveSyncService>().artistsStream.listen((_) {
      if (mounted) _loadUserProfile();
    });
  }

  @override
  void dispose() {
    _liveSub?.cancel();
    super.dispose();
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

    _loadUserPlans();

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

          await storage.setString('user_name', _userName);
          await storage.setString('user_email', _userEmail);
          if (serverCreatedAt != null) {
            await storage.setString('user_created_at', serverCreatedAt);
          }
        }
      } catch (_) {}
    }
  }

  Future<void> _loadUserPlans() async {
    try {
      final storage = sl<StorageService>();
      final email = storage.getString('user_email') ?? '';
      List<Map<String, dynamic>> activeList = [];
      if (email.isNotEmpty) {
        try {
          final plans = await sl<ApiService>().getUserPlans(email: email);
          activeList = plans.where((p) {
            final status = (p['status'] ?? '').toString().toLowerCase();
            final isExpired =
                p['is_expired'] == true ||
                (p['days_left'] != null && (p['days_left'] as num) <= 0);
            return status == 'active' && !isExpired;
          }).toList();
        } catch (_) {}
      }

      // Merge local active plans from StorageService
      for (final type in ['event', 'gallery', 'chat', 'artist', 'art_centre', 'plan']) {
        final local = storage.getString('active_plan_$type');
        if (local != null && local.isNotEmpty) {
          final already = activeList.any((p) =>
              (p['plan_name'] ?? '').toString().toLowerCase() == local.toLowerCase() ||
              (p['item_type'] ?? '').toString().toLowerCase() == type);
          if (!already) {
            activeList.add({
              'plan_name': local,
              'item_type': type,
              'status': 'active',
              'price': storage.getString('last_payment_amount') ?? 'Paid',
            });
          }
        }
      }
      final chatPlan = storage.getString('chat_plan') ?? storage.getString('chat_plan_name');
      if (chatPlan != null && chatPlan.isNotEmpty && !chatPlan.toLowerCase().contains('free')) {
        final already = activeList.any((p) =>
            (p['item_type'] ?? '').toString().toLowerCase() == 'chat' ||
            (p['plan_name'] ?? '').toString().toLowerCase() == chatPlan.toLowerCase());
        if (!already) {
          activeList.add({
            'plan_name': chatPlan,
            'item_type': 'chat',
            'status': 'active',
            'price': 'Paid',
          });
        }
      }

      if (mounted) {
        setState(() {
          _userActivePlans = activeList;
        });
      }
    } catch (_) {}
  }

  String _formatMemberSince(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      return 'Recently Joined';
    }
    try {
      final dt = DateTime.tryParse(dateStr.replaceAll(' ', 'T'));
      if (dt != null) {
        const months = [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December',
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

  void _onShareProfile() {
    final artistId = _artistProfile?['id']?.toString();
    final name = _artistProfile?['name']?.toString() ?? _userName;
    final category = _artistProfile?['category']?.toString();
    final avatar = _artistProfile?['avatar_url']?.toString();

    ShareHelper.shareProfile(
      context: context,
      name: name,
      artistId: artistId,
      category: category,
      avatarUrl: avatar,
      email: _userEmail,
    );
  }

  void _showChangePasswordModal() {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Close Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Change Password'.trData(context),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Color(0xFF64748B),
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(dialogContext),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Enter your new password. Make sure it\'s secure and at least 6 characters long.'
                      .trData(context),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),

                // New Password
                Text(
                  'New Password'.trData(context),
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter new password'.trData(context),
                    hintStyle: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13.5,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF5E227A),
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF5E227A),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Confirm New Password
                Text(
                  'Confirm New Password'.trData(context),
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Confirm new password'.trData(context),
                    hintStyle: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13.5,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons: Cancel & Update Password
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: 42,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Color(0xFF333333),
                            width: 1.0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                        ),
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text(
                          'Cancel'.trData(context),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E1E1E),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 42,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A2777),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                        ),
                        onPressed: () async {
                          final newPass = newPasswordController.text.trim();
                          final confirmPass =
                              confirmPasswordController.text.trim();

                          if (newPass.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Password must be at least 6 characters.'
                                      .trData(context),
                                ),
                                backgroundColor: const Color(0xFFEF4444),
                              ),
                            );
                            return;
                          }
                          if (newPass != confirmPass) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Passwords do not match.'.trData(context),
                                ),
                                backgroundColor: const Color(0xFFEF4444),
                              ),
                            );
                            return;
                          }

                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.pop(dialogContext);
                          final success = await sl<ApiService>().changePassword(
                            email: _userEmail,
                            newPassword: newPass,
                          );

                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  (success
                                          ? 'Password updated successfully!'
                                          : 'Failed to update password.')
                                      .trData(context),
                                ),
                                backgroundColor:
                                    success
                                        ? const Color(0xFF6A2777)
                                        : const Color(0xFFEF4444),
                              ),
                            );
                          }
                        },
                        child: Text(
                          'Update Password'.trData(context),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditProfileModal() {
    final nameController = TextEditingController(text: _userName);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Profile Details'.trData(context),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Color(0xFF64748B),
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(dialogContext),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Update your full display name across Artist Dubai.'.trData(
                    context,
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Full Name'.trData(context),
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter your full name'.trData(context),
                    hintStyle: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13.5,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF5E227A),
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF5E227A),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: 42,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Color(0xFF333333),
                            width: 1.0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                        ),
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text(
                          'Cancel'.trData(context),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E1E1E),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 42,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A2777),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                        ),
                        onPressed: () async {
                          final newName = nameController.text.trim();
                          if (newName.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Full name cannot be empty.'.trData(context),
                                ),
                                backgroundColor: const Color(0xFFEF4444),
                              ),
                            );
                            return;
                          }

                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.pop(dialogContext);
                          final success = await sl<ApiService>().updateProfile(
                            email: _userEmail,
                            fullName: newName,
                          );

                          if (success) {
                            final storage = sl<StorageService>();
                            await storage.setString('user_name', newName);
                            if (mounted) {
                              setState(() {
                                _userName = newName;
                              });
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Profile updated successfully!'.trData(
                                      context,
                                    ),
                                  ),
                                  backgroundColor: const Color(0xFF6A2777),
                                ),
                              );
                            }
                          } else {
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to update profile.'.trData(context),
                                  ),
                                  backgroundColor: const Color(0xFFEF4444),
                                ),
                              );
                            }
                          }
                        },
                        child: Text(
                          'Save Changes'.trData(context),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteAccountModal() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header
                Text(
                  'Are you absolutely sure?'.trData(context),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'This action cannot be undone. This will permanently delete your account and remove all your data from our servers. This includes:'
                      .trData(context),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),

                // Bullets List
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _BulletPointText('Your artist profile (if any)'),
                    SizedBox(height: 6),
                    _BulletPointText('All your artwork images'),
                    SizedBox(height: 6),
                    _BulletPointText('Your account information'),
                    SizedBox(height: 6),
                    _BulletPointText('All your event history'),
                    SizedBox(height: 6),
                    _BulletPointText('Any saved preferences'),
                    SizedBox(height: 6),
                    _BulletPointText('Your liked artists and galleries'),
                  ],
                ),
                const SizedBox(height: 24),

                // Action Buttons: Yes, delete my account & Cancel
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(dialogContext);
                      await sl<ApiService>().deleteAccount(_userEmail);
                      _onSignOut();
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Account deleted successfully.'.trData(context),
                            ),
                            backgroundColor: const Color(0xFFEF4444),
                          ),
                        );
                      }
                    },
                    child: Text(
                      'Yes, delete my account'.trData(context),
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFF333333),
                        width: 1.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(
                      'Cancel'.trData(context),
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rh = ResponsiveHelper.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF6B1C9B),
      appBar: const AppTopBar(backgroundColor: Colors.white),
      body: SafeArea(
        child: Column(
          children: [
            // Page Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.18),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go(RouteNames.home);
                            }
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Account Settings'.trData(context),
                            style: TextStyle(
                              fontSize: rh.sp(18),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (rh.isCompact) ...[
                    IconButton(
                      icon: const Icon(
                        Icons.share_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _onShareProfile,
                      tooltip: 'Share'.trData(context),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(6),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(
                        Icons.home_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => context.go(RouteNames.home),
                      tooltip: 'Home'.trData(context),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(6),
                    ),
                  ] else ...[
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                      ),
                      onPressed: _onShareProfile,
                      icon: const Icon(
                        Icons.share_outlined,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: Text(
                        'Share'.trData(context),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                      ),
                      onPressed: () => context.go(RouteNames.home),
                      icon: const Icon(
                        Icons.home_outlined,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: Text(
                        'Home'.trData(context),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Main Body Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: rh.horizontalPadding,
                  vertical: 16.0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: rh.contentMaxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card 1: Account Information (Dynamic from MySQL)
                        _buildSectionCard(
                          icon: Icons.person_outline,
                          title: 'Account Information'.trData(context),
                          subtitle:
                              'Manage your account settings and preferences'
                                  .trData(context),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow(
                                'Email'.trData(context),
                                _userEmail.isNotEmpty
                                    ? _userEmail
                                    : 'No email provided'.trData(context),
                              ),
                              const SizedBox(height: 14),
                              _buildInfoRow(
                                'Member Since'.trData(context),
                                _memberSince.isNotEmpty
                                    ? _memberSince
                                    : 'Recently Joined'.trData(context),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: _buildInfoRow(
                                      'Full Name'.trData(context),
                                      _userName.isNotEmpty
                                          ? _userName
                                          : 'User'.trData(context),
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: Color(0xFF6A2777),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                    ),
                                    onPressed: _showEditProfileModal,
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 15,
                                      color: Color(0xFF6A2777),
                                    ),
                                    label: Text(
                                      'Edit'.trData(context),
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF6A2777),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Membership Badges'.trData(context),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (_userActivePlans.isEmpty) ...[
                                    _buildBadgeChip(
                                      icon: Icons.check_circle_outline,
                                      label: 'Registered Member',
                                      color: const Color(0xFF64748B),
                                      bgColor: const Color(0xFFF1F5F9),
                                      borderColor: const Color(0xFFCBD5E1),
                                    ),
                                  ] else ...[
                                    for (final p in _userActivePlans) ...[
                                      _buildPlanBadgeForUserPlan(p),
                                    ],
                                  ],
                                  if (_artistProfile != null) ...[
                                    _buildBadgeChip(
                                      icon: Icons.verified_rounded,
                                      label: 'Verified Artist',
                                      color: const Color(0xFF6A2777),
                                      bgColor: const Color(0xFFF3E8FF),
                                      borderColor: const Color(0xFFD8B4FE),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Card: Active Subscriptions & Listing Plans
                        _buildSectionCard(
                          icon: Icons.workspace_premium_outlined,
                          title: 'Active Subscriptions & Plans'.trData(context),
                          subtitle: _userActivePlans.isNotEmpty
                              ? 'Your active platform plans and publishing coverage'
                                  .trData(context)
                              : 'Manage or subscribe to platform publishing plans'
                                  .trData(context),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_userActivePlans.isNotEmpty) ...[
                                for (final p in _userActivePlans) ...[
                                  _buildUserActivePlanItem(p),
                                  const SizedBox(height: 10),
                                ],
                              ] else ...[
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.info_outline,
                                        color: Color(0xFF64748B),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Unlock unlimited chat messaging, event publishing, and gallery directory listings.'
                                              .trData(context),
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            color: Color(0xFF64748B),
                                            height: 1.35,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              SizedBox(
                                width: double.infinity,
                                height: 42,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF5E227A),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () {
                                    context
                                        .push(RouteNames.listingPlans)
                                        .then((_) {
                                      _loadUserPlans();
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.tune_rounded,
                                    size: 16,
                                  ),
                                  label: Text(
                                    (_userActivePlans.isNotEmpty
                                            ? 'Manage / Browse Listing Plans'
                                            : 'Explore Listing Plans')
                                        .trData(context),
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Card 2: Artist Profile (Dynamic from MySQL)
                        _buildSectionCard(
                          icon: Icons.palette_outlined,
                          title: 'Artist Profile'.trData(context),
                          subtitle:
                              _artistProfile != null
                                  ? 'Your active artist profile details on Artist Dubai'
                                      .trData(context)
                                  : 'Create your artist profile to showcase your work'
                                      .trData(context),
                          child:
                              _artistProfile != null
                                  ? Column(
                                    children: [
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          ClipOval(
                                            child: Container(
                                              width: 52,
                                              height: 52,
                                              color: const Color(0xFFF3E8FF),
                                              child:
                                                  _artistProfile!['avatar_url'] !=
                                                              null &&
                                                          _artistProfile!['avatar_url']
                                                              .toString()
                                                              .isNotEmpty
                                                      ? AppCachedImage(
                                                        imageUrl:
                                                            _artistProfile!['avatar_url']
                                                                .toString(),
                                                        width: 52,
                                                        height: 52,
                                                        fit: BoxFit.cover,
                                                        errorWidget: const Icon(
                                                          Icons.person,
                                                          color: Color(
                                                            0xFF6A2777,
                                                          ),
                                                          size: 26,
                                                        ),
                                                      )
                                                      : const Icon(
                                                        Icons.person,
                                                        color: Color(
                                                          0xFF6A2777,
                                                        ),
                                                        size: 26,
                                                      ),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _artistProfile!['name']
                                                          ?.toString() ??
                                                      _userName,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF1E1E1E),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  _artistProfile!['category']
                                                          ?.toString()
                                                          .trData(context) ??
                                                      'Contemporary Art'.trData(
                                                        context,
                                                      ),
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Color(0xFF6A2777),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  _artistProfile!['location']
                                                          ?.toString()
                                                          .trData(context) ??
                                                      'Dubai, UAE'.trData(
                                                        context,
                                                      ),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF64748B),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: SizedBox(
                                              height: 38,
                                              child: ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(
                                                    0xFF6A2777,
                                                  ),
                                                  foregroundColor: Colors.white,
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                      ),
                                                ),
                                                onPressed: () {
                                                  context.push(
                                                    RouteNames
                                                        .artistRegistration,
                                                    extra: {
                                                      'isEditing': true,
                                                      'artistId':
                                                          _artistProfile!['id']
                                                              ?.toString(),
                                                    },
                                                  );
                                                },
                                                icon: const Icon(
                                                  Icons.edit_outlined,
                                                  size: 15,
                                                ),
                                                label: Text(
                                                  'Edit'.trData(context),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: SizedBox(
                                              height: 38,
                                              child: ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(
                                                    0xFF551478,
                                                  ),
                                                  foregroundColor: Colors.white,
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                      ),
                                                ),
                                                onPressed: _onShareProfile,
                                                icon: const Icon(
                                                  Icons.share_outlined,
                                                  size: 15,
                                                ),
                                                label: Text(
                                                  'Share'.trData(context),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          SizedBox(
                                            height: 38,
                                            width: 44,
                                            child: OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: const Color(
                                                  0xFF6A2777,
                                                ),
                                                side: const BorderSide(
                                                  color: Color(0xFF6A2777),
                                                  width: 1.2,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                padding: EdgeInsets.zero,
                                              ),
                                              onPressed: () {
                                                final id =
                                                    _artistProfile!['id']
                                                        ?.toString();
                                                if (id != null &&
                                                    id.isNotEmpty) {
                                                  context.push('/artist/$id');
                                                } else {
                                                  context.push(
                                                    RouteNames.artists,
                                                  );
                                                }
                                              },
                                              child: const Icon(
                                                Icons.visibility_outlined,
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                  : Column(
                                    children: [
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFF3E8FF),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.palette_outlined,
                                          size: 32,
                                          color: Color(0xFF6A2777),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No Artist Profile'.trData(context),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E1E1E),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Create your artist profile to be discoverable on the platform and showcase your portfolio.'
                                            .trData(context),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF64748B),
                                          height: 1.35,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        height: 40,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF6A2777,
                                            ),
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                            ),
                                          ),
                                          onPressed:
                                              () => context.push(
                                                RouteNames.artistRegistration,
                                              ),
                                          child: Text(
                                            'Create Artist Profile'.trData(
                                              context,
                                            ),
                                            style: const TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                    ],
                                  ),
                        ),
                        const SizedBox(height: 16),

                        // Card 3: Account Actions
                        _buildSectionCard(
                          icon: Icons.shield_outlined,
                          title: 'Account Actions'.trData(context),
                          subtitle: 'Sign out or delete your account'.trData(
                            context,
                          ),
                          child: Column(
                            children: [
                              const SizedBox(height: 6),
                              // Change Password Button
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Color(0xFF333333),
                                      width: 1.0,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: _showChangePasswordModal,
                                  icon: const Icon(
                                    Icons.key_outlined,
                                    size: 18,
                                    color: Color(0xFF1E1E1E),
                                  ),
                                  label: Text(
                                    'Change Password'.trData(context),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E1E1E),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Sign Out Button
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Color(0xFF333333),
                                      width: 1.0,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: _onSignOut,
                                  icon: const Icon(
                                    Icons.logout,
                                    size: 18,
                                    color: Color(0xFF1E1E1E),
                                  ),
                                  label: Text(
                                    'Sign Out'.trData(context),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E1E1E),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Delete Account Button
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFEF4444),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: _showDeleteAccountModal,
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                  ),
                                  label: Text(
                                    'Delete Account'.trData(context),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Note Callout Box
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                      height: 1.4,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Note: '.trData(context),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E1E1E),
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                            'Account deletion requests are processed manually for security reasons. After clicking "Delete Account", you\'ll be signed out and our team will process your request within 7 business days. You\'ll receive a confirmation email once the deletion is complete.'
                                                .trData(context),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: -1),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF1E1E1E)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title.trData(context),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle.trData(context),
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.trData(context),
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 2),
        Text(
          value.trData(context),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E1E1E),
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label.trData(context),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanBadgeForUserPlan(Map<String, dynamic> p) {
    final type = (p['item_type'] ?? '').toString().toLowerCase();
    final name = (p['plan_name'] ?? '').toString();
    if (type == 'chat' || name.toLowerCase().contains('chat')) {
      return _buildBadgeChip(
        icon: Icons.workspace_premium_rounded,
        label: name.isNotEmpty ? name : 'VIP Sender',
        color: const Color(0xFF0F766E),
        bgColor: const Color(0xFFCCFBF1),
        borderColor: const Color(0xFF99F6E4),
      );
    }
    if (type == 'gallery' || name.toLowerCase().contains('gall')) {
      return _buildBadgeChip(
        icon: Icons.museum_outlined,
        label: name.isNotEmpty ? name : 'Gallery Partner',
        color: const Color(0xFF0284C7),
        bgColor: const Color(0xFFE0F2FE),
        borderColor: const Color(0xFFBAE6FD),
      );
    }
    if (type == 'event' || name.toLowerCase().contains('event')) {
      return _buildBadgeChip(
        icon: Icons.event_available_rounded,
        label: name.isNotEmpty ? name : 'Event Host',
        color: const Color(0xFF6A2777),
        bgColor: const Color(0xFFF5E8FF),
        borderColor: const Color(0xFFE9D5FF),
      );
    }
    return _buildBadgeChip(
      icon: Icons.star_rounded,
      label: name.isNotEmpty ? name : 'Active Plan',
      color: const Color(0xFFD97706),
      bgColor: const Color(0xFFFEF3C7),
      borderColor: const Color(0xFFFDE68A),
    );
  }

  Widget _buildUserActivePlanItem(Map<String, dynamic> p) {
    final type = (p['item_type'] ?? '').toString().toLowerCase();
    final name = (p['plan_name'] ?? 'Active Plan').toString();
    final price = p['price']?.toString() ?? 'Covered';

    IconData icon;
    Color iconColor;
    Color iconBg;
    VoidCallback? onAction;
    String actionLabel = '';

    if (type == 'chat' || name.toLowerCase().contains('chat')) {
      icon = Icons.forum_rounded;
      iconColor = const Color(0xFF0F766E);
      iconBg = const Color(0xFFCCFBF1);
      actionLabel = 'Open Chat';
      onAction = () => context.push(RouteNames.artistChat);
    } else if (type == 'gallery' || name.toLowerCase().contains('gall')) {
      icon = Icons.museum_outlined;
      iconColor = const Color(0xFF0284C7);
      iconBg = const Color(0xFFE0F2FE);
      actionLabel = 'Register Gallery';
      onAction = () => context.push(RouteNames.galleryRegistration);
    } else if (type == 'event' || name.toLowerCase().contains('event')) {
      icon = Icons.event_available_rounded;
      iconColor = const Color(0xFF6A2777);
      iconBg = const Color(0xFFF5E8FF);
      actionLabel = 'Create Event';
      onAction = () => context.push(RouteNames.createArtEvent);
    } else {
      icon = Icons.workspace_premium_rounded;
      iconColor = const Color(0xFFD97706);
      iconBg = const Color(0xFFFEF3C7);
      actionLabel = 'View Plans';
      onAction = () => context.push(RouteNames.listingPlans);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name.trData(context),
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1E1E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 11,
                            color: Color(0xFF059669),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Active'.trData(context),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      price.trData(context),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    InkWell(
                      onTap: onAction,
                      child: Text(
                        actionLabel.trData(context),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: iconColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletPointText extends StatelessWidget {
  final String text;
  const _BulletPointText(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '•  ',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
        ),
        Expanded(
          child: Text(
            text.trData(context),
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
        ),
      ],
    );
  }
}
