import 'package:flutter/material.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../domain/models/art_event_model.dart';
import '../widgets/event_gallery_modal.dart';

class EventPhotosView extends StatefulWidget {
  const EventPhotosView({super.key});

  @override
  State<EventPhotosView> createState() => _EventPhotosViewState();
}

class _EventPhotosViewState extends State<EventPhotosView> {
  void _openGallery(ArtEventModel event, EventPhotoGallery gallery, {int initialIndex = 0}) {
    EventGalleryModal.show(
      context,
      event: event,
      gallery: gallery,
      initialIndex: initialIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Generate default gallery cards if events list is short
    final eventsWithGalleries = ArtEventModel.mockEvents
        .where((event) => event.galleries.isNotEmpty)
        .toList();

    // Standard high quality fallback images for 3-thumbnail gallery cards
    const defaultThumbnails = [
      'https://images.unsplash.com/photo-1506744038136-46273834b3fb?q=80&w=800&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?q=80&w=800&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1552053831-71594a27632d?q=80&w=800&auto=format&fit=crop',
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF6B1C9B),
      appBar: const AppTopBar(backgroundColor: Colors.white),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Section
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 4),
                child: Text(
                  'EVENTS PHOTOS',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 20),
                child: Text(
                  'Photo galleries from Dubai art events',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.white70,
                  ),
                ),
              ),

              // 2. Galleries Card List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: eventsWithGalleries.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, eventIndex) {
                  final event = eventsWithGalleries[eventIndex];
                  final gallery = event.galleries.first;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gallery.title,
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (gallery.subtitle != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            gallery.subtitle!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),

                        // 3 Thumbnails Row
                        Row(
                          children: List.generate(3, (imgIdx) {
                            String imgUrl;
                            if (gallery.images.isNotEmpty && imgIdx < gallery.images.length) {
                              imgUrl = gallery.images[imgIdx].imageUrl;
                            } else {
                              imgUrl = defaultThumbnails[imgIdx % defaultThumbnails.length];
                            }

                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(right: imgIdx < 2 ? 10.0 : 0.0),
                                child: GestureDetector(
                                  onTap: () => _openGallery(event, gallery, initialIndex: imgIdx),
                                  child: AspectRatio(
                                    aspectRatio: 1.0,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        imgUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          color: Colors.white.withValues(alpha: 0.15),
                                          child: const Icon(
                                            Icons.collections,
                                            color: Colors.white70,
                                            size: 28,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
    );
  }
}
