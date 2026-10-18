import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../constants/colors.dart';
import '../theme/design_tokens.dart';

/// A premium button with multiple variants and sizes
class PDButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final PDButtonVariant variant;
  final PDButtonSize size;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  /// @deprecated Use label instead
  @Deprecated('Use label instead')
  final String? text;

  const PDButton({
    super.key,
    String? label,
    this.onPressed,
    this.variant = PDButtonVariant.primary,
    this.size = PDButtonSize.md,
    this.isLoading = false,
    this.isFullWidth = true,
    this.leadingIcon,
    this.trailingIcon,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.borderRadius,
    @Deprecated('Use label instead') this.text,
  }) : label = label ?? text ?? '';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    
    final bgColor = backgroundColor ?? _getBackgroundColor(colors);
    final fgColor = foregroundColor ?? _getForegroundColor(colors);
    final borderColor = variant == PDButtonVariant.outline ? colors.primary : Colors.transparent;
    
    final horizontalPadding = padding?.horizontal ?? _getHorizontalPadding();
    final verticalPadding = padding?.vertical ?? _getVerticalPadding();
    final buttonHeight = _getButtonHeight();
    final borderRadiusValue = borderRadius ?? BorderRadius.circular(DesignTokens.radiusButton);
    final textStyle = _getTextStyle(fgColor);
    
    final child = isLoading
        ? SizedBox(
            width: _getLoadingSize(),
            height: _getLoadingSize(),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fgColor),
            ),
          )
        : Row(
            mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leadingIcon != null) ...[
                Icon(leadingIcon, size: _getIconSize(), color: fgColor),
                SizedBox(width: DesignTokens.space2),
              ],
              Flexible(
                child: Text(
                  label,
                  style: textStyle,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailingIcon != null) ...[
                SizedBox(width: DesignTokens.space2),
                Icon(trailingIcon, size: _getIconSize(), color: fgColor),
              ],
            ],
          );

    return AnimatedContainer(
      duration: DesignTokens.durationFast,
      curve: DesignTokens.springSmooth,
      height: buttonHeight,
      width: isFullWidth ? double.infinity : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: borderRadiusValue,
          child: Ink(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            decoration: BoxDecoration(
              color: onPressed != null ? bgColor : bgColor.withValues(alpha: 0.5),
              borderRadius: borderRadiusValue,
              border: Border.all(
                color: onPressed != null ? borderColor : borderColor.withValues(alpha: 0.5),
                width: variant == PDButtonVariant.outline ? DesignTokens.borderMedium : 0,
              ),
              boxShadow: _getShadow(colors),
            ),
            child: child,
          ),
        ),
      ),
    ).animate(target: onPressed != null ? 1 : 0).scale(
      begin: const Offset(1, 1),
      end: const Offset(0.98, 0.98),
      duration: DesignTokens.durationFast,
    );
  }

  Color _getBackgroundColor(AppColorsExtension colors) {
    switch (variant) {
      case PDButtonVariant.primary:
        return colors.primary;
      case PDButtonVariant.secondary:
        return colors.secondary;
      case PDButtonVariant.outline:
        return Colors.transparent;
      case PDButtonVariant.ghost:
        return Colors.transparent;
      case PDButtonVariant.destructive:
        return colors.error;
      case PDButtonVariant.success:
        return colors.success;
    }
  }

  Color _getForegroundColor(AppColorsExtension colors) {
    switch (variant) {
      case PDButtonVariant.primary:
        return colors.onPrimary;
      case PDButtonVariant.secondary:
        return colors.onSecondary;
      case PDButtonVariant.outline:
        return colors.primary;
      case PDButtonVariant.ghost:
        return colors.primary;
      case PDButtonVariant.destructive:
        return Colors.white;
      case PDButtonVariant.success:
        return Colors.white;
    }
  }

  double _getHorizontalPadding() {
    switch (size) {
      case PDButtonSize.xs:
        return DesignTokens.space3;
      case PDButtonSize.sm:
        return DesignTokens.space4;
      case PDButtonSize.md:
        return DesignTokens.space6;
      case PDButtonSize.lg:
        return DesignTokens.space8;
      case PDButtonSize.xl:
        return DesignTokens.space10;
    }
  }

  double _getVerticalPadding() {
    switch (size) {
      case PDButtonSize.xs:
        return DesignTokens.space1;
      case PDButtonSize.sm:
        return DesignTokens.space2;
      case PDButtonSize.md:
        return DesignTokens.space3;
      case PDButtonSize.lg:
        return DesignTokens.space4;
      case PDButtonSize.xl:
        return DesignTokens.space5;
    }
  }

  double _getButtonHeight() {
    switch (size) {
      case PDButtonSize.xs:
        return DesignTokens.buttonHeightSm;
      case PDButtonSize.sm:
        return DesignTokens.buttonHeightSm;
      case PDButtonSize.md:
        return DesignTokens.buttonHeightMd;
      case PDButtonSize.lg:
        return DesignTokens.buttonHeightLg;
      case PDButtonSize.xl:
        return DesignTokens.buttonHeightXl;
    }
  }

  double _getLoadingSize() {
    switch (size) {
      case PDButtonSize.xs:
        return 16;
      case PDButtonSize.sm:
        return 20;
      case PDButtonSize.md:
        return 24;
      case PDButtonSize.lg:
        return 28;
      case PDButtonSize.xl:
        return 32;
    }
  }

  double _getIconSize() {
    switch (size) {
      case PDButtonSize.xs:
        return DesignTokens.iconXs;
      case PDButtonSize.sm:
        return DesignTokens.iconSm;
      case PDButtonSize.md:
        return DesignTokens.iconMd;
      case PDButtonSize.lg:
        return DesignTokens.iconLg;
      case PDButtonSize.xl:
        return DesignTokens.iconXl;
    }
  }

  TextStyle _getTextStyle(Color color) {
    switch (size) {
      case PDButtonSize.xs:
        return TokenTextStyles.labelSmall(color: color, weight: DesignTokens.wSemiBold);
      case PDButtonSize.sm:
        return TokenTextStyles.labelMedium(color: color, weight: DesignTokens.wSemiBold);
      case PDButtonSize.md:
        return TokenTextStyles.labelLarge(color: color, weight: DesignTokens.wSemiBold);
      case PDButtonSize.lg:
        return TokenTextStyles.titleSmall(color: color, weight: DesignTokens.wSemiBold);
      case PDButtonSize.xl:
        return TokenTextStyles.titleMedium(color: color, weight: DesignTokens.wBold);
    }
  }

  List<BoxShadow>? _getShadow(AppColorsExtension colors) {
    if (variant == PDButtonVariant.outline || variant == PDButtonVariant.ghost) {
      return null;
    }
    if (onPressed == null) return null;
    
    return [
      BoxShadow(
        color: colors.primary.withValues(alpha: 0.3),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ];
  }
}

/// Button variants
enum PDButtonVariant {
  primary,
  secondary,
  outline,
  ghost,
  destructive,
  success,
}

/// Button sizes
enum PDButtonSize {
  xs,
  sm,
  md,
  lg,
  xl,
}