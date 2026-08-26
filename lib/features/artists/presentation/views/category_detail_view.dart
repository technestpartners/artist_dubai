import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_top_bar.dart';
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

  @override
  void initState() {
    super.initState();
    _title = widget.categoryName ?? 'Calligraphy & Typography';
    _categoryEmoji = widget.emoji ?? '✍️';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final artists =
        ArtistModel.mockArtists.where((a) {
          if (widget.categoryName == null) return true;
          return a.category.toLowerCase().contains(_title.toLowerCase()) ||
              _title.toLowerCase().contains(a.category.toLowerCase());
        }).toList();

    final activeArtists =
        artists.isEmpty ? ArtistModel.mockArtists.take(1).toList() : artists;

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
                                      'Artworks (1)',
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
                    if (_selectedTabIndex == 0)
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
                      _buildArtworkCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            const AppBottomNavBar(currentIndex: 1),
          ],
        ),
      ),
    );
  }

  // Artist Card (Matching Screenshot media_1787732673273.png)
  Widget _buildArtistCard(BuildContext context, ArtistModel artist) {
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
                      artist.name.isEmpty ? 'Fatima Al Qasimi' : artist.name,
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
                              ? 'Sharjah, UAE'
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
            ],
          ),
          const SizedBox(height: 12),

          // Bio Snippet
          Text(
            artist.bio.isEmpty
                ? 'Traditional calligrapher and contemporary artist specializing in Arabic typography and mixed media installations.'
                : artist.bio,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),

          // Experience & Artwork Count Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Professional - 15+ years',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
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

  Widget _buildArtworkCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with Top-Right Featured Badge (Matching Screenshot media_1787732712379.png)
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.network(
                  'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?q=80&w=1200&auto=format&fit=crop',
                  height: 380,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => Container(
                        height: 380,
                        color: const Color(0xFFF1F5F9),
                        child: const Icon(
                          Icons.image,
                          size: 64,
                          color: Color(0xFF64748B),
                        ),
                      ),
                ),
              ),
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
                const Text(
                  'Sacred Verses',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'by Fatima Al Qasimi',
                  style: TextStyle(fontSize: 13.5, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Mixed Media on Paper',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 2),
                const Text(
                  '70 x 50 cm',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 16),

                // Price Range & View Details Button Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'USD 1800 - 2200',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5E227A),
                      ),
                    ),
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
                                  title: const Text('Sacred Verses'),
                                  content: const Text(
                                    'Sacred Verses by Fatima Al Qasimi\n\n'
                                    'Medium: Mixed Media on Paper\n'
                                    'Dimensions: 70 x 50 cm\n'
                                    'Price Range: USD 1800 - 2200\n\n'
                                    'Original artwork combining traditional Arabic calligraphy with classical gold leaf & ink techniques.',
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
