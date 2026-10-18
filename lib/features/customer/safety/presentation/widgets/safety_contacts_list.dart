import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/constants/colors.dart';
import '../../../../../core/constants/dimensions.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../core/widgets/app_toast.dart';

class SafetyContactsList extends StatelessWidget {
  const SafetyContactsList({super.key, required this.userId});

  final String userId;

  Future<void> _call(BuildContext context, String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _delete(
    BuildContext context,
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    try {
      await doc.reference.delete();
    } catch (_) {
      if (context.mounted) {
        AppToast.error(context, 'Could not remove the contact');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('safetyContacts')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(
            'Contacts are unavailable right now. Please try again later.',
            style: AppTextStyles.bodySmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          );
        }
        if (!snapshot.hasData) {
          return Center(
            child: SizedBox(
              width: AppDimensions.iconSm,
              height: AppDimensions.iconSm,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
              ),
            ),
          );
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Text(
            'No emergency contacts yet. Add family or friends who should follow your trips.',
            style: AppTextStyles.bodySmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          );
        }
        return Column(
          children: docs.map((doc) => _row(context, colors, doc)).toList(),
        );
      },
    );
  }

  Widget _row(
    BuildContext context,
    AppColorsExtension colors,
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final name = ((data['name'] as String?) ?? 'Contact').trim();
    final phone = (data['phone'] as String?) ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
      child: Row(
        children: [
          CircleAvatar(
            radius: AppDimensions.avatarSm / 2,
            backgroundColor: colors.primaryContainer,
            child: Text(
              name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
              style: AppTextStyles.labelLarge.copyWith(color: colors.primary),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelLarge.copyWith(color: colors.onSurface),
                ),
                Text(
                  phone,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _call(context, phone),
            icon: Icon(Icons.call_rounded, size: AppDimensions.iconSm, color: colors.success),
          ),
          IconButton(
            onPressed: () => _delete(context, doc),
            icon: Icon(Icons.delete_outline_rounded, size: AppDimensions.iconSm, color: colors.error),
          ),
        ],
      ),
    );
  }
}
