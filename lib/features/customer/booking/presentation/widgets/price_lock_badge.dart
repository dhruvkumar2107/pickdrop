import 'package:flutter/material.dart';
import '../../../../../../core/constants/colors.dart';
import '../../../../../../core/constants/dimensions.dart';
import '../../../../../../core/theme/text_styles.dart';
import '../../../../../../core/widgets/glass_card.dart';

class PriceLockBadge extends StatelessWidget {
  final double lockedFare;
  final bool isCompact;

  const PriceLockBadge({
    super.key,
    required this.lockedFare,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingSm,
          vertical: AppDimensions.spacingXxs,
        ),
        decoration: BoxDecoration(
          color: colors.successLight,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(
            color: colors.success.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded, size: 12, color: colors.success),
            const SizedBox(width: 4),
            Text(
              'Price Lock: ₹${lockedFare.toStringAsFixed(0)}',
              style: AppTextStyles.labelSmall.copyWith(
                color: colors.success,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      borderColor: colors.success.withValues(alpha: 0.3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingSm),
            decoration: BoxDecoration(
              color: colors.successLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.verified_user_rounded,
              size: 20,
              color: colors.success,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Price Lock Promise',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.success,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
                      ),
                      child: Text(
                        'GUARANTEE',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: colors.onPrimary,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${lockedFare.toStringAsFixed(0)} is your final fare. No extra cash, no hidden fee surprise.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
