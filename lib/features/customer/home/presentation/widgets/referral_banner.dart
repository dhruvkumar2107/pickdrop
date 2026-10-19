import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../config/env/env_config.dart';
import '../../../../../core/constants/colors.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/utils/helpers.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../../../../core/widgets/glass_card.dart';
import '../../../../../core/widgets/gradient_button.dart';

class ReferralBanner extends StatefulWidget {
  const ReferralBanner({super.key});

  @override
  State<ReferralBanner> createState() => _ReferralBannerState();
}

class _ReferralBannerState extends State<ReferralBanner> {
  late final Future<String> _codeFuture;

  @override
  void initState() {
    super.initState();
    _codeFuture = _loadCode();
  }

  Future<String> _loadCode() async {
    final result = await FirebaseFunctions.instanceFor(region: EnvConfig.functionsRegion)
        .httpsCallable('getReferralCode').call();
    return (Map<String, dynamic>.from(result.data as Map)['code'] as String).toUpperCase();
  }

  Future<void> _copyCode(BuildContext context, String code) async {
    AppHelpers.copyToClipboard(code);
    if (!context.mounted) return;
    AppToast.success(context, 'Referral code copied: $code');
  }

  Future<void> _shareInvite(BuildContext context, String code) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: 'Use my PickDrop referral code $code. You and I each receive ₹50 wallet credit after your first completed delivery. Download PickDrop and enter the code at checkout.',
          subject: 'PickDrop referral code $code',
        ),
      );
    } catch (_) {}
    if (!context.mounted) return;
    AppToast.success(context, 'Your invite is ready to share');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _codeFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return GlassCard(
            child: Text(snapshot.hasError ? 'Referral codes are unavailable right now.' : 'Loading your referral code…'),
          );
        }
        return _buildCard(context, snapshot.data!);
      },
    );
  }

  Widget _buildCard(BuildContext context, String code) {
    final colors = context.colors;

    return GlassCard(
      radius: DesignTokens.radiusLg,
      padding: const EdgeInsets.all(DesignTokens.space4),
      showShadow: true,
      borderColor: colors.primary.withValues(alpha: 0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(DesignTokens.space2),
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  size: DesignTokens.iconMd,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: DesignTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Give ₹50, Get ₹50',
                      style: TokenTextStyles.titleMedium(
                        color: colors.onSurface,
                        weight: DesignTokens.wBold,
                      ),
                    ),
                    Text(
                      'Both sides get credit after my friend’s first delivery.',
                      style: TokenTextStyles.bodySmall(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space3),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.space3,
              vertical: DesignTokens.space2,
            ),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    code,
                    style: TokenTextStyles.titleSmall(
                      color: colors.primary,
                      weight: DesignTokens.wExtraBold,
                      letterSpacing: DesignTokens.lsWide,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _copyCode(context, code),
                  icon: Icon(
                    Icons.copy_rounded,
                    size: DesignTokens.iconSm,
                    color: colors.primary,
                  ),
                  label: Text(
                    'Copy',
                    style: TokenTextStyles.labelLarge(color: colors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.space3),
          Row(
            children: [
              Expanded(
                child: GradientButton(
                  text: 'Share invite',
                  leadingIcon: Icons.share_rounded,
                  height: DesignTokens.buttonHeightMd,
                  onPressed: () => _shareInvite(context, code),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
