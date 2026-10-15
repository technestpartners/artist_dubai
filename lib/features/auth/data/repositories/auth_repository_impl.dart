import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/live_sync_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../domain/models/auth_session_model.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiService _apiService;
  final StorageService _storageService;
  final LiveSyncService _liveSyncService;

  AuthRepositoryImpl({
    required ApiService apiService,
    required StorageService storageService,
    required LiveSyncService liveSyncService,
  }) : _apiService = apiService,
       _storageService = storageService,
       _liveSyncService = liveSyncService;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final userData = await _apiService.login(email.trim(), password);
    if (userData == null) {
      throw const ServerException(message: 'User account could not be found.');
    }

    return _persistSessionFromPayload(userData, fallbackEmail: email.trim());
  }

  @override
  Future<AuthSession> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    final res = await _apiService.registerUser(
      name: fullName.trim(),
      email: email.trim(),
      password: password,
      role: role.trim().toLowerCase(),
    );

    if (res == null) {
      throw const ServerException(
        message: 'Registration failed. Please try again.',
      );
    }

    return _persistSessionFromPayload(res, fallbackEmail: email.trim());
  }

  @override
  Future<void> logout() async {
    await _storageService.setBool('is_logged_in', false);
    await _storageService.setBool('is_admin', false);
    await _storageService.remove('user_role');
    await _storageService.remove('user_email');
    await _storageService.remove('user_name');
    await _storageService.remove('user_id');
    await _storageService.remove('auth_token');
    await _storageService.remove('has_artist_profile');
    await _storageService.remove('artist_profile_id');
    await _storageService.remove('artist_profile_name');
    try {
      await _storageService.deleteSecure('auth_token');
    } catch (_) {}

    try {
      _liveSyncService.notifyAuthChanged(false);
    } catch (_) {}
  }

  @override
  Future<AuthSession?> getCachedSession() async {
    final isLoggedIn = _storageService.getBool('is_logged_in') ?? false;
    if (!isLoggedIn) return null;

    final token = _storageService.getString('auth_token') ?? '';
    final email = _storageService.getString('user_email') ?? '';
    final name = _storageService.getString('user_name') ?? '';
    final role = _storageService.getString('user_role') ?? 'user';
    final isAdmin = _storageService.getBool('is_admin') ?? false;
    final idStr = _storageService.getString('user_id');
    final hasArtist = _storageService.getBool('has_artist_profile') ?? false;
    final artistId = _storageService.getString('artist_profile_id');
    final artistName = _storageService.getString('artist_profile_name');

    final user = UserModel(
      id: int.tryParse(idStr ?? '0') ?? 0,
      fullName: name,
      email: email,
      role: role,
      isAdmin: isAdmin,
      token: token,
    );

    return AuthSession(
      user: user,
      token: token,
      isAdmin: isAdmin,
      hasArtistProfile: hasArtist,
      artistProfileId: artistId,
      artistProfileName: artistName,
    );
  }

  @override
  Future<bool> isLoggedIn() async {
    return _storageService.getBool('is_logged_in') ?? false;
  }

  Future<AuthSession> _persistSessionFromPayload(
    Map<String, dynamic> payload, {
    required String fallbackEmail,
  }) async {
    final userMap = payload['user'] as Map<String, dynamic>? ?? {};
    final userEmail =
        (userMap['email'] as String? ?? fallbackEmail).trim().toLowerCase();
    final rawRole = (userMap['role'] as String? ?? 'user').toLowerCase();

    final isAdmin =
        userMap['is_admin'] == true ||
        rawRole == 'admin' ||
        rawRole == 'superadmin' ||
        rawRole == 'super_admin' ||
        userEmail == 'admin@artistdubai.com' ||
        userEmail == 'admin@dubaiart.ae' ||
        userEmail == 'admin@admin.com';

    await _storageService.setBool('is_logged_in', true);
    await _storageService.setBool('is_admin', isAdmin);
    await _storageService.setString('user_role', rawRole);
    await _storageService.setString(
      'user_email',
      userMap['email'] as String? ?? fallbackEmail,
    );
    await _storageService.setString(
      'user_name',
      userMap['full_name'] as String? ?? (isAdmin ? 'Admin' : 'User'),
    );

    if (userMap['created_at'] != null) {
      await _storageService.setString(
        'user_created_at',
        userMap['created_at'].toString(),
      );
    }
    if (userMap['id'] != null) {
      await _storageService.setString('user_id', userMap['id'].toString());
    }

    final token =
        payload['token']?.toString() ?? userMap['token']?.toString() ?? '';
    if (token.isNotEmpty) {
      await _storageService.setString('auth_token', token);
      try {
        await _storageService.writeSecure('auth_token', token);
      } catch (_) {}
    }

    // Artist Profile Hydration
    final dynamic rawArtist =
        payload['artist_profile'] ?? userMap['artist_profile'];
    bool hasArtistProfile = false;
    String? artistId;
    String? artistName;

    if (rawArtist is Map<String, dynamic> && rawArtist['id'] != null) {
      hasArtistProfile = true;
      artistId = rawArtist['id'].toString();
      artistName = rawArtist['name']?.toString();
      await _storageService.setBool('has_artist_profile', true);
      await _storageService.setString('artist_profile_id', artistId);
      if (artistName != null) {
        await _storageService.setString('artist_profile_name', artistName);
      }
    } else {
      await _storageService.setBool('has_artist_profile', false);
      await _storageService.remove('artist_profile_id');
      await _storageService.remove('artist_profile_name');
    }

    // Refresh artist profile in background
    try {
      await _apiService.getMyArtistProfile(forceRefresh: true);
    } catch (_) {}

    // Notify auth state subscribers
    try {
      _liveSyncService.notifyAuthChanged(true);
    } catch (_) {}

    final user = UserModel.fromJson(userMap).copyWith(
      email: userMap['email'] as String? ?? fallbackEmail,
      isAdmin: isAdmin,
      token: token,
    );

    return AuthSession(
      user: user,
      token: token,
      isAdmin: isAdmin,
      hasArtistProfile: hasArtistProfile,
      artistProfileId: artistId,
      artistProfileName: artistName,
    );
  }
}
