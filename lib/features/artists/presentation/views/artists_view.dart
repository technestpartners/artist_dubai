import 'dart:async';
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
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/app_cached_image.dart';
import '../../../../core/utils/share_helper.dart';
import '../../domain/models/artist_model.dart';
import 'artist_detail_view.dart';
import 'package:artist_dubai/l10n/app_localizations.dart';
import '../../../../core/utils/data_translator.dart';

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
  bool _isLoading = true;
  List<CategoryInfo> _categories =
      (sl<ApiService>().cachedCategories != null &&
              sl<ApiService>().cachedCategories!.isNotEmpty)
          ? sl<ApiService>().cachedCategories!
          : const <CategoryInfo>[];
  final TextEditingController _categorySearchController = TextEditingController();
  String _categoryFilterQuery = '';
  final Set<String> _favoritedArtistIds = {};
  final Set<String> _followedArtistIds = {};
  bool _hasArtistProfile = false;
  String? _myArtistId;
  ArtistModel? _myArtistProfile;
  StreamSubscription<List<ArtistModel>>? _artistsSub;
  StreamSubscription<Map<String, dynamic>>? _favSub;
  StreamSubscription<List<CategoryInfo>>? _catSub;
  StreamSubscription<bool>? _authSub;

  void _shareArtist(ArtistModel artist) {
    final name = artist.name.isEmpty ? 'Artist' : artist.name;
    ShareHelper.shareArtist(
      context: context,
      artistId: artist.id,
      name: name,
      category: artist.category,
      avatarUrl: artist.avatarUrl,
    );
  }

  String _getEffectiveEmail() {
    try {
      String? email = sl<StorageService>().getString('user_email');
      if (email != null && email.isNotEmpty) return email;
      email = sl<StorageService>().getString('device_guest_id');
      if (email != null && email.isNotEmpty) return email;
      final newId =
          'guest_${DateTime.now().millisecondsSinceEpoch}@artistdubai.com';
      sl<StorageService>().setString('device_guest_id', newId);
      return newId;
    } catch (_) {
      return 'user@artistdubai.com';
    }
  }

  late final FavoritesService _favService;

  void _toggleFavorite(ArtistModel artist) async {
    final wasFav = _favService.isArtistFavorite(artist.id);

    // Optimistically update likes count in list immediately
    setState(() {
      if (wasFav) {
        _favoritedArtistIds.remove(artist.id);
      } else {
        _favoritedArtistIds.add(artist.id);
      }
      final updatedIndex = _allArtists.indexWhere((a) => a.id == artist.id);
      if (updatedIndex != -1) {
        final old = _allArtists[updatedIndex];
        final newLikes =
            wasFav ? (old.likesCount - 1).clamp(0, 999999) : (old.likesCount + 1);
        _allArtists[updatedIndex] = old.copyWith(likesCount: newLikes);
      }
    });

    // Toggle favorite state in FavoritesService (instantly updates local storage & notifies listeners)
    final nowFav = await _favService.toggleArtistFavorite(artist.id);

    if (mounted) {
      if (_favoritedArtistIds.contains(artist.id) != nowFav) {
        setState(() {
          if (nowFav) {
            _favoritedArtistIds.add(artist.id);
          } else {
            _favoritedArtistIds.remove(artist.id);
          }
        });
      }

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !nowFav
                ? 'Removed ${artist.name} from favorites'
                : 'Added ${artist.name} to favorites! ❤️',
          ),
          backgroundColor:
              !nowFav ? const Color(0xFF475569) : const Color(0xFF6A2777),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _favService = sl<FavoritesService>();
    _favoritedArtistIds.addAll(_favService.artistIds);
    _favService.addListener(_onFavoritesUpdated);

    final cached = sl<ApiService>().cachedArtists;
    if (cached != null && cached.isNotEmpty) {
      _allArtists = List.from(cached);
      _isLoading = false;
    } else {
      _allArtists = [];
      _isLoading = false;
    }
    _fetchData();
    _checkMyArtistProfile();

    _artistsSub = sl<LiveSyncService>().artistsStream.listen((artists) {
      if (mounted) {
        setState(() {
          _allArtists = artists;
          _isLoading = false;
        });
        _checkMyArtistProfile();
      }
    });

    _favSub = sl<LiveSyncService>().favoritesStream.listen((favData) {
      if (mounted) {
        _favService.updateFromServer(favData);
      }
    });

    _catSub = sl<LiveSyncService>().categoriesStream.listen((cats) {
      if (mounted) {
        setState(() {
          _categories = cats;
        });
      }
    });

    _authSub = sl<LiveSyncService>().authStream.listen((isLoggedIn) {
      if (mounted) {
        setState(() {});
        _checkMyArtistProfile();
        _fetchData(silent: true);
      }
    });

    DataTranslator.translationNotifier.addListener(_onTranslationChanged);
  }

  void _onFavoritesUpdated() {
    if (mounted) {
      setState(() {
        _favoritedArtistIds
          ..clear()
          ..addAll(_favService.artistIds);
      });
    }
  }

  void _onTranslationChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _favService.removeListener(_onFavoritesUpdated);
    DataTranslator.translationNotifier.removeListener(_onTranslationChanged);
    _artistsSub?.cancel();
    _favSub?.cancel();
    _catSub?.cancel();
    _authSub?.cancel();
    _hideCategoryOverlay();
    _categorySearchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData({bool silent = false}) async {
    if (!silent && _allArtists.isEmpty) {
      setState(() => _isLoading = true);
    }
    final userEmail = _favService.getEffectiveEmail();

    // Fetch artists directly and independently so list renders immediately
    try {
      final artists = await sl<ApiService>().getArtists(forceRefresh: true);
      if (mounted) {
        setState(() {
          _allArtists = artists;
          _isLoading = false;
        });
        _checkMyArtistProfile();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }

    // Refresh categories in background
    sl<ApiService>()
        .getCategories(forceRefresh: true)
        .then((cats) {
          if (mounted && cats.isNotEmpty) {
            setState(() => _categories = cats);
          }
        })
        .catchError((_) {});

    // Refresh user interactions in background
    sl<ApiService>()
        .getUserInteractions(userEmail: userEmail, forceRefresh: true)
        .then((interactions) {
          if (mounted) {
            final serverLiked = interactions['liked'] ?? <String>{};
            _favService.addServerArtistIds(serverLiked);
            setState(() {
              _followedArtistIds
                ..clear()
                ..addAll(interactions['followed'] ?? {});
            });
          }
        })
        .catchError((_) {});
  }

  void _silentRefresh(String userEmail) {
    sl<ApiService>()
        .getArtists(forceRefresh: true)
        .then((artists) {
          if (mounted && artists.isNotEmpty) {
            setState(() => _allArtists = artists);
          }
        })
        .catchError((_) {});

    sl<ApiService>()
        .getUserInteractions(userEmail: userEmail, forceRefresh: true)
        .then((interactions) {
          if (mounted) {
            final serverLiked = interactions['liked'] ?? <String>{};
            _favService.addServerArtistIds(serverLiked);
            setState(() {
              _followedArtistIds
                ..clear()
                ..addAll(interactions['followed'] ?? {});
            });
          }
        })
        .catchError((_) {});
  }

  void _checkMyArtistProfile() async {
    try {
      final storage = sl<StorageService>();
      final isLoggedIn = storage.getBool('is_logged_in') ?? false;
      final email = (storage.getString('user_email') ?? '').trim().toLowerCase();
      final cachedHas = storage.getBool('has_artist_profile') ?? false;
      final cachedId = storage.getString('artist_profile_id');

      if (!isLoggedIn || email.isEmpty) {
        if (mounted) {
          setState(() {
            _hasArtistProfile = false;
            _myArtistId = null;
            _myArtistProfile = null;
          });
        }
        return;
      }

      // Fast check from local cached artist ID or matching in loaded _allArtists
      ArtistModel? match;
      if (_allArtists.isNotEmpty) {
        match = _allArtists.where((a) {
          if (cachedId != null && cachedId.isNotEmpty && a.id == cachedId) {
            return true;
          }
          final aEmail = a.email.trim().toLowerCase();
          return aEmail.isNotEmpty && aEmail == email;
        }).firstOrNull;
      }

      final hasProfile = match != null || (cachedHas && cachedId != null && cachedId.isNotEmpty);
      final artistId = match?.id ?? cachedId;

      if (mounted) {
        setState(() {
          _hasArtistProfile = hasProfile;
          _myArtistId = artistId;
          _myArtistProfile = match;
        });
      }

      // Background verify and refresh with API
      final artist = await sl<ApiService>().getMyArtistProfile();
      if (mounted) {
        setState(() {
          _hasArtistProfile = artist != null;
          _myArtistId = artist?.id ?? artistId;
          _myArtistProfile = artist ?? match;
        });
      }
    } catch (_) {}
  }

  void _openArtistDetail(ArtistModel artist) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder:
            (context) => ArtistDetailView(
              artist: artist,
              initialIsFavorited: _favoritedArtistIds.contains(artist.id),
              initialIsFollowing: _followedArtistIds.contains(artist.id),
            ),
      ),
    );
    // On return — silently refresh from DB in background, no loading flash
    if (mounted) _silentRefresh(_getEffectiveEmail());
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
    final l10n = AppLocalizations.of(context);
    final effectiveArtists =
        _allArtists.where((a) {
          if (!a.isActive) return false;
          final st = a.status.toLowerCase().trim();
          if (st == 'inactive' ||
              st == 'deactive' ||
              st == 'suspended' ||
              st == 'deleted' ||
              st == 'pending') {
            return false;
          }
          return true;
        }).toList();

    // Sort latest artists first
    effectiveArtists.sort((a, b) {
      final aId = int.tryParse(a.id) ?? 0;
      final bId = int.tryParse(b.id) ?? 0;
      if (aId != bId) return bId.compareTo(aId);
      return b.createdAt.compareTo(a.createdAt);
    });
    final filteredArtists =
        _selectedCategory == null
            ? effectiveArtists
            : effectiveArtists.where((a) {
              final selLower = _selectedCategory!.toLowerCase().trim();
              final aCatLower = a.category.toLowerCase().trim();
              final selEn =
                  DataTranslator.translate(
                    selLower,
                    isArabic: false,
                  ).toLowerCase();
              final selAr =
                  DataTranslator.translate(
                    selLower,
                    isArabic: true,
                  ).toLowerCase();
              final aCatEn =
                  DataTranslator.translate(
                    aCatLower,
                    isArabic: false,
                  ).toLowerCase();
              final aCatAr =
                  DataTranslator.translate(
                    aCatLower,
                    isArabic: true,
                  ).toLowerCase();

              return aCatLower.contains(selLower) ||
                  selLower.contains(aCatLower) ||
                  aCatEn.contains(selEn) ||
                  selEn.contains(aCatEn) ||
                  aCatAr.contains(selAr) ||
                  selAr.contains(aCatAr);
            }).toList();

    final rh = ResponsiveHelper.of(context);
    final hPad = rh.horizontalPadding;

    return PopScope(
      canPop: _categoryOverlayEntry == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _categoryOverlayEntry != null) {
          _hideCategoryOverlay();
        }
      },
      child: Scaffold(
      backgroundColor: const Color(0xFF6B1C9B),
      appBar: const AppTopBar(),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF6B1C9B),
          backgroundColor: Colors.white,
          onRefresh: _fetchData,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 16.0),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: rh.contentMaxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 0. Top Navigation & Action Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  context.canPop()
                                      ? Icons.arrow_back
                                      : Icons.home_outlined,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  context.canPop() ? l10n.back : l10n.home,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: SizedBox(
                            height: 38,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF6B1C9B),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              onPressed: () async {
                                if (_hasArtistProfile) {
                                  String? artistId = _myArtistId;
                                  ArtistModel? myArtist = _myArtistProfile;
                                  if (artistId == null || artistId.isEmpty) {
                                    try {
                                      artistId = sl<StorageService>()
                                          .getString('artist_profile_id');
                                    } catch (_) {}
                                  }
                                  await context.push(
                                    RouteNames.artistRegistration,
                                    extra: {
                                      'isEditing': true,
                                      'artist': myArtist,
                                      'artistId': artistId,
                                    },
                                  );
                                  if (mounted) {
                                    _checkMyArtistProfile();
                                    _fetchData(silent: true);
                                  }
                                } else {
                                  await context.push(
                                    RouteNames.artistRegistration,
                                  );
                                  if (mounted) {
                                    _checkMyArtistProfile();
                                    _fetchData(silent: true);
                                  }
                                }
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _hasArtistProfile
                                        ? Icons.edit_outlined
                                        : Icons.add,
                                    size: 16,
                                    color: const Color(0xFF6B1C9B),
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      _hasArtistProfile
                                          ? 'Edit Artist'.trData(context)
                                          : l10n.artistRegistration,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF6B1C9B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 1. Featured Artists Header
                    Center(
                      child: Column(
                        children: [
                          Text(
                            l10n.featuredArtists,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isLoading && filteredArtists.isEmpty
                                ? l10n.loadingArtists
                                : filteredArtists.isEmpty
                                ? l10n.noArtistProfilesAvailable
                                : l10n.discoverArtistsCount(
                                  filteredArtists.length,
                                ),
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFFE2D6F5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. Select a Category Input Box (Floating Dropdown)
                    _buildCategorySelectorField(),
                    const SizedBox(height: 16),

                    // 3. Artists List OR Loading State OR Empty State
                    if (_isLoading && filteredArtists.isEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48.0),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        ),
                      ),
                    ] else if (filteredArtists.isEmpty) ...[
                      Center(
                        child: Column(
                          children: [
                            Text(
                              l10n.noArtistsYet,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.beTheFirstToCreateArtistProfile,
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: Color(0xFFE2D6F5),
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 40,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF6B1C9B),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () async {
                                  if (_isLoggedIn) {
                                    if (_hasArtistProfile) {
                                      await context.push(
                                        RouteNames.artistRegistration,
                                        extra: {
                                          'isEditing': true,
                                          'artist': _myArtistProfile,
                                          'artistId': _myArtistId,
                                        },
                                      );
                                    } else {
                                      await context.push(
                                        RouteNames.artistRegistration,
                                      );
                                    }
                                    if (mounted) {
                                      _checkMyArtistProfile();
                                      _fetchData(silent: true);
                                    }
                                  } else {
                                    context.push(RouteNames.login);
                                  }
                                },
                                child: Text(
                                  _hasArtistProfile
                                      ? 'Edit Artist'.trData(context)
                                      : l10n.createArtistProfile,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF6B1C9B),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ] else ...[
                      // Wide layout: 2-column GridView
                      if (rh.isMobile)
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredArtists.length,
                          separatorBuilder:
                              (context, index) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final artist = filteredArtists[index];
                            return _buildArtistCard(artist);
                          },
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: rh.gridCrossAxisCount,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                childAspectRatio:
                                    rh.isDesktop
                                        ? 0.62
                                        : (rh.isFold ? 0.64 : 0.66),
                              ),
                          itemCount: filteredArtists.length,
                          itemBuilder: (context, index) {
                            return _buildArtistCard(filteredArtists[index]);
                          },
                        ),
                      const SizedBox(height: 18),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 1),
    ),
  );
  }

  // Select a Category Field
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
              color:
                  _isCategoryListExpanded
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
                  _selectedCategory != null
                      ? DataTranslator.tr(context, _selectedCategory!)
                      : AppLocalizations.of(context).selectCategory,
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
              if (_selectedCategory != null)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      _selectedCategory = null;
                    });
                    _hideCategoryOverlay();
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.0),
                    child: Icon(
                      Icons.close,
                      color: Color(0xFF5F6368),
                      size: 18,
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

  // Floating Auto-Adjusting Category Popup with Instant Search
  void _showCategoryOverlay() {
    _hideCategoryOverlay();

    final renderBox =
        _selectorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;

    // Height tailored for comfortable scrolling through all 50 categories
    final double popupHeight = (screenHeight * 0.44).clamp(280.0, 360.0);

    final double spaceBelow =
        screenHeight - (offset.dy + size.height) - mediaQuery.padding.bottom;
    final double spaceAbove = offset.dy - mediaQuery.padding.top;

    // Auto-adjust: If space below is insufficient, open above the selector
    final bool showAbove = spaceBelow < popupHeight && spaceAbove > spaceBelow;

    final double topPosition =
        showAbove
            ? (offset.dy - popupHeight - 4).clamp(
              mediaQuery.padding.top + 8.0,
              screenHeight - popupHeight,
            )
            : (offset.dy + size.height + 4).clamp(
              0.0,
              screenHeight - popupHeight - mediaQuery.padding.bottom,
            );

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
            // Floating Auto-Adjusting Overlay Card
            Positioned(
              left: offset.dx.clamp(
                16.0,
                (screenWidth - size.width - 16.0).clamp(16.0, screenWidth),
              ),
              top: topPosition,
              width: size.width,
              height: popupHeight,
              child: Material(
                color: Colors.transparent,
                child: StatefulBuilder(
                  builder: (context, setOverlayState) {
                    final isAr =
                        Localizations.localeOf(context).languageCode == 'ar';
                    final query = _categoryFilterQuery.trim().toLowerCase();
                    final filteredCategories =
                        query.isEmpty
                            ? _categories
                            : _categories.where((c) {
                              final nameEn = c.name.toLowerCase();
                              final nameAr =
                                  DataTranslator.tr(
                                    context,
                                    c.name,
                                  ).toLowerCase();
                              return nameEn.contains(query) ||
                                  nameAr.contains(query);
                            }).toList();

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.16),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Column(
                          children: [
                            // 1. Search Bar inside Category Overlay
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFAFBFD),
                                border: Border(
                                  bottom: BorderSide(
                                    color: Color(0xFFEDF2F7),
                                    width: 1.0,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.search,
                                    size: 18,
                                    color: Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _categorySearchController,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        color: Color(0xFF1E293B),
                                      ),
                                      decoration: InputDecoration(
                                        hintText:
                                            isAr
                                                ? 'ابحث في 50 فئة فنية...'
                                                : 'Search 50 art categories...',
                                        hintStyle: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF94A3B8),
                                        ),
                                        isDense: true,
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: 4,
                                            ),
                                      ),
                                      onChanged: (val) {
                                        setOverlayState(() {
                                          _categoryFilterQuery = val;
                                        });
                                      },
                                    ),
                                  ),
                                  if (_categoryFilterQuery.isNotEmpty)
                                    GestureDetector(
                                      onTap: () {
                                        setOverlayState(() {
                                          _categorySearchController.clear();
                                          _categoryFilterQuery = '';
                                        });
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 4.0,
                                        ),
                                        child: Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // 2. Categories Scrollable List
                            Expanded(
                              child:
                                  filteredCategories.isEmpty
                                      ? Center(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 20,
                                          ),
                                          child: Text(
                                            isAr
                                                ? 'لا توجد فئات مطابقة'
                                                : 'No matching categories',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF94A3B8),
                                            ),
                                          ),
                                        ),
                                      )
                                      : ListView.separated(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 2,
                                        ),
                                        itemCount:
                                            query.isEmpty
                                                ? filteredCategories.length + 1
                                                : filteredCategories.length,
                                        separatorBuilder:
                                            (context, index) => const Divider(
                                              height: 1,
                                              thickness: 1,
                                              color: Color(0xFFF1F5F9),
                                            ),
                                        itemBuilder: (context, index) {
                                          // "All Categories" option when not searching
                                          if (query.isEmpty && index == 0) {
                                            final isAllSelected =
                                                _selectedCategory == null;
                                            return InkWell(
                                              onTap: () {
                                                setState(() {
                                                  _selectedCategory = null;
                                                });
                                                _hideCategoryOverlay();
                                              },
                                              child: Container(
                                                color:
                                                    isAllSelected
                                                        ? const Color(
                                                          0xFFF7EEFA,
                                                        )
                                                        : Colors.transparent,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 14.0,
                                                      vertical: 9.0,
                                                    ),
                                                child: Row(
                                                  children: [
                                                    const Text(
                                                      '🎨',
                                                      style: TextStyle(
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Text(
                                                        isAr
                                                            ? 'جميع الفئات (الكل)'
                                                            : 'All Categories',
                                                        style: TextStyle(
                                                          fontSize: 13.5,
                                                          fontWeight:
                                                              isAllSelected
                                                                  ? FontWeight
                                                                      .w700
                                                                  : FontWeight
                                                                      .w500,
                                                          color:
                                                              isAllSelected
                                                                  ? const Color(
                                                                    0xFF5E227A,
                                                                  )
                                                                  : const Color(
                                                                    0xFF1E1E1E,
                                                                  ),
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      isAr
                                                          ? '${_allArtists.length} فنان'
                                                          : '${_allArtists.length} artists',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            isAllSelected
                                                                ? const Color(
                                                                  0xFF5E227A,
                                                                )
                                                                : const Color(
                                                                  0xFF64748B,
                                                                ),
                                                        fontWeight:
                                                            isAllSelected
                                                                ? FontWeight
                                                                    .w600
                                                                : FontWeight
                                                                    .w400,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }

                                          final cat =
                                              query.isEmpty
                                                  ? filteredCategories[index -
                                                      1]
                                                  : filteredCategories[index];
                                          final count =
                                              _allArtists.where((a) {
                                                final catLow =
                                                    cat.name.toLowerCase();
                                                final aLow =
                                                    a.category.toLowerCase();
                                                return aLow.contains(catLow) ||
                                                    catLow.contains(aLow);
                                              }).length;
                                          final isSelected =
                                              _selectedCategory == cat.name;

                                          return InkWell(
                                            onTap: () {
                                              setState(() {
                                                _selectedCategory =
                                                    isSelected
                                                        ? null
                                                        : cat.name;
                                              });
                                              _hideCategoryOverlay();
                                            },
                                            child: Container(
                                              color:
                                                  isSelected
                                                      ? const Color(0xFFF7EEFA)
                                                      : Colors.transparent,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 14.0,
                                                    vertical: 8.5,
                                                  ),
                                              child: Row(
                                                children: [
                                                  Text(
                                                    cat.emoji,
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Text(
                                                      DataTranslator.tr(
                                                        context,
                                                        cat.name,
                                                      ),
                                                      style: TextStyle(
                                                        fontSize: 13.5,
                                                        fontWeight:
                                                            isSelected
                                                                ? FontWeight
                                                                    .w700
                                                                : FontWeight
                                                                    .w500,
                                                        color:
                                                            isSelected
                                                                ? const Color(
                                                                  0xFF5E227A,
                                                                )
                                                                : const Color(
                                                                  0xFF1E1E1E,
                                                                ),
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    isAr
                                                        ? '$count فنان'
                                                        : '$count artists',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          isSelected
                                                              ? const Color(
                                                                0xFF5E227A,
                                                              )
                                                              : const Color(
                                                                0xFF64748B,
                                                              ),
                                                      fontWeight:
                                                          isSelected
                                                              ? FontWeight.w600
                                                              : FontWeight.w400,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
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
    _categorySearchController.clear();
    _categoryFilterQuery = '';
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
    final l10n = AppLocalizations.of(context);
    final rh = ResponsiveHelper.of(context);
    final bannerHeight = rh.cardBannerHeight;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openArtistDetail(artist),
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
                      imageUrl:
                          artist.bannerUrl.isNotEmpty
                              ? artist.bannerUrl
                              : (artist.avatarUrl.isNotEmpty
                                  ? artist.avatarUrl
                                  : ''),
                      height: bannerHeight,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  PositionedDirectional(
                    top: 10,
                    end: 10,
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
                        ListenableBuilder(
                          listenable: _favService,
                          builder: (context, _) {
                            final isFav = _favService.isArtistFavorite(
                              artist.id,
                            );
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _toggleFavorite(artist),
                                borderRadius: BorderRadius.circular(18),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color:
                                        isFav
                                            ? const Color(
                                              0xFFE11D48,
                                            ).withValues(alpha: 0.9)
                                            : Colors.black.withValues(
                                              alpha: 0.35,
                                            ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isFav
                                        ? Icons.favorite
                                        : Icons.favorite_border,
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
                      artist.localizedName(context),
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Category Name
                    Text(
                      artist.localizedCategory(context),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF5F6368),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Location
                    // Location
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: Color(0xFF757575),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            artist.localizedLocation(context),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFF757575),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Bio
                    Text(
                      artist.localizedBio(context),
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
                        artist.localizedExperienceLevel(context).isNotEmpty
                            ? artist.localizedExperienceLevel(context)
                            : (Localizations.localeOf(context).languageCode ==
                                    'ar'
                                ? 'محترف (أكثر من 5 سنوات)'
                                : 'Professional (5+ years)'),
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
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.people_outline,
                                size: 18,
                                color: Color(0xFF757575),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  l10n.artistCardStats(
                                    artist.likesCount,
                                    artist.worksCount,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF757575),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 40,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5E227A),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(
                                horizontal: rh.isCompact ? 10 : 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () => _openArtistDetail(artist),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                AppLocalizations.of(context).viewProfile,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
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
