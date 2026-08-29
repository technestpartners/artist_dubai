import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/art_event_model.dart';
import 'event_detail_view.dart';

class EventsView extends StatefulWidget {
  const EventsView({super.key});

  @override
  State<EventsView> createState() => _EventsViewState();
}

class _EventsViewState extends State<EventsView> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All Categories';
  List<ArtEventModel> _allEvents = ArtEventModel.mockEvents;
  final List<String> _categories = ArtEventModel.categories;

  @override
  void initState() {
    super.initState();
    _fetchDynamicEvents();
  }

  Future<void> _fetchDynamicEvents() async {
    try {
      final apiClient = sl<ApiClient>();
      final response = await apiClient.get(ApiEndpoints.events);
      if (response is Map<String, dynamic> && response['data'] is List) {
        final List list = response['data'];
        final fetched = list.map((json) {
          return ArtEventModel(
            id: json['id']?.toString() ?? 'event_${DateTime.now().millisecondsSinceEpoch}',
            title: json['title'] ?? 'Art Event',
            category: json['category'] ?? 'Art Exhibition',
            price: (json['is_free'] == 1 || json['is_free'] == true) ? 'Free Entrance' : 'Ticketed',
            description: json['description'] ?? '',
            dateTime: json['event_date'] ?? 'Upcoming Event',
            location: json['location'] ?? 'Dubai, UAE',
            attendeesCount: 12,
            maxAttendees: 100,
            organizer: json['organizer_name'] ?? 'Dubai Culture',
            tags: (json['tags'] is String && (json['tags'] as String).isNotEmpty)
                ? (json['tags'] as String).split(',')
                : ['Art', 'Event'],
          );
        }).toList();

        if (fetched.isNotEmpty && mounted) {
          setState(() {
            _allEvents = fetched;
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _isLoggedIn {
    try {
      return sl<StorageService>().getBool('is_logged_in') ?? false;
    } catch (_) {
      return false;
    }
  }

  void _handleProtectedAction({
    required VoidCallback onAuthorized,
    required String promptMessage,
  }) {
    if (_isLoggedIn) {
      onAuthorized();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            promptMessage,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: const Color(0xFF6A2777),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Login',
            textColor: Colors.white,
            onPressed: () {
              if (mounted) {
                context.push(RouteNames.login);
              }
            },
          ),
        ),
      );
      if (mounted) {
        context.push(RouteNames.login);
      }
    }
  }

  void _showEventDetails(ArtEventModel event) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EventDetailView(event: event)),
    );
  }

  void _showBookTicketsModal(ArtEventModel event) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final ticketsController = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Row with Close Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          'Book tickets: ${event.title}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E1E1E),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Color(0xFF64748B),
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Please provide your details to confirm your booking.',
                    style: TextStyle(fontSize: 13.5, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 18),

                  // Name Field
                  const Text(
                    'Name',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'Your full name',
                      hintStyle: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13.5,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF5E227A),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Email Field
                  const Text(
                    'Email',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'you@example.com',
                      hintStyle: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13.5,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF5E227A),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Phone Field
                  const Text(
                    'Phone (optional)',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: '+971 ...',
                      hintStyle: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13.5,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF5E227A),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Tickets Field
                  const Text(
                    'Tickets',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: ticketsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF5E227A),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Total Display
                  Text(
                    'Total: ${event.price}',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action Buttons: Cancel & Confirm Booking
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1E1E1E),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5E227A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Booking confirmed for ${event.title}!',
                              ),
                              backgroundColor: const Color(0xFF5E227A),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: const Text(
                          'Confirm Booking',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCategoryDropdown() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'Select Event Category',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _selectedCategory == category;

                    return ListTile(
                      title: Text(
                        category,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color:
                              isSelected
                                  ? const Color(0xFF6A2777)
                                  : const Color(0xFF2E2E2E),
                        ),
                      ),
                      trailing:
                          isSelected
                              ? const Icon(
                                Icons.check,
                                color: Color(0xFF6A2777),
                              )
                              : null,
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();

    final filteredEvents =
        _allEvents.where((e) {
          final matchesCategory =
              _selectedCategory == 'All Categories' ||
              e.category == _selectedCategory;
          final matchesQuery =
              query.isEmpty ||
              e.title.toLowerCase().contains(query) ||
              e.description.toLowerCase().contains(query) ||
              e.organizer.toLowerCase().contains(query) ||
              e.location.toLowerCase().contains(query);

          return matchesCategory && matchesQuery;
        }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppTopBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row (Back Arrow and Title)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF1E1E1E),
                      size: 22,
                    ),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(RouteNames.home);
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Art Events',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E1E1E),
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Discover Art Events in Dubai',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Action Row (All Events & Create Event button)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1E1E1E),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onPressed: () => context.go(RouteNames.home),
                    icon: const Icon(
                      Icons.menu_book_outlined,
                      size: 16,
                      color: Color(0xFF1E1E1E),
                    ),
                    label: const Text(
                      'All Events',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 40,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6A2777),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onPressed: () {
                        _handleProtectedAction(
                          onAuthorized: () {
                            context.push(RouteNames.createArtEvent);
                          },
                          promptMessage: 'Please log in to create an event',
                        );
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text(
                        'Create Event',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search Bar
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search events...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 14.5,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF5F6368),
                    size: 22,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF2E2E3E),
                      width: 1.0,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: const Color(0xFF2E2E3E).withValues(alpha: 0.5),
                      width: 1.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF6A2777),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Category Selector Box
              InkWell(
                onTap: _showCategoryDropdown,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 12.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF2E2E3E).withValues(alpha: 0.5),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedCategory,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1E1E1E),
                        ),
                      ),
                      const Icon(
                        Icons.unfold_more,
                        color: Color(0xFF5F6368),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Events Cards List
              if (filteredEvents.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_busy_outlined,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No events found',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredEvents.length,
                  separatorBuilder:
                      (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final event = filteredEvents[index];
                    return _buildEventCard(event);
                  },
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildEventCard(ArtEventModel event) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2E2E3E).withValues(alpha: 0.2),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Category Tag and Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8F6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  event.category,
                  style: const TextStyle(
                    color: Color(0xFF6A2777),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                event.price,
                style: const TextStyle(
                  color: Color(0xFF6A2777),
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            event.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 6),

          // Description
          Text(
            event.description,
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),

          // Date & Time
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  event.dateTime,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4A4A4A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Location
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  event.location,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4A4A4A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Attendees
          Row(
            children: [
              const Icon(
                Icons.people_outline,
                size: 16,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Text(
                '${event.attendeesCount}/${event.maxAttendees} attendees',
                style: const TextStyle(fontSize: 13, color: Color(0xFF4A4A4A)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Organized by
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              children: [
                const TextSpan(text: 'Organized by '),
                TextSpan(
                  text: event.organizer,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tags
          Wrap(
            spacing: 6,
            children:
                event.tags
                    .map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 16),

          // Action Buttons: Book Now & View Details (Matches Screenshot media_1787744080054.png)
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF8FAFC),
                      foregroundColor: const Color(0xFF1E1E1E),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    onPressed: () {
                      _showBookTicketsModal(event);
                    },
                    child: const Text(
                      'Book Now',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A2777),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: () => _showEventDetails(event),
                    child: const Text(
                      'View Details',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
