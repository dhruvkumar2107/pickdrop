import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// Backward compatible extension for context.colors (used by existing code)
extension AppColorsContextExtension on BuildContext {
  AppColorsExtension get colors => Theme.of(this).extension<AppColorsExtension>() ?? AppColorsExtension.light;
}

/// Extension to easily access design tokens from context
extension DesignTokenContext on BuildContext {
  /// Quick access to the (static) design token values.
  Type get tokens => DesignTokens;
}

/// AppColorsExtension - Theme extension for Material 3 compatibility
/// All values sourced from DesignTokens for consistency
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color primaryEnd;
  final Color primaryContainer;
  final Color onPrimary;
  final Color surface;
  final Color surfaceCard;
  final Color surfaceElevated;
  final Color surfaceVariant;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color outline;
  final Color outlineVariant;
  final Color secondary;
  final Color secondaryContainer;
  final Color onSecondary;
  final Color success;
  final Color successLight;
  final Color warning;
  final Color warningLight;
  final Color error;
  final Color errorLight;
  final Color info;
  final Color infoLight;
  final Color shadow;
  final Color glass;
  final Color glassBorder;
  final Color customerAccent;
  final Color driverAccent;
  final Color transparent;

  const AppColorsExtension({
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.primaryEnd,
    required this.primaryContainer,
    required this.onPrimary,
    required this.surface,
    required this.surfaceCard,
    required this.surfaceElevated,
    required this.surfaceVariant,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outline,
    required this.outlineVariant,
    required this.secondary,
    required this.secondaryContainer,
    required this.onSecondary,
    required this.success,
    required this.successLight,
    required this.warning,
    required this.warningLight,
    required this.error,
    required this.errorLight,
    required this.info,
    required this.infoLight,
    required this.shadow,
    required this.glass,
    required this.glassBorder,
    required this.customerAccent,
    required this.driverAccent,
    required this.transparent,
  });

  static final light = AppColorsExtension(
    primary: DesignTokens.green600,
    primaryLight: DesignTokens.green400,
    primaryDark: DesignTokens.green700,
    primaryEnd: DesignTokens.green500,
    primaryContainer: DesignTokens.green50,
    onPrimary: DesignTokens.white,
    surface: DesignTokens.white,
    surfaceCard: DesignTokens.white,
    surfaceElevated: DesignTokens.white,
    surfaceVariant: DesignTokens.white100,
    onSurface: DesignTokens.black900,
    onSurfaceVariant: DesignTokens.black500,
    outline: DesignTokens.hairlineLight,
    outlineVariant: DesignTokens.hairlineLight.withValues(alpha: 0.5),
    secondary: DesignTokens.black900,
    secondaryContainer: DesignTokens.white100,
    onSecondary: DesignTokens.white,
    success: DesignTokens.success500,
    successLight: DesignTokens.success50,
    warning: DesignTokens.warning500,
    warningLight: DesignTokens.warning50,
    error: DesignTokens.error500,
    errorLight: DesignTokens.error50,
    info: DesignTokens.info500,
    infoLight: DesignTokens.info50,
    shadow: DesignTokens.shadowMedium,
    glass: DesignTokens.glassWhite10,
    glassBorder: DesignTokens.hairlineLight,
    customerAccent: DesignTokens.green500,
    driverAccent: DesignTokens.green500,
    transparent: Colors.transparent,
  );

  static final dark = AppColorsExtension(
    primary: DesignTokens.green400,
    primaryLight: DesignTokens.green500,
    primaryDark: DesignTokens.green600,
    primaryEnd: DesignTokens.green500,
    primaryContainer: DesignTokens.black800,
    onPrimary: DesignTokens.black900,
    surface: DesignTokens.black900,
    surfaceCard: DesignTokens.black800,
    surfaceElevated: DesignTokens.black700,
    surfaceVariant: DesignTokens.black700,
    onSurface: DesignTokens.white,
    onSurfaceVariant: DesignTokens.white300,
    outline: DesignTokens.hairlineDark,
    outlineVariant: DesignTokens.hairlineDark.withValues(alpha: 0.5),
    secondary: DesignTokens.white,
    secondaryContainer: DesignTokens.black800,
    onSecondary: DesignTokens.black900,
    success: DesignTokens.success500,
    successLight: DesignTokens.success50,
    warning: DesignTokens.warning500,
    warningLight: DesignTokens.warning50,
    error: DesignTokens.error500,
    errorLight: DesignTokens.error50,
    info: DesignTokens.info500,
    infoLight: DesignTokens.info50,
    shadow: DesignTokens.shadowDark,
    glass: DesignTokens.glassBlack10,
    glassBorder: DesignTokens.hairlineDark,
    customerAccent: DesignTokens.green400,
    driverAccent: DesignTokens.green400,
    transparent: Colors.transparent,
  );

  @override
  AppColorsExtension copyWith({
    Color? primary,
    Color? primaryLight,
    Color? primaryDark,
    Color? primaryEnd,
    Color? primaryContainer,
    Color? onPrimary,
    Color? surface,
    Color? surfaceCard,
    Color? surfaceElevated,
    Color? surfaceVariant,
    Color? onSurface,
    Color? onSurfaceVariant,
    Color? outline,
    Color? outlineVariant,
    Color? secondary,
    Color? secondaryContainer,
    Color? onSecondary,
    Color? success,
    Color? successLight,
    Color? warning,
    Color? warningLight,
    Color? error,
    Color? errorLight,
    Color? info,
    Color? infoLight,
    Color? shadow,
    Color? glass,
    Color? glassBorder,
    Color? customerAccent,
    Color? driverAccent,
    Color? transparent,
  }) {
    return AppColorsExtension(
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      primaryDark: primaryDark ?? this.primaryDark,
      primaryEnd: primaryEnd ?? this.primaryEnd,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      onPrimary: onPrimary ?? this.onPrimary,
      surface: surface ?? this.surface,
      surfaceCard: surfaceCard ?? this.surfaceCard,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      onSurface: onSurface ?? this.onSurface,
      onSurfaceVariant: onSurfaceVariant ?? this.onSurfaceVariant,
      outline: outline ?? this.outline,
      outlineVariant: outlineVariant ?? this.outlineVariant,
      secondary: secondary ?? this.secondary,
      secondaryContainer: secondaryContainer ?? this.secondaryContainer,
      onSecondary: onSecondary ?? this.onSecondary,
      success: success ?? this.success,
      successLight: successLight ?? this.successLight,
      warning: warning ?? this.warning,
      warningLight: warningLight ?? this.warningLight,
      error: error ?? this.error,
      errorLight: errorLight ?? this.errorLight,
      info: info ?? this.info,
      infoLight: infoLight ?? this.infoLight,
      shadow: shadow ?? this.shadow,
      glass: glass ?? this.glass,
      glassBorder: glassBorder ?? this.glassBorder,
      customerAccent: customerAccent ?? this.customerAccent,
      driverAccent: driverAccent ?? this.driverAccent,
      transparent: transparent ?? this.transparent,
    );
  }

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) {
      return this;
    }
    return AppColorsExtension(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      primaryEnd: Color.lerp(primaryEnd, other.primaryEnd, t)!,
      primaryContainer: Color.lerp(primaryContainer, other.primaryContainer, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceCard: Color.lerp(surfaceCard, other.surfaceCard, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      onSurfaceVariant: Color.lerp(onSurfaceVariant, other.onSurfaceVariant, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      outlineVariant: Color.lerp(outlineVariant, other.outlineVariant, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      secondaryContainer: Color.lerp(secondaryContainer, other.secondaryContainer, t)!,
      onSecondary: Color.lerp(onSecondary, other.onSecondary, t)!,
      success: Color.lerp(success, other.success, t)!,
      successLight: Color.lerp(successLight, other.successLight, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningLight: Color.lerp(warningLight, other.warningLight, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorLight: Color.lerp(errorLight, other.errorLight, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoLight: Color.lerp(infoLight, other.infoLight, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      glass: Color.lerp(glass, other.glass, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      customerAccent: Color.lerp(customerAccent, other.customerAccent, t)!,
      driverAccent: Color.lerp(driverAccent, other.driverAccent, t)!,
      transparent: Color.lerp(transparent, other.transparent, t)!,
    );
  }
}

/// Backward compatible AppColors class - deprecated in favor of context.tokens
/// All values sourced from DesignTokens for single source of truth
class AppColors {
  // Gradients - from DesignTokens
  static const brandGradient = LinearGradient(
    colors: [DesignTokens.green600, DesignTokens.green500],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const darkGradient = LinearGradient(
    colors: [DesignTokens.black900, DesignTokens.black800],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const successGradient = LinearGradient(
    colors: [DesignTokens.success500, DesignTokens.success500],
  );

  static const driverGradient = LinearGradient(
    colors: [DesignTokens.green500, DesignTokens.green400],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Backward compatibility (Light mode defaults) - sourced from DesignTokens
  @Deprecated('Use context.tokens.green600 or context.colors.primary instead')
  static const Color primary = DesignTokens.green600;
  
  @Deprecated('Use context.colors.primaryLight instead')
  static const Color primaryLight = DesignTokens.green400;
  
  @Deprecated('Use context.colors.primaryDark instead')
  static const Color primaryDark = DesignTokens.green700;
  
  @Deprecated('Use context.colors.primaryEnd instead')
  static const Color primaryEnd = DesignTokens.green500;
  
  @Deprecated('Use context.colors.primaryContainer instead')
  static const Color primaryContainer = DesignTokens.green50;
  
  @Deprecated('Use context.colors.onPrimary instead')
  static const Color onPrimary = DesignTokens.white;
  
  @Deprecated('Use context.colors.surface instead')
  static const Color surface = DesignTokens.white;
  
  @Deprecated('Use context.colors.surfaceCard instead')
  static const Color surfaceCard = DesignTokens.white;
  
  @Deprecated('Use context.colors.surfaceElevated instead')
  static const Color surfaceElevated = DesignTokens.white;
  
  @Deprecated('Use context.colors.surfaceVariant instead')
  static const Color surfaceVariant = DesignTokens.white100;
  
  @Deprecated('Use context.colors.onSurface instead')
  static const Color onSurface = DesignTokens.black900;
  
  @Deprecated('Use context.colors.onSurfaceVariant instead')
  static const Color onSurfaceVariant = DesignTokens.black500;
  
  @Deprecated('Use context.colors.outline instead')
  static const Color outline = DesignTokens.hairlineLight;
  
  @Deprecated('Use context.colors.outlineVariant instead')
  static const Color outlineVariant = DesignTokens.hairlineLight;
  
  @Deprecated('Use context.colors.secondary instead')
  static const Color secondary = DesignTokens.black900;
  
  @Deprecated('Use context.colors.secondaryContainer instead')
  static const Color secondaryContainer = DesignTokens.white100;
  
  @Deprecated('Use context.colors.onSecondary instead')
  static const Color onSecondary = DesignTokens.white;
  
  @Deprecated('Use context.colors.success instead')
  static const Color success = DesignTokens.success500;
  
  @Deprecated('Use context.colors.successLight instead')
  static const Color successLight = DesignTokens.success50;
  
  @Deprecated('Use context.colors.warning instead')
  static const Color warning = DesignTokens.warning500;
  
  @Deprecated('Use context.colors.warningLight instead')
  static const Color warningLight = DesignTokens.warning50;
  
  @Deprecated('Use context.colors.error instead')
  static const Color error = DesignTokens.error500;
  
  @Deprecated('Use context.colors.errorLight instead')
  static const Color errorLight = DesignTokens.error50;
  
  @Deprecated('Use context.colors.info instead')
  static const Color info = DesignTokens.info500;
  
  @Deprecated('Use context.colors.infoLight instead')
  static const Color infoLight = DesignTokens.info50;
  
  @Deprecated('Use context.colors.shadow instead')
  static const Color shadow = DesignTokens.shadowMedium;
  
  @Deprecated('Use context.tokens.glassWhite10 instead')
  static const Color glass = DesignTokens.glassWhite10;
  
  @Deprecated('Use context.colors.glassBorder instead')
  static const Color glassBorder = DesignTokens.hairlineLight;
  
  @Deprecated('Use context.colors.customerAccent instead')
  static const Color customerAccent = DesignTokens.green500;
  
  @Deprecated('Use context.colors.driverAccent instead')
  static const Color driverAccent = DesignTokens.green500;
  
  @Deprecated('Use context.colors.transparent instead')
  static const Color transparent = Colors.transparent;
}