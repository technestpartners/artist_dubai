import 'package:flutter/material.dart';
import '../../domain/models/dashboard_item.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/utils/data_translator.dart';

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
    final rh = ResponsiveHelper.of(context);
    final iconSize = rh.scale(56).clamp(48.0, 80.0);
    final titleFontSize = rh.adaptiveFont(item.title.contains('|') ? 12.0 : 14.5);
    final subFontSize = rh.adaptiveFont(item.title.contains('|') ? 10.5 : 11.5);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF28208C),
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
                // Solid Circular Icon — scales with screen class
                SizedBox(
                  width: iconSize,
                  height: iconSize,
                  child: Image.asset(item.iconPath, fit: BoxFit.contain),
                ),
                const SizedBox(height: 6),

                // Title Text
                Flexible(
                  child: Text(
                    item.title.trData(context),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                      height: 1.1,
                    ),
                  ),
                ),

                // Subtitle Text (if present)
                if (item.subtitle != null) ...[
                  const SizedBox(height: 3),
                  Flexible(
                    child: Text(
                      item.subtitle!.trData(context),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFFD6C8F2),
                        fontSize: subFontSize,
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
