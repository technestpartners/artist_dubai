import 'dart:convert';
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

  // Menu Permissions
  bool isMenuPermissionEnabled(String routeName);
  Future<void> setMenuPermissionEnabled(String routeName, bool isEnabled);
  Map<String, bool> getAllMenuPermissions();
  Future<void> saveAllMenuPermissions(Map<String, bool> permissions);

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
  static const String keyMenuPermissions = 'menu_permissions_map';

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
    try {
      await secureStorage
          .delete(key: keyAuthToken)
          .timeout(const Duration(milliseconds: 200), onTimeout: () {});
      await secureStorage
          .delete(key: keyRefreshToken)
          .timeout(const Duration(milliseconds: 200), onTimeout: () {});
    } catch (_) {}
  }

  @override
  Future<void> writeSecure(String key, String value) =>
      secureStorage.write(key: key, value: value);

  @override
  Future<String?> readSecure(String key) => secureStorage.read(key: key);

  @override
  Future<void> deleteSecure(String key) => secureStorage.delete(key: key);

  // --- Menu Permissions Implementation ---
  static const Map<String, bool> _defaultPermissionsMap = {
    '/about-us': true,
    '/artists': true,
    '/government': true,
    '/artist-registration': true,
    '/events': true,
    '/events-competition': true,
    '/galleries': true,
    '/events-photos': true,
    '/gallery-registration': true,
    '/login': true,
    '/ai': true,
  };

  @override
  bool isMenuPermissionEnabled(String routeName) {
    try {
      final raw = prefs.getString(keyMenuPermissions);
      if (raw == null || raw.isEmpty) return true;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final clean = routeName.split('?').first.trim();
      if (clean == '/events-competition' && map.containsKey('/events')) {
        return map['/events'] != false;
      }
      if (clean == '/events' && map.containsKey('/events-competition')) {
        return map['/events-competition'] != false;
      }
      if (map.containsKey(clean)) {
        final val = map[clean];
        return val == true || val == 1 || val == '1' || val == 'true';
      }
      return true;
    } catch (_) {
      return true;
    }
  }

  @override
  Map<String, bool> getAllMenuPermissions() {
    try {
      final raw = prefs.getString(keyMenuPermissions);
      if (raw == null || raw.isEmpty) {
        return Map<String, bool>.from(_defaultPermissionsMap);
      }
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final result = Map<String, bool>.from(_defaultPermissionsMap);
      decoded.forEach((key, value) {
        result[key] = value == true || value == 1 || value == '1' || value == 'true';
      });
      return result;
    } catch (_) {
      return Map<String, bool>.from(_defaultPermissionsMap);
    }
  }

  @override
  Future<void> setMenuPermissionEnabled(String routeName, bool isEnabled) async {
    final current = getAllMenuPermissions();
    final clean = routeName.split('?').first.trim();
    current[clean] = isEnabled;
    if (clean == '/events') {
      current['/events-competition'] = isEnabled;
    } else if (clean == '/events-competition') {
      current['/events'] = isEnabled;
    }
    await saveAllMenuPermissions(current);
  }

  @override
  Future<void> saveAllMenuPermissions(Map<String, bool> permissions) async {
    await prefs.setString(keyMenuPermissions, jsonEncode(permissions));
  }
}

