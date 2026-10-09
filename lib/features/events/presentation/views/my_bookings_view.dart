import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/live_sync_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/utils/data_translator.dart';
import '../../../../core/utils/responsive_helper.dart';

class MyBookingsView extends StatefulWidget {
  const MyBookingsView({super.key});

  @override
  State<MyBookingsView> createState() => _MyBookingsViewState();
}

class _MyBookingsViewState extends State<MyBookingsView> {
  static const Color _primaryPurple = Color(0xFF6B1C9B);
  static const Color _darkBg = Color(0xFF6B1C9B);

  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;
  String _userEmail = '';
  StreamSubscription<void>? _bookingsSub;

  @override
  void initState() {
    super.initState();
    _loadUserAndBookings();
    _bookingsSub = sl<LiveSyncService>().bookingsStream.listen((_) {
      if (mounted) _fetchBookings();
    });
    DataTranslator.translationNotifier.addListener(_onTranslationChanged);
  }

  void _onTranslationChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    DataTranslator.translationNotifier.removeListener(_onTranslationChanged);
    _bookingsSub?.cancel();
    super.dispose();
  }

  Future<void> _loadUserAndBookings() async {
    try {
      final storage = sl<StorageService>();
      _userEmail = storage.getString('user_email') ?? '';
    } catch (_) {}
    await _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() => _isLoading = true);
    try {
      final list = await sl<ApiService>().getBookings(
        email: _userEmail.isNotEmpty ? _userEmail : null,
        forceRefresh: true,
      );
      if (mounted) {
        setState(() {
          _bookings = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cancelBooking(dynamic bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cancel Booking'.trData(context)),
        content: Text('Are you sure you want to cancel this booking reservation?'.trData(context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Keep Booking'.trData(context)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Yes, Cancel'.trData(context)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await sl<ApiService>().cancelBooking(bookingId);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Booking cancelled successfully'.trData(context)),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
          _fetchBookings();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel booking. Please try again.'.trData(context)),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
    }
  }

  void _showTicketPassModal(Map<String, dynamic> b) {
    final ref = b['id']?.toString() ?? '1';
    final title = b['event_title']?.toString() ?? b['artist_name']?.toString() ?? 'Dubai Cultural Event';
    final name = b['full_name']?.toString() ?? b['name']?.toString() ?? 'Attendee';
    final date = b['event_date']?.toString() ?? 'Upcoming';
    final location = b['location']?.toString() ?? 'Dubai, UAE';
    final tickets = '${b['tickets_count'] ?? 1} Ticket(s)';
    final price = b['total_price']?.toString() ?? 'Free';
    final status = b['status']?.toString() ?? 'Confirmed';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Digital Event Pass'.trData(context),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Booking Reference: #BK-$ref'.trData(context),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _primaryPurple,
                ),
              ),
              const SizedBox(height: 20),
              // Pass Card Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6B1C9B), Color(0xFF4A1070)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryPurple.withValues(alpha: 0.25),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            title.trData(context),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status.trData(context),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildPassField('Attendee'.trData(context), name),
                    const SizedBox(height: 10),
                    _buildPassField('Date & Time'.trData(context), date.trData(context)),
                    const SizedBox(height: 10),
                    _buildPassField('Venue'.trData(context), location.trData(context)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildPassField('Passes'.trData(context), tickets),
                        _buildPassField('Amount'.trData(context), price),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white30),
                    const SizedBox(height: 12),
                    // Visual QR simulation barcode block
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.qr_code_2, size: 36, color: Color(0xFF1E1E1E)),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'VALID AT GATE'.trData(context),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1E1E1E),
                                  ),
                                ),
                                Text(
                                  '#BK-$ref',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 20),
                  label: Text(
                    'Done'.trData(context),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPassField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 13.5, color: Colors.white, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final rh = ResponsiveHelper.of(context);

    return Scaffold(
      backgroundColor: _darkBg,
      appBar: const AppTopBar(backgroundColor: Colors.white),
      body: SafeArea(
        child: RefreshIndicator(
          color: _primaryPurple,
          onRefresh: _fetchBookings,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(rh.horizontalPadding, 10, rh.horizontalPadding, 30),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: rh.contentMaxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sub Header with Back and Title
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                          onPressed: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            } else {
                              context.go(RouteNames.events);
                            }
                          },
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'My Bookings & Passes'.trData(context),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 60),
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      )
                    else if (_bookings.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.confirmation_number_outlined,
                              size: 56,
                              color: Color(0xFF94A3B8),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'No Bookings Yet'.trData(context),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Explore cultural exhibitions and reserve your entry passes.'.trData(context),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryPurple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.event, size: 18),
                              label: Text('Browse Events'.trData(context)),
                              onPressed: () => context.go(RouteNames.events),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _bookings.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final b = _bookings[index];
                          final id = b['id']?.toString() ?? '$index';
                          final title = b['event_title']?.toString() ?? b['artist_name']?.toString() ?? 'Event Reservation';
                          final date = b['event_date']?.toString() ?? 'Upcoming';
                          final location = b['location']?.toString() ?? 'Dubai, UAE';
                          final tickets = b['tickets_count'] ?? 1;
                          final price = b['total_price']?.toString() ?? 'Free';
                          final status = b['status']?.toString() ?? 'Confirmed';
                          final isConfirmed = status.toLowerCase() == 'confirmed';

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        title.trData(context),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 16.5,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF1E1E1E),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isConfirmed
                                            ? const Color(0xFFDEF7EC)
                                            : const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        status.trData(context),
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          color: isConfirmed
                                              ? const Color(0xFF03543F)
                                              : const Color(0xFF92400E),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 14, color: _primaryPurple),
                                    const SizedBox(width: 6),
                                    Text(
                                      date.trData(context),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _primaryPurple,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    const Icon(Icons.people_outline, size: 15, color: Color(0xFF64748B)),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$tickets ${'Tickets'.trData(context)}',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      price.trData(context),
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        location.trData(context),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: _primaryPurple,
                                          side: const BorderSide(color: _primaryPurple),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                        ),
                                        icon: const Icon(Icons.qr_code, size: 16),
                                        label: Text(
                                          'Digital Pass'.trData(context),
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                        ),
                                        onPressed: () => _showTicketPassModal(b),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    IconButton(
                                      icon: const Icon(Icons.cancel_outlined, color: Color(0xFFEF4444), size: 20),
                                      tooltip: 'Cancel Booking'.trData(context),
                                      onPressed: () => _cancelBooking(id),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
