import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../constants/colors.dart';
import '../theme/design_tokens.dart';
import 'design_system.dart';

/// A premium bottom sheet
class PDBottomSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  final Widget? titleAction;
  final bool isScrollable;
  final bool showDragHandle;
  final double? maxHeight;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const PDBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.titleAction,
    this.isScrollable = true,
    this.showDragHandle = true,
    this.maxHeight,
    this.backgroundColor,
    this.borderRadius,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    Widget? titleAction,
    bool isScrollable = true,
    bool showDragHandle = true,
    double? maxHeight,
    Color? backgroundColor,
    BorderRadius? borderRadius,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: DesignTokens.glassBlack20,
      builder: (context) => PDBottomSheet(
        title: title,
        titleAction: titleAction,
        isScrollable: isScrollable,
        showDragHandle: showDragHandle,
        maxHeight: maxHeight,
        backgroundColor: backgroundColor,
        borderRadius: borderRadius,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ?? (isDark ? DesignTokens.black800 : DesignTokens.white);
    final radius = borderRadius ?? BorderRadius.vertical(
      top: Radius.circular(DesignTokens.radiusSheet),
    );

    return Container(
      constraints: maxHeight != null
          ? BoxConstraints(maxHeight: maxHeight!)
          : BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: radius,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDragHandle)
            Container(
              margin: EdgeInsets.only(top: DesignTokens.spacingSm),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.outlineVariant,
                borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
              ),
            ),
          if (title != null || titleAction != null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                DesignTokens.spacingLg,
                DesignTokens.spacingMd,
                DesignTokens.spacingLg,
                DesignTokens.spacingSm,
              ),
              child: Row(
                children: [
                  if (title != null)
                    Text(
                      title!,
                      style: TokenTextStyles.titleLarge(
                        color: colors.onSurface,
                        weight: DesignTokens.wSemiBold,
                      ),
                    ),
                  if (titleAction != null) ...[
                    const Spacer(),
                    titleAction!,
                  ],
                ],
              ),
            ),
          if (title != null || titleAction != null)
            Divider(color: colors.outlineVariant, height: 1, indent: DesignTokens.spacingLg, endIndent: DesignTokens.spacingLg),
          Flexible(
            child: isScrollable
                ? SingleChildScrollView(
                    padding: EdgeInsets.all(DesignTokens.spacingLg),
                    child: child,
                  )
                : Padding(
                    padding: EdgeInsets.all(DesignTokens.spacingLg),
                    child: child,
                  ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    ).animate().fadeIn(
      duration: DesignTokens.durationNormal,
    ).slideY(
      begin: 0.1,
      end: 0,
      duration: DesignTokens.durationNormal,
      curve: DesignTokens.springSmooth,
    );
  }
}

/// A premium modal dialog
class PDDialog extends StatelessWidget {
  final Widget child;
  final String? title;
  final String? subtitle;
  final List<Widget>? actions;
  final MainAxisAlignment actionsAlignment;
  final double? maxWidth;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final bool barrierDismissible;

  const PDDialog({
    super.key,
    this.child = const SizedBox.shrink(),
    this.title,
    this.subtitle,
    this.actions,
    this.actionsAlignment = MainAxisAlignment.end,
    this.maxWidth,
    this.backgroundColor,
    this.borderRadius,
    this.barrierDismissible = true,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    Widget child = const SizedBox.shrink(),
    String? title,
    String? subtitle,
    List<Widget>? actions,
    MainAxisAlignment actionsAlignment = MainAxisAlignment.end,
    double? maxWidth,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: DesignTokens.glassBlack20,
      builder: (context) => PDDialog(
        title: title,
        subtitle: subtitle,
        actions: actions,
        actionsAlignment: actionsAlignment,
        maxWidth: maxWidth,
        backgroundColor: backgroundColor,
        borderRadius: borderRadius,
        barrierDismissible: barrierDismissible,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ?? (isDark ? DesignTokens.black800 : DesignTokens.white);
    final radius = borderRadius ?? BorderRadius.circular(DesignTokens.radiusXl);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: maxWidth ?? 500,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          margin: EdgeInsets.all(DesignTokens.spacingLg),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: isDark ? DesignTokens.shadowDark : DesignTokens.shadowElevated,
                blurRadius: DesignTokens.elevationXl,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null || subtitle != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    DesignTokens.spacingLg,
                    DesignTokens.spacingLg,
                    DesignTokens.spacingLg,
                    subtitle != null ? DesignTokens.spacingXs : DesignTokens.spacingMd,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null)
                        Text(
                          title!,
                          style: TokenTextStyles.headlineSmall(
                            color: colors.onSurface,
                            weight: DesignTokens.wSemiBold,
                          ),
                        ),
                      if (subtitle != null) ...[
                        SizedBox(height: DesignTokens.space1),
                        Text(
                          subtitle!,
                          style: TokenTextStyles.bodyMedium(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
              if (title != null || subtitle != null)
                Divider(color: colors.outlineVariant, height: 1, indent: DesignTokens.spacingLg, endIndent: DesignTokens.spacingLg),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(DesignTokens.spacingLg),
                  child: child,
                ),
              ),
              if (actions != null && actions!.isNotEmpty) ...[
                Divider(color: colors.outlineVariant, height: 1, indent: DesignTokens.spacingLg, endIndent: DesignTokens.spacingLg),
                Padding(
                  padding: EdgeInsets.all(DesignTokens.spacingMd),
                  child: Row(
                    mainAxisAlignment: actionsAlignment,
                    children: actions!.map((action) {
                      if (action != actions!.last) {
                        return Padding(
                          padding: EdgeInsets.only(right: DesignTokens.spacingSm),
                          child: action,
                        );
                      }
                      return action;
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ).animate().fadeIn(
        duration: DesignTokens.durationFast,
      ).scale(
        begin: const Offset(0.95, 0.95),
        end: const Offset(1, 1),
        duration: DesignTokens.durationNormal,
        curve: DesignTokens.springSmooth,
      ),
    );
  }
}

/// A confirmation dialog
Future<bool?> showPDConfirmation({
  required BuildContext context,
  required String title,
  required String message,
  String confirmText = 'Confirm',
  String cancelText = 'Cancel',
  bool isDestructive = false,
  bool barrierDismissible = true,
}) {
  return PDDialog.show<bool>(
    context: context,
    title: title,
    subtitle: message,
    actions: [
      PDButton(
        label: cancelText,
        variant: PDButtonVariant.ghost,
        size: PDButtonSize.md,
        onPressed: () => Navigator.of(context).pop(false),
      ),
      PDButton(
        label: confirmText,
        variant: isDestructive ? PDButtonVariant.destructive : PDButtonVariant.primary,
        size: PDButtonSize.md,
        onPressed: () => Navigator.of(context).pop(true),
      ),
    ],
  );
}

/// A toast/snackbar replacement
class PDToast {
  static void show({
    required BuildContext context,
    required String message,
    PDToastType type = PDToastType.info,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    final colors = context.colors;
    
    Color backgroundColor;
    IconData icon;
    
    switch (type) {
      case PDToastType.success:
        backgroundColor = colors.success;
        icon = Icons.check_circle_rounded;
        break;
      case PDToastType.error:
        backgroundColor = colors.error;
        icon = Icons.error_rounded;
        break;
      case PDToastType.warning:
        backgroundColor = colors.warning;
        icon = Icons.warning_rounded;
        break;
      case PDToastType.info:
        backgroundColor = colors.info;
        icon = Icons.info_rounded;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: DesignTokens.iconMd),
            SizedBox(width: DesignTokens.spacingSm),
            Expanded(
              child: Text(
                message,
                style: TokenTextStyles.bodyMedium(color: Colors.white),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(width: DesignTokens.spacingMd),
              TextButton(
                onPressed: () {
                  onAction();
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
                child: Text(
                  actionLabel,
                  style: TokenTextStyles.labelMedium(
                    color: Colors.white,
                    weight: DesignTokens.wBold,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
        margin: EdgeInsets.all(DesignTokens.spacingLg),
        duration: duration,
        padding: EdgeInsets.all(DesignTokens.spacingMd),
      ),
    );
  }

  static void success(BuildContext context, String message, {VoidCallback? onAction, String? actionLabel}) {
    show(context: context, message: message, type: PDToastType.success, onAction: onAction, actionLabel: actionLabel);
  }

  static void error(BuildContext context, String message, {VoidCallback? onAction, String? actionLabel}) {
    show(context: context, message: message, type: PDToastType.error, onAction: onAction, actionLabel: actionLabel);
  }

  static void warning(BuildContext context, String message, {VoidCallback? onAction, String? actionLabel}) {
    show(context: context, message: message, type: PDToastType.warning, onAction: onAction, actionLabel: actionLabel);
  }

  static void info(BuildContext context, String message, {VoidCallback? onAction, String? actionLabel}) {
    show(context: context, message: message, type: PDToastType.info, onAction: onAction, actionLabel: actionLabel);
  }
}

enum PDToastType {
  success,
  error,
  warning,
  info,
}

/// A loading overlay
class PDLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;
  final Color? backgroundColor;

  const PDLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: backgroundColor ?? (isDark 
                  ? DesignTokens.black900.withValues(alpha: 0.7)
                  : DesignTokens.white.withValues(alpha: 0.7)),
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(DesignTokens.spacingXl),
                  decoration: BoxDecoration(
                    color: isDark ? DesignTokens.black800 : DesignTokens.white,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? DesignTokens.shadowDark : DesignTokens.shadowElevated,
                        blurRadius: DesignTokens.elevationLg,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                        ),
                      ),
                      if (message != null) ...[
                        SizedBox(height: DesignTokens.spacingMd),
                        Text(
                          message!,
                          style: TokenTextStyles.bodyMedium(color: colors.onSurface),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}