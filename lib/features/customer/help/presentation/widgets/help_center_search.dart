import 'package:flutter/material.dart';

import '../../../../../core/constants/colors.dart';
import '../../../../../core/constants/dimensions.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../core/widgets/glass_card.dart';

class FaqItem {
  final String question;
  final String answer;

  const FaqItem({required this.question, required this.answer});
}

class HelpCenterSearch extends StatefulWidget {
  final List<FaqItem> faqs;
  final VoidCallback? onLiveChat;

  const HelpCenterSearch({super.key, required this.faqs, this.onLiveChat});

  static const List<FaqItem> defaultFaqs = [
    FaqItem(
      question: 'How do I book a delivery?',
      answer:
          'Pick your pickup and drop locations, choose a vehicle type that fits your goods, review the fare, and confirm. A nearby driver is assigned within minutes.',
    ),
    FaqItem(
      question: 'How is the fare calculated?',
      answer:
          'Fare = base fare + distance fare + time fare, plus surge (if any) and 5% GST. The full breakdown is shown before you confirm the booking.',
    ),
    FaqItem(
      question: 'What is the pickup OTP?',
      answer:
          'A 4-digit OTP is generated for every trip. Share it with the driver only after your goods are loaded to start the trip.',
    ),
    FaqItem(
      question: 'Can I cancel after a driver is assigned?',
      answer:
          'Yes. Cancellation is free within 2 minutes of assignment. After that a ₹50 cancellation fee applies.',
    ),
    FaqItem(
      question: 'Which payment methods are supported?',
      answer: 'UPI, cards, netbanking via Razorpay, and cash (COD) to the driver.',
    ),
  ];

  @override
  State<HelpCenterSearch> createState() => _HelpCenterSearchState();
}

class _HelpCenterSearchState extends State<HelpCenterSearch> {
  final _controller = TextEditingController();
  String _query = '';
  int? _openIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    setState(() => _query = '');
  }

  List<FaqItem> get _results {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.faqs;
    return widget.faqs
        .where((faq) =>
            faq.question.toLowerCase().contains(query) ||
            faq.answer.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final results = _results;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          onChanged: (value) => setState(() => _query = value),
          style: AppTextStyles.bodyMedium.copyWith(color: colors.onSurface),
          decoration: InputDecoration(
            hintText: 'Search help topics, e.g. fare, OTP, refund',
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: colors.onSurfaceVariant,
            ),
            prefixIcon: Icon(Icons.search_rounded, color: colors.primary),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    onPressed: _clear,
                    icon: Icon(Icons.close_rounded, color: colors.onSurfaceVariant),
                  ),
            filled: true,
            fillColor: colors.surfaceVariant,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingMd,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spacingMd),
        if (results.isEmpty)
          _emptyState(colors)
        else
          ...List.generate(results.length, (i) {
            final faq = results[i];
            final open = _openIndex == i;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
              child: GlassCard(
                onTap: () => setState(() => _openIndex = open ? null : i),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            faq.question,
                            style: AppTextStyles.labelLarge.copyWith(
                              color: colors.onSurface,
                            ),
                          ),
                        ),
                        Icon(
                          open
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          color: colors.onSurfaceVariant,
                        ),
                      ],
                    ),
                    if (open) ...[
                      const SizedBox(height: AppDimensions.spacingSm),
                      Text(
                        faq.answer,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: colors.onSurfaceVariant,
                          height: DesignTokens.lhRelaxed,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _emptyState(AppColorsExtension colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 36, color: colors.onSurfaceVariant),
          const SizedBox(height: AppDimensions.spacingSm),
          Text(
            'No match — start a live chat instead',
            textAlign: TextAlign.center,
            style: AppTextStyles.labelLarge.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: AppDimensions.spacingXs),
          Text(
            'Our priority agents reply in under 5 minutes during an active trip.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          OutlinedButton.icon(
            onPressed: widget.onLiveChat,
            icon: Icon(Icons.chat_bubble_outline_rounded,
                size: AppDimensions.iconSm, color: colors.primary),
            label: Text(
              'Start live chat',
              style: AppTextStyles.labelMedium.copyWith(color: colors.primary),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
