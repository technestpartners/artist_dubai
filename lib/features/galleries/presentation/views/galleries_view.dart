import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/live_sync_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/app_cached_image.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';

class GalleriesView extends StatefulWidget {
  const GalleriesView({super.key});

  @override
  State<GalleriesView> createState() => _GalleriesViewState();
}

class _GalleriesViewState extends State<GalleriesView> {
  List<Map<String, dynamic>> _registeredGalleries = [];
  StreamSubscription<List<Map<String, dynamic>>>? _galleriesSub;
  StreamSubscription<bool>? _authSub;

  static const Color _screenBg = Color(0xFF651B8A);
  static const Color _cardBg = Color(0xFF551478);

  bool get _isLoggedIn {
    try {
      return sl<StorageService>().getBool('is_logged_in') ?? false;
    } catch (_) {
      return false;
    }
  }

  void _updateGalleriesList(List<Map<String, dynamic>> galleries) {
    if (!mounted) return;
    setState(() {
      _registeredGalleries = galleries.where((g) {
        final status = (g['status'] ?? '').toString().trim().toLowerCase();
        if (status == 'pending' || status == 'rejected') return false;
        final isPublic = g['is_public'];
        if (isPublic == 0 || isPublic == '0' || isPublic == false || isPublic == 'false') return false;
        return true;
      }).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchGalleries();
    _authSub = sl<LiveSyncService>().authStream.listen((isLoggedIn) {
      if (mounted) {
        setState(() {});
        if (isLoggedIn) {
          _fetchGalleries();
        }
      }
    });
    _galleriesSub = sl<LiveSyncService>().galleriesStream.listen((galleries) {
      _updateGalleriesList(galleries);
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _galleriesSub?.cancel();
    super.dispose();
  }

  Future<void> _fetchGalleries() async {
    try {
      final galleries = await sl<ApiService>().getGalleries();
      _updateGalleriesList(galleries);
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

                if (!_isLoggedIn) ...[
                  _buildAuthGate(context),
                ] else ...[
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
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: -1),
    );
  }

  Widget _buildAuthGate(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8, bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFF651B8A).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.museum_outlined,
                size: 34,
                color: Color(0xFF651B8A),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Explore Dubai Galleries',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Log in or sign up with your email to discover physical art spaces, galleries, and exhibition hubs across Dubai.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF651B8A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                final loggedIn = await context.push(RouteNames.register, extra: 'user');
                if (loggedIn == true || _isLoggedIn) {
                  if (mounted) setState(() {});
                }
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add_outlined, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Sign Up as Art Lover (Free Access)',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF651B8A),
                side: const BorderSide(color: Color(0xFF651B8A), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                final loggedIn = await context.push(RouteNames.login);
                if (loggedIn == true || _isLoggedIn) {
                  if (mounted) setState(() {});
                }
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login_rounded, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Already have an account? Sign In',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_outline_rounded, size: 16, color: Color(0xFF94A3B8)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Access is free. Simply sign in so we can provide you with gallery opening and exhibition updates.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
