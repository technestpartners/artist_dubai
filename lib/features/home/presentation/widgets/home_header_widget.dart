import 'package:flutter/material.dart';

class HomeHeaderWidget extends StatelessWidget {
  const HomeHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final logoSize = (screenWidth * 0.20).clamp(72.0, 96.0);
        final titleFontSize = (screenWidth * 0.052).clamp(18.0, 23.0);
        final subtitleFontSize = (screenWidth * 0.028).clamp(10.0, 12.5);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Direct Logo Image (no shadow, no background container, no round crop shape)
                SizedBox(
                  width: logoSize,
                  height: logoSize,
                  child: Image.asset(
                    'assets/images/artist-dubai-logo-26Kex3Rz.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 16),

                // Header Titles
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ARTIST DUBAI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'COMMUNITY PLATFORM',
                      style: TextStyle(
                        color: const Color(0xFFD4C2F0),
                        fontSize: subtitleFontSize,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
