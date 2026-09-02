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
      useSafeArea: false,
      barrierColor: Colors.black,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.black,
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
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    final validImages = widget.gallery.images
        .where((img) => img.imageUrl.isNotEmpty && (img.imageUrl.startsWith('http') || img.imageUrl.startsWith('assets/') || img.imageUrl.startsWith('/')))
        .toList();

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
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onNext() {
    if (_currentIndex < _images.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_images.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.broken_image_outlined, size: 64, color: Colors.white54),
              const SizedBox(height: 16),
              const Text(
                'No images available',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white24,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    }

    final currentImage = _images[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _showControls = !_showControls;
          });
        },
        child: Stack(
          children: [
            // 1. Full-screen Swipeable & Zoomable Image View
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
                return InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: Center(
                    child: AppCachedImage(
                      imageUrl: item.imageUrl,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                );
              },
            ),

            // 2. Top Bar (Close Button, Title & Counter)
            if (_showControls)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.75),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.gallery.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (widget.gallery.subtitle != null && widget.gallery.subtitle!.isNotEmpty)
                                Text(
                                  widget.gallery.subtitle!,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontSize: 12.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        if (_images.length > 1)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_currentIndex + 1} / ${_images.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

            // 3. Desktop / Web Previous Arrow
            if (_showControls && _currentIndex > 0)
              Positioned(
                left: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: InkWell(
                    onTap: _onPrevious,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chevron_left, color: Colors.white, size: 30),
                    ),
                  ),
                ),
              ),

            // 4. Desktop / Web Next Arrow
            if (_showControls && _currentIndex < _images.length - 1)
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: InkWell(
                    onTap: _onNext,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chevron_right, color: Colors.white, size: 30),
                    ),
                  ),
                ),
              ),

            // 5. Bottom Caption / Description
            if (_showControls && currentImage.caption.isNotEmpty && currentImage.caption != 'Event photo' && currentImage.caption != 'Gallery photo')
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Text(
                      currentImage.caption,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
