import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';

import '../constants/colors.dart';
import '../theme/design_tokens.dart';
import 'cards.dart';
import 'design_system.dart';

/// Skeleton loader for cards
class PDSkeletonCard extends StatelessWidget {
  final double? height;
  final double? width;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? margin;

  const PDSkeletonCard({
    super.key,
    this.height,
    this.width,
    this.borderRadius,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? DesignTokens.black700 : DesignTokens.white200,
      highlightColor: isDark ? DesignTokens.black600 : DesignTokens.white300,
      child: Container(
        height: height,
        width: width,
        margin: margin,
        decoration: BoxDecoration(
          color: isDark ? DesignTokens.black700 : DesignTokens.white200,
          borderRadius: borderRadius ?? BorderRadius.circular(DesignTokens.radiusCard),
        ),
      ),
    );
  }
}

/// Skeleton loader for list items
class PDSkeletonListItem extends StatelessWidget {
  final bool hasLeading;
  final bool hasTrailing;
  final int lines;
  final double? height;

  const PDSkeletonListItem({
    super.key,
    this.hasLeading = true,
    this.hasTrailing = false,
    this.lines = 2,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? DesignTokens.black700 : DesignTokens.white200,
      highlightColor: isDark ? DesignTokens.black600 : DesignTokens.white300,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: DesignTokens.spacingSm,
          horizontal: DesignTokens.spacingMd,
        ),
        child: Row(
          children: [
            if (hasLeading) ...[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? DesignTokens.black700 : DesignTokens.white200,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
              ),
              SizedBox(width: DesignTokens.spacingMd),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(lines, (index) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: DesignTokens.spacingXs),
                    child: Container(
                      height: index == 0 ? 16 : 12,
                      width: index == 0 ? double.infinity : 200,
                      decoration: BoxDecoration(
                        color: isDark ? DesignTokens.black700 : DesignTokens.white200,
                        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                      ),
                    ),
                  );
                }),
              ),
            ),
            if (hasTrailing) ...[
              SizedBox(width: DesignTokens.spacingMd),
              Container(
                width: 60,
                height: 20,
                decoration: BoxDecoration(
                  color: isDark ? DesignTokens.black700 : DesignTokens.white200,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Skeleton for vehicle cards
class PDSkeletonVehicleCard extends StatelessWidget {
  const PDSkeletonVehicleCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? DesignTokens.black700 : DesignTokens.white200,
      highlightColor: isDark ? DesignTokens.black600 : DesignTokens.white300,
      child: PDCard(
        variant: PDCardVariant.elevated,
        padding: EdgeInsets.zero,
        child: Container(
          padding: EdgeInsets.all(DesignTokens.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isDark ? DesignTokens.black700 : DesignTokens.white200,
                      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                    ),
                  ),
                  SizedBox(width: DesignTokens.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 120,
                          height: 18,
                          decoration: BoxDecoration(
                            color: isDark ? DesignTokens.black700 : DesignTokens.white200,
                            borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                          ),
                        ),
                        SizedBox(height: DesignTokens.space1),
                        Container(
                          width: 80,
                          height: 12,
                          decoration: BoxDecoration(
                            color: isDark ? DesignTokens.black700 : DesignTokens.white200,
                            borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 60,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isDark ? DesignTokens.black700 : DesignTokens.white200,
                      borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                    ),
                  ),
                ],
              ),
              SizedBox(height: DesignTokens.spacingMd),
              Row(
                children: List.generate(4, (index) => Expanded(
                  child: Container(
                    height: 28,
                    margin: EdgeInsets.only(right: index < 3 ? DesignTokens.spacingSm : 0),
                    decoration: BoxDecoration(
                      color: isDark ? DesignTokens.black700 : DesignTokens.white200,
                      borderRadius: BorderRadius.circular(DesignTokens.radiusChip),
                    ),
                  ),
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton for driver card
class PDSkeletonDriverCard extends StatelessWidget {
  const PDSkeletonDriverCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? DesignTokens.black700 : DesignTokens.white200,
      highlightColor: isDark ? DesignTokens.black600 : DesignTokens.white300,
      child: PDCard(
        variant: PDCardVariant.elevated,
        padding: EdgeInsets.all(DesignTokens.spacingMd),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isDark ? DesignTokens.black700 : DesignTokens.white200,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: DesignTokens.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 140,
                    height: 18,
                    decoration: BoxDecoration(
                      color: isDark ? DesignTokens.black700 : DesignTokens.white200,
                      borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                    ),
                  ),
                  SizedBox(height: DesignTokens.space1),
                  Container(
                    width: 180,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isDark ? DesignTokens.black700 : DesignTokens.white200,
                      borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                    ),
                  ),
                  SizedBox(height: DesignTokens.space1),
                  Container(
                    width: 100,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isDark ? DesignTokens.black700 : DesignTokens.white200,
                      borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? DesignTokens.black700 : DesignTokens.white200,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for trip card
class PDSkeletonTripCard extends StatelessWidget {
  const PDSkeletonTripCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? DesignTokens.black700 : DesignTokens.white200,
      highlightColor: isDark ? DesignTokens.black600 : DesignTokens.white300,
      child: PDCard(
        variant: PDCardVariant.elevated,
        padding: EdgeInsets.all(DesignTokens.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    width: 140,
                    height: 18,
                    decoration: BoxDecoration(
                      color: isDark ? DesignTokens.black700 : DesignTokens.white200,
                      borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                    ),
                  ),
                ),
                Container(
                  width: 80,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isDark ? DesignTokens.black700 : DesignTokens.white200,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusChip),
                  ),
                ),
              ],
            ),
            SizedBox(height: DesignTokens.spacingMd),
            ...List.generate(2, (index) => Padding(
              padding: EdgeInsets.only(bottom: DesignTokens.spacingSm),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isDark ? DesignTokens.black700 : DesignTokens.white200,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: DesignTokens.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 60,
                          height: 10,
                          decoration: BoxDecoration(
                            color: isDark ? DesignTokens.black700 : DesignTokens.white200,
                            borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                          ),
                        ),
                        SizedBox(height: DesignTokens.space1),
                        Container(
                          width: 200,
                          height: 12,
                          decoration: BoxDecoration(
                            color: isDark ? DesignTokens.black700 : DesignTokens.white200,
                            borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
            SizedBox(height: DesignTokens.spacingMd),
            Divider(color: isDark ? DesignTokens.black600 : DesignTokens.white300, height: 1),
            SizedBox(height: DesignTokens.spacingSm),
            Row(
              children: [
                Container(
                  width: 80,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isDark ? DesignTokens.black700 : DesignTokens.white200,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                  ),
                ),
                SizedBox(width: DesignTokens.spacingMd),
                Container(
                  width: 100,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isDark ? DesignTokens.black700 : DesignTokens.white200,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                  ),
                ),
                Spacer(),
                Container(
                  width: 70,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isDark ? DesignTokens.black700 : DesignTokens.white200,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state widget
class PDEmptyState extends StatelessWidget {
  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? customAction;
  final double iconSize;

  const PDEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    this.customAction,
    this.iconSize = 64,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: iconSize * 0.6,
                color: colors.primary,
              ),
            ).animate().fadeIn(
              duration: DesignTokens.durationNormal,
            ).scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1, 1),
              duration: DesignTokens.durationNormal,
              curve: DesignTokens.springGentle,
            ),
            SizedBox(height: DesignTokens.spacingLg),
            Text(
              title,
              style: TokenTextStyles.titleLarge(
                color: colors.onSurface,
                weight: DesignTokens.wSemiBold,
              ),
              textAlign: TextAlign.center,
            ).animate(delay: 100.ms).fadeIn(
              duration: DesignTokens.durationNormal,
            ).slideY(begin: 0.2, end: 0),
            if (message != null) ...[
              SizedBox(height: DesignTokens.spacingSm),
              Text(
                message!,
                style: TokenTextStyles.bodyMedium(color: colors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ).animate(delay: 200.ms).fadeIn(
                duration: DesignTokens.durationNormal,
              ).slideY(begin: 0.2, end: 0),
            ],
            if (actionLabel != null || customAction != null) ...[
              SizedBox(height: DesignTokens.spacingXl),
              (customAction ?? PDButton(
                label: actionLabel!,
                variant: PDButtonVariant.primary,
                size: PDButtonSize.md,
                isFullWidth: false,
                onPressed: onAction,
              )).animate(delay: 300.ms).fadeIn(
                duration: DesignTokens.durationNormal,
              ).slideY(begin: 0.2, end: 0),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error state widget
class PDErrorState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool showRetry;

  const PDErrorState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.error_outline_rounded,
    this.actionLabel,
    this.onAction,
    this.showRetry = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: colors.error,
              ),
            ).animate().fadeIn(
              duration: DesignTokens.durationNormal,
            ).shake(duration: 500.ms),
            SizedBox(height: DesignTokens.spacingLg),
            Text(
              title,
              style: TokenTextStyles.titleLarge(
                color: colors.onSurface,
                weight: DesignTokens.wSemiBold,
              ),
              textAlign: TextAlign.center,
            ).animate(delay: 100.ms).fadeIn(
              duration: DesignTokens.durationNormal,
            ).slideY(begin: 0.2, end: 0),
            SizedBox(height: DesignTokens.spacingSm),
            Text(
              message,
              style: TokenTextStyles.bodyMedium(color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ).animate(delay: 200.ms).fadeIn(
              duration: DesignTokens.durationNormal,
            ).slideY(begin: 0.2, end: 0),
            if (showRetry && actionLabel != null && onAction != null) ...[
              SizedBox(height: DesignTokens.spacingXl),
              PDButton(
                label: actionLabel!,
                variant: PDButtonVariant.primary,
                size: PDButtonSize.md,
                isFullWidth: false,
                leadingIcon: Icons.refresh_rounded,
                onPressed: onAction,
              ).animate(delay: 300.ms).fadeIn(
                duration: DesignTokens.durationNormal,
              ).slideY(begin: 0.2, end: 0),
            ],
          ],
        ),
      ),
    );
  }
}

/// Success state widget
class PDSuccessState extends StatelessWidget {
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  const PDSuccessState({
    super.key,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.check_circle_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: colors.success,
              ),
            ).animate().fadeIn(
              duration: DesignTokens.durationNormal,
            ).scale(
              begin: const Offset(0.5, 0.5),
              end: const Offset(1, 1),
              duration: 600.ms,
              curve: Curves.elasticOut,
            ),
            SizedBox(height: DesignTokens.spacingLg),
            Text(
              title,
              style: TokenTextStyles.titleLarge(
                color: colors.onSurface,
                weight: DesignTokens.wSemiBold,
              ),
              textAlign: TextAlign.center,
            ).animate(delay: 100.ms).fadeIn(
              duration: DesignTokens.durationNormal,
            ).slideY(begin: 0.2, end: 0),
            if (message != null) ...[
              SizedBox(height: DesignTokens.spacingSm),
              Text(
                message!,
                style: TokenTextStyles.bodyMedium(color: colors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ).animate(delay: 200.ms).fadeIn(
                duration: DesignTokens.durationNormal,
              ).slideY(begin: 0.2, end: 0),
            ],
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: DesignTokens.spacingXl),
              PDButton(
                label: actionLabel!,
                variant: PDButtonVariant.success,
                size: PDButtonSize.md,
                isFullWidth: false,
                onPressed: onAction,
              ).animate(delay: 300.ms).fadeIn(
                duration: DesignTokens.durationNormal,
              ).slideY(begin: 0.2, end: 0),
            ],
          ],
        ),
      ),
    );
  }
}

/// A loading indicator with custom styling
class PDLoader extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color? color;
  final String? message;

  const PDLoader({
    super.key,
    this.size = 24,
    this.strokeWidth = 3,
    this.color,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final loaderColor = color ?? colors.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: strokeWidth,
            valueColor: AlwaysStoppedAnimation<Color>(loaderColor),
          ),
        ),
        if (message != null) ...[
          SizedBox(height: DesignTokens.spacingMd),
          Text(
            message!,
            style: TokenTextStyles.bodyMedium(color: colors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// A page-level loading state
class PDPageLoader extends StatelessWidget {
  final String? message;

  const PDPageLoader({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),
          ),
          if (message != null) ...[
            SizedBox(height: DesignTokens.spacingLg),
            Text(
              message!,
              style: TokenTextStyles.bodyLarge(color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}