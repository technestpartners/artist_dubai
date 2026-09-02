import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/storage_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/services/live_sync_service.dart';
import '../../../../core/widgets/app_cached_image.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../bookings/presentation/views/book_artist_view.dart';
import '../../domain/models/artist_model.dart';

class ArtistDetailView extends StatefulWidget {
  final ArtistModel? artist;
  final bool? initialIsFavorited;

  const ArtistDetailView({
    super.key,
    this.artist,
    this.initialIsFavorited,
  });

  @override
  State<ArtistDetailView> createState() => _ArtistDetailViewState();
}

class _ArtistDetailViewState extends State<ArtistDetailView> {
  bool _isFollowing = false;
  bool _isGridView =
      true; // Toggle between Grid (2-column) and List (1-column horizontal)
  bool _isArtistFavorited = false;
  final Set<int> _favoritedArtworks = {};
  List<Map<String, dynamic>> _artworksList = [];

  late int _likesCount;
  late int _followersCount;
  late int _worksCount;
  StreamSubscription<List<ArtistModel>>? _artistLiveSub;
  StreamSubscription<Map<String, dynamic>>? _favLiveSub;
  DateTime? _lastUserFavoriteActionTime;
  DateTime? _lastUserFollowActionTime;

  List<Map<String, dynamic>> _photoGalleries = [];

  @override
  void initState() {
    super.initState();
    final artist = widget.artist;
    _isArtistFavorited = widget.initialIsFavorited ?? false;
    _likesCount = artist?.likesCount ?? 0;
    _followersCount = artist?.followersCount ?? 0;
    _worksCount = artist?.worksCount ?? 0;
    if (_isArtistFavorited && _likesCount == 0) _likesCount = 1;
    _loadAllData();

    _artistLiveSub = sl<LiveSyncService>().artistsStream.listen((artists) {
      if (mounted && widget.artist != null) {
        final match = artists.where((a) => a.id == widget.artist!.id).firstOrNull;
        if (match != null) {
          setState(() {
            _likesCount = match.likesCount;
            if (_isArtistFavorited && _likesCount == 0) _likesCount = 1;
            if (_lastUserFollowActionTime == null || DateTime.now().difference(_lastUserFollowActionTime!).inSeconds >= 3) {
              _followersCount = match.followersCount;
            }
            if (_isFollowing && _followersCount == 0) _followersCount = 1;
            if (match.worksCount > 0 || _artworksList.isEmpty) {
              _worksCount = match.worksCount;
            }
          });
        }
      }
    });

    _favLiveSub = sl<LiveSyncService>().favoritesStream.listen((favData) {
      if (mounted && widget.artist != null) {
        if (_lastUserFavoriteActionTime != null && DateTime.now().difference(_lastUserFavoriteActionTime!).inSeconds < 3) {
          return;
        }
        final favArtists = (favData['artists'] as List<ArtistModel>?) ?? [];
        final isFav = favArtists.any((a) => a.id == widget.artist!.id);
        setState(() {
          _isArtistFavorited = isFav;
          if (_isArtistFavorited && _likesCount == 0) _likesCount = 1;
        });
      }
    });
  }

  @override
  void dispose() {
    _artistLiveSub?.cancel();
    _favLiveSub?.cancel();
    super.dispose();
  }

  String _getEffectiveEmail() {
    try {
      String? email = sl<StorageService>().getString('user_email');
      if (email != null && email.isNotEmpty) return email;
      email = sl<StorageService>().getString('device_guest_id');
      if (email != null && email.isNotEmpty) return email;
      final newId = 'guest_${DateTime.now().millisecondsSinceEpoch}@artistdubai.com';
      sl<StorageService>().setString('device_guest_id', newId);
      return newId;
    } catch (_) {
      return 'user@artistdubai.com';
    }
  }

  Future<void> _loadAllData() async {
    final artist = widget.artist;
    final userEmail = _getEffectiveEmail();
    try {
      final results = await Future.wait([
        sl<ApiService>().getGalleries(
          artistId: artist?.id,
          artistName: artist?.name,
        ),
        sl<ApiService>().getArtworks(
          artistId: artist?.id,
          artistName: artist?.name,
        ),
        if (artist != null)
          sl<ApiService>().getArtistInteractionStatus(
            artistId: artist.id,
            userEmail: userEmail,
          )
        else
          Future.value(null),
        sl<ApiService>().getFavorites(email: userEmail),
      ]);

      final rawGalleries = results[0] as List<Map<String, dynamic>>? ?? [];
      final artworks = results[1] as List<Map<String, dynamic>>? ?? [];
      final status = results[2] as Map<String, dynamic>?;
      final favData = results[3] as Map<String, dynamic>? ?? {};
      final favArtists = (favData['artists'] as List<ArtistModel>?) ?? [];
      final isFavInBackend = artist != null && favArtists.any((a) => a.id == artist.id);

      // Filter out physical art centers that don't belong to this artist
      final galleries = rawGalleries.where((g) {
        final artistId = (g['artist_id'] ?? '').toString();
        final artistName = (g['artist_name'] ?? '').toString();
        final currentArtistId = artist?.id ?? '';
        final currentArtistName = artist?.name ?? '';
        final matchesArtist = (currentArtistId.isNotEmpty && artistId == currentArtistId) ||
            (currentArtistName.isNotEmpty && artistName.toLowerCase() == currentArtistName.toLowerCase());
        return matchesArtist;
      }).toList();

      if (mounted) {
        setState(() {
          _photoGalleries = galleries;
          if (artworks.isNotEmpty) {
            _artworksList = artworks;
            _worksCount = artworks.length;
          }
          if (status != null) {
            _isArtistFavorited = status['is_liked'] == true;
            _isFollowing = status['is_following'] == true;
            if (status['likes_count'] != null) {
              _likesCount = (status['likes_count'] as num).toInt();
            }
            if (_isArtistFavorited && _likesCount == 0) {
              _likesCount = 1;
            }
            if (status['followers_count'] != null) {
              _followersCount = (status['followers_count'] as num).toInt();
            }
            if (_isFollowing && _followersCount == 0) {
              _followersCount = 1;
            }
            if (status['works_count'] != null && _artworksList.isEmpty) {
              _worksCount = (status['works_count'] as num).toInt();
            }
          } else {
            _isArtistFavorited = isFavInBackend;
            if (_isArtistFavorited && _likesCount == 0) {
              _likesCount = 1;
            }
          }
        });
      }
    } catch (_) {}
  }

  void _shareArtist() {
    final artist = widget.artist;
    final name = artist?.name ?? 'Artist';
    final id = artist?.id ?? '';
    Clipboard.setData(
      ClipboardData(
        text: 'Check out $name on Artist Dubai: https://artistdubai.com/artists/$id',
      ),
    );
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Link to $name copied to clipboard!',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleArtistFavorite() async {
    final artist = widget.artist;
    if (artist == null) return;
    final userEmail = _getEffectiveEmail();
    final wasFav = _isArtistFavorited;
    _lastUserFavoriteActionTime = DateTime.now();

    setState(() {
      _isArtistFavorited = !wasFav;
      if (!wasFav) {
        _likesCount += 1;
      } else {
        if (_likesCount > 0) _likesCount -= 1;
      }
    });

    final res = await sl<ApiService>().likeArtist(
      artistId: artist.id,
      userEmail: userEmail,
      action: wasFav ? 'unlike' : 'like',
    );
    if (res != null && mounted) {
      setState(() {
        if (res['likes_count'] != null) {
          _likesCount = (res['likes_count'] as num).toInt();
        }
        if (res['is_liked'] != null) {
          _isArtistFavorited = res['is_liked'] == true;
        }
        if (_isArtistFavorited && _likesCount == 0) {
          _likesCount = 1;
        }
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasFav
                ? 'Unliked ${artist.name}\'s profile'
                : 'Liked ${artist.name}\'s profile ❤️',
          ),
          backgroundColor: wasFav ? const Color(0xFF475569) : const Color(0xFFE11D48),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _toggleFollowArtist() async {
    final artist = widget.artist;
    if (artist == null) return;
    final userEmail = _getEffectiveEmail();
    final wasFollowing = _isFollowing;
    _lastUserFollowActionTime = DateTime.now();

    setState(() {
      _isFollowing = !wasFollowing;
      if (!wasFollowing) {
        _followersCount += 1;
      } else {
        if (_followersCount > 0) _followersCount -= 1;
      }
    });

    final res = await sl<ApiService>().followArtist(
      artistId: artist.id,
      userEmail: userEmail,
      action: wasFollowing ? 'unfollow' : 'follow',
    );
    if (res != null && mounted) {
      setState(() {
        if (res['followers_count'] != null) {
          _followersCount = (res['followers_count'] as num).toInt();
        }
        if (res['is_following'] != null) {
          _isFollowing = res['is_following'] == true;
        }
        if (_isFollowing && _followersCount == 0) {
          _followersCount = 1;
        }
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasFollowing
                ? 'Unfollowed ${artist.name}'
                : 'Now following ${artist.name} 🎉',
          ),
          backgroundColor: wasFollowing ? const Color(0xFF475569) : const Color(0xFF6A2777),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _toggleArtworkFavorite(int itemId) async {
    final userEmail = sl<StorageService>().getString('user_email') ?? '';
    final wasFav = _favoritedArtworks.contains(itemId);
    setState(() {
      if (wasFav) {
        _favoritedArtworks.remove(itemId);
      } else {
        _favoritedArtworks.add(itemId);
      }
    });

    if (userEmail.isNotEmpty) {
      await sl<ApiService>().toggleFavorite(
        email: userEmail,
        itemType: 'artwork',
        itemId: itemId.toString(),
      );
    }
  }

  void _showArtworkDetailModal(Map<String, dynamic> item, int itemId) {
    final title = (item['title'] ?? 'Artwork').toString();
    final year = (item['year'] ?? '').toString();
    final medium = (item['medium'] ?? '').toString();
    final dimensions = (item['dimensions'] ?? '').toString();
    final description = (item['description'] ?? '').toString();
    final imageUrl = (item['image_url'] ?? item['image'] ?? '').toString();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isFav = _favoritedArtworks.contains(itemId);
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: AppCachedImage(
                            imageUrl: imageUrl,
                            height: 240,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: CircleAvatar(
                            backgroundColor: Colors.black.withValues(alpha: 0.6),
                            radius: 16,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white, size: 16),
                              onPressed: () => Navigator.pop(context),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18.0),
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
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E1E1E),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  isFav ? Icons.favorite : Icons.favorite_border,
                                  color: isFav ? const Color(0xFFE11D48) : const Color(0xFF64748B),
                                ),
                                onPressed: () {
                                  _toggleArtworkFavorite(itemId);
                                  setModalState(() {});
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$year • $medium • $dimensions',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            description,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFF475569),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCreateGalleryModal(String artistName) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
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
                      // Title Header with Close Button
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
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        cursorColor: const Color(0xFF6A2777),
                        decoration: InputDecoration(
                          hintText: 'Enter gallery title...',
                          hintStyle: const TextStyle(
                            color: Color(0xFF94A3B8),
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
                              color: Color(0xFFCBD5E1),
                              width: 1.0,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF6A2777),
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
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        cursorColor: const Color(0xFF6A2777),
                        decoration: InputDecoration(
                          hintText: 'Describe this gallery...',
                          hintStyle: const TextStyle(
                            color: Color(0xFF94A3B8),
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
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF6A2777),
                              width: 1.5,
                            ),
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
                        onTap: isUploading ? null : pickImages,
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
                            children: [
                              const Icon(
                                Icons.upload_outlined,
                                size: 36,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                modalImages.isEmpty
                                    ? 'Click to select images or drag and drop'
                                    : '${modalImages.length} image(s) selected (tap to add more)',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: modalImages.isNotEmpty
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: modalImages.isNotEmpty
                                      ? const Color(0xFF6A2777)
                                      : const Color(0xFF64748B),
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
                                      child: InkWell(
                                        onTap: isUploading
                                            ? null
                                            : () {
                                                setModalState(() {
                                                  modalImages.removeAt(idx);
                                                });
                                              },
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.6),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            size: 14,
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
                      const SizedBox(height: 24),

                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
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
                                onPressed: isUploading ? null : () => Navigator.pop(context),
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
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
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
                                onPressed: isUploading
                                    ? null
                                    : () async {
                                        final title = titleController.text.trim();
                                        final desc = descController.text.trim();
                                        if (title.isEmpty) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Please enter a gallery title')),
                                          );
                                          return;
                                        }

                                        setModalState(() {
                                          isUploading = true;
                                        });

                                        final artist = widget.artist;
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
                                                content: Text('Please select at least one photo from your device.'),
                                                backgroundColor: Color(0xFFDC2626),
                                              ),
                                            );
                                          }
                                          return;
                                        }

                                        final coverUrl = finalUploadedUrls.first;

                                        final created = await sl<ApiService>().createGallery(
                                          title: title,
                                          description: desc.isNotEmpty ? desc : 'Curated collection by Artist',
                                          artistId: artist?.id,
                                          artistName: artist?.name,
                                          imageUrl: coverUrl,
                                          images: finalUploadedUrls,
                                        );

                                        if (context.mounted) {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Gallery "$title" saved to database!'),
                                              backgroundColor: const Color(0xFF6A2777),
                                              duration: const Duration(seconds: 2),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }

                                        if (mounted) {
                                          final newGalleryItem = created ?? {
                                            'title': title,
                                            'name': title,
                                            'description': desc,
                                            'image_url': coverUrl,
                                            'image': coverUrl,
                                            'images': finalUploadedUrls,
                                            'photo_count': finalUploadedUrls.length,
                                            'artist_id': artist?.id,
                                            'artist_name': artist?.name,
                                            'category': 'Artist gallery',
                                          };
                                          setState(() {
                                            _photoGalleries.insert(0, newGalleryItem);
                                          });
                                        }
                                      },
                                child: isUploading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Create Gallery',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
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
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentArtist =
        widget.artist ??
        const ArtistModel(
          id: '0',
          name: 'Artist',
          category: 'Artist',
          bio: '',
          location: 'Dubai, UAE',
          avatarUrl: '',
          bannerUrl: '',
          worksCount: 0,
          followersCount: 0,
        );

    final List<Map<String, dynamic>> displayedArtworks = _artworksList;

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
                        context.pop(_isArtistFavorited);
                      } else {
                        context.go(RouteNames.home);
                      }
                    },
                  ),
                  const Expanded(
                    child: Text(
                      'Artist Profile',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E1E1E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _shareArtist,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
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
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _toggleArtistFavorite,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _isArtistFavorited
                              ? const Color(0xFFE11D48).withValues(alpha: 0.1)
                              : Colors.transparent,
                          border: Border.all(
                            color: _isArtistFavorited
                                ? const Color(0xFFE11D48)
                                : const Color(0xFFCBD5E1),
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          _isArtistFavorited
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 18,
                          color: _isArtistFavorited
                              ? const Color(0xFFE11D48)
                              : const Color(0xFF1E1E1E),
                        ),
                      ),
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
                            backgroundImage: currentArtist.avatarUrl.isNotEmpty
                                ? CachedNetworkImageProvider(
                                    currentArtist.avatarUrl,
                                  )
                                : null,
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
                              Flexible(
                                child: Text(
                                  currentArtist.location,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    color: Color(0xFF64748B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Stats Row (Artworks | Likes | Followers)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatItem('$_worksCount', 'Artworks'),
                              Container(
                                height: 24,
                                width: 1,
                                color: const Color(0xFFE2E8F0),
                              ),
                              _buildStatItem('$_likesCount', 'Likes'),
                              Container(
                                height: 24,
                                width: 1,
                                color: const Color(0xFFE2E8F0),
                              ),
                              _buildStatItem('$_followersCount', 'Followers'),
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
                              _buildTagChip(currentArtist.experienceLevel.isNotEmpty ? currentArtist.experienceLevel : 'Verified Artist'),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Verified Badge & Location
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: const [
                              Icon(
                                Icons.verified_user_outlined,
                                size: 15,
                                color: Color(0xFF6A2777),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Verified Artist • Dubai, UAE',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6A2777),
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
                                      backgroundColor: _isFollowing
                                          ? const Color(0xFF6A2777).withValues(alpha: 0.08)
                                          : Colors.transparent,
                                      side: BorderSide(
                                        color: _isFollowing
                                            ? const Color(0xFF6A2777)
                                            : const Color(0xFF333333),
                                        width: _isFollowing ? 1.4 : 1.0,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: _toggleFollowArtist,
                                    icon: Icon(
                                      _isFollowing
                                          ? Icons.check
                                          : Icons.person_add_outlined,
                                      size: 16,
                                      color: _isFollowing
                                          ? const Color(0xFF6A2777)
                                          : const Color(0xFF1E1E1E),
                                    ),
                                    label: Text(
                                      _isFollowing ? 'Following' : 'Follow',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: _isFollowing
                                            ? const Color(0xFF6A2777)
                                            : const Color(0xFF1E1E1E),
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

                    // 3. Portfolio Section with View Mode Switcher
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        const SizedBox(height: 4),
                        Text(
                          'Explore ${currentArtist.name}\'s collection of artworks',
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Portfolio Artworks Content (Grid vs List)
                    if (_isGridView)
                      _buildArtworksGrid(displayedArtworks)
                    else
                      _buildArtworksList(displayedArtworks),
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
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
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
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 1),
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

  // 2-Column Grid View of Artworks
  Widget _buildArtworksGrid(List<Map<String, dynamic>> artworks) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: artworks.length,
      itemBuilder: (context, index) {
        final item = artworks[index];
        final itemId = (item['id'] is int)
            ? item['id'] as int
            : int.tryParse(item['id']?.toString() ?? '') ?? (index + 1);
        final isFav = _favoritedArtworks.contains(itemId);
        final isFeatured = item['is_featured'] == 1 || item['is_featured'] == true || index == 0;
        final imageUrl = (item['image_url'] ?? item['image'] ?? '').toString();
        final title = (item['title'] ?? 'Artwork ${index + 1}').toString();
        final year = (item['year'] ?? '2024').toString();
        final medium = (item['medium'] ?? 'Mixed Media').toString();
        final dimensions = (item['dimensions'] ?? '').toString();

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showArtworkDetailModal(item, itemId),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image with Featured & Price Badges (Expanded to fill available height perfectly)
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(11),
                        ),
                        child: AppCachedImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      if (isFeatured)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6A2777),
                              borderRadius: BorderRadius.circular(5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
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
                ),

                // Details Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () => _toggleArtworkFavorite(itemId),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                size: 18,
                                color: isFav ? const Color(0xFFE11D48) : const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$year • $medium',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (dimensions.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          dimensions,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 1-Column Horizontal List View of Artworks
  Widget _buildArtworksList(List<Map<String, dynamic>> artworks) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: artworks.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = artworks[index];
        final itemId = (item['id'] is int)
            ? item['id'] as int
            : int.tryParse(item['id']?.toString() ?? '') ?? (index + 1);
        final isFav = _favoritedArtworks.contains(itemId);
        final imageUrl = (item['image_url'] ?? item['image'] ?? '').toString();
        final title = (item['title'] ?? 'Artwork ${index + 1}').toString();
        final year = (item['year'] ?? '2024').toString();
        final medium = (item['medium'] ?? 'Mixed Media').toString();
        final dimensions = (item['dimensions'] ?? '').toString();

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showArtworkDetailModal(item, itemId),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: AppCachedImage(
                    imageUrl: imageUrl,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$year • $medium',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      if (dimensions.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          dimensions,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => _toggleArtworkFavorite(itemId),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      size: 18,
                      color: isFav ? const Color(0xFFE11D48) : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int _computeFallbackIndex(String title, int seedOffset) {
    int hash = 0;
    for (int i = 0; i < title.length; i++) {
      hash = (hash * 31 + title.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return (hash + seedOffset) & 0x7FFFFFFF;
  }

  Widget _buildGalleryPhotoItem(
    String imgUrl, {
    BoxFit fit = BoxFit.contain,
    double? width,
    double? height,
    int fallbackIndex = 0,
  }) {
    final Widget errorPlaceholder = Container(
      width: width,
      height: height,
      color: const Color(0xFFF3F4F6),
      child: const Center(
        child: Icon(Icons.broken_image_outlined, color: Color(0xFF9CA3AF), size: 24),
      ),
    );

    if (imgUrl.startsWith('http://') ||
        imgUrl.startsWith('https://')) {
      return AppCachedImage(
        imageUrl: imgUrl,
        fit: fit,
        width: width,
        height: height,
        errorWidget: errorPlaceholder,
      );
    } else if (imgUrl.startsWith('blob:') || imgUrl.startsWith('data:image')) {
      return Image.network(
        imgUrl,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) => errorPlaceholder,
      );
    } else if (!kIsWeb && imgUrl.isNotEmpty) {
      try {
        final file = File(imgUrl);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: fit,
            width: width,
            height: height,
            errorBuilder: (context, error, stackTrace) => errorPlaceholder,
          );
        }
      } catch (_) {}
    }

    return errorPlaceholder;
  }

  Widget _buildGalleryCard(Map<String, dynamic> gallery) {
    final image = (gallery['image'] ?? gallery['image_url'] ?? '').toString();
    final title = (gallery['title'] ?? gallery['name'] ?? 'Photo Gallery').toString();
    final subtitle = (gallery['subtitle'] ?? gallery['description'] ?? '').toString();
    final count = (gallery['count'] ?? (gallery['photo_count'] != null ? '${gallery['photo_count']} photos' : '1 photos')).toString();
    final cardFallbackIdx = _computeFallbackIndex(title, 0);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _showPhotoGalleryModal(gallery),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(11),
                  ),
                  child: _buildGalleryPhotoItem(
                    image,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 140,
                    fallbackIndex: cardFallbackIdx,
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
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.photo_library_outlined,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          count,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPhotoGalleryModal(Map<String, dynamic> gallery) {
    final title = (gallery['title'] ?? gallery['name'] ?? 'Photo Gallery').toString();
    final subtitle = (gallery['subtitle'] ?? gallery['description'] ?? '').toString();
    final mainImage = (gallery['image'] ?? gallery['image_url'] ?? '').toString();

    // Extract images
    final List<String> images = [];
    if (gallery['images'] is List) {
      for (final img in gallery['images']) {
        if (img is String && img.isNotEmpty) {
          images.add(img);
        } else if (img is Map && img['image_url'] != null && img['image_url'].toString().isNotEmpty) {
          images.add(img['image_url'].toString());
        }
      }
    } else if (gallery['images_json'] != null) {
      try {
        final decoded = jsonDecode(gallery['images_json'].toString());
        if (decoded is List) {
          for (final img in decoded) {
            if (img is String && img.isNotEmpty) {
              images.add(img);
            } else if (img is Map && img['image_url'] != null && img['image_url'].toString().isNotEmpty) {
              images.add(img['image_url'].toString());
            }
          }
        }
      } catch (_) {}
    }

    if (images.isEmpty && mainImage.isNotEmpty) {
      images.add(mainImage);
    }

    int activeIdx = 0;
    final pageController = PageController();

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 550, maxHeight: 720),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 12, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Photo ${activeIdx + 1} of ${images.length} • ${widget.artist?.name ?? 'Artist'}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 22),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1, color: Color(0xFF334155)),

                    // Main Image Swiper with Arrows
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PageView.builder(
                            controller: pageController,
                            itemCount: images.length,
                            onPageChanged: (idx) {
                              setModalState(() {
                                activeIdx = idx;
                              });
                            },
                            itemBuilder: (context, index) {
                              final imgUrl = images[index];
                              return InteractiveViewer(
                                minScale: 0.8,
                                maxScale: 3.0,
                                child: Center(
                                  child: _buildGalleryPhotoItem(
                                    imgUrl,
                                    fit: BoxFit.contain,
                                    fallbackIndex: _computeFallbackIndex(title, index),
                                  ),
                                ),
                              );
                            },
                          ),

                          // Left navigation arrow
                          if (activeIdx > 0)
                            Positioned(
                              left: 8,
                              child: InkWell(
                                onTap: () {
                                  pageController.previousPage(
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.white),
                                ),
                              ),
                            ),

                          // Right navigation arrow
                          if (activeIdx < images.length - 1)
                            Positioned(
                              right: 8,
                              child: InkWell(
                                onTap: () {
                                  pageController.nextPage(
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Description / Subtitle
                    if (subtitle.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                        child: Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                      ),

                    // Bottom Thumbnails Strip
                    if (images.length > 1)
                      Container(
                        height: 64,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        child: Center(
                          child: ListView.separated(
                            shrinkWrap: true,
                            scrollDirection: Axis.horizontal,
                            itemCount: images.length,
                            separatorBuilder: (context, idx) => const SizedBox(width: 8),
                            itemBuilder: (context, idx) {
                              final isCurrent = idx == activeIdx;
                              return InkWell(
                                onTap: () {
                                  pageController.animateToPage(
                                    idx,
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isCurrent ? const Color(0xFF6A2777) : Colors.transparent,
                                      width: 2.0,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: _buildGalleryPhotoItem(
                                      images[idx],
                                      fit: BoxFit.cover,
                                      width: 48,
                                      height: 48,
                                      fallbackIndex: _computeFallbackIndex(title, idx),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
