import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
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

  Future<String> _trackingUrl() async {
    final response = await FirebaseFunctions.instanceFor(region: EnvConfig.functionsRegion)
        .httpsCallable('createPublicTrackingLink')
        .call({'bookingId': bookingId});
    final token = Map<String, dynamic>.from(response.data as Map)['token'] as String;
    return '${EnvConfig.trackingBaseUrl}/track/$token';
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    try {
      final url = await _trackingUrl();
      final message = 'Track my PickDrop trip live: $url';
      final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(message)}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
      if (!context.mounted) return;
      await SharePlus.instance.share(ShareParams(text: message, subject: 'Share my live PickDrop trip'));
    } catch (_) {
      if (context.mounted) AppToast.error(context, 'Could not create a tracking link. Try again.');
    }
  }

  Future<void> _copyLink(BuildContext context) async {
    try {
      final url = await _trackingUrl();
      AppHelpers.copyToClipboard(url);
      if (context.mounted) AppToast.success(context, 'Tracking link copied to clipboard');
    } catch (_) {
      if (context.mounted) AppToast.error(context, 'Could not create a tracking link. Try again.');
    }
  }

  Future<void> _stopSharing(BuildContext context) async {
    try {
      await FirebaseFunctions.instanceFor(region: EnvConfig.functionsRegion)
          .httpsCallable('revokePublicTrackingLink')
          .call({'bookingId': bookingId});
      if (context.mounted) {
        AppToast.success(context, 'Live tracking link disabled');
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (context.mounted) AppToast.error(context, 'Could not disable the tracking link. Try again.');
    }
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
                  'A private tracking link will be created when you share.',
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
        const SizedBox(height: AppDimensions.spacingSm),
        TextButton.icon(
          onPressed: () => _stopSharing(context),
          icon: const Icon(Icons.link_off_rounded),
          label: const Text('Stop sharing this link'),
          style: TextButton.styleFrom(foregroundColor: colors.error),
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
