import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../di/injection_container.dart';
import '../services/notification_service.dart';

/// Shows the floating notifications panel anchored to the bell icon.
void showNotificationsPanel(BuildContext context, GlobalKey bellKey) {
  final RenderBox? renderBox =
      bellKey.currentContext?.findRenderObject() as RenderBox?;
  if (renderBox == null) return;

  final offset = renderBox.localToGlobal(Offset.zero);
  final screenWidth = MediaQuery.of(context).size.width;
  const panelWidth = 330.0;

  // Position panel to align with bell, clamped inside screen
  double left = offset.dx - panelWidth + renderBox.size.width + 10;
  if (left < 10) left = 10;
  if (left + panelWidth > screenWidth - 10) left = screenWidth - panelWidth - 10;
  final top = offset.dy + renderBox.size.height + 6;

  showDialog(
    context: context,
    barrierColor: Colors.transparent,
    barrierDismissible: true,
    builder: (ctx) => _NotificationsPanelDialog(
      left: left,
      top: top,
      panelWidth: panelWidth,
    ),
  );
}

class _NotificationsPanelDialog extends StatefulWidget {
  final double left;
  final double top;
  final double panelWidth;

  const _NotificationsPanelDialog({
    required this.left,
    required this.top,
    required this.panelWidth,
  });

  @override
  State<_NotificationsPanelDialog> createState() =>
      _NotificationsPanelDialogState();
}

class _NotificationsPanelDialogState extends State<_NotificationsPanelDialog> {
  final NotificationService _notificationService = sl<NotificationService>();

  @override
  void initState() {
    super.initState();
    _notificationService.syncWithBackend();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _notificationService,
      builder: (context, _) {
        final items = _notificationService.notifications;
        final unreadCount = _notificationService.unreadCount;

        return Stack(
          children: [
            // Transparent tap area to dismiss dialog
            GestureDetector(
              onTap: () => Navigator.pop(context),
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),

            // Panel Box
            Positioned(
              left: widget.left,
              top: widget.top,
              width: widget.panelWidth,
              child: Material(
                elevation: 14,
                borderRadius: BorderRadius.circular(14),
                shadowColor: Colors.black38,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Row
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
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
                            if (unreadCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6A2777),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$unreadCount new',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                            const Spacer(),
                            if (items.isNotEmpty && unreadCount > 0)
                              TextButton(
                                onPressed: () {
                                  _notificationService.markAllAsRead();
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Mark all read',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6A2777),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),

                      // Notification items list
                      if (items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 36),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.notifications_off_outlined,
                                size: 38,
                                color: Color(0xFFCBD5E1),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'No new notifications',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 340),
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: items.length,
                            separatorBuilder: (_, __) => const Divider(
                              height: 1,
                              color: Color(0xFFF1F5F9),
                            ),
                            itemBuilder: (_, index) => _buildItem(context, items[index]),
                          ),
                        ),

                      if (items.isNotEmpty) ...[
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  _notificationService.clearAll();
                                },
                                child: const Text(
                                  'Clear all',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Text(
                                  'Close',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6A2777),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildItem(BuildContext context, AppNotificationItem n) {
    return InkWell(
      onTap: () {
        _notificationService.markAsRead(n.id);
        Navigator.pop(context);
        if (n.route != null && n.route!.isNotEmpty) {
          try {
            context.push(n.route!);
          } catch (_) {}
        }
      },
      child: Container(
        color: n.isRead ? Colors.white : const Color(0xFFFAF5FF),
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
                            fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700,
                            color: const Color(0xFF1E1E1E),
                          ),
                        ),
                      ),
                      if (!n.isRead)
                        Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.only(left: 4, right: 4),
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
                        onTap: () => _notificationService.dismiss(n.id),
                        child: const Padding(
                          padding: EdgeInsets.all(2.0),
                          child: Icon(
                            Icons.close,
                            size: 15,
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    n.body,
                    style: TextStyle(
                      fontSize: 12,
                      color: n.isRead ? const Color(0xFF64748B) : const Color(0xFF475569),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
