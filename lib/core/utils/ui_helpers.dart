import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'data_translator.dart';

class UiHelpers {
  UiHelpers._();

  static void showSnackBar(
    BuildContext context, {
    required String message,
    bool isError = false,
    Duration duration = const Duration(milliseconds: 1500),
    Color? backgroundColor,
    SnackBarBehavior behavior = SnackBarBehavior.floating,
  }) {
    bool isArabic = false;
    try {
      isArabic = Localizations.localeOf(context).languageCode == 'ar';
    } catch (_) {
      isArabic = DataTranslator.isAppArabic;
    }

    final translatedMessage = message.trData(context);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          translatedMessage,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        ),
        backgroundColor: backgroundColor ?? (isError ? AppColors.error : AppColors.primaryDark),
        behavior: behavior,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: duration,
      ),
    );
  }

  static Future<void> showErrorDialog(
    BuildContext context, {
    String? title,
    required String message,
    String? buttonText,
  }) {
    bool isArabic = false;
    try {
      isArabic = Localizations.localeOf(context).languageCode == 'ar';
    } catch (_) {
      isArabic = DataTranslator.isAppArabic;
    }

    final effectiveTitle = (title ?? 'Required Details Missing').trData(context);
    final effectiveMessage = message.trData(context);
    final effectiveButton = buttonText != null ? buttonText.trData(context) : (isArabic ? 'حسناً' : 'OK');

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFDC2626),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  effectiveTitle,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            effectiveMessage,
            style: const TextStyle(
              fontSize: 14.5,
              color: Color(0xFF475569),
              height: 1.4,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A2777),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  effectiveButton,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
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
