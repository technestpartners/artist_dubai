import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/routes/route_names.dart';
import '../utils/data_translator.dart';

/// Reusable navigation back button with RTL support and fallback route.
class AppBackButton extends StatelessWidget {
  final Color color;
  final String? label;
  final VoidCallback? onPressed;
  final String fallbackRoute;

  const AppBackButton({
    super.key,
    this.color = Colors.white,
    this.label,
    this.onPressed,
    this.fallbackRoute = RouteNames.home,
  });

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final icon = isRtl ? Icons.arrow_forward : Icons.arrow_back;

    void handleTap() {
      if (onPressed != null) {
        onPressed!();
      } else if (context.canPop()) {
        context.pop();
      } else {
        context.go(fallbackRoute);
      }
    }

    if (label == null || label!.isEmpty) {
      return IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: handleTap,
      );
    }

    return InkWell(
      onTap: handleTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              label!.trData(context),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
