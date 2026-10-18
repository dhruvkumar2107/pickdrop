import 'package:flutter/material.dart';

import '../../../../../core/constants/colors.dart';
import '../../../../../core/constants/dimensions.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../core/widgets/glass_card.dart';

class TollEstimateCard extends StatelessWidget {
  const TollEstimateCard({super.key, required this.distanceKm});

  final double distanceKm;

  static const int parkingFee = 20;

  static int tollsFor(double km) => (km / 12).round() * 45;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tolls = tollsFor(distanceKm);
    final total = tolls + parkingFee;

    return GlassCard(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingSm),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Icon(
                  Icons.toll_rounded,
                  size: AppDimensions.iconSm,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tolls & parking',
                      style: AppTextStyles.labelLarge
                          .copyWith(color: colors.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Estimated, included in your locked fare',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '₹$total',
                style: AppTextStyles.priceSmall.copyWith(color: colors.primary),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Container(height: 1, color: colors.outlineVariant),
          const SizedBox(height: AppDimensions.spacingSm),
          _line(
            colors,
            'Highway tolls (${distanceKm.toStringAsFixed(1)} km)',
            tolls,
          ),
          const SizedBox(height: AppDimensions.spacingXs),
          _line(colors, 'Parking allowance', parkingFee),
          const SizedBox(height: AppDimensions.spacingXs),
          Text(
            'No hidden charges — if tolls come in lower, you keep the difference in your wallet.',
            style: AppTextStyles.bodySmall
                .copyWith(color: colors.onSurfaceVariant, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _line(AppColorsExtension colors, String label, int amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style:
                AppTextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
          ),
        ),
        Text(
          '₹$amount',
          style: AppTextStyles.bodySmall.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
