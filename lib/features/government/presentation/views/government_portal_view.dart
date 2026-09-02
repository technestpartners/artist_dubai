import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/live_sync_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../domain/models/government_entity.dart';

class GovernmentPortalView extends StatefulWidget {
  const GovernmentPortalView({super.key});

  @override
  State<GovernmentPortalView> createState() => _GovernmentPortalViewState();
}
class _GovernmentPortalViewState extends State<GovernmentPortalView> {
  List<GovernmentEntity> _entities = [];
  StreamSubscription<List<GovernmentEntity>>? _govSub;

  @override
  void initState() {
    super.initState();
    _fetchEntities();
    _govSub = sl<LiveSyncService>().governmentStream.listen((entities) {
      if (mounted) {
        setState(() {
          _entities = entities;
        });
      }
    });
  }

  @override
  void dispose() {
    _govSub?.cancel();
    super.dispose();
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
    _showGoogleReviewsModal(context, entity);
  }

  void _showGoogleReviewsModal(BuildContext context, GovernmentEntity entity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _GoogleReviewsSheet(
        entity: entity,
        onReviewAdded: () {
          _fetchEntities();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<GovernmentEntity> entities = _entities;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: const AppTopBar(),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF6A2777),
          onRefresh: _fetchEntities,
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
                Expanded(
                  child: Text(
                    entity.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF64748B),
                    ),
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
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Website',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFF6A2777),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
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
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Directions',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFF6A2777),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
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
        ],
      ),
    );
  }
}

class _GoogleReviewsSheet extends StatefulWidget {
  final GovernmentEntity entity;
  final VoidCallback onReviewAdded;

  const _GoogleReviewsSheet({
    required this.entity,
    required this.onReviewAdded,
  });

  @override
  State<_GoogleReviewsSheet> createState() => _GoogleReviewsSheetState();
}

class _GoogleReviewsSheetState extends State<_GoogleReviewsSheet> {
  late List<ReviewModel> _reviews;
  bool _isLoading = false;
  int _selectedFilterStar = 0; // 0 = all
  final Set<int> _likedReviewIds = {};

  @override
  void initState() {
    super.initState();
    _reviews = widget.entity.reviews;
    _fetchLiveReviews();
  }

  Future<void> _fetchLiveReviews() async {
    setState(() => _isLoading = true);
    try {
      final liveReviews = await sl<ApiService>().getReviews(entityName: widget.entity.name);
      if (mounted && liveReviews.isNotEmpty) {
        setState(() {
          _reviews = liveReviews;
        });
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddReviewModal() {
    double selectedRating = 5.0;
    final loggedInUser = sl<StorageService>().getString('user_name') ?? '';
    final nameCtrl = TextEditingController(text: loggedInUser);
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dCtx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4EEF7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.rate_review_outlined,
                        color: Color(0xFF6A2777),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Write a Review',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            widget.entity.name,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(dCtx),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Star Rating Selector
                const Text(
                  'Your Overall Rating',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starNum = index + 1;
                    return InkWell(
                      onTap: () {
                        setDialogState(() {
                          selectedRating = starNum.toDouble();
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          selectedRating >= starNum ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 36,
                          color: selectedRating >= starNum ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),

                // Name Input
                const Text(
                  'Your Name',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Enter your name',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF6A2777), width: 1.8),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Review Text Input
                const Text(
                  'Review & Feedback',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: commentCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Describe your visit, galleries, atmosphere...',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF6A2777), width: 1.8),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final name = nameCtrl.text.trim().isEmpty ? 'Art Enthusiast' : nameCtrl.text.trim();
                      final text = commentCtrl.text.trim().isEmpty
                          ? 'Wonderful cultural space in Dubai with inspiring exhibitions.'
                          : commentCtrl.text.trim();

                      Navigator.pop(dCtx);

                      final ok = await sl<ApiService>().addReview(
                        entityName: widget.entity.name,
                        authorName: name,
                        rating: selectedRating,
                        text: text,
                      );

                      if (ok) {
                        widget.onReviewAdded();
                        _fetchLiveReviews();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Thank you! Your Google Review has been published.'),
                              backgroundColor: Color(0xFF059669),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A2777),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'Post Review',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedFilterStar == 0
        ? _reviews
        : _reviews.where((r) => r.rating.round() == _selectedFilterStar).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Google "G" Badge
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Center(
                    child: Text(
                      'G',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF4285F4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Google Reviews',
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF4285F4)),
                        ],
                      ),
                      Text(
                        widget.entity.name,
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(color: Color(0xFFF1F5F9), height: 20),

          // Scrollable Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                // Score & Breakdown Summary Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Big Rating
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            widget.entity.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              height: 1.1,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              5,
                              (i) => const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.entity.reviewCount} reviews',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),

                      // Breakdown Bars
                      Expanded(
                        child: Column(
                          children: [
                            _buildBreakdownBar('5', 0.78),
                            _buildBreakdownBar('4', 0.16),
                            _buildBreakdownBar('3', 0.04),
                            _buildBreakdownBar('2', 0.01),
                            _buildBreakdownBar('1', 0.01),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.rate_review_outlined, size: 17),
                        label: const Text(
                          'Write a Review',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A2777),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _showAddReviewModal,
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.open_in_new, size: 15),
                      label: const Text(
                        'Google Maps',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4285F4),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        final url = widget.entity.googleMapsReviewsUrl ?? widget.entity.directionsUrl;
                        final uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Star Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('All (${_reviews.length})', 0),
                      _filterChip('5 Stars ★', 5),
                      _filterChip('4 Stars ★', 4),
                      _filterChip('3 Stars ★', 3),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Reviews List
                if (_isLoading && _reviews.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(color: Color(0xFF6A2777)),
                    ),
                  )
                else if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Text(
                        'No reviews found for this rating.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  )
                else
                  ...filtered.map((r) => _buildReviewItem(r)),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownBar(String star, double percent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        children: [
          Text(
            star,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                minHeight: 5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, int starValue) {
    final isSelected = _selectedFilterStar == starValue;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedFilterStar = starValue),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6A2777) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewItem(ReviewModel r) {
    final rId = r.id ?? r.hashCode;
    final isLiked = _likedReviewIds.contains(rId);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Row
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFE9D5FF),
                backgroundImage: (r.authorPhoto != null && r.authorPhoto!.isNotEmpty)
                    ? CachedNetworkImageProvider(r.authorPhoto!)
                    : null,
                child: r.authorPhoto == null
                    ? Text(
                        r.authorName.isNotEmpty ? r.authorName[0].toUpperCase() : 'A',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6A2777)),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.authorName,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (r.isLocalGuide)
                      Row(
                        children: [
                          const Icon(Icons.stars_rounded, size: 12, color: Color(0xFFEA4335)),
                          const SizedBox(width: 3),
                          const Text(
                            'Local Guide',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              Text(
                r.relativeTime,
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Rating Stars
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                i < r.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 16,
                color: const Color(0xFFF59E0B),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Review Comment Text
          Text(
            r.text,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF334155),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),

          // Helpful / Like Button
          InkWell(
            onTap: () {
              setState(() {
                if (isLiked) {
                  _likedReviewIds.remove(rId);
                } else {
                  _likedReviewIds.add(rId);
                }
              });
            },
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isLiked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
                    size: 14,
                    color: isLiked ? const Color(0xFF6A2777) : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Helpful (${r.likesCount + (isLiked ? 1 : 0)})',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isLiked ? FontWeight.bold : FontWeight.w500,
                      color: isLiked ? const Color(0xFF6A2777) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
