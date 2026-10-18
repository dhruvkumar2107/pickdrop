import 'package:flutter/material.dart';
import '../../../../../../core/constants/dimensions.dart';
import '../../../../../../core/theme/text_styles.dart';
import '../../../../../../core/widgets/glass_card.dart';

class SurgeTransparencyCard extends StatelessWidget {
  final double surgeMultiplier;
  final VoidCallback onBookLater;

  const SurgeTransparencyCard({
    super.key,
    required this.surgeMultiplier,
    required this.onBookLater,
  });

  @override
  Widget build(BuildContext context) {
    if (surgeMultiplier <= 1.0) return const SizedBox.shrink();

    final surgePercent = ((surgeMultiplier - 1.0) * 100).round();

    return GlassCard(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      borderColor: const Color(0xFFF59E0B).withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingXs),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  size: 18,
                  color: Color(0xFFD97706),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'High Demand in Your Area (+$surgePercent%)',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: const Color(0xFF92400E),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Fares are temporarily higher due to elevated demand for trucks right now.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: const Color(0xFFB45309),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onBookLater,
              icon: const Icon(Icons.schedule_rounded, size: 14, color: Color(0xFFD97706)),
              label: Text(
                'Schedule for later at regular price',
                style: AppTextStyles.labelSmall.copyWith(
                  color: const Color(0xFFD97706),
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
