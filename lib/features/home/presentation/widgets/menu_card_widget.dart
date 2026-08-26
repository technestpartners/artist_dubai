import 'package:flutter/material.dart';
import '../../domain/models/menu_card_item.dart';

class MenuCardWidget extends StatelessWidget {
  final MenuCardItem item;
  final VoidCallback? onTap;

  const MenuCardWidget({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardHeight = constraints.maxHeight;
        final cardWidth = constraints.maxWidth;

        // Auto-scale dimensions for image display
        final iconSize = (cardHeight * 0.42).clamp(40.0, 60.0);
        final titleFontSize = item.isLongTitle
            ? (cardHeight * 0.082).clamp(8.5, 11.0)
            : (cardHeight * 0.098).clamp(10.0, 13.0);
        final subtitleFontSize = (cardHeight * 0.080).clamp(8.0, 10.5);
        final spacing = (cardHeight * 0.05).clamp(3.0, 8.0);
        final cornerRadius = (cardWidth * 0.14).clamp(16.0, 26.0);
        final textBlockHeight = (cardHeight * 0.28).clamp(28.0, 42.0);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(cornerRadius),
            splashColor: Colors.white24,
            highlightColor: Colors.white10,
            child: Ink(
              decoration: BoxDecoration(
                color: const Color(0xFF301B92),
                borderRadius: BorderRadius.circular(cornerRadius),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),

                    // 1. Direct Image from assets/images/ (Clipped as clean circle, zero borders, zero white dots)
                    SizedBox(
                      width: iconSize,
                      height: iconSize,
                      child: ClipOval(
                        child: Image.asset(
                          item.imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.image,
                              color: Colors.white,
                              size: 32,
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: spacing),

                    // 2. Uniform-Height Text Slot
                    SizedBox(
                      height: textBlockHeight,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.title,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.25,
                              height: 1.1,
                            ),
                          ),
                          if (item.subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              item.subtitle!,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: const Color(0xFFD6C8F2),
                                fontSize: subtitleFontSize,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.25,
                                height: 1.05,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const Spacer(flex: 3),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
