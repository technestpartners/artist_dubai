import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/live_sync_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../domain/models/art_event_model.dart';

class EventsView extends StatefulWidget {
  const EventsView({super.key});

  @override
  State<EventsView> createState() => _EventsViewState();
}

class _EventsViewState extends State<EventsView> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All Categories';
  List<ArtEventModel> _allEvents = [];
  List<String> _categories = ['All Categories'];
  final Set<String> _likedEventIds = {};
  final GlobalKey _categorySelectorKey = GlobalKey();
  OverlayEntry? _categoryOverlayEntry;
  bool _isCategoryListExpanded = false;
  StreamSubscription<List<ArtEventModel>>? _eventsSub;
  StreamSubscription<Map<String, dynamic>>? _favSub;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
    _fetchCategories();
    _eventsSub = sl<LiveSyncService>().eventsStream.listen((events) {
      if (mounted) {
        setState(() {
          _allEvents = events;
        });
      }
    });
    _favSub = sl<LiveSyncService>().favoritesStream.listen((favData) {
      if (mounted && favData.isNotEmpty) {
        final favEvents = (favData['events'] as List<ArtEventModel>?) ?? [];
        final favIds = favEvents.map((e) => e.id).toSet();
        setState(() {
          _likedEventIds.clear();
          _likedEventIds.addAll(favIds);
        });
      }
    });
  }

  void _hideCategoryOverlay() {
    _categoryOverlayEntry?.remove();
    _categoryOverlayEntry = null;
    if (mounted) {
      setState(() => _isCategoryListExpanded = false);
    }
  }

  Future<void> _fetchEvents({bool forceRefresh = false}) async {
    try {
      final userEmail = sl<StorageService>().getString('user_email');
      final results = await Future.wait([
        sl<ApiService>().getEvents(forceRefresh: forceRefresh),
        if (userEmail != null && userEmail.isNotEmpty)
          sl<ApiService>().getFavorites(email: userEmail, forceRefresh: forceRefresh)
        else
          Future.value(<String, dynamic>{'events': <ArtEventModel>[]}),
      ]);

      final events = results[0] as List<ArtEventModel>;
      final favData = results[1] as Map<String, dynamic>;
      final favEvents = (favData['events'] as List<ArtEventModel>?) ?? [];
      final favIds = favEvents.map((e) => e.id).toSet();

      if (mounted) {
        setState(() {
          _allEvents = events;
          _likedEventIds.clear();
          _likedEventIds.addAll(favIds);
        });
      }
    } catch (_) {}
  }

  void _shareEvent(ArtEventModel event) {
    Clipboard.setData(
      ClipboardData(
        text: 'Check out ${event.title} on Artist Dubai: https://artistdubai.com/events/${event.id}',
      ),
    );
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Event link for "${event.title}" copied to clipboard!',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF6A2777),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleEventLike(ArtEventModel event) async {
    final userEmail = sl<StorageService>().getString('user_email') ?? '';
    final wasLiked = _likedEventIds.contains(event.id);

    setState(() {
      if (wasLiked) {
        _likedEventIds.remove(event.id);
      } else {
        _likedEventIds.add(event.id);
      }
    });

    if (userEmail.isNotEmpty) {
      await sl<ApiService>().toggleFavorite(
        email: userEmail,
        itemType: 'event',
        itemId: event.id,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasLiked
                ? 'Removed "${event.title}" from saved events'
                : 'Saved "${event.title}" to favorites! ❤️',
          ),
          backgroundColor: wasLiked ? null : const Color(0xFF6A2777),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final cats = await sl<ApiService>().getCategories(type: 'event');
      if (mounted && cats.isNotEmpty) {
        setState(() {
          _categories = ['All Categories', ...cats.map((c) => c.name)];
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    _favSub?.cancel();
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
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (mounted) {
        context.push(RouteNames.login);
      }
    }
  }

  void _showEventDetails(ArtEventModel event) {
    context.push(RouteNames.eventDetail, extra: event);
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
        child: RefreshIndicator(
          color: const Color(0xFF6A2777),
          onRefresh: () => _fetchEvents(forceRefresh: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              // Header Row (Back Arrow and Title matching reference)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(RouteNames.home);
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(right: 12.0, top: 4.0, bottom: 4.0),
                      child: Icon(
                        Icons.arrow_back,
                        color: Color(0xFF1E1E1E),
                        size: 20,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
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
                        SizedBox(height: 2),
                        Text(
                          'Discover Art Events in Dubai',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF5B6E8C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Action Row (Home Breadcrumb & Wide Create Event Button)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => context.go(RouteNames.home),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.home_outlined,
                            size: 18,
                            color: Color(0xFF1E1E1E),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Home',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E1E1E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B267B),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add, size: 17, color: Colors.white),
                          SizedBox(width: 5),
                          Text(
                            'Create Event',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

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

              // Category Selector Box (Floating Dropdown)
              _buildCategorySelectorField(),
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
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildCategorySelectorField() {
    return Container(
      key: _categorySelectorKey,
      child: InkWell(
        onTap: () {
          if (_isCategoryListExpanded) {
            _hideCategoryOverlay();
          } else {
            _showCategoryOverlay();
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isCategoryListExpanded
                  ? const Color(0xFF6A2777)
                  : const Color(0xFF2E2E3E).withValues(alpha: 0.5),
              width: _isCategoryListExpanded ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _selectedCategory,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
              ),
              Icon(
                _isCategoryListExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: const Color(0xFF5F6368),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCategoryOverlay() {
    _hideCategoryOverlay();

    final renderBox = _categorySelectorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;

    final double neededHeight = _categories.length * 36.0 + 8.0;
    final double spaceBelow = screenHeight - (offset.dy + size.height) - mediaQuery.padding.bottom - 16.0;
    final double spaceAbove = offset.dy - mediaQuery.padding.top - 16.0;

    final double availableSpace = (spaceBelow >= neededHeight || spaceBelow >= spaceAbove) ? spaceBelow : spaceAbove;
    final double popupHeight = neededHeight.clamp(80.0, availableSpace.clamp(180.0, screenHeight - 60.0));

    final bool showAbove = spaceBelow < popupHeight && spaceAbove > spaceBelow;

    final double topPosition = showAbove
        ? (offset.dy - popupHeight - 4).clamp(mediaQuery.padding.top + 8.0, screenHeight - popupHeight)
        : (offset.dy + size.height + 4).clamp(0.0, screenHeight - popupHeight - mediaQuery.padding.bottom);

    _categoryOverlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _hideCategoryOverlay,
                child: Container(color: Colors.transparent),
              ),
            ),
            Positioned(
              left: offset.dx.clamp(16.0, (screenWidth - size.width - 16.0).clamp(16.0, screenWidth)),
              top: topPosition,
              width: size.width,
              height: popupHeight,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.18),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      shrinkWrap: true,
                      itemCount: _categories.length,
                      separatorBuilder: (context, index) => const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFF1F5F9),
                      ),
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = _selectedCategory == cat;

                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedCategory = cat;
                            });
                            _hideCategoryOverlay();
                            _fetchEvents();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14.0,
                              vertical: 8.5,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    cat,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected ? const Color(0xFF6A2777) : const Color(0xFF1E1E1E),
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check,
                                    size: 18,
                                    color: Color(0xFF6A2777),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_categoryOverlayEntry!);
    setState(() {
      _isCategoryListExpanded = true;
    });
  }

  Widget _buildEventCard(ArtEventModel event) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showEventDetails(event),
        borderRadius: BorderRadius.circular(12),
        child: Container(
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
          // Top Row: Category Tag, Price, Share & Heart buttons
          Row(
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
              const Spacer(),
              if (_isLoggedIn) ...[
                // Share button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _shareEvent(event),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.share_outlined,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Like/Favorite ❤️ button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _toggleEventLike(event),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _likedEventIds.contains(event.id)
                            ? const Color(0xFFE11D48).withValues(alpha: 0.1)
                            : Colors.transparent,
                        border: Border.all(
                          color: _likedEventIds.contains(event.id)
                              ? const Color(0xFFE11D48)
                              : const Color(0xFFE2E8F0),
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        _likedEventIds.contains(event.id)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 16,
                        color: _likedEventIds.contains(event.id)
                            ? const Color(0xFFE11D48)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              ],
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

          // Action Button: View Details
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A2777),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => _showEventDetails(event),
              child: const Text(
                'View Details',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    ),
    );
  }
}
