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

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
              maxWidth: rh.contentMaxWidth,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: rh.horizontalPadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Spacer(flex: isShort ? 1 : 2),
                    // App Icon or Emoji
                    Center(
                      child:
                          item.imagePath != null
                              ? Container(
                                width: iconSize,
                                height: iconSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.25,
                                      ),
                                      blurRadius: 18,
                                      offset: const Offset(0, 6),
                                    ),
                                    BoxShadow(
                                      color: const Color(
                                        0xFFE879F9,
                                      ).withValues(alpha: 0.45),
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
                                style: TextStyle(
                                  fontSize: isShort ? 48 : 68,
                                  height: 1.1,
                                ),
                              ),
                    ),
                    SizedBox(height: isShort ? 16 : 28),

                    // Title
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            item.title.trData(context),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: rh.sp(
                                isShort ? 19 : (rh.isCompact ? 20 : 23),
                              ),
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: isShort ? 12 : 18),

                    // Description
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          item.description.trData(context),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFFF1E8FB),
                            fontSize: rh.sp(
                              isShort ? 13.5 : (rh.isCompact ? 14.5 : 16.5),
                            ),
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                    Spacer(flex: isShort ? 1 : 2),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
