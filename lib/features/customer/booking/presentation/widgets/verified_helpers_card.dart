import 'package:flutter/material.dart';
import '../../../../../core/constants/colors.dart';
import '../../../../../core/constants/dimensions.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../core/widgets/glass_card.dart';
import '../../../../../core/widgets/status_chip.dart';

class VerifiedHelpersCard extends StatefulWidget {
  final ValueChanged<List<String>> onChanged;

  const VerifiedHelpersCard({super.key, required this.onChanged});

  @override
  State<VerifiedHelpersCard> createState() => _VerifiedHelpersCardState();
}

class _VerifiedHelpersCardState extends State<VerifiedHelpersCard> {
  static const double pickupPrice = 79;
  static const double dropPrice = 79;
  static const double bundlePrice = 149;

  static const List<_Helper> _helpers = [
    _Helper(id: 'helper_pickup_ravi', name: 'Ravi Kumar', role: 'pickup', rating: 4.9, jobs: 1240),
    _Helper(id: 'helper_pickup_suresh', name: 'Suresh Babu', role: 'pickup', rating: 4.7, jobs: 980),
    _Helper(id: 'helper_drop_anil', name: 'Anil Sharma', role: 'drop', rating: 4.8, jobs: 1510),
    _Helper(id: 'helper_drop_manoj', name: 'Manoj Gupta', role: 'drop', rating: 4.6, jobs: 760),
  ];

  String? _pickupId;
  String? _dropId;

  bool get _hasPickup => _pickupId != null;
  bool get _hasDrop => _dropId != null;
  bool get _hasBoth => _hasPickup && _hasDrop;

  double get _total {
    if (_hasBoth) return bundlePrice;
    if (_hasPickup) return pickupPrice;
    if (_hasDrop) return dropPrice;
    return 0;
  }

  List<String> get _selectedIds =>
      [_pickupId, _dropId].whereType<String>().toList(growable: false);

  void _toggle(_Helper helper) {
    setState(() {
      if (helper.role == 'pickup') {
        _pickupId = _pickupId == helper.id ? null : helper.id;
      } else {
        _dropId = _dropId == helper.id ? null : helper.id;
      }
    });
    widget.onChanged(_selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GlassCard(
      showShadow: true,
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
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.groups_rounded, size: AppDimensions.iconMd, color: colors.primary),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verified loading helpers',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      'Transparent pricing - nothing to pay in cash later',
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
          const SizedBox(height: AppDimensions.spacingMd),
          _sectionLabel('At pickup - ₹${pickupPrice.toStringAsFixed(0)} each', colors),
          ..._helpers.where((h) => h.role == 'pickup').map((h) => _helperRow(h, colors)),
          const SizedBox(height: AppDimensions.spacingSm),
          _sectionLabel('At drop - ₹${dropPrice.toStringAsFixed(0)} each', colors),
          ..._helpers.where((h) => h.role == 'drop').map((h) => _helperRow(h, colors)),
          const SizedBox(height: AppDimensions.spacingSm),
          const Divider(height: AppDimensions.spacingMd),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Running total',
                      style: AppTextStyles.labelSmall.copyWith(color: colors.onSurfaceVariant),
                    ),
                    Text(
                      '₹${_total.toStringAsFixed(0)}',
                      style: AppTextStyles.priceMedium.copyWith(color: colors.primary),
                    ),
                  ],
                ),
              ),
              if (_hasBoth)
                StatusChip(
                  label: 'BUNDLE PRICE - SAVE ₹${(pickupPrice + dropPrice - bundlePrice).toStringAsFixed(0)}',
                  status: AppChipStatus.success,
                  showDot: false,
                )
              else
                StatusChip(
                  label: _total == 0 ? 'NO HELPER SELECTED' : 'ONE HELPER ADDED',
                  status: AppChipStatus.neutral,
                  showDot: false,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, AppColorsExtension colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingXs),
      child: Text(
        text,
        style: AppTextStyles.labelMedium.copyWith(
          color: colors.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _helperRow(_Helper helper, AppColorsExtension colors) {
    final selected = helper.role == 'pickup'
        ? _pickupId == helper.id
        : _dropId == helper.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
      child: GestureDetector(
        onTap: () => _toggle(helper),
        child: AnimatedContainer(
          duration: DesignTokens.durationFast,
          curve: DesignTokens.springSnappy,
          padding: const EdgeInsets.all(AppDimensions.spacingSm),
          decoration: BoxDecoration(
            color: selected ? colors.primaryContainer : colors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: selected ? colors.primary : colors.outline,
              width: selected ? DesignTokens.borderMedium : DesignTokens.borderThin,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: AppDimensions.avatarMd,
                height: AppDimensions.avatarMd,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? colors.primary : colors.surfaceCard,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  helper.name.substring(0, 1),
                  style: AppTextStyles.titleSmall.copyWith(
                    color: selected ? colors.onPrimary : colors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            helper.name,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelLarge.copyWith(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spacingXs),
                        const StatusChip(
                          label: 'ID VERIFIED',
                          status: AppChipStatus.success,
                          showDot: false,
                          dense: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, size: 14, color: colors.warning),
                        const SizedBox(width: 2),
                        Text(
                          helper.rating.toStringAsFixed(1),
                          style: AppTextStyles.labelSmall.copyWith(color: colors.onSurface),
                        ),
                        const SizedBox(width: AppDimensions.spacingSm),
                        Icon(Icons.work_outline_rounded, size: 13, color: colors.onSurfaceVariant),
                        const SizedBox(width: 3),
                        Text(
                          '${helper.jobs} jobs',
                          style: AppTextStyles.labelSmall.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.spacingXs),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${(helper.role == 'pickup' ? pickupPrice : dropPrice).toStringAsFixed(0)}',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Icon(
                    selected ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                    size: AppDimensions.iconSm,
                    color: selected ? colors.primary : colors.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Helper {
  final String id;
  final String name;
  final String role;
  final double rating;
  final int jobs;

  const _Helper({
    required this.id,
    required this.name,
    required this.role,
    required this.rating,
    required this.jobs,
  });
}
