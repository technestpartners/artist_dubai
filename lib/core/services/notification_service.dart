import 'package:flutter/material.dart';
import '../di/injection_container.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AppNotificationItem {
  final String id;
  final String title;
  final String body;
  final String timeAgo;
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
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.route,
    this.isRead = false,
  });
}

class NotificationService extends ChangeNotifier {
  final List<AppNotificationItem> _notifications = [];
  bool _isLoading = false;

  NotificationService() {
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

  Future<void> syncWithBackend() async {
    _isLoading = true;
    try {
      final api = sl<ApiService>();
      final res = await api.getNotifications(email: _userEmail, forceRefresh: true);
      final rawList = (res['notifications'] as List<dynamic>?) ?? [];

      if (rawList.isNotEmpty) {
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

          IconData icon;
          Color iconColor;
          Color iconBg;

          if (type.contains('booking') || type.contains('request')) {
            icon = Icons.calendar_month_outlined;
            iconColor = const Color(0xFF6A2777);
            iconBg = const Color(0xFFEDE9FE);
          } else if (type.contains('event') || type.contains('exhibition')) {
            icon = Icons.celebration_outlined;
            iconColor = const Color(0xFFD97706);
            iconBg = const Color(0xFFFEF3C7);
          } else if (type.contains('artist') || type.contains('welcome')) {
            icon = Icons.palette_outlined;
            iconColor = const Color(0xFF2563EB);
            iconBg = const Color(0xFFDBEAFE);
          } else if (type.contains('review')) {
            icon = Icons.star_outline_rounded;
            iconColor = const Color(0xFFEAB308);
            iconBg = const Color(0xFFFEF9C3);
          } else {
            icon = Icons.notifications_none_rounded;
            iconColor = const Color(0xFF6A2777);
            iconBg = const Color(0xFFEDE9FE);
          }

          _notifications.add(
            AppNotificationItem(
              id: id,
              title: title,
              body: body,
              timeAgo: timeAgo,
              icon: icon,
              iconColor: iconColor,
              iconBg: iconBg,
              route: route,
              isRead: isRead,
            ),
          );
        }
      }
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    for (final n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();

    try {
      await sl<ApiService>().markAllNotificationsRead(email: _userEmail);
    } catch (_) {}
  }

  Future<void> markAsRead(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1 && !_notifications[idx].isRead) {
      _notifications[idx].isRead = true;
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
    notifyListeners();

    try {
      await sl<ApiService>().markAllNotificationsRead(email: _userEmail);
    } catch (_) {}
  }

  void addNotification({
    required String title,
    required String body,
    required IconData icon,
    Color iconColor = const Color(0xFF6A2777),
    Color iconBg = const Color(0xFFEDE9FE),
    String? route,
  }) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _notifications.insert(
      0,
      AppNotificationItem(
        id: id,
        title: title,
        body: body,
        timeAgo: 'Just now',
        icon: icon,
        iconColor: iconColor,
        iconBg: iconBg,
        route: route,
        isRead: false,
      ),
    );
    notifyListeners();
  }
}
