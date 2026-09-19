import 'package:flutter/material.dart';
import 'package:artist_dubai/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_top_bar.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

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
                l10n.privacyPolicy,
                style: TextStyle(
                  fontSize: rh.adaptiveFont(26),
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 10),

              // Last Updated Date
              Text(
                l10n.privacyPolicyLastUpdated,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFE2D6F5),
                ),
              ),
              const SizedBox(height: 24),

              // Section: Introduction
              Text(
                l10n.privacyIntroTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.privacyIntroText,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFE2D6F5),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Section: Information We Collect
              Text(
                l10n.privacyCollectTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.privacyCollectSubtitle,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFE2D6F5),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),

              // Bullet Points
              _buildBulletPoint(
                label: l10n.privacyBulletIdentityLabel,
                text: l10n.privacyBulletIdentityText,
              ),
              _buildBulletPoint(
                label: l10n.privacyBulletContactLabel,
                text: l10n.privacyBulletContactText,
              ),
              _buildBulletPoint(
                label: l10n.privacyBulletTechLabel,
                text: l10n.privacyBulletTechText,
              ),
              _buildBulletPoint(
                label: l10n.privacyBulletUsageLabel,
                text: l10n.privacyBulletUsageText,
              ),
              _buildBulletPoint(
                label: l10n.privacyBulletProfileLabel,
                text: l10n.privacyBulletProfileText,
              ),
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

  Widget _buildBulletPoint({required String label, required String text}) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 10.0, start: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsetsDirectional.only(top: 6.0, end: 10.0),
            child: Icon(Icons.circle, size: 6, color: Color(0xFFE2D6F5)),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14.5,
                  color: Color(0xFFE2D6F5),
                  height: 1.45,
                ),
                children: [
                  TextSpan(
                    text: label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  TextSpan(
                    text: text,
                    style: const TextStyle(color: Color(0xFFE2D6F5)),
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
