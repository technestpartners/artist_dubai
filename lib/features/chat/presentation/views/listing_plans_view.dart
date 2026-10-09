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
  static const List<ListingPlanItem> plans = [];

  @override
  State<ListingPlansView> createState() => _ListingPlansViewState();
}

class _ListingPlansViewState extends State<ListingPlansView> {
  List<ListingPlanItem> _plans = sl<ApiService>().cachedListingPlans ?? [];
  List<Map<String, dynamic>> _userActivePlans = [];
  bool _isLoading = false;
  StreamSubscription<List<ListingPlanItem>>? _plansSub;

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
      final list = await sl<ApiService>().getListingPlans(forceRefresh: forceRefresh);
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
          _userActivePlans = plans.where((p) {
            final status = (p['status'] ?? '').toString().toLowerCase();
            final isExpired = p['is_expired'] == true ||
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
    context.push(
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
    ).then((_) {
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
    final displayPlans = activePlans.isNotEmpty ? activePlans : _plans;

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
                        'Pay to publish your events, galleries and art centres on Artist Dubai.'.trData(context),
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
                          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
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
                                'No listing plans available'.trData(context),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Publishing plans will appear here once configured.'.trData(context),
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

  Widget _buildUserActivePlanBanner(BuildContext context) {
    final active = _userActivePlans.first;
    final planName = active['plan_name']?.toString() ?? 'Active Plan';
    final price = active['price']?.toString() ?? '';
    final daysLeft = active['days_left'] != null ? active['days_left'].toString() : '30';
    final expiryDate = active['expiry_date']?.toString().split(' ').first ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF134E4A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF34D399), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified, size: 12, color: Colors.white),
                    const SizedBox(width: 4),
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
              const Spacer(),
              InkWell(
                onTap: () => context.push(RouteNames.settings),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        'Manage in Settings'.trData(context),
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFFA7F3D0),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.chevron_right, size: 14, color: Color(0xFFA7F3D0)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  planName.trData(context),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              if (price.isNotEmpty)
                Text(
                  price.trData(context),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6EE7B7),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.timer_outlined, size: 14, color: Color(0xFFA7F3D0)),
              const SizedBox(width: 5),
              Text(
                '$daysLeft days remaining'.trData(context) +
                    (expiryDate.isNotEmpty ? ' (until $expiryDate)' : ''),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFA7F3D0),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, ListingPlanItem plan) {
    final isCurrentPlan = _userActivePlans.any((up) {
      final name = up['plan_name']?.toString().toLowerCase().trim() ?? '';
      final itemTitle = up['item_title']?.toString().toLowerCase().trim() ?? '';
      final planTitle = plan.title.toLowerCase().trim();
      return name == planTitle || itemTitle == planTitle || (name.isNotEmpty && name.contains(planTitle));
    });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: isCurrentPlan
            ? Border.all(color: const Color(0xFF10B981), width: 2.2)
            : Border.all(color: Colors.transparent, width: 2.2),
        boxShadow: [
          BoxShadow(
            color: isCurrentPlan
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
                  const Icon(Icons.check_circle, size: 14, color: Color(0xFF10B981)),
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

          // Header Row: Title + Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  plan.title.trData(context),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
              ),
              if (plan.badge.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCurrentPlan ? const Color(0xFFDCFCE7) : const Color(0xFFF1EBF7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    plan.badge.trData(context),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isCurrentPlan ? const Color(0xFF047857) : const Color(0xFF5E227A),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),

          // Category subheading
          Text(
            plan.category.trData(context),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF7E4A96),
            ),
          ),
          const SizedBox(height: 12),

          // Price
          Text(
            plan.price.trData(context),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 6),

          // Description
          if (plan.description.isNotEmpty) ...[
            Text(
              plan.description.trData(context),
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Features Checklist
          for (final feature in plan.features) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check,
                    size: 16,
                    color: Color(0xFF5E227A),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature.trData(context),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () => _onPayPressed(context, plan),
              style: ElevatedButton.styleFrom(
                backgroundColor: isCurrentPlan ? const Color(0xFF059669) : const Color(0xFF5E227A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              icon: Icon(
                isCurrentPlan ? Icons.replay_rounded : Icons.arrow_forward_rounded,
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
