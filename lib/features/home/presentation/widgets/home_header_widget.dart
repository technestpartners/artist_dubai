import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/locale_provider.dart';
import '../../../../core/utils/responsive_helper.dart';

class HomeHeaderWidget extends StatelessWidget {
  const HomeHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final rh = ResponsiveHelper.of(context);
    final l10n = AppLocalizations.of(context);

    final logoSize = rh.isDesktop
        ? 120.0
        : rh.isTablet
            ? 100.0
            : (rh.width * 0.22).clamp(64.0, 110.0);
    final titleFontSize = rh.isDesktop
        ? 26.0
        : rh.isTablet
            ? 22.0
            : (rh.width * 0.048).clamp(16.0, 22.0);
    final subtitleFontSize = rh.isDesktop
        ? 14.0
        : rh.isTablet
            ? 12.5
            : (rh.width * 0.026).clamp(9.5, 12.5);
    final hPad = rh.isWide ? 16.0 : 10.0;
    final vPad = rh.isWide ? 8.0 : 4.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: rh.contentMaxWidth),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Responsive Logo Image
              SizedBox(
                width: logoSize,
                height: logoSize,
                child: Image.asset(
                  'assets/images/header_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(width: rh.isWide ? 16.0 : 10.0),

              // Header Titles
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.appName.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l10n.communityPlatform.toUpperCase(),
                      style: TextStyle(
                        color: const Color(0xFFD4C2F0),
                        fontSize: subtitleFontSize,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Home Header Language Toggle Button
              Consumer<LocaleProvider>(
                builder: (context, localeProvider, _) {
                  final isArabic = localeProvider.isArabic;
                  return Tooltip(
                    message: isArabic ? 'Switch to English' : 'التبديل إلى العربية',
                    child: InkWell(
                      onTap: () => localeProvider.toggleLocale(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.45),
                            width: 1.2,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.language, size: 15, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              isArabic ? 'English' : 'عربي',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
