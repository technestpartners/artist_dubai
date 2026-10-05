import 'package:flutter/material.dart';
import 'package:artist_dubai/l10n/app_localizations.dart';

import '../../../../core/utils/responsive_helper.dart';

class HomeFooterWidget extends StatelessWidget {
  const HomeFooterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rh = ResponsiveHelper.of(context);
    final vPad = rh.isShortScreen ? 2.0 : (rh.isWide ? 6.0 : 3.0);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: vPad),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            l10n.hostedBy,
            style: const TextStyle(
              color: Color(0xFFE2D6F5),
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}
