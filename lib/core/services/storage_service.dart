import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class StorageService {
  Future<void> setString(String key, String value);
  String? getString(String key);
  Future<void> setBool(String key, bool value);
  bool? getBool(String key);
  Future<void> remove(String key);
  Future<void> clear();
  Future<void> clearAuthSession();

  // Secure Storage
  Future<void> writeSecure(String key, String value);
  Future<String?> readSecure(String key);
  Future<void> deleteSecure(String key);
}

class StorageServiceImpl implements StorageService {
  final SharedPreferences prefs;
  final FlutterSecureStorage secureStorage;

  static const String keyAuthToken = 'auth_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyHasCompletedOnboarding = 'has_completed_onboarding';

  StorageServiceImpl({required this.prefs, required this.secureStorage});

  @override
  Future<void> setString(String key, String value) =>
      prefs.setString(key, value);

  @override
  String? getString(String key) => prefs.getString(key);

  @override
  Future<void> setBool(String key, bool value) => prefs.setBool(key, value);

  @override
  bool? getBool(String key) => prefs.getBool(key);

  @override
  Future<void> remove(String key) => prefs.remove(key);

  @override
  Future<void> clear() => prefs.clear();

  @override
  Future<void> clearAuthSession() async {
    await prefs.setBool('is_logged_in', false);
    await prefs.setBool('is_admin', false);
    await prefs.remove('user_id');
    await prefs.remove('user_role');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_created_at');
    await prefs.remove('auth_token');
    await prefs.setBool('has_artist_profile', false);
    await prefs.remove('artist_profile_id');
    await prefs.remove('artist_profile_name');
    await secureStorage.delete(key: keyAuthToken);
    await secureStorage.delete(key: keyRefreshToken);
  }

  @override
  Future<void> writeSecure(String key, String value) =>
      secureStorage.write(key: key, value: value);

  @override
  Future<String?> readSecure(String key) => secureStorage.read(key: key);

  @override
  Future<void> deleteSecure(String key) => secureStorage.delete(key: key);
}
