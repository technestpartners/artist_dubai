import 'dart:convert';
import 'package:flutter/material.dart';
import '../di/injection_container.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AppNotificationItem {
  final String id;
  final String title;
  final String body;
  final String timeAgo;
  final String type;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String? route;
  bool isRead;

  AppNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timeAgo,
    this.type = 'general',
    IconData? icon,
    Color? iconColor,
    Color? iconBg,
    this.route,
    this.isRead = false,
  })  : icon = icon ?? NotificationService.resolveIconAndColors(type).$1,
        iconColor = iconColor ?? NotificationService.resolveIconAndColors(type).$2,
        iconBg = iconBg ?? NotificationService.resolveIconAndColors(type).$3;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'time_ago': timeAgo,
    'type': type,
    'icon_color': iconColor.toARGB32(),
    'icon_bg': iconBg.toARGB32(),
    'route': route,
    'is_read': isRead,
  };

  factory AppNotificationItem.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? 'general';
    final (defIcon, defColor, defBg) = NotificationService.resolveIconAndColors(type);
    return AppNotificationItem(
      id: json['id']?.toString() ?? '0',
      title: json['title'] as String? ?? 'Notification',
      body: json['body'] as String? ?? '',
      timeAgo: json['time_ago'] as String? ?? 'Recent',
      type: type,
      icon: defIcon,
      iconColor: json['icon_color'] != null
          ? Color(json['icon_color'] as int)
          : defColor,
      iconBg: json['icon_bg'] != null
          ? Color(json['icon_bg'] as int)
          : defBg,
      route: json['route'] as String?,
      isRead: json['is_read'] == true,
    );
  }
}

class NotificationService extends ChangeNotifier {
  static const String _kCacheKeyPrefix = 'cached_notifications_';
  final List<AppNotificationItem> _notifications = [];
  bool _isLoading = false;

  NotificationService() {
    _loadFromCache();
    syncWithBackend();
  }

  bool get isLoading => _isLoading;

  List<AppNotificationItem> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  String? get _userEmail {
    try {
      final email = sl<StorageService>().getString('user_email');
      return (email != null && email.isNotEmpty) ? email : null;
    } catch (_) {
      return null;
    }
  }

  String get _cacheKey => '$_kCacheKeyPrefix${_userEmail ?? 'guest'}';

  void _loadFromCache() {
    try {
      final raw = sl<StorageService>().getString(_cacheKey);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List<dynamic>;
        _notifications.clear();
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            _notifications.add(AppNotificationItem.fromJson(item));
          }
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  void _saveToCache() {
    try {
      final encoded = jsonEncode(_notifications.map((n) => n.toJson()).toList());
      sl<StorageService>().setString(_cacheKey, encoded);
    } catch (_) {}
  }

  static (IconData, Color, Color) resolveIconAndColors(String type) {
    final t = type.toLowerCase();
    if (t.contains('message') || t.contains('chat')) {
      return (
        Icons.chat_bubble_outline_rounded,
        const Color(0xFF10B981),
        const Color(0xFFD1FAE5),
      );
    } else if (t.contains('rsvp') || t.contains('booking') || t.contains('request')) {
      return (
        Icons.calendar_month_outlined,
        const Color(0xFF6A2777),
        const Color(0xFFEDE9FE),
      );
    } else if (t.contains('event') || t.contains('exhibition')) {
      return (
        Icons.celebration_outlined,
        const Color(0xFFD97706),
        const Color(0xFFFEF3C7),
      );
    } else if (t.contains('artwork') || t.contains('piece') || t.contains('painting')) {
      return (
        Icons.auto_awesome_rounded,
        const Color(0xFFEC4899),
        const Color(0xFFFCE7F3),
      );
    } else if (t.contains('gallery') || t.contains('center')) {
      return (
        Icons.account_balance_outlined,
        const Color(0xFF0D9488),
        const Color(0xFFCCFBF1),
      );
    } else if (t.contains('artist') || t.contains('welcome')) {
      return (
        Icons.palette_outlined,
        const Color(0xFF2563EB),
        const Color(0xFFDBEAFE),
      );
    } else if (t.contains('review') || t.contains('rating')) {
      return (
        Icons.star_outline_rounded,
        const Color(0xFFEAB308),
        const Color(0xFFFEF9C3),
      );
    } else if (t.contains('status') || t.contains('approval')) {
      return (
        Icons.verified_outlined,
        const Color(0xFF059669),
        const Color(0xFFD1FAE5),
      );
    } else {
      return (
        Icons.notifications_none_rounded,
        const Color(0xFF6A2777),
        const Color(0xFFEDE9FE),
      );
    }
  }

  Future<void> syncWithBackend() async {
    _isLoading = true;
    try {
      final api = sl<ApiService>();
      final res = await api.getNotifications(email: _userEmail, forceRefresh: true);
      final rawList = (res['notifications'] as List<dynamic>?) ?? [];

      _notifications.clear();
      for (final item in rawList) {
        final m = item as Map<String, dynamic>;
        final id = m['id']?.toString() ?? '0';
        final title = m['title'] as String? ?? 'Notification';
        final body = m['body'] as String? ?? '';
        final type = (m['type'] as String? ?? 'general').toLowerCase();
        final route = m['route'] as String?;
        final isRead = m['is_read'] == true || m['is_read'] == 1 || m['is_read'] == '1';
        final timeAgo = m['time_ago'] as String? ?? 'Recent';

        final (icon, iconColor, iconBg) = resolveIconAndColors(type);

        _notifications.add(
          AppNotificationItem(
            id: id,
            title: title,
            body: body,
            timeAgo: timeAgo,
            type: type,
            icon: icon,
            iconColor: iconColor,
            iconBg: iconBg,
            route: route,
            isRead: isRead,
          ),
        );
      }
      _saveToCache();
    } catch (_) {
      // Offline fallback: keep existing cache in memory
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    for (final n in _notifications) {
      n.isRead = true;
    }
    _saveToCache();
    notifyListeners();

    try {
      await sl<ApiService>().markAllNotificationsRead(email: _userEmail);
    } catch (_) {}
  }

  Future<void> markAsRead(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1 && !_notifications[idx].isRead) {
      _notifications[idx].isRead = true;
      _saveToCache();
      notifyListeners();

      final numericId = int.tryParse(id);
      if (numericId != null && numericId > 0) {
        try {
          await sl<ApiService>().markNotificationRead(numericId);
        } catch (_) {}
      }
    }
  }

  Future<void> dismiss(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    _saveToCache();
    notifyListeners();

    final numericId = int.tryParse(id);
    if (numericId != null && numericId > 0) {
      try {
        await sl<ApiService>().deleteNotification(numericId);
      } catch (_) {}
    }
  }

  Future<void> clearAll() async {
    _notifications.clear();
    _saveToCache();
    notifyListeners();

    try {
      await sl<ApiService>().clearAllNotifications(email: _userEmail);
    } catch (_) {}
  }

  void addNotification({
    required String title,
    required String body,
    IconData? icon,
    Color? iconColor,
    Color? iconBg,
    String type = 'general',
    String? route,
  }) {
    final (resolvedIcon, resolvedIconColor, resolvedIconBg) =
        resolveIconAndColors(type);

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _notifications.insert(
      0,
      AppNotificationItem(
        id: id,
        title: title,
        body: body,
        timeAgo: 'Just now',
        type: type,
        icon: icon ?? resolvedIcon,
        iconColor: iconColor ?? resolvedIconColor,
        iconBg: iconBg ?? resolvedIconBg,
        route: route,
        isRead: false,
      ),
    );
    _saveToCache();
    notifyListeners();

    // Also persist to backend asynchronously if online
    try {
      sl<ApiService>().createNotification(
        title: title,
        body: body,
        type: type,
        route: route,
        email: _userEmail,
      );
    } catch (_) {}
  }
}
