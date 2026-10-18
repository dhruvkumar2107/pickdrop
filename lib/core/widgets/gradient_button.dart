import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../constants/colors.dart';
import '../constants/dimensions.dart';

/// Full-width CTA button with the brand gradient, loading and disabled states.
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Gradient? gradient;
  final Color? foregroundColor;
  final TextStyle? textStyle;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.leadingIcon,
    this.trailingIcon,
    this.height = AppDimensions.buttonHeightLg,
    this.borderRadius = AppDimensions.radiusMd,
    this.padding,
    this.gradient,
    this.foregroundColor,
    this.textStyle,
  });

  bool get _enabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fg = foregroundColor ?? colors.onPrimary;

    final child = isLoading
        ? SizedBox(
            width: AppDimensions.iconSm,
            height: AppDimensions.iconSm,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          )
        : Row(
            mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leadingIcon != null) ...[
                Icon(leadingIcon, size: AppDimensions.iconSm, color: fg),
                const SizedBox(width: AppDimensions.spacingSm),
              ],
              Text(
                text,
                style: (textStyle ??
                        const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ))
                    .copyWith(color: fg),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: AppDimensions.spacingSm),
                Icon(trailingIcon, size: AppDimensions.iconSm, color: fg),
              ],
            ],
          );

    return AnimatedOpacity(
      duration: AppConstants.shortAnimation,
      opacity: _enabled ? 1 : 0.55,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Ink(
            width: isFullWidth ? double.infinity : null,
            height: height,
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: AppDimensions.spacingLg),
            decoration: BoxDecoration(
              gradient: _enabled
                  ? (gradient ?? AppColors.brandGradient)
                  : LinearGradient(colors: [colors.outline, colors.outline]),
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: _enabled
                  ? [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              widthFactor: 1,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
