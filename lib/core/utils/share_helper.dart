import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/api_endpoints.dart';

enum ShareContentType {
  artist,
  event,
  artwork,
  gallery,
  profile,
  general,
}

class ShareHelper {
  ShareHelper._();

  static const String webProductionUrl = 'https://technestpartners.com/api/';

  /// Resolve relative and absolute image URLs safely from MySQL backend
  static String? resolveImageUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;
    var trimmed = rawUrl.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://') || trimmed.startsWith('data:image/')) {
      return trimmed;
    }
    if (trimmed.startsWith('/')) {
      trimmed = trimmed.substring(1);
    }
    final apiBase = ApiEndpoints.baseUrl;
    final serverBase = apiBase.endsWith('/') ? apiBase : '$apiBase/';
    return '$serverBase$trimmed';
  }

  static String getBaseUrl() {
    if (kIsWeb) {
      final origin = Uri.base.origin;
      if (!origin.contains('localhost') && !origin.contains('127.0.0.1')) {
        var path = Uri.base.path;
        if (path.endsWith('index.html')) {
          path = path.substring(0, path.length - 'index.html'.length);
        }
        if (!path.endsWith('/')) {
          path = '$path/';
        }
        return '$origin$path';
      }
    }
    return webProductionUrl;
  }

  static String getArtistShareUrl(String artistId) {
    final base = getBaseUrl();
    return '${base}api.php?resource=share&artist=$artistId';
  }

  static String getEventShareUrl(String eventId) {
    final base = getBaseUrl();
    return '${base}api.php?resource=share&event=$eventId';
  }

  static String getArtworkShareUrl(String artworkId, {String? artistId}) {
    final base = getBaseUrl();
    if (artistId != null && artistId.isNotEmpty) {
      return '${base}api.php?resource=share&artist=$artistId&artwork=$artworkId';
    }
    return '${base}api.php?resource=share&artwork=$artworkId';
  }

  static String getGalleryShareUrl(String galleryId) {
    final base = getBaseUrl();
    return '${base}api.php?resource=share&gallery=$galleryId';
  }

  static String getProfileShareUrl({String? profileId}) {
    final base = getBaseUrl();
    if (profileId != null && profileId.isNotEmpty) {
      return '${base}api.php?resource=share&profile=${Uri.encodeComponent(profileId)}';
    }
    return '${base}api.php?resource=share&profile=me';
  }

  /// Universally safe URL launcher for Web, Android, iOS and Desktop
  static Future<bool> openUrl(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      if (kIsWeb) {
        return await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
          webOnlyWindowName: '_blank',
        );
      } else {
        if (await canLaunchUrl(uri)) {
          return await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
        } else {
          return await launchUrl(
            uri,
            mode: LaunchMode.platformDefault,
          );
        }
      }
    } catch (_) {
      try {
        final uri = Uri.parse(urlString);
        return await launchUrl(uri);
      } catch (_) {
        return false;
      }
    }
  }

  /// Primary share entry point for Artists
  static Future<void> shareArtist({
    required BuildContext context,
    required String artistId,
    required String name,
    String? category,
    String? avatarUrl,
  }) async {
    final shareUrl = getArtistShareUrl(artistId);
    final resolvedImage = resolveImageUrl(avatarUrl);
    final text = 'Discover $name, an inspiring ${category ?? 'artist'} on Artist Dubai: $shareUrl';
    await share(
      context: context,
      title: name.isNotEmpty ? name : 'Artist Dubai',
      subtitle: category ?? 'Artist',
      shareUrl: shareUrl,
      shareText: text,
      imageUrl: resolvedImage,
      contentType: ShareContentType.artist,
    );
  }

  /// Primary share entry point for User & Artist Profiles
  static Future<void> shareProfile({
    required BuildContext context,
    required String name,
    String? artistId,
    String? category,
    String? avatarUrl,
    String? email,
  }) async {
    if (artistId != null && artistId.isNotEmpty) {
      await shareArtist(
        context: context,
        artistId: artistId,
        name: name,
        category: category ?? 'Artist',
        avatarUrl: avatarUrl,
      );
    } else {
      final shareUrl = getProfileShareUrl(profileId: email ?? name);
      final resolvedImage = resolveImageUrl(avatarUrl);
      final text = 'Connect with $name on Artist Dubai - UAE VIP Art & Cultural Community: $shareUrl';
      await share(
        context: context,
        title: name.isNotEmpty ? name : 'Artist Dubai Member',
        subtitle: category ?? 'VIP Community Member',
        shareUrl: shareUrl,
        shareText: text,
        imageUrl: resolvedImage,
        contentType: ShareContentType.profile,
      );
    }
  }

  /// Primary share entry point for Events
  static Future<void> shareEvent({
    required BuildContext context,
    required String eventId,
    required String title,
    String? location,
    String? imageUrl,
    String? dateTime,
  }) async {
    final shareUrl = getEventShareUrl(eventId);
    final resolvedImage = resolveImageUrl(imageUrl);
    final dateSnippet = (dateTime != null && dateTime.trim().isNotEmpty) ? ' on $dateTime' : '';
    final locSnippet = (location != null && location.trim().isNotEmpty) ? ' ($location)' : '';
    final text = 'Join the event "$title"$dateSnippet$locSnippet on Artist Dubai: $shareUrl';
    await share(
      context: context,
      title: title.isNotEmpty ? title : 'Art Event',
      subtitle: location ?? (dateTime ?? 'Dubai, UAE'),
      shareUrl: shareUrl,
      shareText: text,
      imageUrl: resolvedImage,
      contentType: ShareContentType.event,
    );
  }

  /// Primary share entry point for Artworks
  static Future<void> shareArtwork({
    required BuildContext context,
    required String artworkId,
    required String title,
    required String artistName,
    String? artistId,
    String? imageUrl,
  }) async {
    final shareUrl = getArtworkShareUrl(artworkId, artistId: artistId);
    final resolvedImage = resolveImageUrl(imageUrl);
    final text = 'Admire "$title" by $artistName on Artist Dubai: $shareUrl';
    await share(
      context: context,
      title: title.isNotEmpty ? title : 'Artwork',
      subtitle: 'By $artistName',
      shareUrl: shareUrl,
      shareText: text,
      imageUrl: resolvedImage,
      contentType: ShareContentType.artwork,
    );
  }

  /// Primary share entry point for Galleries
  static Future<void> shareGallery({
    required BuildContext context,
    required String galleryId,
    required String title,
    String? location,
    String? imageUrl,
  }) async {
    final shareUrl = getGalleryShareUrl(galleryId);
    final resolvedImage = resolveImageUrl(imageUrl);
    final text = 'Explore "$title" on Artist Dubai: $shareUrl';
    await share(
      context: context,
      title: title.isNotEmpty ? title : 'Art Gallery',
      subtitle: location ?? 'Dubai, UAE',
      shareUrl: shareUrl,
      shareText: text,
      imageUrl: resolvedImage,
      contentType: ShareContentType.gallery,
    );
  }

  /// Universal share router: Opens native share sheet on mobile devices when appropriate,
  /// or displays the Artist Dubai custom modal with direct channel links.
  static Future<void> share({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String shareUrl,
    String? shareText,
    String? imageUrl,
    ShareContentType contentType = ShareContentType.general,
  }) async {
    final effectiveShareText = shareText ?? 'Check out $title on Artist Dubai: $shareUrl';

    // On mobile platforms (Android/iOS), try native OS share sheet first
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
      try {
        final box = context.findRenderObject() as RenderBox?;
        final origin = box != null ? box.localToGlobal(Offset.zero) & box.size : null;
        final result = await SharePlus.instance.share(
          ShareParams(
            text: effectiveShareText,
            subject: title,
            sharePositionOrigin: origin,
          ),
        );
        if (result.status != ShareResultStatus.dismissed) {
          return;
        }
      } catch (_) {
        // Fall back to modal sheet if native share is canceled or errors
      }
    }

    if (context.mounted) {
      await showShareModal(
        context: context,
        title: title,
        subtitle: subtitle,
        shareUrl: shareUrl,
        shareText: effectiveShareText,
        imageUrl: imageUrl,
        contentType: contentType,
      );
    }
  }

  /// Enhanced Artist Dubai Share Modal Bottom Sheet
  static Future<void> showShareModal({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String shareUrl,
    String? shareText,
    String? imageUrl,
    ShareContentType contentType = ShareContentType.general,
  }) async {
    final effectiveShareText = shareText ?? 'Check out $title on Artist Dubai: $shareUrl';
    final resolvedImage = resolveImageUrl(imageUrl);

    String modalTitle;
    switch (contentType) {
      case ShareContentType.artist:
        modalTitle = 'Share Artist Profile';
        break;
      case ShareContentType.profile:
        modalTitle = 'Share Profile';
        break;
      case ShareContentType.event:
        modalTitle = 'Share Event';
        break;
      case ShareContentType.artwork:
        modalTitle = 'Share Artwork';
        break;
      case ShareContentType.gallery:
        modalTitle = 'Share Gallery';
        break;
      case ShareContentType.general:
        modalTitle = 'Share with Friends';
        break;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(ctx).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Grab handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    modalTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey, size: 22),
                    onPressed: () => Navigator.pop(ctx),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Preview Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    if (resolvedImage != null && resolvedImage.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.network(
                          resolvedImage,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildAvatarFallback(title),
                        ),
                      )
                    else
                      _buildAvatarFallback(title),
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
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Copy Link Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link, size: 18, color: Color(0xFF64748B)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        shareUrl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF475569),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: effectiveShareText));
                        Navigator.pop(ctx);
                        if (context.mounted) {
                          _showCopiedFeedback(context, title);
                        }
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B1C9B),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Copy',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Share Channel Options (First Row)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildShareOption(
                    icon: Icons.chat,
                    iconColor: const Color(0xFF25D366),
                    label: 'WhatsApp',
                    onTap: () async {
                      Navigator.pop(ctx);
                      final waUrl = 'https://wa.me/?text=${Uri.encodeComponent(effectiveShareText)}';
                      await openUrl(waUrl);
                    },
                  ),
                  _buildShareOption(
                    icon: Icons.alternate_email,
                    iconColor: const Color(0xFF000000),
                    label: 'X (Twitter)',
                    onTap: () async {
                      Navigator.pop(ctx);
                      final xUrl = 'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(effectiveShareText)}';
                      await openUrl(xUrl);
                    },
                  ),
                  _buildShareOption(
                    icon: Icons.facebook,
                    iconColor: const Color(0xFF1877F2),
                    label: 'Facebook',
                    onTap: () async {
                      Navigator.pop(ctx);
                      final fbUrl = 'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(shareUrl)}';
                      await openUrl(fbUrl);
                    },
                  ),
                  _buildShareOption(
                    icon: Icons.send,
                    iconColor: const Color(0xFF229ED9),
                    label: 'Telegram',
                    onTap: () async {
                      Navigator.pop(ctx);
                      final tgUrl = 'https://t.me/share/url?url=${Uri.encodeComponent(shareUrl)}&text=${Uri.encodeComponent(title)}';
                      await openUrl(tgUrl);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Share Channel Options (Second Row)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildShareOption(
                    icon: Icons.share,
                    iconColor: const Color(0xFF6B1C9B),
                    label: 'More Apps',
                    onTap: () async {
                      Navigator.pop(ctx);
                      try {
                        final box = context.findRenderObject() as RenderBox?;
                        final origin = box != null ? box.localToGlobal(Offset.zero) & box.size : null;
                        await SharePlus.instance.share(
                          ShareParams(
                            text: effectiveShareText,
                            subject: title,
                            sharePositionOrigin: origin,
                          ),
                        );
                      } catch (_) {}
                    },
                  ),
                  _buildShareOption(
                    icon: Icons.business,
                    iconColor: const Color(0xFF0A66C2),
                    label: 'LinkedIn',
                    onTap: () async {
                      Navigator.pop(ctx);
                      final liUrl = 'https://www.linkedin.com/sharing/share-offsite/?url=${Uri.encodeComponent(shareUrl)}';
                      await openUrl(liUrl);
                    },
                  ),
                  _buildShareOption(
                    icon: Icons.email_outlined,
                    iconColor: const Color(0xFFEA4335),
                    label: 'Email',
                    onTap: () async {
                      Navigator.pop(ctx);
                      final emailUrl = 'mailto:?subject=${Uri.encodeComponent('Artist Dubai: $title')}&body=${Uri.encodeComponent('$effectiveShareText\n\n$shareUrl')}';
                      await openUrl(emailUrl);
                    },
                  ),
                  _buildShareOption(
                    icon: Icons.copy,
                    iconColor: const Color(0xFF475569),
                    label: 'Copy Link',
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: effectiveShareText));
                      Navigator.pop(ctx);
                      if (context.mounted) {
                        _showCopiedFeedback(context, title);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildAvatarFallback(String name) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'A';
    return CircleAvatar(
      radius: 24,
      backgroundColor: const Color(0xFF6B1C9B),
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  static Widget _buildShareOption({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _showCopiedFeedback(BuildContext context, String title) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Link to $title copied to clipboard!',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF6B1C9B),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
