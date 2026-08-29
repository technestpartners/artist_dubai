import 'package:flutter/material.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../home/presentation/widgets/home_footer_widget.dart';

class GalleriesView extends StatefulWidget {
  const GalleriesView({super.key});

  @override
  State<GalleriesView> createState() => _GalleriesViewState();
}

class _GalleriesViewState extends State<GalleriesView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _galleries = const [
    {
      'title': 'Alserkal Avenue Art District',
      'location': 'Al Quoz, Dubai',
      'description': 'Renowned cultural district featuring contemporary art galleries, design venues, pop-ups, and creative spaces.',
      'rating': 4.9,
      'image': 'https://images.unsplash.com/photo-1541701494587-cb58502866ab?q=80&w=1200&auto=format&fit=crop',
      'tags': ['Contemporary', 'Visual Arts', 'Design', 'Pop-ups'],
      'hours': '10:00 AM - 07:00 PM',
      'phone': '+971 4 333 8644',
    },
    {
      'title': 'Jameel Arts Centre',
      'location': 'Jaddaf Waterfront, Dubai',
      'description': 'Independent institution dedicated to exhibiting contemporary art, hosting research commissions, and engaging communities.',
      'rating': 4.8,
      'image': 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?q=80&w=1200&auto=format&fit=crop',
      'tags': ['Museum', 'Sculpture Garden', 'Exhibitions'],
      'hours': '10:00 AM - 08:00 PM',
      'phone': '+971 4 873 9800',
    },
    {
      'title': 'Dubai Opera Gallery',
      'location': 'Downtown Dubai',
      'description': 'Showcasing premier modern artworks, sculptures, and international master collections right at Downtown Dubai.',
      'rating': 4.7,
      'image': 'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?q=80&w=1200&auto=format&fit=crop',
      'tags': ['Modern Art', 'International', 'Sculptures'],
      'hours': '10:00 AM - 10:00 PM',
      'phone': '+971 4 325 3900',
    },
    {
      'title': 'Meem Gallery',
      'location': 'Al Quoz 3, Dubai',
      'description': 'Specialized in modern and contemporary Arab, Persian, and regional Middle Eastern fine art masterpieces.',
      'rating': 4.9,
      'image': 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=1200&auto=format&fit=crop',
      'tags': ['Middle Eastern Art', 'Fine Art', 'Calligraphy'],
      'hours': '10:00 AM - 06:00 PM',
      'phone': '+971 4 347 7883',
    },
    {
      'title': 'The Third Line',
      'location': 'Alserkal Avenue, Dubai',
      'description': 'Pioneering gallery representing Middle Eastern contemporary artists locally, regionally, and internationally.',
      'rating': 4.8,
      'image': 'https://images.unsplash.com/photo-1577896851231-70ef18881754?q=80&w=1200&auto=format&fit=crop',
      'tags': ['Pioneering', 'Emerging Artists', 'Mixed Media'],
      'hours': '11:00 AM - 07:00 PM',
      'phone': '+971 4 341 1367',
    },
    {
      'title': 'Cuadro Fine Art Gallery',
      'location': 'DIFC Gate Village, Dubai',
      'description': 'Located in DIFC, Cuadro offers four key areas: Exhibitions, Education, Residency, and Consultation.',
      'rating': 4.7,
      'image': 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?q=80&w=1200&auto=format&fit=crop',
      'tags': ['DIFC', 'Fine Art', 'Residency'],
      'hours': '10:00 AM - 08:00 PM',
      'phone': '+971 4 425 0400',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showGalleryDetails(Map<String, dynamic> gallery) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    gallery['image'],
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        gallery['title'],
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1E1E)),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(gallery['rating'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: Color(0xFF5E227A), size: 16),
                    const SizedBox(width: 4),
                    Text(gallery['location'], style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(gallery['description'], style: const TextStyle(color: Color(0xFF334155), fontSize: 13.5, height: 1.4)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text('Hours: ${gallery['hours']}', style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569))),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text('Contact: ${gallery['phone']}', style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569))),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5E227A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _galleries.where((g) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final title = (g['title'] as String).toLowerCase();
      final loc = (g['location'] as String).toLowerCase();
      final desc = (g['description'] as String).toLowerCase();
      return title.contains(q) || loc.contains(q) || desc.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF6B1C9B),
      appBar: const AppTopBar(backgroundColor: Colors.white),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Title & Subtitle
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 4),
                child: Text(
                  'GALLERIES ART CENTER',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 16),
                child: Text(
                  'Physical galleries and art spaces across Dubai',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.white70,
                  ),
                ),
              ),

              // Search Bar
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    hintText: 'Search galleries & centers...',
                    hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: const Icon(Icons.close, color: Colors.white54, size: 18),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              const SizedBox(height: 20),

              // Galleries List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final gallery = filtered[index];
                  final tags = gallery['tags'] as List<String>;

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: Image.network(
                            gallery['image'],
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 150,
                              color: Colors.white.withValues(alpha: 0.15),
                              child: const Icon(Icons.apartment, color: Colors.white70, size: 36),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      gallery['title'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 18),
                                      const SizedBox(width: 4),
                                      Text(
                                        gallery['rating'].toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    color: Color(0xFFFFD700),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    gallery['location'],
                                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                gallery['description'],
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13.5,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: tags
                                    .map(
                                      (tag) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          tag,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF5E227A),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onPressed: () => _showGalleryDetails(gallery),
                                  icon: const Icon(Icons.info_outline, size: 18),
                                  label: const Text(
                                    'View Gallery Details',
                                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
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
              ),
              const SizedBox(height: 24),
              const HomeFooterWidget(),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: -1),
    );
  }
}
