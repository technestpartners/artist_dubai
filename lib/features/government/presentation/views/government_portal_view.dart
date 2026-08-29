import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';
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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchGovernmentEntities();
  }

  Future<void> _fetchGovernmentEntities() async {
    try {
      final apiClient = sl<ApiClient>();
      final response = await apiClient.get(ApiEndpoints.government);
      if (response is Map<String, dynamic> && response['data'] is List) {
        final List list = response['data'];
        final fetched = list.map((json) => GovernmentEntity.fromJson(json)).toList();
        if (fetched.isNotEmpty && mounted) {
          setState(() {
            _entities = fetched;
          });
        }
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
            ..._entities.map((entity) => _buildEntityCard(context, entity)),
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
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  entity.name,
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E1E1E),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 5.0,
                ),
                decoration: BoxDecoration(
                  color:
                      isOpen
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color:
                            isOpen
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFDC2626),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOpen ? 'Open' : 'Closed',
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w700,
                        color:
                            isOpen
                                ? const Color(0xFF15803D)
                                : const Color(0xFFB91C1C),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildRatingStars(entity.rating),
              const SizedBox(width: 6),
              Text(
                '${entity.rating}',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () => _onReviewsTap(context, entity),
                child: Text(
                  '(${entity.reviewCount} reviews)',
                  style: const TextStyle(
                    fontSize: 13.0,
                    color: Color(0xFF64748B),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.category_outlined,
                size: 15,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  entity.category,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 15,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  entity.location,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.access_time_outlined,
                size: 15,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  timingText,
                  style: TextStyle(
                    fontSize: 13.5,
                    color:
                        isOpen
                            ? const Color(0xFF15803D)
                            : const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _onWebsiteTap(context, entity),
                  icon: const Icon(Icons.language, size: 16),
                  label: const Text('Website'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF5E227A),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _onDirectionsTap(context, entity),
                  icon: const Icon(Icons.directions, size: 16),
                  label: const Text('Directions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5E227A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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
