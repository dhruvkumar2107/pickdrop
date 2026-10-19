import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../../../../../core/constants/colors.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../../../../core/widgets/gradient_button.dart';
import '../../../../../core/widgets/inputs/inputs.dart';
import '../../../../../core/widgets/status_chip.dart';
import '../../../../../config/env/env_config.dart';
import '../widgets/payout_history_list.dart';

class DriverPayoutsPage extends StatefulWidget {
  const DriverPayoutsPage({super.key});

  @override
  State<DriverPayoutsPage> createState() => _DriverPayoutsPageState();
}

class _DriverPayoutsPageState extends State<DriverPayoutsPage> {
  static const double minPayout = 100;

  static const double fallbackBalance = 0;

  final TextEditingController _upiController = TextEditingController();

  final TextEditingController _amountController = TextEditingController();

  Stream<QuerySnapshot<Map<String, dynamic>>>? _history;

  bool _submitting = false;

  double _balance = fallbackBalance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  double get _amount => double.tryParse(_amountController.text.trim()) ?? 0;

  bool get _canWithdraw =>
      !_submitting &&
      _upiController.text.trim().contains('@') &&
      _amount >= minPayout &&
      _amount <= _balance;

  @override
  void initState() {
    super.initState();
    _amountController.text = fallbackBalance.toStringAsFixed(0);
    final uid = _uid;
    if (uid != null) {
      _history = FirebaseFirestore.instance
          .collection('driverPayouts')
          .where('driverId', isEqualTo: uid)
          .snapshots();
    }
    _loadBalance();
  }

  @override
  void dispose() {
    _upiController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadBalance() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(uid)
          .get();
      final value = (snapshot.data()?['availableBalance'] as num?)?.toDouble();
      if (!mounted || value == null) return;
      setState(() {
        _balance = value;
        _amountController.text = value.toStringAsFixed(0);
      });
    } catch (_) {
      _balance = fallbackBalance;
    }
  }

  Future<void> _submit() async {
    final uid = _uid;
    if (uid == null || !_canWithdraw) return;
    setState(() => _submitting = true);
    final amount = _amount;
    final upi = _upiController.text.trim();
    try {
      final result = await FirebaseFunctions.instanceFor(region: EnvConfig.functionsRegion)
          .httpsCallable('requestPayout')
          .call<Map<String, dynamic>>({'amount': amount, 'upiId': upi});
      if (result.data['status'] != 'PENDING_REVIEW') {
        throw StateError('The payout request was not accepted for review.');
      }
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _balance = (_balance - amount).clamp(0, double.infinity).toDouble();
        _amountController.text = _balance.toStringAsFixed(0);
        _upiController.clear();
      });
      AppToast.success(
        context,
        'Payout request for ₹${amount.toStringAsFixed(0)} submitted for review. It has not been transferred yet.',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      AppToast.error(
        context,
        'Could not place the payout request. Check your connection and try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.surface,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildWithdrawCard(colors)),
          SliverToBoxAdapter(child: _buildHistory(colors)),
          const SliverToBoxAdapter(child: SizedBox(height: 48)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        DesignTokens.spacingXl,
        MediaQuery.of(context).padding.top + DesignTokens.spacingLg,
        DesignTokens.spacingXl,
        DesignTokens.spacingXxl,
      ),
      decoration: const BoxDecoration(gradient: AppColors.driverGradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const BackButton(color: DesignTokens.ivory50),
              const SizedBox(width: DesignTokens.spacingXs),
              Text(
                'Payouts',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: DesignTokens.ivory50,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingXs),
          Text(
            'Request a payout to your UPI ID. Requests remain pending until an operator completes the transfer.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              height: 1.4,
              color: DesignTokens.ivory50.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawCard(AppColorsExtension colors) {
    final belowMinimum = _amount > 0 && _amount < minPayout;
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.spacingXl),
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.spacingLg),
        decoration: BoxDecoration(
          color: colors.surfaceCard,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          border: Border.all(color: colors.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available balance',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '₹${_balance.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const StatusChip(
                  label: 'Manual review',
                  status: AppChipStatus.warning,
                  dense: true,
                ),
              ],
            ),
            Divider(height: DesignTokens.spacingXl, color: colors.outlineVariant),
            CustomTextField(
              controller: _amountController,
              label: 'Amount (min ₹${minPayout.toStringAsFixed(0)})',
              hint: 'e.g. 640',
              keyboardType: TextInputType.number,
              prefixIcon: Icon(Icons.currency_rupee, size: DesignTokens.iconMd),
              errorText: belowMinimum ? 'Minimum payout is ₹100' : null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: DesignTokens.spacingMd),
            CustomTextField(
              controller: _upiController,
              label: 'UPI ID',
              hint: 'yourname@upi',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icon(Icons.alternate_email, size: DesignTokens.iconMd),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: DesignTokens.spacingLg),
            GradientButton(
              text: 'Withdraw instantly',
              leadingIcon: Icons.bolt_rounded,
              gradient: AppColors.driverGradient,
              isLoading: _submitting,
              onPressed: _canWithdraw ? _submit : null,
            ),
            const SizedBox(height: DesignTokens.spacingSm),
            Text(
              'Minimum request is ₹100. Submitting a request does not transfer funds; support must review and complete it.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                height: 1.4,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistory(AppColorsExtension colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.spacingXl,
        0,
        DesignTokens.spacingXl,
        DesignTokens.spacingXl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payout history',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingSm),
          PayoutHistoryList(stream: _history),
        ],
      ),
    );
  }
}
