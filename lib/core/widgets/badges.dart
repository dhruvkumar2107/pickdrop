import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../constants/colors.dart';
import '../theme/design_tokens.dart';

/// A status badge/chip
class PDBadge extends StatelessWidget {
  final String label;
  final PDBadgeVariant variant;
  final PDBadgeSize size;
  final IconData? icon;
  final Color? customColor;
  final VoidCallback? onTap;
  final bool isOutlined;

  const PDBadge({
    super.key,
    required this.label,
    this.variant = PDBadgeVariant.neutral,
    this.size = PDBadgeSize.md,
    this.icon,
    this.customColor,
    this.onTap,
    this.isOutlined = false,
  });

  const PDBadge.success({
    super.key,
    required this.label,
    this.size = PDBadgeSize.md,
    this.icon = Icons.check_circle_rounded,
    this.onTap,
  }) : variant = PDBadgeVariant.success,
       customColor = null,
       isOutlined = false;

  const PDBadge.warning({
    super.key,
    required this.label,
    this.size = PDBadgeSize.md,
    this.icon = Icons.warning_rounded,
    this.onTap,
  }) : variant = PDBadgeVariant.warning,
       customColor = null,
       isOutlined = false;

  const PDBadge.error({
    super.key,
    required this.label,
    this.size = PDBadgeSize.md,
    this.icon = Icons.error_rounded,
    this.onTap,
  }) : variant = PDBadgeVariant.error,
       customColor = null,
       isOutlined = false;

  const PDBadge.info({
    super.key,
    required this.label,
    this.size = PDBadgeSize.md,
    this.icon = Icons.info_rounded,
    this.onTap,
  }) : variant = PDBadgeVariant.info,
       customColor = null,
       isOutlined = false;

  const PDBadge.primary({
    super.key,
    required this.label,
    this.size = PDBadgeSize.md,
    this.icon,
    this.onTap,
  }) : variant = PDBadgeVariant.primary,
       customColor = null,
       isOutlined = false;

  const PDBadge.outline({
    super.key,
    required this.label,
    this.size = PDBadgeSize.md,
    this.icon,
    this.onTap,
    required Color color,
  }) : variant = PDBadgeVariant.custom,
       customColor = color,
       isOutlined = true;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = customColor ?? _getColor(colors);
    final bgColor = isOutlined ? Colors.transparent : color.withValues(alpha: 0.12);
    final borderColor = isOutlined ? color : color.withValues(alpha: 0.3);
    final textColor = isOutlined ? color : color;

    final horizontalPadding = _getHorizontalPadding();
    final verticalPadding = _getVerticalPadding();
    final fontSize = _getFontSize();
    final iconSize = _getIconSize();
    final borderRadius = _getBorderRadius();

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: iconSize, color: textColor),
          SizedBox(width: DesignTokens.space1),
        ],
        Text(
          label,
          style: TextStyle(
            fontFamily: DesignTokens.fontUI,
            fontSize: fontSize,
            fontWeight: DesignTokens.wSemiBold,
            color: textColor,
            letterSpacing: DesignTokens.lsWide,
          ),
        ),
      ],
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: borderColor, width: DesignTokens.borderThin),
            ),
            child: child,
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: DesignTokens.borderThin),
      ),
      child: child,
    );
  }

  Color _getColor(AppColorsExtension colors) {
    switch (variant) {
      case PDBadgeVariant.success:
        return colors.success;
      case PDBadgeVariant.warning:
        return colors.warning;
      case PDBadgeVariant.error:
        return colors.error;
      case PDBadgeVariant.info:
        return colors.info;
      case PDBadgeVariant.primary:
        return colors.primary;
      case PDBadgeVariant.neutral:
        return colors.onSurfaceVariant;
      case PDBadgeVariant.custom:
        return customColor ?? colors.primary;
    }
  }

  double _getHorizontalPadding() {
    switch (size) {
      case PDBadgeSize.xs:
        return DesignTokens.space2;
      case PDBadgeSize.sm:
        return DesignTokens.space3;
      case PDBadgeSize.md:
        return DesignTokens.space4;
      case PDBadgeSize.lg:
        return DesignTokens.space5;
    }
  }

  double _getVerticalPadding() {
    switch (size) {
      case PDBadgeSize.xs:
        return DesignTokens.space0;
      case PDBadgeSize.sm:
        return DesignTokens.space1;
      case PDBadgeSize.md:
        return DesignTokens.space2;
      case PDBadgeSize.lg:
        return DesignTokens.space3;
    }
  }

  double _getFontSize() {
    switch (size) {
      case PDBadgeSize.xs:
        return 9;
      case PDBadgeSize.sm:
        return 10;
      case PDBadgeSize.md:
        return 11;
      case PDBadgeSize.lg:
        return 12;
    }
  }

  double _getIconSize() {
    switch (size) {
      case PDBadgeSize.xs:
        return 10;
      case PDBadgeSize.sm:
        return 12;
      case PDBadgeSize.md:
        return 14;
      case PDBadgeSize.lg:
        return 16;
    }
  }

  double _getBorderRadius() {
    switch (size) {
      case PDBadgeSize.xs:
        return DesignTokens.radiusSm;
      case PDBadgeSize.sm:
      case PDBadgeSize.md:
      case PDBadgeSize.lg:
        return DesignTokens.radiusChip;
    }
  }
}

enum PDBadgeVariant {
  success,
  warning,
  error,
  info,
  primary,
  neutral,
  custom,
}

enum PDBadgeSize {
  xs,
  sm,
  md,
  lg,
}

/// A status indicator dot
class PDStatusDot extends StatelessWidget {
  final Color color;
  final double size;
  final bool pulsing;
  final bool showRing;

  const PDStatusDot({
    super.key,
    required this.color,
    this.size = 8,
    this.pulsing = false,
    this.showRing = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget dot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.6),
            blurRadius: size * 1.5,
            spreadRadius: size * 0.25,
          ),
        ],
      ),
    );

    if (pulsing) {
      dot = dot.animate(onPlay: (controller) => controller.repeat(reverse: true)).scale(
        begin: const Offset(0.85, 0.85),
        end: const Offset(1.3, 1.3),
        duration: 900.ms,
        curve: Curves.easeInOut,
      ).fade(
        begin: 1,
        end: 0.4,
        duration: 900.ms,
      );
    }

    if (showRing) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 2,
            height: size * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
          ).animate(onPlay: (controller) => controller.repeat()).scale(
            begin: const Offset(0.45, 0.45),
            end: const Offset(1.0, 1.0),
            duration: 1800.ms,
            curve: Curves.easeOut,
          ).fade(
            begin: 0.9,
            end: 0,
            duration: 1800.ms,
          ),
          dot,
        ],
      );
    }

    return dot;
  }
}

/// A progress step indicator
class PDStepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> labels;
  final Color? activeColor;
  final Color? completedColor;
  final Color? inactiveColor;
  final double lineWidth;

  const PDStepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.labels,
    this.activeColor,
    this.completedColor,
    this.inactiveColor,
    this.lineWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final active = activeColor ?? colors.primary;
    final completed = completedColor ?? colors.success;
    final inactive = inactiveColor ?? colors.outlineVariant;

    return Row(
      children: List.generate(totalSteps, (index) {
        final isCompleted = index < currentStep;
        final isCurrent = index == currentStep;
        final isLast = index == totalSteps - 1;

        return Expanded(
          flex: 2,
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  if (!isLast)
                    Positioned(
                      left: size / 2,
                      right: size / 2,
                      child: Container(
                        height: lineWidth,
                        color: index < currentStep ? completed : inactive,
                      ),
                    ),
                  Container(
                    width: size,
                    height: size,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? completed
                          : isCurrent
                              ? active
                              : colors.surfaceVariant,
                      border: isCurrent && !isCompleted
                          ? Border.all(color: active, width: 2)
                          : null,
                    ),
                    child: isCompleted
                        ? Icon(
                            Icons.check_rounded,
                            size: size * 0.5,
                            color: colors.onPrimary,
                          )
                        : Text(
                            '${index + 1}',
                            style: TokenTextStyles.labelSmall(
                              color: isCurrent ? colors.onPrimary : colors.onSurfaceVariant,
                              weight: DesignTokens.wBold,
                            ),
                          ),
                  ),
                ],
              ),
              SizedBox(height: DesignTokens.space2),
              Text(
                labels[index],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TokenTextStyles.labelSmall(
                  color: isCompleted || isCurrent
                      ? colors.onSurface
                      : colors.onSurfaceVariant,
                  fontWeight: isCompleted || isCurrent ? DesignTokens.wSemiBold : DesignTokens.wMedium,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  double get size => 28;
}

/// A price display component
class PDPrice extends StatelessWidget {
  final double amount;
  final PDPriceSize size;
  final Color? color;
  final String? prefix;
  final String? suffix;
  final bool showCurrency;
  final FontWeight? weight;

  const PDPrice({
    super.key,
    required this.amount,
    this.size = PDPriceSize.md,
    this.color,
    this.prefix,
    this.suffix,
    this.showCurrency = true,
    this.weight,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final priceColor = color ?? colors.primary;

    String formattedAmount = amount.toStringAsFixed(0);
    if (showCurrency) {
      formattedAmount = '₹$formattedAmount';
    }
    if (prefix != null) {
      formattedAmount = '$prefix$formattedAmount';
    }
    if (suffix != null) {
      formattedAmount = '$formattedAmount$suffix';
    }

    TextStyle style;
    switch (size) {
      case PDPriceSize.xs:
        style = TokenTextStyles.priceSmall(color: priceColor, weight: weight ?? DesignTokens.wBold);
        break;
      case PDPriceSize.sm:
        style = TokenTextStyles.priceSmall(color: priceColor, weight: weight ?? DesignTokens.wBold);
        break;
      case PDPriceSize.md:
        style = TokenTextStyles.priceMedium(color: priceColor, weight: weight ?? DesignTokens.wExtraBold);
        break;
      case PDPriceSize.lg:
        style = TokenTextStyles.priceLarge(color: priceColor, weight: weight ?? DesignTokens.wExtraBold);
        break;
      case PDPriceSize.xl:
        style = TokenTextStyles.priceXLarge(color: priceColor, weight: weight ?? DesignTokens.wExtraBold);
        break;
    }

    return Text(formattedAmount, style: style);
  }
}

enum PDPriceSize {
  xs,
  sm,
  md,
  lg,
  xl,
}

/// A fare breakdown row
class PDFareRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isNegative;
  final bool isTotal;
  final Color? labelColor;
  final Color? amountColor;

  const PDFareRow({
    super.key,
    required this.label,
    required this.amount,
    this.isNegative = false,
    this.isTotal = false,
    this.labelColor,
    this.amountColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final lblColor = labelColor ?? (isTotal ? colors.onSurface : colors.onSurfaceVariant);
    final amtColor = amountColor ?? (isNegative ? colors.success : (isTotal ? colors.primary : colors.onSurface));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TokenTextStyles.bodySmall(
            color: lblColor,
            weight: isTotal ? DesignTokens.wSemiBold : DesignTokens.wRegular,
          ),
        ),
        Text(
          '${isNegative ? '-' : ''}₹${amount.abs().toStringAsFixed(0)}',
          style: TokenTextStyles.bodySmall(
            color: amtColor,
            weight: isTotal ? DesignTokens.wBold : DesignTokens.wRegular,
          ),
        ),
      ],
    );
  }
}