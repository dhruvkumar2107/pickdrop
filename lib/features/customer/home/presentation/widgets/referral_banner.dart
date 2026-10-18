import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../core/constants/colors.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/utils/helpers.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../../../../core/widgets/glass_card.dart';
import '../../../../../core/widgets/gradient_button.dart';

class ReferralBanner extends StatelessWidget {
  final String phoneNumber;

  const ReferralBanner({
    super.key,
    this.phoneNumber = '+919876543210',
  });

  String get _referralCode {
    final digits = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final source = digits.length >= 6 ? phoneNumber : '+919876543210';
    return AppHelpers.generateReferralCode(source);
  }

  Future<void> _copyCode(BuildContext context) async {
    final code = _referralCode;
    AppHelpers.copyToClipboard(code);
    if (!context.mounted) return;
    AppToast.success(context, 'Referral code copied: $code');
  }

  Future<void> _shareInvite(BuildContext context) async {
    final code = _referralCode;
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: 'Use my PickDrop referral code $code and we both get ₹50. '
              'You get ₹50 off your first delivery, and ₹50 lands in my wallet. '
              'Download PickDrop and add the code at checkout.',
          subject: 'PickDrop referral code $code',
        ),
      );
    } catch (_) {}
    if (!context.mounted) return;
    AppToast.success(context, 'Your invite is ready to share');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final code = _referralCode;

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
                  onPressed: () => _copyCode(context),
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
                  onPressed: () => _shareInvite(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
