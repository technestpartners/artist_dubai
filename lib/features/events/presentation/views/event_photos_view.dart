import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
        final title = g['name'] as String? ?? g['title'] as String? ?? 'Photo Gallery';
        final subtitle = g['description'] as String? ?? g['subtitle'] as String? ?? g['about'] as String?;
        final coverImage = g['image_url'] as String? ?? g['image'] as String? ?? '';
        final rawImgs = g['images'] as List<dynamic>? ?? [];

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

  void _showUploadPhotosModal(BuildContext context) {
    final titleController = TextEditingController();
    final subtitleController = TextEditingController();
    final ImagePicker picker = ImagePicker();
    final List<XFile> modalImages = [];
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickImages() async {
              try {
                final List<XFile> selected = await picker.pickMultiImage(imageQuality: 85);
                if (selected.isNotEmpty) {
                  setModalState(() {
                    modalImages.addAll(selected);
                  });
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error selecting images: $e'),
                      backgroundColor: const Color(0xFFDC2626),
                    ),
                  );
                }
              }
            }

            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Upload Event Photos',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E1E1E),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                            onPressed: isUploading ? null : () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Title Field
                      const Text(
                        'Gallery Title *',
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
                          hintText: 'e.g. Opening Night Highlights',
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Subtitle Field
                      const Text(
                        'Subtitle / Description',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E1E1E),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: subtitleController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Add a brief note about these photos...',
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Images Box
                      const Text(
                        'Photos *',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E1E1E),
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: pickImages,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAFAFA),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFCBD5E1),
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 32,
                                color: Color(0xFF6B1C9B),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                modalImages.isEmpty
                                    ? 'Click to select photos from device'
                                    : '${modalImages.length} photo(s) selected (tap to add more)',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: modalImages.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                                  color: modalImages.isNotEmpty ? const Color(0xFF6B1C9B) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (modalImages.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 70,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: modalImages.length,
                            itemBuilder: (context, idx) {
                              final img = modalImages[idx];
                              return Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 70,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: kIsWeb
                                          ? Image.network(
                                              img.path,
                                              width: 70,
                                              height: 70,
                                              fit: BoxFit.cover,
                                            )
                                          : Image.file(
                                              File(img.path),
                                              width: 70,
                                              height: 70,
                                              fit: BoxFit.cover,
                                            ),
                                    ),
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: GestureDetector(
                                        onTap: () {
                                          setModalState(() {
                                            modalImages.removeAt(idx);
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.7),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            size: 12,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),

                      // Action Buttons: Cancel & Upload
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1E1E1E),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                            ),
                            onPressed: isUploading ? null : () => Navigator.pop(context),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6B1C9B),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                            ),
                            onPressed: isUploading
                                ? null
                                : () async {
                                    final title = titleController.text.trim();
                                    final subtitle = subtitleController.text.trim();
                                    if (title.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Please enter a gallery title')),
                                      );
                                      return;
                                    }

                                    setModalState(() {
                                      isUploading = true;
                                    });

                                    List<String> finalUploadedUrls = [];

                                    if (modalImages.isNotEmpty) {
                                      for (final xfile in modalImages) {
                                        try {
                                          final bytes = await xfile.readAsBytes();
                                          final nameParts = xfile.name.split('.');
                                          final ext = nameParts.length > 1 ? nameParts.last : 'jpg';
                                          final url = await sl<ApiService>().uploadImageBytes(
                                            bytes,
                                            ext: ext.isNotEmpty ? ext : 'jpg',
                                          );
                                          if (url != null && url.isNotEmpty) {
                                            finalUploadedUrls.add(url);
                                          }
                                        } catch (_) {}
                                      }
                                    }

                                    if (finalUploadedUrls.isEmpty) {
                                      setModalState(() {
                                        isUploading = false;
                                      });
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Please select at least one photo from your device to upload.'),
                                            backgroundColor: Color(0xFFDC2626),
                                          ),
                                        );
                                      }
                                      return;
                                    }

                                    final coverUrl = finalUploadedUrls.first;

                                    await sl<ApiService>().createGallery(
                                      title: title,
                                      description: subtitle.isNotEmpty ? subtitle : 'Event photo collection',
                                      imageUrl: coverUrl,
                                      images: finalUploadedUrls,
                                    );

                                    sl<LiveSyncService>().notifyGalleriesChanged();
                                    sl<LiveSyncService>().notifyEventsChanged();

                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Photo gallery "$title" published to database!'),
                                          backgroundColor: const Color(0xFF6B1C9B),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                            child: isUploading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Upload & Save',
                                    style: TextStyle(fontWeight: FontWeight.bold),
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
      },
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
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
                        Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 20),
                          child: Text(
                            'Photo galleries from Dubai art events',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF6B1C9B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.upload_outlined, size: 16),
                      label: const Text('Upload', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                      onPressed: () => _showUploadPhotosModal(context),
                    ),
                  ),
                ],
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
