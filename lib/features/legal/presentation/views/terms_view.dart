import 'package:flutter/material.dart';
import 'package:artist_dubai/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_top_bar.dart';

class TermsView extends StatelessWidget {
  const TermsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rh = ResponsiveHelper.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF6B1C9B),
      appBar: const AppTopBar(backgroundColor: Colors.white),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: rh.contentMaxWidth),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: rh.horizontalPadding, vertical: 16.0),
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button
              InkWell(
                onTap: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(RouteNames.home);
                  }
                },
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Directionality.of(context) == TextDirection.rtl
                            ? Icons.arrow_forward
                            : Icons.arrow_back,
                        size: 20,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.back,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                l10n.termsOfService,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 10),

              // Last Updated Date
              Text(
                l10n.termsLastUpdated,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFE2D6F5),
                ),
              ),
              const SizedBox(height: 24),

              // Section: Agreement to Terms
              Text(
                l10n.termsAgreementTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.termsAgreementText,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFE2D6F5),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Section: Use License
              Text(
                l10n.termsLicenseTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.termsLicenseSubtitle,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFE2D6F5),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),

              // Bullet Points
              _buildBulletPoint(l10n.termsBullet1),
              _buildBulletPoint(l10n.termsBullet2),
              _buildBulletPoint(l10n.termsBullet3),
              _buildBulletPoint(l10n.termsBullet4),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: -1),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 10.0, start: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsetsDirectional.only(top: 7.0, end: 10.0),
            child: Icon(Icons.circle, size: 5.5, color: Color(0xFFE2D6F5)),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14.5,
                color: Color(0xFFE2D6F5),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
