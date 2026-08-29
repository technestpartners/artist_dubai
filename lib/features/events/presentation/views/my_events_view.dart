import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../home/presentation/widgets/home_footer_widget.dart';
import '../../domain/models/art_event_model.dart';

class EventAttendeeBooking {
  final String id;
  final String eventId;
  final String attendeeName;
  final String attendeeEmail;
  final String attendeePhone;
  final int ticketsCount;
  final String pricePaid;
  final String bookingDate;
  final String status;

  const EventAttendeeBooking({
    required this.id,
    required this.eventId,
    required this.attendeeName,
    required this.attendeeEmail,
    required this.attendeePhone,
    required this.ticketsCount,
    required this.pricePaid,
    required this.bookingDate,
    this.status = 'Confirmed',
  });
}

class MyEventsView extends StatefulWidget {
  const MyEventsView({super.key});

  @override
  State<MyEventsView> createState() => _MyEventsViewState();
}

class _MyEventsViewState extends State<MyEventsView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<ArtEventModel> _myCreatedEvents = [];
  Map<String, List<EventAttendeeBooking>> _eventBookingsMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyEvents();
  }

  Future<void> _fetchMyEvents() async {
    setState(() => _isLoading = _myCreatedEvents.isEmpty);
    try {
      final events = await sl<ApiService>().getEvents(forceRefresh: true);
      final rawBookings = await sl<ApiService>().getBookings(forceRefresh: true);

      final Map<String, List<EventAttendeeBooking>> map = {};

      for (final b in rawBookings) {
        final evId = b['event_id']?.toString() ?? '1';
        final bookingObj = EventAttendeeBooking(
          id: b['id']?.toString() ?? 'bk-1',
          eventId: evId,
          attendeeName: b['full_name'] as String? ?? b['customer_name'] as String? ?? 'Attendee',
          attendeeEmail: b['email'] as String? ?? b['customer_email'] as String? ?? '',
          attendeePhone: b['phone'] as String? ?? '+971 50 000 0000',
          ticketsCount: (b['tickets_count'] as num?)?.toInt() ?? 1,
          pricePaid: b['total_price'] as String? ?? 'Free',
          bookingDate: b['created_at'] as String? ?? 'Today',
          status: b['status'] as String? ?? 'Confirmed',
        );

        if (!map.containsKey(evId)) {
          map[evId] = [];
        }
        map[evId]!.add(bookingObj);
      }

      if (mounted) {
        setState(() {
          _myCreatedEvents = events;
          _eventBookingsMap = map;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ArtEventModel> get _filteredEvents {
    if (_searchQuery.trim().isEmpty) return _myCreatedEvents;
    final query = _searchQuery.toLowerCase().trim();
    return _myCreatedEvents.where((e) {
      return e.title.toLowerCase().contains(query) ||
          e.category.toLowerCase().contains(query) ||
          e.location.toLowerCase().contains(query);
    }).toList();
  }

  void _showAttendeesModal(ArtEventModel event) {
    final bookings = _eventBookingsMap[event.id] ?? const [];
    final totalTickets = bookings.fold<int>(0, (sum, b) => sum + b.ticketsCount);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.4,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E1E1E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _modalMetricItem('Registered Bookings', '${bookings.length}', Icons.receipt_long_outlined),
                      const SizedBox(width: 20),
                      _modalMetricItem('Tickets Sold', '$totalTickets / ${event.maxAttendees}', Icons.confirmation_number_outlined),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  const Text(
                    'Attendee Booking List',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: bookings.isEmpty
                        ? const Center(
                            child: Text(
                              'No bookings found for this event yet.',
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            itemCount: bookings.length,
                            separatorBuilder: (context, index) => const Divider(height: 20),
                            itemBuilder: (context, index) {
                              final booking = bookings[index];
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: const Color(0xFF5E227A),
                                    child: Text(
                                      booking.attendeeName.substring(0, 1).toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                booking.attendeeName,
                                                style: const TextStyle(
                                                  fontSize: 14.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF1E1E1E),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFDCFCE7),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                booking.status,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF15803D),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.email_outlined, size: 13, color: Color(0xFF64748B)),
                                            const SizedBox(width: 4),
                                            Text(
                                              booking.attendeeEmail,
                                              style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(Icons.phone_outlined, size: 13, color: Color(0xFF64748B)),
                                            const SizedBox(width: 4),
                                            Text(
                                              booking.attendeePhone,
                                              style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '🎟️ ${booking.ticketsCount} Ticket${booking.ticketsCount > 1 ? 's' : ''} (${booking.pricePaid})',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF5E227A),
                                              ),
                                            ),
                                            Text(
                                              booking.bookingDate,
                                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _modalMetricItem(String title, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF5E227A), size: 18),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E1E1E)),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalCreated = _myCreatedEvents.length;
    final totalBookingsCount = _eventBookingsMap.values
        .fold<int>(0, (sum, list) => sum + list.length);
    final totalTicketsSold = _eventBookingsMap.values.fold<int>(
        0, (sum, list) => sum + list.fold<int>(0, (s, b) => s + b.ticketsCount));

    final filtered = _filteredEvents;

    return Scaffold(
      backgroundColor: const Color(0xFF6B1C9B),
      appBar: const AppTopBar(backgroundColor: Colors.white),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : RefreshIndicator(
                color: const Color(0xFF5E227A),
                onRefresh: _fetchMyEvents,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
              // 1. Header Title & Create Event Button (Dark Purple Theme)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MY CREATED EVENTS',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Manage your published art events, track attendee ticket bookings, and review attendee records',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: Colors.white70,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () => context.push(RouteNames.createArtEvent),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Create Event', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF5E227A),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Metric Overview Bar (Translucent Cards)
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Events Created',
                      value: '$totalCreated',
                      icon: Icons.event_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Total Bookings',
                      value: '$totalBookingsCount',
                      icon: Icons.receipt_long_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Tickets Sold',
                      value: '$totalTicketsSold',
                      icon: Icons.confirmation_number_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 3. Search Bar
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    hintText: 'Search my created events...',
                    hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: const Icon(Icons.close, color: Colors.white54, size: 18),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              const SizedBox(height: 20),

              // 4. Created Events List
              if (filtered.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5A1684).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.event_busy_outlined, size: 48, color: Colors.white54),
                      SizedBox(height: 12),
                      Text(
                        'No created events found.',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Create your first art event to manage bookings here.',
                        style: TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final event = filtered[index];
                    final bookings = _eventBookingsMap[event.id] ?? const [];
                    final ticketsSold = bookings.fold<int>(0, (sum, b) => sum + b.ticketsCount);

                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF5A1684).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (event.imageUrl != null)
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              child: Image.network(
                                event.imageUrl!,
                                height: 140,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        event.title,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        event.category,
                                        style: const TextStyle(
                                          color: Color(0xFFFFD700),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.white70),
                                    const SizedBox(width: 6),
                                    Text(
                                      event.dateTime,
                                      style: const TextStyle(fontSize: 12.5, color: Colors.white70),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 14, color: Colors.white70),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        event.location,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12.5, color: Colors.white70),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Price: ${event.price}',
                                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    Text(
                                      'Bookings: $ticketsSold / ${event.maxAttendees} Tickets',
                                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFFFFD700)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: const Color(0xFF5E227A),
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                        ),
                                        onPressed: () => _showAttendeesModal(event),
                                        icon: const Icon(Icons.people_outline, size: 16),
                                        label: Text(
                                          'View Attendees (${bookings.length})',
                                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      ),
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Edit event ${event.title} opened.'),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.edit_outlined, size: 15),
                                      label: const Text('Edit', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 24),

              // Footer Attribution
              const HomeFooterWidget(),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: -1),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF5A1684).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFFFD700), size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
