import 'package:flutter/material.dart';
import 'package:artist_dubai/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/utils/responsive_helper.dart';

class ComingSoonView extends StatelessWidget {
  final String? featureName;
  const ComingSoonView({super.key, this.featureName});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rh = ResponsiveHelper.of(context);
    final logoSize = rh.isDesktop ? 260.0 : rh.isTablet ? 230.0 : 200.0;

    return Scaffold(
      backgroundColor: const Color(0xFF5D1F8E),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
                    tooltip: 'Back',
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(RouteNames.home);
                      }
                    },
                  ),
                  const Spacer(),
                ],
              ),
            ),
            const Spacer(flex: 1),

            // Top Artist Dubai Logo as per original image shape
            Center(
              child: Image.asset(
                'assets/images/header_logo.png',
                width: logoSize,
                height: logoSize,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/images/header_logo.png',
                    width: logoSize,
                    height: logoSize,
                    fit: BoxFit.contain,
                  );
                },
              ),
            ),
            const Spacer(flex: 3),

            // Feature Name & "Actively from" & "06.2026"
            Center(
              child: Column(
                children: [
                  if (featureName != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        featureName!,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                  Text(
                    l10n.activelyFrom,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: rh.adaptiveFont(32),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '06.2026',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: rh.adaptiveFont(38),
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(flex: 3),

            // "back to home" Pill Button
            Center(
              child: SizedBox(
                height: rh.buttonHeight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF230078),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 36,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(RouteNames.home);
                    }
                  },
                  child: Text(
                    l10n.backToHome,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(flex: 4),

            // Bottom Footer
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Center(
                child: Text(
                  l10n.hostedBy,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
