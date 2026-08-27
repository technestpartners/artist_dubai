import 'package:flutter/material.dart';
import '../../domain/models/menu_card_item.dart';

class MenuCardWidget extends StatelessWidget {
  final MenuCardItem item;
  final VoidCallback? onTap;

  const MenuCardWidget({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardHeight = constraints.maxHeight;
        final cardWidth = constraints.maxWidth;

        // Auto-scale dimensions flexibly for all screen heights
        final iconSize = (cardHeight * 0.36).clamp(32.0, 52.0);
        final titleFontSize =
            item.isLongTitle
                ? (cardHeight * 0.080).clamp(8.5, 10.5)
                : (cardHeight * 0.092).clamp(9.5, 12.0);
        final subtitleFontSize = (cardHeight * 0.076).clamp(7.5, 10.0);
        final cornerRadius = (cardWidth * 0.14).clamp(14.0, 24.0);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(cornerRadius),
            splashColor: Colors.white24,
            highlightColor: Colors.white10,
            child: Ink(
              decoration: BoxDecoration(
                color: const Color(0xFF28208C),
                borderRadius: BorderRadius.circular(cornerRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6.0,
                  vertical: 4.0,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 1. Direct Image from assets/images/
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
                                size: 28,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // 2. Flexible Text Container
                      Flexible(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
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
                                letterSpacing: 0.2,
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
                                  letterSpacing: 0.2,
                                  height: 1.05,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
