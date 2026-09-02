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

class ArtistsView extends StatefulWidget {
  const ArtistsView({super.key});

  @override
  State<ArtistsView> createState() => _ArtistsViewState();
}

class _ArtistsViewState extends State<ArtistsView> {
  String? _selectedCategory;
  bool _isCategoryListExpanded = false;
  OverlayEntry? _categoryOverlayEntry;
  final GlobalKey _selectorKey = GlobalKey();
  List<ArtistModel> _allArtists = [];
  List<CategoryInfo> _categories = ArtistModel.categoryList;
  final Set<String> _favoritedArtistIds = {};
  StreamSubscription<List<ArtistModel>>? _artistsSub;
  StreamSubscription<Map<String, dynamic>>? _favSub;
  StreamSubscription<List<CategoryInfo>>? _catSub;

  void _shareArtist(ArtistModel artist) {
    Clipboard.setData(
      ClipboardData(
        text:
            'Discover ${artist.name} (${artist.category}) on Artist Dubai!\nExplore their portfolio: https://artistdubai.com/artists/${artist.id}',
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
                'Profile link for ${artist.name} copied to clipboard!',
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5),
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

  String _getEffectiveEmail() {
    try {
      String? email = sl<StorageService>().getString('user_email');
      if (email != null && email.isNotEmpty) return email;
      email = sl<StorageService>().getString('device_guest_id');
      if (email != null && email.isNotEmpty) return email;
      final newId = 'guest_${DateTime.now().millisecondsSinceEpoch}@artistdubai.com';
      sl<StorageService>().setString('device_guest_id', newId);
      return newId;
    } catch (_) {
      return 'user@artistdubai.com';
    }
  }

  DateTime? _lastUserToggleTime;

  void _toggleFavorite(ArtistModel artist) async {
    final userEmail = _getEffectiveEmail();
    final wasFav = _favoritedArtistIds.contains(artist.id);
    _lastUserToggleTime = DateTime.now();

    setState(() {
      if (wasFav) {
        _favoritedArtistIds.remove(artist.id);
      } else {
        _favoritedArtistIds.add(artist.id);
      }

      final updatedIndex = _allArtists.indexWhere((a) => a.id == artist.id);
      if (updatedIndex != -1) {
        final old = _allArtists[updatedIndex];
        final newLikes = wasFav
            ? (old.likesCount - 1).clamp(0, 999999)
            : (old.likesCount + 1);
        _allArtists[updatedIndex] = ArtistModel(
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
          followersCount: old.followersCount,
          likesCount: newLikes,
        );
      }
    });

    final res = await sl<ApiService>().likeArtist(
      artistId: artist.id,
      userEmail: userEmail,
      action: wasFav ? 'unlike' : 'like',
    );

    if (res != null && mounted) {
      setState(() {
        if (res['is_liked'] != null) {
          if (res['is_liked'] == true) {
            _favoritedArtistIds.add(artist.id);
          } else {
            _favoritedArtistIds.remove(artist.id);
          }
        }
        final updatedIndex = _allArtists.indexWhere((a) => a.id == artist.id);
        if (updatedIndex != -1 && res['likes_count'] != null) {
          final old = _allArtists[updatedIndex];
          _allArtists[updatedIndex] = ArtistModel(
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
            followersCount: old.followersCount,
            likesCount: (res['likes_count'] as num).toInt(),
          );
        }
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasFav
                ? 'Removed ${artist.name} from favorites'
                : 'Added ${artist.name} to favorites! ❤️',
          ),
          backgroundColor: wasFav ? const Color(0xFF475569) : const Color(0xFF6A2777),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchData();

    _artistsSub = sl<LiveSyncService>().artistsStream.listen((artists) {
      if (mounted) {
        setState(() {
          _allArtists = artists;
        });
      }
    });

    _favSub = sl<LiveSyncService>().favoritesStream.listen((favData) {
      if (mounted) {
        if (_lastUserToggleTime != null && DateTime.now().difference(_lastUserToggleTime!).inSeconds < 3) {
          return;
        }
        final favArtists = (favData['artists'] as List<ArtistModel>?) ?? [];
        final favIds = favArtists.map((a) => a.id).toSet();
        setState(() {
          _favoritedArtistIds.clear();
          _favoritedArtistIds.addAll(favIds);
        });
      }
    });

    _catSub = sl<LiveSyncService>().categoriesStream.listen((cats) {
      if (mounted) {
        setState(() {
          _categories = cats;
        });
      }
    });
  }

  @override
  void dispose() {
    _artistsSub?.cancel();
    _favSub?.cancel();
    _catSub?.cancel();
    _hideCategoryOverlay();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final userEmail = _getEffectiveEmail();
      final results = await Future.wait([
        sl<ApiService>().getCategories(),
        sl<ApiService>().getArtists(),
        sl<ApiService>().getFavorites(email: userEmail),
      ]);

      final categories = results[0] as List<CategoryInfo>;
      final artists = results[1] as List<ArtistModel>;
      final favData = results[2] as Map<String, dynamic>;
      final favArtists = (favData['artists'] as List<ArtistModel>?) ?? [];
      final favIds = favArtists.map((a) => a.id).toSet();

      if (mounted) {
        setState(() {
          _categories = categories;
          _allArtists = artists;
          _favoritedArtistIds.clear();
          _favoritedArtistIds.addAll(favIds);
        });
      }
    } catch (_) {}
  }

  bool get _isLoggedIn {
    try {
      return sl<StorageService>().getBool('is_logged_in') ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveArtists = _allArtists;
    final filteredArtists =
        _selectedCategory == null
            ? effectiveArtists
            : effectiveArtists
                .where((a) =>
                    a.category.toLowerCase().contains(_selectedCategory!.toLowerCase()) ||
                    _selectedCategory!.toLowerCase().contains(a.category.toLowerCase()))
                .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFD),
      appBar: const AppTopBar(),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF5E227A),
          onRefresh: _fetchData,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Featured Artists Header
                Center(
                  child: Column(
                    children: [
                      const Text(
                        'Featured Artists',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E1E1E),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        filteredArtists.isEmpty
                            ? 'No artist profiles available yet'
                            : 'Discover ${filteredArtists.length} talented artists in Dubai',
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Artists List OR Empty State (Positioned Above Category Selector)
                if (filteredArtists.isEmpty) ...[
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          'No Artists Yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E1E1E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Be the first to create an artist profile!',
                          style: TextStyle(fontSize: 13.5, color: Color(0xFF616161)),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 40,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5E227A),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              if (_isLoggedIn) {
                                context.push(RouteNames.artistRegistration);
                              } else {
                                context.push(RouteNames.login);
                              }
                            },
                            child: const Text(
                              'Create Artist Profile',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ] else ...[
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredArtists.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final artist = filteredArtists[index];
                      return _buildArtistCard(artist);
                    },
                  ),
                  const SizedBox(height: 18),
                ],

                // 3. Select a Category Input Box (Floating Dropdown)
                _buildCategorySelectorField(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 1),
    );
  }

  // Select a Category Field
  Widget _buildCategorySelectorField() {
    return Container(
      key: _selectorKey,
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
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 11.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isCategoryListExpanded
                  ? const Color(0xFF5E227A)
                  : Colors.black.withValues(alpha: 0.2),
              width: _isCategoryListExpanded ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: Color(0xFF5F6368), size: 19),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedCategory ?? 'Select a Category',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color:
                        _selectedCategory != null
                            ? const Color(0xFF1E1E1E)
                            : const Color(0xFF222222),
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

  // Floating Auto-Adjusting Category Popup
  void _showCategoryOverlay() {
    _hideCategoryOverlay();

    final renderBox = _selectorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;

    // Compact dynamic popup height (approx 38px per item)
    final double popupHeight = (_categories.length * 38.0 + 8.0).clamp(100.0, 245.0);

    final double spaceBelow = screenHeight - (offset.dy + size.height) - mediaQuery.padding.bottom;
    final double spaceAbove = offset.dy - mediaQuery.padding.top;

    // Auto-adjust: If space below is insufficient, open above the selector
    final bool showAbove = spaceBelow < popupHeight && spaceAbove > spaceBelow;

    final double topPosition = showAbove
        ? (offset.dy - popupHeight - 2).clamp(mediaQuery.padding.top + 8.0, screenHeight - popupHeight)
        : (offset.dy + size.height + 2).clamp(0.0, screenHeight - popupHeight - mediaQuery.padding.bottom);

    _categoryOverlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            // Full-screen transparent barrier to dismiss on tap outside
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _hideCategoryOverlay,
                child: Container(color: Colors.transparent),
              ),
            ),
            // Floating Auto-Adjusting Overlay Card (Matching media_1787997749795.png)
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
                        final count = _allArtists.where((a) {
                          final catLow = cat.name.toLowerCase();
                          final aLow = a.category.toLowerCase();
                          return aLow.contains(catLow) || catLow.contains(aLow);
                        }).length;
                        final isSelected = _selectedCategory == cat.name;

                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedCategory = isSelected ? null : cat.name;
                            });
                            _hideCategoryOverlay();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14.0,
                              vertical: 8.5,
                            ),
                            child: Row(
                              children: [
                                Text(cat.emoji, style: const TextStyle(fontSize: 15)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    cat.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected ? const Color(0xFF5E227A) : const Color(0xFF1E1E1E),
                                    ),
                                  ),
                                ),
                                Text(
                                  '$count artists',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: isSelected ? const Color(0xFF5E227A) : const Color(0xFF64748B),
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  ),
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

  void _hideCategoryOverlay() {
    if (_categoryOverlayEntry != null) {
      _categoryOverlayEntry?.remove();
      _categoryOverlayEntry = null;
    }
    if (mounted && _isCategoryListExpanded) {
      setState(() {
        _isCategoryListExpanded = false;
      });
    }
  }

  Widget _buildArtistCard(ArtistModel artist) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ArtistDetailView(
                artist: artist,
                initialIsFavorited: _favoritedArtistIds.contains(artist.id),
              ),
            ),
          );
          if (mounted) _fetchData();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.15),
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Banner Image with Share & Favorite Buttons
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
                child: AppCachedImage(
                  imageUrl: artist.bannerUrl,
                  height: 165,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Row(
                  children: [
                    // Interactive Share Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _shareArtist(artist),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.share_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Interactive Favorite Heart Button
                    Builder(
                      builder: (context) {
                        final isFav = _favoritedArtistIds.contains(artist.id);
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _toggleFavorite(artist),
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isFav
                                    ? const Color(0xFFE11D48).withValues(alpha: 0.9)
                                    : Colors.black.withValues(alpha: 0.35),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Card Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Artist Name
                Text(
                  artist.name,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 4),

                // Category Name
                Text(
                  artist.category,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF5F6368),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),

                // Location
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Color(0xFF757575),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      artist.location,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Bio
                Text(
                  artist.bio,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF5F6368),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Experience Badge (Professional 10+ years)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.8),
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    artist.experienceLevel.isNotEmpty
                        ? artist.experienceLevel
                        : 'Professional (5+ years)',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Footer Row: Likes / Artworks & View Profile Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 18,
                          color: Color(0xFF757575),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${artist.likesCount} likes   ${artist.worksCount} artworks',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF757575),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5E227A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => ArtistDetailView(
                                    artist: artist,
                                    initialIsFavorited: _favoritedArtistIds.contains(artist.id),
                                  ),
                            ),
                          );
                          if (mounted) _fetchData();
                        },
                        child: const Text(
                          'View Profile',
                          style: TextStyle(
                            fontSize: 14,
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
    ),
    ),
    );
  }
}
