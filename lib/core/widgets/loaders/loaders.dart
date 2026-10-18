import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../constants/colors.dart';
import '../../constants/dimensions.dart';

class AppLoader extends StatelessWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const AppLoader({
    super.key,
    this.size = 24,
    this.color,
    this.strokeWidth = 3,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(color ?? AppColors.primary),
      ),
    );
  }
}

class FullScreenLoader extends StatelessWidget {
  final String? message;
  final Color? backgroundColor;

  const FullScreenLoader({
    super.key,
    this.message,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? AppColors.surface.withValues(alpha: 0.9),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLoader(size: 48, strokeWidth: 4),
            if (message != null) ...[
              const SizedBox(height: AppDimensions.spacingMd),
              Text(
                message!,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class OverlayLoader extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const OverlayLoader({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: AppColors.surface.withValues(alpha: 0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppLoader(size: 40, strokeWidth: 3),
                    if (message != null) ...[
                      const SizedBox(height: AppDimensions.spacingMd),
                      Text(
                        message!,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class ButtonLoader extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const ButtonLoader({
    super.key,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const AppLoader(size: 20, strokeWidth: 2, color: AppColors.onPrimary)
        : child;
  }
}

class ShimmerLoader extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerLoader({
    super.key,
    required this.child,
    required this.isLoading,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return child;

    return Shimmer.fromColors(
      baseColor: baseColor ?? AppColors.secondaryContainer,
      highlightColor: highlightColor ?? AppColors.surfaceVariant,
      child: child,
    );
  }
}

class SkeletonCard extends StatelessWidget {
  final double? height;
  final double? width;
  final BorderRadius? borderRadius;

  const SkeletonCard({
    super.key,
    this.height,
    this.width,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer,
        borderRadius: borderRadius ?? BorderRadius.circular(AppDimensions.radiusLg),
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final double spacing;

  const SkeletonList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 100,
    this.spacing = AppDimensions.spacingMd,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, _) => SizedBox(height: spacing),
      itemBuilder: (context, index) => SkeletonCard(height: itemHeight),
    );
  }
}

class SkeletonProfile extends StatelessWidget {
  const SkeletonProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SkeletonCard(
          height: 80,
          width: 80,
          borderRadius: BorderRadius.circular(40),
        ),
        const SizedBox(height: AppDimensions.spacingMd),
        SkeletonCard(height: 20, width: 150),
        const SizedBox(height: AppDimensions.spacingXs),
        SkeletonCard(height: 16, width: 100),
        const SizedBox(height: AppDimensions.spacingLg),
        SkeletonCard(height: 50),
        const SizedBox(height: AppDimensions.spacingMd),
        SkeletonCard(height: 50),
        const SizedBox(height: AppDimensions.spacingMd),
        SkeletonCard(height: 50),
      ],
    );
  }
}

class SkeletonVehicleCard extends StatelessWidget {
  const SkeletonVehicleCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonCard(
      height: 160,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
    );
  }
}

class SkeletonTripCard extends StatelessWidget {
  const SkeletonTripCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonCard(
      height: 140,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
    );
  }
}

class SkeletonAddressCard extends StatelessWidget {
  const SkeletonAddressCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonCard(
      height: 80,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
    );
  }
}