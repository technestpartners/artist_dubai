import 'dart:convert';
import 'package:flutter/material.dart';
import '../di/injection_container.dart';
import 'api_service.dart';
import 'local_notification_service.dart';
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
  final String? userEmail;
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
    this.userEmail,
    this.isRead = false,
  }) : icon = icon ?? NotificationService.resolveIconAndColors(type).$1,
       iconColor =
           iconColor ?? NotificationService.resolveIconAndColors(type).$2,
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
    'user_email': userEmail,
    'is_read': isRead,
  };

  factory AppNotificationItem.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? 'general';
    final (defIcon, defColor, defBg) = NotificationService.resolveIconAndColors(
      type,
    );
    return AppNotificationItem(
      id: json['id']?.toString() ?? '0',
      title: json['title'] as String? ?? 'Notification',
      body: json['body'] as String? ?? '',
      timeAgo: json['time_ago'] as String? ?? 'Recent',
      type: type,
      icon: defIcon,
      iconColor:
          json['icon_color'] != null
              ? Color(json['icon_color'] as int)
              : defColor,
      iconBg: json['icon_bg'] != null ? Color(json['icon_bg'] as int) : defBg,
      route: json['route'] as String?,
      userEmail: json['user_email'] as String?,
      isRead: json['is_read'] == true,
    );
  }
}

class NotificationService extends ChangeNotifier {
  static const String _kCacheKeyPrefix = 'cached_notifications_';
  final List<AppNotificationItem> _notifications = [];
  final Set<String> _alertedNotificationIds = {};
  bool _hasInitializedAlerts = false;
  bool _isLoading = false;

  NotificationService() {
    _loadFromCache();
    syncWithBackend();
  }

  bool get isLoading => _isLoading;

  List<AppNotificationItem> get notifications =>
      List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  String? get _userEmail {
    try {
      final email = sl<StorageService>().getString('user_email');
      return (email != null && email.trim().isNotEmpty) ? email.trim() : null;
    } catch (_) {
      return null;
    }
  }

  String get _cacheKey {
    final clean = _userEmail?.toLowerCase() ?? 'guest';
    return '$_kCacheKeyPrefix$clean';
  }

  void onUserChanged() {
    _loadFromCache();
    syncWithBackend();
  }

  void _loadFromCache() {
    try {
      final cleanEmail = _userEmail?.toLowerCase();
      final raw = sl<StorageService>().getString(_cacheKey);
      _notifications.clear();
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List<dynamic>;
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            final notif = AppNotificationItem.fromJson(item);
            final notifEmail = notif.userEmail?.toLowerCase();
            // Client-side isolation: do not load notifications belonging to another user
            if (cleanEmail != null &&
                notifEmail != null &&
                notifEmail.isNotEmpty &&
                notifEmail != cleanEmail) {
              continue;
            }
            if (cleanEmail == null &&
                notifEmail != null &&
                notifEmail.isNotEmpty) {
              continue;
            }
            _notifications.add(notif);
          }
        }
      }
      final savedAlerted = sl<StorageService>().getStringList('alerted_notification_ids');
      if (savedAlerted != null) {
        _alertedNotificationIds.addAll(savedAlerted);
      }
      notifyListeners();
    } catch (_) {}
  }

  void _saveToCache() {
    try {
      final encoded = jsonEncode(
        _notifications.map((n) => n.toJson()).toList(),
      );
      sl<StorageService>().setString(_cacheKey, encoded);

      final list = _alertedNotificationIds.toList();
      if (list.length > 200) {
        list.removeRange(0, list.length - 200);
      }
      sl<StorageService>().setStringList('alerted_notification_ids', list);
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
    } else if (t.contains('rsvp') ||
        t.contains('booking') ||
        t.contains('request')) {
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
    } else if (t.contains('artwork') ||
        t.contains('piece') ||
        t.contains('painting')) {
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
    _loadFromCache();
    final cleanEmail = _userEmail?.toLowerCase();

    // If guest / not logged in, clear notifications and do not fetch personal notifications
    if (cleanEmail == null || cleanEmail.isEmpty) {
      _notifications.clear();
      _saveToCache();
      notifyListeners();
      return;
    }

    _isLoading = true;
    try {
      final api = sl<ApiService>();
      final res = await api.getNotifications(
        email: cleanEmail,
        forceRefresh: true,
      );
      final rawList = (res['notifications'] as List<dynamic>?) ?? [];

      _notifications.clear();
      for (final item in rawList) {
        final m = item as Map<String, dynamic>;
        final notifUserEmail =
            (m['user_email'] as String?)?.trim().toLowerCase();
        final type = (m['type'] as String? ?? 'general').toLowerCase();

        // Strict user-wise client filter:
        // If notifUserEmail is specified and doesn't match cleanEmail, skip it!
        if (notifUserEmail != null &&
            notifUserEmail.isNotEmpty &&
            notifUserEmail != cleanEmail) {
          continue;
        }
        // If it's a private chat/message or booking and doesn't belong to current user, skip it!
        if ((type == 'message' || type.contains('chat') || type == 'booking') &&
            notifUserEmail != cleanEmail) {
          continue;
        }

        final id = m['id']?.toString() ?? '0';
        final title = m['title'] as String? ?? 'Notification';
        final body = m['body'] as String? ?? '';
        final route = m['route'] as String?;
        final isRead =
            m['is_read'] == true || m['is_read'] == 1 || m['is_read'] == '1';
        final timeAgo = m['time_ago'] as String? ?? 'Recent';

        final (icon, iconColor, iconBg) = resolveIconAndColors(type);

        final notifItem = AppNotificationItem(
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
          userEmail: notifUserEmail ?? cleanEmail,
        );

        _notifications.add(notifItem);

        // Alert on newly arrived unread notifications during active session
        if (!isRead && !_alertedNotificationIds.contains(id)) {
          _alertedNotificationIds.add(id);
          if (_hasInitializedAlerts) {
            try {
              sl<LocalNotificationService>().showNotification(
                id: int.tryParse(id),
                title: title,
                body: body,
                payload: route,
                type: type,
              );
            } catch (_) {}
          }
        }
      }
      _hasInitializedAlerts = true;
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
    final (
      resolvedIcon,
      resolvedIconColor,
      resolvedIconBg,
    ) = resolveIconAndColors(type);

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
        userEmail: _userEmail?.toLowerCase(),
        isRead: false,
      ),
    );
    _alertedNotificationIds.add(id);
    _saveToCache();
    notifyListeners();

    // Trigger local push notification alert immediately
    try {
      sl<LocalNotificationService>().showNotification(
        id: int.tryParse(id),
        title: title,
        body: body,
        payload: route,
        type: type,
      );
    } catch (_) {}

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
