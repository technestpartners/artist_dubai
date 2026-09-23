import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/live_sync_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/app_cached_image.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/utils/data_translator.dart';
import '../../../../core/utils/share_helper.dart';
import 'package:artist_dubai/l10n/app_localizations.dart';

class GalleriesView extends StatefulWidget {
  final String? initialGalleryId;
  const GalleriesView({super.key, this.initialGalleryId});

  @override
  State<GalleriesView> createState() => _GalleriesViewState();
}

class _GalleriesViewState extends State<GalleriesView> {
  List<Map<String, dynamic>> _registeredGalleries = [];
  bool _isLoading = true;
  StreamSubscription<List<Map<String, dynamic>>>? _galleriesSub;

  static const Color _screenBg = Color(0xFF6B1C9B);
  static const Color _cardBg = Color(0xFF551478);

  @override
  void initState() {
    super.initState();
    _loadGalleries();
    _galleriesSub = sl<LiveSyncService>().galleriesStream.listen((galleries) {
      if (mounted) {
        setState(() {
          _registeredGalleries = galleries;
        });
      }
    });
    DataTranslator.translationNotifier.addListener(_onTranslationChanged);
  }

  void _onTranslationChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    DataTranslator.translationNotifier.removeListener(_onTranslationChanged);
    _galleriesSub?.cancel();
    super.dispose();
  }

  Future<void> _loadGalleries() async {
    setState(() => _isLoading = true);
    try {
      final list = await sl<ApiService>().getGalleries();
      if (widget.initialGalleryId != null && widget.initialGalleryId!.isNotEmpty) {
        final targetId = widget.initialGalleryId!.trim();
        list.sort((a, b) {
          final aMatch = a['id']?.toString() == targetId;
          final bMatch = b['id']?.toString() == targetId;
          if (aMatch && !bMatch) return -1;
          if (!aMatch && bMatch) return 1;
          return 0;
        });
      }
      if (mounted) {
        setState(() {
          _registeredGalleries = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool get _isLoggedIn {
    try {
      return sl<StorageService>().getBool('is_logged_in') ?? false;
    } catch (_) {
      return false;
    }
  }

  void _handleProtectedAction({
    required VoidCallback onAuthorized,
    required String promptMessage,
  }) {
    if (_isLoggedIn) {
      onAuthorized();
    } else {
      _showLoginPromptDialog(promptMessage);
    }
  }

  void _showLoginPromptDialog(String promptMessage) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.lock_outline, color: Color(0xFF6A2777), size: 24),
            const SizedBox(width: 10),
            Text(AppLocalizations.of(context).loginRequired, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B))),
          ],
        ),
        content: Text(
          promptMessage.trData(context),
          style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(context).cancel, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A2777),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.push(RouteNames.login);
            },
            child: Text(AppLocalizations.of(context).logIn, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    await ShareHelper.openUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rh = ResponsiveHelper.of(context);
    return Scaffold(
      backgroundColor: _screenBg,
      appBar: const AppTopBar(backgroundColor: Colors.white),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: rh.contentMaxWidth),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.fromLTRB(rh.horizontalPadding, 24, rh.horizontalPadding, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Header Title & Subtitle
                    Text(
                      l10n.galleriesArtCenter,
                      style: TextStyle(
                        fontSize: rh.adaptiveFont(24),
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.galleriesSubtitle,
                      style: TextStyle(
                        fontSize: rh.adaptiveFont(14.5),
                        color: Colors.white70,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 18),

                // Action Row (Home Breadcrumb & Register Gallery Button)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () => context.go(RouteNames.home),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.home_outlined,
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l10n.home,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF6B1C9B),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            _handleProtectedAction(
                              onAuthorized: () {
                                context.push(RouteNames.galleryRegistration);
                              },
                              promptMessage: 'Please log in to register an art gallery'.trData(context),
                            );
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add, size: 17, color: Color(0xFF6B1C9B)),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  l10n.galleryRegistration,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF6B1C9B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  )
                else if (_registeredGalleries.isEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.apartment_outlined,
                          size: 46,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No art centers listed yet'.trData(context),
                          style: const TextStyle(
                            fontSize: 17.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Registered galleries and art centers will be shown here.'.trData(context),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Colors.white70,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  Center(
                    child: Text(
                      'Hosted by Nizar Fahem'.trData(context),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ] else ...[
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 600;
                      final crossAxisCount = constraints.maxWidth >= 900 ? 3 : 2;

                      Widget buildGalleryCard(Map<String, dynamic> gallery) {
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
                                            name.trData(context),
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
                                          child: Text(
                                            Localizations.localeOf(context).languageCode == 'ar' ? 'مفتوح' : 'Open',
                                            style: const TextStyle(
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
                                      (category.isNotEmpty ? category : 'Art Space').trData(context),
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
                                            location.trData(context),
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

                                    // Directions and Share Actions
                                    Row(
                                      children: [
                                        Expanded(
                                          child: SizedBox(
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
                                              label: Text(
                                                l10n.directions,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        InkWell(
                                          onTap: () {
                                            ShareHelper.shareGallery(
                                              context: context,
                                              galleryId: gallery['id']?.toString() ?? '',
                                              title: name,
                                              location: location,
                                              imageUrl: imageUrl,
                                            );
                                          },
                                          borderRadius: BorderRadius.circular(12),
                                          child: Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Icon(
                                              Icons.share_outlined,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (isWide) {
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _registeredGalleries.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.78,
                          ),
                          itemBuilder: (context, index) => buildGalleryCard(_registeredGalleries[index]),
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _registeredGalleries.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) => buildGalleryCard(_registeredGalleries[index]),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      l10n.hostedBy,
                      style: const TextStyle(
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
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: -1),
    );
  }
}
