import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../constants/dimensions.dart';

/// Rounded bottom sheet with drag handle, optional title and close button.
class AppBottomSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  final Widget? trailing;
  final bool showDragHandle;
  final bool showCloseButton;
  final bool isScrollable;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  const AppBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.trailing,
    this.showDragHandle = true,
    this.showCloseButton = true,
    this.isScrollable = false,
    this.padding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    final content = Padding(
      padding: padding ??
          const EdgeInsets.fromLTRB(
            AppDimensions.spacingLg,
            AppDimensions.spacingSm,
            AppDimensions.spacingLg,
            AppDimensions.spacingXl,
          ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showDragHandle)
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outline,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
              ),
            ),
          if (title != null || showCloseButton) ...[
            const SizedBox(height: AppDimensions.spacingMd),
            Row(
              children: [
                if (title != null)
                  Expanded(
                    child: Text(
                      title!,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                ?trailing,
                if (showCloseButton)
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(
                      Icons.close_rounded,
                      size: AppDimensions.iconMd,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ],
          Flexible(
            fit: FlexFit.loose,
            child: isScrollable
                ? SingleChildScrollView(child: child)
                : child,
          ),
        ],
      ),
    );

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? colors.surfaceCard,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.18),
            blurRadius: 32,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(top: false, child: content),
    );
  }
}

/// Shows [AppBottomSheet] styled consistently across the app.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? title,
  Widget? trailing,
  bool isDismissible = true,
  bool enableDrag = true,
  bool isScrollable = false,
  bool showCloseButton = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent,
    builder: (context) => AppBottomSheet(
      title: title,
      trailing: trailing,
      isScrollable: isScrollable,
      showCloseButton: showCloseButton,
      child: builder(context),
    ),
  );
}
