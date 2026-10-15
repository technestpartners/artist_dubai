import 'package:flutter/material.dart';
import '../utils/data_translator.dart';

/// Standardized empty state component for lists, search, and category views.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionText;
  final VoidCallback? onAction;
  final Color iconColor;
  final Color titleColor;
  final Color subtitleColor;
  final Color buttonColor;
  final Color buttonTextColor;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionText,
    this.onAction,
    this.iconColor = Colors.white70,
    this.titleColor = Colors.white,
    this.subtitleColor = const Color(0xFFE2D6F5),
    this.buttonColor = Colors.white,
    this.buttonTextColor = const Color(0xFF6B1C9B),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 52, color: iconColor),
            const SizedBox(height: 16),
            Text(
              title.trData(context),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!.trData(context),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: subtitleColor,
                  height: 1.4,
                ),
              ),
            ],
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: buttonTextColor,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: onAction,
                child: Text(
                  actionText!.trData(context),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
