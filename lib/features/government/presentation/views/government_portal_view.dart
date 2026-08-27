import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../domain/models/government_entity.dart';

class GovernmentPortalView extends StatefulWidget {
  const GovernmentPortalView({super.key});

  @override
  State<GovernmentPortalView> createState() => _GovernmentPortalViewState();
}

class _GovernmentPortalViewState extends State<GovernmentPortalView> {
  List<GovernmentEntity> _entities = GovernmentEntity.entities;

  @override
  void initState() {
    super.initState();
    _fetchEntities();
  }

  Future<void> _fetchEntities() async {
    try {
      final entities = await sl<ApiService>().getGovernmentEntities();
      if (mounted) {
        setState(() {
          _entities = entities;
        });
      }
    } catch (_) {}
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        IconData icon;
        if (rating >= starValue) {
          icon = Icons.star;
        } else if (rating >= starValue - 0.5) {
          icon = Icons.star_half;
        } else {
          icon = Icons.star_border;
        }
        return Icon(icon, size: 15, color: const Color(0xFFF59E0B));
      }),
    );
  }

  Future<void> _launchExternalUrl(
    BuildContext context,
    String urlString,
  ) async {
    final uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening $urlString...'),
              backgroundColor: const Color(0xFF6A2777),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening $urlString...'),
            backgroundColor: const Color(0xFF6A2777),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _onWebsiteTap(BuildContext context, GovernmentEntity entity) {
    _launchExternalUrl(context, entity.websiteUrl);
  }

  void _onDirectionsTap(BuildContext context, GovernmentEntity entity) {
    _launchExternalUrl(context, entity.directionsUrl);
  }

  void _onReviewsTap(BuildContext context, GovernmentEntity entity) {
    _launchExternalUrl(
      context,
      entity.googleMapsReviewsUrl ?? entity.directionsUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<GovernmentEntity> entities = _entities;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: const AppTopBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          children: [
            // Page Header
            const Text(
              'Government Portal',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E1E1E),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Partnership opportunities with Dubai's government entities",
              style: TextStyle(
                fontSize: 14.5,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w400,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),

            // Government Entity Cards List
            ...entities.map((entity) => _buildEntityCard(context, entity)),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: -1),
    );
  }

  Widget _buildEntityCard(BuildContext context, GovernmentEntity entity) {
    final isOpen = entity.isCurrentlyOpen;
    final timingText = entity.liveTimingText;

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & Status Badge Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  entity.name,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E1E1E),
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color:
                      isOpen
                          ? const Color(0xFFE8F8F0)
                          : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isOpen ? 'Open' : 'Closed',
                  style: TextStyle(
                    color:
                        isOpen
                            ? const Color(0xFF059669)
                            : const Color(0xFFDC2626),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Rating, Stars, Reviews & Category Row (Tappable to view Google Reviews)
          InkWell(
            onTap: () => _onReviewsTap(context, entity),
            borderRadius: BorderRadius.circular(4),
            child: Row(
              children: [
                Text(
                  entity.rating.toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(width: 5),
                _buildRatingStars(entity.rating),
                const SizedBox(width: 5),
                Text(
                  '(${entity.reviewCount})',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  '·',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    entity.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Location Row (Tappable to view Google Map)
          InkWell(
            onTap: () => _onDirectionsTap(context, entity),
            borderRadius: BorderRadius.circular(4),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 4),
                Text(
                  entity.location,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Timing Status Row
          Text(
            timingText,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: isOpen ? const Color(0xFF059669) : const Color(0xFFDC2626),
            ),
          ),
          const SizedBox(height: 14),

          // Action Buttons (Website & Directions)
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _onWebsiteTap(context, entity),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4EEF7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.language,
                          size: 18,
                          color: Color(0xFF6A2777),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Website',
                          style: TextStyle(
                            color: Color(0xFF6A2777),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => _onDirectionsTap(context, entity),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4EEF7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.near_me_outlined,
                          size: 18,
                          color: Color(0xFF6A2777),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Directions',
                          style: TextStyle(
                            color: Color(0xFF6A2777),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
