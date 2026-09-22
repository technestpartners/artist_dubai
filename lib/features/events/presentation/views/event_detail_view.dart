import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/favorites_service.dart';
import '../../../../core/services/live_sync_service.dart';
import '../../../../core/widgets/app_cached_image.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/utils/share_helper.dart';
import '../../../../core/utils/data_translator.dart';
import '../../domain/models/art_event_model.dart';

class EventDetailView extends StatefulWidget {
  final ArtEventModel? event;
  final String? eventId;

  const EventDetailView({super.key, this.event, this.eventId});

  @override
  State<EventDetailView> createState() => _EventDetailViewState();
}

class _EventDetailViewState extends State<EventDetailView> {
  ArtEventModel? _fetchedEvent;
  bool _isLoading = false;
  bool _isDescriptionExpanded = false;
  final Set<String> _likedEventIds = {};
  StreamSubscription<Map<String, dynamic>>? _favSub;
  StreamSubscription<List<ArtEventModel>>? _eventsSub;

  static const Color _primaryPurple = Color(0xFF6B1C9B);
  static const Color _darkBg = Color(0xFF6B1C9B);

  String? get effectiveId => widget.eventId ?? widget.event?.id ?? _fetchedEvent?.id;

  ArtEventModel get event {
    if (_fetchedEvent != null) return _fetchedEvent!;
    if (widget.event != null) return widget.event!;
    return ArtEventModel.sampleEvent;
  }

  @override
  void initState() {
    super.initState();
    _loadEventDetails();
    _likedEventIds.addAll(sl<FavoritesService>().eventIds);
    sl<FavoritesService>().addListener(_onFavoritesChanged);
    _checkInitialFavorite();

    _favSub = sl<LiveSyncService>().favoritesStream.listen((favData) {
      if (mounted && favData.isNotEmpty) {
        sl<FavoritesService>().updateFromServer(favData);
      }
    });

    _eventsSub = sl<LiveSyncService>().eventsStream.listen((events) {
      final id = effectiveId;
      if (id != null && mounted) {
        final match = events.where((e) => e.id == id).firstOrNull;
        if (match != null) {
          setState(() {
            _fetchedEvent = match;
          });
        }
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
    _loadEventDetails();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    sl<FavoritesService>().removeListener(_onFavoritesChanged);
    DataTranslator.translationNotifier.removeListener(_onTranslationChanged);
    _favSub?.cancel();
    _eventsSub?.cancel();
    super.dispose();
  }

  Future<void> _checkInitialFavorite() async {
    try {
      final effectiveEmail = sl<FavoritesService>().getEffectiveEmail();
      final favData = await sl<ApiService>().getFavorites(email: effectiveEmail);
      sl<FavoritesService>().updateFromServer(favData);
      if (mounted) {
        setState(() {
          _likedEventIds.clear();
          _likedEventIds.addAll(sl<FavoritesService>().eventIds);
        });
      }
    } catch (_) {}
  }

  Future<void> _loadEventDetails() async {
    final id = effectiveId;
    if (id == null || id.isEmpty) return;

    try {
      final res = await sl<ApiService>().getEventDetails(id, forceRefresh: true);
      if (mounted) {
        setState(() {
          _fetchedEvent = res;
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}

    try {
      final allEvents = await sl<ApiService>().getEvents(forceRefresh: true);
      final match = allEvents.where((e) => e.id == id).firstOrNull;
      if (match != null && mounted) {
        setState(() {
          _fetchedEvent = match;
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _toggleFavorite(ArtEventModel ev) async {
    final wasLiked = _likedEventIds.contains(ev.id);
    final nowLiked = await sl<FavoritesService>().toggleEventFavorite(ev.id);

    if (mounted) {
      setState(() {
        if (nowLiked) {
          _likedEventIds.add(ev.id);
        } else {
          _likedEventIds.remove(ev.id);
        }
      });

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasLiked
                ? 'Removed "${ev.title}" from favorites'
                : 'Saved "${ev.title}" to favorites! ❤️',
          ),
          backgroundColor: wasLiked ? null : _primaryPurple,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _shareEvent(ArtEventModel ev) {
    ShareHelper.shareEvent(
      context: context,
      eventId: ev.id,
      title: ev.title,
      location: ev.location,
      imageUrl: ev.imageUrl,
      dateTime: ev.dateTime,
    );
  }

  Future<void> _openMapDirections(String locationQuery) async {
    final encoded = Uri.encodeComponent(locationQuery);
    await ShareHelper.openUrl('https://www.google.com/maps/search/?api=1&query=$encoded');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _darkBg,
        appBar: AppTopBar(backgroundColor: Colors.white),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final rh = ResponsiveHelper.of(context);
    final ev = event;
    final isLiked = _likedEventIds.contains(ev.id);
    final similarEvents = ArtEventModel.mockEvents.where((e) => e.id != ev.id).toList();

    return Scaffold(
      backgroundColor: _darkBg,
      appBar: const AppTopBar(backgroundColor: Colors.white),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(rh.horizontalPadding, 6, rh.horizontalPadding, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: rh.contentMaxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // 1. Sub-Header: Back button, Title, Actions (Heart, Calendar, Share)
              _buildSubHeader(isLiked, ev),
              const SizedBox(height: 12),

              // 2. Hero Banner Image (Reference Screenshot 4)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 240,
                  width: double.infinity,
                  child: ev.imageUrl != null && ev.imageUrl!.isNotEmpty
                      ? AppCachedImage(imageUrl: ev.imageUrl!, fit: BoxFit.cover)
                      : Container(
                          color: const Color(0xFFE2E8F0),
                          child: const Icon(Icons.event, size: 64, color: Colors.grey),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Event Details Card (White Container)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
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
                    // Title
                    Text(
                      ev.localizedTitle(context),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E1E1E),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Date & Time (Purple text)
                    Text(
                      ev.displaySchedule.trData(context),
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: _primaryPurple,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Expandable Description with "Read More"
                    _buildExpandableDescription(ev.localizedDescription(context)),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 16),

                    // Location Row with pin
                    GestureDetector(
                      onTap: () => _openMapDirections(ev.location),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: _primaryPurple,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              (ev.location.isNotEmpty
                                      ? ev.location
                                      : 'Hatta Wadi Hub, located off the Dubai-Hatta road, Dubai')
                                  .trData(context),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF334155),
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Map Preview Card (Reference Screenshot 4 & 5)
                    _buildMapPreviewWidget(ev),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 4. "Similar Events You Might Like" Section
              Text(
                'Similar Events You Might Like'.trData(context),
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),

              // Horizontal list of similar events
              SizedBox(
                height: 290,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: similarEvents.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    return _buildSimilarEventCard(similarEvents[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }

  // Sub-header with back button and top action icons (Reference Screenshot 4)
  Widget _buildSubHeader(bool isLiked, ArtEventModel ev) {
    return Row(
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
            'Event Details'.trData(context),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Action 1: Favorite Heart Button
        _buildTopActionIcon(
          icon: isLiked ? Icons.favorite : Icons.favorite_border,
          color: isLiked ? Colors.redAccent : Colors.white,
          onTap: () => _toggleFavorite(ev),
        ),
        const SizedBox(width: 8),
        // Action 2: Share Button
        _buildTopActionIcon(
          icon: Icons.ios_share,
          color: Colors.white,
          onTap: () => _shareEvent(ev),
        ),
      ],
    );
  }

  Widget _buildTopActionIcon({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 19, color: color),
        ),
      ),
    );
  }

  Widget _buildExpandableDescription(String rawText) {
    final text = rawText.isNotEmpty
        ? rawText
        : "Get ready to push your limits at Ultra Trail Dubai (UTD), one of the region's most exciting and inclusive ultra trail events. Held from 27-29 November in the rugged wilderness of Hatta, runners will experience breathtaking mountain trails, steep climbs, and picturesque valley vistas. Whether you are a beginner or a seasoned endurance athlete, there are distances suited for everyone.";

    const int maxCollapsedChars = 170;
    final isLong = text.length > maxCollapsedChars;
    final displayText = (!_isDescriptionExpanded && isLong)
        ? '${text.substring(0, maxCollapsedChars)}...'
        : text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: displayText,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4B5563),
              height: 1.5,
            ),
            children: [
              if (isLong) ...[
                const TextSpan(text: ' '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: GestureDetector(
                    onTap: () => setState(() => _isDescriptionExpanded = !_isDescriptionExpanded),
                    child: Text(
                      _isDescriptionExpanded
                          ? 'Read Less'.trData(context)
                          : 'Read More'.trData(context),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _primaryPurple,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _getVenueDisplayName(ArtEventModel ev) {
    if (ev.location.isEmpty) {
      return ev.locationCity ?? 'Dubai, UAE';
    }
    final parts = ev.location.split(',');
    if (parts.isNotEmpty && parts.first.trim().isNotEmpty) {
      return parts.first.trim();
    }
    return ev.location;
  }

  Widget _buildMapPreviewWidget(ArtEventModel ev) {
    final venueName = _getVenueDisplayName(ev);

    return GestureDetector(
      onTap: () => _openMapDirections(ev.location),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 190,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F2EE),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              // 1. Realistic Vector Map Canvas
              Positioned.fill(
                child: CustomPaint(
                  painter: _MapCanvasPainter(),
                ),
              ),

              // 2. Interactive Center Pin with Floating Venue Callout
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Floating Venue Badge Callout
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.16),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: _primaryPurple,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 200),
                            child: Text(
                              venueName.trData(context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E293B),
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 3),

                    // Pointer Radar Pulse & Center Dot Marker
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer Radar Pulse
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: _primaryPurple.withValues(alpha: 0.16),
                            shape: BoxShape.circle,
                          ),
                        ),
                        // Inner Pulse
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _primaryPurple.withValues(alpha: 0.32),
                            shape: BoxShape.circle,
                          ),
                        ),
                        // Center Core Pin
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: _primaryPurple,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),

              // 3. Bottom Bar: Google Branding & Open Directions Action
              Positioned(
                bottom: 10,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Google Logo Watermark
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Google'.trData(context),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.blueGrey[700],
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),

                    // Open Directions Pill Button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.directions, size: 14, color: _primaryPurple),
                          const SizedBox(width: 4),
                          Text(
                            'Open Directions'.trData(context),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: _primaryPurple,
                            ),
                          ),
                        ],
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

  Widget _buildSimilarEventCard(ArtEventModel item) {
    final isLiked = _likedEventIds.contains(item.id);

    return GestureDetector(
      onTap: () => context.push(RouteNames.eventDetailWithId(item.id), extra: item),
      child: Container(
        width: 245,
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
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 145,
                    width: double.infinity,
                    child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                        ? AppCachedImage(imageUrl: item.imageUrl!, fit: BoxFit.cover)
                        : Container(
                            color: const Color(0xFFF1F5F9),
                            child: const Center(
                              child: Icon(Icons.palette_outlined, size: 42, color: Color(0xFF94A3B8)),
                            ),
                          ),
                  ),
                ),
                // Category Chip on Top Start
                if (item.category.isNotEmpty)
                  PositionedDirectional(
                    top: 8,
                    start: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.localizedCategory(context),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                // Heart Like Button on Top End
                PositionedDirectional(
                  top: 8,
                  end: 8,
                  child: GestureDetector(
                    onTap: () => _toggleFavorite(item),
                    child: Container(
                      width: 34,
                      height: 34,
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
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Event Title (2 lines max for full readability)
            Text(
              item.localizedTitle(context),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E1E1E),
                height: 1.25,
              ),
            ),
            const SizedBox(height: 6),

            // Date & Time
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 13,
                  color: _primaryPurple,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    item.displaySchedule.trData(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: _primaryPurple,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Location
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 13,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    item.localizedVenue(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MapCanvasPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Background Land (Google Maps cream tone)
    final bgPaint = Paint()..color = const Color(0xFFF3F2EE);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Green Park Area (natural curved park)
    final parkPaint = Paint()..color = const Color(0xFFD8F1D8);
    final parkPath = Path()
      ..moveTo(size.width * 0.72, size.height)
      ..cubicTo(size.width * 0.74, size.height * 0.7, size.width * 0.85, size.height * 0.65, size.width, size.height * 0.62)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(parkPath, parkPaint);

    // 3. Water Body / Canal (soft Google Maps blue)
    final waterPaint = Paint()..color = const Color(0xFFC7E4F0);
    final waterPath = Path()
      ..moveTo(0, size.height * 0.35)
      ..cubicTo(size.width * 0.25, size.height * 0.32, size.width * 0.45, size.height * 0.2, size.width * 0.7, size.height * 0.12)
      ..cubicTo(size.width * 0.85, size.height * 0.08, size.width * 0.95, size.height * 0.04, size.width, 0)
      ..lineTo(0, 0)
      ..close();
    canvas.drawPath(waterPath, waterPaint);

    // 4. Urban Minor Streets Grid (White with subtle borders)
    final minorBorderPaint = Paint()
      ..color = const Color(0xFFE8E5DF)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;
    final minorRoadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    final gridPath = Path();
    // Horizontal streets
    gridPath.moveTo(0, size.height * 0.52);
    gridPath.lineTo(size.width, size.height * 0.48);
    gridPath.moveTo(0, size.height * 0.72);
    gridPath.lineTo(size.width * 0.72, size.height * 0.74);
    gridPath.moveTo(0, size.height * 0.88);
    gridPath.lineTo(size.width, size.height * 0.88);
    // Vertical streets
    gridPath.moveTo(size.width * 0.18, size.height * 0.35);
    gridPath.lineTo(size.width * 0.15, size.height);
    gridPath.moveTo(size.width * 0.4, size.height * 0.22);
    gridPath.lineTo(size.width * 0.38, size.height);
    gridPath.moveTo(size.width * 0.62, size.height * 0.15);
    gridPath.lineTo(size.width * 0.65, size.height);
    gridPath.moveTo(size.width * 0.84, size.height * 0.1);
    gridPath.lineTo(size.width * 0.82, size.height * 0.65);

    canvas.drawPath(gridPath, minorBorderPaint);
    canvas.drawPath(gridPath, minorRoadPaint);

    // 5. Major Arterial Highway (Yellow/Gold with amber borders)
    final highwayBorderPaint = Paint()
      ..color = const Color(0xFFE5CE82)
      ..strokeWidth = 7.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final highwayPaint = Paint()
      ..color = const Color(0xFFFDE896)
      ..strokeWidth = 5.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final highwayPath = Path()
      ..moveTo(0, size.height * 0.78)
      ..cubicTo(size.width * 0.3, size.height * 0.75, size.width * 0.52, size.height * 0.55, size.width * 0.75, size.height * 0.38)
      ..lineTo(size.width, size.height * 0.24);

    canvas.drawPath(highwayPath, highwayBorderPaint);
    canvas.drawPath(highwayPath, highwayPaint);

    // 6. Secondary Branch Avenue
    final secondaryBorder = Paint()
      ..color = const Color(0xFFDEDBD4)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke;
    final secondaryRoad = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.2
      ..style = PaintingStyle.stroke;

    final branchPath = Path()
      ..moveTo(size.width * 0.46, size.height * 0.6)
      ..cubicTo(size.width * 0.52, size.height * 0.75, size.width * 0.58, size.height * 0.88, size.width * 0.68, size.height);

    canvas.drawPath(branchPath, secondaryBorder);
    canvas.drawPath(branchPath, secondaryRoad);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
