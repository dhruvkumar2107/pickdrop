import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/constants/colors.dart';
import '../../../../../core/constants/dimensions.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../../../../core/widgets/glass_card.dart';
import '../../../../../core/widgets/status_chip.dart';
import '../../../booking/presentation/widgets/insurance_claim_sheet.dart';
import '../../../help/presentation/widgets/instant_refund_card.dart';
import '../../../tracking/presentation/widgets/proof_of_delivery_sheet.dart';

class TripDetailPage extends StatelessWidget {
  const TripDetailPage({super.key, this.isInsured = true});

  final bool isInsured;

  @override
  Widget build(BuildContext context) {
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
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white),
                    ),
                    const SizedBox(width: AppDimensions.spacingXs),
                    Expanded(
                      child: Text(
                        'Trip Details',
                        style:
                            AppTextStyles.headlineSmall.copyWith(color: Colors.white),
                      ),
                    ),
                    const StatusChip(label: 'DELIVERED', status: AppChipStatus.success),
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
                            Text('Trip #PD1004', style: AppTextStyles.titleMedium),
                            Text('₹520',
                                style: AppTextStyles.priceMedium
                                    .copyWith(color: AppColors.primary)),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.spacingXs),
                        Text(
                          '28 Sep 2026 • 11:45',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(height: AppDimensions.spacingLg),
                        _TripRow(
                          icon: Icons.trip_origin_rounded,
                          color: AppColors.primary,
                          label: 'Pickup',
                          address: '55 Electronic City Phase 1, Bangalore',
                        ),
                        const SizedBox(height: AppDimensions.spacingMd),
                        _TripRow(
                          icon: Icons.location_on_rounded,
                          color: const Color(0xFF16A34A),
                          label: 'Drop',
                          address: '9 HSR Layout Sector 2, Bangalore',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingLg),
                  GlassCard(
                    child: Column(
                      children: const [
                        _InfoRow(label: 'Vehicle', value: 'Pickup'),
                        _InfoRow(label: 'Distance', value: '12.4 km'),
                        _InfoRow(label: 'Duration', value: '38 min'),
                        _InfoRow(label: 'Payment', value: 'UPI'),
                        _InfoRow(label: 'Status', value: 'Delivered'),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingLg),
                  GlassCard(
                    child: Column(
                      children: const [
                        _InfoRow(label: 'Base fare', value: '₹120'),
                        _InfoRow(label: 'Distance fare', value: '₹240'),
                        _InfoRow(label: 'Time fare', value: '₹90'),
                        _InfoRow(label: 'GST (5%)', value: '₹23'),
                        Divider(height: AppDimensions.spacingLg),
                        _InfoRow(label: 'Total', value: '₹473', bold: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingLg),
                  GlassCard(
                    child: Column(
                      children: [
                        _ActionRow(
                          icon: Icons.verified_outlined,
                          label: 'Proof of delivery',
                          subtitle: 'Photo & receiver acknowledgment',
                          onTap: () => ProofOfDeliverySheet.show(
                            context,
                            bookingId: 'PD1004',
                            isPickup: false,
                            onProofCompleted: () => AppToast.success(
                              context,
                              'Delivery proof & digital receipt recorded!',
                            ),
                          ),
                        ),
                        if (isInsured) ...[
                          const Divider(height: AppDimensions.spacingMd),
                          _ActionRow(
                            icon: Icons.health_and_safety_rounded,
                            label: 'Insurance claim',
                            subtitle: 'File or track your transit claim',
                            onTap: () => InsuranceClaimSheet.show(
                              context,
                              bookingId: 'PD1004',
                              goodsValue: 12000,
                            ),
                          ),
                        ],
                        const Divider(height: AppDimensions.spacingMd),
                        _ActionRow(
                          icon: Icons.report_gmailerrorred_rounded,
                          label: 'Report an issue',
                          subtitle: 'Instant refund to your wallet',
                          onTap: () => InstantRefundCard.show(
                            context,
                            bookingId: 'PD1004',
                          ),
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
              Text(label,
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.onSurfaceVariant)),
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
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingXs),
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
                child: Icon(icon, size: AppDimensions.iconSm, color: colors.primary),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyles.labelLarge),
                    Text(
                      subtitle,
                      style: AppTextStyles.labelSmall
                          .copyWith(color: colors.onSurfaceVariant),
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
          Text(label,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.onSurfaceVariant)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
