import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../di/injection_container.dart';
import 'api_service.dart';
import 'live_sync_service.dart';
import 'storage_service.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'app_locale';

  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  bool get isArabic => _locale.languageCode == 'ar';

  /// Load persisted locale from SharedPreferences.
  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_localeKey);
    if (saved != null) {
      _locale = Locale(saved);
      if (sl.isRegistered<StorageService>()) {
        await sl<StorageService>().setString(_localeKey, saved);
      }
      notifyListeners();
    }
  }

  /// Switch to a new locale and persist the choice.
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;

    // 1. Immediately persist locale so subsequent network calls carry the new locale
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);

    try {
      if (sl.isRegistered<StorageService>()) {
        await sl<StorageService>().setString(_localeKey, locale.languageCode);
      }
      if (sl.isRegistered<ApiService>()) {
        sl<ApiService>().invalidateAllCaches();
      }
    } catch (_) {}

    // 2. Rebuild UI with new locale
    notifyListeners();

    // 3. Force live sync stream refresh across all pages
    try {
      if (sl.isRegistered<LiveSyncService>()) {
        await sl<LiveSyncService>().forceLocaleRefresh();
      }
    } catch (_) {}
  }

  /// Toggle between English and Arabic.
  Future<void> toggleLocale() async {
    await setLocale(
      isArabic ? const Locale('en') : const Locale('ar'),
    );
  }
}
