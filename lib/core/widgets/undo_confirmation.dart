import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../theme/design_tokens.dart';
import 'dialogs/dialogs.dart';

Future<bool> showUndoConfirmation(
  BuildContext context, {
  required String title,
  required String message,
  required String actionLabel,
}) {
  final completer = Completer<bool>();
  final colors = context.colors;

  try {
    final messenger = ScaffoldMessenger.of(context);
    final controller = messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        backgroundColor: colors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TokenTextStyles.titleSmall(
                color: colors.onSurface,
                weight: DesignTokens.wSemiBold,
              ),
            ),
            const SizedBox(height: DesignTokens.space1),
            Text(
              message,
              style: TokenTextStyles.bodySmall(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: actionLabel,
          textColor: colors.primary,
          onPressed: () {
            if (!completer.isCompleted) completer.complete(true);
          },
        ),
      ),
    );
    controller.closed.then((_) {
      if (!completer.isCompleted) completer.complete(false);
    });
  } catch (_) {
    if (!completer.isCompleted) completer.complete(false);
  }

  return completer.future;
}

Future<bool> showFriendlyConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Not now',
  bool isDestructive = false,
}) async {
  final result = await AppDialog.showConfirmation(
    context: context,
    title: title,
    message: message,
    confirmText: confirmLabel,
    cancelText: cancelLabel,
    isDestructive: isDestructive,
  );
  return result ?? false;
}
