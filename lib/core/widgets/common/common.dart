import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

import '../../constants/app_constants.dart';
import '../../constants/colors.dart';
import '../../constants/dimensions.dart';
import '../buttons/buttons.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData? icon;
  final String? actionText;
  final VoidCallback? onAction;
  final Widget? customAction;
  final String? lottieAsset;

  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.actionText,
    this.onAction,
    this.customAction,
    this.lottieAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (lottieAsset != null)
              SizedBox(
                width: 140,
                height: 140,
                child: Lottie.asset(
                  lottieAsset!,
                  width: 140,
                  height: 140,
                  repeat: true,
                  fit: BoxFit.contain,
                  frameRate: FrameRate.max,
                ),
              )
                  .animate()
                  .fadeIn(duration: AppConstants.mediumAnimation)
                  .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0))
            else
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingXl),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Icon(
                  icon ?? Icons.inbox_outlined,
                  size: 64,
                  color: AppColors.primary,
                ),
              )
                  .animate()
                  .fadeIn(duration: AppConstants.mediumAnimation)
                  .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0)),
            const SizedBox(height: AppDimensions.spacingLg),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
              textAlign: TextAlign.center,
            )
                .animate(delay: 200.ms)
                .fadeIn(duration: AppConstants.mediumAnimation)
                .slideY(begin: 0.2, end: 0),
            const SizedBox(height: AppDimensions.spacingSm),
            Text(
              message,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            )
                .animate(delay: 300.ms)
                .fadeIn(duration: AppConstants.mediumAnimation)
                .slideY(begin: 0.2, end: 0),
            if (actionText != null || customAction != null) ...[
              const SizedBox(height: AppDimensions.spacingLg),
              (customAction ??
                      PrimaryButton(
                        text: actionText!,
                        onPressed: onAction,
                        isFullWidth: false,
                      ))
                  .animate(delay: 400.ms)
                  .fadeIn(duration: AppConstants.mediumAnimation)
                  .slideY(begin: 0.2, end: 0),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final IconData? icon;
  final String? lottieAsset;

  const ErrorState({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
    this.icon,
    this.lottieAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (lottieAsset != null)
              SizedBox(
                width: 140,
                height: 140,
                child: Lottie.asset(
                  lottieAsset!,
                  width: 140,
                  height: 140,
                  repeat: true,
                  fit: BoxFit.contain,
                  frameRate: FrameRate.max,
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingXl),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Icon(
                  icon ?? Icons.error_outline,
                  size: 64,
                  color: AppColors.error,
                ),
              ),
            const SizedBox(height: AppDimensions.spacingLg),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingSm),
            Text(
              message,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppDimensions.spacingLg),
              PrimaryButton(
                text: 'Try Again',
                onPressed: onRetry,
                isFullWidth: false,
                leadingIcon: Icons.refresh,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class NoInternetState extends StatelessWidget {
  final VoidCallback? onRetry;

  const NoInternetState({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      title: 'No Internet Connection',
      message: 'Please check your connection and try again',
      onRetry: onRetry,
      icon: Icons.wifi_off,
      lottieAsset: 'assets/animations/error.json',
    );
  }
}

class DividerWidget extends StatelessWidget {
  final double height;
  final Color? color;
  final double? indent;
  final double? endIndent;

  const DividerWidget({
    super.key,
    this.height = 1,
    this.color,
    this.indent,
    this.endIndent,
  });

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: height,
      thickness: height,
      color: color ?? AppColors.outlineVariant,
      indent: indent,
      endIndent: endIndent,
    );
  }
}

class SpacerWidget extends StatelessWidget {
  final double height;

  const SpacerWidget({super.key, this.height = AppDimensions.spacingMd});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: height);
  }
}

class HorizontalSpacer extends StatelessWidget {
  final double width;

  const HorizontalSpacer({super.key, this.width = AppDimensions.spacingMd});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width);
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final bool showDivider;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            ?action,
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppDimensions.spacingXs),
          Text(
            subtitle!,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
        if (showDivider) ...[
          const SizedBox(height: AppDimensions.spacingSm),
          const DividerWidget(),
        ],
      ],
    );
  }
}

class BadgeWidget extends StatelessWidget {
  final String text;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const BadgeWidget({
    super.key,
    required this.text,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingSm,
            vertical: 4,
          ),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primaryContainer,
        borderRadius: borderRadius ?? BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: fontSize ?? 11,
          fontWeight: FontWeight.w600,
          color: textColor ?? AppColors.primary,
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String status;
  final bool isActive;

  const StatusBadge({
    super.key,
    required this.status,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    switch (status.toUpperCase()) {
      case 'ONLINE':
      case 'ACTIVE':
      case 'DELIVERED':
      case 'COMPLETED':
        backgroundColor = AppColors.successLight;
        textColor = AppColors.success;
        break;
      case 'OFFLINE':
      case 'INACTIVE':
      case 'CANCELLED':
        backgroundColor = AppColors.errorLight;
        textColor = AppColors.error;
        break;
      case 'PENDING':
      case 'SEARCHING':
      case 'DRIVER_ASSIGNED':
      case 'ARRIVED':
      case 'PICKED_UP':
      case 'IN_TRANSIT':
        backgroundColor = AppColors.infoLight;
        textColor = AppColors.info;
        break;
      default:
        backgroundColor = AppColors.surfaceVariant;
        textColor = AppColors.onSurfaceVariant;
    }

    return BadgeWidget(
      text: status.replaceAll('_', ' '),
      backgroundColor: backgroundColor,
      textColor: textColor,
    );
  }
}

class AvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;

  const AvatarWidget({
    super.key,
    this.imageUrl,
    this.name,
    this.radius = 24,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name != null
        ? name!.split(' ').map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').take(2).join()
        : '?';

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? AppColors.primaryContainer,
      backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
      child: imageUrl == null
          ? Text(
              initials,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: radius * 0.7,
                fontWeight: FontWeight.w600,
                color: textColor ?? AppColors.primary,
              ),
            )
          : null,
    );
  }
}

class RatingWidget extends StatelessWidget {
  final double rating;
  final int maxRating;
  final double size;
  final Color? filledColor;
  final Color? emptyColor;
  final bool showValue;
  final VoidCallback? onTap;

  const RatingWidget({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.size = 20,
    this.filledColor,
    this.emptyColor,
    this.showValue = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(maxRating, (index) {
            final isFilled = index < rating.floor();
            final isHalf = index == rating.floor() && rating % 1 >= 0.5;

            return Icon(
              isFilled
                  ? Icons.star
                  : (isHalf ? Icons.star_half : Icons.star_border),
              size: size,
              color: isFilled || isHalf
                  ? (filledColor ?? Colors.amber)
                  : (emptyColor ?? AppColors.outline),
            );
          }),
          if (showValue) ...[
            const SizedBox(width: AppDimensions.spacingXs),
            Text(
              rating.toStringAsFixed(1),
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class StepperWidget extends StatelessWidget {
  final List<String> steps;
  final int currentStep;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? completedColor;
  final bool showNumbers;

  const StepperWidget({
    super.key,
    required this.steps,
    required this.currentStep,
    this.activeColor,
    this.inactiveColor,
    this.completedColor,
    this.showNumbers = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(steps.length, (index) {
        final isCompleted = index < currentStep;
        final isCurrent = index == currentStep;
        final isLast = index == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCompleted || isCurrent
                        ? (isCompleted ? (completedColor ?? AppColors.success) : (activeColor ?? AppColors.primary))
                        : (inactiveColor ?? AppColors.outline),
                    borderRadius: BorderRadius.circular(12),
                    border: isCurrent && !isCompleted
                        ? Border.all(color: activeColor ?? AppColors.primary, width: 3)
                        : null,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, size: 14, color: AppColors.onPrimary)
                        : (showNumbers
                            ? Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isCurrent ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                                ),
                              )
                            : null),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: isCompleted ? (completedColor ?? AppColors.success) : (inactiveColor ?? AppColors.outline),
                  ),
              ],
            ),
            const SizedBox(width: AppDimensions.spacingMd),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.spacingLg),
                child: Text(
                  steps[index],
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                    color: isCompleted || isCurrent ? AppColors.onSurface : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class AnimatedCounter extends StatelessWidget {
  final int value;
  final Duration duration;
  final TextStyle? style;
  final String? prefix;
  final String? suffix;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 1000),
    this.style,
    this.prefix,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: duration,
      builder: (context, value, child) {
        return Text(
          '${prefix ?? ''}$value${suffix ?? ''}',
          style: style ??
              const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
        );
      },
    );
  }
}

class PulseAnimation extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;

  const PulseAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1000),
    this.minScale = 0.95,
    this.maxScale = 1.05,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: minScale, end: maxScale),
      duration: duration,
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: child,
      onEnd: () {
        // Restart animation
      },
    );
  }
}

class FadeInWidget extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Duration? delay;
  final double? beginOffset;

  const FadeInWidget({
    super.key,
    required this.child,
    this.duration = AppConstants.mediumAnimation,
    this.delay,
    this.beginOffset,
  });

  @override
  Widget build(BuildContext context) {
    return child.animate(delay: delay).fadeIn(duration: duration).slideY(
          begin: beginOffset ?? 0.2,
          end: 0,
          duration: duration,
        );
  }
}

class ScaleOnTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;
  final Duration duration;

  const ScaleOnTap({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.95,
    this.duration = AppConstants.shortAnimation,
  });

  @override
  State<ScaleOnTap> createState() => _ScaleOnTapState();
}

class _ScaleOnTapState extends State<ScaleOnTap> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleFactor).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(scale: _scaleAnimation.value, child: child),
        child: widget.child,
      ),
    );
  }
}