import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../config/router/route_names.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/buttons/buttons.dart';
import '../../../../core/widgets/gradient_button.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingSlide> _slides = [
    OnboardingSlide(
      title: AppStrings.onboardingSlide1Title,
      description: AppStrings.onboardingSlide1Desc,
      icon: Icons.flash_on_outlined,
      lottieAsset: 'assets/animations/onboarding_1.json',
    ),
    OnboardingSlide(
      title: AppStrings.onboardingSlide2Title,
      description: AppStrings.onboardingSlide2Desc,
      icon: Icons.gps_fixed_outlined,
      lottieAsset: 'assets/animations/onboarding_2.json',
    ),
    OnboardingSlide(
      title: AppStrings.onboardingSlide3Title,
      description: AppStrings.onboardingSlide3Desc,
      icon: Icons.payments_outlined,
      lottieAsset: 'assets/animations/onboarding_3.json',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: AppConstants.mediumAnimation,
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyOnboardingSeen, true);
    if (mounted) {
      context.go(RouteNames.phoneLogin);
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  Widget _buildSlide(BuildContext context, int index) {
    final colors = context.colors;
    final slide = _slides[index];
    final lottieAsset = slide.lottieAsset;
    final stepLabel = '0${index + 1} / 0${_slides.length}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXl),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 148,
                height: 148,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [colors.primary, colors.primaryEnd],
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.35),
                      blurRadius: 36,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.spacingLg),
                  child: lottieAsset != null
                      ? Lottie.asset(
                          lottieAsset,
                          width: 120,
                          height: 120,
                          repeat: false,
                          fit: BoxFit.contain,
                          frameRate: FrameRate.max,
                        )
                      : Icon(
                          slide.icon,
                          size: 68,
                          color: colors.onPrimary,
                        ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(
                    begin: const Offset(0.85, 0.85),
                    end: const Offset(1.0, 1.0),
                    curve: Curves.elasticOut,
                  ),
              const SizedBox(height: AppDimensions.spacingXl),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingMd,
                  vertical: AppDimensions.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Text(
                  stepLabel,
                  style: AppTextStyles.labelMedium.copyWith(color: colors.primary),
                ),
              )
                  .animate(delay: 150.ms)
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.2, end: 0),
              const SizedBox(height: AppDimensions.spacingMd),
              Text(
                slide.title,
                style: AppTextStyles.displayMedium.copyWith(color: colors.onSurface),
                textAlign: TextAlign.center,
              )
                  .animate(delay: 200.ms)
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.2, end: 0),
              const SizedBox(height: AppDimensions.spacingSm),
              Text(
                slide.description,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              )
                  .animate(delay: 300.ms)
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.2, end: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator(AppColorsExtension colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_slides.length, (index) {
        final isActive = index == _currentPage;

        return AnimatedContainer(
          duration: AppConstants.mediumAnimation,
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXs),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            gradient: isActive ? AppColors.brandGradient : null,
            color: isActive ? null : colors.outline,
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isLastPage = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spacingXl,
                AppDimensions.spacingSm,
                AppDimensions.spacingSm,
                AppDimensions.spacingXs,
              ),
              child: Row(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: AppColors.brandGradient,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
                        ),
                        child: const Icon(
                          Icons.local_shipping_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingSm),
                      Text(
                        AppStrings.appName,
                        style: AppTextStyles.headlineSmall.copyWith(color: colors.onSurface),
                      ),
                    ],
                  ),
                  const Spacer(),
                  TextButtonWidget(
                    text: AppStrings.skip,
                    onPressed: _skipOnboarding,
                    textColor: colors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: _buildSlide,
              ),
            ),
            _buildPageIndicator(colors),
            const SizedBox(height: AppDimensions.spacingXl),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXl),
              child: GradientButton(
                text: isLastPage ? 'Get Started' : AppStrings.next,
                onPressed: _nextPage,
                trailingIcon: isLastPage ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
              )
                  .animate(delay: 200.ms)
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.2, end: 0),
            ),
            const SizedBox(height: AppDimensions.spacingXl),
          ],
        ),
      ),
    );
  }
}

class OnboardingSlide {
  final String title;
  final String description;
  final IconData icon;
  final String? lottieAsset;

  OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
    this.lottieAsset,
  });
}
