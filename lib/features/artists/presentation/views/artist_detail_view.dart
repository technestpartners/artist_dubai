import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../bookings/presentation/views/book_artist_view.dart';
import '../../domain/models/artist_model.dart';

class ArtistDetailView extends StatefulWidget {
  final ArtistModel? artist;

  const ArtistDetailView({super.key, this.artist});

  @override
  State<ArtistDetailView> createState() => _ArtistDetailViewState();
}

class _ArtistDetailViewState extends State<ArtistDetailView> {
  bool _isFollowing = false;
  bool _isGridView =
      true; // Toggle between Grid (2-column) and List (1-column horizontal)
  final Set<int> _favoritedArtworks = {};

  final List<Map<String, String>> _photoGalleries = [
    {
      'title': 'Exhibition Highlights 2024',
      'count': '1 photos',
      'image':
          'https://images.unsplash.com/photo-1451187580459-43490279c0fa?q=80&w=1200&auto=format&fit=crop',
    },
  ];

  void _showCreateGalleryModal(String artistName) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Header with Close Button (Matching Screenshot media_1787735179440.png)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Create New Gallery for $artistName',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E1E1E),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Color(0xFF64748B),
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Gallery Title
                  const Text(
                    'Gallery Title',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: 'Enter gallery title...',
                      hintStyle: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13.5,
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
                          color: Color(0xFF5E227A),
                          width: 1.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF5E227A),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description (optional)
                  const Text(
                    'Description (optional)',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Describe this gallery...',
                      hintStyle: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13.5,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Images Drag & Drop Box
                  const Text(
                    'Images',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Image selection opened'),
                          backgroundColor: Color(0xFF6A2777),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFCBD5E1),
                          style: BorderStyle.solid,
                          width: 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.upload_outlined,
                            size: 36,
                            color: Color(0xFF64748B),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Click to select images or drag and drop',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Modal Actions Row: Cancel & Create Gallery
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        height: 42,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFF333333),
                              width: 1.0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E1E1E),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 42,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6A2777),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                          ),
                          onPressed: () {
                            final title = titleController.text.trim();
                            if (title.isNotEmpty) {
                              setState(() {
                                _photoGalleries.add({
                                  'title': title,
                                  'count': '0 photos',
                                  'image':
                                      'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?q=80&w=1200&auto=format&fit=crop',
                                });
                              });
                            }
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Gallery created successfully!'),
                                backgroundColor: Color(0xFF6A2777),
                              ),
                            );
                          },
                          child: const Text(
                            'Create Gallery',
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
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentArtist =
        widget.artist ??
        ArtistModel.mockArtists.firstWhere(
          (a) => a.category.contains('Calligraphy'),
          orElse: () => ArtistModel.mockArtists.first,
        );

    final mockArtworks = List.generate(15, (index) {
      final id = index + 1;
      return {
        'id': id.toString(),
        'title': 'Artwork $id',
        'details': '2024 • Mixed Media',
        'dimensions': '120 x 80 cm',
        'description': 'Artwork by ${currentArtist.name}',
        'artist': 'By ${currentArtist.name}',
        'price': '\$${(id * 500) + 1500}',
        'image':
            [
              'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?q=80&w=1200&auto=format&fit=crop',
              'https://images.unsplash.com/photo-1541701494587-cb58502866ab?q=80&w=1200&auto=format&fit=crop',
              'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=1200&auto=format&fit=crop',
              'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?q=80&w=1200&auto=format&fit=crop',
              'https://images.unsplash.com/photo-1451187580459-43490279c0fa?q=80&w=1200&auto=format&fit=crop',
            ][index % 5],
      };
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: const AppTopBar(backgroundColor: Colors.white),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Sub-Header with Back Button & Share/Favorite Actions
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    'Artist Profile',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.share_outlined,
                      size: 18,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.favorite_border,
                      size: 18,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

            // Main Body Scroll Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. Artist Main Information Card (Matching Screenshots)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Column(
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 42,
                            backgroundColor: const Color(0xFFF3E8FF),
                            backgroundImage: NetworkImage(
                              currentArtist.avatarUrl,
                            ),
                            child:
                                currentArtist.avatarUrl.isEmpty
                                    ? const Icon(
                                      Icons.person,
                                      size: 42,
                                      color: Color(0xFF6A2777),
                                    )
                                    : null,
                          ),
                          const SizedBox(height: 14),

                          // Name
                          Text(
                            currentArtist.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E1E1E),
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Category
                          Text(
                            currentArtist.category,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Location
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                currentArtist.location,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Stats Row (15 Artworks | 0 Likes | 0 Followers)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatItem('15', 'Artworks'),
                              Container(
                                height: 24,
                                width: 1,
                                color: const Color(0xFFE2E8F0),
                              ),
                              _buildStatItem('0', 'Likes'),
                              Container(
                                height: 24,
                                width: 1,
                                color: const Color(0xFFE2E8F0),
                              ),
                              _buildStatItem('0', 'Followers'),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Bio Paragraph
                          Text(
                            currentArtist.bio,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFF475569),
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Tags Row
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              _buildTagChip(currentArtist.category),
                              _buildTagChip(currentArtist.location),
                              _buildTagChip('Professional'),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Joined Date
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 15,
                                color: Color(0xFF64748B),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Joined August 2024',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Action Buttons Row: Book Artist & Follow
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: SizedBox(
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
                                          builder:
                                              (context) => BookArtistView(
                                                artistName: currentArtist.name,
                                              ),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Book Artist',
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: SizedBox(
                                  height: 44,
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: Color(0xFF333333),
                                        width: 1.0,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isFollowing = !_isFollowing;
                                      });
                                    },
                                    icon: Icon(
                                      _isFollowing
                                          ? Icons.check
                                          : Icons.person_add_outlined,
                                      size: 16,
                                      color: const Color(0xFF1E1E1E),
                                    ),
                                    label: Text(
                                      _isFollowing ? 'Following' : 'Follow',
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E1E1E),
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
                    const SizedBox(height: 28),

                    // 3. Portfolio Section with View Mode Switcher (Matching Screenshots media_1787735140178.png & media_1787735153023.png)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Portfolio',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E1E1E),
                          ),
                        ),

                        // View Mode Switcher Toggle (Grid 🔲 vs List ☰)
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              // Grid Mode Toggle Button
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _isGridView = true;
                                  });
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color:
                                        _isGridView
                                            ? const Color(0xFF6A2777)
                                            : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    Icons.grid_view,
                                    size: 18,
                                    color:
                                        _isGridView
                                            ? Colors.white
                                            : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),

                              // List Mode Toggle Button
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _isGridView = false;
                                  });
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color:
                                        !_isGridView
                                            ? const Color(0xFF6A2777)
                                            : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    Icons.view_list,
                                    size: 18,
                                    color:
                                        !_isGridView
                                            ? Colors.white
                                            : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Portfolio Artworks Content (Grid vs List)
                    if (_isGridView)
                      _buildArtworksGrid(mockArtworks)
                    else
                      _buildArtworksList(mockArtworks),
                    const SizedBox(height: 20),

                    // 4. Photo Galleries Section Container (Matching Screenshot media_1787735179440.png)
                    Container(
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Photo Galleries',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E1E1E),
                                ),
                              ),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Color(0xFF333333),
                                    width: 1.0,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                ),
                                onPressed:
                                    () => _showCreateGalleryModal(
                                      currentArtist.name,
                                    ),
                                icon: const Icon(
                                  Icons.add,
                                  size: 16,
                                  color: Color(0xFF1E1E1E),
                                ),
                                label: const Text(
                                  'Create Gallery',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E1E1E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Galleries Content
                          if (_photoGalleries.isEmpty)
                            Center(
                              child: Column(
                                children: const [
                                  Icon(
                                    Icons.collections_outlined,
                                    size: 48,
                                    color: Color(0xFF64748B),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'No photo galleries available yet',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _photoGalleries.length,
                              separatorBuilder:
                                  (context, index) =>
                                      const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final gallery = _photoGalleries[index];
                                return _buildGalleryCard(gallery);
                              },
                            ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom Navigation Bar
            const AppBottomNavBar(currentIndex: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String number, String label) {
    return Column(
      children: [
        Text(
          number,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E1E1E),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildTagChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF475569),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // 2-Column Grid View of Artworks (Matching Screenshot media_1787735140178.png)
  Widget _buildArtworksGrid(List<Map<String, String>> artworks) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.65,
      ),
      itemCount: artworks.length,
      itemBuilder: (context, index) {
        final item = artworks[index];
        final itemIndex = index + 1;
        final isFav = _favoritedArtworks.contains(itemIndex);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image with Featured Badge
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(10),
                    ),
                    child: Image.network(
                      item['image']!,
                      height: 135,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => Container(
                            height: 135,
                            color: const Color(0xFFF1F5F9),
                            child: const Icon(
                              Icons.image,
                              size: 36,
                              color: Color(0xFF64748B),
                            ),
                          ),
                    ),
                  ),
                  if (index == 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6A2777),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Featured',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // Details Section
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title']!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '2024',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Mixed Media',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            if (isFav) {
                              _favoritedArtworks.remove(itemIndex);
                            } else {
                              _favoritedArtworks.add(itemIndex);
                            }
                          });
                        },
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: isFav ? Colors.red : const Color(0xFF64748B),
                        ),
                      ),
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

  // 1-Column Horizontal List View of Artworks (Matching Screenshot media_1787735153023.png)
  Widget _buildArtworksList(List<Map<String, String>> artworks) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: artworks.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = artworks[index];
        final itemIndex = index + 1;
        final isFav = _favoritedArtworks.contains(itemIndex);

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item['image']!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => Container(
                        width: 56,
                        height: 56,
                        color: const Color(0xFFF1F5F9),
                        child: const Icon(
                          Icons.image,
                          size: 24,
                          color: Color(0xFF64748B),
                        ),
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title']!,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item['details']!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item['description']!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item['artist']!,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    if (isFav) {
                      _favoritedArtworks.remove(itemIndex);
                    } else {
                      _favoritedArtworks.add(itemIndex);
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    size: 18,
                    color: isFav ? Colors.red : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGalleryCard(Map<String, String> gallery) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
                child: Image.network(
                  gallery['image']!,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => Container(
                        height: 140,
                        color: const Color(0xFFF1F5F9),
                        child: const Icon(
                          Icons.collections,
                          size: 36,
                          color: Color(0xFF64748B),
                        ),
                      ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    gallery['count']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gallery['title']!,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Main gallery by Artist',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
