import 'dart:ui';

import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../constants/dimensions.dart';

/// Frosted-glass card used for floating panels over maps and hero headers.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final double blur;
  final Color? color;
  final Color? borderColor;
  final bool showBorder;
  final bool showShadow;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppDimensions.spacingLg),
    this.margin,
    this.radius = AppDimensions.radiusLg,
    this.blur = 18,
    this.color,
    this.borderColor,
    this.showBorder = true,
    this.showShadow = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color ?? colors.glass,
            borderRadius: BorderRadius.circular(radius),
            border: showBorder
                ? Border.all(color: borderColor ?? colors.glassBorder, width: 1)
                : null,
            boxShadow: showShadow
                ? [
                    BoxShadow(
                      color: colors.shadow.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: child,
        ),
      ),
    );

    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }

    if (onTap == null) return card;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: card,
    );
  }
}
