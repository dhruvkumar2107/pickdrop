import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/router/route_names.dart';
import '../../../../../core/constants/colors.dart';
import '../../../../../core/constants/dimensions.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../core/widgets/glass_card.dart';
import '../../../../../core/widgets/gradient_button.dart';
import '../widgets/live_share_card.dart';

class WebTrackingPage extends StatelessWidget {
  const WebTrackingPage({super.key, required this.bookingId});

  final String bookingId;

  static const List<_Stage> _stages = [
    _Stage('SEARCHING', 'Finding your driver'),
    _Stage('DRIVER_ASSIGNED', 'Driver on the way to pickup'),
    _Stage('AT_PICKUP', 'Loading your goods'),
    _Stage('PICKED_UP', 'On the way to the drop'),
    _Stage('DELIVERED', 'Delivered'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.surface,
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data();
          if (data == null) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            return _MissingView(bookingId: bookingId, colors: colors);
          }

          final status = (data['status'] as String? ?? 'SEARCHING').toUpperCase();
          final stageIndex = _stages.indexWhere((s) => s.id == status);
          final activeIndex = stageIndex < 0 ? 0 : stageIndex;
          final driverId = data['driverId'] as String?;
          final pickup = data['pickup'] as Map<String, dynamic>? ?? {};
          final drop = data['drop'] as Map<String, dynamic>? ?? {};
          final fare = (data['fareBreakdown'] as Map<String, dynamic>? ?? {})['total'];

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(
                  padding: const EdgeInsets.all(AppDimensions.spacingXl),
                  children: [
                    Row(
                      children: [
                        Icon(Icons.local_shipping_rounded,
                            color: colors.primary,
                            size: AppDimensions.iconMd),
                        const SizedBox(width: AppDimensions.spacingSm),
                        Text('PickDrop', style: AppTextStyles.headlineSmall),
                        const Spacer(),
                        Text('Live tracking',
                            style: AppTextStyles.labelLarge
                                .copyWith(color: colors.onSurfaceVariant)),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingXl),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_stages[activeIndex].label,
                              style: AppTextStyles.titleMedium),
                          const SizedBox(height: AppDimensions.spacingMd),
                          ...List.generate(_stages.length, (index) {
                            final done = index <= activeIndex;
                            return Padding(
                              padding: const EdgeInsets.only(
                                  bottom: AppDimensions.spacingSm),
                              child: Row(
                                children: [
                                  Icon(
                                    done
                                        ? Icons.check_circle_rounded
                                        : Icons.radio_button_unchecked,
                                    size: AppDimensions.iconSm,
                                    color: done
                                        ? colors.success
                                        : colors.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: AppDimensions.spacingSm),
                                  Expanded(
                                    child: Text(
                                      _stages[index].label,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: done
                                            ? colors.onSurface
                                            : colors.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingLg),
                    _RouteCard(
                      pickup: (pickup['address'] as String?) ?? 'Pickup',
                      drop: (drop['address'] as String?) ?? 'Drop',
                    ),
                    const SizedBox(height: AppDimensions.spacingLg),
                    FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      future: driverId == null || driverId.isEmpty
                          ? null
                          : FirebaseFirestore.instance
                              .collection('drivers')
                              .doc(driverId)
                              .get(),
                      builder: (context, driverSnap) {
                        final driver = driverSnap.data?.data();
                        final name =
                            (driver?['name'] as String?) ?? 'Your driver';
                        return GlassCard(
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor:
                                    colors.primary.withValues(alpha: 0.15),
                                child: Text(
                                  name.isEmpty
                                      ? '?'
                                      : name[0].toUpperCase(),
                                  style: AppTextStyles.titleSmall
                                      .copyWith(color: colors.primary),
                                ),
                              ),
                              const SizedBox(width: AppDimensions.spacingMd),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: AppTextStyles.titleSmall),
                                    Text(
                                      driverId == null || driverId.isEmpty
                                          ? 'Waiting for a driver to accept'
                                          : 'Verified PickDrop partner',
                                      style: AppTextStyles.bodySmall.copyWith(
                                          color: colors.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                              if (fare != null)
                                Text(
                                  '₹${(fare as num).toStringAsFixed(0)}',
                                  style: AppTextStyles.titleMedium
                                      .copyWith(color: colors.primary),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppDimensions.spacingXl),
                    GradientButton(
                      text: 'Book your own PickDrop',
                      isFullWidth: true,
                      onPressed: () => context.go(RouteNames.customerHome),
                    ),
                    const SizedBox(height: AppDimensions.spacingMd),
                    TextButton(
                      onPressed: () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => LiveShareCard(
                          bookingId: bookingId,
                        ),
                      ),
                      child: const Text('Copy this tracking link'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.pickup, required this.drop});

  final String pickup;
  final String drop;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GlassCard(
      child: Column(
        children: [
          _Point(
            color: colors.success,
            icon: Icons.trip_origin_rounded,
            label: pickup,
          ),
          Padding(
            padding: const EdgeInsets.only(left: AppDimensions.spacingSm),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 2,
                height: AppDimensions.spacingLg,
                color: colors.outline,
              ),
            ),
          ),
          _Point(
            color: colors.error,
            icon: Icons.location_on_rounded,
            label: drop,
          ),
        ],
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({
    required this.color,
    required this.icon,
    required this.label,
  });

  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: AppDimensions.iconMd),
        const SizedBox(width: AppDimensions.spacingMd),
        Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
      ],
    );
  }
}

class _MissingView extends StatelessWidget {
  const _MissingView({required this.bookingId, required this.colors});

  final String bookingId;
  final AppColorsExtension colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded,
                size: 64, color: AppColors.primary),
            const SizedBox(height: AppDimensions.spacingMd),
            Text('Tracking link not found', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppDimensions.spacingSm),
            Text(
              'Delivery $bookingId is no longer available. Ask the sender for a fresh link.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: AppDimensions.spacingLg),
            SizedBox(
              width: 260,
              child: GradientButton(
                text: 'Book a PickDrop',
                isFullWidth: true,
                onPressed: () => context.go(RouteNames.customerHome),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stage {
  const _Stage(this.id, this.label);

  final String id;
  final String label;
}
