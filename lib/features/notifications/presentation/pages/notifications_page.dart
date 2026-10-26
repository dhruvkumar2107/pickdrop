import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/router/route_names.dart';
import '../../../../../core/constants/colors.dart';
import '../../../../../core/constants/dimensions.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../core/widgets/common/common.dart';
import '../../../../shared/services/notification_service.dart';

/// Inbox of booking updates and support replies written by Cloud Functions.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  Query<Map<String, dynamic>> _query(String uid) => FirebaseFirestore.instance
      .collection('notifications')
      .where('userId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(50);

  Future<void> _markAllRead(String uid) async {
    final unread = await FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .limit(200)
        .get();
    if (unread.docs.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  void _open(BuildContext context, DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    if (data['isRead'] != true) {
      doc.reference.update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }
    final route = routeForNotification(data);
    if (route != null && route != RouteNames.notifications) {
      context.push(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Notifications', style: AppTextStyles.headlineSmall),
        iconTheme: const IconThemeData(color: AppColors.onSurface),
        actions: [
          if (uid != null)
            IconButton(
              tooltip: 'Mark all as read',
              onPressed: () => _markAllRead(uid),
              icon: const Icon(
                Icons.done_all_rounded,
                color: AppColors.onSurfaceVariant,
              ),
            ),
        ],
      ),
      body: uid == null
          ? const _Empty()
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _query(uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Could not load notifications.'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const _Empty();
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.spacingSm,
                  ),
                  itemCount: docs.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final unread = data['isRead'] != true;
                    final created = data['createdAt'];
                    return ListTile(
                      onTap: () => _open(context, doc),
                      leading: Icon(
                        data['type'] == 'support_reply'
                            ? Icons.support_agent_rounded
                            : Icons.local_shipping_rounded,
                        color: unread
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant,
                      ),
                      title: Text(
                        data['title']?.toString() ?? 'Update',
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        [
                          data['body']?.toString() ?? '',
                          if (created is Timestamp) _relative(created.toDate()),
                        ].where((part) => part.isNotEmpty).join('\n'),
                      ),
                      isThreeLine: created is Timestamp,
                      trailing: unread
                          ? const CircleAvatar(
                              radius: 4,
                              backgroundColor: AppColors.primary,
                            )
                          : null,
                    );
                  },
                );
              },
            ),
    );
  }

  static String _relative(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inDays < 1) return '${diff.inHours} h ago';
    if (diff.inDays < 7) return '${diff.inDays} d ago';
    return '${time.day}/${time.month}/${time.year}';
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: AppDimensions.spacingXxl),
      child: EmptyState(
        icon: Icons.notifications_none_rounded,
        title: 'No notifications',
        message: 'Booking updates and support replies will show up here',
      ),
    );
  }
}
