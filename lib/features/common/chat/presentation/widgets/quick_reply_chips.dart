import 'package:flutter/material.dart';

import '../../../../../core/constants/colors.dart';
import '../../../../../core/constants/dimensions.dart';
import '../../../../../core/theme/text_styles.dart';

class QuickReplyChips extends StatelessWidget {
  const QuickReplyChips({
    super.key,
    required this.onSend,
    this.language = 'en',
  });

  static const List<Map<String, String>> phrases = <Map<String, String>>[
    <String, String>{
      'en': 'Where are you?',
      'hi': 'आप कहाँ हैं',
      'kn': 'ನೀವು ಎಲ್ಲಿದ್ದೀರಿ',
    },
    <String, String>{
      'en': "I'm coming",
      'hi': 'मैं आ रहा हूँ',
      'kn': 'ನಾನು ಬರುತ್ತಿದ್ದೇನೆ',
    },
    <String, String>{
      'en': 'Please wait 5 min',
      'hi': 'कृपया 5 मिनट प्रतीक्षा करें',
      'kn': 'ದಯವಿಟ್ಟು 5 ನಿಮಿಷ ಕಾಯಿರಿ',
    },
    <String, String>{
      'en': 'Reached outside',
      'hi': 'मैं बाहर पहुँच गया हूँ',
      'kn': 'ನಾನು ಹೊರಗೆ ತಲುಪಿದ್ದೇನೆ',
    },
    <String, String>{
      'en': 'Call me',
      'hi': 'मुझे कॉल करें',
      'kn': 'ನನಗೆ ಕರೆ ಮಾಡಿ',
    },
    <String, String>{'en': 'Thank you', 'hi': 'धन्यवाद', 'kn': 'ಧನ್ಯವಾದಗಳು'},
  ];

  final ValueChanged<String> onSend;
  final String language;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      height: AppDimensions.chipHeightLg + AppDimensions.spacingMd,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingLg,
          vertical: AppDimensions.spacingXs,
        ),
        itemCount: phrases.length,
        separatorBuilder: (_, _) =>
            const SizedBox(width: AppDimensions.spacingSm),
        itemBuilder: (context, index) {
          final chip = phrases[index];
          final label = chip[language] ?? chip['en']!;

          return Material(
            color: colors.glass,
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              onTap: () => onSend(label),
              child: Ink(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingMd,
                  vertical: AppDimensions.spacingXs,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  border: Border.all(color: colors.glassBorder, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      size: AppDimensions.iconXs,
                      color: colors.primary,
                    ),
                    const SizedBox(width: AppDimensions.spacingXxs),
                    Text(
                      label,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
