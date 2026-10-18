import 'package:flutter/material.dart';

import '../../../../../core/constants/colors.dart';
import '../../../../../core/constants/dimensions.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../core/utils/helpers.dart';
import '../../data/chat_service.dart';

class ChatMessageBubble extends StatefulWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.language = 'en',
  });

  final ChatMessage message;
  final bool isMine;
  final String language;

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble> {
  bool _showOriginal = false;

  @override
  void didUpdateWidget(covariant ChatMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.id != widget.message.id ||
        oldWidget.language != widget.language) {
      _showOriginal = false;
    }
  }

  String get _translatedText {
    final computed = ChatService.autoTranslate(
      widget.message.text,
      widget.language,
    );
    if (computed != widget.message.text) return computed;
    final stored = widget.message.translation[widget.language];
    if (stored != null && stored != widget.message.text) return stored;
    return widget.message.text;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final original = widget.message.text;
    final translated = widget.isMine ? original : _translatedText;
    final hasTranslation = !widget.isMine && translated != original;
    final visibleText = hasTranslation && !_showOriginal
        ? translated
        : original;

    return Align(
      alignment: widget.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingLg,
            vertical: AppDimensions.spacingXs,
          ),
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.spacingMd,
            AppDimensions.spacingSm,
            AppDimensions.spacingMd,
            AppDimensions.spacingXs,
          ),
          decoration: BoxDecoration(
            gradient: widget.isMine ? AppColors.brandGradient : null,
            color: widget.isMine ? null : colors.glass,
            border: widget.isMine
                ? null
                : Border.all(color: colors.glassBorder, width: 1),
            borderRadius: BorderRadiusDirectional.only(
              topStart: const Radius.circular(AppDimensions.radiusLg),
              topEnd: const Radius.circular(AppDimensions.radiusLg),
              bottomStart: Radius.circular(
                widget.isMine ? AppDimensions.radiusLg : AppDimensions.radiusXs,
              ),
              bottomEnd: Radius.circular(
                widget.isMine ? AppDimensions.radiusXs : AppDimensions.radiusLg,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.10),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                visibleText,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: widget.isMine ? colors.onPrimary : colors.onSurface,
                ),
              ),
              if (hasTranslation) ...[
                const SizedBox(height: AppDimensions.spacingXxs),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _showOriginal = !_showOriginal),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.translate_rounded,
                        size: AppDimensions.iconXs,
                        color: widget.isMine
                            ? colors.onPrimary.withValues(alpha: 0.8)
                            : colors.primary,
                      ),
                      const SizedBox(width: AppDimensions.spacingXxs),
                      Text(
                        _showOriginal ? 'View translation' : 'View original',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: widget.isMine
                              ? colors.onPrimary.withValues(alpha: 0.85)
                              : colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppDimensions.spacingXxs),
              Text(
                AppHelpers.formatTime(widget.message.createdAt),
                style: AppTextStyles.labelSmall.copyWith(
                  color: widget.isMine
                      ? colors.onPrimary.withValues(alpha: 0.75)
                      : colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
