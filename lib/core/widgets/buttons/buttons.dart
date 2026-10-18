import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../constants/app_constants.dart';
import '../../constants/colors.dart';
import '../../constants/dimensions.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? height;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.leadingIcon,
    this.trailingIcon,
    this.backgroundColor,
    this.foregroundColor,
    this.height,
    this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leadingIcon != null) ...[
          Icon(leadingIcon, size: AppDimensions.iconSm),
          const SizedBox(width: AppDimensions.spacingSm),
        ],
        if (isLoading)
          SizedBox(
            width: AppDimensions.iconSm,
            height: AppDimensions.iconSm,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor ?? AppColors.onPrimary),
            ),
          )
        else
          Text(text, style: TextStyle(color: foregroundColor ?? AppColors.onPrimary)),
        if (trailingIcon != null && !isLoading) ...[
          const SizedBox(width: AppDimensions.spacingSm),
          Icon(trailingIcon, size: AppDimensions.iconSm),
        ],
      ],
    );

    return AnimatedContainer(
      duration: AppConstants.shortAnimation,
      curve: Curves.easeInOut,
      width: isFullWidth ? double.infinity : null,
      height: height ?? AppDimensions.buttonHeightMd,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.primary,
          foregroundColor: foregroundColor ?? AppColors.onPrimary,
          elevation: AppDimensions.elevationNone,
          shadowColor: AppColors.transparent,
          padding: padding ??
              const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingLg,
                vertical: AppDimensions.spacingMd,
              ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? AppDimensions.radiusMd),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: child,
      ),
    ).animate(target: isLoading ? 0 : 1).scale(
          duration: AppConstants.shortAnimation,
          begin: const Offset(0.98, 0.98),
          end: const Offset(1.0, 1.0),
        );
  }
}

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? height;
  final double? borderRadius;

  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.leadingIcon,
    this.trailingIcon,
    this.backgroundColor,
    this.foregroundColor,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height ?? AppDimensions.buttonHeightMd,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.secondary,
          foregroundColor: foregroundColor ?? AppColors.onSecondary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingLg,
            vertical: AppDimensions.spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? AppDimensions.radiusMd),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: AppDimensions.iconSm,
                height: AppDimensions.iconSm,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(foregroundColor ?? AppColors.onSecondary),
                ),
              )
            : Row(
                mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (leadingIcon != null) ...[
                    Icon(leadingIcon, size: AppDimensions.iconSm),
                    const SizedBox(width: AppDimensions.spacingSm),
                  ],
                  Text(text),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: AppDimensions.spacingSm),
                    Icon(trailingIcon, size: AppDimensions.iconSm),
                  ],
                ],
              ),
      ),
    );
  }
}

class OutlinedPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final Color? borderColor;
  final Color? textColor;
  final double? height;
  final double? borderRadius;

  const OutlinedPrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.leadingIcon,
    this.trailingIcon,
    this.borderColor,
    this.textColor,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height ?? AppDimensions.buttonHeightMd,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor ?? AppColors.primary,
          side: BorderSide(color: borderColor ?? AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingLg,
            vertical: AppDimensions.spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? AppDimensions.radiusMd),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: AppDimensions.iconSm,
                height: AppDimensions.iconSm,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor ?? AppColors.primary),
                ),
              )
            : Row(
                mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (leadingIcon != null) ...[
                    Icon(leadingIcon, size: AppDimensions.iconSm),
                    const SizedBox(width: AppDimensions.spacingSm),
                  ],
                  Text(text),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: AppDimensions.spacingSm),
                    Icon(trailingIcon, size: AppDimensions.iconSm),
                  ],
                ],
              ),
      ),
    );
  }
}

class TextButtonWidget extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? textColor;
  final FontWeight? fontWeight;
  final double? fontSize;
  final bool underline;

  const TextButtonWidget({
    super.key,
    required this.text,
    this.onPressed,
    this.textColor,
    this.fontWeight,
    this.fontSize,
    this.underline = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: textColor ?? AppColors.primary,
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: fontSize ?? 14,
          fontWeight: fontWeight ?? FontWeight.w500,
          color: textColor ?? AppColors.primary,
          decoration: underline ? TextDecoration.underline : TextDecoration.none,
        ),
      ),
    );
  }
}

class IconButtonWidget extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? backgroundColor;
  final double? size;
  final double? iconSize;
  final String? tooltip;
  final EdgeInsetsGeometry? padding;

  const IconButtonWidget({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.backgroundColor,
    this.size,
    this.iconSize,
    this.tooltip,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: iconSize ?? AppDimensions.iconMd, color: color ?? AppColors.onSurface),
      style: IconButton.styleFrom(
        backgroundColor: backgroundColor ?? AppColors.transparent,
        padding: padding ?? EdgeInsets.all(AppDimensions.spacingSm),
        minimumSize: Size(size ?? AppDimensions.iconLg, size ?? AppDimensions.iconLg),
      ),
      tooltip: tooltip,
    );
  }
}

class ToggleButton extends StatelessWidget {
  final bool isOn;
  final String labelOn;
  final String labelOff;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final Color? inactiveColor;
  final IconData? iconOn;
  final IconData? iconOff;

  const ToggleButton({
    super.key,
    required this.isOn,
    required this.labelOn,
    required this.labelOff,
    this.onChanged,
    this.activeColor,
    this.inactiveColor,
    this.iconOn,
    this.iconOff,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged?.call(!isOn),
      child: AnimatedContainer(
        duration: AppConstants.mediumAnimation,
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingLg,
          vertical: AppDimensions.spacingMd,
        ),
        decoration: BoxDecoration(
          color: isOn ? (activeColor ?? AppColors.primary) : (inactiveColor ?? AppColors.surfaceVariant),
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(
            color: isOn ? (activeColor ?? AppColors.primary) : AppColors.outline,
            width: 1.5,
          ),
          boxShadow: isOn
              ? [
                  BoxShadow(
                    color: (activeColor ?? AppColors.primary).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconOn != null || iconOff != null) ...[
              Icon(
                isOn ? iconOn : iconOff,
                size: AppDimensions.iconSm,
                color: isOn ? AppColors.onPrimary : AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: AppDimensions.spacingSm),
            ],
            Text(
              isOn ? labelOn : labelOff,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isOn ? AppColors.onPrimary : AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SocialLoginButton extends StatelessWidget {
  final String text;
  final String assetIcon;
  final VoidCallback? onPressed;
  final bool isLoading;

  const SocialLoginButton({
    super.key,
    required this.text,
    required this.assetIcon,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppDimensions.buttonHeightMd,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.onSurface,
          side: const BorderSide(color: AppColors.outline, width: 1),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingLg,
            vertical: AppDimensions.spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: AppDimensions.iconSm,
                height: AppDimensions.iconSm,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(assetIcon, width: 24, height: 24),
                  const SizedBox(width: AppDimensions.spacingMd),
                  Text(
                    text,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}