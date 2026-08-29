import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_top_bar.dart';

class BookingsView extends StatefulWidget {
  const BookingsView({super.key});

  @override
  State<BookingsView> createState() => _BookingsViewState();
}

class _BookingsViewState extends State<BookingsView> {
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() => _isLoading = _bookings.isEmpty);

    try {
      String? userId;
      try {
        userId = sl<StorageService>().getString('user_id');
      } catch (_) {}

      final data = await sl<ApiService>().getBookings(
        userId: userId,
        forceRefresh: forceRefresh,
      );
      if (mounted) {
        setState(() {
          _bookings = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: const AppTopBar(backgroundColor: Colors.white),
      body: Column(
        children: [
          // Sub-header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 12, 16, 14),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(RouteNames.home);
                    }
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'My Bookings',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Manage your event bookings',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => context.go(RouteNames.home),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.home_outlined, color: Colors.black87, size: 20),
                        SizedBox(width: 4),
                        Text(
                          'Home',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF6A2777)))
                : _bookings.isEmpty
                    ? _buildEmpty(context)
                    : RefreshIndicator(
                        color: const Color(0xFF6A2777),
                        onRefresh: () => _fetchBookings(forceRefresh: true),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _bookings.length,
                          itemBuilder: (context, index) =>
                              _buildCard(context, _bookings[index]),
                        ),
                      ),
          ),

          const AppBottomNavBar(currentIndex: 2),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, Map<String, dynamic> b) {
    final status = (b['status'] as String? ?? 'confirmed');
    final amount = (b['total_amount'] as num?)?.toDouble() ?? 0.0;
    final amountStr = amount == 0.0 ? 'Free' : '${amount.toStringAsFixed(2)} AED';
    final eventTitle = b['event_title'] as String? ?? b['notes'] as String? ?? 'Event Booking';
    final eventCategory = b['event_category'] as String? ?? 'Event Booking';
    final eventDateTime = b['event_date_time'] as String? ?? b['booking_date'] as String? ?? '';
    final location = [b['event_location'], b['event_location_city']]
        .where((e) => e != null && (e as String).isNotEmpty)
        .join(', ');
    final organizer = b['event_organizer'] as String? ?? b['artist_name'] as String?;
    final customerEmail = b['customer_email'] as String? ?? '';
    final customerName = b['customer_name'] as String? ?? '';
    final ref = b['ref'] as String? ?? '#${(b['id'] as String).substring(0, 8)}';
    final createdAt = b['created_at'] as String? ?? '';

    Color statusColor;
    Color statusBg;
    switch (status.toLowerCase()) {
      case 'confirmed':
        statusColor = const Color(0xFF7C3AED);
        statusBg = const Color(0xFFEDE9FE);
        break;
      case 'cancelled':
      case 'canceled':
        statusColor = const Color(0xFFDC2626);
        statusBg = const Color(0xFFFEE2E2);
        break;
      default:
        statusColor = const Color(0xFF059669);
        statusBg = const Color(0xFFD1FAE5);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header: category | status badge | amount
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              children: [
                Text(
                  eventCategory,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status[0].toUpperCase() + status.substring(1),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amountStr,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                    const Text(
                      '1 ticket',
                      style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Divider(height: 1, color: Color(0xFFE2E8F0)),
          ),

          // Event title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              eventTitle,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E1E1E),
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Ref + booked on
          if (ref.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'Ref $ref${createdAt.isNotEmpty ? '  •  Booked on $createdAt' : ''}',
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF6A2777)),
              ),
            ),
          const SizedBox(height: 10),

          // Detail rows
          if (eventDateTime.isNotEmpty)
            _infoRow(Icons.calendar_today_outlined, eventDateTime),
          if (location.isNotEmpty)
            _infoRow(Icons.location_on_outlined, location),
          if (organizer != null && organizer.isNotEmpty)
            _infoRow(Icons.person_outline, organizer),
          if (customerEmail.isNotEmpty)
            _infoRow(Icons.email_outlined, customerEmail),
          if (customerName.isNotEmpty)
            _infoRow(Icons.badge_outlined, customerName),

          // Payment note
          if (amount > 0)
            Container(
              margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 15, color: Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Payment of $amountStr is collected by the organizer at the venue. Online payment is not available yet.',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

          const Padding(
            padding: EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Divider(height: 1, color: Color(0xFFE2E8F0)),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.push(RouteNames.events),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1E1E1E),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text(
                      'View Event Details',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ticket downloaded!'),
                          backgroundColor: Color(0xFF6A2777),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1E1E1E),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text(
                      'Download Ticket',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: status == 'cancelled' ? null : () => _confirmCancel(context, b),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFE2E8F0),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text(
                      'Cancel Booking',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmCancel(BuildContext context, Map<String, dynamic> b) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Cancel Booking', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to cancel this booking? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Booking', style: TextStyle(color: Color(0xFF6A2777))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Booking cancelled.'),
                  backgroundColor: Color(0xFFDC2626),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              _fetchBookings(forceRefresh: true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.confirmation_number_outlined, size: 64, color: Color(0xFF4A5568)),
            const SizedBox(height: 20),
            const Text(
              'No Bookings Found',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1E1E)),
            ),
            const SizedBox(height: 10),
            const Text(
              "You haven't booked any events yet. Start exploring events to make your first booking!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.45),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.push(RouteNames.events),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5E227A),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Browse Events', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
