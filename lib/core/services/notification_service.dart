import 'package:flutter/material.dart';
import '../di/injection_container.dart';
import 'api_service.dart';

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
  final List<AppNotificationItem> _notifications = [
    AppNotificationItem(
      id: 'welcome_1',
      title: 'Welcome to Artist Dubai',
      body: 'Explore top UAE talent, artworks, and register your artist profile.',
      timeAgo: '1d ago',
      icon: Icons.palette_outlined,
      iconColor: const Color(0xFF2563EB),
      iconBg: const Color(0xFFDBEAFE),
      route: '/artists',
      isRead: false,
    ),
  ];

  final Set<String> _readIds = {};
  final Set<String> _dismissedIds = {};

  NotificationService() {
    syncWithBackend();
  }

  List<AppNotificationItem> get notifications =>
      List.unmodifiable(_notifications.where((n) => !_dismissedIds.contains(n.id)));

  int get unreadCount =>
      _notifications.where((n) => !n.isRead && !_dismissedIds.contains(n.id)).length;

  Future<void> syncWithBackend() async {
    try {
      final api = sl<ApiService>();
      final bookings = await api.getBookings();
      final events = await api.getEvents();

      // 1. Convert recent bookings from MySQL into live notifications
      for (final b in bookings.take(5)) {
        final id = 'booking_${b['id']}';
        if (_dismissedIds.contains(id)) continue;

        final isArtist = (b['booking_type'] as String? ?? '').toLowerCase().contains('artist');
        final eventTitle = b['event_title'] as String? ?? 'Art Event';
        final name = b['full_name'] as String? ?? 'A client';
        final tickets = b['tickets_count'] ?? 1;

        final existingIdx = _notifications.indexWhere((n) => n.id == id);
        if (existingIdx == -1) {
          _notifications.insert(
            0,
            AppNotificationItem(
              id: id,
              title: isArtist ? 'New Booking Request' : 'Ticket Booking Confirmed',
              body: isArtist
                  ? '$name sent a booking request.'
                  : 'Booking for $eventTitle ($tickets ticket${tickets == 1 ? '' : 's'}) is confirmed.',
              timeAgo: 'Recent',
              icon: isArtist ? Icons.calendar_month_outlined : Icons.confirmation_number_outlined,
              iconColor: const Color(0xFF6A2777),
              iconBg: const Color(0xFFEDE9FE),
              route: isArtist ? '/booking-requests' : '/bookings',
              isRead: _readIds.contains(id),
            ),
          );
        }
      }

      // 2. Convert recent events from MySQL into live notifications
      for (final ev in events.take(3)) {
        final id = 'event_${ev.id}';
        if (_dismissedIds.contains(id)) continue;

        final existingIdx = _notifications.indexWhere((n) => n.id == id);
        if (existingIdx == -1) {
          _notifications.add(
            AppNotificationItem(
              id: id,
              title: 'Upcoming: ${ev.title}',
              body: '${ev.title} at ${ev.location}.',
              timeAgo: 'Upcoming',
              icon: Icons.celebration_outlined,
              iconColor: const Color(0xFFD97706),
              iconBg: const Color(0xFFFEF3C7),
              route: '/events',
              isRead: _readIds.contains(id),
            ),
          );
        }
      }

      notifyListeners();
    } catch (_) {}
  }

  void markAllAsRead() {
    for (final n in _notifications) {
      n.isRead = true;
      _readIds.add(n.id);
    }
    notifyListeners();
  }

  void markAsRead(String id) {
    _readIds.add(id);
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1 && !_notifications[idx].isRead) {
      _notifications[idx].isRead = true;
      notifyListeners();
    }
  }

  void dismiss(String id) {
    _dismissedIds.add(id);
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void clearAll() {
    for (final n in _notifications) {
      _dismissedIds.add(n.id);
    }
    _notifications.clear();
    notifyListeners();
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
