import 'dart:async';
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/favorites_service.dart';
import '../../../../core/services/live_sync_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_cached_image.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../domain/models/art_event_model.dart';
import '../../../artists/domain/models/artist_model.dart';
import '../../../../core/utils/data_translator.dart';
import '../../../../core/utils/share_helper.dart';
import 'package:artist_dubai/l10n/app_localizations.dart';

class EventsView extends StatefulWidget {
  final int initialTabIndex;
  const EventsView({super.key, this.initialTabIndex = 0});

  @override
  State<EventsView> createState() => _EventsViewState();
}

class _EventsViewState extends State<EventsView> with WidgetsBindingObserver {
  late int _selectedViewMode; // 0 = What's On hub, 1 = Discover / Filtered results, 2 = Favourites

  final ScrollController _featuredScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All Categories';
  String _activeDateFilter = 'All'; // 'All', 'Today', 'This Week', 'Custom Dates'
  DateTimeRange? _customDateRange;
  String _activePriceFilter = 'All'; // 'All', 'Free', 'Paid'
  String _sortBy = 'Soonest'; // 'Soonest', 'Title A-Z', 'Price'

  static const List<String> _defaultCategories = [
    'All Categories',
    'Arabic Calligraphy',
    'Calligraphy & Typography',
    'Contemporary Painting',
    'Art Exhibition',
    'Digital Art & Sculpture',
    'Photography',
    'Abstract Painting',
    'Ceramics & Pottery',
    'Art Workshop',
    'Cultural Festival',
    'Gallery Opening',
    'Music & Concerts',
    'Sports & Fitness',
  ];

  List<ArtEventModel> _allEvents = [];
  late List<String> _categories = List<String>.from(_defaultCategories);
  final Set<String> _likedEventIds = {};

  StreamSubscription<List<ArtEventModel>>? _eventsSub;
  StreamSubscription<Map<String, dynamic>>? _favSub;
  StreamSubscription<List<CategoryInfo>>? _catSub;
  StreamSubscription<bool>? _authSub;
  Timer? _periodicSyncTimer;

  // Artist Dubai Brand Palette
  static const Color _primaryPurple = Color(0xFF6B1C9B);
  static const Color _darkBg = Color(0xFF6B1C9B);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedViewMode = widget.initialTabIndex == 1 ? 1 : 0;
    _likedEventIds.addAll(sl<FavoritesService>().eventIds);
    sl<FavoritesService>().addListener(_onFavoritesChanged);
    _fetchEvents();
    _fetchCategories();

    if (!_isTesting) {
      _periodicSyncTimer = Timer.periodic(const Duration(seconds: 12), (_) {
        if (mounted) {
          _fetchEvents(forceRefresh: true);
        }
      });
    }

    _authSub = sl<LiveSyncService>().authStream.listen((isLoggedIn) {
      if (mounted) {
        setState(() {});
        if (isLoggedIn) {
          _fetchEvents(forceRefresh: true);
        }
      }
    });

    _eventsSub = sl<LiveSyncService>().eventsStream.listen((events) {
      if (mounted) {
        setState(() {
          _allEvents = events.where((e) => e.isActive && e.status.toLowerCase() != 'pending').toList();
        });
      }
    });

    _catSub = sl<LiveSyncService>().categoriesStream.listen((cats) {
      if (mounted && cats.isNotEmpty) {
        final merged = <String>{..._defaultCategories};
        for (final c in cats) {
          if (c.name.trim().isNotEmpty) {
            merged.add(c.name.trim());
          }
        }
        setState(() {
          _categories = merged.toList();
        });
      }
    });

    _favSub = sl<LiveSyncService>().favoritesStream.listen((favData) {
      if (mounted && favData.isNotEmpty) {
        sl<FavoritesService>().updateFromServer(favData);
      }
    });

    DataTranslator.translationNotifier.addListener(_onTranslationChanged);
  }

  void _onFavoritesChanged() {
    if (mounted) {
      setState(() {
        _likedEventIds.clear();
        _likedEventIds.addAll(sl<FavoritesService>().eventIds);
      });
    }
  }

  void _onTranslationChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _fetchEvents(forceRefresh: true);
    }
  }

  @override
  void dispose() {
    sl<FavoritesService>().removeListener(_onFavoritesChanged);
    DataTranslator.translationNotifier.removeListener(_onTranslationChanged);
    WidgetsBinding.instance.removeObserver(this);
    _periodicSyncTimer?.cancel();
    _authSub?.cancel();
    _eventsSub?.cancel();
    _favSub?.cancel();
    _catSub?.cancel();
    _searchController.dispose();
    _featuredScrollController.dispose();
    super.dispose();
  }

  bool get _isTesting =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  bool get _isLoggedIn {
    try {
      return sl<StorageService>().getBool('is_logged_in') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _fetchEvents({bool forceRefresh = false}) async {
    try {
      final effectiveEmail = sl<FavoritesService>().getEffectiveEmail();
      final results = await Future.wait([
        sl<ApiService>().getEvents(forceRefresh: forceRefresh),
        sl<ApiService>().getFavorites(email: effectiveEmail, forceRefresh: forceRefresh),
      ]);

      final events = results[0] as List<ArtEventModel>;
      final favData = results[1] as Map<String, dynamic>;
      sl<FavoritesService>().updateFromServer(favData);

      if (mounted) {
        setState(() {
          _allEvents = events.where((e) => e.isActive && e.status.toLowerCase() != 'pending').toList();
          _likedEventIds.clear();
          _likedEventIds.addAll(sl<FavoritesService>().eventIds);
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchCategories() async {
    try {
      final cats = await sl<ApiService>().getCategories(type: 'event');
      if (mounted && cats.isNotEmpty) {
        final merged = <String>{..._defaultCategories};
        for (final c in cats) {
          if (c.name.trim().isNotEmpty) {
            merged.add(c.name.trim());
          }
        }
        setState(() {
          _categories = merged.toList();
        });
      }
    } catch (_) {}
  }

  List<ArtEventModel> get _combinedEvents {
    if (_allEvents.isEmpty) {
      return ArtEventModel.mockEvents;
    }
    final list = List<ArtEventModel>.from(_allEvents);
    final existingTitles = list.map((e) => e.title.toLowerCase().trim()).toSet();
    for (final mock in ArtEventModel.mockEvents) {
      if (!existingTitles.contains(mock.title.toLowerCase().trim())) {
        list.add(mock);
      }
    }
    return list;
  }

  bool get _isFilterActive =>
      _searchController.text.isNotEmpty ||
      _activeDateFilter != 'All' ||
      _selectedCategory != 'All Categories' ||
      _activePriceFilter != 'All';

  void _clearAllFilters() {
    setState(() {
      _searchController.clear();
      _activeDateFilter = 'All';
      _customDateRange = null;
      _activePriceFilter = 'All';
      _selectedCategory = 'All Categories';
      _sortBy = 'Soonest';
      _selectedViewMode = 0;
    });
  }

  double _extractPrice(String price) {
    final lower = price.toLowerCase();
    if (lower.contains('free') || lower.contains('مجاني')) return 0.0;
    final match = RegExp(r'\d+(\.\d+)?').firstMatch(lower);
    if (match != null) {
      return double.tryParse(match.group(0)!) ?? 0.0;
    }
    return 0.0;
  }

  bool _matchesCategory(ArtEventModel e, String selectedCategory) {
    final sel = selectedCategory.trim().toLowerCase();
    if (sel == 'all categories' || sel == 'all' || sel == 'الكل' || sel == 'جميع الفئات' || sel.isEmpty) {
      return true;
    }

    final cat = e.category.trim().toLowerCase();
    if (cat == sel || cat.contains(sel) || sel.contains(cat)) return true;

    // Tag matching
    for (final tag in e.tags) {
      final t = tag.trim().toLowerCase();
      if (t == sel || t.contains(sel) || sel.contains(t)) return true;
    }

    // Token keyword match (tokens of length >= 4)
    final selTokens = sel.split(RegExp(r'[\s&,/]+')).where((w) => w.length >= 4).toList();
    for (final token in selTokens) {
      if (cat.contains(token)) return true;
      for (final tag in e.tags) {
        if (tag.toLowerCase().contains(token)) return true;
      }
    }

    // Title / Description matching
    if (e.title.toLowerCase().contains(sel) || e.description.toLowerCase().contains(sel)) {
      return true;
    }

    return false;
  }

  bool _matchesDate(ArtEventModel e, String filter, DateTimeRange? customRange) {
    if (filter == 'All') return true;

    final rawDate = '${e.dateTime} ${e.formattedDate}'.toLowerCase();

    if (filter == 'Today') {
      if (rawDate.contains('today') || rawDate.contains('اليوم')) return true;
      final now = DateTime.now();
      final todayIso = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      if (rawDate.contains(todayIso)) return true;

      final months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
      final mStr = months[now.month - 1];
      final dayStr = now.day.toString();
      if (rawDate.contains(mStr) && rawDate.contains(dayStr)) return true;

      return _isEventActiveOnDate(e, now);
    }

    if (filter == 'This Week') {
      if (rawDate.contains('today') || rawDate.contains('this week') || rawDate.contains('هذا الأسبوع') || rawDate.contains('tomorrow')) {
        return true;
      }
      final now = DateTime.now();
      for (int i = 0; i < 7; i++) {
        final day = now.add(Duration(days: i));
        final months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
        final mStr = months[day.month - 1];
        final dayStr = day.day.toString();
        if (rawDate.contains(mStr) && rawDate.contains(dayStr)) return true;
        if (_isEventActiveOnDate(e, day)) return true;
      }
      return false;
    }

    if (filter == 'Custom Dates' && customRange != null) {
      final start = customRange.start;
      final end = customRange.end;
      for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
        final months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
        final mStr = months[d.month - 1];
        final dayStr = d.day.toString();
        if (rawDate.contains(mStr) && rawDate.contains(dayStr)) return true;
        if (_isEventActiveOnDate(e, d)) return true;
      }
      return false;
    }

    return true;
  }

  bool _isEventActiveOnDate(ArtEventModel e, DateTime target) {
    final isoMatches = RegExp(r'\b\d{4}-\d{2}-\d{2}\b').allMatches(e.dateTime);
    if (isoMatches.isNotEmpty) {
      try {
        final dates = isoMatches.map((m) => DateTime.parse(m.group(0)!)).toList();
        if (dates.length == 1) {
          final d = dates.first;
          return d.year == target.year && d.month == target.month && d.day == target.day;
        } else if (dates.length >= 2) {
          final start = dates[0];
          final end = dates[1];
          return !target.isBefore(start) && !target.isAfter(end);
        }
      } catch (_) {}
    }
    return false;
  }

  bool _matchesPrice(ArtEventModel e, String filter) {
    if (filter == 'All') return true;
    final p = e.price.trim().toLowerCase();
    final isFree = p == 'free' || p == '0' || p == '0 aed' || p.contains('مجاني') || p.isEmpty;
    if (filter == 'Free') return isFree;
    if (filter == 'Paid') return !isFree;
    return true;
  }

  List<ArtEventModel> _getFilteredEvents() {
    final query = _searchController.text.trim().toLowerCase();

    var list = _combinedEvents.where((e) {
      if (!e.isActive) return false;
      final st = e.status.toLowerCase().trim();
      if (st == 'cancelled' || st == 'inactive' || st == 'draft' || st == 'deleted' || st == 'pending') {
        return false;
      }

      // 1. Category Filter
      if (!_matchesCategory(e, _selectedCategory)) return false;

      // 2. Query Filter
      if (query.isNotEmpty) {
        final matchesQuery = e.title.toLowerCase().contains(query) ||
            e.localizedTitle(context).toLowerCase().contains(query) ||
            e.description.toLowerCase().contains(query) ||
            e.category.toLowerCase().contains(query) ||
            e.organizer.toLowerCase().contains(query) ||
            e.location.toLowerCase().contains(query) ||
            e.tags.any((t) => t.toLowerCase().contains(query));
        if (!matchesQuery) return false;
      }

      // 3. Price Filter
      if (!_matchesPrice(e, _activePriceFilter)) return false;

      // 4. Date Filter
      if (!_matchesDate(e, _activeDateFilter, _customDateRange)) return false;

      return true;
    }).toList();

    // Sorting
    if (_sortBy == 'Title (A - Z)' || _sortBy == 'Title A-Z') {
      list.sort((a, b) => a.title.compareTo(b.title));
    } else if (_sortBy == 'Price: Low to High') {
      list.sort((a, b) => _extractPrice(a.price).compareTo(_extractPrice(b.price)));
    } else if (_sortBy == 'Price: High to Low' || _sortBy == 'Price') {
      list.sort((a, b) => _extractPrice(b.price).compareTo(_extractPrice(a.price)));
    } else if (_sortBy == 'Most Popular') {
      list.sort((a, b) => b.attendeesCount.compareTo(a.attendeesCount));
    }

    return list;
  }

  void _toggleEventLike(ArtEventModel event) async {
    final wasLiked = _likedEventIds.contains(event.id);
    final nowLiked = await sl<FavoritesService>().toggleEventFavorite(event.id);

    if (mounted) {
      setState(() {
        if (nowLiked) {
          _likedEventIds.add(event.id);
        } else {
          _likedEventIds.remove(event.id);
        }
      });

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasLiked
                ? 'Removed "${event.title}" from saved events'
                : 'Saved "${event.title}" to favorites! ❤️',
          ),
          backgroundColor: wasLiked ? null : _primaryPurple,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showEventDetails(ArtEventModel event) {
    context.push(RouteNames.eventDetailWithId(event.id), extra: event);
  }

  void _shareEvent(ArtEventModel event) {
    ShareHelper.shareEvent(
      context: context,
      eventId: event.id,
      title: event.title,
      location: event.location,
      imageUrl: event.imageUrl,
      dateTime: event.dateTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    final rh = ResponsiveHelper.of(context);
    final filteredEvents = _getFilteredEvents();

    return Scaffold(
      backgroundColor: _darkBg,
      appBar: const AppTopBar(),
      body: SafeArea(
        child: RefreshIndicator(
          color: _primaryPurple,
          onRefresh: () => _fetchEvents(forceRefresh: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: rh.horizontalPadding, vertical: 12.0),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: rh.contentMaxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Header with Title & Register Event Button (Artist Dubai Theme)
                    _buildHeaderSection(),
                    const SizedBox(height: 14),

                    // 2. Search Field
                    _buildSearchBar(),
                    const SizedBox(height: 12),

                    // 3. Quick Date Filter Tabs: [ Today ] [ This Week ] [ Custom Dates ] (from reference)
                    _buildQuickDateFilterTabs(),
                    const SizedBox(height: 14),

                    // 4. Secondary Filter Chips: [ Category ] [ Sort By ]
                    _buildFilterChipsRow(),
                    const SizedBox(height: 20),

                    // 5. Active Filter Badges (if filtered)
                    if (_isFilterActive)
                      _buildActiveFilterBadges(),

                    // 6. Main Content: If search/filter active or Discover mode selected, show Search Results; else show Featured + Recommended
                    if (_selectedViewMode == 1 || _isFilterActive)
                      _buildSearchResultsSection(filteredEvents)
                    else
                      _buildWhatsOnSections(filteredEvents),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
    );
  }

  // -------------------------------------------------------------
  // Header Section (Artist Dubai Theme)
  // -------------------------------------------------------------
  Widget _buildHeaderSection() {
    final l10n = AppLocalizations.of(context);
    final canGoBack = Navigator.canPop(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (canGoBack)
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsetsDirectional.only(end: 12.0, top: 4.0, bottom: 4.0),
              child: Icon(Icons.arrow_back, color: Colors.white, size: 22),
            ),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "What's On".trData(context),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.eventsSubtitle,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFFE2D6F5),
                ),
              ),
            ],
          ),
        ),
        // Create Event Button
        SizedBox(
          height: 38,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _primaryPurple,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () {
              if (_isLoggedIn) {
                context.push(RouteNames.createArtEvent);
              } else {
                context.push(RouteNames.login);
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, size: 16, color: _primaryPurple),
                const SizedBox(width: 4),
                Text(
                  l10n.registerArtEvent,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _primaryPurple,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // Search Bar
  // -------------------------------------------------------------
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14.5),
        cursorColor: _primaryPurple,
        decoration: InputDecoration(
          hintText: 'Search Events'.trData(context),
          hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14.5),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B), size: 22),
          suffixIcon: _searchController.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() {});
                  },
                  child: const Icon(Icons.close, color: Color(0xFF64748B), size: 20),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // Quick Date Filter Tabs: [ Today ] [ This Week ] [ Custom Dates ] (Reference)
  // -------------------------------------------------------------
  Widget _buildQuickDateFilterTabs() {
    return Row(
      children: [
        Expanded(
          child: _buildDatePill(
            title: 'Today'.trData(context),
            isSelected: _activeDateFilter == 'Today',
            onTap: () {
              setState(() {
                _activeDateFilter = _activeDateFilter == 'Today' ? 'All' : 'Today';
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildDatePill(
            title: 'This Week'.trData(context),
            isSelected: _activeDateFilter == 'This Week',
            onTap: () {
              setState(() {
                _activeDateFilter = _activeDateFilter == 'This Week' ? 'All' : 'This Week';
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildDatePill(
            title: 'Custom Dates'.trData(context),
            isSelected: _activeDateFilter == 'Custom Dates',
            onTap: () async {
              final picked = await _pickDateRange();
              if (picked != null) {
                setState(() {
                  _customDateRange = picked;
                  _activeDateFilter = 'Custom Dates';
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Future<DateTimeRange?> _pickDateRange() async {
    final now = DateTime.now();
    return showDateRangePicker(
      context: context,
      initialDateRange: _customDateRange,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Select Date Range'.trData(context),
      saveText: 'Save'.trData(context),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryPurple,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1E293B),
              secondaryContainer: Color(0xFFF3E8FF),
              onSecondaryContainer: Color(0xFF581C87),
            ),
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: _primaryPurple,
              foregroundColor: Colors.white,
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.white),
              actionsIconTheme: IconThemeData(color: Colors.white),
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              headerBackgroundColor: _primaryPurple,
              headerForegroundColor: Colors.white,
              headerHeadlineStyle: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              headerHelpStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
              rangePickerBackgroundColor: Colors.white,
              rangePickerSurfaceTintColor: Colors.transparent,
              rangePickerHeaderBackgroundColor: _primaryPurple,
              rangePickerHeaderForegroundColor: Colors.white,
              rangePickerHeaderHeadlineStyle: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              rangePickerHeaderHelpStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
              rangeSelectionBackgroundColor: const Color(0xFFF3E8FF),
              rangeSelectionOverlayColor: WidgetStateProperty.all(
                _primaryPurple.withValues(alpha: 0.12),
              ),
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                if (states.contains(WidgetState.disabled)) {
                  return Colors.grey.shade400;
                }
                return const Color(0xFF1E293B);
              }),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return _primaryPurple;
                }
                return null;
              }),
              todayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return _primaryPurple;
              }),
              todayBorder: const BorderSide(color: _primaryPurple, width: 1.5),
              weekdayStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
  }

  Widget _buildDatePill({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isSelected ? _primaryPurple : Colors.white,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // Filter Chips Row: [ Category ] [ Sort By ] (Reference)
  // -------------------------------------------------------------
  Widget _buildFilterChipsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            label: _selectedCategory == 'All Categories' ? 'Category'.trData(context) : _selectedCategory.trData(context),
            isActive: _selectedCategory != 'All Categories',
            onTap: _showCategoryFilterDialog,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: _sortBy == 'Soonest' ? 'Sort By'.trData(context) : _sortBy.trData(context),
            isActive: _sortBy != 'Soonest',
            onTap: _showSortDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.3),
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? _primaryPurple : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFilterBadges() {
    if (!_isFilterActive) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (_activeDateFilter != 'All')
            _buildActiveBadge(
              label: _activeDateFilter == 'Custom Dates' && _customDateRange != null
                  ? '${_customDateRange!.start.day}/${_customDateRange!.start.month} - ${_customDateRange!.end.day}/${_customDateRange!.end.month}'
                  : _activeDateFilter.trData(context),
              onRemove: () => setState(() {
                _activeDateFilter = 'All';
                _customDateRange = null;
              }),
            ),
          if (_activePriceFilter != 'All')
            _buildActiveBadge(
              label: (_activePriceFilter == 'Free' ? 'Free Admission' : 'Paid').trData(context),
              onRemove: () => setState(() => _activePriceFilter = 'All'),
            ),
          if (_selectedCategory != 'All Categories')
            _buildActiveBadge(
              label: _selectedCategory.trData(context),
              onRemove: () => setState(() => _selectedCategory = 'All Categories'),
            ),
          if (_searchController.text.isNotEmpty)
            _buildActiveBadge(
              label: '"${_searchController.text}"',
              onRemove: () => setState(() => _searchController.clear()),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveBadge({required String label, required VoidCallback onRemove}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _primaryPurple),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 15, color: _primaryPurple),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // What's On Mode: "Featured" Carousel + "Recommended for You"
  // -------------------------------------------------------------
  Widget _buildWhatsOnSections(List<ArtEventModel> events) {
    final featuredEvents = events.isNotEmpty ? events : ArtEventModel.mockEvents;
    final recommendedEvents = events.length > 2
        ? events.sublist(2)
        : (events.isNotEmpty ? events : ArtEventModel.mockEvents);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section: "Featured"
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Featured'.trData(context),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (featuredEvents.length > 1) ...[
                  // Scroll Left Button
                  InkWell(
                    onTap: () {
                      if (_featuredScrollController.hasClients) {
                        _featuredScrollController.animateTo(
                          (_featuredScrollController.offset - 264)
                              .clamp(0.0, _featuredScrollController.position.maxScrollExtent),
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chevron_left, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Scroll Right Button
                  InkWell(
                    onTap: () {
                      if (_featuredScrollController.hasClients) {
                        _featuredScrollController.animateTo(
                          (_featuredScrollController.offset + 264)
                              .clamp(0.0, _featuredScrollController.position.maxScrollExtent),
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chevron_right, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                GestureDetector(
                  onTap: () => setState(() => _selectedViewMode = 1),
                  child: Text(
                    'SEE ALL'.trData(context),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFF3E8F6),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Horizontal Featured Carousel (Reference Screenshot 1)
        SizedBox(
          height: 270,
          child: Listener(
            onPointerSignal: (pointerSignal) {
              if (pointerSignal is PointerScrollEvent && _featuredScrollController.hasClients) {
                final target = (_featuredScrollController.offset + pointerSignal.scrollDelta.dy)
                    .clamp(0.0, _featuredScrollController.position.maxScrollExtent);
                _featuredScrollController.jumpTo(target);
              }
            },
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.trackpad,
                  PointerDeviceKind.stylus,
                },
              ),
              child: ListView.separated(
                controller: _featuredScrollController,
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                scrollDirection: Axis.horizontal,
                itemCount: featuredEvents.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  return _buildHorizontalEventCard(featuredEvents[index]);
                },
              ),
            ),
          ),
        ),

        const SizedBox(height: 26),

        // Section: "Recommended for You" (Reference Screenshot 2)
        Text(
          'Recommended for You'.trData(context),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 14),

        for (final ev in recommendedEvents) ...[
          _buildLargeEventCard(ev),
          const SizedBox(height: 18),
        ],
      ],
    );
  }

  // -------------------------------------------------------------
  // Horizontal Featured Card (Screenshots 1 & 2 Layout in Purple Theme)
  // -------------------------------------------------------------
  Widget _buildHorizontalEventCard(ArtEventModel event) {
    final isLiked = _likedEventIds.contains(event.id);

    return GestureDetector(
      onTap: () => _showEventDetails(event),
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rounded Image with top-right circular white heart button
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 175,
                    width: 226,
                    child: event.imageUrl != null && event.imageUrl!.isNotEmpty
                        ? AppCachedImage(imageUrl: event.imageUrl!, fit: BoxFit.cover)
                        : Container(
                            color: const Color(0xFFF1F5F9),
                            child: const Icon(Icons.event, size: 48, color: Colors.grey),
                          ),
                  ),
                ),
                PositionedDirectional(
                  top: 8,
                  end: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => _shareEvent(event),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.share_outlined,
                            color: _primaryPurple,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _toggleEventLike(event),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : _primaryPurple,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Title
            Text(
              event.localizedTitle(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(height: 3),

            // Date
            Text(
              (event.dateTime.isNotEmpty ? event.dateTime : event.formattedDate).trData(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // Large Event Card (Screenshots 2 & 3 Layout in Purple Theme)
  // -------------------------------------------------------------
  Widget _buildLargeEventCard(ArtEventModel event) {
    final isLiked = _likedEventIds.contains(event.id);

    return GestureDetector(
      onTap: () => _showEventDetails(event),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 190,
                    width: double.infinity,
                    child: event.imageUrl != null && event.imageUrl!.isNotEmpty
                        ? AppCachedImage(imageUrl: event.imageUrl!, fit: BoxFit.cover)
                        : Container(
                            color: const Color(0xFFF1F5F9),
                            child: const Icon(Icons.event, size: 50, color: Colors.grey),
                          ),
                  ),
                ),
                PositionedDirectional(
                  top: 10,
                  end: 10,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => _shareEvent(event),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.share_outlined,
                            color: _primaryPurple,
                            size: 19,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _toggleEventLike(event),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : _primaryPurple,
                            size: 21,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              event.localizedTitle(context),
              style: const TextStyle(
                fontSize: 17.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(height: 4),

            Text(
              (event.dateTime.isNotEmpty ? event.dateTime : event.formattedDate).trData(context),
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // Filtered Search Results Mode (Reference Screenshot 3 Layout)
  // -------------------------------------------------------------
  Widget _buildSearchResultsSection(List<ArtEventModel> events) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Search Results'.trData(context),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            if (_isFilterActive || _selectedViewMode == 1)
              TextButton(
                onPressed: _clearAllFilters,
                child: Text(
                  'Clear All'.trData(context),
                  style: const TextStyle(color: Color(0xFFE2D6F5), fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        if (events.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            alignment: Alignment.center,
            child: Column(
              children: [
                const Icon(Icons.event_busy_outlined, size: 52, color: Colors.white70),
                const SizedBox(height: 14),
                Text(
                  'No events found matching your search.'.trData(context),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Color(0xFFE2D6F5), fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Try adjusting your dates, category, or price filters.'.trData(context),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.white60),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _clearAllFilters,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: Text('Clear All Filters'.trData(context), style: const TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _primaryPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(height: 18),
            itemBuilder: (context, index) => _buildLargeEventCard(events[index]),
          ),
      ],
    );
  }

  // -------------------------------------------------------------
  // Filter Bottom Sheets
  // -------------------------------------------------------------
  void _showCategoryFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF551478),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        String catSearch = '';
        return StatefulBuilder(
          builder: (bottomCtx, setModalState) {
            final displayCats = _categories.where((c) {
              if (catSearch.isEmpty) return true;
              return c.toLowerCase().contains(catSearch.toLowerCase()) ||
                  c.trData(context).toLowerCase().contains(catSearch.toLowerCase());
            }).toList();

            return Container(
              height: MediaQuery.of(ctx).size.height * 0.65,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter by Category'.trData(context),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      if (_selectedCategory != 'All Categories')
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(ctx);
                            setState(() => _selectedCategory = 'All Categories');
                          },
                          child: Text(
                            'Reset'.trData(context),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFE2D6F5)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Search within categories
                  TextField(
                    onChanged: (val) => setModalState(() => catSearch = val.trim()),
                    style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
                    cursorColor: _primaryPurple,
                    decoration: InputDecoration(
                      hintText: 'Search categories...'.trData(context),
                      hintStyle: const TextStyle(fontSize: 13.5, color: Color(0xFF64748B)),
                      prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.separated(
                      itemCount: displayCats.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.white.withValues(alpha: 0.15)),
                      itemBuilder: (context, index) {
                        final cat = displayCats[index];
                        final isSel = _selectedCategory == cat;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          title: Text(
                            cat.trData(context),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                              color: isSel ? Colors.white : const Color(0xFFE2D6F5),
                            ),
                          ),
                          trailing: isSel ? const Icon(Icons.check_circle, color: Colors.white, size: 20) : null,
                          onTap: () {
                            Navigator.pop(ctx);
                            setState(() => _selectedCategory = cat);
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
      },
    );
  }

  void _showSortDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF551478),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Sort Events'.trData(context),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(height: 16),
                for (final opt in ['Soonest', 'Title (A - Z)', 'Price: Low to High', 'Price: High to Low', 'Most Popular']) ...[
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                    title: Text(
                      opt.trData(context),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: _sortBy == opt ? FontWeight.w800 : FontWeight.w500,
                        color: _sortBy == opt ? Colors.white : const Color(0xFFE2D6F5),
                      ),
                    ),
                    trailing: _sortBy == opt ? const Icon(Icons.check_circle, color: Colors.white, size: 20) : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() => _sortBy = opt);
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
