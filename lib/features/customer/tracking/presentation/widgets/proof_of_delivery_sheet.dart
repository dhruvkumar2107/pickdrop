import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../../../../../../core/constants/colors.dart';
import '../../../../../../core/constants/dimensions.dart';
import '../../../../../../core/theme/text_styles.dart';

/// Shows the goods photos the driver took at pickup and drop. Photos are
/// captured on the driver's active-trip screen and stored per booking.
class ProofOfDeliverySheet extends StatelessWidget {
  final String bookingId;

  const ProofOfDeliverySheet({super.key, required this.bookingId});

  static Future<void> show(BuildContext context, {required String bookingId}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProofOfDeliverySheet(bookingId: bookingId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spacingXl,
        AppDimensions.spacingLg,
        AppDimensions.spacingXl,
        AppDimensions.spacingXl,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
            .snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data();
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.outline,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusFull,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingLg),
                Text(
                  'Goods photos',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
                Text(
                  'Taken by your driver at pickup and drop, before each code is accepted.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingLg),
                if (snapshot.hasError)
                  const Text('Could not load this trip.')
                else if (data == null)
                  const LinearProgressIndicator()
                else ...[
                  _ProofPhoto(
                    label: 'At pickup',
                    path: data['pickupProofPath'] as String?,
                    takenAt: data['pickupOtpVerifiedAt'],
                  ),
                  const SizedBox(height: AppDimensions.spacingLg),
                  _ProofPhoto(
                    label: 'At delivery',
                    path: data['deliveryProofPath'] as String?,
                    takenAt: data['dropOtpVerifiedAt'],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProofPhoto extends StatelessWidget {
  final String label;
  final String? path;
  final dynamic takenAt;

  const _ProofPhoto({required this.label, this.path, this.takenAt});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final time = takenAt is Timestamp
        ? TimeOfDay.fromDateTime((takenAt as Timestamp).toDate()).format(context)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          time == null ? label : '$label · $time',
          style: AppTextStyles.labelMedium.copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: AppDimensions.spacingXs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          child: path == null
              ? Container(
                  height: 120,
                  width: double.infinity,
                  color: colors.surfaceVariant,
                  alignment: Alignment.center,
                  child: Text(
                    'Not taken yet',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                )
              : FutureBuilder<String>(
                  future: FirebaseStorage.instance.ref(path).getDownloadURL(),
                  builder: (context, url) {
                    if (url.hasError) {
                      return const SizedBox(
                        height: 120,
                        child: Center(child: Text('Photo unavailable')),
                      );
                    }
                    if (!url.hasData) {
                      return const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return Image.network(
                      url.data!,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    );
                  },
                ),
        ),
      ],
    );
  }
}
