import 'package:flutter/material.dart';
import '../../../../core/utils/responsive_helper.dart';

class DashboardHeaderWidget extends StatelessWidget {
  const DashboardHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final rh = ResponsiveHelper.of(context);
    final logoSize = rh.isDesktop ? 80.0 : rh.isTablet ? 72.0 : 64.0;
    final titleFontSize = rh.adaptiveFont(19);
    final subtitleFontSize = rh.adaptiveFont(10);
    final spacing = rh.isWide ? 18.0 : 14.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: rh.isWide ? 4.0 : 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo as per original image shape
          Image.asset(
            'assets/images/header_logo.png',
            width: logoSize,
            height: logoSize,
            fit: BoxFit.contain,
          ),
          SizedBox(width: spacing),

          // Title & Tagline
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Builder(
                  builder: (context) {
                    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isArabic ? 'فنان دبي' : 'ARTIST DUBAI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w700,
                            letterSpacing: isArabic ? 0.0 : 0.8,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isArabic ? 'منصة المجتمع الثقافي الفني' : 'COMMUNITY PLATFORM',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: subtitleFontSize,
                            fontWeight: FontWeight.w400,
                            letterSpacing: isArabic ? 0.0 : 2.2,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
