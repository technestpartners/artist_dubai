import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_top_bar.dart';
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

  // Mock list of events created by the logged-in user / artist
  final List<ArtEventModel> _myCreatedEvents = [
    const ArtEventModel(
      id: 'my-event-1',
      title: 'Contemporary Arabic Calligraphy Masterclass',
      category: 'Art Workshop',
      price: '50.00 AED',
      description: 'Join master artist Nizar Fahem for an exclusive live calligraphy workshop.',
      dateTime: 'Thu, 4 Sep 2025 at 10:00 AM',
      formattedDate: 'Thursday, 4 September 2025',
      timeRange: '10:00 AM - 02:00 PM',
      location: 'Alserkal Avenue, Al Quoz, Dubai',
      attendeesCount: 10,
      maxAttendees: 20,
      organizer: 'Nizar Fahem',
      organizerEmail: 'nizar@artistdubai.com',
      tags: ['Calligraphy', 'Masterclass', 'Workshop'],
    ),
    const ArtEventModel(
      id: 'my-event-2',
      title: 'Youth Digital Art & NFT Showcase 2026',
      category: 'Art Exhibition',
      price: 'Free',
      description: 'Showcasing digital artwork from rising UAE artists and creators.',
      dateTime: 'Sat, 12 Sep 2025 at 04:00 PM',
      formattedDate: 'Saturday, 12 September 2025',
      timeRange: '04:00 PM - 09:00 PM',
      location: 'Dubai Design District (d3), Building 7',
      attendeesCount: 6,
      maxAttendees: 50,
      organizer: 'Nizar Fahem',
      organizerEmail: 'nizar@artistdubai.com',
      tags: ['Digital Art', 'Exhibition', 'd3'],
    ),
    const ArtEventModel(
      id: 'my-event-3',
      title: 'Oil Painting & Abstract Expressions',
      category: 'Gallery Opening',
      price: '30.00 AED',
      description: 'Interactive gallery opening featuring abstract canvas paintings.',
      dateTime: 'Sun, 20 Sep 2025 at 06:00 PM',
      formattedDate: 'Sunday, 20 September 2025',
      timeRange: '06:00 PM - 10:00 PM',
      location: 'Jameel Arts Centre, Jaddaf Waterfront',
      attendeesCount: 4,
      maxAttendees: 30,
      organizer: 'Nizar Fahem',
      organizerEmail: 'nizar@artistdubai.com',
      tags: ['Oil Painting', 'Gallery', 'Abstract'],
    ),
  ];

  // Mock booking records per event (who booked tickets for each event)
  final Map<String, List<EventAttendeeBooking>> _eventBookingsMap = {
    'my-event-1': const [
      EventAttendeeBooking(
        id: 'bk-101',
        eventId: 'my-event-1',
        attendeeName: 'Rashid Al Nuaimi',
        attendeeEmail: 'rashid.alnuaimi@example.ae',
        attendeePhone: '+971 50 123 4567',
        ticketsCount: 2,
        pricePaid: '100.00 AED',
        bookingDate: 'Today, 14:30',
      ),
      EventAttendeeBooking(
        id: 'bk-102',
        eventId: 'my-event-1',
        attendeeName: 'Fatima Al Zarooni',
        attendeeEmail: 'fatima.z@example.com',
        attendeePhone: '+971 55 987 6543',
        ticketsCount: 3,
        pricePaid: '150.00 AED',
        bookingDate: 'Yesterday, 11:15',
      ),
      EventAttendeeBooking(
        id: 'bk-103',
        eventId: 'my-event-1',
        attendeeName: 'Marcus Vance',
        attendeeEmail: 'marcus.v@artworld.com',
        attendeePhone: '+971 52 444 3322',
        ticketsCount: 1,
        pricePaid: '50.00 AED',
        bookingDate: '25 Aug 2026, 09:20',
      ),
      EventAttendeeBooking(
        id: 'bk-104',
        eventId: 'my-event-1',
        attendeeName: 'Aisha Al Habbai',
        attendeeEmail: 'aisha.habbai@dubaiart.ae',
        attendeePhone: '+971 56 777 8899',
        ticketsCount: 4,
        pricePaid: '200.00 AED',
        bookingDate: '24 Aug 2026, 16:45',
      ),
    ],
    'my-event-2': const [
      EventAttendeeBooking(
        id: 'bk-201',
        eventId: 'my-event-2',
        attendeeName: 'Omar Al Suwaidi',
        attendeeEmail: 'omar.s@creative.ae',
        attendeePhone: '+971 50 888 1234',
        ticketsCount: 2,
        pricePaid: 'Free',
        bookingDate: 'Today, 16:10',
      ),
      EventAttendeeBooking(
        id: 'bk-202',
        eventId: 'my-event-2',
        attendeeName: 'Elena Rostova',
        attendeeEmail: 'elena.rostova@design.com',
        attendeePhone: '+971 54 321 0987',
        ticketsCount: 1,
        pricePaid: 'Free',
        bookingDate: '26 Aug 2026, 18:00',
      ),
      EventAttendeeBooking(
        id: 'bk-203',
        eventId: 'my-event-2',
        attendeeName: 'Tariq Mansoor',
        attendeeEmail: 'tariq.m@techart.ae',
        attendeePhone: '+971 52 111 2233',
        ticketsCount: 3,
        pricePaid: 'Free',
        bookingDate: '23 Aug 2026, 12:30',
      ),
    ],
    'my-event-3': const [
      EventAttendeeBooking(
        id: 'bk-301',
        eventId: 'my-event-3',
        attendeeName: 'Hind Al Qassimi',
        attendeeEmail: 'hind.q@culture.ae',
        attendeePhone: '+971 50 555 6677',
        ticketsCount: 2,
        pricePaid: '60.00 AED',
        bookingDate: 'Today, 10:05',
      ),
      EventAttendeeBooking(
        id: 'bk-302',
        eventId: 'my-event-3',
        attendeeName: 'David Chen',
        attendeeEmail: 'david.chen@studio.com',
        attendeePhone: '+971 56 333 4455',
        ticketsCount: 2,
        pricePaid: '60.00 AED',
        bookingDate: '25 Aug 2026, 15:40',
      ),
    ],
  };

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
                  // Drag Handle Indicator
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

                  // Modal Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Booked Attendees (${bookings.length})',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E1E1E),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              event.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Summary Metric Bar inside Modal
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F5FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE9D8F8)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _modalMetricItem('Total Attendees', '${bookings.length} Persons', Icons.group),
                        Container(height: 24, width: 1, color: const Color(0xFFD6C8F2)),
                        _modalMetricItem('Total Tickets', '$totalTickets Tickets', Icons.confirmation_number),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Attendees List
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
                                  // Avatar Initials
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: const Color(0xFF28208C),
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

                                  // Details Column
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

                                        // Email
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

                                        // Phone
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

                                        // Tickets & Date Row
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '🎟️ ${booking.ticketsCount} Ticket${booking.ticketsCount > 1 ? 's' : ''} (${booking.pricePaid})',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF28208C),
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
        Icon(icon, color: const Color(0xFF28208C), size: 18),
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

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: const AppTopBar(backgroundColor: Colors.white),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF28208C), Color(0xFF5E227A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF28208C).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: const [
                              Icon(Icons.event_seat_outlined, color: Colors.white, size: 24),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'My Created Events',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => context.push(RouteNames.createArtEvent),
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text('Create Event', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF28208C),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Manage your published art events, track attendee ticket bookings, and review attendee records.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFFD6C8F2),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Metric Overview Bar
              Row(
                children: [
                  _metricCard('Events Created', '$totalCreated', Icons.event),
                  const SizedBox(width: 10),
                  _metricCard('Bookings', '$totalBookingsCount', Icons.people_outline),
                  const SizedBox(width: 10),
                  _metricCard('Tickets Sold', '$totalTicketsSold', Icons.confirmation_number_outlined),
                ],
              ),
              const SizedBox(height: 16),

              // Search Input Field
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search my created events...',
                  hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13.5),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF28208C), width: 1.8),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // List of Created Events
              _filteredEvents.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: const [
                          Icon(Icons.event_busy, size: 48, color: Color(0xFF94A3B8)),
                          SizedBox(height: 12),
                          Text(
                            'No created events found.',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E1E1E)),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredEvents.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final event = _filteredEvents[index];
                        final bookings = _eventBookingsMap[event.id] ?? const [];
                        final ticketsCount = bookings.fold<int>(0, (sum, b) => sum + b.ticketsCount);

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title & Category Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF28208C).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      event.category,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF28208C),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    event.price,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF5E227A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              Text(
                                event.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E1E1E),
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Date & Location Info
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF64748B)),
                                  const SizedBox(width: 6),
                                  Text(
                                    event.dateTime,
                                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      event.location,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Booked Data Summary Card
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F5FF),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFE9D8F8)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Booked Tickets Record',
                                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '$ticketsCount Tickets Booked (${bookings.length} Persons)',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF28208C),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: () => _showAttendeesModal(event),
                                      icon: const Icon(Icons.visibility_outlined, size: 14),
                                      label: const Text('View Attendees', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFF28208C),
                                        side: const BorderSide(color: Color(0xFF28208C)),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
    );
  }

  Widget _metricCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF28208C), size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E1E1E)),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}
