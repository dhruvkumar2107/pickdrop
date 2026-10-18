import 'package:flutter/material.dart';
import '../../../../../../core/constants/colors.dart';
import '../../../../../../core/constants/dimensions.dart';
import '../../../../../../core/theme/text_styles.dart';

class GoodsHandlingTagsWidget extends StatelessWidget {
  final List<String> selectedTags;
  final ValueChanged<List<String>> onTagsChanged;

  static const List<Map<String, dynamic>> availableTags = [
    {'id': 'fragile', 'label': 'Fragile Handle With Care', 'icon': Icons.wine_bar_outlined, 'color': Color(0xFFEF4444)},
    {'id': 'this_side_up', 'label': 'This Side Up ↑', 'icon': Icons.arrow_upward_rounded, 'color': Color(0xFF2563EB)},
    {'id': 'perishable', 'label': 'Perishable Goods', 'icon': Icons.ac_unit_rounded, 'color': Color(0xFF059669)},
    {'id': 'heavy', 'label': 'Heavy Load', 'icon': Icons.fitness_center_rounded, 'color': Color(0xFFD97706)},
  ];

  const GoodsHandlingTagsWidget({
    super.key,
    required this.selectedTags,
    required this.onTagsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Goods Handling Tags for Driver',
          style: AppTextStyles.titleSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXs),
        Text(
          'Tags will be prominently highlighted on driver\'s app during pickup & transit',
          style: AppTextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: AppDimensions.spacingSm),
        Wrap(
          spacing: AppDimensions.spacingSm,
          runSpacing: AppDimensions.spacingSm,
          children: availableTags.map((tag) {
            final id = tag['id'] as String;
            final isSelected = selectedTags.contains(id);
            final color = tag['color'] as Color;

            return FilterChip(
              avatar: Icon(
                tag['icon'] as IconData,
                size: 16,
                color: isSelected ? Colors.white : color,
              ),
              label: Text(tag['label'] as String),
              labelStyle: AppTextStyles.labelSmall.copyWith(
                color: isSelected ? Colors.white : colors.onSurface,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              selected: isSelected,
              selectedColor: color,
              backgroundColor: colors.surfaceVariant,
              checkmarkColor: Colors.white,
              onSelected: (selected) {
                final updated = List<String>.from(selectedTags);
                if (selected) {
                  updated.add(id);
                } else {
                  updated.remove(id);
                }
                onTagsChanged(updated);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
