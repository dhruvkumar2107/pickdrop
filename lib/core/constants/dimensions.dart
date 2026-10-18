import '../theme/design_tokens.dart';

/// AppDimensions - Backward compatible wrapper around DesignTokens
/// All values sourced from DesignTokens for single source of truth
class AppDimensions {
  // Spacing (8px base grid) - from DesignTokens
  @Deprecated('Use DesignTokens.spacingXs instead')
  static const double spacingXxs = DesignTokens.space1;

  @Deprecated('Use DesignTokens.spacingSm instead')
  static const double spacingXs = DesignTokens.space2;

  @Deprecated('Use DesignTokens.spacingMd instead')
  static const double spacingSm = DesignTokens.space4;

  @Deprecated('Use DesignTokens.spacingLg instead')
  static const double spacingMd = DesignTokens.space6;

  @Deprecated('Use DesignTokens.spacingXl instead')
  static const double spacingLg = DesignTokens.space8;

  @Deprecated('Use DesignTokens.spacingXxl instead')
  static const double spacingXl = DesignTokens.space10;

  @Deprecated('Use DesignTokens.spacingXxxl instead')
  static const double spacingXxl = DesignTokens.space12;

  @Deprecated('Use DesignTokens.spacingXxxl instead')
  static const double spacingXxxl = DesignTokens.space16;

  @Deprecated('Use DesignTokens.spacingXxxl instead')
  static const double spacingHuge = DesignTokens.space20;

  // Border Radius - from DesignTokens
  @Deprecated('Use DesignTokens.radiusXs instead')
  static const double radiusXs = DesignTokens.radiusXs;

  @Deprecated('Use DesignTokens.radiusSm instead')
  static const double radiusSm = DesignTokens.radiusSm;

  @Deprecated('Use DesignTokens.radiusMd instead')
  static const double radiusMd = DesignTokens.radiusMd;

  @Deprecated('Use DesignTokens.radiusLg instead')
  static const double radiusLg = DesignTokens.radiusLg;

  @Deprecated('Use DesignTokens.radiusXl instead')
  static const double radiusXl = DesignTokens.radiusXl;

  @Deprecated('Use DesignTokens.radiusXxl instead')
  static const double radiusXxl = DesignTokens.radiusXxl;

  @Deprecated('Use DesignTokens.radiusFull instead')
  static const double radiusFull = DesignTokens.radiusFull;

  // Elevation - from DesignTokens (as doubles, not const)
  static const double elevationNone = DesignTokens.elevationNone;

  @Deprecated('Use DesignTokens.elevationXs instead')
  static const double elevationXs = DesignTokens.elevationXs * 1.0;

  @Deprecated('Use DesignTokens.elevationSm instead')
  static const double elevationSm = DesignTokens.elevationSm * 1.0;

  @Deprecated('Use DesignTokens.elevationMd instead')
  static const double elevationMd = DesignTokens.elevationMd * 1.0;

  @Deprecated('Use DesignTokens.elevationLg instead')
  static const double elevationLg = DesignTokens.elevationLg * 1.0;

  @Deprecated('Use DesignTokens.elevationXl instead')
  static const double elevationXl = DesignTokens.elevationXl * 1.0;

  @Deprecated('Use DesignTokens.elevationXxl instead')
  static const double elevationXxl = DesignTokens.elevationXxl * 1.0;

  // Icon Sizes - from DesignTokens
  @Deprecated('Use DesignTokens.iconXs instead')
  static const double iconXs = DesignTokens.iconXs;

  @Deprecated('Use DesignTokens.iconSm instead')
  static const double iconSm = DesignTokens.iconSm;

  @Deprecated('Use DesignTokens.iconMd instead')
  static const double iconMd = DesignTokens.iconMd;

  @Deprecated('Use DesignTokens.iconLg instead')
  static const double iconLg = DesignTokens.iconLg;

  @Deprecated('Use DesignTokens.iconXl instead')
  static const double iconXl = DesignTokens.iconXl;

  @Deprecated('Use DesignTokens.iconXxl instead')
  static const double iconXxl = DesignTokens.iconXxl;

  @Deprecated('Use DesignTokens.iconHero instead')
  static const double iconHero = DesignTokens.iconHero;

  // Button Heights - from DesignTokens
  @Deprecated('Use DesignTokens.buttonHeightSm instead')
  static const double buttonHeightSm = DesignTokens.buttonHeightSm;

  @Deprecated('Use DesignTokens.buttonHeightMd instead')
  static const double buttonHeightMd = DesignTokens.buttonHeightMd;

  @Deprecated('Use DesignTokens.buttonHeightLg instead')
  static const double buttonHeightLg = DesignTokens.buttonHeightLg;

  @Deprecated('Use DesignTokens.buttonHeightXl instead')
  static const double buttonHeightXl = DesignTokens.buttonHeightXl;

  // Input Heights - from DesignTokens
  @Deprecated('Use DesignTokens.inputHeightSm instead')
  static const double inputHeightSm = DesignTokens.inputHeightSm;

  @Deprecated('Use DesignTokens.inputHeightMd instead')
  static const double inputHeightMd = DesignTokens.inputHeightMd;

  @Deprecated('Use DesignTokens.inputHeightLg instead')
  static const double inputHeightLg = DesignTokens.inputHeightLg;

  // Touch targets (accessibility)
  static const double minTouchTarget = 48.0;

  // Screen
  @Deprecated('Use DesignTokens.bpMobile instead')
  static const double maxContentWidth = DesignTokens.bpMobile;
  static const double phoneFrameWidth = DesignTokens.phoneFrameWidth;
  static const double phoneFrameMargin = DesignTokens.phoneFrameMargin;

  @Deprecated('Use DesignTokens.bottomSheetMaxHeightRatio instead')
  static const double bottomSheetMaxHeightRatio = 0.9;

  // Map
  @Deprecated('Use DesignTokens.mapToolbarPadding instead')
  static const double mapToolbarPadding = DesignTokens.spacingLg;

  @Deprecated('Use DesignTokens.mapMarkerSize instead')
  static const double mapMarkerSize = 40.0;

  // Avatar - from DesignTokens
  @Deprecated('Use DesignTokens.avatarSm instead')
  static const double avatarSm = DesignTokens.avatarSm;

  @Deprecated('Use DesignTokens.avatarMd instead')
  static const double avatarMd = DesignTokens.avatarMd;

  @Deprecated('Use DesignTokens.avatarLg instead')
  static const double avatarLg = DesignTokens.avatarLg;

  @Deprecated('Use DesignTokens.avatarXl instead')
  static const double avatarXl = DesignTokens.avatarXl;

  @Deprecated('Use DesignTokens.avatarXxl instead')
  static const double avatarXxl = DesignTokens.avatarXxl;

  @Deprecated('Use DesignTokens.avatarHero instead')
  static const double avatarHero = DesignTokens.avatarHero;

  // Chip heights - from DesignTokens
  static const double chipHeightSm = DesignTokens.chipHeightSm;
  static const double chipHeightMd = DesignTokens.chipHeightMd;
  static const double chipHeightLg = DesignTokens.chipHeightLg;

  // Responsive breakpoints
  static const double bpMobile = DesignTokens.bpMobile;
  static const double bpTablet = DesignTokens.bpTablet;
  static const double bpDesktop = DesignTokens.bpDesktop;
  static const double bpWide = DesignTokens.bpWide;
}