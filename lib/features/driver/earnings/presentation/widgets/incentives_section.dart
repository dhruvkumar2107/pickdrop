import 'package:flutter/material.dart';

import '../../../../../core/constants/colors.dart';
import '../../../../../core/theme/design_tokens.dart';

class IncentivesSection extends StatelessWidget {
  const IncentivesSection({super.key, this.weeklyTrips = 26});

  final int weeklyTrips;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final nextTier = weeklyTrips < 30
        ? <String, Object>{'target': 30, 'bonus': 700}
        : <String, Object>{'target': 40, 'bonus': 1200};
    final target = nextTier['target'] as int;
    final progress =
        (weeklyTrips / target).clamp(0.0, 1.0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Incentives & bonuses',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingXs),
        Text(
          'Steady demand, more earnings — these tiers refresh every Monday.',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingMd),
        _IncentiveCard(
          icon: Icons.emoji_events_outlined,
          title: 'Weekly trip bonus',
          rows: <_IncentiveRow>[
            _IncentiveRow(
              label: '$weeklyTrips / $target trips this week',
              value: '₹${nextTier['bonus']} waiting',
              highlight: true,
            ),
            _IncentiveRow(label: '30 trips', value: '+ ₹700'),
            _IncentiveRow(label: '40 trips', value: '+ ₹1,200'),
          ],
          progress: progress,
        ),
        const SizedBox(height: DesignTokens.spacingMd),
        _IncentiveCard(
          icon: Icons.access_time_rounded,
          title: 'Peak hour incentives',
          rows: <_IncentiveRow>[
            _IncentiveRow(label: '7 – 10 AM weekdays', value: '+15% fare'),
            _IncentiveRow(label: '5 – 9 PM weekdays', value: '+20% fare'),
            _IncentiveRow(label: 'Weekend lunch rush', value: '+ ₹40 / trip'),
          ],
        ),
        const SizedBox(height: DesignTokens.spacingMd),
        _IncentiveCard(
          icon: Icons.local_fire_department_outlined,
          title: 'Streak rewards',
          rows: <_IncentiveRow>[
            _IncentiveRow(label: '5 days online', value: '+ ₹150'),
            _IncentiveRow(label: '7 days online', value: '+ ₹400 & priority jobs'),
            _IncentiveRow(label: '14 days online', value: '+ ₹1,000'),
          ],
        ),
      ],
    );
  }
}

class _IncentiveCard extends StatelessWidget {
  const _IncentiveCard({
    required this.icon,
    required this.title,
    required this.rows,
    this.progress,
  });

  final IconData icon;

  final String title;

  final List<_IncentiveRow> rows;

  final double? progress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.spacingMd),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: DesignTokens.iconMd, color: colors.driverAccent),
              const SizedBox(width: DesignTokens.spacingSm),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: DesignTokens.spacingSm),
            ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: colors.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(colors.driverAccent),
              ),
            ),
          ],
          const SizedBox(height: DesignTokens.spacingSm),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: DesignTokens.spacingXs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      row.label,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight:
                            row.highlight ? FontWeight.w600 : FontWeight.w400,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Text(
                    row.value,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: row.highlight
                          ? colors.driverAccent
                          : colors.success,
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

class _IncentiveRow {
  const _IncentiveRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;

  final String value;

  final bool highlight;
}
