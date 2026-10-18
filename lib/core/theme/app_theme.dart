import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/colors.dart';
import '../constants/dimensions.dart';
import 'text_styles.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final ext = AppColorsExtension.light;
    final colorScheme = ColorScheme.light(
      primary: ext.primary,
      onPrimary: ext.onPrimary,
      primaryContainer: ext.primaryContainer,
      secondary: ext.secondary,
      onSecondary: ext.onSecondary,
      secondaryContainer: ext.secondaryContainer,
      surface: ext.surface,
      onSurface: ext.onSurface,
      error: ext.error,
      onError: Colors.white,
      errorContainer: ext.errorLight,
      outline: ext.outline,
      outlineVariant: ext.outlineVariant,
      shadow: ext.shadow,
    );

    return _buildTheme(colorScheme, ext, Brightness.light);
  }

  static ThemeData get darkTheme {
    final ext = AppColorsExtension.dark;
    final colorScheme = ColorScheme.dark(
      primary: ext.primary,
      onPrimary: ext.onPrimary,
      primaryContainer: ext.primaryContainer,
      secondary: ext.secondary,
      onSecondary: ext.onSecondary,
      secondaryContainer: ext.secondaryContainer,
      surface: ext.surface,
      onSurface: ext.onSurface,
      error: ext.error,
      onError: ext.onSecondary,
      errorContainer: ext.errorLight,
      outline: ext.outline,
      outlineVariant: ext.outlineVariant,
      shadow: ext.shadow,
    );

    return _buildTheme(colorScheme, ext, Brightness.dark);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme, AppColorsExtension ext, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: ext.surface,
      canvasColor: ext.surface,
      extensions: [ext],
      textTheme: _buildTextTheme(colorScheme),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: ext.surface,
        foregroundColor: ext.onSurface,
        elevation: AppDimensions.elevationNone,
        centerTitle: true,
        titleTextStyle: AppTextStyles.headlineSmall.copyWith(color: ext.onSurface),
        iconTheme: IconThemeData(color: ext.onSurface),
        actionsIconTheme: IconThemeData(color: ext.onSurface),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: ext.surfaceCard,
        elevation: AppDimensions.elevationSm,
        shadowColor: ext.shadow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          side: BorderSide(color: ext.outlineVariant, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ext.primary,
          foregroundColor: ext.onPrimary,
          elevation: AppDimensions.elevationNone,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingLg,
            vertical: AppDimensions.spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          ),
          textStyle: AppTextStyles.labelLarge,
          minimumSize: const Size(double.infinity, AppDimensions.buttonHeightMd),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ext.secondary,
          foregroundColor: ext.onSecondary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingLg,
            vertical: AppDimensions.spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          ),
          textStyle: AppTextStyles.labelLarge,
          minimumSize: const Size(double.infinity, AppDimensions.buttonHeightMd),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ext.primary,
          side: BorderSide(color: ext.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingLg,
            vertical: AppDimensions.spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          ),
          textStyle: AppTextStyles.labelLarge.copyWith(color: ext.primary),
          minimumSize: const Size(double.infinity, AppDimensions.buttonHeightMd),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ext.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingMd,
            vertical: AppDimensions.spacingSm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          ),
          textStyle: AppTextStyles.labelLarge.copyWith(color: ext.primary),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? ext.surfaceCard : ext.surfaceCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingLg,
          vertical: AppDimensions.spacingMd,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          borderSide: BorderSide(color: ext.outline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          borderSide: BorderSide(color: ext.outline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          borderSide: BorderSide(color: ext.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          borderSide: BorderSide(color: ext.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          borderSide: BorderSide(color: ext.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          borderSide: BorderSide(color: ext.outlineVariant, width: 1),
        ),
        labelStyle: AppTextStyles.bodyMedium.copyWith(color: ext.onSurfaceVariant),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: ext.onSurfaceVariant.withValues(alpha: 0.6)),
        errorStyle: AppTextStyles.bodySmall.copyWith(color: ext.error),
        prefixIconColor: ext.onSurfaceVariant,
        suffixIconColor: ext.onSurfaceVariant,
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: ext.surfaceCard,
        elevation: AppDimensions.elevationLg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLg)),
        ),
        modalBackgroundColor: ext.surfaceCard,
        dragHandleColor: ext.outline,
        showDragHandle: true,
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: ext.surfaceCard,
        elevation: AppDimensions.elevationLg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        titleTextStyle: AppTextStyles.headlineSmall.copyWith(color: ext.onSurface),
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: ext.onSurface),
        surfaceTintColor: Colors.transparent,
      ),

      // SnackBar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ext.secondary,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: ext.onSecondary),
        actionTextColor: ext.primaryLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusSm)),
        behavior: SnackBarBehavior.floating,
        elevation: AppDimensions.elevationMd,
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: ext.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: ext.surfaceVariant,
        selectedColor: ext.primaryContainer,
        labelStyle: AppTextStyles.labelMedium.copyWith(color: ext.onSurface),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMd,
          vertical: AppDimensions.spacingXs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          side: BorderSide(color: ext.outline, width: 1),
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    return GoogleFonts.interTextTheme().copyWith(
      displayLarge: AppTextStyles.displayLarge,
      displayMedium: AppTextStyles.displayMedium,
      displaySmall: AppTextStyles.displaySmall,
      headlineLarge: AppTextStyles.headlineLarge,
      headlineMedium: AppTextStyles.headlineMedium,
      headlineSmall: AppTextStyles.headlineSmall,
      titleLarge: AppTextStyles.titleLarge,
      titleMedium: AppTextStyles.titleMedium,
      titleSmall: AppTextStyles.titleSmall,
      bodyLarge: AppTextStyles.bodyLarge,
      bodyMedium: AppTextStyles.bodyMedium,
      bodySmall: AppTextStyles.bodySmall,
      labelLarge: AppTextStyles.labelLarge,
      labelMedium: AppTextStyles.labelMedium,
      labelSmall: AppTextStyles.labelSmall,
    ).apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );
  }
}