import 'package:flutter/material.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../domain/models/menu_card_item.dart';

class MenuCardWidget extends StatelessWidget {
  final MenuCardItem item;
  final VoidCallback? onTap;

  const MenuCardWidget({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final rh = ResponsiveHelper.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardHeight = constraints.maxHeight;
        final cardWidth = constraints.maxWidth;

        // Widen clamp maximums on tablet / desktop
        final maxIconSize = rh.isDesktop ? 96.0 : rh.isTablet ? 84.0 : 72.0;
        final maxTitleFont = rh.isDesktop ? 18.0 : rh.isTablet ? 16.5 : 16.5;
        final maxSubFont = rh.isDesktop ? 14.0 : rh.isTablet ? 13.0 : 12.5;

        final iconSize = (cardHeight * 0.42).clamp(46.0, maxIconSize);
        final titleFontSize = item.isLongTitle
            ? (cardHeight * 0.110).clamp(11.5, maxTitleFont - 2)
            : (cardHeight * 0.125).clamp(13.0, maxTitleFont);
        final subtitleFontSize = (cardHeight * 0.095).clamp(10.5, maxSubFont);
        final cornerRadius = (cardWidth * 0.14).clamp(16.0, 28.0);

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
                  vertical: 3.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 1. Flexible Image — shrinks when space is tight
                    Flexible(
                      flex: 3,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: iconSize,
                          maxHeight: iconSize,
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            item.imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.image,
                                color: Colors.white,
                                size: (iconSize * 0.55).clamp(28.0, 42.0),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),

                    // 2. Flexible Text Container
                    Flexible(
                      flex: 2,
                      child: Builder(
                        builder: (context) {
                          final localizedTitle = item.getLocalizedTitle(context);
                          final localizedSubtitle = item.getLocalizedSubtitle(context);
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    localizedTitle,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: titleFontSize,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                      height: 1.1,
                                    ),
                                  ),
                                ),
                              ),
                              if (localizedSubtitle != null)
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      localizedSubtitle,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      style: TextStyle(
                                        color: const Color(0xFFD6C8F2),
                                        fontSize: subtitleFontSize,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.2,
                                        height: 1.05,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
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
