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
        final maxIconSize = rh.isDesktop ? 96.0 : rh.isTablet ? 84.0 : 66.0;
        final maxTitleFont = rh.isDesktop ? 18.0 : rh.isTablet ? 16.5 : 15.0;
        final maxSubFont = rh.isDesktop ? 14.0 : rh.isTablet ? 13.0 : 12.0;

        final minIcon = rh.isWide ? 44.0 : 26.0;
        final minTitle = rh.isWide ? 12.0 : 9.0;
        final minSub = rh.isWide ? 10.0 : 7.5;

        final iconSize = (cardHeight * 0.36).clamp(minIcon, maxIconSize);
        final titleFontSize = item.isLongTitle
            ? (cardHeight * 0.095).clamp(minTitle, maxTitleFont - 2)
            : (cardHeight * 0.112).clamp(minTitle, maxTitleFont);
        final subtitleFontSize = (cardHeight * 0.082).clamp(minSub, maxSubFont);
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
                  vertical: 2.5,
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
                                size: (iconSize * 0.55).clamp(18.0, 42.0),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),

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
