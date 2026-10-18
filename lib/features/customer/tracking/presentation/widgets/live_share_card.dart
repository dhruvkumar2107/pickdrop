import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../config/env/env_config.dart';
import '../../../../../config/router/route_names.dart';
import '../../../../../core/constants/colors.dart';
import '../../../../../core/constants/dimensions.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../core/utils/helpers.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../../../../core/widgets/buttons/buttons.dart';
import '../../../../../core/widgets/glass_card.dart';
import '../../../../../core/widgets/gradient_button.dart';

class LiveShareCard extends StatelessWidget {
  const LiveShareCard({super.key, required this.bookingId});

  final String bookingId;

  String get trackingUrl => '${EnvConfig.trackingBaseUrl}/track/$bookingId';

  String get _message => 'Track my PickDrop trip live: $trackingUrl';

  Future<void> _openWhatsApp(BuildContext context) async {
    final uri = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(_message)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    if (!context.mounted) return;
    await SharePlus.instance.share(
      ShareParams(text: _message, subject: 'Share my live PickDrop trip'),
    );
  }

  void _copyLink(BuildContext context) {
    AppHelpers.copyToClipboard(trackingUrl);
    AppToast.success(context, 'Tracking link copied to clipboard');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: AppDimensions.avatarMd,
              height: AppDimensions.avatarMd,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_on_outlined,
                size: AppDimensions.iconMd,
                color: colors.primary,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Share live trip on WhatsApp',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                  Text(
                    'Family can watch the trip without installing the app',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingMd),
        GlassCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingMd,
            vertical: AppDimensions.spacingSm,
          ),
          child: Row(
            children: [
              Icon(
                Icons.link_rounded,
                size: AppDimensions.iconSm,
                color: colors.primary,
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              Expanded(
                child: Text(
                  trackingUrl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spacingMd),
        GradientButton(
          text: 'Share on WhatsApp',
          leadingIcon: Icons.chat_rounded,
          onPressed: () => _openWhatsApp(context),
          gradient: AppColors.successGradient,
        ),
        const SizedBox(height: AppDimensions.spacingSm),
        OutlinedPrimaryButton(
          text: 'Copy link',
          leadingIcon: Icons.copy_rounded,
          onPressed: () => _copyLink(context),
          borderColor: colors.outline,
          textColor: colors.onSurface,
        ),
        const SizedBox(height: AppDimensions.spacingMd),
        GlassCard(
          onTap: () => context.push(RouteNames.safetyMode),
          showShadow: true,
          padding: const EdgeInsets.all(AppDimensions.spacingMd),
          child: Row(
            children: [
              Container(
                width: AppDimensions.avatarMd,
                height: AppDimensions.avatarMd,
                decoration: BoxDecoration(
                  color: colors.warning.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shield_outlined,
                  size: AppDimensions.iconMd,
                  color: colors.warning,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Family & friends',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      'Add emergency contacts and safety alerts',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: AppDimensions.iconMd,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
