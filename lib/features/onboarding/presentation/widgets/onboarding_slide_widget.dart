import 'package:flutter/material.dart';
import '../../../../core/utils/data_translator.dart';
import '../../domain/models/onboarding_item.dart';

class OnboardingSlideWidget extends StatelessWidget {
  final OnboardingItem item;

  const OnboardingSlideWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(flex: 3),
          // App Icon or Emoji
          Center(
            child: item.imagePath != null
                ? Container(
                    width: 112,
                    height: 112,
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
                    style: const TextStyle(fontSize: 68, height: 1.1),
                  ),
          ),
          const SizedBox(height: 38),

          // Title
          Center(
            child: Text(
              item.title.trData(context),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 27,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Description
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                item.description.trData(context),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFE0DBE5),
                  fontSize: 16.5,
                  height: 1.45,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}
