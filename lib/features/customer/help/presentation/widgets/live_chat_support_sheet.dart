import 'package:flutter/material.dart';
import '../../../../../core/constants/colors.dart';
import '../../../../../core/constants/dimensions.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../core/widgets/app_toast.dart';

class LiveChatSupportSheet extends StatefulWidget {
  final String? activeBookingId;

  const LiveChatSupportSheet({
    super.key,
    this.activeBookingId,
  });

  static Future<void> show(BuildContext context, {String? activeBookingId}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LiveChatSupportSheet(activeBookingId: activeBookingId),
    );
  }

  @override
  State<LiveChatSupportSheet> createState() => _LiveChatSupportSheetState();
}

class _LiveChatSupportSheetState extends State<LiveChatSupportSheet> {
  final _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'text': 'Hello! PickDrop Priority Support here. We answer active trips in under 3 minutes.',
      'time': 'Just now',
    },
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage([String? quickReply]) {
    final text = quickReply ?? _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'isUser': true,
        'text': text,
        'time': 'Just now',
      });
      if (quickReply == null) _messageController.clear();
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'isUser': false,
          'text': 'We have received your priority message. An agent is reviewing your active trip details right now.',
          'time': 'Just now',
        });
      });
    });
  }

  void _requestInstantCallback() {
    AppToast.success(context, 'Callback scheduled! An agent will call you in < 2 mins.');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.fromLTRB(
        AppDimensions.spacingLg,
        AppDimensions.spacingMd,
        AppDimensions.spacingLg,
        AppDimensions.spacingMd + bottomInset,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.outline,
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingSm),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.support_agent_rounded, color: colors.primary, size: 20),
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Live Priority Support', style: AppTextStyles.titleMedium),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.successLight,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
                          ),
                          child: Text(
                            'SLA < 3 MIN',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: colors.success,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      widget.activeBookingId != null ? 'Trip: ${widget.activeBookingId}' : 'General Inquiries',
                      style: AppTextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.phone_callback_rounded),
                tooltip: 'Request Callback',
                color: colors.primary,
                onPressed: _requestInstantCallback,
              ),
            ],
          ),
          const Divider(height: 16),
          // Quick action chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ActionChip(
                  label: const Text('Driver Stopped'),
                  onPressed: () => _sendMessage('My driver seems stopped and is not moving.'),
                ),
                const SizedBox(width: 6),
                ActionChip(
                  label: const Text('Asked Extra Cash'),
                  onPressed: () => _sendMessage('Driver is demanding extra money above price lock.'),
                ),
                const SizedBox(width: 6),
                ActionChip(
                  label: const Text('Emergency Assistance'),
                  onPressed: () => _sendMessage('I need urgent assistance with my cargo.'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final msg = _messages[i];
                final isUser = msg['isUser'] as bool;
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser ? colors.primary : colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    ),
                    child: Text(
                      msg['text'] as String,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isUser ? colors.onPrimary : colors.onSurface,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    filled: true,
                    fillColor: colors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              IconButton(
                icon: const Icon(Icons.send_rounded),
                color: colors.primary,
                onPressed: () => _sendMessage(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
