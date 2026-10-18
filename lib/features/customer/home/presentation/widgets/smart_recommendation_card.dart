import 'package:flutter/material.dart';

import '../../../../../core/constants/colors.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/widgets/buttons/buttons.dart';
import '../../../../../core/widgets/glass_card.dart';

class SmartRecommendationCard extends StatelessWidget {
  final String goodsType;
  final double distanceKm;
  final ValueChanged<String> onAccept;

  const SmartRecommendationCard({
    super.key,
    required this.goodsType,
    required this.distanceKm,
    required this.onAccept,
  });

  static const List<String> _foodKeywords = [
    'food',
    'grocery',
    'groceries',
    'meal',
    'fruits',
    'vegetable',
    'cake',
    'bakery',
    'catering',
    'milk',
    'curd',
  ];

  static const List<String> _fragileKeywords = [
    'fragile',
    'glass',
    'tv',
    'television',
    'monitor',
    'mirror',
    'ceramic',
    'electronics',
    'laptop',
  ];

  static const List<String> _heavyKeywords = [
    'furniture',
    'sofa',
    'wardrobe',
    'fridge',
    'refrigerator',
    'washing machine',
    'machine',
    'bulk',
    'cement',
    'steel',
    'construction',
    'heavy',
    'bed',
    'almirah',
  ];

  static const List<String> _mediumKeywords = [
    'box',
    'boxes',
    'carton',
    'cartons',
    'appliance',
    'appliances',
    'medium',
    'books',
    'tools',
  ];

  static const List<String> _lightKeywords = [
    'document',
    'documents',
    'envelope',
    'parcel',
    'letter',
    'medicine',
    'gift',
    'accessories',
    'clothes',
  ];

  bool _contains(List<String> keywords) {
    final goods = goodsType.toLowerCase();
    return keywords.any(goods.contains);
  }

  int get _declaredWeight {
    final match = RegExp(r'(\d+)\s*kg').firstMatch(goodsType.toLowerCase());
    if (match == null) return 0;
    return int.tryParse(match.group(1) ?? '') ?? 0;
  }

  ({
    String vehicle,
    List<String> reasons,
    String? note,
  }) _recommendation() {
    if (_contains(_foodKeywords)) {
      return (
        vehicle: '3-Wheeler',
        reasons: ['Perishable load', 'Steady, shock-free ride'],
        note: 'Carry it in a thermal box so it reaches exactly as it left.',
      );
    }
    if (_contains(_fragileKeywords)) {
      return (
        vehicle: 'Pickup',
        reasons: ['Fragile goods', 'Flat, cushioned deck'],
        note: null,
      );
    }
    if (_contains(_heavyKeywords)) {
      return (
        vehicle: 'Pickup',
        reasons: ['Bulky goods', 'Open loading space'],
        note: null,
      );
    }
    final weight = _declaredWeight;
    if (weight >= 20) {
      return (
        vehicle: '3-Wheeler',
        reasons: ['$weight kg load', 'Roomy cargo bed'],
        note: null,
      );
    }
    if (_contains(_mediumKeywords)) {
      return (
        vehicle: '3-Wheeler',
        reasons: ['Medium load', 'Balanced price and space'],
        note: null,
      );
    }
    if (_contains(_lightKeywords)) {
      if (distanceKm <= 8) {
        return (
          vehicle: 'Bike',
          reasons: ['Light parcel', 'Short hop, fastest on a bike'],
          note: null,
        );
      }
      return (
        vehicle: '3-Wheeler',
        reasons: ['Light parcel', 'Comfy cover for a longer trip'],
        note: null,
      );
    }
    if (distanceKm <= 6) {
      return (
        vehicle: 'Bike',
        reasons: ['Quick hop', 'Cheapest way across town'],
        note: null,
      );
    }
    return (
      vehicle: '3-Wheeler',
      reasons: ['Mixed load', 'Best value for this distance'],
      note: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final result = _recommendation();

    return GlassCard(
      radius: DesignTokens.radiusLg,
      padding: const EdgeInsets.all(DesignTokens.space4),
      showShadow: true,
      borderColor: colors.primary.withValues(alpha: 0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: DesignTokens.iconSm,
                color: colors.primary,
              ),
              const SizedBox(width: DesignTokens.space2),
              Expanded(
                child: Text(
                  'Based on your goods, we suggest a ${result.vehicle}',
                  style: TokenTextStyles.titleSmall(
                    color: colors.onSurface,
                    weight: DesignTokens.wSemiBold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space2),
          Text(
            '“$goodsType” • ${distanceKm.toStringAsFixed(1)} km trip',
            style: TokenTextStyles.bodySmall(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DesignTokens.space3),
          Wrap(
            spacing: DesignTokens.space2,
            runSpacing: DesignTokens.space2,
            children: [
              for (final reason in result.reasons)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.space2,
                    vertical: DesignTokens.space1,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: DesignTokens.iconXs,
                        color: colors.primary,
                      ),
                      const SizedBox(width: DesignTokens.space1),
                      Text(
                        reason,
                        style: TokenTextStyles.labelSmall(
                          color: colors.primary,
                          weight: DesignTokens.wMedium,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (result.note != null) ...[
            const SizedBox(height: DesignTokens.space3),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(DesignTokens.space3),
              decoration: BoxDecoration(
                color: colors.infoLight,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: DesignTokens.iconSm,
                    color: colors.info,
                  ),
                  const SizedBox(width: DesignTokens.space2),
                  Expanded(
                    child: Text(
                      result.note!,
                      style: TokenTextStyles.bodySmall(
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: DesignTokens.space4),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  text: 'Apply ${result.vehicle}',
                  onPressed: () => onAccept(result.vehicle),
                  height: DesignTokens.buttonHeightMd,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
