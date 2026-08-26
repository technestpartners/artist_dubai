import 'package:flutter/material.dart';
import '../../domain/models/dashboard_item.dart';

class DashboardCardWidget extends StatelessWidget {
  final DashboardItem item;
  final VoidCallback onTap;

  const DashboardCardWidget({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1C0B5E),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Solid Circular Icon
                SizedBox(
                  width: 42,
                  height: 42,
                  child: Image.asset(item.iconPath, fit: BoxFit.contain),
                ),
                const SizedBox(height: 6),

                // Title Text
                Flexible(
                  child: Text(
                    item.title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: item.title.contains('|') ? 10.0 : 12.0,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                      height: 1.1,
                    ),
                  ),
                ),

                // Subtitle Text (if present)
                if (item.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Flexible(
                    child: Text(
                      item.subtitle!,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: item.title.contains('|') ? 9.0 : 9.5,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
