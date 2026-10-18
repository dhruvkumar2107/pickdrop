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
import '../../../../core/widgets/loaders/loaders.dart';
import '../providers/auth_providers.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    var onboardingSeen = false;
    try {
      final prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(milliseconds: 1000));
      onboardingSeen =
          prefs.getBool(AppConstants.keyOnboardingSeen) ?? false;
    } catch (_) {
      onboardingSeen = false;
    }

    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    if (!onboardingSeen) {
      context.go(RouteNames.onboarding);
      return;
    }

    final result = await ref.read(getCurrentUserUseCaseProvider).call();
    if (!mounted) return;

    result.fold(
      (_) => context.go(RouteNames.phoneLogin),
      (user) {
        if (user.displayName == null || user.displayName!.isEmpty) {
          context.go(RouteNames.roleSelection);
        } else if (user.role == AppConstants.roleDriver) {
          context.go(RouteNames.driverHome);
        } else {
          context.go(RouteNames.customerHome);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colors.primary, colors.primaryEnd],
              ),
            ),
            child: const SizedBox.expand(),
          ),
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                color: colors.onPrimary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -70,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                color: colors.onPrimary.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Lottie.asset(
                    'assets/animations/splash_logo.json',
                    width: 140,
                    height: 140,
                    repeat: true,
                    fit: BoxFit.contain,
                    frameRate: FrameRate.max,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 800.ms)
                    .scale(
                      begin: const Offset(0.7, 0.7),
                      end: const Offset(1.0, 1.0),
                      duration: 800.ms,
                      curve: Curves.elasticOut,
                    ),
                const SizedBox(height: AppDimensions.spacingLg),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: colors.onPrimary,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadow.withValues(alpha: 0.3),
                        blurRadius: 32,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.local_shipping_rounded,
                    size: 60,
                    color: colors.primary,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 800.ms)
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1.0, 1.0),
                      duration: 800.ms,
                      curve: Curves.elasticOut,
                    ),
                const SizedBox(height: AppDimensions.spacingXl),
                Text(
                  AppStrings.appName,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: colors.onPrimary,
                    letterSpacing: -0.5,
                    height: 1.15,
                  ),
                )
                    .animate(delay: 300.ms)
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.3, end: 0),
                const SizedBox(height: AppDimensions.spacingSm),
                Text(
                  AppStrings.appTagline,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: colors.onPrimary.withValues(alpha: 0.9),
                    letterSpacing: 0.2,
                  ),
                )
                    .animate(delay: 450.ms)
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.3, end: 0),
                const SizedBox(height: AppDimensions.spacingXxl),
                AppLoader(
                  size: 36,
                  color: colors.onPrimary,
                  strokeWidth: 3,
                ).animate(delay: 700.ms).fadeIn(duration: 500.ms),
                const Spacer(),
                Text(
                  'v${AppConstants.appVersion}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colors.onPrimary.withValues(alpha: 0.75),
                  ),
                ).animate(delay: 900.ms).fadeIn(duration: 500.ms),
                const SizedBox(height: AppDimensions.spacingXl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
