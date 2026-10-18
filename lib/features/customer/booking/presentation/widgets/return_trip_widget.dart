import 'package:flutter/material.dart';

import '../../../../../core/constants/colors.dart';
import '../../../../../core/constants/dimensions.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../core/widgets/glass_card.dart';

class ReturnTripWidget extends StatelessWidget {
  const ReturnTripWidget({
    super.key,
    required this.value,
    required this.onChanged,
    this.distanceKm = 0,
    this.distanceFare = 0,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final double distanceKm;
  final double distanceFare;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GlassCard(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      borderColor: value ? colors.primary.withValues(alpha: 0.4) : colors.glassBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (value ? colors.primary : colors.onSurfaceVariant)
                      .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Icon(
                  value ? Icons.swap_horiz_rounded : Icons.restart_alt_rounded,
                  color: value ? colors.primary : colors.onSurfaceVariant,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Same driver again / Return trip',
                      style: AppTextStyles.labelLarge
                          .copyWith(color: colors.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Book the return leg now and get the same trusted driver',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colors.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
          if (value) ...[
            const SizedBox(height: AppDimensions.spacingMd),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.spacingSm),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Return leg added to your quote',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: colors.primary, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppDimensions.spacingXs),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Distance',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: colors.onSurfaceVariant, fontSize: 11),
                        ),
                      ),
                      Text(
                        '${distanceKm.toStringAsFixed(1)} km → ${(distanceKm * 2).toStringAsFixed(1)} km',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Distance component',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: colors.onSurfaceVariant, fontSize: 11),
                        ),
                      ),
                      Text(
                        '₹${distanceFare.toStringAsFixed(0)} → '
                        '₹${(distanceFare * 2).toStringAsFixed(0)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
