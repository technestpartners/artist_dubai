import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:artist_dubai/app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/storage_service.dart';
import '../../domain/models/onboarding_item.dart';
import '../widgets/onboarding_slide_widget.dart';

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
  void dispose() {
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
      context.go(RouteNames.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentIndex == _slides.length - 1;
    final isFirstPage = _currentIndex == 0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF5A2575), // Top-left purple glow
              Color(0xFF2E0D3E),
              Color(0xFF030104), // Pure deep pitch black center
              Color(0xFF1E082B),
              Color(0xFF5E227A), // Bottom-right purple glow
            ],
            stops: [0.0, 0.28, 0.55, 0.80, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar with Skip Button
              Padding(
                padding: const EdgeInsets.only(top: 8.0, right: 20.0),
                child: Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
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
                    child: const Text('Skip'),
                  ),
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
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4.5),
                    width: 7.5,
                    height: 7.5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          isActive
                              ? Colors.white
                              : const Color(0xFF6B5377).withValues(alpha: 0.6),
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
                      if (!isFirstPage)
                        SizedBox(
                          width: 142,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _onPrevious,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5A396A),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: const Text(
                              'Previous',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      SizedBox(
                        width: isLastPage ? 168 : (isFirstPage ? 116 : 116),
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _onNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isLastPage
                                    ? Colors.white
                                    : const Color(0xFF5A396A),
                            foregroundColor:
                                isLastPage
                                    ? const Color(0xFF1E0A36)
                                    : Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: Text(
                            isLastPage ? 'Get Started' : 'Next',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  isLastPage
                                      ? FontWeight.w600
                                      : FontWeight.w400,
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
