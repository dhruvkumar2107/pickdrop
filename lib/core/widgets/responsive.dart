import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../theme/design_tokens.dart';

/// Responsive layout helper
class PDResponsive {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < DesignTokens.bpMobile;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= DesignTokens.bpMobile && width < DesignTokens.bpDesktop;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= DesignTokens.bpDesktop;
  }

  static bool isWide(BuildContext context) {
    return MediaQuery.of(context).size.width >= DesignTokens.bpWide;
  }

  /// Get the number of columns for a grid based on screen width
  static int getGridColumns(BuildContext context, {
    int mobile = 1,
    int tablet = 2,
    int desktop = 3,
    int wide = 4,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width >= DesignTokens.bpWide) return wide;
    if (width >= DesignTokens.bpDesktop) return desktop;
    if (width >= DesignTokens.bpMobile) return tablet;
    return mobile;
  }

  /// Get the max content width for centered content
  static double getMaxContentWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= DesignTokens.bpWide) return DesignTokens.bpWide * 0.9;
    if (width >= DesignTokens.bpDesktop) return DesignTokens.bpDesktop * 0.9;
    if (width >= DesignTokens.bpMobile) return width * 0.95;
    return width;
  }

  /// Get responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= DesignTokens.bpDesktop) {
      return EdgeInsets.symmetric(
        horizontal: width * 0.1,
        vertical: DesignTokens.spacingLg,
      );
    }
    if (width >= DesignTokens.bpMobile) {
      return EdgeInsets.all(DesignTokens.spacingLg);
    }
    return EdgeInsets.all(DesignTokens.spacingMd);
  }

  /// Get responsive font scale
  static double getFontScale(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= DesignTokens.bpDesktop) return 1.1;
    if (width >= DesignTokens.bpMobile) return 1.0;
    return 0.95;
  }

  /// Get responsive spacing
  static double getSpacing(BuildContext context, double baseSpacing) {
    final scale = getFontScale(context);
    return baseSpacing * scale;
  }
}

/// A responsive layout builder
class PDResponsiveBuilder extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? wide;

  const PDResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.wide,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width >= DesignTokens.bpWide && wide != null) {
      return wide!;
    }
    if (width >= DesignTokens.bpDesktop && desktop != null) {
      return desktop!;
    }
    if (width >= DesignTokens.bpMobile && tablet != null) {
      return tablet!;
    }
    return mobile;
  }
}

/// A responsive grid view
class PDResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double? aspectRatio;
  final double spacing;
  final double runSpacing;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final int? wideColumns;
  final EdgeInsetsGeometry? padding;

  const PDResponsiveGrid({
    super.key,
    required this.children,
    this.aspectRatio,
    this.spacing = DesignTokens.spacingMd,
    this.runSpacing = DesignTokens.spacingMd,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
    this.wideColumns = 4,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;
        final width = constraints.maxWidth;
        
        if (width >= DesignTokens.bpWide) {
          crossAxisCount = wideColumns!;
        } else if (width >= DesignTokens.bpDesktop) {
          crossAxisCount = desktopColumns!;
        } else if (width >= DesignTokens.bpMobile) {
          crossAxisCount = tabletColumns!;
        } else {
          crossAxisCount = mobileColumns!;
        }

        return GridView.builder(
          padding: padding,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: runSpacing,
            childAspectRatio: aspectRatio ?? 1.0,
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

/// A responsive wrapper that constrains content width on large screens
class PDConstrainedContent extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final Alignment alignment;

  const PDConstrainedContent({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final contentWidth = maxWidth ?? PDResponsive.getMaxContentWidth(context);
        
        return Align(
          alignment: alignment,
          child: Container(
            constraints: BoxConstraints(maxWidth: contentWidth),
            width: width > contentWidth ? contentWidth : width,
            padding: padding,
            child: child,
          ),
        );
      },
    );
  }
}

/// A responsive app bar that adapts to screen size
class PDResponsiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final double elevation;
  final Color? backgroundColor;
  final PreferredSizeWidget? bottom;

  const PDResponsiveAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.elevation = 0,
    this.backgroundColor,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isMobile = PDResponsive.isMobile(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      title: title,
      centerTitle: centerTitle,
      elevation: elevation,
      backgroundColor: backgroundColor ?? (isDark ? DesignTokens.black900 : DesignTokens.white),
      foregroundColor: colors.onSurface,
      leading: leading,
      actions: actions,
      bottom: bottom,
      titleTextStyle: TokenTextStyles.headlineSmall(
        color: colors.onSurface,
        weight: DesignTokens.wSemiBold,
      ),
      toolbarHeight: isMobile ? kToolbarHeight : kToolbarHeight + 8,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}