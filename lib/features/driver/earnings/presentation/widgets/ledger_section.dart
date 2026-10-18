import 'package:flutter/material.dart';

import '../../../../../core/constants/colors.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/widgets/status_chip.dart';
import '../../../shared/services/driver_commission_service.dart';

class LedgerSection extends StatelessWidget {
  const LedgerSection({super.key, this.entries = _defaultEntries});

  static const List<Map<String, dynamic>> _defaultEntries =
      <Map<String, dynamic>>[
    <String, dynamic>{
      'tripId': 'PD-2041',
      'date': '12 Oct · 7:42 PM',
      'gross': 420.0,
      'completedTrips': 18,
      'status': 'PAID',
    },
    <String, dynamic>{
      'tripId': 'PD-2042',
      'date': '12 Oct · 9:05 PM',
      'gross': 340.0,
      'completedTrips': 19,
      'status': 'PAID',
    },
    <String, dynamic>{
      'tripId': 'PD-2043',
      'date': '13 Oct · 8:20 AM',
      'gross': 290.0,
      'completedTrips': 20,
      'status': 'PROCESSING',
    },
    <String, dynamic>{
      'tripId': 'PD-2044',
      'date': '13 Oct · 12:10 PM',
      'gross': 590.0,
      'completedTrips': 21,
      'status': 'REQUESTED',
    },
  ];

  final List<Map<String, dynamic>> entries;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (entries.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.spacingLg),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily ledger',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingXs),
          Text(
            'Exact maths for every trip — before and after commission.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingMd),
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0)
              Divider(height: DesignTokens.spacingLg, color: colors.outlineVariant),
            _LedgerRow(entry: entries[i]),
          ],
        ],
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.entry});

  final Map<String, dynamic> entry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final gross = (entry['gross'] as num?)?.toDouble() ?? 0;
    final completedTrips = (entry['completedTrips'] as num?)?.toInt() ?? 0;
    final breakdown = DriverCommissionService.breakdown(
      fare: gross,
      completedTrips: completedTrips,
    );
    final commission = (breakdown['commission'] as num).toDouble();
    final net = (breakdown['net'] as num).toDouble();
    final tripId = entry['tripId'];
    final status = entry['status'];
    final isFree = breakdown['isFreeTier'] == true;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Trip ${tripId is String ? tripId : ''}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
              ),
              if (status is String)
                StatusChip.fromStatus(status, label: status, dense: true),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingXs),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Gross ₹${gross.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Fee -₹${commission.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isFree ? colors.success : colors.warning,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'You get ₹${net.toStringAsFixed(0)}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.success,
                  ),
                ),
              ),
            ],
          ),
          if (entry['date'] is String)
            Text(
              '${entry['date']}${isFree ? ' · free tier' : ''}',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                color: colors.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
