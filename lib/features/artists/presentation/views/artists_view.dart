import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_top_bar.dart';
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
  final List<ArtistModel> _allArtists = ArtistModel.mockArtists;
  final List<CategoryInfo> _categories = ArtistModel.categoryList;

  bool get _isLoggedIn {
    try {
      return sl<StorageService>().getBool('is_logged_in') ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool loggedIn = _isLoggedIn;

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFD),
      appBar: const AppTopBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: loggedIn ? _buildLoggedInView() : _buildLoggedOutView(),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 1),
    );
  }

  // 1. Logged Out View (Matches Screenshot media_1787743827404.png)
  Widget _buildLoggedOutView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Featured Artists Header
        Center(
          child: Column(
            children: const [
              Text(
                'Featured Artists',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E1E1E),
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'No artist profiles available yet',
                style: TextStyle(fontSize: 14.5, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // No Artists Yet Box & Create Profile Button
        Center(
          child: Column(
            children: [
              const Text(
                'No Artists Yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Be the first to create an artist profile!',
                style: TextStyle(fontSize: 14.5, color: Color(0xFF616161)),
              ),
              const SizedBox(height: 20),

              // Create Artist Profile Button
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5E227A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    context.push(RouteNames.login);
                  },
                  child: const Text(
                    'Create Artist Profile',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),

        // Select a Category Input Box
        _buildCategorySelectorField(),
        const SizedBox(height: 6),

        // Inline Category List Box (Matching Screenshot)
        if (_isCategoryListExpanded) _buildInlineCategoryList(),
        const SizedBox(height: 24),
      ],
    );
  }

  // 2. Logged In View
  Widget _buildLoggedInView() {
    final filteredArtists =
        _selectedCategory == null
            ? _allArtists
            : _allArtists
                .where((a) => a.category == _selectedCategory)
                .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Section
        Center(
          child: Column(
            children: const [
              Text(
                'Featured Artists',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E1E1E),
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Discover 30 talented artists',
                style: TextStyle(fontSize: 14.5, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Active Category Filter Badge
        if (_selectedCategory != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF5E227A).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF5E227A).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.filter_list,
                      size: 16,
                      color: Color(0xFF5E227A),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Filtered by: $_selectedCategory',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5E227A),
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCategory = null;
                    });
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF5E227A),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Artists List
        if (filteredArtists.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(
                  Icons.palette_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  'No artists found in this category',
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
            itemCount: filteredArtists.length,
            separatorBuilder: (context, index) => const SizedBox(height: 18),
            itemBuilder: (context, index) {
              final artist = filteredArtists[index];
              return _buildArtistCard(artist);
            },
          ),
        const SizedBox(height: 28),

        // Select a Category Field
        _buildCategorySelectorField(),
        const SizedBox(height: 6),
        if (_isCategoryListExpanded) _buildInlineCategoryList(),
        const SizedBox(height: 24),
      ],
    );
  }

  // Select a Category Field
  Widget _buildCategorySelectorField() {
    return InkWell(
      onTap: () {
        setState(() {
          _isCategoryListExpanded = !_isCategoryListExpanded;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.15),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Color(0xFF5F6368), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _selectedCategory ?? 'Select a Category',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
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
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // Inline Category List Box (Exact Match to Screenshot)
  Widget _buildInlineCategoryList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.12),
          width: 1.0,
        ),
      ),
      child: Column(
        children: List.generate(_categories.length, (index) {
          final cat = _categories[index];
          final count = _allArtists.where((a) => a.category == cat.name).length;
          final isSelected = _selectedCategory == cat.name;
          final isLast = index == _categories.length - 1;

          return Column(
            children: [
              InkWell(
                onTap: () {
                  if (!_isLoggedIn) {
                    setState(() {
                      _selectedCategory = isSelected ? null : cat.name;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Please log in to view ${cat.name} artists',
                        ),
                        backgroundColor: const Color(0xFF5E227A),
                        behavior: SnackBarBehavior.floating,
                        action: SnackBarAction(
                          label: 'Login',
                          textColor: Colors.white,
                          onPressed: () => context.push(RouteNames.login),
                        ),
                      ),
                    );
                  } else {
                    setState(() {
                      _selectedCategory = isSelected ? null : cat.name;
                    });
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 13.0,
                  ),
                  child: Row(
                    children: [
                      Text(cat.emoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          cat.name,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: const Color(0xFF1E1E1E),
                          ),
                        ),
                      ),
                      Text(
                        '$count artists',
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              isSelected
                                  ? const Color(0xFF5E227A)
                                  : const Color(0xFF64748B),
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFF1F5F9),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildArtistCard(ArtistModel artist) {
    return Container(
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
                child: Image.network(
                  artist.bannerUrl,
                  height: 165,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => Container(
                        height: 165,
                        color: const Color(0xFF5E227A).withValues(alpha: 0.15),
                        child: const Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 44,
                            color: Color(0xFF5E227A),
                          ),
                        ),
                      ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.share_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border,
                        color: Colors.white,
                        size: 20,
                      ),
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
                  child: const Text(
                    'Professional (10+ years)',
                    style: TextStyle(
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
                          '${artist.followersCount} likes   ${artist.worksCount} artworks',
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
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => ArtistDetailView(artist: artist),
                            ),
                          );
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
    );
  }
}
