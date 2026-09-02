import 'package:flutter/material.dart';
import '../../domain/models/art_event_model.dart';
import '../../../../core/widgets/app_cached_image.dart';

class EventGalleryModal extends StatefulWidget {
  final ArtEventModel event;
  final EventPhotoGallery gallery;
  final int initialIndex;

  const EventGalleryModal({
    super.key,
    required this.event,
    required this.gallery,
    this.initialIndex = 0,
  });

  static Future<void> show(
    BuildContext context, {
    required ArtEventModel event,
    required EventPhotoGallery gallery,
    int initialIndex = 0,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder:
          (context) => Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 24.0,
            ),
            backgroundColor: Colors.transparent,
            child: EventGalleryModal(
              event: event,
              gallery: gallery,
              initialIndex: initialIndex,
            ),
          ),
    );
  }

  @override
  State<EventGalleryModal> createState() => _EventGalleryModalState();
}

class _EventGalleryModalState extends State<EventGalleryModal> {
  late PageController _pageController;
  late int _currentIndex;
  late List<GalleryImageItem> _images;

  @override
  void initState() {
    super.initState();
    final validImages = widget.gallery.images.where((img) => img.imageUrl.isNotEmpty).toList();
    if (validImages.isNotEmpty) {
      _images = validImages;
    } else if (widget.gallery.imageUrl.isNotEmpty) {
      _images = [
        GalleryImageItem(
          title: widget.gallery.title,
          imageUrl: widget.gallery.imageUrl,
          caption: widget.gallery.subtitle ?? 'Event photo',
        ),
      ];
    } else {
      _images = [];
    }

    _currentIndex = _images.isNotEmpty ? widget.initialIndex.clamp(0, _images.length - 1) : 0;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPrevious() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onNext() {
    if (_currentIndex < _images.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onDelete() {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Photo'),
            content: const Text(
              'Are you sure you want to delete this photo from the gallery?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() {
                    if (_images.length > 1) {
                      _images.removeAt(_currentIndex);
                      if (_currentIndex >= _images.length) {
                        _currentIndex = _images.length - 1;
                      }
                    } else {
                      Navigator.pop(context);
                    }
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Photo deleted successfully'),
                      backgroundColor: Color(0xFFE53E3E),
                    ),
                  );
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Color(0xFFE53E3E)),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_images.isEmpty) {
      return Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.gallery.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Icon(Icons.photo_library_outlined, size: 48, color: Colors.black26),
            const SizedBox(height: 12),
            const Text(
              'No photos available for this gallery.',
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    }

    final currentImage = _images[_currentIndex];

    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 14.0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Event Gallery: ${widget.event.title}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E1E1E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currentImage.title.isNotEmpty
                            ? currentImage.title
                            : 'Event Image ${_currentIndex + 1}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                // Red Trash Delete Button
                InkWell(
                  onTap: _onDelete,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Close button
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Color(0xFF2E2E2E),
                    size: 22,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Image Carousel with Navigation & Counter
          SizedBox(
            height: 280,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: _images.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final item = _images[index];
                    return AppCachedImage(
                      imageUrl: item.imageUrl,
                      fit: BoxFit.cover,
                    );
                  },
                ),

                // Left Chevron Arrow
                if (_currentIndex > 0)
                  Positioned(
                    left: 12,
                    child: InkWell(
                      onTap: _onPrevious,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.chevron_left,
                          size: 22,
                          color: Color(0xFF1E1E1E),
                        ),
                      ),
                    ),
                  ),

                // Right Chevron Arrow
                if (_currentIndex < _images.length - 1)
                  Positioned(
                    right: 12,
                    child: InkWell(
                      onTap: _onNext,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.chevron_right,
                          size: 22,
                          color: Color(0xFF1E1E1E),
                        ),
                      ),
                    ),
                  ),

                // Counter Badge (e.g. 3 / 3)
                Positioned(
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${_images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Caption / Subtitle Footer
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 14.0,
            ),
            child: Text(
              currentImage.caption,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
