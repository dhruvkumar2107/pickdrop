import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../constants/colors.dart';
import '../theme/design_tokens.dart';
import 'buttons/buttons.dart';

enum AppStateViewType { loading, empty, error, offline, noDriver, slowNetwork }

class AppStateView extends StatelessWidget {
  final AppStateViewType type;
  final String? title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppStateView({
    super.key,
    required this.type,
    this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  static const Map<AppStateViewType, (String, String, String)> _defaults = {
    AppStateViewType.loading: (
      'Just a moment',
      'We are getting things ready for you.',
      'assets/animations/loading.json',
    ),
    AppStateViewType.empty: (
      'Nothing here yet',
      'Your completed trips will show up here.',
      'assets/animations/empty_trips.json',
    ),
    AppStateViewType.error: (
      'Something went wrong',
      'Please try once more, we will pick up right where we left off.',
      'assets/animations/error.json',
    ),
    AppStateViewType.offline: (
      'You are offline',
      'Check your connection and try again.',
      'assets/animations/error.json',
    ),
    AppStateViewType.noDriver: (
      'No riders nearby',
      'We are widening the search, try again in a moment.',
      'assets/animations/no_driver.json',
    ),
    AppStateViewType.slowNetwork: (
      'Slow connection',
      'This is taking longer than usual, try again.',
      'assets/animations/error.json',
    ),
  };

  static const Map<AppStateViewType, IconData> _fallbackIcons = {
    AppStateViewType.loading: Icons.hourglass_top_rounded,
    AppStateViewType.empty: Icons.inbox_outlined,
    AppStateViewType.error: Icons.error_outline_rounded,
    AppStateViewType.offline: Icons.wifi_off_rounded,
    AppStateViewType.noDriver: Icons.local_shipping_outlined,
    AppStateViewType.slowNetwork: Icons.signal_cellular_alt_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final defaults = _defaults[type]!;
    final asset = defaults.$3;
    final isRepeat = type == AppStateViewType.loading;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 140,
              height: 140,
              child: Lottie.asset(
                asset,
                width: 140,
                height: 140,
                repeat: isRepeat,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Icon(
                  _fallbackIcons[type],
                  size: 72,
                  color: colors.primary,
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.space6),
            Text(
              title ?? defaults.$1,
              textAlign: TextAlign.center,
              style: TokenTextStyles.titleMedium(
                color: colors.onSurface,
                weight: DesignTokens.wSemiBold,
              ),
            ),
            const SizedBox(height: DesignTokens.space2),
            Text(
              message ?? defaults.$2,
              textAlign: TextAlign.center,
              style: TokenTextStyles.bodyMedium(
                color: colors.onSurfaceVariant,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: DesignTokens.space6),
              PrimaryButton(
                text: actionLabel!,
                onPressed: onAction,
                isFullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
