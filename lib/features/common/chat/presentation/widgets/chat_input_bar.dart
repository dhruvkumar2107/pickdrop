import 'package:flutter/material.dart';

import '../../../../../core/constants/colors.dart';
import '../../../../../core/constants/dimensions.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/text_styles.dart';

class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.language,
    required this.onLanguageChanged,
    required this.onSend,
  });

  final TextEditingController controller;
  final String language;
  final ValueChanged<String> onLanguageChanged;
  final ValueChanged<String> onSend;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.spacingLg,
          AppDimensions.spacingSm,
          AppDimensions.spacingLg,
          AppDimensions.spacingSm,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceCard,
          border: Border(top: BorderSide(color: colors.outline, width: 1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.translate_rounded,
                  size: AppDimensions.iconSm,
                  color: colors.primary,
                ),
                const SizedBox(width: AppDimensions.spacingSm),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'en', label: Text('EN')),
                    ButtonSegment(value: 'hi', label: Text('हि')),
                    ButtonSegment(value: 'kn', label: Text('ಕನ್')),
                  ],
                  selected: <String>{language},
                  showSelectedIcon: false,
                  onSelectionChanged: (values) => onLanguageChanged(values.first),
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: WidgetStatePropertyAll(
                      BorderSide(color: colors.glassBorder),
                    ),
                    backgroundColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? colors.primary
                          : colors.glass,
                    ),
                    foregroundColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? colors.onPrimary
                          : colors.onSurface,
                    ),
                    textStyle: WidgetStatePropertyAll(AppTextStyles.labelSmall),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingSm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 3,
                    textInputAction: TextInputAction.send,
                    onSubmitted: onSend,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: colors.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                      filled: true,
                      fillColor: colors.glass,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacingMd,
                        vertical: AppDimensions.spacingMd,
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusFull),
                        borderSide: BorderSide(color: colors.glassBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusFull),
                        borderSide: BorderSide(color: colors.glassBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusFull),
                        borderSide: BorderSide(
                          color: colors.primary,
                          width: DesignTokens.borderFocus,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingSm),
                GestureDetector(
                  onTap: () => onSend(controller.text),
                  child: Container(
                    width: AppDimensions.buttonHeightMd,
                    height: AppDimensions.buttonHeightMd,
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.send_rounded,
                      size: AppDimensions.iconSm,
                      color: colors.onPrimary,
                    ),
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
