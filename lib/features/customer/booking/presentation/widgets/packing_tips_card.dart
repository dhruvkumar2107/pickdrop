import 'package:flutter/material.dart';
import '../../../../../core/constants/colors.dart';
import '../../../../../core/constants/dimensions.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../core/widgets/glass_card.dart';

class PackingTipsCard extends StatefulWidget {
  final String goodsType;

  const PackingTipsCard({super.key, required this.goodsType});

  @override
  State<PackingTipsCard> createState() => _PackingTipsCardState();
}

class _PackingTipsCardState extends State<PackingTipsCard> {
  bool _expanded = false;

  static const Map<String, _TipsCategory> _categories = {
    'electronics': _TipsCategory(
      icon: Icons.devices_other_rounded,
      bullets: [
        'Wrap every item in at least 2 cm of bubble wrap or foam corner guards.',
        'Remove batteries and pack loose cables in a separate sealed pouch.',
        'Use the original box if you still have it, else double-box with padding on all sides.',
        'Never stack screens face-down - lay them flat and mark "LCD SIDE UP".',
        'Photograph serial numbers and existing scratches before handing over.',
        'Tape all box seams shut and write "Fragile" on two sides.',
      ],
    ),
    'food': _TipsCategory(
      icon: Icons.restaurant_rounded,
      bullets: [
        'Chill or freeze perishables before pickup so they last the whole ride.',
        'Use insulated bags with ice packs for dairy, meat and desserts.',
        'Double-bag liquids and tape the caps so nothing leaks in transit.',
        'Pack ready-to-eat food in rigid, sealed containers - never open trays.',
        'Label the box "Keep Upright" and "Deliver within 2 hours".',
        'Keep raw and cooked food in separate leak-proof boxes.',
      ],
    ),
    'documents': _TipsCategory(
      icon: Icons.folder_copy_outlined,
      bullets: [
        'Slide papers into a waterproof zip folder or laminated sleeve first.',
        'Add a stiff cardboard backer so nothing bends or curls.',
        'Seal the folder with a tamper sticker across the opening.',
        'Photograph every important page as a backup on your phone.',
        'Write the destination address on the outside, never on the papers.',
        'Bundle pages with a rubber band inside the sleeve so they stay in order.',
      ],
    ),
    'furniture': _TipsCategory(
      icon: Icons.weekend_outlined,
      bullets: [
        'Dismantle legs, knobs and shelves and tape them to the main body in one bundle.',
        'Wrap corners and edges with foam rolls - corners take the hardest hits.',
        'Shrink-wrap drawers shut so they cannot slide open in transit.',
        'Cover fabric with a moving blanket to stop dust and snags.',
        'Stand wardrobes and tables upright and strap them to the vehicle wall.',
        'Empty every cupboard - even light items turn into projectiles.',
      ],
    ),
    'glassware': _TipsCategory(
      icon: Icons.wine_bar_outlined,
      bullets: [
        'Wrap every piece twice - bubble wrap first, newspaper over it.',
        'Wrap stems separately and pack glasses stem-down in a divided box.',
        'Fill all empty space with crumpled paper so nothing can shift.',
        'Tape an X on mirrors and glass tops to hold shards together.',
        'Use a double-walled carton and label it FRAGILE on two sides.',
        'Always keep heavier items at the bottom, glass on top.',
      ],
    ),
    'medicines': _TipsCategory(
      icon: Icons.medication_rounded,
      bullets: [
        'Keep medicines in their original, clearly labelled pharmacy boxes.',
        'Use a rigid padded box so blister packs and vials are never crushed.',
        'Maintain the cold chain - ice packs for insulin, no direct contact.',
        'Send prescription papers with the shipment and keep a copy at home.',
        'Mark the box "Medical - Handle With Care" and "This Side Up".',
        'Check expiry dates before packing so nothing arrives expired.',
      ],
    ),
    'clothes': _TipsCategory(
      icon: Icons.checkroom_rounded,
      bullets: [
        'Fold along seams or roll garments to avoid hard creases.',
        'Put formal wear in a garment bag with the hanger hooked inside.',
        'Bag shoes and belts separately so soles never touch fabric.',
        'Use vacuum bags for bulky quilts and winter wear to save space.',
        'Slip acid-free tissue between embroidered or embellished pieces.',
        'Seal the carton fully and label it "Do Not Wet".',
      ],
    ),
    'fragile': _TipsCategory(
      icon: Icons.inventory_2_outlined,
      bullets: [
        'Pick a box one size smaller - less empty space means less movement.',
        'Line the bottom of every box with 5 cm of crumpled paper or foam.',
        'Wrap each item individually, even when they feel sturdy together.',
        'Fill every gap so nothing slides when the driver brakes.',
        'Seal with the H-tape method: two strips across, one along the seam.',
        'Write "Fragile", "This Side Up" and the address on two sides.',
      ],
    ),
  };

  static const List<List<String>> _keywords = [
    ['electronic', 'laptop', 'computer', 'television', ' tv', 'mobile', 'phone', 'camera', 'appliance', 'speaker', 'monitor', 'gadget', 'refrigerator', 'fridge', 'washing'],
    ['food', 'perishable', 'grocer', 'vegetable', 'fruit', 'dairy', 'milk', 'cake', 'bakery', 'meat', 'chicken', 'fish', 'frozen', 'ice cream', 'catering', 'restaurant'],
    ['medicine', 'pharma', 'drug', 'tablet', 'vaccine', 'medical', 'health', 'syrup'],
    ['document', 'file', 'paper', 'legal', 'certificate', 'book', 'stationery', 'magazine', 'archive', 'contract'],
    ['furniture', 'sofa', 'couch', 'table', 'chair', 'wardrobe', 'bed', 'desk', 'cabinet', 'mattress', 'shelf', 'cupboard'],
    ['cloth', 'dress', 'apparel', 'textile', 'garment', 'saree', 'uniform', 'laundry', 'shoe'],
    ['glass', 'mirror', 'bottle', 'crockery', 'china', 'vase', 'showpiece', 'decor', 'crystal'],
  ];

  static const List<String> _categoryKeys = [
    'electronics',
    'food',
    'medicines',
    'documents',
    'furniture',
    'clothes',
    'glassware',
  ];

  String get _resolvedKey {
    final raw = widget.goodsType.trim().toLowerCase();
    if (raw.isEmpty) return 'fragile';
    for (var i = 0; i < _keywords.length; i++) {
      for (final keyword in _keywords[i]) {
        if (raw.contains(keyword)) return _categoryKeys[i];
      }
    }
    return 'fragile';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final category = _categories[_resolvedKey]!;
    final label =
        widget.goodsType.trim().isEmpty ? 'goods' : widget.goodsType.trim();

    return GlassCard(
      showShadow: true,
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingSm),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(category.icon, size: AppDimensions.iconMd, color: colors.primary),
                ),
                const SizedBox(width: AppDimensions.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Packing tips for your $label',
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                      Text(
                        '${category.bullets.length} quick checks before pickup',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: colors.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: DesignTokens.durationNormal,
                  curve: DesignTokens.springSnappy,
                  child: Icon(
                    Icons.expand_more_rounded,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: AppDimensions.spacingMd),
            const Divider(height: AppDimensions.spacingSm),
            const SizedBox(height: AppDimensions.spacingSm),
            ...category.bullets.map(
              (bullet) => Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: AppDimensions.iconSm,
                      color: colors.primary,
                    ),
                    const SizedBox(width: AppDimensions.spacingSm),
                    Expanded(
                      child: Text(
                        bullet,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: colors.onSurfaceVariant,
                          height: DesignTokens.lhRelaxed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TipsCategory {
  final IconData icon;
  final List<String> bullets;

  const _TipsCategory({required this.icon, required this.bullets});
}
