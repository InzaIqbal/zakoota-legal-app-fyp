import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_constants.dart';
import 'widgets/onboarding_content.dart';
import 'widgets/dots_indicator.dart';

/// Onboarding screen with 3-slide PageView
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'icon': PhosphorIconsRegular.magnifyingGlass,
      'title': 'Find Verified Lawyers',
      'description': 'Connect with top legal experts instantly.',
    },
    {
      'icon': PhosphorIconsRegular.gavel,
      'title': 'Track Your Case',
      'description': 'Real-time updates on hearings and documents.',
    },
    {
      'icon': PhosphorIconsRegular.shieldCheck,
      'title': 'Secure Payments',
      'description': 'Escrow protection for your peace of mind.',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _skipToWelcome() {
    context.go('/welcome');
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: AppDurations.medium,
        curve: Curves.easeInOut,
      );
    } else {
      _skipToWelcome();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withValues(alpha: 0.14),
              ),
            ),
          ),
          Positioned(
            bottom: 180,
            left: -120,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    0,
                  ),
                  child: Row(
                    children: [
                      const Spacer(),
                      TextButton(
                        onPressed: _skipToWelcome,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white.withValues(alpha: 0.92),
                        ),
                        child: const Text('Skip'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: _slides.length,
                    itemBuilder: (context, index) {
                      final slide = _slides[index];
                      return OnboardingContent(
                        icon: slide['icon'] as PhosphorIconData,
                        title: slide['title'] as String,
                        description: slide['description'] as String,
                      );
                    },
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      DotsIndicator(
                        currentPage: _currentPage,
                        pageCount: _slides.length,
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _nextPage,
                        icon: PhosphorIcon(
                          _currentPage == _slides.length - 1
                              ? PhosphorIconsRegular.checkCircle
                              : PhosphorIconsRegular.arrowRight,
                          size: 18,
                        ),
                        label: Text(
                          _currentPage == _slides.length - 1
                              ? 'Get Started'
                              : 'Next',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
