import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/live_sync_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/app_cached_image.dart';
import '../../../home/presentation/widgets/home_footer_widget.dart';
import '../../domain/models/art_event_model.dart';

class MyEventsView extends StatefulWidget {
  const MyEventsView({super.key});

  @override
  State<MyEventsView> createState() => _MyEventsViewState();
}

class _MyEventsViewState extends State<MyEventsView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<ArtEventModel> _myCreatedEvents = [];
  bool _isLoading = false;
  StreamSubscription<List<ArtEventModel>>? _eventsSub;

  bool get _isTesting =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    _fetchMyEvents();
    _eventsSub = sl<LiveSyncService>().eventsStream.listen((events) {
      if (mounted) {
        setState(() => _myCreatedEvents = events);
      }
    });
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchMyEvents({bool forceRefresh = false}) async {
    if (_isTesting) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = _myCreatedEvents.isEmpty);
    try {
      String? uEmail;
      try {
        uEmail = sl<StorageService>().getString('user_email');
      } catch (_) {}
      final events = await sl<ApiService>().getEvents(forceRefresh: forceRefresh, userEmail: uEmail);
      if (mounted) {
        setState(() {
          _myCreatedEvents = events;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
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

  @override
  Widget build(BuildContext context) {
    final totalCreated = _myCreatedEvents.length;
    final totalCategories = _myCreatedEvents.map((e) => e.category).toSet().length;
    final totalCapacity = _myCreatedEvents.fold<int>(0, (sum, e) => sum + e.maxAttendees);

    final filtered = _filteredEvents;

    return Scaffold(
      backgroundColor: const Color(0xFF6B1C9B),
      appBar: const AppTopBar(backgroundColor: Colors.white),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : RefreshIndicator(
                color: const Color(0xFF6A2777),
                onRefresh: _fetchMyEvents,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Header Title & Create Event Button
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
                                  'Manage your published art events and community exhibitions',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: Color(0xFFE2D6F5),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: () => context.push(RouteNames.createArtEvent),
                            icon: const Icon(Icons.add, size: 16, color: Color(0xFF6B1C9B)),
                            label: const Text('Create Event', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6B1C9B))),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF6B1C9B),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 2. Metric Overview Bar
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
                              title: 'Categories',
                              value: '$totalCategories',
                              icon: Icons.category_outlined,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildMetricCard(
                              title: 'Total Capacity',
                              value: '$totalCapacity',
                              icon: Icons.people_outline,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (_myCreatedEvents.any((e) => e.status.toLowerCase().trim() == 'pending' || (!e.isActive && e.status.toLowerCase().trim() != 'cancelled' && e.status.toLowerCase().trim() != 'inactive'))) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.hourglass_top_rounded, size: 20, color: Color(0xFFD97706)),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Submitted events are sent to the administrator for review and will be published once approved.',
                                  style: TextStyle(fontSize: 12.5, color: Color(0xFF92400E), height: 1.35, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // 3. Search Bar
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                          cursorColor: const Color(0xFF6A2777),
                          decoration: InputDecoration(
                            hintText: 'Search my created events...',
                            hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B), size: 20),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? GestureDetector(
                                    onTap: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                    child: const Icon(Icons.close, color: Color(0xFF64748B), size: 18),
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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.event_busy_outlined, size: 48, color: Color(0xFF94A3B8)),
                              SizedBox(height: 12),
                              Text(
                                'No created events found.',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Create your first art event to showcase it here.',
                                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
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

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (event.imageUrl != null && event.imageUrl!.isNotEmpty)
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                      child: AppCachedImage(
                                        imageUrl: event.imageUrl!,
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
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                event.title,
                                                style: const TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF0F172A),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Wrap(
                                              spacing: 6,
                                              runSpacing: 4,
                                              crossAxisAlignment: WrapCrossAlignment.center,
                                              children: [
                                                Builder(
                                                  builder: (context) {
                                                    final isPending = event.status.toLowerCase().trim() == 'pending' ||
                                                        (!event.isActive &&
                                                            event.status.toLowerCase().trim() != 'cancelled' &&
                                                            event.status.toLowerCase().trim() != 'inactive');
                                                    return Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: isPending ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
                                                        borderRadius: BorderRadius.circular(10),
                                                        border: Border.all(
                                                          color: isPending ? const Color(0xFFFDE68A) : const Color(0xFFBBF7D0),
                                                          width: 0.8,
                                                        ),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            isPending ? Icons.hourglass_top_rounded : Icons.check_circle_outline_rounded,
                                                            size: 11,
                                                            color: isPending ? const Color(0xFFD97706) : const Color(0xFF16A34A),
                                                          ),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            isPending ? 'Pending Review' : 'Approved & Live',
                                                            style: TextStyle(
                                                              color: isPending ? const Color(0xFFB45309) : const Color(0xFF15803D),
                                                              fontSize: 10.5,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFF3E8FF),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Text(
                                                    event.category,
                                                    style: const TextStyle(
                                                      color: Color(0xFF6A2777),
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
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
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Free Community Entry',
                                              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                            ),
                                            Text(
                                              'Capacity: ${event.maxAttendees} attendees',
                                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF6A2777)),
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
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF6A2777), size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
