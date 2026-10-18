import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/constants/colors.dart';
import '../../../../../core/constants/dimensions.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../data/chat_service.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/quick_reply_chips.dart';

enum ChatPeerRole { customer, driver }

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.bookingId,
    required this.peerName,
    required this.peerRole,
  });

  final String bookingId;
  final String peerName;
  final ChatPeerRole peerRole;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatService _service = ChatService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final Stream<List<ChatMessage>> _messages;
  String _language = 'en';
  int _knownCount = 0;

  @override
  void initState() {
    super.initState();
    _messages = _service.messages(widget.bookingId);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String get _myId => FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

  String get _myRole =>
      widget.peerRole == ChatPeerRole.driver ? 'customer' : 'driver';

  void _snapToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      if (_scrollController.offset > 80) return;
      _scrollController.animateTo(
        0,
        duration: AppConstants.shortAnimation,
        curve: AppConstants.defaultCurve,
      );
    });
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    _controller.clear();
    try {
      await _service.send(
        bookingId: widget.bookingId,
        senderId: _myId,
        senderRole: _myRole,
        text: text,
      );
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, 'Message could not be sent. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        surfaceTintColor: colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: AppDimensions.iconSm,
            color: colors.onSurface,
          ),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: AppDimensions.avatarSm / 2,
              backgroundColor: colors.primaryContainer,
              child: Icon(
                widget.peerRole == ChatPeerRole.driver
                    ? Icons.local_shipping_outlined
                    : Icons.person_outline_rounded,
                size: AppDimensions.iconSm,
                color: colors.primary,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.peerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: AppDimensions.iconXs,
                        height: AppDimensions.iconXs,
                        decoration: BoxDecoration(
                          color: colors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingXxs),
                      Text(
                        'Online',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList(colors)),
          QuickReplyChips(onSend: _send, language: _language),
          ChatInputBar(
            controller: _controller,
            language: _language,
            onLanguageChanged: (value) => setState(() => _language = value),
            onSend: _send,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(AppColorsExtension colors) {
    return StreamBuilder<List<ChatMessage>>(
      stream: _messages,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _emptyState(
            colors,
            icon: Icons.lock_outline_rounded,
            title: 'Chat is not available for this trip yet',
            subtitle: 'Messages appear once your trip is active.',
          );
        }
        if (!snapshot.hasData) {
          return Center(
            child: SizedBox(
              width: AppDimensions.iconLg,
              height: AppDimensions.iconLg,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
              ),
            ),
          );
        }

        final messages = snapshot.data!;
        if (messages.length != _knownCount) {
          _knownCount = messages.length;
          _snapToLatest();
        }
        if (messages.isEmpty) {
          return _emptyState(
            colors,
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Start the conversation',
            subtitle: 'Use a quick reply below - no typing needed.',
          );
        }

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingMd),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[messages.length - 1 - index];
            return ChatMessageBubble(
              message: message,
              isMine: message.senderId == _myId,
              language: _language,
            );
          },
        );
      },
    );
  }

  Widget _emptyState(
    AppColorsExtension colors, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: AppDimensions.iconXxl, color: colors.onSurfaceVariant),
            const SizedBox(height: AppDimensions.spacingMd),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleSmall.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: AppDimensions.spacingXs),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
