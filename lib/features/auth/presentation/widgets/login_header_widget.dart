import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:artist_dubai/l10n/app_localizations.dart';
import '../../../../app/routes/route_names.dart';

/// Top bar actions for auth screens containing back and home buttons.
class LoginHeader extends StatelessWidget {
  final double horizontalPadding;

  const LoginHeader({super.key, required this.horizontalPadding});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 12.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(RouteNames.home);
              }
            },
          ),
          InkWell(
            onTap: () => context.go(RouteNames.home),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.home_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.home,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
