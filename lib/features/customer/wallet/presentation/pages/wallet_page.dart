import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../config/router/route_names.dart';
import '../../../../../../core/constants/app_constants.dart';
import '../../../../../../core/constants/colors.dart';
import '../../../../../../core/constants/dimensions.dart';
import '../../../../../../core/constants/strings.dart';
import '../../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../../../core/widgets/app_toast.dart';
import '../../../../../../core/widgets/buttons/buttons.dart';
import '../../../../../../core/widgets/common/common.dart';
import '../../../../../../core/widgets/glass_card.dart';
import '../../../../../../core/widgets/gradient_button.dart';
import '../../../../../../shared/services/razorpay_service.dart';
import '../../../home/presentation/widgets/referral_banner.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  double _balance = 0;
  bool _isBalanceVisible = true;

  static const List<int> _quickAmounts = [100, 200, 500, 1000, 2000, 5000];

  final List<_WalletTransaction> _transactions = [];
  late final RazorpayService _razorpayService;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _walletSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _transactionsSubscription;
  String? _pendingOrderId;
  bool _topupInProgress = false;

  String _formatDate(DateTime date) {
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '${date.day}/${date.month}/${date.year} • $hh:$mm';
  }

  @override
  void initState() {
    super.initState();
    _razorpayService = RazorpayService();
    _razorpayService.setCallbacks(
      onSuccess: _onTopupSuccess,
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _topupInProgress = false;
          _pendingOrderId = null;
        });
        AppToast.error(context, 'Wallet payment was cancelled or failed.');
      },
    );
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _walletSubscription = FirebaseFirestore.instance
          .collection('wallets')
          .doc(uid)
          .snapshots()
          .listen((snapshot) {
            if (mounted) {
              setState(
                () => _balance =
                    (snapshot.data()?['balance'] as num?)?.toDouble() ?? 0,
              );
            }
          });
      _transactionsSubscription = FirebaseFirestore.instance
          .collection('walletTransactions')
          .where('userId', isEqualTo: uid)
          .snapshots()
          .listen((snapshot) {
            if (!mounted) return;
            final items = snapshot.docs.map((doc) {
              final data = doc.data();
              final credit =
                  data['type'] == 'TOPUP' || data['type'] == 'CREDIT';
              final created = data['createdAt'];
              return _WalletTransaction(
                title: credit ? 'Wallet top-up' : 'Wallet activity',
                subtitle: (data['status'] ?? '').toString(),
                amount: (data['amount'] as num? ?? 0).toDouble(),
                isCredit: credit,
                dateTime: created is Timestamp
                    ? created.toDate()
                    : DateTime.now(),
                icon: credit ? Icons.add_circle_outline : Icons.receipt_long,
              );
            }).toList()..sort((a, b) => b.dateTime.compareTo(a.dateTime));
            setState(() {
              _transactions
                ..clear()
                ..addAll(items);
            });
          });
    }
  }

  @override
  void dispose() {
    _walletSubscription?.cancel();
    _transactionsSubscription?.cancel();
    _razorpayService.dispose();
    super.dispose();
  }

  void _toggleBalanceVisibility() {
    setState(() => _isBalanceVisible = !_isBalanceVisible);
  }

  void _openAddMoneySheet() {
    _openQuickAmountSheet(
      title: AppStrings.addMoney,
      confirmLabel: AppStrings.addMoney,
      isAddMoney: true,
    );
  }

  void _openRechargeSheet() {
    _openQuickAmountSheet(
      title: AppStrings.recharge,
      confirmLabel: AppStrings.recharge,
      isAddMoney: false,
    );
  }

  void _openQuickAmountSheet({
    required String title,
    required String confirmLabel,
    required bool isAddMoney,
  }) {
    if (!mounted) return;
    showAppBottomSheet<void>(
      context: context,
      title: title,
      builder: (_) => _QuickAmountSheet(
        confirmLabel: confirmLabel,
        quickAmounts: _quickAmounts,
        isAddMoney: isAddMoney,
        onAmountSelected: (amount) {
          Navigator.of(context).pop();
          _initiatePayment(amount);
        },
      ),
    );
  }

  Future<void> _initiatePayment(int amount) async {
    if (_topupInProgress) return;
    setState(() => _topupInProgress = true);
    try {
      final order = await _razorpayService.createWalletOrder(amount);
      _pendingOrderId = order['orderId'] as String;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw StateError('Sign in to add money.');
      await _razorpayService.openCheckout(
        amount: amount.toDouble(),
        orderId: _pendingOrderId!,
        description: 'PickDrop wallet top-up',
        customerName: user.displayName ?? '',
        customerEmail: user.email ?? '',
        customerPhone: user.phoneNumber ?? '',
      );
    } catch (e) {
      if (mounted) {
        AppToast.error(
          context,
          'Could not start wallet top-up. ${e is StateError ? e.message : ''}',
        );
      }
      if (mounted) setState(() => _topupInProgress = false);
    }
  }

  Future<void> _onTopupSuccess(PaymentSuccessResponse response) async {
    final orderId = _pendingOrderId;
    if (orderId == null ||
        response.paymentId == null ||
        response.signature == null) {
      return;
    }
    final paid = await _razorpayService.verifyWalletPayment(
      orderId: orderId,
      paymentId: response.paymentId!,
      signature: response.signature!,
    );
    if (!mounted) return;
    setState(() {
      _topupInProgress = false;
      _pendingOrderId = null;
    });
    if (paid) {
      AppToast.success(context, 'Wallet top-up received.');
    } else {
      AppToast.error(
        context,
        'Payment could not be verified. Contact support with your payment ID.',
      );
    }
  }

  void _openCoupons() {
    if (!mounted) return;
    context.go(RouteNames.coupons);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.surface,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHero(context, colors)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spacingLg,
                AppDimensions.spacingLg,
                AppDimensions.spacingLg,
                0,
              ),
              child: const ReferralBanner(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spacingLg,
                AppDimensions.spacingLg,
                AppDimensions.spacingLg,
                0,
              ),
              child: _buildCouponsShortcut(context, colors),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spacingLg,
                AppDimensions.spacingXl,
                AppDimensions.spacingLg,
                AppDimensions.spacingMd,
              ),
              child: SectionHeader(title: AppStrings.transactionHistory),
            ),
          ),
          if (_transactions.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                title: 'No transactions yet',
                message: 'Add money or book a trip to see activity here',
                lottieAsset: 'assets/animations/empty_wallet.json',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spacingLg,
                0,
                AppDimensions.spacingLg,
                AppDimensions.spacingXxl,
              ),
              sliver: SliverList.separated(
                itemCount: _transactions.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppDimensions.spacingSm),
                itemBuilder: (context, index) {
                  final transaction = _transactions[index];
                  return _TransactionTile(
                        transaction: transaction,
                        formattedDate: _formatDate(transaction.dateTime),
                      )
                      .animate()
                      .fadeIn(duration: AppConstants.mediumAnimation)
                      .slideX(
                        begin: transaction.isCredit ? 0.06 : -0.06,
                        end: 0,
                        duration: AppConstants.mediumAnimation,
                        delay: Duration(milliseconds: 40 * index),
                      );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context, AppColorsExtension colors) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppDimensions.spacingLg,
        MediaQuery.of(context).padding.top + AppDimensions.spacingLg,
        AppDimensions.spacingLg,
        AppDimensions.spacingXl,
      ),
      decoration: const BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButtonWidget(
                icon: Icons.arrow_back_rounded,
                color: colors.onPrimary,
                onPressed: () {
                  if (!mounted) return;
                  context.pop();
                },
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              Expanded(
                child: Text(
                  AppStrings.wallet,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          GlassCard(
            radius: AppDimensions.radiusLg,
            color: Colors.white.withValues(alpha: 0.16),
            borderColor: Colors.white.withValues(alpha: 0.28),
            showShadow: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppStrings.walletBalance,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _toggleBalanceVisibility,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.all(AppDimensions.spacingSm),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusSm,
                          ),
                        ),
                        child: Icon(
                          _isBalanceVisible
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          size: AppDimensions.iconSm,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingSm),
                Text(
                  _isBalanceVisible
                      ? '₹${_balance.toStringAsFixed(2)}'
                      : '₹ • • • • • •',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingLg),
                Row(
                  children: [
                    Expanded(
                      child: GradientButton(
                        text: AppStrings.addMoney,
                        leadingIcon: Icons.add_rounded,
                        height: AppDimensions.buttonHeightMd,
                        borderRadius: AppDimensions.radiusMd,
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.95),
                            Colors.white.withValues(alpha: 0.8),
                          ],
                        ),
                        foregroundColor: colors.primaryDark,
                        onPressed: _openAddMoneySheet,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingMd),
                    Expanded(
                      child: OutlinedPrimaryButton(
                        text: AppStrings.recharge,
                        leadingIcon: Icons.refresh_rounded,
                        height: AppDimensions.buttonHeightMd,
                        borderRadius: AppDimensions.radiusMd,
                        borderColor: Colors.white.withValues(alpha: 0.7),
                        textColor: Colors.white,
                        onPressed: _openRechargeSheet,
                      ),
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

  Widget _buildCouponsShortcut(
    BuildContext context,
    AppColorsExtension colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: colors.primary.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: colors.transparent,
        child: InkWell(
          onTap: _openCoupons,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingMd),
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_offer_rounded,
                  color: Colors.white,
                  size: AppDimensions.iconMd,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.myCoupons,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Save more on your next trip',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.onSurfaceVariant,
                size: AppDimensions.iconMd,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletTransaction {
  const _WalletTransaction({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isCredit,
    required this.dateTime,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final double amount;
  final bool isCredit;
  final DateTime dateTime;
  final IconData icon;
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.transaction,
    required this.formattedDate,
  });

  final _WalletTransaction transaction;
  final String formattedDate;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final amountColor = transaction.isCredit ? colors.success : colors.error;
    final amountBg = transaction.isCredit
        ? colors.successLight
        : colors.errorLight;
    final sign = transaction.isCredit ? '+' : '−';

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: AppDimensions.avatarMd,
            height: AppDimensions.avatarMd,
            decoration: BoxDecoration(
              color: amountBg,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Icon(
              transaction.icon,
              color: amountColor,
              size: AppDimensions.iconMd,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  transaction.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spacingSm),
          Text(
            '$sign₹${transaction.amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAmountSheet extends StatefulWidget {
  const _QuickAmountSheet({
    required this.confirmLabel,
    required this.quickAmounts,
    required this.isAddMoney,
    required this.onAmountSelected,
  });

  final String confirmLabel;
  final List<int> quickAmounts;
  final bool isAddMoney;
  final ValueChanged<int> onAmountSelected;

  @override
  State<_QuickAmountSheet> createState() => _QuickAmountSheetState();
}

class _QuickAmountSheetState extends State<_QuickAmountSheet> {
  int? _selectedAmount;

  void _selectAmount(int amount) {
    setState(() => _selectedAmount = amount);
  }

  void _confirm() {
    final amount = _selectedAmount;
    if (amount == null) return;
    widget.onAmountSelected(amount);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose an amount',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingMd),
        Wrap(
          spacing: AppDimensions.spacingSm,
          runSpacing: AppDimensions.spacingSm,
          children: widget.quickAmounts.map((amount) {
            final isSelected = _selectedAmount == amount;
            return GestureDetector(
              onTap: () => _selectAmount(amount),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: AppConstants.shortAnimation,
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingLg,
                  vertical: AppDimensions.spacingMd,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.brandGradient : null,
                  color: isSelected ? null : colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(
                    color: isSelected ? colors.primary : colors.outline,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: colors.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  '₹$amount',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? colors.onPrimary : colors.onSurface,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppDimensions.spacingXl),
        GradientButton(
          text: widget.confirmLabel,
          onPressed: _selectedAmount == null ? null : _confirm,
          leadingIcon: Icons.check_rounded,
        ),
        const SizedBox(height: AppDimensions.spacingSm),
        Text(
          'You will be redirected to complete payment securely',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingMd),
      ],
    );
  }
}
