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

  /// Plans list
  static const List<ListingPlanItem> plans = <ListingPlanItem>[];

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
    {'id': 'all', 'label': 'All Plans', 'icon': Icons.grid_view_rounded},
    {'id': 'event', 'label': 'Events', 'icon': Icons.event_available_rounded},
    {'id': 'gallery', 'label': 'Galleries', 'icon': Icons.museum_rounded},
    {'id': 'chat', 'label': 'VIP Chat', 'icon': Icons.forum_rounded},
    {'id': 'artist', 'label': 'Artists', 'icon': Icons.palette_rounded},
    {'id': 'art_centre', 'label': 'Art Centres', 'icon': Icons.account_balance_rounded},
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
      List<Map<String, dynamic>> activeList = [];
      if (email != null && email.trim().isNotEmpty) {
        try {
          final plans = await sl<ApiService>().getUserPlans(email: email);
          activeList = plans.where((p) {
            final status = (p['status'] ?? '').toString().toLowerCase();
            final isExpired =
                p['is_expired'] == true ||
                (p['days_left'] != null && (p['days_left'] as num) <= 0);
            return status == 'active' && !isExpired;
          }).toList();
        } catch (_) {}
      }

      // Merge local active plans from StorageService
      for (final type in ['event', 'gallery', 'chat', 'artist', 'art_centre', 'plan']) {
        final local = storage.getString('active_plan_$type');
        if (local != null && local.isNotEmpty) {
          final already = activeList.any((p) =>
              (p['plan_name'] ?? '').toString().toLowerCase() == local.toLowerCase() ||
              (p['item_type'] ?? '').toString().toLowerCase() == type);
          if (!already) {
            activeList.add({
              'plan_name': local,
              'item_type': type,
              'status': 'active',
              'is_expired': false,
            });
          }
        }
      }
      final chatPlan = storage.getString('chat_plan') ?? storage.getString('chat_plan_name');
      if (chatPlan != null && chatPlan.isNotEmpty && !chatPlan.toLowerCase().contains('free')) {
        final already = activeList.any((p) =>
            (p['item_type'] ?? '').toString().toLowerCase() == 'chat' ||
            (p['plan_name'] ?? '').toString().toLowerCase() == chatPlan.toLowerCase());
        if (!already) {
          activeList.add({
            'plan_name': chatPlan,
            'item_type': 'chat',
            'status': 'active',
            'is_expired': false,
          });
        }
      }

      if (mounted) {
        setState(() {
          _userActivePlans = activeList;
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
            'planId': plan.id?.toString() ?? plan.title,
            'planName': plan.title,
            'planPeriod': plan.duration,
            'duration': plan.duration,
            'durationDays': plan.durationDays,
            'duration_days': plan.durationDays,
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF4C1765),
              Color(0xFF5E227A),
              Color(0xFF6A248A),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
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
                      vertical: 18.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header Section
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.22),
                                ),
                              ),
                              child: const Icon(
                                Icons.workspace_premium_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'LISTING PLANS'.trData(context),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    'Official publishing & showcase passes'.trData(context),
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.78),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // User Active Plan Banner (if any active plan exists)
                        if (_userActivePlans.isNotEmpty) ...[
                          _buildUserActivePlanBanner(context),
                          const SizedBox(height: 20),
                        ],

                        // Category Filter Tabs
                        _buildCategoryFilterBar(basePlans),
                        const SizedBox(height: 18),

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
                              borderRadius: BorderRadius.circular(18),
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
                            const SizedBox(height: 18),
                          ],

                        const SizedBox(height: 24),
                      ],
                    ),
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
          final id = cat['id']?.toString() ?? 'all';
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
              borderRadius: BorderRadius.circular(22),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.22),
                    width: 1.2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cat['icon'] as IconData,
                      size: 15,
                      color: isSelected
                          ? const Color(0xFF5E227A)
                          : Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      (cat['label']?.toString() ?? '').trData(context),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected
                            ? const Color(0xFF5E227A)
                            : Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6.5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF5E227A).withValues(alpha: 0.12)
                            : Colors.white.withValues(alpha: 0.22),
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
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E0A2F).withValues(alpha: 0.9),
            const Color(0xFF2E0F45).withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.4),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.08),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF10B981)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded, size: 13, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(
                      'ACTIVE SUBSCRIBER'.trData(context),
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: Text(
                  '${_userActivePlans.length} ${_userActivePlans.length == 1 ? "Plan Active" : "Plans Active"}'
                      .trData(context),
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE2D4F0),
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
                    vertical: 3,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Manage'.trData(context),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.12)),
          const SizedBox(height: 12),
          for (int i = 0; i < _userActivePlans.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: Colors.white.withValues(alpha: 0.12)),
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
    final rawDaysLeft = active['days_left'];
    final int? daysLeftNum = rawDaysLeft != null ? int.tryParse(rawDaysLeft.toString()) : null;
    final expiryDate = active['expires_at'] != null && active['expires_at'].toString().isNotEmpty
        ? active['expires_at'].toString().split(' ').first
        : (active['expiry_date']?.toString().split(' ').first ?? '');
    final durationLabel = active['duration_label']?.toString() ??
        active['duration']?.toString() ??
        active['billing_cycle']?.toString() ??
        '';

    // Format duration string: handle permanent/lifetime plans vs day-based plans
    String displayDuration;
    IconData durationIcon = Icons.timer_outlined;

    if (daysLeftNum != null && daysLeftNum > 0) {
      if (daysLeftNum >= 330) {
        displayDuration = '$daysLeftNum Days Remaining (~1 Year)'.trData(context);
      } else if (daysLeftNum >= 60) {
        final months = (daysLeftNum / 30).round();
        displayDuration = '$daysLeftNum Days Remaining (~$months Mos)'.trData(context);
      } else {
        displayDuration = '$daysLeftNum Days Remaining'.trData(context);
      }
      if (expiryDate.isNotEmpty) {
        displayDuration += ' (until $expiryDate)';
      }
    } else if (daysLeftNum != null && daysLeftNum <= 0) {
      displayDuration = 'Expired'.trData(context);
      durationIcon = Icons.event_busy_outlined;
    } else if (durationLabel.isNotEmpty) {
      displayDuration = durationLabel.trData(context);
      if (durationLabel.toLowerCase().contains('permanent') || durationLabel.toLowerCase().contains('lifetime')) {
        durationIcon = Icons.all_inclusive_rounded;
      }
    } else if (itemType.contains('artist')) {
      displayDuration = 'Permanent Free Profile'.trData(context);
      durationIcon = Icons.all_inclusive_rounded;
    } else if (itemType.contains('gallery') || itemType.contains('centre')) {
      displayDuration = '1 Year (365 Days)'.trData(context);
    } else {
      displayDuration = '30-Day Listing'.trData(context);
    }

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
      typeIcon = Icons.museum_rounded;
      typeLabel = 'Gallery Plan';
      actionLabel = 'Register Gallery';
      onAction = () => context.push(RouteNames.galleryRegistration);
    } else if (itemType == 'chat' ||
        itemType == 'messaging' ||
        planName.toLowerCase().contains('chat')) {
      typeIcon = Icons.forum_rounded;
      typeLabel = 'Chat Plan';
      actionLabel = 'Open Chat';
      onAction = () => context.push(RouteNames.artistChat);
    } else if (itemType == 'artist' ||
        planName.toLowerCase().contains('artist')) {
      typeIcon = Icons.palette_rounded;
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
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(typeIcon, size: 16, color: const Color(0xFF6EE7B7)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                planName.trData(context),
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            if (price.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  price.trData(context),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6EE7B7),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                typeLabel.trData(context),
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFA7F3D0),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              durationIcon,
              size: 13,
              color: const Color(0xFFA7F3D0),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                displayDuration,
                style: const TextStyle(
                  fontSize: 11.5,
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
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4.5,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF059669), Color(0xFF10B981)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        actionLabel.trData(context),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 12,
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
    Color iconColor;
    IconData iconData;
    LinearGradient iconGradient;

    switch (itemType) {
      case 'event':
        iconColor = const Color(0xFF6A2777);
        iconGradient = const LinearGradient(
          colors: [Color(0xFFF5E8FF), Color(0xFFEDE9FE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        iconData = Icons.event_available_rounded;
        break;
      case 'gallery':
        iconColor = const Color(0xFF0284C7);
        iconGradient = const LinearGradient(
          colors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        iconData = Icons.museum_outlined;
        break;
      case 'chat':
      case 'messaging':
        iconColor = const Color(0xFF0F766E);
        iconGradient = const LinearGradient(
          colors: [Color(0xFFCCFBF1), Color(0xFF99F6E4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        iconData = Icons.forum_outlined;
        break;
      case 'artist':
        iconColor = const Color(0xFF6B1C9B);
        iconGradient = const LinearGradient(
          colors: [Color(0xFFF3E8FF), Color(0xFFE9D5FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        iconData = Icons.palette_outlined;
        break;
      case 'art_centre':
        iconColor = const Color(0xFF6366F1);
        iconGradient = const LinearGradient(
          colors: [Color(0xFFEDE9FE), Color(0xFFDDD6FE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        iconData = Icons.account_balance_outlined;
        break;
      default:
        iconColor = const Color(0xFF475569);
        iconGradient = const LinearGradient(
          colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        iconData = Icons.workspace_premium_outlined;
    }

    final isCurrentPlan = _userActivePlans.any((up) {
      final name = up['plan_name']?.toString().toLowerCase().trim() ?? '';
      final itemTitle = up['item_title']?.toString().toLowerCase().trim() ?? '';
      final planTitle = plan.title.toLowerCase().trim();
      final type = up['item_type']?.toString().toLowerCase().trim() ?? '';
      return name == planTitle ||
          itemTitle == planTitle ||
          (name.isNotEmpty && name.contains(planTitle)) ||
          (planTitle.isNotEmpty && name.contains(planTitle)) ||
          (type.isNotEmpty &&
              (type == itemType ||
                  type.contains(itemType) ||
                  itemType.contains(type)));
    });

    VoidCallback? onDirectAction;
    String directActionLabel = '';
    IconData directActionIcon = Icons.arrow_forward_rounded;
    if (itemType == 'event' || plan.title.toLowerCase().contains('event')) {
      directActionLabel = 'Create Event';
      directActionIcon = Icons.add_circle_outline_rounded;
      onDirectAction = () => context.push(RouteNames.createArtEvent);
    } else if (itemType == 'gallery' ||
        plan.title.toLowerCase().contains('gall')) {
      directActionLabel = 'Register Gallery';
      directActionIcon = Icons.add_business_rounded;
      onDirectAction = () => context.push(RouteNames.galleryRegistration);
    } else if (itemType == 'chat' ||
        itemType == 'messaging' ||
        plan.title.toLowerCase().contains('chat')) {
      directActionLabel = 'Open Chat';
      directActionIcon = Icons.forum_rounded;
      onDirectAction = () => context.push(RouteNames.artistChat);
    } else if (itemType == 'artist' ||
        plan.title.toLowerCase().contains('artist')) {
      directActionLabel = 'My Profile';
      directActionIcon = Icons.person_rounded;
      onDirectAction = () => context.push(RouteNames.profile);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isCurrentPlan
            ? Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.55),
                width: 1.6,
              )
            : Border.all(
                color: const Color(0xFFEDE4F3),
                width: 1.0,
              ),
        boxShadow: [
          if (isCurrentPlan) ...[
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.14),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: const Color(0xFF5E227A).withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ] else ...[
            BoxShadow(
              color: const Color(0xFF5E227A).withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
          ],
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active Plan Header Pill
          if (isCurrentPlan) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 14,
                    color: Color(0xFF059669),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'CURRENT ACTIVE PLAN'.trData(context),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF065F46),
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Title & Icon Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: iconGradient,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.18),
                    width: 1,
                  ),
                ),
                child: Icon(
                  iconData,
                  color: iconColor,
                  size: 26,
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
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E1B4B),
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 8,
                      runSpacing: 5,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          plan.category.trData(context),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6A2777),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: plan.isActive
                                ? const Color(0xFFECFDF5)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: plan.isActive
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
                                color: plan.isActive
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
                                  color: plan.isActive
                                      ? const Color(0xFF059669)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (plan.duration.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFBFDBFE),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.schedule_rounded,
                                  size: 11,
                                  color: Color(0xFF1D4ED8),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  plan.duration.trData(context),
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1D4ED8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (plan.badge.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFAF5FF), Color(0xFFF3E8FF)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFE9D5FF),
                              ),
                            ),
                            child: Text(
                              plan.badge.trData(context),
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6A2777),
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (plan.description.isNotEmpty) ...[
                      const SizedBox(height: 7),
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

          // Luxury Hero Pricing Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFAF5FF), Color(0xFFF5F3FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE9D5FF).withValues(alpha: 0.7),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Listing Price'.trData(context),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7E22CE),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      plan.price.trData(context),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E1B4B),
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE9D5FF)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5E227A).withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.bolt_rounded,
                        size: 14,
                        color: Color(0xFFD97706),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Instant Activation'.trData(context),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4C1D95),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Included Features Checklist
          Text(
            'Included Features:'.trData(context),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF334155),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          for (final feat in plan.effectiveFeatures)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFD8B4FE)),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 11,
                      color: Color(0xFF6A2777),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      feat.trData(context),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF334155),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Action Buttons
          if (isCurrentPlan) ...[
            if (onDirectAction != null) ...[
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: onDirectAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: Icon(directActionIcon, size: 16),
                  label: Text(
                    directActionLabel.trData(context),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton.icon(
                onPressed: () => _onPayPressed(context, plan),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF059669),
                  side: const BorderSide(
                    color: Color(0xFFA7F3D0),
                    width: 1.2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: const Color(0xFFECFDF5).withValues(alpha: 0.5),
                ),
                icon: const Icon(Icons.replay_rounded, size: 15),
                label: Text(
                  'Active • Tap to Extend / Renew'.trData(context),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5E227A), Color(0xFF7A2D99)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5E227A).withValues(alpha: 0.24),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => _onPayPressed(context, plan),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: Text(
                  plan.buttonText.trData(context),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
