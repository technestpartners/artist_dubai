import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../artists/domain/models/artist_model.dart';
import '../../../events/domain/models/art_event_model.dart';
import '../../../home/presentation/widgets/home_footer_widget.dart';

class FavoritesView extends StatefulWidget {
  const FavoritesView({super.key});

  @override
  State<FavoritesView> createState() => _FavoritesViewState();
}

class _FavoritesViewState extends State<FavoritesView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ArtistModel> _favoritedArtists = [];
  List<ArtEventModel> _favoritedEvents = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchFavorites();
  }

  Future<void> _fetchFavorites() async {
    try {
      final artists = await sl<ApiService>().getArtists(forceRefresh: true);
      final events = await sl<ApiService>().getEvents(forceRefresh: true);
      if (mounted) {
        setState(() {
          _favoritedArtists = artists;
          _favoritedEvents = events;
        });
      }
    } catch (_) {}
  }

  final List<Map<String, String>> _favoritedArtworks = [
    {
      'title': 'Desert Horizon',
      'artist': 'Frankie DeChiazza',
      'details': '2024 • Oil on Canvas',
      'dimensions': '120 x 90 cm',
      'price': '\$2,000',
      'image': 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?q=80&w=1200&auto=format&fit=crop',
    },
    {
      'title': 'Urban Reflections',
      'artist': 'Alexander Mollov',
      'details': '2025 • Digital Art',
      'dimensions': '100 x 70 cm',
      'price': '\$1,500',
      'image': 'https://images.unsplash.com/photo-1541701494587-cb58502866ab?q=80&w=1200&auto=format&fit=crop',
    },
    {
      'title': 'Calligraphic Symphony',
      'artist': 'Sara Al-Mahmoud',
      'details': '2024 • Mixed Media & Gold Leaf',
      'dimensions': '150 x 100 cm',
      'price': '\$3,200',
      'image': 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=1200&auto=format&fit=crop',
    },
  ];

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _removeArtist(int index) {
    setState(() {
      _favoritedArtists.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Removed artist from favorites'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _removeEvent(int index) {
    setState(() {
      _favoritedEvents.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Removed event from favorites'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _removeArtwork(int index) {
    setState(() {
      _favoritedArtworks.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Removed artwork from favorites'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6B1C9B),
      appBar: const AppTopBar(backgroundColor: Colors.white),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header Title & Subtitle (Dark Purple Theme matching other pages)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MY FAVORITES | SAVED PROFILES',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Your saved artist profiles, favorited events, and liked artworks',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Colors.white70,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Segmented Tab Switcher
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF5A1684).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      labelColor: const Color(0xFF5E227A),
                      unselectedLabelColor: Colors.white70,
                      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      padding: const EdgeInsets.all(3),
                      tabs: [
                        Tab(text: 'Artists (${_favoritedArtists.length})'),
                        Tab(text: 'Events (${_favoritedEvents.length})'),
                        Tab(text: 'Artworks (${_favoritedArtworks.length})'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. Tab Content View
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Favorited Artists List
                  _buildArtistsTab(),

                  // Tab 2: Favorited Events List
                  _buildEventsTab(),

                  // Tab 3: Favorited Artworks List
                  _buildArtworksTab(),
                ],
              ),
            ),

            // Footer Attribution
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: HomeFooterWidget(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildArtistsTab() {
    if (_favoritedArtists.isEmpty) {
      return _buildEmptyState(
        icon: Icons.person_off_outlined,
        message: 'No favorited artist profiles yet.',
        subMessage: 'Explore artists and tap the heart icon to save them here.',
        actionText: 'Explore Artists',
        onAction: () => context.go(RouteNames.artists),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _favoritedArtists.length,
      itemBuilder: (context, index) {
        final artist = _favoritedArtists[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF5A1684).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: NetworkImage(artist.avatarUrl),
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            artist.name,
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            artist.category,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFFFFD700),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 14, color: Colors.white70),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  artist.location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.favorite, color: Color(0xFFEF4444)),
                      onPressed: () => _removeArtist(index),
                      tooltip: 'Remove from favorites',
                    ),
                  ],
                ),
                if (artist.bio.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    artist.bio,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, color: Colors.white70, height: 1.3),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () => context.push('/artist/${artist.id}'),
                        child: const Text('View Profile', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF5E227A),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () => context.push(RouteNames.bookArtist),
                        child: const Text('Book Artist', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventsTab() {
    if (_favoritedEvents.isEmpty) {
      return _buildEmptyState(
        icon: Icons.event_busy_outlined,
        message: 'No favorited events yet.',
        subMessage: 'Browse art exhibitions and save events to your list.',
        actionText: 'Browse Events',
        onAction: () => context.go(RouteNames.events),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _favoritedEvents.length,
      itemBuilder: (context, index) {
        final event = _favoritedEvents[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF5A1684).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      event.imageUrl ?? 'https://images.unsplash.com/photo-1541701494587-cb58502866ab?q=80&w=1200&auto=format&fit=crop',
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 18,
                      child: IconButton(
                        icon: const Icon(Icons.favorite, color: Color(0xFFEF4444), size: 18),
                        onPressed: () => _removeEvent(index),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${event.formattedDate} • ${event.location}',
                      style: const TextStyle(fontSize: 12.5, color: Colors.white70),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          event.price,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFFFD700)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF5E227A),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          onPressed: () => context.go(RouteNames.events),
                          child: const Text('View Event', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
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
    );
  }

  Widget _buildArtworksTab() {
    if (_favoritedArtworks.isEmpty) {
      return _buildEmptyState(
        icon: Icons.image_not_supported_outlined,
        message: 'No favorited artworks saved.',
        subMessage: 'Explore portfolios and heart individual artworks.',
        actionText: 'Explore Portfolios',
        onAction: () => context.go(RouteNames.artists),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _favoritedArtworks.length,
      itemBuilder: (context, index) {
        final item = _favoritedArtworks[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF5A1684).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    item['image']!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title']!,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'By ${item['artist']!}',
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFFFFD700), fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item['details']!} • ${item['dimensions']!}',
                        style: const TextStyle(fontSize: 11.5, color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['price']!,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.favorite, color: Color(0xFFEF4444)),
                  onPressed: () => _removeArtwork(index),
                  tooltip: 'Remove artwork',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String subMessage,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 54, color: Colors.white54),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              subMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF5E227A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: onAction,
              child: Text(actionText, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
