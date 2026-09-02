import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
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

  void _showChangePasswordDialog() {
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
                            const Text(
                              'Change Password',
                              style: TextStyle(
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
                        const Text(
                          'Enter your new password. Make sure it\'s secure and at least 6 characters long.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'New Password',
                          style: TextStyle(
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
                            hintText: 'Enter new password',
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
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Confirm New Password',
                          style: TextStyle(
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
                            hintText: 'Confirm new password',
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
                              return 'Passwords do not match';
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
                              child: const Text('Cancel', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
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
                                                    ? 'Password updated successfully in MySQL!'
                                                    : 'Failed to update password. Please check backend connection.',
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
                                  : const Text('Update Password', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
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
                  const SizedBox(height: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: const [
                      Text('Your artist profile (if any)', style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.5)),
                      Text('All your artwork images', style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.5)),
                      Text('Your account information', style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.5)),
                      Text('All your bookings and event history', style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.5)),
                      Text('Any saved preferences', style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.5)),
                      Text('Your liked artists and galleries', style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.5)),
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
                          const SnackBar(
                            content: Text('Account deleted successfully from MySQL.'),
                            backgroundColor: Color(0xFFEF4444),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(milliseconds: 2000),
                          ),
                        );
                      }
                    },
                    child: const Text('Yes, delete my account', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
                    child: const Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      appBar: const AppTopBar(backgroundColor: Colors.white),
      body: SafeArea(
        child: Column(
          children: [
            // "Account Settings" Sub-Header with Back Arrow & Home Action
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(RouteNames.home);
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      'Account Settings',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => context.go(RouteNames.home),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        children: const [
                          Icon(Icons.home_outlined, color: Colors.black87, size: 20),
                          SizedBox(width: 4),
                          Text(
                            'Home',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

            // Main Body Scrollable List
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF5E227A),
                onRefresh: _loadUserProfile,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  children: [
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
                            const Text(
                              'Please sign in to manage your account settings.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 15, color: Color(0xFF64748B)),
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
                              child: const Text('Sign In', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
                              children: const [
                                Icon(Icons.person_outline, size: 22, color: Color(0xFF1E1E1E)),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Account Information',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E1E1E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Manage your account settings and preferences',
                              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 20),
                            _buildAccountField('Email', _userEmail.isNotEmpty ? _userEmail : 'No email provided'),
                            const SizedBox(height: 16),
                            _buildAccountField('Member Since', _memberSince.isNotEmpty ? _memberSince : 'Recently Joined'),
                            const SizedBox(height: 16),
                            _buildAccountField('Full Name', _userName.isNotEmpty ? _userName : 'User'),
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
                              children: const [
                                Icon(Icons.palette_outlined, size: 22, color: Color(0xFF1E1E1E)),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Artist Profile',
                                    style: TextStyle(
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
                                  ? 'Your active artist profile details on Artist Dubai'
                                  : 'Create your artist profile to showcase your work',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 20),
                            if (_artistProfile != null) ...[
                              // Active Artist Profile View
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: const Color(0xFFF3E8FF),
                                    backgroundImage: _artistProfile!['avatar_url'] != null && _artistProfile!['avatar_url'].toString().isNotEmpty
                                        ? CachedNetworkImageProvider(_artistProfile!['avatar_url'].toString())
                                        : null,
                                    child: _artistProfile!['avatar_url'] == null || _artistProfile!['avatar_url'].toString().isEmpty
                                        ? const Icon(Icons.person, color: Color(0xFF6A2777), size: 28)
                                        : null,
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
                              SizedBox(
                                width: double.infinity,
                                height: 42,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF5E227A),
                                    side: const BorderSide(color: Color(0xFF5E227A), width: 1.2),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () => context.push(RouteNames.artists),
                                  icon: const Icon(Icons.visibility_outlined, size: 18),
                                  label: const Text('View in Artists Directory', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
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
                                    const Text(
                                      'No Artist Profile',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E1E1E),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        'Create your artist profile to be discoverable on the platform and receive booking requests.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
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
                                      child: const Text(
                                        'Create Artist Profile',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
                              children: const [
                                Icon(Icons.shield_outlined, size: 22, color: Color(0xFF1E1E1E)),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Account Actions',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E1E1E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Sign out or delete your account',
                              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
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
                                label: const Text(
                                  'Change Password',
                                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
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
                                label: const Text(
                                  'Sign Out',
                                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
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
                                label: const Text(
                                  'Delete Account',
                                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
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
                              child: const Text(
                                'Note: Account deletion permanently removes your account and all associated data from the MySQL database.',
                                style: TextStyle(
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
                          style: TextStyle(fontSize: 12, color: Colors.grey.withValues(alpha: 0.5)),
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
