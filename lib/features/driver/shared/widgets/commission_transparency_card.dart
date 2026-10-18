import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/router/route_names.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../services/driver_commission_service.dart';

class CommissionTransparencyCard extends StatefulWidget {
  const CommissionTransparencyCard({
    super.key,
    required this.gross,
    this.completedTrips = 0,
  });

  final double gross;

  final int completedTrips;

  @override
  State<CommissionTransparencyCard> createState() =>
      _CommissionTransparencyCardState();
}

class _CommissionTransparencyCardState
    extends State<CommissionTransparencyCard> {
  late Map<String, dynamic> _breakdown;

  @override
  void initState() {
    super.initState();
    _breakdown = _compute();
    DriverCommissionService.loadConfig().then((_) {
      if (!mounted) return;
      setState(() => _breakdown = _compute());
    });
  }

  Map<String, dynamic> _compute() => DriverCommissionService.breakdown(
        fare: widget.gross,
        completedTrips: widget.completedTrips,
      );

  String _rupees(double value) => '₹${value.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final commission = (_breakdown['commission'] as num).toDouble();
    final net = (_breakdown['net'] as num).toDouble();
    final gross = (_breakdown['gross'] as num).toDouble();
    final rate = ((_breakdown['rate'] as num).toDouble() * 100).toStringAsFixed(0);
    final isFreeTier = _breakdown['isFreeTier'] == true;

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
          Row(
            children: [
              Container(
                width: DesignTokens.avatarSm,
                height: DesignTokens.avatarSm,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.receipt_long_outlined,
                  size: DesignTokens.iconSm,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: DesignTokens.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fair fare for you',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      isFreeTier ? 'Your first 20 trips are commission free' : 'Rate $rate% per completed trip',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.verified_outlined,
                size: DesignTokens.iconMd,
                color: colors.success,
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingMd),
          Row(
            children: [
              _StatCell(
                label: 'Trip total',
                value: _rupees(gross),
                color: colors.onSurface,
                flex: 1,
              ),
              _StatCell(
                label: 'PickDrop fee',
                value: '- ${_rupees(commission)}',
                color: commission == 0 ? colors.success : colors.warning,
                flex: 1,
              ),
              _StatCell(
                label: 'You take home',
                value: _rupees(net),
                color: colors.success,
                flex: 1,
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingMd),
          Row(
            children: [
              Icon(
                Icons.local_offer_outlined,
                size: DesignTokens.iconSm,
                color: colors.success,
              ),
              const SizedBox(width: DesignTokens.spacingSm),
              Expanded(
                child: Text(
                  isFreeTier
                      ? 'New driver benefit: 0% commission — '
                          '${_breakdown['freeTripsRemaining']} trips left'
                      : 'Commission included above. No hidden platform fees.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => context.go(RouteNames.driverPayouts),
                child: Text(
                  'View payouts',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.primary,
                    decoration: TextDecoration.underline,
                    decorationColor: colors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    required this.color,
    required this.flex,
  });

  final String label;

  final String value;

  final Color color;

  final int flex;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Expanded(
      flex: flex,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingXs),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
