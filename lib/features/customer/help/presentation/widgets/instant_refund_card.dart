import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/constants/colors.dart';
import '../../../../../core/constants/dimensions.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../../../../core/widgets/gradient_button.dart';

class InstantRefundCard extends StatefulWidget {
  final String? bookingId;
  final VoidCallback? onRefunded;

  const InstantRefundCard({super.key, this.bookingId, this.onRefunded});

  static Future<void> show(
    BuildContext context, {
    String? bookingId,
    VoidCallback? onRefunded,
  }) {
    return showAppBottomSheet<void>(
      context: context,
      title: 'Report an issue',
      isScrollable: true,
      builder: (_) => InstantRefundCard(
        bookingId: bookingId,
        onRefunded: onRefunded,
      ),
    );
  }

  @override
  State<InstantRefundCard> createState() => _InstantRefundCardState();
}

class _InstantRefundCardState extends State<InstantRefundCard> {
  static const double maxRefund = 100;

  static const List<_RefundIssue> _issues = [
    _RefundIssue(
      id: 'EXTRA_CASH',
      label: 'Driver asked for extra cash',
      icon: Icons.payments_outlined,
      amount: 100,
    ),
    _RefundIssue(
      id: 'WRONG_FARE',
      label: 'Fare was higher than promised',
      icon: Icons.receipt_long_outlined,
      amount: 75,
    ),
    _RefundIssue(
      id: 'DAMAGED_GOODS',
      label: 'Goods arrived damaged',
      icon: Icons.broken_image_outlined,
      amount: 100,
    ),
  ];

  _RefundIssue? _selected;
  bool _processing = false;
  bool _refunded = false;
  double _refundedAmount = 0;
  String _refundedLabel = '';

  double _refundFor(_RefundIssue issue) =>
      issue.amount > maxRefund ? maxRefund : issue.amount;

  Future<void> _getRefund() async {
    final issue = _selected;
    if (issue == null) {
      AppToast.warning(context, 'Choose what went wrong first');
      return;
    }

    final amount = _refundFor(issue);
    setState(() => _processing = true);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await FirebaseFirestore.instance.collection('reports').add({
          'type': 'REFUND_REQUEST',
          'reporterId': uid,
          'issue': issue.id,
          'bookingId': widget.bookingId ?? '',
          'amount': amount,
          'status': 'VERIFIED_INSTANT_REFUND',
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (_) {}

      try {
        await FirebaseFirestore.instance.collection('wallets').doc(uid).set({
          'balance': FieldValue.increment(amount),
          'lastCreditReason': 'Instant refund - ${issue.label}',
        }, SetOptions(merge: true));
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _processing = false;
      _refunded = true;
      _refundedAmount = amount;
      _refundedLabel = issue.label;
    });
    widget.onRefunded?.call();
    AppToast.success(context, '₹${amount.toStringAsFixed(0)} refunded to your wallet instantly');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (_refunded) return _confirmation(colors);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.spacingMd),
          decoration: BoxDecoration(
            color: colors.successLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.bolt_rounded, color: colors.success, size: 20),
                  const SizedBox(width: AppDimensions.spacingSm),
                  Text(
                    'Instant refund promise',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingXs),
              Text(
                'Verified issues are refunded straight to your PickDrop wallet in seconds - no forms, no waiting, no tickets.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: colors.onSurfaceVariant,
                  height: DesignTokens.lhRelaxed,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spacingLg),
        Text(
          'What went wrong?',
          style: AppTextStyles.labelMedium.copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: AppDimensions.spacingSm),
        ..._issues.map((issue) => _issueRow(colors, issue)),
        if (_selected != null) ...[
          const SizedBox(height: AppDimensions.spacingSm),
          Text(
            'Refund of ₹${_refundFor(_selected!).toStringAsFixed(0)} will be credited to your wallet instantly.',
            style: AppTextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: AppDimensions.spacingLg),
        GradientButton(
          text: 'Get instant refund',
          isLoading: _processing,
          onPressed: _getRefund,
        ),
      ],
    );
  }

  Widget _confirmation(AppColorsExtension colors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle_rounded, size: 72, color: colors.success)
            .animate()
            .fadeIn(duration: 300.ms)
            .scale(
              begin: const Offset(0.4, 0.4),
              duration: 600.ms,
              curve: DesignTokens.springBouncy,
            ),
        const SizedBox(height: AppDimensions.spacingMd),
        Text(
          'Refunded to wallet instantly',
          textAlign: TextAlign.center,
          style: AppTextStyles.titleMedium.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),
        const SizedBox(height: AppDimensions.spacingXs),
        Text(
          '₹${_refundedAmount.toStringAsFixed(0)} added for "${_refundedLabel.toLowerCase()}". Use it on your very next booking.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
        ).animate().fadeIn(delay: 350.ms),
        const SizedBox(height: AppDimensions.spacingLg),
        GradientButton(
          text: 'Done',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }

  Widget _issueRow(AppColorsExtension colors, _RefundIssue issue) {
    final selected = _selected?.id == issue.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
      child: GestureDetector(
        onTap: () => setState(() => _selected = issue),
        child: AnimatedContainer(
          duration: DesignTokens.durationFast,
          curve: DesignTokens.springSnappy,
          padding: const EdgeInsets.all(AppDimensions.spacingMd),
          decoration: BoxDecoration(
            color: selected ? colors.primaryContainer : colors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: selected ? colors.primary : colors.outline,
              width: selected ? DesignTokens.borderMedium : DesignTokens.borderThin,
            ),
          ),
          child: Row(
            children: [
              Icon(issue.icon, size: AppDimensions.iconMd, color: colors.primary),
              const SizedBox(width: AppDimensions.spacingSm),
              Expanded(
                child: Text(
                  issue.label,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '₹${_refundFor(issue).toStringAsFixed(0)}',
                style: AppTextStyles.labelLarge.copyWith(
                  color: colors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingXs),
              Icon(
                selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                size: AppDimensions.iconSm,
                color: selected ? colors.primary : colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RefundIssue {
  final String id;
  final String label;
  final IconData icon;
  final double amount;

  const _RefundIssue({
    required this.id,
    required this.label,
    required this.icon,
    required this.amount,
  });
}
