import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/live_sync_service.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../artists/domain/models/artist_model.dart';
import '../../../events/domain/models/art_event_model.dart';
import '../../../government/domain/models/government_entity.dart';

enum AdminTab {
  artists,
  events,
  calendar,
  galleries,
  bookings,
  artCenters,
  government,
}

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  AdminTab _selectedTab = AdminTab.artists;

  List<ArtistModel> _artists = [];
  List<ArtEventModel> _events = [];
  List<Map<String, dynamic>> _galleries = [];
  List<Map<String, dynamic>> _bookings = [];
  List<GovernmentEntity> _govEntities = [];

  StreamSubscription<List<ArtistModel>>? _artistsSub;
  StreamSubscription<List<ArtEventModel>>? _eventsSub;
  StreamSubscription<List<Map<String, dynamic>>>? _galleriesSub;
  StreamSubscription<List<Map<String, dynamic>>>? _bookingsSub;

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _subscribeLiveStreams();
  }

  void _subscribeLiveStreams() {
    final liveSync = sl<LiveSyncService>();
    _artistsSub = liveSync.artistsStream.listen((list) {
      if (mounted && list.isNotEmpty) {
        setState(() => _artists = list);
      }
    });
    _eventsSub = liveSync.eventsStream.listen((list) {
      if (mounted && list.isNotEmpty) {
        setState(() => _events = list);
      }
    });
    _galleriesSub = liveSync.galleriesStream.listen((list) {
      if (mounted && list.isNotEmpty) {
        setState(() => _galleries = list);
      }
    });
    _bookingsSub = liveSync.bookingsStream.listen((list) {
      if (mounted) {
        setState(() => _bookings = list);
      }
    });
  }

  @override
  void dispose() {
    _artistsSub?.cancel();
    _eventsSub?.cancel();
    _galleriesSub?.cancel();
    _bookingsSub?.cancel();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    try {
      final results = await Future.wait([
        sl<ApiService>().getArtists(forceRefresh: true).catchError((_) => <ArtistModel>[]),
        sl<ApiService>().getEvents(forceRefresh: true).catchError((_) => <ArtEventModel>[]),
        sl<ApiService>().getGalleries(forceRefresh: true).catchError((_) => <Map<String, dynamic>>[]),
        sl<ApiService>().getBookings(forceRefresh: true).catchError((_) => <Map<String, dynamic>>[]),
        sl<ApiService>().getGovernmentEntities(forceRefresh: true).catchError((_) => <GovernmentEntity>[]),
      ]);

      if (mounted) {
        setState(() {
          _artists = results[0] as List<ArtistModel>;
          _events = results[1] as List<ArtEventModel>;
          _galleries = results[2] as List<Map<String, dynamic>>;
          _bookings = results[3] as List<Map<String, dynamic>>;
          _govEntities = results[4] as List<GovernmentEntity>;
        });
      }
    } catch (_) {}
  }

  void _confirmDelete({
    required String title,
    required String message,
    required Future<void> Function() onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        content: Text(message, style: const TextStyle(fontSize: 14, color: Color(0xFF475569))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await onConfirm();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteNames.home);
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'Admin Dashboard',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Artist Dubai management',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFF6A2777),
        onRefresh: _loadAllData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. KPI Summary Cards (2x2 Grid matching screenshots)
              _buildMetricsGrid(),
              const SizedBox(height: 16),

              // 2. Multi-row Tab Selector Bar matching screenshots
              _buildTabSelector(),
              const SizedBox(height: 16),

              // 3. Tab Content View
              _buildTabContent(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(),
    );
  }

  Widget _buildMetricsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.people_outline_rounded,
                count: '${_artists.length}',
                label: 'Artists',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.calendar_today_outlined,
                count: '${_events.length}',
                label: 'Events',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.image_outlined,
                count: '${_galleries.length}',
                label: 'Galleries',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.confirmation_number_outlined,
                count: '${_bookings.length}',
                label: 'Bookings',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String count,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF6A2777), size: 22),
          const SizedBox(height: 8),
          Text(
            count,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Row 1
          Row(
            children: [
              _buildTabButton(AdminTab.artists, 'Artists'),
              _buildTabButton(AdminTab.events, 'Events'),
              _buildTabButton(AdminTab.calendar, 'Calendar'),
              _buildTabButton(AdminTab.galleries, 'Galleries'),
              _buildTabButton(AdminTab.bookings, 'Bookings'),
            ],
          ),
          const SizedBox(height: 4),
          // Row 2
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTabButton(AdminTab.artCenters, 'Art Centers'),
              _buildTabButton(AdminTab.government, 'Government'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(AdminTab tab, String title) {
    final isSelected = _selectedTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x10000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case AdminTab.artists:
        return _buildArtistsTab();
      case AdminTab.events:
        return _buildEventsTab();
      case AdminTab.calendar:
        return _buildCalendarTab();
      case AdminTab.galleries:
        return _buildGalleriesTab();
      case AdminTab.bookings:
        return _buildBookingsTab();
      case AdminTab.artCenters:
        return _buildArtCentersTab();
      case AdminTab.government:
        return _buildGovernmentTab();
    }
  }

  // --- 1. Artists Tab ---
  Widget _buildArtistsTab() {
    if (_artists.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'No artists registered yet.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _artists.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final artist = _artists[index];
        return _buildListItemCard(
          title: artist.name,
          subtitle: artist.location.isNotEmpty ? artist.location : 'Dubai, UAE',
          badgeText: artist.category,
          onEdit: () {
            context.push('${RouteNames.artists}/${artist.id}');
          },
          onDelete: () {
            _confirmDelete(
              title: 'Delete Artist Profile',
              message: 'Are you sure you want to remove ${artist.name}?',
              onConfirm: () async {
                setState(() => _artists.removeAt(index));
                await sl<ApiService>().deleteArtist(artist.id);
              },
            );
          },
        );
      },
    );
  }

  // --- 2. Events Tab ---
  Widget _buildEventsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A2777),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => context.push(RouteNames.createArtEvent),
            child: const Text('New event', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          ),
        ),
        const SizedBox(height: 12),
        if (_events.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'No events created yet.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _events.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final ev = _events[index];
              return _buildListItemCard(
                title: ev.title,
                subtitle: '${ev.formattedDate} - ${ev.location}',
                badgeText: 'active',
                isStatusBadge: true,
                onEdit: () {
                  context.push(RouteNames.events);
                },
                onDelete: () {
                  _confirmDelete(
                    title: 'Delete Event',
                    message: 'Are you sure you want to delete "${ev.title}"?',
                    onConfirm: () async {
                      setState(() => _events.removeAt(index));
                      await sl<ApiService>().deleteEvent(ev.id);
                    },
                  );
                },
              );
            },
          ),
      ],
    );
  }

  // --- 3. Calendar Tab ---
  Widget _buildCalendarTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A2777),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => context.push(RouteNames.createArtEvent),
            child: const Text('Add to calendar', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          ),
        ),
        const SizedBox(height: 24),
        if (_events.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No upcoming events.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13.5),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _events.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final ev = _events[index];
              return _buildListItemCard(
                title: ev.title,
                subtitle: '${ev.formattedDate} - ${ev.locationCity ?? ev.location}',
                badgeText: 'Scheduled',
                isStatusBadge: true,
              );
            },
          ),
      ],
    );
  }

  // --- 4. Galleries Tab ---
  Widget _buildGalleriesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A2777),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.add, size: 14),
            label: const Text('New gallery', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            onPressed: () => context.push(RouteNames.galleryRegistration),
          ),
        ),
        const SizedBox(height: 12),
        if (_galleries.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'No galleries registered.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _galleries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final gal = _galleries[index];
              final name = gal['name'] as String? ?? 'Gallery';
              final id = gal['id'];
              return _buildListItemCard(
                title: name,
                subtitle: 'Artist gallery',
                badgeText: 'Public',
                isPurpleBadge: true,
                onDelete: () {
                  _confirmDelete(
                    title: 'Delete Gallery',
                    message: 'Are you sure you want to remove "$name"?',
                    onConfirm: () async {
                      setState(() => _galleries.removeAt(index));
                      await sl<ApiService>().deleteGallery(id);
                    },
                  );
                },
              );
            },
          ),
      ],
    );
  }

  // --- 5. Bookings Tab ---
  Widget _buildBookingsTab() {
    if (_bookings.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'No bookings visible.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 13.5),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final b = _bookings[index];
        final title = b['event_title'] as String? ?? b['full_name'] as String? ?? 'Booking';
        final status = b['status'] as String? ?? 'Confirmed';
        final date = b['event_date'] as String? ?? b['created_at'] as String? ?? '';
        return _buildListItemCard(
          title: title,
          subtitle: date,
          badgeText: status,
          isStatusBadge: true,
        );
      },
    );
  }

  // --- 6. Art Centers Tab ---
  Widget _buildArtCentersTab() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _galleries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final gal = _galleries[index];
        return _buildListItemCard(
          title: gal['name'] as String? ?? 'Art Center',
          subtitle: gal['location'] as String? ?? 'Dubai, UAE',
          badgeText: 'Verified',
          isStatusBadge: true,
        );
      },
    );
  }

  // --- 7. Government Tab ---
  Widget _buildGovernmentTab() {
    final list = _govEntities.isNotEmpty ? _govEntities : GovernmentEntity.entities;
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final g = list[index];
        return _buildListItemCard(
          title: g.name,
          subtitle: g.category,
          badgeText: g.defaultIsOpen ? 'Open Now' : 'Closed',
          isStatusBadge: true,
        );
      },
    );
  }

  // Common card container matching screenshots
  Widget _buildListItemCard({
    required String title,
    required String subtitle,
    String? badgeText,
    bool isStatusBadge = false,
    bool isPurpleBadge = false,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          if (badgeText != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isPurpleBadge
                    ? const Color(0xFF6A2777)
                    : (isStatusBadge ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC)),
                borderRadius: BorderRadius.circular(12),
                border: isPurpleBadge
                    ? null
                    : Border.all(color: const Color(0xFFCBD5E1), width: 0.8),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: isPurpleBadge ? Colors.white : const Color(0xFF334155),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF475569)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: onEdit,
            ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
