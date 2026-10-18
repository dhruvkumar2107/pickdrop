import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../constants/app_constants.dart';
import '../../constants/colors.dart';
import '../../constants/dimensions.dart';
import '../../constants/strings.dart';
import '../buttons/buttons.dart';
import '../inputs/inputs.dart';

class AppDialog {
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
    Color? barrierColor,
    bool useSafeArea = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? AppColors.shadow,
      useSafeArea: useSafeArea,
      builder: (context) => Dialog(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        child: child.animate().fadeIn(duration: AppConstants.mediumAnimation).scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1.0, 1.0),
              duration: AppConstants.mediumAnimation,
              curve: Curves.easeOutBack,
            ),
      ),
    );
  }

  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = AppStrings.yes,
    String cancelText = AppStrings.no,
    Color? confirmColor,
    bool isDestructive = false,
    Widget? icon,
  }) {
    return show<bool>(
      context: context,
      child: _ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        confirmColor: confirmColor ?? (isDestructive ? AppColors.error : AppColors.primary),
        isDestructive: isDestructive,
        icon: icon,
      ),
    );
  }

  static Future<void> showInfo({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = AppStrings.ok,
    Widget? icon,
    VoidCallback? onConfirm,
  }) {
    return show<void>(
      context: context,
      child: _InfoDialog(
        title: title,
        message: message,
        buttonText: buttonText,
        icon: icon,
        onConfirm: onConfirm,
      ),
    );
  }

  static Future<void> showError({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = AppStrings.ok,
    VoidCallback? onRetry,
  }) {
    return show<void>(
      context: context,
      child: _ErrorDialog(
        title: title,
        message: message,
        buttonText: buttonText,
        onRetry: onRetry,
      ),
    );
  }

  static Future<void> showSuccess({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = AppStrings.ok,
    VoidCallback? onConfirm,
  }) {
    return show<void>(
      context: context,
      child: _SuccessDialog(
        title: title,
        message: message,
        buttonText: buttonText,
        onConfirm: onConfirm,
      ),
    );
  }

  static Future<String?> showInput({
    required BuildContext context,
    required String title,
    required String hint,
    String? initialValue,
    String confirmText = AppStrings.ok,
    String cancelText = AppStrings.cancel,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    FormFieldValidator<String>? validator,
  }) {
    final controller = TextEditingController(text: initialValue);
    final formKey = GlobalKey<FormState>();

    return show<String>(
      context: context,
      child: _InputDialog(
        title: title,
        hint: hint,
        controller: controller,
        formKey: formKey,
        confirmText: confirmText,
        cancelText: cancelText,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
      ),
    );
  }
}

class _ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final Color confirmColor;
  final bool isDestructive;
  final Widget? icon;

  const _ConfirmationDialog({
    required this.title,
    required this.message,
    required this.confirmText,
    required this.cancelText,
    required this.confirmColor,
    required this.isDestructive,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(height: AppDimensions.spacingMd),
          ],
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          Row(
            children: [
              Expanded(
                child: OutlinedPrimaryButton(
                  text: cancelText,
                  onPressed: () => Navigator.of(context).pop(false),
                  borderColor: AppColors.outline,
                  textColor: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Expanded(
                child: PrimaryButton(
                  text: confirmText,
                  onPressed: () => Navigator.of(context).pop(true),
                  backgroundColor: confirmColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final Widget? icon;
  final VoidCallback? onConfirm;

  const _InfoDialog({
    required this.title,
    required this.message,
    required this.buttonText,
    this.icon,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(height: AppDimensions.spacingMd),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacingMd),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
              child: const Icon(Icons.info_outline, size: 32, color: AppColors.info),
            ),
            const SizedBox(height: AppDimensions.spacingMd),
          ],
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          PrimaryButton(
            text: buttonText,
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm?.call();
            },
          ),
        ],
      ),
    );
  }
}

class _ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback? onRetry;

  const _ErrorDialog({
    required this.title,
    required this.message,
    required this.buttonText,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingMd),
            decoration: BoxDecoration(
              color: AppColors.errorLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            ),
            child: const Icon(Icons.error_outline, size: 32, color: AppColors.error),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          Row(
            children: [
              if (onRetry != null)
                Expanded(
                  child: OutlinedPrimaryButton(
                    text: 'Retry',
                    onPressed: () {
                      Navigator.of(context).pop();
                      onRetry!.call();
                    },
                  ),
                ),
              if (onRetry != null) const SizedBox(width: AppDimensions.spacingMd),
              Expanded(
                child: PrimaryButton(
                  text: buttonText,
                  onPressed: () => Navigator.of(context).pop(),
                  backgroundColor: AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback? onConfirm;

  const _SuccessDialog({
    required this.title,
    required this.message,
    required this.buttonText,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingMd),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            ),
            child: const Icon(Icons.check_circle_outline, size: 32, color: AppColors.success),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          PrimaryButton(
            text: buttonText,
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm?.call();
            },
          ),
        ],
      ),
    );
  }
}

class _InputDialog extends StatefulWidget {
  final String title;
  final String hint;
  final TextEditingController controller;
  final GlobalKey<FormState> formKey;
  final String confirmText;
  final String cancelText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;

  const _InputDialog({
    required this.title,
    required this.hint,
    required this.controller,
    required this.formKey,
    required this.confirmText,
    required this.cancelText,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  @override
  State<_InputDialog> createState() => _InputDialogState();
}

class _InputDialogState extends State<_InputDialog> {
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
      ),
      child: Form(
        key: widget.formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingLg),
            CustomTextField(
              controller: widget.controller,
              hint: widget.hint,
              keyboardType: widget.keyboardType,
              inputFormatters: widget.inputFormatters,
              validator: widget.validator,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (widget.formKey.currentState?.validate() ?? false) {
                  Navigator.of(context).pop(widget.controller.text);
                }
              },
            ),
            const SizedBox(height: AppDimensions.spacingLg),
            Row(
              children: [
                Expanded(
                  child: OutlinedPrimaryButton(
                    text: widget.cancelText,
                    onPressed: () => Navigator.of(context).pop(),
                    borderColor: AppColors.outline,
                    textColor: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingMd),
                Expanded(
                  child: PrimaryButton(
                    text: widget.confirmText,
                    onPressed: () {
                      if (widget.formKey.currentState?.validate() ?? false) {
                        Navigator.of(context).pop(widget.controller.text);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class BottomSheetHelper {
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    bool isScrollControlled = true,
    bool isDismissible = true,
    bool enableDrag = true,
    Color? backgroundColor,
    double? maxHeight,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: AppColors.transparent,
      builder: (context) => Container(
        constraints: maxHeight != null
            ? BoxConstraints(maxHeight: maxHeight)
            : BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXl)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: AppDimensions.spacingMd),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outline,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
            ),
            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}

class SnackBarHelper {
  static void showSuccess(BuildContext context, String message, {VoidCallback? onAction, String? actionLabel}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.onSecondary, size: 20),
            const SizedBox(width: AppDimensions.spacingSm),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.onSecondary,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
        action: onAction != null && actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: AppColors.onSecondary,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  static void showError(BuildContext context, String message, {VoidCallback? onAction, String? actionLabel}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: AppColors.onSecondary, size: 20),
            const SizedBox(width: AppDimensions.spacingSm),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.onSecondary,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
        action: onAction != null && actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: AppColors.onSecondary,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  static void showInfo(BuildContext context, String message, {VoidCallback? onAction, String? actionLabel}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: AppColors.onSecondary, size: 20),
            const SizedBox(width: AppDimensions.spacingSm),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.onSecondary,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
        action: onAction != null && actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: AppColors.onSecondary,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  static void showWarning(BuildContext context, String message, {VoidCallback? onAction, String? actionLabel}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: AppColors.onSecondary, size: 20),
            const SizedBox(width: AppDimensions.spacingSm),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.onSecondary,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
        action: onAction != null && actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: AppColors.onSecondary,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }
}