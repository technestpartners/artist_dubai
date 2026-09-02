import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/live_sync_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_top_bar.dart';

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
      await storage.setBool('is_logged_in', false);
      await storage.setString('user_email', '');
      await storage.setString('user_name', '');
      await storage.setString('user_created_at', '');
      await storage.setString('auth_token', '');
    } catch (_) {}
    if (mounted) {
      context.go(RouteNames.home);
    }
  }

  void _showChangePasswordModal() {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
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
                // Header with Close Button (Matching Screenshot media_1787735877633.png)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Change Password',
                      style: TextStyle(
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
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Enter your new password. Make sure it\'s secure and at least 6 characters long.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),

                // New Password
                const Text(
                  'New Password',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Enter new password',
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
                const Text(
                  'Confirm New Password',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Confirm new password',
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
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
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
                          final confirmPass = confirmPasswordController.text.trim();

                          if (newPass.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Password must be at least 6 characters.'),
                                backgroundColor: Color(0xFFEF4444),
                              ),
                            );
                            return;
                          }
                          if (newPass != confirmPass) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Passwords do not match.'),
                                backgroundColor: Color(0xFFEF4444),
                              ),
                            );
                            return;
                          }

                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.pop(context);
                          final success = await sl<ApiService>().changePassword(
                            email: _userEmail,
                            newPassword: newPass,
                          );

                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Password updated successfully!'
                                      : 'Failed to update password.',
                                ),
                                backgroundColor:
                                    success ? const Color(0xFF6A2777) : const Color(0xFFEF4444),
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'Update Password',
                          style: TextStyle(
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
      builder: (context) {
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
                    const Text(
                      'Edit Profile Details',
                      style: TextStyle(
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
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Update your full display name across Artist Dubai.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Full Name',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Enter your full name',
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
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
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
                              const SnackBar(
                                content: Text('Full name cannot be empty.'),
                                backgroundColor: Color(0xFFEF4444),
                              ),
                            );
                            return;
                          }

                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.pop(context);
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
                                const SnackBar(
                                  content: Text('Profile updated successfully!'),
                                  backgroundColor: Color(0xFF6A2777),
                                ),
                              );
                            }
                          } else {
                            if (mounted) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to update profile.'),
                                  backgroundColor: Color(0xFFEF4444),
                                ),
                              );
                            }
                          }
                        },
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(
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
      builder: (context) {
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
                // Header (Matching Screenshot media_1787735895539.png)
                const Text(
                  'Are you absolutely sure?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'This action cannot be undone. This will permanently delete your account and remove all your data from our servers. This includes:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
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
                    _BulletPointText('All your bookings and event history'),
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
                      Navigator.pop(context);
                      await sl<ApiService>().deleteAccount(_userEmail);
                      _onSignOut();
                      if (mounted) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Account deleted successfully.'),
                            backgroundColor: Color(0xFFEF4444),
                          ),
                        );
                      }
                    },
                    child: const Text(
                      'Yes, delete my account',
                      style: TextStyle(
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
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
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
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      appBar: const AppTopBar(backgroundColor: Colors.white),
      body: SafeArea(
        child: Column(
          children: [
            // Page Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Color(0xFF1E1E1E),
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
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Account Settings',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E1E1E),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFFE2E8F0),
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
                      color: Color(0xFF1E1E1E),
                    ),
                    label: const Text(
                      'Home',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

            // Main Body Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card 1: Account Information (Dynamic from MySQL)
                    _buildSectionCard(
                      icon: Icons.person_outline,
                      title: 'Account Information',
                      subtitle: 'Manage your account settings and preferences',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('Email', _userEmail.isNotEmpty ? _userEmail : 'No email provided'),
                          const SizedBox(height: 14),
                          _buildInfoRow('Member Since', _memberSince.isNotEmpty ? _memberSince : 'Recently Joined'),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: _buildInfoRow('Full Name', _userName.isNotEmpty ? _userName : 'User'),
                              ),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFF6A2777)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                ),
                                onPressed: _showEditProfileModal,
                                icon: const Icon(Icons.edit_outlined, size: 15, color: Color(0xFF6A2777)),
                                label: const Text(
                                  'Edit',
                                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF6A2777)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card 2: Artist Profile (Dynamic from MySQL)
                    _buildSectionCard(
                      icon: Icons.palette_outlined,
                      title: 'Artist Profile',
                      subtitle: _artistProfile != null
                          ? 'Your active artist profile details on Artist Dubai'
                          : 'Create your artist profile to showcase your work',
                      child: _artistProfile != null
                          ? Column(
                              children: [
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 26,
                                      backgroundColor: const Color(0xFFF3E8FF),
                                      backgroundImage: _artistProfile!['avatar_url'] != null && _artistProfile!['avatar_url'].toString().isNotEmpty
                                          ? CachedNetworkImageProvider(_artistProfile!['avatar_url'].toString())
                                          : null,
                                      child: _artistProfile!['avatar_url'] == null || _artistProfile!['avatar_url'].toString().isEmpty
                                          ? const Icon(Icons.person, color: Color(0xFF6A2777), size: 26)
                                          : null,
                                    ),
                                    const SizedBox(width: 14),
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
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  height: 38,
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF6A2777),
                                      side: const BorderSide(color: Color(0xFF6A2777), width: 1.2),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () => context.push(RouteNames.artists),
                                    icon: const Icon(Icons.visibility_outlined, size: 16),
                                    label: const Text('View in Artists Directory', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
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
                                const Text(
                                  'No Artist Profile',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E1E1E),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Create your artist profile to be discoverable on the platform and receive booking requests.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
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
                                      backgroundColor: const Color(0xFF6A2777),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                      ),
                                    ),
                                    onPressed: () => context.push(RouteNames.artistRegistration),
                                    child: const Text(
                                      'Create Artist Profile',
                                      style: TextStyle(
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
                      title: 'Account Actions',
                      subtitle: 'Sign out or delete your account',
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
                              label: const Text(
                                'Change Password',
                                style: TextStyle(
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
                              label: const Text(
                                'Sign Out',
                                style: TextStyle(
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
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: const Text(
                                'Delete Account',
                                style: TextStyle(
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
                              text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                  height: 1.4,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Note: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E1E1E),
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        'Account deletion requests are processed manually for security reasons. After clicking "Delete Account", you\'ll be signed out and our team will process your request within 7 business days. You\'ll receive a confirmation email once the deletion is complete.',
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
                  title,
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
            subtitle,
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
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E1E1E),
          ),
        ),
      ],
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
            text,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
        ),
      ],
    );
  }
}
