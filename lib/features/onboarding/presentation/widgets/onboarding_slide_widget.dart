import 'package:flutter/material.dart';
import '../../domain/models/onboarding_item.dart';

class OnboardingSlideWidget extends StatelessWidget {
  final OnboardingItem item;

  const OnboardingSlideWidget({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(flex: 3),
          // Native 3D Emoji Icon matching the screenshots exactly
          Center(
            child: Text(
              item.emoji,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 68,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 38),

          // Title
          Center(
            child: Text(
              item.title,
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
                item.description,
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
