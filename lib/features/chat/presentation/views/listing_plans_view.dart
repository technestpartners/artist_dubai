import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/live_sync_service.dart';
import '../../../../core/utils/data_translator.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../domain/models/listing_plan_model.dart';

export '../../domain/models/listing_plan_model.dart';

class ListingPlansView extends StatefulWidget {
  const ListingPlansView({super.key});

  /// Default baseline plans for fallback and offline tests
  static const List<ListingPlanItem> plans = ApiService.defaultListingPlans;

  @override
  State<ListingPlansView> createState() => _ListingPlansViewState();
}

class _ListingPlansViewState extends State<ListingPlansView> {
  List<ListingPlanItem> _plans = ListingPlansView.plans;
  StreamSubscription<List<ListingPlanItem>>? _plansSub;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() {
    // 1. Fetch live listing plans from MySQL via ApiService
    _fetchPlans();

    // 2. Listen for real-time live sync updates from Admin changes
    try {
      final liveSync = sl<LiveSyncService>();
      _plansSub = liveSync.listingPlansStream.listen((updatedList) {
        if (mounted && updatedList.isNotEmpty) {
          setState(() {
            _plans = updatedList;
          });
        }
      });
    } catch (_) {}
  }

  Future<void> _fetchPlans({bool forceRefresh = false}) async {
    try {
      final list = await sl<ApiService>().getListingPlans(forceRefresh: forceRefresh);
      if (mounted && list.isNotEmpty) {
        setState(() {
          _plans = list;
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
    // Navigate to plan payment screen with chosen plan details
    context.push(
      RouteNames.planPayment,
      extra: {
        'itemType': plan.itemType,
        'planName': plan.title,
        'planPeriod': plan.badge,
        'planAmount': plan.price,
        'amount': plan.price,
      },
    );
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
          onRefresh: () => _fetchPlans(forceRefresh: true),
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
                      const SizedBox(height: 20),

                      // Plan Cards
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

  Widget _buildPlanCard(BuildContext context, ListingPlanItem plan) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    color: const Color(0xFFF1EBF7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    plan.badge.trData(context),
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5E227A),
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
            child: ElevatedButton(
              onPressed: () => _onPayPressed(context, plan),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5E227A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                plan.buttonText.trData(context),
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
