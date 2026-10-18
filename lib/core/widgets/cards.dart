import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../theme/design_tokens.dart';

/// A premium card with multiple variants
class PDCard extends StatelessWidget {
  final Widget child;
  final PDCardVariant variant;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;
  final BorderRadius? borderRadius;
  final bool showBorder;
  final double? radius;
  final bool showShadow;
  final Color? color;
  final List<Color>? gradientColors;

  const PDCard({
    super.key,
    required this.child,
    this.variant = PDCardVariant.elevated,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.boxShadow,
    this.borderRadius,
    this.showBorder = true,
    this.radius,
    this.showShadow = false,
    this.color,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final bgColor = backgroundColor ?? color ?? _getBackgroundColor(colors, isDark);
    final border = borderColor ?? _getBorderColor(colors, isDark);
    final shadow = boxShadow ?? _getShadow(colors, isDark);
    final radiusValue = borderRadius ?? BorderRadius.circular(radius ?? DesignTokens.radiusCard);
    final effectiveShadow = showShadow ? shadow : null;
    final effectiveGradient = gradientColors != null 
        ? LinearGradient(
            colors: gradientColors!,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : null;

    final card = Material(
      color: Colors.transparent,
      child: Ink(
        padding: padding ?? EdgeInsets.all(DesignTokens.spacingMd),
        decoration: BoxDecoration(
          color: effectiveGradient == null ? bgColor : null,
          gradient: effectiveGradient,
          borderRadius: radiusValue,
          border: showBorder ? Border.all(color: border, width: DesignTokens.borderThin) : null,
          boxShadow: effectiveShadow,
        ),
        child: child,
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radiusValue,
          child: card,
        ),
      );
    }

    if (margin != null) {
      return Container(margin: margin, child: card);
    }

    return card;
  }

  Color _getBackgroundColor(AppColorsExtension colors, bool isDark) {
    switch (variant) {
      case PDCardVariant.elevated:
        return isDark ? colors.surfaceCard : colors.surfaceCard;
      case PDCardVariant.outlined:
        return isDark ? colors.surfaceCard : colors.surfaceCard;
      case PDCardVariant.filled:
        return isDark ? colors.surfaceVariant : colors.surfaceVariant;
      case PDCardVariant.glass:
        return isDark ? colors.glass : colors.glass;
      case PDCardVariant.gradient:
        return Colors.transparent;
      case PDCardVariant.success:
        return isDark ? colors.success.withValues(alpha: 0.15) : colors.successLight;
      case PDCardVariant.warning:
        return isDark ? colors.warning.withValues(alpha: 0.15) : colors.warningLight;
      case PDCardVariant.info:
        return isDark ? colors.info.withValues(alpha: 0.15) : colors.infoLight;
      case PDCardVariant.primary:
        return isDark ? colors.primary.withValues(alpha: 0.15) : colors.primaryContainer;
      case PDCardVariant.destructive:
        return isDark ? colors.error.withValues(alpha: 0.15) : colors.errorLight;
    }
  }

  Color _getBorderColor(AppColorsExtension colors, bool isDark) {
    switch (variant) {
      case PDCardVariant.elevated:
        return colors.outlineVariant;
      case PDCardVariant.outlined:
        return colors.outline;
      case PDCardVariant.filled:
        return Colors.transparent;
      case PDCardVariant.glass:
        return colors.glassBorder;
      case PDCardVariant.gradient:
        return colors.primary;
      case PDCardVariant.success:
        return colors.success.withValues(alpha: 0.35);
      case PDCardVariant.warning:
        return colors.warning.withValues(alpha: 0.35);
      case PDCardVariant.info:
        return colors.info.withValues(alpha: 0.35);
      case PDCardVariant.primary:
        return colors.primary.withValues(alpha: 0.35);
      case PDCardVariant.destructive:
        return colors.error.withValues(alpha: 0.35);
    }
  }

  List<BoxShadow>? _getShadow(AppColorsExtension colors, bool isDark) {
    if (variant == PDCardVariant.outlined || variant == PDCardVariant.filled) {
      return null;
    }
    if (variant == PDCardVariant.glass) {
      return [
        BoxShadow(
          color: isDark ? DesignTokens.shadowDark : DesignTokens.shadowLight,
          blurRadius: DesignTokens.elevationMd,
          offset: const Offset(0, 4),
        ),
      ];
    }
    return [
      BoxShadow(
        color: isDark ? DesignTokens.shadowDark : DesignTokens.shadowMedium,
        blurRadius: DesignTokens.elevationMd,
        offset: const Offset(0, 4),
      ),
    ];
  }
}

/// Card variants
enum PDCardVariant {
  elevated,
  outlined,
  filled,
  glass,
  gradient,
  success,
  warning,
  info,
  primary,
  destructive,
}

/// Vehicle option card used in the vehicle selection screen.
class PDVehicleCard extends StatelessWidget {
  final String vehicleType;
  final String label;
  final int capacityKg;
  final double estimatedFare;
  final int etaMinutes;
  final double distanceKm;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color accentColor;
  final bool isRecommended;
  final bool isBestValue;

  const PDVehicleCard({
    super.key,
    required this.vehicleType,
    required this.label,
    required this.capacityKg,
    required this.estimatedFare,
    required this.etaMinutes,
    required this.distanceKm,
    this.isSelected = false,
    this.onTap,
    this.accentColor = const Color(0xFF00C853),
    this.isRecommended = false,
    this.isBestValue = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return PDCard(
      variant: PDCardVariant.elevated,
      onTap: onTap,
      backgroundColor: isSelected ? accentColor.withValues(alpha: 0.08) : colors.surfaceCard,
      borderColor: isSelected ? accentColor : colors.outlineVariant,
      borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            ),
            child: Icon(Icons.local_shipping_rounded, color: accentColor, size: 28),
          ),
          SizedBox(width: DesignTokens.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        style: TokenTextStyles.titleMedium(color: colors.onSurface),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isRecommended) ...[
                      SizedBox(width: DesignTokens.spacingXs),
                      _tag('Recommended', colors.primary),
                    ],
                    if (isBestValue) ...[
                      SizedBox(width: DesignTokens.spacingXs),
                      _tag('Best Value', colors.success),
                    ],
                  ],
                ),
                SizedBox(height: DesignTokens.spacingXxs),
                Text(
                  'Up to ${capacityKg}kg  \u2022  ${etaMinutes}min away  \u2022  ${distanceKm.toStringAsFixed(1)}km',
                  style: TokenTextStyles.bodySmall(color: colors.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: DesignTokens.spacingSm),
          Text(
            '\u20B9${estimatedFare.toStringAsFixed(0)}',
            style: TokenTextStyles.titleMedium(color: colors.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacingXs, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
      ),
      child: Text(text, style: TokenTextStyles.labelSmall(color: color)),
    );
  }
}