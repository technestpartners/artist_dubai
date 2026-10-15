import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/live_sync_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/data_translator.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../domain/models/listing_plan_model.dart';

export '../../domain/models/listing_plan_model.dart';

class ListingPlansView extends StatefulWidget {
  const ListingPlansView({super.key});

  /// Default baseline plans for fallback and offline tests
  static const List<ListingPlanItem> plans =
      ListingPlanItem.defaultBaselinePlans;

  @override
  State<ListingPlansView> createState() => _ListingPlansViewState();
}

class _ListingPlansViewState extends State<ListingPlansView> {
  List<ListingPlanItem> _plans = sl<ApiService>().cachedListingPlans ?? [];
  List<Map<String, dynamic>> _userActivePlans = [];
  bool _isLoading = false;
  String _selectedCategoryFilter = 'all';
  StreamSubscription<List<ListingPlanItem>>? _plansSub;

  final List<Map<String, dynamic>> _filterCategories = const [
    {'id': 'all', 'label': 'All Plans', 'icon': Icons.apps_rounded},
    {'id': 'event', 'label': 'Events', 'icon': Icons.event_available_rounded},
    {'id': 'gallery', 'label': 'Galleries', 'icon': Icons.museum_outlined},
    {'id': 'chat', 'label': 'Chat & Messaging', 'icon': Icons.forum_outlined},
    {'id': 'artist', 'label': 'Artists', 'icon': Icons.palette_outlined},
    {'id': 'art_centre', 'label': 'Art Centres', 'icon': Icons.account_balance_outlined},
  ];

  bool _matchesCategory(ListingPlanItem plan, String filter) {
    if (filter == 'all') return true;
    final itemType = plan.itemType.toLowerCase().trim();
    final cat = plan.category.toLowerCase().trim();
    final title = plan.title.toLowerCase().trim();

    if (filter == 'event') {
      return itemType == 'event' || cat.contains('event') || title.contains('event');
    }
    if (filter == 'gallery') {
      return itemType == 'gallery' || cat.contains('gall') || title.contains('gall');
    }
    if (filter == 'chat') {
      return itemType == 'chat' ||
          itemType == 'messaging' ||
          cat.contains('chat') ||
          cat.contains('messag') ||
          title.contains('chat') ||
          title.contains('messag');
    }
    if (filter == 'artist') {
      return itemType == 'artist' || cat.contains('artist') || cat.contains('portfolio') || title.contains('artist');
    }
    if (filter == 'art_centre') {
      return itemType == 'art_centre' || cat.contains('centre') || cat.contains('center');
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() {
    if (_plans.isEmpty) {
      _isLoading = true;
    }
    // 1. Fetch live listing plans from MySQL via ApiService
    _fetchPlans();

    // 2. Fetch logged-in user's active plans
    _fetchUserActivePlans();

    // 3. Listen for real-time live sync updates from Admin changes
    try {
      final liveSync = sl<LiveSyncService>();
      _plansSub = liveSync.listingPlansStream.listen((updatedList) {
        if (mounted && updatedList.isNotEmpty) {
          setState(() {
            _plans = updatedList;
            _isLoading = false;
          });
        }
      });
    } catch (_) {}
  }

  Future<void> _fetchPlans({bool forceRefresh = false}) async {
    try {
      final list = await sl<ApiService>().getListingPlans(
        forceRefresh: forceRefresh,
      );
      if (mounted) {
        setState(() {
          _plans = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchUserActivePlans() async {
    try {
      final storage = sl<StorageService>();
      final email = storage.getString('user_email');
      if (email == null || email.trim().isEmpty) return;

      final plans = await sl<ApiService>().getUserPlans(email: email);
      if (mounted) {
        setState(() {
          _userActivePlans =
              plans.where((p) {
                final status = (p['status'] ?? '').toString().toLowerCase();
                final isExpired =
                    p['is_expired'] == true ||
                    (p['days_left'] != null && (p['days_left'] as num) <= 0);
                return status == 'active' && !isExpired;
              }).toList();
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _plansSub?.cancel();
    super.dispose();
  }

  void _onPayPressed(BuildContext context, ListingPlanItem plan) {
    // Navigate to plan payment screen with chosen plan details and plan purchase flag
    context
        .push(
          RouteNames.planPayment,
          extra: {
            'isPlanPurchase': true,
            'itemType': plan.itemType,
            'planName': plan.title,
            'planPeriod': plan.badge.isNotEmpty ? plan.badge : '30-Day Listing',
            'planAmount': plan.price,
            'amount': plan.price,
            'features': plan.features,
          },
        )
        .then((_) {
          if (mounted) {
            _fetchPlans(forceRefresh: true);
            _fetchUserActivePlans();
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final rh = ResponsiveHelper.of(context);
    final activePlans = _plans.where((p) => p.isActive).toList();
    final basePlans = activePlans.isNotEmpty ? activePlans : _plans;
    final displayPlans =
        basePlans.where((p) => _matchesCategory(p, _selectedCategoryFilter)).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF5E227A),
      appBar: const AppTopBar(backgroundColor: Colors.white),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF5E227A),
          backgroundColor: Colors.white,
          onRefresh: () async {
            await Future.wait([
              _fetchPlans(forceRefresh: true),
              _fetchUserActivePlans(),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: rh.contentMaxWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: rh.horizontalPadding,
                    vertical: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title & Subtitle
                      Text(
                        'LISTING PLANS'.trData(context),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Purchase plans to publish events, showcase galleries, unlock VIP chat and artist privileges on Artist Dubai.'
                            .trData(context),
                        style: const TextStyle(
                          color: Color(0xFFE2D4F0),
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // User Active Plan Banner (if any active plan exists)
                      if (_userActivePlans.isNotEmpty) ...[
                        _buildUserActivePlanBanner(context),
                        const SizedBox(height: 20),
                      ],

                      // Category Filter Tabs
                      _buildCategoryFilterBar(basePlans),
                      const SizedBox(height: 16),

                      // Plan Cards, Loading or Empty State
                      if (_isLoading && displayPlans.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          ),
                        )
                      else if (displayPlans.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 40,
                            horizontal: 20,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.workspace_premium_outlined,
                                color: Colors.white70,
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No plans found for this category'.trData(context),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Select another tab or view All Plans to see available options.'
                                    .trData(context),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFE2D4F0),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        for (final plan in displayPlans) ...[
                          _buildPlanCard(context, plan),
                          const SizedBox(height: 16),
                        ],

                      const SizedBox(height: 24),

                      // Footer "Hosted by Nizar Fahem"
                      Center(
                        child: Text(
                          'Hosted by Nizar Fahem'.trData(context),
                          style: const TextStyle(
                            color: Color(0xFFD4BEE4),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: -1),
    );
  }

  Widget _buildCategoryFilterBar(List<ListingPlanItem> allPlans) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _filterCategories.map((cat) {
          final id = cat['id'] as String;
          final isSelected = _selectedCategoryFilter == id;
          final count = id == 'all'
              ? allPlans.length
              : allPlans.where((p) => _matchesCategory(p, id)).length;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedCategoryFilter = id;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.25),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cat['icon'] as IconData,
                      size: 15,
                      color: isSelected
                          ? const Color(0xFF5E227A)
                          : Colors.white.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      (cat['label'] as String).trData(context),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFF5E227A)
                            : Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF5E227A).withValues(alpha: 0.12)
                            : Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? const Color(0xFF5E227A)
                              : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUserActivePlanBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF064E3B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF34D399), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified, size: 13, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(
                      'ACTIVE SUBSCRIBER'.trData(context),
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_userActivePlans.length} ${_userActivePlans.length == 1 ? "Plan Active" : "Plans Active"}'
                      .trData(context),
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFA7F3D0),
                  ),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => context.push(RouteNames.settings),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Manage'.trData(context),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFA7F3D0),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right,
                        size: 15,
                        color: Color(0xFFA7F3D0),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFF047857)),
          const SizedBox(height: 10),
          for (int i = 0; i < _userActivePlans.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, color: Color(0xFF047857)),
              ),
            _buildActivePlanRow(context, _userActivePlans[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildActivePlanRow(
    BuildContext context,
    Map<String, dynamic> active,
  ) {
    final planName = active['plan_name']?.toString() ?? 'Active Plan';
    final itemType = (active['item_type'] ?? '').toString().toLowerCase();
    final price = active['price']?.toString() ?? '';
    final daysLeft =
        active['days_left'] != null ? active['days_left'].toString() : '30';
    final expiryDate = active['expiry_date']?.toString().split(' ').first ?? '';

    IconData typeIcon = Icons.workspace_premium_rounded;
    String typeLabel = 'Subscription';
    VoidCallback? onAction;
    String actionLabel = '';

    if (itemType == 'event' || planName.toLowerCase().contains('event')) {
      typeIcon = Icons.event_available_rounded;
      typeLabel = 'Event Plan';
      actionLabel = 'Create Event';
      onAction = () => context.push(RouteNames.createArtEvent);
    } else if (itemType == 'gallery' ||
        planName.toLowerCase().contains('gall')) {
      typeIcon = Icons.museum_outlined;
      typeLabel = 'Gallery Plan';
      actionLabel = 'Register Gallery';
      onAction = () => context.push(RouteNames.galleryRegistration);
    } else if (itemType == 'chat' ||
        itemType == 'messaging' ||
        planName.toLowerCase().contains('chat')) {
      typeIcon = Icons.forum_outlined;
      typeLabel = 'Chat Plan';
      actionLabel = 'Open Chat';
      onAction = () => context.push(RouteNames.artistChat);
    } else if (itemType == 'artist' ||
        planName.toLowerCase().contains('artist')) {
      typeIcon = Icons.palette_outlined;
      typeLabel = 'Artist Membership';
      actionLabel = 'My Profile';
      onAction = () => context.push(RouteNames.profile);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(typeIcon, size: 16, color: const Color(0xFF6EE7B7)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                planName.trData(context),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            if (price.isNotEmpty)
              Text(
                price.trData(context),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6EE7B7),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                typeLabel.trData(context),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFA7F3D0),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.timer_outlined,
              size: 12,
              color: Color(0xFFA7F3D0),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '$daysLeft days remaining'.trData(context) +
                    (expiryDate.isNotEmpty ? ' (until $expiryDate)' : ''),
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFFA7F3D0),
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onAction != null && actionLabel.isNotEmpty) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: onAction,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        actionLabel.trData(context),
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(
                        Icons.arrow_forward,
                        size: 10,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildPlanCard(BuildContext context, ListingPlanItem plan) {
    final String itemType = plan.itemType.toLowerCase().trim();
    Color bgIconColor;
    Color iconColor;
    IconData iconData;

    switch (itemType) {
      case 'event':
        bgIconColor = const Color(0xFFF3E8FF);
        iconColor = const Color(0xFF6A2777);
        iconData = Icons.event_available_rounded;
        break;
      case 'gallery':
        bgIconColor = const Color(0xFFE0F2FE);
        iconColor = const Color(0xFF0284C7);
        iconData = Icons.museum_outlined;
        break;
      case 'chat':
      case 'messaging':
        bgIconColor = const Color(0xFFCCFBF1);
        iconColor = const Color(0xFF0F766E);
        iconData = Icons.forum_outlined;
        break;
      case 'artist':
        bgIconColor = const Color(0xFFFEF3C7);
        iconColor = const Color(0xFFD97706);
        iconData = Icons.palette_outlined;
        break;
      case 'art_centre':
        bgIconColor = const Color(0xFFEDE9FE);
        iconColor = const Color(0xFF6366F1);
        iconData = Icons.account_balance_outlined;
        break;
      default:
        bgIconColor = const Color(0xFFF1F5F9);
        iconColor = const Color(0xFF475569);
        iconData = Icons.star_border_rounded;
    }

    final isCurrentPlan = _userActivePlans.any((up) {
      final name = up['plan_name']?.toString().toLowerCase().trim() ?? '';
      final itemTitle = up['item_title']?.toString().toLowerCase().trim() ?? '';
      final planTitle = plan.title.toLowerCase().trim();
      final type = up['item_type']?.toString().toLowerCase().trim() ?? '';
      return name == planTitle ||
          itemTitle == planTitle ||
          (name.isNotEmpty && name.contains(planTitle)) ||
          (type.isNotEmpty && type == itemType && planTitle.contains(type));
    });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border:
            isCurrentPlan
                ? Border.all(color: const Color(0xFF10B981), width: 2.2)
                : Border.all(color: Colors.transparent, width: 2.2),
        boxShadow: [
          BoxShadow(
            color:
                isCurrentPlan
                    ? const Color(0xFF10B981).withValues(alpha: 0.18)
                    : Colors.black.withValues(alpha: 0.08),
            blurRadius: isCurrentPlan ? 16 : 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // If this is user's current plan, display distinct active indicator
          if (isCurrentPlan) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 14,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'CURRENT ACTIVE PLAN'.trData(context),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF065F46),
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Header: Icon + Title + Category & Badges + Description
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: bgIconColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  iconData,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.title.trData(context),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          plan.category.trData(context),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6A2777),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                plan.isActive
                                    ? const Color(0xFFECFDF5)
                                    : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color:
                                  plan.isActive
                                      ? const Color(0xFFA7F3D0)
                                      : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                plan.isActive
                                    ? Icons.check_circle_rounded
                                    : Icons.visibility_off_outlined,
                                size: 11,
                                color:
                                    plan.isActive
                                        ? const Color(0xFF059669)
                                        : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                (plan.isActive ? 'Active in App' : 'Hidden')
                                    .trData(context),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      plan.isActive
                                          ? const Color(0xFF059669)
                                          : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (plan.badge.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1EBF7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              plan.badge.trData(context),
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF5E227A),
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (plan.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        plan.description.trData(context),
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF64748B),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          // Price & Features Display
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 360;
              final priceBox = Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Listing Price'.trData(context),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      plan.price.trData(context),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              );

              final featuresList = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Included Features:'.trData(context),
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final feat in plan.effectiveFeatures)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.check_circle_rounded,
                              size: 14,
                              color: Color(0xFF6A2777),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              feat.trData(context),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF334155),
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    priceBox,
                    const SizedBox(height: 12),
                    featuresList,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  priceBox,
                  const SizedBox(width: 14),
                  Expanded(child: featuresList),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () => _onPayPressed(context, plan),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isCurrentPlan
                        ? const Color(0xFF059669)
                        : const Color(0xFF6A2777),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              icon: Icon(
                isCurrentPlan
                    ? Icons.replay_rounded
                    : Icons.arrow_forward_rounded,
                size: 16,
              ),
              label: Text(
                isCurrentPlan
                    ? 'Active • Tap to Extend / Renew'.trData(context)
                    : plan.buttonText.trData(context),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
