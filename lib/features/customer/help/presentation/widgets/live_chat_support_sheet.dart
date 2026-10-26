import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../../config/env/env_config.dart';
import '../../../../../core/constants/colors.dart';
import '../../../../../core/constants/dimensions.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../core/widgets/app_toast.dart';

/// Sends a support request to the PickDrop team (admin review console) and
/// lists the user's earlier requests with any replies. Replies also arrive
/// as notifications.
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

  /// Files a callback request; support calls the phone number on the account.
  static Future<void> requestCallback(
    BuildContext context, {
    String? bookingId,
  }) async {
    try {
      await FirebaseFunctions.instanceFor(region: EnvConfig.functionsRegion)
          .httpsCallable('createSupportTicket')
          .call({
            'message': 'Please call me back.',
            'category': 'CALLBACK',
            if (bookingId != null && bookingId.isNotEmpty) 'bookingId': bookingId,
          });
      if (context.mounted) {
        AppToast.success(
          context,
          'Callback requested. Our team will call your registered number.',
        );
      }
    } on FirebaseFunctionsException catch (e) {
      if (context.mounted) {
        AppToast.error(context, e.message ?? 'Could not request a callback.');
      }
    } catch (_) {
      if (context.mounted) AppToast.error(context, 'Could not request a callback.');
    }
  }

  @override
  State<LiveChatSupportSheet> createState() => _LiveChatSupportSheetState();
}

class _LiveChatSupportSheetState extends State<LiveChatSupportSheet> {
  final _messageController = TextEditingController();
  String _category = 'TRIP';
  bool _sending = false;

  static const _quickIssues = [
    ('Driver not moving', 'TRIP', 'My driver seems stopped and is not moving.'),
    ('Asked extra cash', 'PAYMENT', 'The driver is asking for money above the app fare.'),
    ('Goods damaged', 'DAMAGE', 'My goods were damaged during this trip.'),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.length < 5) {
      AppToast.warning(context, 'Describe the issue in a few words.');
      return;
    }
    setState(() => _sending = true);
    try {
      final bookingId = widget.activeBookingId;
      await FirebaseFunctions.instanceFor(region: EnvConfig.functionsRegion)
          .httpsCallable('createSupportTicket')
          .call({
            'message': text,
            'category': _category,
            if (bookingId != null && bookingId.isNotEmpty) 'bookingId': bookingId,
          });
      _messageController.clear();
      if (mounted) {
        AppToast.success(
          context,
          'Sent to PickDrop support. You will get a notification when we reply.',
        );
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        AppToast.error(context, e.message ?? 'Could not send. Please try again.');
      }
    } catch (_) {
      if (mounted) AppToast.error(context, 'Could not send. Please try again.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final uid = FirebaseAuth.instance.currentUser?.uid;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Message support', style: AppTextStyles.titleMedium),
          Text(
            widget.activeBookingId == null
                ? 'Our team reads every request and replies in the app.'
                : 'Your current trip is attached so we can check it quickly.',
            style: AppTextStyles.bodySmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Wrap(
            spacing: AppDimensions.spacingSm,
            children: [
              for (final (label, category, message) in _quickIssues)
                ActionChip(
                  label: Text(label),
                  onPressed: () => setState(() {
                    _category = category;
                    _messageController.text = message;
                  }),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Text('Your requests', style: AppTextStyles.labelLarge),
          const SizedBox(height: AppDimensions.spacingXs),
          Expanded(
            child: uid == null
                ? const SizedBox.shrink()
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('supportTickets')
                        .where('customerId', isEqualTo: uid)
                        .limit(20)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Text('Could not load your requests.');
                      }
                      final docs = [...?snapshot.data?.docs]
                        ..sort((a, b) => _millis(b).compareTo(_millis(a)));
                      if (docs.isEmpty) {
                        return Text(
                          'No requests yet.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        );
                      }
                      return ListView(
                        children: docs.map((doc) {
                          final data = doc.data();
                          final reply = data['reply'] as String?;
                          return Card(
                            child: ListTile(
                              title: Text(data['message']?.toString() ?? ''),
                              subtitle: Text(
                                reply == null
                                    ? 'Waiting for a reply'
                                    : 'Support: $reply',
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    hintText: 'Describe the issue',
                    counterText: '',
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Send',
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.send_rounded, color: colors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static int _millis(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final created = doc.data()['createdAt'];
    return created is Timestamp ? created.millisecondsSinceEpoch : 0;
  }
}
