import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/constants/colors.dart';
import '../../../../../core/constants/dimensions.dart';
import '../../../../../core/constants/strings.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../../../../core/widgets/glass_card.dart';
import '../../../../../core/widgets/status_chip.dart';
import '../widgets/help_center_search.dart';
import '../widgets/instant_refund_card.dart';
import '../widgets/live_chat_support_sheet.dart';
import '../widgets/priority_trip_help_card.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key, this.activeBookingId, this.activeTripLabel});

  final String? activeBookingId;
  final String? activeTripLabel;

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  Future<void> _callSupport() async {
    final uri = Uri(scheme: 'tel', path: '1800000000');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) AppToast.info(context, 'Dial 1800 000 000 to reach support');
    }
  }

  Future<void> _emailSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@pickdrop.in',
      queryParameters: {'subject': 'PickDrop support request'},
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) AppToast.info(context, 'Email us at support@pickdrop.in');
    }
  }

  void _openLiveChat() {
    LiveChatSupportSheet.show(context, activeBookingId: widget.activeBookingId);
  }

  void _requestCallback() {
    AppToast.success(context, 'Callback requested - an agent will call you within 5 min.');
  }

  void _openInstantRefund() {
    InstantRefundCard.show(context, bookingId: widget.activeBookingId);
  }

  @override
  Widget build(BuildContext context) {
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
                        AppStrings.helpSupport,
                        style: AppTextStyles.headlineSmall
                            .copyWith(color: Colors.white),
                      ),
                    ),
                    const StatusChip(
                      label: 'SLA 5 MIN',
                      status: AppChipStatus.success,
                      backgroundColor: Colors.white,
                      foregroundColor: DesignTokens.success500,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppDimensions.spacingXl),
              children: [
                if (widget.activeBookingId != null) ...[
                  PriorityTripHelpCard(
                    bookingId: widget.activeBookingId!,
                    tripLabel: widget.activeTripLabel,
                  ),
                  const SizedBox(height: AppDimensions.spacingXl),
                ],
                Text(AppStrings.faqs, style: AppTextStyles.titleMedium),
                const SizedBox(height: AppDimensions.spacingMd),
                HelpCenterSearch(
                  faqs: HelpCenterSearch.defaultFaqs,
                  onLiveChat: _openLiveChat,
                ),
                const SizedBox(height: AppDimensions.spacingXl),
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.call_outlined,
                        title: AppStrings.contactUs,
                        subtitle: '24×7 helpline',
                        onTap: _callSupport,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingMd),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.mail_outline_rounded,
                        title: 'Email us',
                        subtitle: 'support@pickdrop.in',
                        onTap: _emailSupport,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingMd),
                _CallbackTicketRow(onRequestCallback: _requestCallback),
                const SizedBox(height: AppDimensions.spacingMd),
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'Live chat',
                        subtitle: 'Reply in 5 min',
                        onTap: _openLiveChat,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingMd),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.currency_rupee_rounded,
                        title: 'Instant refund',
                        subtitle: 'To wallet, no waiting',
                        onTap: _openInstantRefund,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingMd),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () =>
                          AppToast.info(context, AppStrings.termsConditions),
                      child: Text(AppStrings.termsConditions,
                          style: AppTextStyles.labelMedium
                              .copyWith(color: AppColors.primary)),
                    ),
                    TextButton(
                      onPressed: () =>
                          AppToast.info(context, AppStrings.privacyPolicy),
                      child: Text(AppStrings.privacyPolicy,
                          style: AppTextStyles.labelMedium
                              .copyWith(color: AppColors.primary)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CallbackTicketRow extends StatelessWidget {
  final VoidCallback onRequestCallback;

  const _CallbackTicketRow({required this.onRequestCallback});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GlassCard(
      showShadow: true,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingMd,
        vertical: AppDimensions.spacingSm,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingSm),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.confirmation_number_outlined,
                size: AppDimensions.iconSm, color: colors.primary),
          ),
          const SizedBox(width: AppDimensions.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ticket #PD-2291',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const StatusChip(
                      label: 'IN PROGRESS',
                      status: AppChipStatus.active,
                      dense: true,
                    ),
                    const SizedBox(width: AppDimensions.spacingXs),
                    Flexible(
                      child: Text(
                        'Last reply 2 min ago',
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelSmall
                            .copyWith(color: colors.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onRequestCallback,
            child: Text(
              'Request callback',
              style: AppTextStyles.labelSmall.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      showShadow: true,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          Text(title, style: AppTextStyles.labelLarge,
              textAlign: TextAlign.center),
          Text(subtitle,
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
