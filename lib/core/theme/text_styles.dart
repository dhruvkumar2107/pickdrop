import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// AppTextStyles - Backward compatible wrapper around TokenTextStyles
/// All values sourced from DesignTokens for single source of truth
/// Uses PlayfairDisplay for display, Poppins for UI, Inter for body
class AppTextStyles {
  // =============================================================================
  // DISPLAY — PlayfairDisplay (elegant serif for hero moments)
  // =============================================================================

  @Deprecated('Use TokenTextStyles.displayLarge or context.text.displayLarge instead')
  static TextStyle get displayLarge => TokenTextStyles.displayLarge();

  @Deprecated('Use TokenTextStyles.displayMedium or context.text.displayMedium instead')
  static TextStyle get displayMedium => TokenTextStyles.displayMedium();

  @Deprecated('Use TokenTextStyles.displaySmall or context.text.displaySmall instead')
  static TextStyle get displaySmall => TokenTextStyles.displaySmall();

  // =============================================================================
  // HEADLINE — Poppins (semibold for UI headlines)
  // =============================================================================

  @Deprecated('Use TokenTextStyles.headlineLarge or context.text.headlineLarge instead')
  static TextStyle get headlineLarge => TokenTextStyles.headlineLarge();

  @Deprecated('Use TokenTextStyles.headlineMedium or context.text.headlineMedium instead')
  static TextStyle get headlineMedium => TokenTextStyles.headlineMedium();

  @Deprecated('Use TokenTextStyles.headlineSmall or context.text.headlineSmall instead')
  static TextStyle get headlineSmall => TokenTextStyles.headlineSmall();

  // =============================================================================
  // TITLE — Poppins (UI titles)
  // =============================================================================

  @Deprecated('Use TokenTextStyles.titleLarge or context.text.titleLarge instead')
  static TextStyle get titleLarge => TokenTextStyles.titleLarge();

  @Deprecated('Use TokenTextStyles.titleMedium or context.text.titleMedium instead')
  static TextStyle get titleMedium => TokenTextStyles.titleMedium();

  @Deprecated('Use TokenTextStyles.titleSmall or context.text.titleSmall instead')
  static TextStyle get titleSmall => TokenTextStyles.titleSmall();

  // =============================================================================
  // BODY — Inter (readable body text)
  // =============================================================================

  @Deprecated('Use TokenTextStyles.bodyLarge or context.text.bodyLarge instead')
  static TextStyle get bodyLarge => TokenTextStyles.bodyLarge();

  @Deprecated('Use TokenTextStyles.bodyMedium or context.text.bodyMedium instead')
  static TextStyle get bodyMedium => TokenTextStyles.bodyMedium();

  @Deprecated('Use TokenTextStyles.bodySmall or context.text.bodySmall instead')
  static TextStyle get bodySmall => TokenTextStyles.bodySmall();

  // =============================================================================
  // LABEL — Poppins (UI labels, buttons)
  // =============================================================================

  @Deprecated('Use TokenTextStyles.labelLarge or context.text.labelLarge instead')
  static TextStyle get labelLarge => TokenTextStyles.labelLarge();

  @Deprecated('Use TokenTextStyles.labelMedium or context.text.labelMedium instead')
  static TextStyle get labelMedium => TokenTextStyles.labelMedium();

  @Deprecated('Use TokenTextStyles.labelSmall or context.text.labelSmall instead')
  static TextStyle get labelSmall => TokenTextStyles.labelSmall();

  // =============================================================================
  // PRICE — Poppins (bold, tight tracking for currency)
  // =============================================================================

  @Deprecated('Use TokenTextStyles.priceXLarge or context.text.priceXLarge instead')
  static TextStyle get priceDisplay => TokenTextStyles.priceXLarge();

  @Deprecated('Use TokenTextStyles.priceLarge or context.text.priceLarge instead')
  static TextStyle get priceLarge => TokenTextStyles.priceLarge();

  @Deprecated('Use TokenTextStyles.priceMedium or context.text.priceMedium instead')
  static TextStyle get priceMedium => TokenTextStyles.priceMedium();

  @Deprecated('Use TokenTextStyles.priceSmall or context.text.priceSmall instead')
  static TextStyle get priceSmall => TokenTextStyles.priceSmall();

  // =============================================================================
  // LEGACY ALIASES (for gradual migration)
  // =============================================================================

  @Deprecated('Use labelLarge instead')
  static TextStyle get button => TokenTextStyles.labelLarge();

  @Deprecated('Use bodySmall instead')
  static TextStyle get caption => TokenTextStyles.bodySmall();

  @Deprecated('Use labelSmall instead')
  static TextStyle get overline => TokenTextStyles.labelSmall();
}