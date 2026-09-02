import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/live_sync_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../events/domain/models/art_event_model.dart';
import '../../../events/presentation/views/event_detail_view.dart';

class BookingsView extends StatefulWidget {
  const BookingsView({super.key});

  @override
  State<BookingsView> createState() => _BookingsViewState();
}

class _BookingsViewState extends State<BookingsView> {
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;
  StreamSubscription<List<Map<String, dynamic>>>? _bookingsSub;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
    _bookingsSub = sl<LiveSyncService>().bookingsStream.listen((bookings) {
      if (mounted) {
        setState(() {
          _bookings = bookings;
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _bookingsSub?.cancel();
    super.dispose();
  }

  Future<void> _fetchBookings({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() => _isLoading = _bookings.isEmpty);

    try {
      String? userId;
      String? userEmail;
      try {
        final storage = sl<StorageService>();
        userId = storage.getString('user_id');
        userEmail = storage.getString('user_email');
      } catch (_) {}

      final data = await sl<ApiService>().getBookings(
        userId: userId,
        email: userEmail,
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
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: -1),
    );
  }

  Widget _buildCard(BuildContext context, Map<String, dynamic> b) {
    final status = (b['status'] as String? ?? 'confirmed');
    final amountStr = b['total_price'] as String? ??
        (b['total_amount'] != null ? '${b['total_amount']} AED' : 'Free');
    final ticketsCount = b['tickets_count'] ?? 1;
    final eventTitle = b['event_title'] as String? ??
        b['title'] as String? ??
        b['artist_name'] as String? ??
        b['notes'] as String? ??
        'Art Event Booking';
    final eventCategory = b['booking_type'] as String? ??
        b['event_category'] as String? ??
        'Event Booking';
    final eventDateTime = b['event_date'] as String? ??
        b['event_date_time'] as String? ??
        b['booking_date'] as String? ??
        '';
    final location = (b['location'] as String?)?.isNotEmpty == true
        ? b['location'] as String
        : [b['event_location'], b['event_location_city']]
            .where((e) => e != null && (e as String).isNotEmpty)
            .join(', ');
    final organizer = b['artist_name'] as String? ??
        b['organizer_name'] as String? ??
        b['event_organizer'] as String?;
    final customerEmail = b['email'] as String? ?? b['customer_email'] as String? ?? '';
    final customerName = b['full_name'] as String? ?? b['customer_name'] as String? ?? '';
    final idStr = b['id']?.toString() ?? '1';
    final ref = b['ref'] as String? ?? '#BK-$idStr';
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
                    status.isNotEmpty
                        ? status[0].toUpperCase() + status.substring(1)
                        : 'Confirmed',
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
                    const Text(
                      'Free Entry',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                    Text(
                      '$ticketsCount Guest${ticketsCount == 1 ? '' : 's'}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
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
          if (amountStr.toLowerCase() != 'free' && amountStr != '0' && amountStr != 'AED 0')
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
                    onPressed: () => _openEventDetails(context, b),
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
                    onPressed: () => _showTicketPassDialog(context, b),
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

  Future<void> _openEventDetails(BuildContext context, Map<String, dynamic> b) async {
    final eventTitle = b['event_title'] ?? b['artist_name'] ?? 'Dubai Modern Art Showcase';
    final dynamic rawEventId = b['event_id'];

    try {
      final events = await sl<ApiService>().getEvents();
      final match = events.firstWhere(
        (e) => (rawEventId != null && e.id.toString() == rawEventId.toString()) || e.title.toLowerCase().trim() == eventTitle.toString().toLowerCase().trim(),
        orElse: () => ArtEventModel(
          id: rawEventId?.toString() ?? '1',
          title: eventTitle.toString(),
          category: b['category']?.toString() ?? 'Art Event',
          price: b['total_price']?.toString() ?? 'Free',
          description: b['description'] != null && b['description'].toString().isNotEmpty
              ? b['description'].toString()
              : '',
          dateTime: b['event_date']?.toString() ?? '',
          formattedDate: b['event_date']?.toString() ?? '',
          location: b['location']?.toString() ?? 'Dubai, UAE',
          attendeesCount: 0,
          maxAttendees: 100,
          organizer: b['artist_name']?.toString() ?? b['organizer']?.toString() ?? 'Organizer',
          organizerEmail: b['email']?.toString() ?? '',
          tags: const ['Art', 'Event'],
          imageUrl: b['image_url']?.toString() ?? b['image']?.toString() ?? '',
        ),
      );

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailView(event: match),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        final fallback = ArtEventModel(
          id: rawEventId?.toString() ?? '1',
          title: eventTitle.toString(),
          category: b['category']?.toString() ?? 'Art Event',
          price: b['total_price']?.toString() ?? 'Free',
          description: b['description'] != null && b['description'].toString().isNotEmpty
              ? b['description'].toString()
              : '',
          dateTime: b['event_date']?.toString() ?? '',
          formattedDate: b['event_date']?.toString() ?? '',
          location: b['location']?.toString() ?? 'Dubai, UAE',
          attendeesCount: 0,
          maxAttendees: 100,
          organizer: b['artist_name']?.toString() ?? b['organizer']?.toString() ?? 'Organizer',
          organizerEmail: b['email']?.toString() ?? '',
          tags: const ['Art', 'Event'],
          imageUrl: b['image_url']?.toString() ?? b['image']?.toString() ?? '',
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailView(event: fallback),
          ),
        );
      }
    }
  }

  Future<void> _downloadTicketPdf(BuildContext context, dynamic bookingId) async {
    HapticFeedback.heavyImpact();
    final url = '${ApiEndpoints.baseUrl}api.php?resource=bookings&action=download_ticket&id=$bookingId';
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloading official PDF Ticket #BK-$bookingId...'),
          backgroundColor: const Color(0xFF6A2777),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showTicketPassDialog(BuildContext context, Map<String, dynamic> b) {
    HapticFeedback.lightImpact();
    final bookingId = b['id'] ?? b['booking_id'] ?? '2';
    final eventTitle = b['event_title'] ?? b['artist_name'] ?? 'Dubai Art Event';
    final date = (b['event_date'] ?? '').toString();
    final location = b['location'] ?? 'Dubai, UAE';
    final fullName = b['full_name'] ?? b['name'] ?? 'Attendee';
    final email = b['email'] ?? '';
    final ticketsCount = b['tickets_count'] ?? 1;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ticket Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6A2777), Color(0xFF8B3A9B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.confirmation_number_outlined, color: Colors.white, size: 24),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'DUBAI ART E-TICKET PASS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event Title
                    Text(
                      eventTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Booking Reference: #BK-$bookingId',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6A2777),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Info Container
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          _ticketRow('Attendee', fullName),
                          const SizedBox(height: 6),
                          if (email.isNotEmpty) ...[
                            _ticketRow('Email', email),
                            const SizedBox(height: 6),
                          ],
                          _ticketRow('Date', date),
                          const SizedBox(height: 6),
                          _ticketRow('Venue', location),
                          const SizedBox(height: 6),
                          _ticketRow('Guests', '$ticketsCount Attendee(s)'),
                          const SizedBox(height: 6),
                          _ticketRow('Admission', 'Free Community Entry', isHighlight: true),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Download Action
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text(
                          'Save / Download PDF Pass',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A2777),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _downloadTicketPdf(context, bookingId);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ticketRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
            color: isHighlight ? const Color(0xFF6A2777) : const Color(0xFF1E293B),
          ),
        ),
      ],
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
    final bookingId = b['id'] ?? b['booking_id'];
    final eventTitle = b['event_title'] ?? b['artist_name'] ?? 'Event';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Warning Icon & Header Row
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFDC2626),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Cancel Booking',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text(
                'Are you sure you want to cancel your booking for "$eventTitle"? This will update your reservation in the database.',
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF64748B),
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons Row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1E293B),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Keep Booking',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      
                      await sl<ApiService>().cancelBooking(bookingId);

                      try {
                        sl<NotificationService>().addNotification(
                          title: 'Booking Cancelled',
                          body: 'Your booking for $eventTitle (#BK-$bookingId) has been cancelled.',
                          icon: Icons.cancel_outlined,
                          route: RouteNames.myBookings,
                        );
                      } catch (_) {}

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Booking #BK-$bookingId has been cancelled.'),
                            backgroundColor: const Color(0xFFDC2626),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }

                      _fetchBookings(forceRefresh: true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Yes, Cancel Booking',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
