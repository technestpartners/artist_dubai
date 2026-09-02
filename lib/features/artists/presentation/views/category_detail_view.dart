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
import '../../../../core/widgets/app_cached_image.dart';
import '../../domain/models/artist_model.dart';
import 'artist_detail_view.dart';

class CategoryDetailView extends StatefulWidget {
  final String? categoryName;
  final String? emoji;

  const CategoryDetailView({super.key, this.categoryName, this.emoji});

  @override
  State<CategoryDetailView> createState() => _CategoryDetailViewState();
}

class _CategoryDetailViewState extends State<CategoryDetailView> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedTabIndex = 0; // 0 = Artists, 1 = Artworks
  String _selectedFilter = 'All';
  String _selectedSort = 'Most Popular';

  late final String _title;
  late final String _categoryEmoji;
  List<ArtistModel> _categoryArtists = [];
  List<Map<String, dynamic>> _categoryArtworks = [];
  final Set<String> _likedArtistIds = {};
  StreamSubscription<List<ArtistModel>>? _artistSub;
  StreamSubscription<Map<String, dynamic>>? _favSub;

  @override
  void initState() {
    super.initState();
    _title = widget.categoryName ?? 'Calligraphy & Typography';
    _categoryEmoji = widget.emoji ?? '✍️';
    _fetchCategoryArtists();
    _artistSub = sl<LiveSyncService>().artistsStream.listen((artists) {
      if (mounted && artists.isNotEmpty) {
        setState(() {
          _categoryArtists = artists.where((a) => a.category.toLowerCase().contains(_title.toLowerCase()) || _title.toLowerCase().contains(a.category.toLowerCase())).toList();
        });
      }
    });
    _favSub = sl<LiveSyncService>().favoritesStream.listen((favData) {
      if (mounted && favData.isNotEmpty) {
        final favArtists = (favData['artists'] as List<ArtistModel>?) ?? [];
        setState(() {
          _likedArtistIds.clear();
          _likedArtistIds.addAll(favArtists.map((a) => a.id));
        });
      }
    });
  }

  @override
  void dispose() {
    _artistSub?.cancel();
    _favSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategoryArtists() async {
    try {
      final artists = await sl<ApiService>().getArtists(
        category: _title,
        forceRefresh: true,
      );
      final artworks = await sl<ApiService>().getArtworks(forceRefresh: true);
      final categoryArtistNames = artists.map((a) => a.name.toLowerCase().trim()).toSet();
      final filteredArtworks = artworks.where((aw) {
        final awArtist = (aw['artist_name'] ?? aw['artist'] ?? '').toString().toLowerCase().trim();
        return categoryArtistNames.contains(awArtist);
      }).toList();

      final userEmail = sl<StorageService>().getString('user_email');
      Set<String> favIds = {};
      if (userEmail != null && userEmail.isNotEmpty) {
        final favData = await sl<ApiService>().getFavorites(email: userEmail, forceRefresh: true);
        final favArtists = (favData['artists'] as List<ArtistModel>?) ?? [];
        favIds = favArtists.map((a) => a.id).toSet();
      }
      if (mounted) {
        setState(() {
          _categoryArtists = artists;
          _categoryArtworks = filteredArtworks;
          _likedArtistIds.clear();
          _likedArtistIds.addAll(favIds);
        });
      }
    } catch (_) {}
  }

  void _shareArtist(ArtistModel artist) {
    final name = artist.name.isEmpty ? 'Artist' : artist.name;
    final id = artist.id;
    Clipboard.setData(
      ClipboardData(
        text: 'Check out $name on Artist Dubai: https://artistdubai.com/artists/$id',
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
                'Profile link for $name copied to clipboard!',
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

  void _toggleLike(ArtistModel artist) async {
    final userEmail = sl<StorageService>().getString('user_email') ?? '';
    final wasLiked = _likedArtistIds.contains(artist.id);
    final artistName = artist.name.isEmpty ? 'Artist' : artist.name;

    setState(() {
      if (wasLiked) {
        _likedArtistIds.remove(artist.id);
      } else {
        _likedArtistIds.add(artist.id);
      }

      final idx = _categoryArtists.indexWhere((a) => a.id == artist.id);
      if (idx != -1) {
        final old = _categoryArtists[idx];
        final newLikes = wasLiked
            ? (old.followersCount - 1).clamp(0, 999999)
            : (old.followersCount + 1);
        _categoryArtists[idx] = ArtistModel(
          id: old.id,
          name: old.name,
          category: old.category,
          bio: old.bio,
          location: old.location,
          bannerUrl: old.bannerUrl,
          avatarUrl: old.avatarUrl,
          isFeatured: old.isFeatured,
          tags: old.tags,
          worksCount: old.worksCount,
          followersCount: newLikes,
        );
      }
    });

    if (userEmail.isNotEmpty) {
      await sl<ApiService>().likeArtist(
        artistId: artist.id,
        userEmail: userEmail,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasLiked
                ? 'Unliked $artistName'
                : 'Liked $artistName\'s profile! ❤️',
          ),
          backgroundColor: wasLiked ? null : const Color(0xFF6A2777),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeArtists = _categoryArtists;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: const AppTopBar(),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Sub-Header with Back Button (Matching Screenshot media_1787732673273.png)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF1E1E1E),
                      size: 20,
                    ),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(RouteNames.home);
                      }
                    },
                  ),
                  const Text(
                    'Back',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. Category Detail Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF3E8FF),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _categoryEmoji,
                              style: const TextStyle(fontSize: 26),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _title,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1E1E1E),
                                  letterSpacing: -0.3,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Traditional and contemporary Arabic calligraphy and typographic art.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.group_outlined,
                                    size: 16,
                                    color: Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${activeArtists.length} Artists',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Icon(
                                    Icons.image_outlined,
                                    size: 16,
                                    color: Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    '1 Artworks',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 3. Category Tags Pills Row
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          [
                                'Calligraphy',
                                'Typography',
                                'Arabic Art',
                                'Traditional',
                              ]
                              .map(
                                (tag) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Text(
                                    tag,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: Color(0xFF334155),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                    const SizedBox(height: 18),

                    // 4. Search Bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search artists or artworks...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF64748B),
                          size: 20,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 5. Filter & Sort Row (Matching Screenshots media_1787732750805.png & media_1787732759916.png)
                    Row(
                      children: [
                        // Left Filter Dropdown (All, Featured, New)
                        Expanded(
                          child: PopupMenuButton<String>(
                            onSelected: (value) {
                              setState(() {
                                _selectedFilter = value;
                              });
                            },
                            offset: const Offset(0, 44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            color: Colors.white,
                            itemBuilder:
                                (context) =>
                                    ['All', 'Featured', 'New'].map((option) {
                                      final isSelected =
                                          _selectedFilter == option;
                                      return PopupMenuItem<String>(
                                        value: option,
                                        height: 40,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                isSelected
                                                    ? const Color(0xFFF1F5F9)
                                                    : Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              SizedBox(
                                                width: 20,
                                                child:
                                                    isSelected
                                                        ? const Icon(
                                                          Icons.check,
                                                          size: 16,
                                                          color: Color(
                                                            0xFF1E1E1E,
                                                          ),
                                                        )
                                                        : const SizedBox.shrink(),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                option,
                                                style: TextStyle(
                                                  fontSize: 13.5,
                                                  fontWeight:
                                                      isSelected
                                                          ? FontWeight.bold
                                                          : FontWeight.w400,
                                                  color: const Color(
                                                    0xFF1E1E1E,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF333333),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.filter_list,
                                    size: 18,
                                    color: Color(0xFF1E1E1E),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _selectedFilter,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF1E1E1E),
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.keyboard_arrow_down,
                                    size: 18,
                                    color: Color(0xFF1E1E1E),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Right Sort Dropdown (Most Popular, Most Recent, Name A-Z)
                        Expanded(
                          child: PopupMenuButton<String>(
                            onSelected: (value) {
                              setState(() {
                                _selectedSort = value;
                              });
                            },
                            offset: const Offset(0, 44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            color: Colors.white,
                            itemBuilder:
                                (context) =>
                                    [
                                      'Most Popular',
                                      'Most Recent',
                                      'Name A-Z',
                                    ].map((option) {
                                      final isSelected =
                                          _selectedSort == option;
                                      return PopupMenuItem<String>(
                                        value: option,
                                        height: 40,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                isSelected
                                                    ? const Color(0xFFF1F5F9)
                                                    : Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              SizedBox(
                                                width: 20,
                                                child:
                                                    isSelected
                                                        ? const Icon(
                                                          Icons.check,
                                                          size: 16,
                                                          color: Color(
                                                            0xFF1E1E1E,
                                                          ),
                                                        )
                                                        : const SizedBox.shrink(),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                option,
                                                style: TextStyle(
                                                  fontSize: 13.5,
                                                  fontWeight:
                                                      isSelected
                                                          ? FontWeight.bold
                                                          : FontWeight.w400,
                                                  color: const Color(
                                                    0xFF1E1E1E,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF333333),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _selectedSort,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF1E1E1E),
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.keyboard_arrow_down,
                                    size: 18,
                                    color: Color(0xFF1E1E1E),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFE2E8F0),
                    ),
                    const SizedBox(height: 16),

                    // 6. Segmented Tab Switcher (Artists (1) vs Artworks (1))
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedTabIndex = 0;
                                });
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      _selectedTabIndex == 0
                                          ? Colors.white
                                          : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow:
                                      _selectedTabIndex == 0
                                          ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.05,
                                              ),
                                              blurRadius: 4,
                                            ),
                                          ]
                                          : [],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.group_outlined,
                                      size: 16,
                                      color:
                                          _selectedTabIndex == 0
                                              ? const Color(0xFF1E1E1E)
                                              : const Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Artists (${activeArtists.length})',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight:
                                            _selectedTabIndex == 0
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                        color:
                                            _selectedTabIndex == 0
                                                ? const Color(0xFF1E1E1E)
                                                : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedTabIndex = 1;
                                });
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      _selectedTabIndex == 1
                                          ? Colors.white
                                          : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow:
                                      _selectedTabIndex == 1
                                          ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.05,
                                              ),
                                              blurRadius: 4,
                                            ),
                                          ]
                                          : [],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image_outlined,
                                      size: 16,
                                      color:
                                          _selectedTabIndex == 1
                                              ? const Color(0xFF1E1E1E)
                                              : const Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Artworks (${_categoryArtworks.length})',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight:
                                            _selectedTabIndex == 1
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                        color:
                                            _selectedTabIndex == 1
                                                ? const Color(0xFF1E1E1E)
                                                : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 7. Tab Content List
                    if (_selectedTabIndex == 0) ...[
                      if (activeArtists.isNotEmpty)
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: activeArtists.length,
                          separatorBuilder:
                              (context, index) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final artist = activeArtists[index];
                            return _buildArtistCard(context, artist);
                          },
                        )
                      else
                        _buildEmptyState('No artists found in this category yet.'),
                    ] else ...[
                      if (_categoryArtworks.isNotEmpty)
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _categoryArtworks.length,
                          separatorBuilder:
                              (context, index) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            return _buildArtworkCard(_categoryArtworks[index]);
                          },
                        )
                      else
                        _buildEmptyState('No artworks found in this category yet.'),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 1),
    );
  }

  // Artist Card (Matching Screenshot media_1787732673273.png)
  Widget _buildArtistCard(BuildContext context, ArtistModel artist) {
    final isLiked = _likedArtistIds.contains(artist.id);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3E8FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.group_outlined,
                  color: Color(0xFF5E227A),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artist.name.isEmpty ? 'Artist' : artist.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5E227A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          artist.location.isEmpty
                              ? 'Dubai, UAE'
                              : artist.location,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Share button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _shareArtist(artist),
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
              // Like ❤️ button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _toggleLike(artist),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isLiked
                          ? const Color(0xFFE11D48).withValues(alpha: 0.1)
                          : Colors.transparent,
                      border: Border.all(
                        color: isLiked
                            ? const Color(0xFFE11D48)
                            : const Color(0xFFE2E8F0),
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      size: 16,
                      color: isLiked
                          ? const Color(0xFFE11D48)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Bio Snippet
          Text(
            artist.bio.isEmpty
                ? 'Artist based in Dubai, UAE.'
                : artist.bio,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),

          // Experience & Likes/Artwork Count Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.people_outline, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(
                    '${artist.followersCount} likes',
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              Text(
                '${artist.worksCount > 0 ? artist.worksCount : 3} artworks',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Full-Width Purple View Portfolio Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A2777),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ArtistDetailView(artist: artist),
                  ),
                );
              },
              child: const Text(
                'View Portfolio',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 48,
        horizontal: 24,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.palette_outlined,
              size: 48,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtworkCard(Map<String, dynamic> item) {
    final title = (item['title'] ?? 'Artwork').toString();
    final artist = (item['artist_name'] ?? item['artist'] ?? 'Artist').toString();
    final medium = (item['medium'] ?? '').toString();
    final dimensions = (item['dimensions'] ?? '').toString();
    final description = (item['description'] ?? '').toString();
    final imageUrl = (item['image_url'] ?? item['image'] ?? '').toString();
    final isFeatured = item['is_featured'] == 1 || item['is_featured'] == true;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl.isNotEmpty)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: AppCachedImage(
                    imageUrl: imageUrl,
                    height: 380,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                if (isFeatured)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Featured',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

          // Artwork Text Details
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'by $artist',
                  style: const TextStyle(fontSize: 13.5, color: Color(0xFF64748B)),
                ),
                if (medium.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    medium,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                ],
                if (dimensions.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    dimensions,
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                  ),
                ],
                const SizedBox(height: 16),

                // View Details Button Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: 38,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1E1E1E),
                          side: const BorderSide(
                            color: Color(0xFF333333),
                            width: 1.0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: Text(title),
                                  content: Text(
                                    '$title by $artist\n\n'
                                    '${medium.isNotEmpty ? 'Medium: $medium\n' : ''}'
                                    '${dimensions.isNotEmpty ? 'Dimensions: $dimensions\n\n' : '\n'}'
                                    '$description',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                          );
                        },
                        child: const Text(
                          'View Details',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
