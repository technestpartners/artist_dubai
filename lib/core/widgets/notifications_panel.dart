import 'package:flutter/material.dart';

/// A notification data model
class AppNotification {
  final String id;
  final String title;
  final String body;
  final String timeAgo;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timeAgo,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.isRead = false,
  });
}

/// Shows the floating notifications panel anchored to a given render box.
void showNotificationsPanel(BuildContext context, GlobalKey bellKey) {
  final RenderBox? renderBox =
      bellKey.currentContext?.findRenderObject() as RenderBox?;
  if (renderBox == null) return;

  final offset = renderBox.localToGlobal(Offset.zero);
  final screenWidth = MediaQuery.of(context).size.width;
  const panelWidth = 320.0;

  // Position panel to the left of the bell, clamped inside screen
  double left = offset.dx - panelWidth + renderBox.size.width;
  if (left < 8) left = 8;
  if (left + panelWidth > screenWidth - 8) left = screenWidth - panelWidth - 8;
  final top = offset.dy + renderBox.size.height + 4;

  final notifications = <AppNotification>[
    AppNotification(
      id: '1',
      title: 'New Booking Request',
      body: 'Sarah Ahmed wants to book you for a wedding portrait session',
      timeAgo: '30m ago',
      icon: Icons.calendar_month_outlined,
      iconColor: const Color(0xFF6A2777),
      iconBg: const Color(0xFFEDE9FE),
    ),
    AppNotification(
      id: '2',
      title: 'Event Reminder',
      body: 'Art Exhibition at Dubai Gallery starts tomorrow at 6 PM',
      timeAgo: '2h ago',
      icon: Icons.celebration_outlined,
      iconColor: const Color(0xFFD97706),
      iconBg: const Color(0xFFFEF3C7),
    ),
    AppNotification(
      id: '3',
      title: 'Profile Updated',
      body: 'Your artist profile has been successfully updated',
      timeAgo: '1d ago',
      icon: Icons.person_outline,
      iconColor: const Color(0xFF374151),
      iconBg: const Color(0xFFF3F4F6),
      isRead: true,
    ),
    AppNotification(
      id: '4',
      title: 'New Feature Available',
      body: 'Check out the new artwork portfolio management tools',
      timeAgo: '2d ago',
      icon: Icons.new_releases_outlined,
      iconColor: const Color(0xFFD97706),
      iconBg: const Color(0xFFFEF3C7),
    ),
  ];

  showDialog(
    context: context,
    barrierColor: Colors.transparent,
    barrierDismissible: true,
    builder: (ctx) => _NotificationsPanelDialog(
      left: left,
      top: top,
      panelWidth: panelWidth,
      notifications: notifications,
    ),
  );
}

class _NotificationsPanelDialog extends StatefulWidget {
  final double left;
  final double top;
  final double panelWidth;
  final List<AppNotification> notifications;

  const _NotificationsPanelDialog({
    required this.left,
    required this.top,
    required this.panelWidth,
    required this.notifications,
  });

  @override
  State<_NotificationsPanelDialog> createState() =>
      _NotificationsPanelDialogState();
}

class _NotificationsPanelDialogState
    extends State<_NotificationsPanelDialog> {
  late List<AppNotification> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.notifications);
  }

  void _markAllRead() {
    setState(() {
      for (final n in _items) {
        n.isRead = true;
      }
    });
  }

  void _dismiss(String id) {
    setState(() {
      _items.removeWhere((n) => n.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Transparent barrier
        GestureDetector(
          onTap: () => Navigator.pop(context),
          behavior: HitTestBehavior.opaque,
          child: const SizedBox.expand(),
        ),

        // Panel
        Positioned(
          left: widget.left,
          top: widget.top,
          width: widget.panelWidth,
          child: Material(
            elevation: 12,
            borderRadius: BorderRadius.circular(14),
            shadowColor: Colors.black26,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 14, 12, 10),
                    child: Row(
                      children: [
                        const Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E1E1E),
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _markAllRead,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Mark all read',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF6A2777),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),

                  if (_items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          Icon(Icons.notifications_none,
                              size: 40, color: Color(0xFFCBD5E1)),
                          SizedBox(height: 10),
                          Text(
                            'No notifications',
                            style: TextStyle(
                                color: Color(0xFF94A3B8), fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (_, index) =>
                          _buildItem(_items[index]),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItem(AppNotification n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon circle
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: n.iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(n.icon, size: 18, color: n.iconColor),
          ),
          const SizedBox(width: 10),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        n.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: n.isRead
                              ? FontWeight.w500
                              : FontWeight.w700,
                          color: const Color(0xFF1E1E1E),
                        ),
                      ),
                    ),
                    if (!n.isRead)
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(left: 4, right: 2),
                        decoration: const BoxDecoration(
                          color: Color(0xFF6A2777),
                          shape: BoxShape.circle,
                        ),
                      ),
                    Text(
                      n.timeAgo,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _dismiss(n.id),
                      child: const Icon(Icons.close,
                          size: 15, color: Color(0xFFCBD5E1)),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  n.body,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6A2777),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
