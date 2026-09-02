import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/live_sync_service.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/app_cached_image.dart';

class GalleriesView extends StatefulWidget {
  const GalleriesView({super.key});

  @override
  State<GalleriesView> createState() => _GalleriesViewState();
}

class _GalleriesViewState extends State<GalleriesView> {
  List<Map<String, dynamic>> _registeredGalleries = [];
  StreamSubscription<List<Map<String, dynamic>>>? _galleriesSub;

  static const Color _screenBg = Color(0xFF651B8A);
  static const Color _cardBg = Color(0xFF551478);
  static const Color _bottomBarBg = Color(0xFF531666);

  @override
  void initState() {
    super.initState();
    _fetchGalleries();
    _galleriesSub = sl<LiveSyncService>().galleriesStream.listen((galleries) {
      if (mounted) {
        setState(() {
          _registeredGalleries = galleries.where((g) =>
            g['status'] == 'approved' ||
            g['status'] == 'active' ||
            g['status'] == 'Open' ||
            g['is_approved'] == 1 ||
            (g['is_public'] == 1 && g['status'] != 'pending')
          ).toList();
        });
      }
    });
  }

  @override
  void dispose() {
    _galleriesSub?.cancel();
    super.dispose();
  }

  Future<void> _fetchGalleries() async {
    try {
      final galleries = await sl<ApiService>().getGalleries(status: 'approved');
      if (mounted) {
        setState(() {
          _registeredGalleries = galleries.where((g) =>
            g['status'] == 'approved' ||
            g['status'] == 'active' ||
            g['status'] == 'Open' ||
            g['is_approved'] == 1 ||
            (g['is_public'] == 1 && g['status'] != 'pending')
          ).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _screenBg,
      appBar: const AppTopBar(backgroundColor: Colors.white),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Title & Subtitle
                const Text(
                  'GALLERIES ART CENTER',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Physical galleries and art spaces across Dubai',
                  style: TextStyle(
                    fontSize: 14.5,
                    color: Colors.white70,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Center Announcement Card / Galleries List
                if (_registeredGalleries.isEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.apartment_outlined,
                          size: 46,
                          color: Colors.white,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No art centers listed yet',
                          style: TextStyle(
                            fontSize: 17.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Registered galleries and art centers will be shown here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: Colors.white70,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  const Center(
                    child: Text(
                      'Hosted by Nizar Fahem',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ] else ...[
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _registeredGalleries.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final gallery = _registeredGalleries[index];
                      final name = (gallery['name'] ?? gallery['title'] ?? 'Art Gallery').toString();
                      final category = (gallery['category'] ?? gallery['type'] ?? '').toString();
                      final location = (gallery['location'] ?? gallery['address'] ?? 'Dubai, UAE').toString();
                      final imageUrl = (gallery['image_url'] ?? gallery['image'] ?? '').toString();

                      return Container(
                        decoration: BoxDecoration(
                          color: _cardBg,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (imageUrl.isNotEmpty)
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                                child: AppCachedImage(
                                  imageUrl: imageUrl,
                                  height: 140,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top Row: Title + Open Pill Badge
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.18),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: const Text(
                                          'Open',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),

                                  // Subtitle: Category / Type
                                  Text(
                                    category.isNotEmpty ? category : 'Art Space',
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 10),

                                  // Location Pin & Address
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 16, color: Colors.white70),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          location,
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            color: Colors.white70,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Full-width Directions Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 44,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      onPressed: () => _launchUrl('https://maps.google.com/?q=${Uri.encodeComponent('$name $location')}'),
                                      icon: const Icon(Icons.location_on_outlined, size: 18, color: Colors.white),
                                      label: const Text(
                                        'Directions',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
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
                  const Center(
                    child: Text(
                      'Hosted by Nizar Fahem',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 58,
        color: _bottomBarBg,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home_outlined, color: Colors.white70, size: 24),
              onPressed: () => context.go(RouteNames.home),
            ),
            IconButton(
              icon: const Icon(Icons.people_outline_rounded, color: Colors.white70, size: 24),
              onPressed: () => context.go(RouteNames.artists),
            ),
            IconButton(
              icon: const Icon(Icons.calendar_today_outlined, color: Colors.white70, size: 22),
              onPressed: () => context.go(RouteNames.events),
            ),
          ],
        ),
      ),
    );
  }
}
