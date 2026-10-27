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

        final hasSubtitle = item.subtitle != null;

        // Widen clamp maximums on tablet / desktop / mobile
        final maxIconSize =
            rh.isDesktop
                ? 130.0
                : rh.isTablet
                ? 110.0
                : 80.0;
        final maxSingleTitleFont =
            rh.isDesktop
                ? 22.0
                : rh.isTablet
                ? 19.5
                : 17.5;
        final maxTitleFont =
            rh.isDesktop
                ? 19.0
                : rh.isTablet
                ? 17.5
                : 15.5;
        final maxSubFont =
            rh.isDesktop
                ? 15.0
                : rh.isTablet
                ? 13.5
                : 12.5;

        final minIcon = rh.isWide ? 50.0 : 36.0;
        final minTitle = rh.isWide ? 12.0 : 9.5;
        final minSub = rh.isWide ? 10.5 : 8.0;

        // Visually balanced icon size (~50% of card height instead of crowded 60%)
        final iconSize = (cardHeight * 0.50).clamp(minIcon, maxIconSize);

        // Larger, more professional typography fitting neatly in card
        final titleFontSize =
            !hasSubtitle
                ? (cardHeight * 0.155).clamp(minTitle + 2, maxSingleTitleFont)
                : item.isLongTitle
                ? (cardHeight * 0.118).clamp(minTitle, maxTitleFont - 1.5)
                : (cardHeight * 0.134).clamp(minTitle, maxTitleFont);

        final subtitleFontSize = (cardHeight * 0.100).clamp(minSub, maxSubFont);
        final cornerRadius = (cardWidth * 0.12).clamp(10.0, 24.0);

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
                  vertical: 2.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 1. Flexible Image — visually balanced
                    Flexible(
                      flex: 11,
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
                                size: (iconSize * 0.55).clamp(20.0, 56.0),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),

                    // 2. Flexible Text Container — larger and more prominent
                    Flexible(
                      flex: 9,
                      child: Builder(
                        builder: (context) {
                          final localizedTitle = item.getLocalizedTitle(
                            context,
                          );
                          final localizedSubtitle = item.getLocalizedSubtitle(
                            context,
                          );
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
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
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.35,
                                      height: 1.1,
                                    ),
                                  ),
                                ),
                              ),
                              if (localizedSubtitle != null) ...[
                                const SizedBox(height: 1),
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      localizedSubtitle,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      style: TextStyle(
                                        color: const Color(0xFFE2D6F5),
                                        fontSize: subtitleFontSize,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.25,
                                        height: 1.05,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
