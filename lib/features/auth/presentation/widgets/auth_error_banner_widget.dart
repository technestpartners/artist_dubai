import 'package:flutter/material.dart';

/// Reusable validation error indicator rendered beneath input fields.
class AuthErrorBanner extends StatelessWidget {
  final String? errorText;
  final String? message;

  const AuthErrorBanner({super.key, this.errorText, this.message});

  @override
  Widget build(BuildContext context) {
    final effectiveText = message ?? errorText;
    if (effectiveText == null || effectiveText.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6.0, left: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 14, color: Color(0xFFDC2626)),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              effectiveText,
              style: const TextStyle(
                color: Color(0xFFDC2626),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
