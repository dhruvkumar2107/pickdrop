import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/router/route_names.dart';
import '../../../../../core/constants/colors.dart';
import '../../../../../core/constants/dimensions.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../../../../core/widgets/glass_card.dart';
import 'live_chat_support_sheet.dart';

class PriorityTripHelpCard extends StatelessWidget {
  final String bookingId;
  final String? tripLabel;

  const PriorityTripHelpCard({
    super.key,
    required this.bookingId,
    this.tripLabel,
  });

  void _openLiveChat(BuildContext context) {
    LiveChatSupportSheet.show(context, activeBookingId: bookingId);
  }

  void _requestCallback(BuildContext context) {
    AppToast.success(context, 'Callback requested - an agent will call you within 5 min.');
  }

  void _openChat(BuildContext context) {
    final id = Uri.encodeComponent(bookingId);
    final peer = Uri.encodeComponent('Driver');
    context.push('${RouteNames.chat}?bookingId=$id&peerName=$peer&role=driver');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GlassCard(
      showShadow: true,
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      borderColor: colors.primary,
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
                child: Icon(Icons.support_agent_rounded,
                    size: AppDimensions.iconMd, color: colors.primary),
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Help with this trip',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      tripLabel == null || tripLabel!.isEmpty
                          ? 'Trip $bookingId'
                          : tripLabel!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colors.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingSm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Text(
                  'PRIORITY',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: DesignTokens.lsWide,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingMd,
              vertical: AppDimensions.spacingSm,
            ),
            decoration: BoxDecoration(
              color: colors.successLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule_rounded, size: AppDimensions.iconSm, color: colors.success),
                const SizedBox(width: AppDimensions.spacingXs),
                Expanded(
                  child: Text(
                    'Reply within 5 min during your trip',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Live chat',
                  onTap: () => _openLiveChat(context),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              Expanded(
                child: _ActionButton(
                  icon: Icons.phone_callback_rounded,
                  label: 'Call back',
                  onTap: () => _requestCallback(context),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              Expanded(
                child: _ActionButton(
                  icon: Icons.forum_outlined,
                  label: 'Chat',
                  onTap: () => _openChat(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: colors.surfaceVariant,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingSm,
            vertical: AppDimensions.spacingMd,
          ),
          child: Column(
            children: [
              Icon(icon, size: AppDimensions.iconSm, color: colors.primary),
              const SizedBox(height: AppDimensions.spacingXs),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSmall.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
