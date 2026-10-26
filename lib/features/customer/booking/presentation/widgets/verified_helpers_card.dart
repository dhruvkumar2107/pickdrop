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

  // The assigned driver does the loading and is paid the fee with the trip.
  static const List<_Helper> _helpers = [
    _Helper(id: 'helper_pickup_driver', name: 'Driver loads goods at pickup', role: 'pickup'),
    _Helper(id: 'helper_drop_driver', name: 'Driver unloads goods at drop', role: 'drop'),
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
                      'Loading & unloading help',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      'Paid in the app fare - nothing extra in cash',
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
          _sectionLabel('At pickup', colors),
          ..._helpers.where((h) => h.role == 'pickup').map((h) => _helperRow(h, colors)),
          const SizedBox(height: AppDimensions.spacingSm),
          _sectionLabel('At drop', colors),
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
                  label: _total == 0 ? 'NOT ADDED' : 'HELP ADDED',
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
                child: Icon(
                  helper.role == 'pickup'
                      ? Icons.upload_rounded
                      : Icons.download_rounded,
                  size: AppDimensions.iconSm,
                  color: selected ? colors.onPrimary : colors.onSurface,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              Expanded(
                child: Text(
                  helper.name,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
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

  const _Helper({
    required this.id,
    required this.name,
    required this.role,
  });
}
