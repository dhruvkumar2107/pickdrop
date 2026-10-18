import 'package:flutter/material.dart';

export 'token_text_styles.dart';

/// PickDrop Design Tokens - "Premium Logistics" Design System
/// All design values come from here. No hardcoded colors/sizes in screens;
/// 
/// Brand: Deep Black primary, Electric Green accent
/// Feel: Fast, Trusted, Intelligent, Premium, Reliable
class DesignTokens {
  DesignTokens._();

  // =============================================================================
  // COLOR SYSTEM - "Premium Logistics" Palette
  // =============================================================================

  /// Deep black / near-black - primary brand color
  static const Color black900 = Color(0xFF0A0A0A);
  static const Color black800 = Color(0xFF121212);
  static const Color black700 = Color(0xFF1E1E1E);
  static const Color black600 = Color(0xFF2A2A2A);
  static const Color black500 = Color(0xFF363636);
  static const Color black400 = Color(0xFF424242);
  static const Color black300 = Color(0xFF5A5A5A);
  static const Color black200 = Color(0xFF757575);
  static const Color black100 = Color(0xFF9E9E9E);

  /// Pure white surfaces
  static const Color white = Color(0xFFFFFFFF);
  static const Color white50 = Color(0xFFFAFAFA);
  static const Color white100 = Color(0xFFF5F5F5);
  static const Color white200 = Color(0xFFEEEEEE);
  static const Color white300 = Color(0xFFE0E0E0);

  /// Electric green - primary brand accent (PickDrop Green)
  static const Color green500 = Color(0xFF00E676);
  static const Color green400 = Color(0xFF69F0AE);
  static const Color green600 = Color(0xFF00C853);
  static const Color green700 = Color(0xFF00B040);
  static const Color green50 = Color(0xFFE8F5E9);
  static const Color green100 = Color(0xFFC8E6C9);

  /// Legacy color aliases (for backward compatibility)
  @Deprecated('Use black900 instead')
  static const Color charcoal900 = black900;
  @Deprecated('Use black800 instead')
  static const Color charcoal800 = black800;
  @Deprecated('Use black700 instead')
  static const Color charcoal700 = black700;
  @Deprecated('Use black600 instead')
  static const Color charcoal600 = black600;

  @Deprecated('Use white instead')
  static const Color ivory50 = white;
  @Deprecated('Use white50 instead')
  static const Color ivory100 = white50;
  @Deprecated('Use white100 instead')
  static const Color ivory200 = white100;

  @Deprecated('Use green600 instead')
  static const Color orange500 = green600;
  @Deprecated('Use green400 instead')
  static const Color orange400 = green400;
  @Deprecated('Use green700 instead')
  static const Color orange600 = green700;
  @Deprecated('Use green700 instead')
  static const Color orange700 = green700;
  @Deprecated('Use green50 instead')
  static const Color orange50 = green50;
  @Deprecated('Use green100 instead')
  static const Color orange100 = green100;

  @Deprecated('Use gold500 instead')
  static const Color gold500 = Color(0xFFC9A24B);
  @Deprecated('Use gold400 instead')
  static const Color gold400 = Color(0xFFD4B56B);
  @Deprecated('Use gold600 instead')
  static const Color gold600 = Color(0xFFB88F3D);
  @Deprecated('Use gold50 instead')
  static const Color gold50 = Color(0xFFFAF5EB);

  /// Semantic colors
  static const Color success500 = Color(0xFF16A34A);
  static const Color success50 = Color(0xFFECFDF5);
  static const Color warning500 = Color(0xFFF59E0B);
  static const Color warning50 = Color(0xFFFFFBE6);
  static const Color error500 = Color(0xFFDC2626);
  static const Color error50 = Color(0xFFFEF2F2);
  static const Color info500 = Color(0xFF2563EB);
  static const Color info50 = Color(0xFFEFF6FF);

  /// Glass system colors
  static const Color glassWhite10 = Color(0x1AFFFFFF); // 10% white
  static const Color glassWhite20 = Color(0x33FFFFFF); // 20% white
  static const Color glassWhite30 = Color(0x4DFFFFFF); // 30% white
  static const Color glassBlack10 = Color(0x1A000000); // 10% black
  static const Color glassBlack20 = Color(0x33000000); // 20% black

  /// Hairline border colors
  static const Color hairlineLight = Color(0x1A000000); // 10% black
  static const Color hairlineDark = Color(0x1AFFFFFF); // 10% white

  // =============================================================================
  // TYPOGRAPHY SCALE
  // =============================================================================

  /// Font families - Premium modern stack
  static const String fontDisplay = 'PlayfairDisplay'; // Hero moments, headlines
  static const String fontUI = 'Poppins';              // UI elements, buttons, labels
  static const String fontBody = 'Inter';              // Body text, reading

  /// Font weights
  static const FontWeight wLight = FontWeight.w300;
  static const FontWeight wRegular = FontWeight.w400;
  static const FontWeight wMedium = FontWeight.w500;
  static const FontWeight wSemiBold = FontWeight.w600;
  static const FontWeight wBold = FontWeight.w700;
  static const FontWeight wExtraBold = FontWeight.w800;

  /// Text sizes (Material 3 scale + custom)
  static const double sizeDisplayLarge = 57;
  static const double sizeDisplayMedium = 45;
  static const double sizeDisplaySmall = 36;
  static const double sizeHeadlineLarge = 32;
  static const double sizeHeadlineMedium = 28;
  static const double sizeHeadlineSmall = 24;
  static const double sizeTitleLarge = 22;
  static const double sizeTitleMedium = 18;
  static const double sizeTitleSmall = 16;
  static const double sizeBodyLarge = 16;
  static const double sizeBodyMedium = 14;
  static const double sizeBodySmall = 12;
  static const double sizeLabelLarge = 14;
  static const double sizeLabelMedium = 12;
  static const double sizeLabelSmall = 11;
  static const double sizePriceSmall = 20;
  static const double sizePriceMedium = 28;
  static const double sizePriceLarge = 40;
  static const double sizePriceXLarge = 56;

  /// Line heights
  static const double lhTight = 1.1;
  static const double lhNormal = 1.5;
  static const double lhRelaxed = 1.6;
  static const double lhLoose = 1.75;

  /// Letter spacing
  static const double lsTight = -0.5;
  static const double lsNormal = 0;
  static const double lsWide = 0.5;
  static const double lsPrice = 0.3;
  static const double lsTracking = 1.0;

  // =============================================================================
  // SPACING SYSTEM (8px base)
  // =============================================================================

  static const double space0 = 0;
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space7 = 28;
  static const double space8 = 32;
  static const double space9 = 36;
  static const double space10 = 40;
  static const double space12 = 48;
  static const double space14 = 56;
  static const double space16 = 64;
  static const double space20 = 80;
  static const double space24 = 96;
  static const double space32 = 128;

  // Semantic spacing aliases
  static const double spacingXs = space1;
  static const double spacingSm = space2;
  static const double spacingMd = space4;
  static const double spacingLg = space6;
  static const double spacingXl = space8;
  static const double spacingXxl = space10;
  static const double spacingXxxl = space12;

  // Legacy spacing aliases
  @Deprecated('Use spacingXs instead')
  static const double spacingXxs = space1;

  // =============================================================================
  // RADIUS SYSTEM
  // =============================================================================

  static const double radiusNone = 0;
  static const double radiusXs = 4;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusXxl = 28;
  static const double radiusFull = 9999;

  // Semantic radius aliases
  static const double radiusCard = radiusLg;
  static const double radiusButton = radiusMd;
  static const double radiusInput = radiusSm;
  static const double radiusSheet = radiusXl;
  static const double radiusChip = radiusFull;
  static const double radiusAvatar = radiusFull;

  // =============================================================================
  // ELEVATION / SHADOW SYSTEM
  // =============================================================================

  static const double elevationNone = 0;
  static const double elevationXs = 2;
  static const double elevationSm = 4;
  static const double elevationMd = 8;
  static const double elevationLg = 16;
  static const double elevationXl = 24;
  static const double elevationXxl = 32;

  // Shadow colors - premium soft shadows
  static const Color shadowLight = Color(0x0D000000); // 5% black
  static const Color shadowMedium = Color(0x1A000000); // 10% black
  static const Color shadowDark = Color(0x26000000); // 15% black
  static const Color shadowColored = Color(0x1A00E676); // 10% green
  static const Color shadowElevated = Color(0x1F000000); // 12% black

  // =============================================================================
  // BORDER WIDTHS
  // =============================================================================

  static const double borderHairline = 0.5;
  static const double borderThin = 1;
  static const double borderMedium = 1.5;
  static const double borderThick = 2;
  static const double borderFocus = 2.5;

  // =============================================================================
  // GLASSMORPHISM PRESETS
  // =============================================================================

  static const double glassBlurLightSigma = 10;
  static const double glassBlurMediumSigma = 20;
  static const double glassBlurHeavySigma = 30;

  static const double glassOpacityLight = 0.08; // 8% white
  static const double glassOpacityMedium = 0.12; // 12% white
  static const double glassOpacityHeavy = 0.16; // 16% white

  // =============================================================================
  // ANIMATION TOKENS
  // =============================================================================

  // Durations
  static const Duration durationInstant = Duration(milliseconds: 0);
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 250);
  static const Duration durationSlow = Duration(milliseconds: 350);
  static const Duration durationSlowest = Duration(milliseconds: 500);
  static const Duration durationEnter = Duration(milliseconds: 400);
  static const Duration durationExit = Duration(milliseconds: 300);

  // Spring curves (Flutter uses cubic-bezier approximations)
  static const Curve springGentle = Cubic(0.34, 1.56, 0.64, 1);      // Overshoot
  static const Curve springSmooth = Cubic(0.16, 1, 0.3, 1);          // Material spring
  static const Curve springBouncy = Cubic(0.68, -0.55, 0.27, 1.55);  // Bouncy
  static const Curve springSnappy = Cubic(0.4, 0, 0.2, 1);           // Snappy
  static const Curve easeOutQuart = Cubic(0.25, 1, 0.5, 1);
  static const Curve easeOutExpo = Cubic(0.19, 1, 0.22, 1);
  static const Curve easeOutCubic = Cubic(0.33, 1, 0.68, 1);

  // Stagger
  static const Duration staggerBase = Duration(milliseconds: 60);
  static const Duration staggerItem = Duration(milliseconds: 40);

  // =============================================================================
  // HAPTIC FEEDBACK INTENSITIES
  // =============================================================================

  static const double buttonHeightSm = 40;
  static const double buttonHeightMd = 48;
  static const double buttonHeightLg = 56;
  static const double buttonHeightXl = 64;

  static const double inputHeightSm = 40;
  static const double inputHeightMd = 48;
  static const double inputHeightLg = 56;

  static const double avatarXs = 24;
  static const double avatarSm = 32;
  static const double avatarMd = 40;
  static const double avatarLg = 48;
  static const double avatarXl = 64;
  static const double avatarXxl = 80;
  static const double avatarHero = 120;

  static const double iconXs = 12;
  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;
  static const double iconXl = 28;
  static const double iconXxl = 32;
  static const double iconHero = 48;

  static const double chipHeightSm = 28;
  static const double chipHeightMd = 32;
  static const double chipHeightLg = 36;

  // =============================================================================
  // BREAKPOINTS
  // =============================================================================

  static const double bpMobile = 600;
  static const double bpTablet = 900;
  static const double bpDesktop = 1200;
  static const double bpWide = 1800;
  static const double phoneFrameWidth = 430;
  static const double phoneFrameMargin = 16;

  // =============================================================================
  // Z-INDEX LAYERS
  // =============================================================================

  static const int zBase = 0;
  static const int zDropdown = 100;
  static const int zSticky = 200;
  static const int zSheet = 300;
  static const int zModal = 400;
  static const int zPopover = 500;
  static const int zTooltip = 600;
  static const int zToast = 700;
  static const int zOverlay = 800;

  static const String noiseTextureAsset = 'assets/images/noise_texture.png';
  static const String gradientMeshDarkAsset =
      'assets/images/gradient_mesh_dark.jpg';
  static const String gradientMeshLightAsset =
      'assets/images/gradient_mesh_light.jpg';

  // =============================================================================
  // VEHICLE SPECIFIC
  // =============================================================================

  static const Map<String, Color> vehicleColors = {
    'bike': Color(0xFF8B5CF6),       // Violet
    'three_wheeler': Color(0xFF06B6D4), // Cyan
    'mini_truck': Color(0xFFF97316),  // Orange
    'pickup': Color(0xFFEF4444),     // Red
    'ev_bike': Color(0xFF00E676),    // Green
    'large_truck': Color(0xFF6366F1), // Indigo
    'house_shifting': Color(0xFFEC4899), // Pink
    'business': Color(0xFF8B5CF6),    // Purple
  };

  static const Map<String, String> vehicleIcons = {
    'bike': 'assets/icons/vehicle_bike_3d.png',
    'three_wheeler': 'assets/icons/vehicle_3wheeler_3d.png',
    'mini_truck': 'assets/icons/vehicle_minitruck_3d.png',
    'pickup': 'assets/icons/vehicle_pickup_3d.png',
    'ev_bike': 'assets/icons/vehicle_ev_bike_3d.png',
    'large_truck': 'assets/icons/vehicle_largetruck_3d.png',
    'house_shifting': 'assets/icons/vehicle_houseshifting_3d.png',
    'business': 'assets/icons/vehicle_business_3d.png',
  };

  static const Map<String, String> vehicleLabels = {
    'bike': 'Bike',
    'three_wheeler': '3-Wheeler',
    'mini_truck': 'Mini Truck',
    'pickup': 'Pickup',
    'ev_bike': 'EV Bike',
    'large_truck': 'Large Truck',
    'house_shifting': 'House Shifting',
    'business': 'Business Delivery',
  };

  static const Map<String, int> vehicleCapacityKg = {
    'bike': 20,
    'three_wheeler': 500,
    'mini_truck': 750,
    'pickup': 1500,
    'ev_bike': 15,
    'large_truck': 5000,
    'house_shifting': 3000,
    'business': 1000,
  };

  // =============================================================================
  // STATUS COLORS
  // =============================================================================

  static const Map<String, Color> statusColors = {
    'SEARCHING': green500,
    'DRIVER_ASSIGNED': info500,
    'ARRIVED': Color(0xFF8B5CF6),
    'PICKED_UP': Color(0xFF06B6D4),
    'IN_TRANSIT': Color(0xFF6366F1),
    'DELIVERED': success500,
    'CANCELLED': error500,
    'NO_DRIVER_FOUND': error500,
    'SCHEDULED': Color(0xFF8B5CF6),
    'PENDING': warning500,
  };

  // =============================================================================
  // CATEGORY ICONS
  // =============================================================================

  static const Map<String, IconData> categoryIcons = {
    'parcel': Icons.inventory_2_outlined,
    'bike': Icons.two_wheeler_outlined,
    'three_wheeler': Icons.local_shipping_outlined,
    'mini_truck': Icons.local_shipping_outlined,
    'pickup': Icons.local_shipping_outlined,
    'large_truck': Icons.local_shipping_outlined,
    'house_shifting': Icons.home_outlined,
    'business': Icons.business_outlined,
    'documents': Icons.description_outlined,
    'electronics': Icons.devices_outlined,
    'furniture': Icons.chair_outlined,
    'groceries': Icons.shopping_cart_outlined,
    'fragile': Icons.broken_image_outlined,
  };


  @Deprecated('Use bottomSheetMaxHeightRatio instead')
  static const double bottomSheetMaxHeightRatio = 0.9;

  @Deprecated('Use mapToolbarPadding instead')
  static const double mapToolbarPadding = spacingLg;

  @Deprecated('Use mapMarkerSize instead')
  static const double mapMarkerSize = 40.0;

  @Deprecated('Use space20 instead')
  static const double spacingHuge = space20;

  // =============================================================================
  // HELPER METHODS
  // =============================================================================

  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }

  static Color lerp(Color a, Color b, double t) {
    return Color.lerp(a, b, t)!;
  }

  static Color surfaceFor(bool isDark) {
    return isDark ? black900 : white;
  }

  static Color onSurfaceFor(bool isDark) {
    return isDark ? white : black900;
  }

  static Color cardSurfaceFor(bool isDark) {
    return isDark ? black800 : white;
  }

  static Color variantSurfaceFor(bool isDark) {
    return isDark ? black700 : white100;
  }

  static Color outlineFor(bool isDark) {
    return isDark ? hairlineDark : hairlineLight;
  }

  static LinearGradient brandGradient(bool isDark) {
    return LinearGradient(
      colors: isDark 
          ? [green500, green600]
          : [green600, green700],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static LinearGradient surfaceGradient(bool isDark) {
    return LinearGradient(
      colors: isDark 
          ? [black800, black900]
          : [white, white50],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  static LinearGradient cardGradient(bool isDark, {Color? accent}) {
    if (accent != null) {
      return LinearGradient(
        colors: isDark 
            ? [accent.withValues(alpha: 0.15), black800]
            : [accent.withValues(alpha: 0.1), white],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return LinearGradient(
      colors: isDark 
          ? [black800, black800]
          : [white, white],
    );
  }
}
