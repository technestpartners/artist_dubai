import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GalleriesView extends StatelessWidget {
  const GalleriesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E082B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E0D3E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Galleries & Art Centers',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2E0D3E), Color(0xFF1E082B), Color(0xFF030104)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Search Bar
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search galleries & centers...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Gallery Card 1
            _buildGalleryCard(
              title: 'Alserkal Avenue Art District',
              location: 'Al Quoz, Dubai',
              description:
                  'Renowned cultural district featuring contemporary art galleries, design venues, and creative spaces.',
              rating: 4.9,
              tags: ['Contemporary', 'Visual Arts', 'Design'],
            ),
            const SizedBox(height: 16),

            // Gallery Card 2
            _buildGalleryCard(
              title: 'Jameel Arts Centre',
              location: 'Jaddaf Waterfront, Dubai',
              description:
                  'Independent institution dedicated to exhibiting contemporary art and engaging communities.',
              rating: 4.8,
              tags: ['Museum', 'Sculpture', 'Exhibitions'],
            ),
            const SizedBox(height: 16),

            // Gallery Card 3
            _buildGalleryCard(
              title: 'Dubai Opera Gallery',
              location: 'Downtown Dubai',
              description:
                  'Showcasing premier modern artworks, sculptures, and international master collections.',
              rating: 4.7,
              tags: ['Modern Art', 'International', 'Sculptures'],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryCard({
    required String title,
    required String location,
    required String description,
    required double rating,
    required List<String> tags,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    rating.toString(),
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
                color: Color(0xFFD4AF37),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                location,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children:
                tags
                    .map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B1C9B).withValues(alpha: 0.4),
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
        ],
      ),
    );
  }
}
