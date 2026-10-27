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
                ? 120.0
                : rh.isTablet
                ? 95.0
                : 72.0;
        final maxSingleTitleFont =
            rh.isDesktop
                ? 24.0
                : rh.isTablet
                ? 21.0
                : 18.5;
        final maxTitleFont =
            rh.isDesktop
                ? 20.0
                : rh.isTablet
                ? 18.5
                : 16.5;
        final maxSubFont =
            rh.isDesktop
                ? 16.0
                : rh.isTablet
                ? 14.5
                : 13.5;

        final minIcon = rh.isWide ? 48.0 : 34.0;
        final minTitle = rh.isWide ? 13.0 : 10.0;
        final minSub = rh.isWide ? 11.0 : 8.5;

        // Visually balanced icon size (~45% of card height for harmonious proportions)
        final iconSize = (cardHeight * 0.45).clamp(minIcon, maxIconSize);

        // Larger, more prominent professional typography
        final titleFontSize =
            !hasSubtitle
                ? (cardHeight * 0.165).clamp(minTitle + 3, maxSingleTitleFont)
                : item.isLongTitle
                ? (cardHeight * 0.125).clamp(minTitle, maxTitleFont - 1.5)
                : (cardHeight * 0.145).clamp(minTitle + 1, maxTitleFont);

        final subtitleFontSize = (cardHeight * 0.112).clamp(minSub, maxSubFont);
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
                  horizontal: 5.0,
                  vertical: 2.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 1. Flexible Image — visually balanced
                    Flexible(
                      flex: 10,
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
                      flex: 11,
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
                                      letterSpacing: 0.5,
                                      height: 1.12,
                                    ),
                                  ),
                                ),
                              ),
                              if (localizedSubtitle != null) ...[
                                const SizedBox(height: 1.5),
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      localizedSubtitle,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      style: TextStyle(
                                        color: const Color(0xFFE6DCF8),
                                        fontSize: subtitleFontSize,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.35,
                                        height: 1.08,
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
