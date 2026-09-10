import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/live_sync_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/widgets/app_cached_image.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../artists/domain/models/artist_model.dart';
import '../../../events/domain/models/art_event_model.dart';
import '../../../../core/utils/data_translator.dart';
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
  List<Map<String, dynamic>> _favoritedArtworks = [];
  bool _isLoading = true;
  StreamSubscription<Map<String, dynamic>>? _favSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchFavorites();
    _favSub = sl<LiveSyncService>().favoritesStream.listen((data) {
      if (mounted) {
        setState(() {
          _favoritedArtists = data['artists'] as List<ArtistModel>? ?? [];
          _favoritedEvents = data['events'] as List<ArtEventModel>? ?? [];
          _favoritedArtworks = data['artworks'] as List<Map<String, dynamic>>? ?? [];
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _fetchFavorites({bool forceRefresh = false}) async {
    setState(() => _isLoading = _favoritedArtists.isEmpty && _favoritedEvents.isEmpty && _favoritedArtworks.isEmpty);
    try {
      final userEmail = sl<StorageService>().getString('user_email');
      final data = await sl<ApiService>().getFavorites(email: userEmail, forceRefresh: forceRefresh);
      if (mounted) {
        setState(() {
          _favoritedArtists = data['artists'] as List<ArtistModel>? ?? [];
          _favoritedEvents = data['events'] as List<ArtEventModel>? ?? [];
          _favoritedArtworks = data['artworks'] as List<Map<String, dynamic>>? ?? [];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _favSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _removeArtist(int index) async {
    if (index >= _favoritedArtists.length) return;
    final artist = _favoritedArtists[index];
    final userEmail = sl<StorageService>().getString('user_email') ?? '';
    setState(() {
      _favoritedArtists.removeAt(index);
    });
    if (userEmail.isNotEmpty) {
      await sl<ApiService>().toggleFavorite(
        email: userEmail,
        itemType: 'artist',
        itemId: artist.id,
      );
    }
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Removed artist from favorites'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _removeEvent(int index) async {
    if (index >= _favoritedEvents.length) return;
    final event = _favoritedEvents[index];
    final userEmail = sl<StorageService>().getString('user_email') ?? '';
    setState(() {
      _favoritedEvents.removeAt(index);
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
        const SnackBar(
          content: Text('Removed event from favorites'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _removeArtwork(int index) async {
    if (index >= _favoritedArtworks.length) return;
    final artwork = _favoritedArtworks[index];
    final userEmail = sl<StorageService>().getString('user_email') ?? '';
    setState(() {
      _favoritedArtworks.removeAt(index);
    });
    if (userEmail.isNotEmpty && artwork['id'] != null) {
      await sl<ApiService>().toggleFavorite(
        email: userEmail,
        itemType: 'artwork',
        itemId: artwork['id'].toString(),
      );
    }
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Removed artwork from favorites'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF6B1C9B),
      appBar: const AppTopBar(backgroundColor: Colors.white),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header Title & Subtitle
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.myFavorites.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.myFavoritesSubtitle,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFFE2D6F5),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Segmented Tab Switcher
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: const Color(0xFF6B1C9B),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: const Color(0xFF64748B),
                      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      padding: const EdgeInsets.all(3),
                      tabs: [
                        Tab(text: '${l10n.artists} (${_favoritedArtists.length})'),
                        Tab(text: '${l10n.events} (${_favoritedEvents.length})'),
                        Tab(text: '${l10n.artworks} (${_favoritedArtworks.length})'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. Tab Content View
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : RefreshIndicator(
                      color: const Color(0xFF6B1C9B),
                      backgroundColor: Colors.white,
                      onRefresh: _fetchFavorites,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Tab 1: Favorited Artists List
                          _buildArtistsTab(l10n),

                          // Tab 2: Favorited Events List
                          _buildEventsTab(l10n),

                          // Tab 3: Favorited Artworks List
                          _buildArtworksTab(l10n),
                        ],
                      ),
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
      bottomNavigationBar: const AppBottomNavBar(currentIndex: -1),
    );
  }

  Widget _buildArtistsTab(AppLocalizations l10n) {
    if (_favoritedArtists.isEmpty) {
      return _buildEmptyState(
        icon: Icons.person_off_outlined,
        message: l10n.noFavoritedArtistsYet,
        subMessage: 'Explore artists and tap the heart icon to save them here.',
        actionText: l10n.exploreArtists,
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
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipOval(
                  child: Container(
                    width: 56,
                    height: 56,
                    color: const Color(0xFFF3E8FF),
                    child: artist.avatarUrl.isNotEmpty
                        ? AppCachedImage(
                            imageUrl: artist.avatarUrl,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorWidget: Center(
                              child: Text(
                                artist.name.isNotEmpty ? artist.name[0].toUpperCase() : 'A',
                                style: const TextStyle(color: Color(0xFF6A2777), fontWeight: FontWeight.bold, fontSize: 20),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              artist.name.isNotEmpty ? artist.name[0].toUpperCase() : 'A',
                              style: const TextStyle(color: Color(0xFF6A2777), fontWeight: FontWeight.bold, fontSize: 20),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artist.localizedName(context),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        artist.localizedCategory(context),
                        style: const TextStyle(fontSize: 13, color: Color(0xFF6A2777), fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        artist.localizedLocation(context),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
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
          ),
        );
      },
    );
  }

  Widget _buildEventsTab(AppLocalizations l10n) {
    if (_favoritedEvents.isEmpty) {
      return _buildEmptyState(
        icon: Icons.event_busy_outlined,
        message: l10n.noFavoritedEventsYet,
        subMessage: 'Discover upcoming art events and bookmark them for quick access.',
        actionText: l10n.exploreEvents,
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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  child: AppCachedImage(
                    imageUrl: event.imageUrl!,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            event.localizedCategory(context),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6A2777)),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.favorite, color: Color(0xFFEF4444)),
                          onPressed: () => _removeEvent(index),
                          tooltip: 'Remove from favorites',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.localizedTitle(context),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${event.formattedDate} • ${event.localizedLocation(context)}',
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          event.localizedPrice(context),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6A2777),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          onPressed: () => context.go(RouteNames.events),
                          child: Text(l10n.viewDetails, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
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

  Widget _buildArtworksTab(AppLocalizations l10n) {
    if (_favoritedArtworks.isEmpty) {
      return _buildEmptyState(
        icon: Icons.image_not_supported_outlined,
        message: l10n.noFavoritedArtworksYet,
        subMessage: 'Explore portfolios and heart individual artworks.',
        actionText: l10n.explorePortfolios,
        onAction: () => context.go(RouteNames.artists),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _favoritedArtworks.length,
      itemBuilder: (context, index) {
        final item = _favoritedArtworks[index];
        final title = item['title']?.toString() ?? 'Artwork';
        final artist = (item['artist_name']?.toString() ?? item['artist']?.toString() ?? 'Artist').trData(context);
        final year = item['year']?.toString() ?? '2025';
        final medium = (item['medium']?.toString() ?? item['details']?.toString() ?? 'Mixed Media').trData(context);
        final dimensions = item['dimensions']?.toString() ?? '120 x 80 cm';
        final image = item['image_url']?.toString() ?? item['image']?.toString() ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
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
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: AppCachedImage(
                    imageUrl: image,
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
                        title,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        Localizations.localeOf(context).languageCode == 'ar' ? 'بواسطة $artist' : 'By $artist',
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF6A2777), fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$year • $medium • $dimensions',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
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
            Icon(icon, size: 54, color: Colors.white70),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              subMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFFE2D6F5), height: 1.4),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF6B1C9B),
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
