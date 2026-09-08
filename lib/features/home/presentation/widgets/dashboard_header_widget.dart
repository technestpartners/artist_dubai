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
          // Compact Circular Logo
          Container(
            width: logoSize,
            height: logoSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/header_logo.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: spacing),

          // Title & Tagline
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ARTIST DUBAI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'COMMUNITY PLATFORM',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: subtitleFontSize,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 2.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
