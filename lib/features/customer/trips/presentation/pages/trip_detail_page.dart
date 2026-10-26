import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/router/route_names.dart';
import '../../../../../core/constants/colors.dart';
import '../../../../../core/constants/dimensions.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../../../../core/widgets/glass_card.dart';
import '../../../../../core/widgets/status_chip.dart';
import '../../../booking/presentation/widgets/insurance_claim_sheet.dart';
import '../../../help/presentation/widgets/instant_refund_card.dart';
import '../../../tracking/presentation/widgets/proof_of_delivery_sheet.dart';

class TripDetailPage extends StatefulWidget {
  const TripDetailPage({super.key, this.isInsured = true, this.bookingId});

  final bool isInsured;
  final String? bookingId;

  @override
  State<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends State<TripDetailPage> {
  @override
  Widget build(BuildContext context) {
    final id = widget.bookingId;
    if (id == null || id.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Trip details are unavailable. Open a trip from your history.',
          ),
        ),
      );
    }
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .doc(id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Could not load trip details.')),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final data = snapshot.data!.data();
        if (data == null) {
          return const Scaffold(body: Center(child: Text('Trip not found.')));
        }
        return _buildDetails(context, data);
      },
    );
  }

  Widget _buildDetails(BuildContext context, Map<String, dynamic> data) {
    final bookingId = widget.bookingId!;
    final fare = Map<String, dynamic>.from(data['fareBreakdown'] as Map? ?? {});
    final pickup = Map<String, dynamic>.from(data['pickup'] as Map? ?? {});
    final drop = Map<String, dynamic>.from(data['drop'] as Map? ?? {});
    final total = (fare['total'] as num? ?? 0).toDouble();
    final safeTop = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          Container(
            height: safeTop + 120,
            decoration: const BoxDecoration(gradient: AppColors.brandGradient),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingMd,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingXs),
                    Expanded(
                      child: Text(
                        'Trip Details',
                        style: AppTextStyles.headlineSmall.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    StatusChip.fromStatus(
                      (data['status'] ?? 'UNKNOWN').toString(),
                      dense: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.spacingXl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GlassCard(
                    showShadow: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Trip #${bookingId.substring(0, bookingId.length > 8 ? 8 : bookingId.length)}',
                              style: AppTextStyles.titleMedium,
                            ),
                            Text(
                              '₹${total.toStringAsFixed(0)}',
                              style: AppTextStyles.priceMedium.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.spacingXs),
                        Text(
                          _formatDate(data['createdAt']),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacingLg),
                        _TripRow(
                          icon: Icons.trip_origin_rounded,
                          color: AppColors.primary,
                          label: 'Pickup',
                          address: (pickup['address'] ?? 'Pickup').toString(),
                        ),
                        const SizedBox(height: AppDimensions.spacingMd),
                        _TripRow(
                          icon: Icons.location_on_rounded,
                          color: const Color(0xFF16A34A),
                          label: 'Drop',
                          address: (drop['address'] ?? 'Destination')
                              .toString(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingLg),
                  GlassCard(
                    child: Column(
                      children: [
                        _InfoRow(
                          label: 'Vehicle',
                          value:
                              (data['vehicleTypeId'] ??
                                      data['vehicleType'] ??
                                      'Delivery')
                                  .toString(),
                        ),
                        _InfoRow(
                          label: 'Distance',
                          value:
                              '${((data['distanceKm'] as num?) ?? 0).toStringAsFixed(1)} km',
                        ),
                        _InfoRow(
                          label: 'Duration',
                          value: '${data['estimatedDurationMin'] ?? '—'} min',
                        ),
                        _InfoRow(
                          label: 'Payment',
                          value: (data['paymentMethod'] ?? '—').toString(),
                        ),
                        _InfoRow(
                          label: 'Status',
                          value: (data['status'] ?? '—').toString(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingLg),
                  GlassCard(
                    child: Column(
                      children: [
                        _InfoRow(
                          label: 'Base fare',
                          value: _money(fare['baseFare']),
                        ),
                        _InfoRow(
                          label: 'Distance fare',
                          value: _money(fare['distanceFare']),
                        ),
                        _InfoRow(
                          label: 'Time fare',
                          value: _money(fare['timeFare']),
                        ),
                        _InfoRow(label: 'GST', value: _money(fare['gst'])),
                        Divider(height: AppDimensions.spacingLg),
                        _InfoRow(
                          label: 'Total',
                          value: _money(fare['total']),
                          bold: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingLg),
                  GlassCard(
                    child: Column(
                      children: [
                        _ActionRow(
                          icon: Icons.verified_outlined,
                          label: 'Goods photos',
                          subtitle: 'Taken by the driver at pickup and drop',
                          onTap: () => ProofOfDeliverySheet.show(
                            context,
                            bookingId: bookingId,
                          ),
                        ),
                        if (data['transitInsurance'] == true) ...[
                          const Divider(height: AppDimensions.spacingMd),
                          _ActionRow(
                            icon: Icons.health_and_safety_rounded,
                            label: 'Insurance claim',
                            subtitle: 'File or track your transit claim',
                            onTap: () => InsuranceClaimSheet.show(
                              context,
                              bookingId: bookingId,
                              goodsValue:
                                  (data['goodsValue'] as num?)?.toDouble() ?? 0,
                            ),
                          ),
                        ],
                        const Divider(height: AppDimensions.spacingMd),
                        _ActionRow(
                          icon: Icons.report_gmailerrorred_rounded,
                          label: 'Report an issue',
                          subtitle: 'Request a refund or report a problem',
                          onTap: () => InstantRefundCard.show(
                            context,
                            bookingId: bookingId,
                          ),
                        ),
                        const Divider(height: AppDimensions.spacingMd),
                        _ActionRow(
                          icon: Icons.replay_rounded,
                          label: 'Book again',
                          subtitle: 'Reuse this pickup and drop',
                          onTap: () => _rebook(context, pickup, drop),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  void _rebook(
    BuildContext context,
    Map<String, dynamic> pickup,
    Map<String, dynamic> drop,
  ) {
    final pickupLat = (pickup['lat'] as num?)?.toDouble();
    final pickupLng = (pickup['lng'] as num?)?.toDouble();
    final dropLat = (drop['lat'] as num?)?.toDouble();
    final dropLng = (drop['lng'] as num?)?.toDouble();
    if (pickupLat == null ||
        pickupLng == null ||
        dropLat == null ||
        dropLng == null) {
      AppToast.warning(context, 'This trip cannot be rebooked.');
      return;
    }
    final pickupAddress = (pickup['address'] ?? 'Pickup').toString();
    final dropAddress = (drop['address'] ?? 'Drop').toString();
    context.push(
      '${RouteNames.vehicleSelection}?'
      'pickupLat=$pickupLat&pickupLng=$pickupLng&pickupAddress=${Uri.encodeComponent(pickupAddress)}'
      '&dropLat=$dropLat&dropLng=$dropLng&dropAddress=${Uri.encodeComponent(dropAddress)}',
    );
  }

  String _money(dynamic value) =>
      '₹${((value as num?) ?? 0).toStringAsFixed(2)}';
  String _formatDate(dynamic value) {
    final date = value is Timestamp ? value.toDate().toLocal() : null;
    if (date == null) return 'Date unavailable';
    return '${date.day}/${date.month}/${date.year} • ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _TripRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String address;

  const _TripRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: AppDimensions.spacingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              Text(address, style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.spacingXs,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: AppDimensions.iconSm,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyles.labelLarge),
                    Text(
                      subtitle,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _InfoRow({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? AppTextStyles.titleSmall.copyWith(color: AppColors.primary)
        : AppTextStyles.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingXs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          Text(value, style: style),
        ],
      ),
    );
  }
}
