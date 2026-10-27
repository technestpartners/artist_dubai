import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:artist_dubai/app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/locale_provider.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/data_translator.dart';
import '../../domain/models/onboarding_item.dart';
import '../widgets/onboarding_slide_widget.dart';
import '../../../home/presentation/widgets/home_footer_widget.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<OnboardingItem> _slides = OnboardingItem.items;

  @override
  void initState() {
    super.initState();
    DataTranslator.translationNotifier.addListener(_onTranslationChanged);
  }

  void _onTranslationChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    DataTranslator.translationNotifier.removeListener(_onTranslationChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentIndex < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _onFinish();
    }
  }

  void _onPrevious() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _onFinish() async {
    try {
      final storage = sl<StorageService>();
      await storage.setBool(StorageServiceImpl.keyHasCompletedOnboarding, true);
    } catch (_) {}
    if (mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(RouteNames.home);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentIndex == _slides.length - 1;
    final isFirstPage = _currentIndex == 0;

    return Scaffold(
      backgroundColor: const Color(0xFF4D249E),
      bottomNavigationBar: const SafeArea(
        top: false,
        child: HomeFooterWidget(),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF6B1C9B), // Top vibrant purple from original design
              Color(0xFF58209B), // Mid royal purple
              Color(0xFF4D249E), // Bottom rich purple
            ],
            stops: [0.0, 0.48, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar with Language Toggle and Skip Button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Consumer<LocaleProvider>(
                      builder: (context, localeProvider, _) {
                        final isArabic = localeProvider.isArabic;
                        return Tooltip(
                          message:
                              isArabic
                                  ? 'Switch to English'
                                  : 'التبديل إلى العربية',
                          child: InkWell(
                            onTap: () => localeProvider.toggleLocale(),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.45),
                                  width: 1.2,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.language,
                                    size: 15,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isArabic ? 'English' : 'عربي',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    TextButton(
                      onPressed: _onFinish,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      child: Text('Skip'.trData(context)),
                    ),
                  ],
                ),
              ),

              // Slide Content PageView
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return OnboardingSlideWidget(item: _slides[index]);
                  },
                ),
              ),

              // 4 Page Indicator Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (index) {
                  final isActive = _currentIndex == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 4.5),
                    width: isActive ? 24.0 : 8.0,
                    height: 8.0,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4.0),
                      color:
                          isActive
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.35),
                      boxShadow:
                          isActive
                              ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFFE879F9,
                                  ).withValues(alpha: 0.6),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                              : null,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 42),

              // Bottom Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 10.0,
                ),
                child: SizedBox(
                  height: 56,
                  child: Row(
                    mainAxisAlignment:
                        isFirstPage
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.spaceBetween,
                    children: [
                      if (!isFirstPage) ...[
                        Expanded(
                          flex: 1,
                          child: SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _onPrevious,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.16,
                                ),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.45),
                                  width: 1.2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Previous'.trData(context),
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                      ],
                      isFirstPage
                          ? SizedBox(
                            width: 130,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _onNext,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF6B1C9B),
                                elevation: 2,
                                shadowColor: Colors.black.withValues(
                                  alpha: 0.25,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              child: Text(
                                'Next'.trData(context),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          )
                          : Expanded(
                            flex: isLastPage ? 2 : 1,
                            child: SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _onNext,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF6B1C9B),
                                  elevation: 2,
                                  shadowColor:
                                      isLastPage
                                          ? const Color(
                                            0xFFE879F9,
                                          ).withValues(alpha: 0.5)
                                          : Colors.black.withValues(
                                            alpha: 0.25,
                                          ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    (isLastPage ? 'Get Started' : 'Next')
                                        .trData(context),
                                    maxLines: 1,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}
