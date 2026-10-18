import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/theme/text_styles.dart';

class LanguagePage extends ConsumerWidget {
  const LanguagePage({super.key});

  static const List<_LanguageOption> _options = [
    _LanguageOption(code: 'en', name: 'English', nativeName: 'English'),
    _LanguageOption(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी'),
    _LanguageOption(code: 'kn', name: 'Kannada', nativeName: 'ಕನ್ನಡ'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider);
    final safeTop = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          Container(
            height: safeTop + 120,
            decoration: const BoxDecoration(gradient: AppColors.brandGradient),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppDimensions.spacingMd),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white),
                    ),
                    const SizedBox(width: AppDimensions.spacingXs),
                    Expanded(
                      child: Text(
                        'Language',
                        style: AppTextStyles.headlineSmall
                            .copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppDimensions.spacingXl),
              itemCount: _options.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppDimensions.spacingSm),
              itemBuilder: (context, i) {
                final option = _options[i];
                final selected = current.languageCode == option.code;
                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    side: BorderSide(
                      color: selected ? AppColors.primary : AppColors.outline,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  tileColor: selected
                      ? AppColors.primaryContainer
                      : Colors.white,
                  title: Text(option.name, style: AppTextStyles.titleSmall),
                  subtitle: Text(option.nativeName,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.onSurfaceVariant)),
                  trailing: selected
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.primary)
                      : null,
                  onTap: () =>
                      ref.read(localeProvider.notifier).setLocale(Locale(option.code)),
                )
                    .animate(delay: Duration(milliseconds: i * 80))
                    .fadeIn()
                    .slideX(begin: 0.1, end: 0);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageOption {
  final String code;
  final String name;
  final String nativeName;
  const _LanguageOption({
    required this.code,
    required this.name,
    required this.nativeName,
  });
}
