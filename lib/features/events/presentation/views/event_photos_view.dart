import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/live_sync_service.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/app_cached_image.dart';
import '../../domain/models/art_event_model.dart';
import '../widgets/event_gallery_modal.dart';

class EventPhotosView extends StatefulWidget {
  const EventPhotosView({super.key});

  @override
  State<EventPhotosView> createState() => _EventPhotosViewState();
}

class _EventPhotosViewState extends State<EventPhotosView> {
  List<ArtEventModel> _eventsWithGalleries = [];
  bool _isLoading = true;
  StreamSubscription<List<ArtEventModel>>? _eventsSub;
  StreamSubscription<List<Map<String, dynamic>>>? _galleriesSub;

  @override
  void initState() {
    super.initState();
    _fetchEventPhotos();
    _eventsSub = sl<LiveSyncService>().eventsStream.listen((_) {
      _fetchEventPhotos();
    });
    _galleriesSub = sl<LiveSyncService>().galleriesStream.listen((_) {
      _fetchEventPhotos();
    });
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    _galleriesSub?.cancel();
    super.dispose();
  }

  Future<void> _fetchEventPhotos({bool forceRefresh = false}) async {
    try {
      final results = await Future.wait([
        sl<ApiService>().getGalleries(forceRefresh: forceRefresh),
        sl<ApiService>().getEvents(forceRefresh: forceRefresh),
      ]);

      final rawGalleries = results[0] as List<Map<String, dynamic>>;
      final events = results[1] as List<ArtEventModel>;

      final List<ArtEventModel> combined = [];

      // 1. Convert registered photo galleries from MySQL
      for (final g in rawGalleries) {
        final title = g['name']?.toString() ?? g['title']?.toString() ?? 'Photo Gallery';
        final subtitle = g['description']?.toString() ?? g['subtitle']?.toString() ?? g['about']?.toString();
        final coverImage = g['image_url']?.toString() ?? g['image']?.toString() ?? '';
        
        List<dynamic> rawImgs = [];
        if (g['images'] is List) {
          rawImgs = g['images'] as List<dynamic>;
        } else if (g['images'] is String && (g['images'] as String).isNotEmpty) {
          try {
            final decoded = jsonDecode(g['images'] as String);
            if (decoded is List) {
              rawImgs = decoded;
            } else {
              rawImgs = (g['images'] as String).split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
            }
          } catch (_) {
            rawImgs = (g['images'] as String).split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
          }
        }

        final List<GalleryImageItem> imagesList = [];
        for (var idx = 0; idx < rawImgs.length; idx++) {
          final item = rawImgs[idx];
          if (item is String && item.isNotEmpty) {
            imagesList.add(GalleryImageItem(title: '$title #${idx + 1}', imageUrl: item));
          } else if (item is Map<String, dynamic>) {
            imagesList.add(GalleryImageItem(
              title: item['title'] as String? ?? '$title #${idx + 1}',
              imageUrl: item['image_url'] as String? ?? item['image'] as String? ?? '',
              caption: item['caption'] as String? ?? 'Gallery photo',
            ));
          }
        }

        if (imagesList.isEmpty && coverImage.isNotEmpty) {
          imagesList.add(GalleryImageItem(title: title, imageUrl: coverImage));
        }

        if (imagesList.isNotEmpty || coverImage.isNotEmpty) {
          final photoGallery = EventPhotoGallery(
            title: title,
            subtitle: subtitle,
            photoCount: imagesList.isNotEmpty ? imagesList.length : 1,
            date: g['created_at'] as String? ?? 'Recent',
            imageUrl: coverImage.isNotEmpty ? coverImage : (imagesList.isNotEmpty ? imagesList.first.imageUrl : ''),
            images: imagesList,
          );

          combined.add(ArtEventModel(
            id: 'gal-${g['id'] ?? combined.length}',
            title: title,
            category: g['category'] as String? ?? 'Photo Gallery',
            price: 'Free',
            description: subtitle ?? '',
            dateTime: g['created_at'] as String? ?? '',
            location: g['location'] as String? ?? 'Dubai, UAE',
            attendeesCount: 0,
            maxAttendees: 100,
            organizer: g['artist_name'] as String? ?? 'Artist Dubai',
            tags: ['gallery', 'photos'],
            galleries: [photoGallery],
          ));
        }
      }

      // 2. Add events with galleries from MySQL
      for (final e in events) {
        if (e.galleries.isNotEmpty) {
          combined.add(e);
        }
      }

      if (mounted) {
        setState(() {
          _eventsWithGalleries = combined;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _eventsWithGalleries = [];
          _isLoading = false;
        });
      }
    }
  }

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
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                )
              else if (_eventsWithGalleries.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      'No photo galleries found in database.',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _eventsWithGalleries.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, eventIndex) {
                    final event = _eventsWithGalleries[eventIndex];
                    final gallery = event.galleries.first;
                    final displayImages = gallery.images.where((img) => img.imageUrl.isNotEmpty).toList();

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
                          if (gallery.subtitle != null && gallery.subtitle!.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              gallery.subtitle!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),

                          // Real Photos Grid / Cover Image
                          if (displayImages.isNotEmpty)
                            Row(
                              children: displayImages.take(3).toList().asMap().entries.map((entry) {
                                final imgIndex = entry.key;
                                final imgItem = entry.value;
                                final totalShown = displayImages.take(3).length;

                                return Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => _openGallery(
                                      event,
                                      gallery,
                                      initialIndex: imgIndex,
                                    ),
                                    child: Container(
                                      height: 110,
                                      margin: EdgeInsets.only(
                                        right: imgIndex < totalShown - 1 ? 10.0 : 0.0,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: AppCachedImage(
                                          imageUrl: imgItem.imageUrl,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            )
                          else if (gallery.imageUrl.isNotEmpty)
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _openGallery(event, gallery),
                              child: Container(
                                height: 140,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: AppCachedImage(
                                    imageUrl: gallery.imageUrl,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            )
                          else
                            Container(
                              height: 90,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Icon(Icons.photo_library_outlined, color: Colors.white54, size: 28),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
    );
  }
}
