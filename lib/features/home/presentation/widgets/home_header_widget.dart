import 'package:flutter/material.dart';

class HomeHeaderWidget extends StatelessWidget {
  const HomeHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final logoSize = (screenWidth * 0.26).clamp(92.0, 125.0);
        final titleFontSize = (screenWidth * 0.052).clamp(18.0, 24.0);
        final subtitleFontSize = (screenWidth * 0.028).clamp(10.0, 13.0);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Enlarged Logo Image
                SizedBox(
                  width: logoSize,
                  height: logoSize,
                  child: Image.asset(
                    'assets/images/header_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 14),

                // Header Titles (Aligned to exact same width)
                IntrinsicWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      FittedBox(
                        fit: BoxFit.fitWidth,
                        child: Text(
                          'COMMUNITY PLATFORM',
                          style: TextStyle(
                            color: const Color(0xFFD4C2F0),
                            fontSize: subtitleFontSize,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
