import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/router/route_names.dart';
import '../../../../../core/constants/colors.dart';
import '../../../../../core/constants/dimensions.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../../core/widgets/glass_card.dart';
import 'live_share_card.dart';

class TripActionRow extends StatelessWidget {
  const TripActionRow({super.key, required this.bookingId});

  final String? bookingId;

  String get _bookingKey =>
      (bookingId == null || bookingId!.isEmpty) ? 'active' : bookingId!;

  void _openChat(BuildContext context) {
    final peerName = Uri.encodeComponent('Driver');
    final id = Uri.encodeComponent(_bookingKey);
    context.push('${RouteNames.chat}?bookingId=$id&peerName=$peerName&role=driver');
  }

  void _openShareSheet(BuildContext context) {
    showAppBottomSheet<void>(
      context: context,
      title: 'Share live trip',
      builder: (context) => LiveShareCard(bookingId: _bookingKey),
    );
  }

  void _openSafety(BuildContext context) {
    context.push(RouteNames.safetyMode);
  }

  void _openTripHelp(BuildContext context) {
    final id = Uri.encodeComponent(_bookingKey);
    final trip = Uri.encodeComponent('Live delivery');
    context.push('${RouteNames.helpSupport}?bookingId=$id&tripLabel=$trip');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        Expanded(
          child: _action(
            colors,
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Chat',
            onTap: () => _openChat(context),
          ),
        ),
        const SizedBox(width: AppDimensions.spacingSm),
        Expanded(
          child: _action(
            colors,
            icon: Icons.share_outlined,
            label: 'Share',
            onTap: () => _openShareSheet(context),
          ),
        ),
        const SizedBox(width: AppDimensions.spacingSm),
        Expanded(
          child: _action(
            colors,
            icon: Icons.shield_outlined,
            label: 'Safety',
            onTap: () => _openSafety(context),
          ),
        ),
        const SizedBox(width: AppDimensions.spacingSm),
        Expanded(
          child: _action(
            colors,
            icon: Icons.support_agent_outlined,
            label: 'Help',
            onTap: () => _openTripHelp(context),
          ),
        ),
      ],
    );
  }

  Widget _action(
    AppColorsExtension colors, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      onTap: onTap,
      showShadow: true,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingXs,
        vertical: AppDimensions.spacingSm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppDimensions.iconSm, color: colors.primary),
          const SizedBox(height: AppDimensions.spacingXxs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
