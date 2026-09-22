import 'package:flutter/material.dart';
import '../../../../core/utils/data_translator.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../domain/models/onboarding_item.dart';

class OnboardingSlideWidget extends StatelessWidget {
  final OnboardingItem item;

  const OnboardingSlideWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final rh = ResponsiveHelper.of(context);
    final isShort = rh.isShortScreen;
    final iconSize = isShort ? 72.0 : (rh.isCompact ? 90.0 : 112.0);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: rh.horizontalPadding),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: rh.contentMaxWidth),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Spacer(flex: isShort ? 1 : 3),
              // App Icon or Emoji
              Center(
                child: item.imagePath != null
                    ? Container(
                        width: iconSize,
                        height: iconSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: const Color(0xFF6B1C9B).withValues(alpha: 0.35),
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          item.imagePath!,
                          fit: BoxFit.contain,
                        ),
                      )
                    : Text(
                        item.emoji,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: isShort ? 48 : 68, height: 1.1),
                      ),
              ),
              SizedBox(height: isShort ? 16 : 30),

              // Title
              Center(
                child: Text(
                  item.title.trData(context),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: rh.sp(isShort ? 20 : (rh.isCompact ? 22 : 26)),
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    height: 1.25,
                  ),
                ),
              ),
              SizedBox(height: isShort ? 10 : 16),

              // Description
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    item.description.trData(context),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFFE0DBE5),
                      fontSize: rh.sp(isShort ? 13 : (rh.isCompact ? 14 : 16)),
                      height: 1.45,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              Spacer(flex: isShort ? 1 : 3),
            ],
          ),
        ),
      ),
    );
  }
}
