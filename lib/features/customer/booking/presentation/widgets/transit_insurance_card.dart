import 'package:flutter/material.dart';
import '../../../../../../core/constants/colors.dart';
import '../../../../../../core/constants/dimensions.dart';
import '../../../../../../core/theme/text_styles.dart';
import '../../../../../../core/widgets/glass_card.dart';

class TransitInsuranceCard extends StatelessWidget {
  final bool isInsured;
  final double goodsValue;
  final double premium;
  final ValueChanged<bool> onToggleInsurance;

  const TransitInsuranceCard({
    super.key,
    required this.isInsured,
    required this.goodsValue,
    this.premium = 29.0,
    required this.onToggleInsurance,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GlassCard(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      borderColor: isInsured ? colors.primary : colors.outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingSm),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.security_rounded, size: 20, color: colors.primary),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Transit Goods Insurance',
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '₹${premium.toStringAsFixed(0)}',
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Covers accidental damage & loss up to ₹50,000 with in-app claim settlement',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colors.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isInsured,
                activeThumbColor: colors.primary,
                onChanged: onToggleInsurance,
              ),
            ],
          ),
          if (isInsured) ...[
            const Divider(height: 16),
            Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 14, color: colors.success),
                const SizedBox(width: 4),
                Text(
                  '100% cashless claims processed within 24 hours',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: colors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
