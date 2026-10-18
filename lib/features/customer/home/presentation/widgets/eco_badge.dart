import 'package:flutter/material.dart';

import '../../../../../core/constants/colors.dart';
import '../../../../../core/theme/design_tokens.dart';

class EcoBadge extends StatelessWidget {
  static const double dieselVanGramsPerKm = 150;

  final String vehicleType;
  final double distanceKm;

  const EcoBadge({
    super.key,
    required this.vehicleType,
    required this.distanceKm,
  });

  double? get _gramsPerKm {
    final type = vehicleType.toLowerCase().trim();
    if (type.isEmpty) return null;
    if (type.contains('ev') || type.contains('electric')) return 0.4;
    if (type.contains('bike') ||
        type.contains('two wheeler') ||
        type.contains('two_wheeler') ||
        type.contains('scooter')) {
      return 0.62;
    }
    return null;
  }

  String get _savedLabel {
    final grams = _gramsPerKm;
    if (grams == null) return '0';
    final savedKg = (dieselVanGramsPerKm - grams) * distanceKm / 1000;
    if (savedKg >= 10) return savedKg.toStringAsFixed(0);
    return savedKg.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final grams = _gramsPerKm;
    if (grams == null || distanceKm <= 0) return const SizedBox.shrink();

    return Semantics(
      label: 'Eco friendly, saves $_savedLabel kilograms of CO2',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space2,
          vertical: DesignTokens.space1,
        ),
        decoration: BoxDecoration(
          color: colors.success.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
          border: Border.all(
            color: colors.success.withValues(alpha: 0.4),
            width: DesignTokens.borderThin,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌱', style: TextStyle(fontSize: 12)),
            const SizedBox(width: DesignTokens.space1),
            Text(
              '$_savedLabel kg CO₂ saved',
              style: TokenTextStyles.labelSmall(
                color: colors.success,
                weight: DesignTokens.wSemiBold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
