import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../../../config/router/route_names.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/constants/colors.dart';
import '../../../../../core/constants/dimensions.dart';
import '../../../../../core/constants/strings.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../../../../core/widgets/buttons/buttons.dart';
import '../../../../../core/widgets/cards/cards.dart';
import '../../../../../core/widgets/common/common.dart';
import '../../../../../core/widgets/glass_card.dart';
import '../../../../../core/widgets/gradient_button.dart';
import '../../../../../core/widgets/inputs/inputs.dart';
import '../../../../../core/widgets/loaders/loaders.dart';
import '../../../../../core/widgets/status_chip.dart';
import '../../../../../shared/services/razorpay_service.dart';

/// Premium checkout screen with fare summary, promo code, payment method
/// selection and a mocked processing / success flow.
class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  static const double _baseFare = 80.0;
  static const double _distanceFare = 118.0;
  static const double _timeFare = 42.0;
  static const double _surgeCharges = 25.0;

  static const String _flatPromoCode = 'PICKDROP50';
  static const String _percentPromoCode = 'FIRST10';

  static const List<_PaymentOption> _methods = [
    _PaymentOption(
      id: 'upi',
      title: 'UPI',
      subtitle: 'Google Pay, PhonePe, Paytm',
      icon: Icons.qr_code_2_rounded,
    ),
    _PaymentOption(
      id: 'card',
      title: 'Card',
      subtitle: 'Visa, Mastercard, RuPay',
      icon: Icons.credit_card_rounded,
    ),
    _PaymentOption(
      id: 'netbanking',
      title: 'Netbanking',
      subtitle: 'All major Indian banks',
      icon: Icons.account_balance_outlined,
    ),
    _PaymentOption(
      id: 'wallet',
      title: AppStrings.wallet,
      subtitle: 'PickDrop wallet balance ₹500',
      icon: Icons.account_balance_wallet_outlined,
    ),
    _PaymentOption(
      id: 'cod',
      title: AppStrings.payCash,
      subtitle: 'Pay the driver on delivery',
      icon: Icons.payments_outlined,
    ),
  ];

  static const List<_OfferCode> _offers = [
    _OfferCode(
      code: _flatPromoCode,
      description: 'Flat ₹50 off on any booking',
    ),
    _OfferCode(
      code: _percentPromoCode,
      description: '10% off up to ₹100 for first time users',
    ),
  ];

  final TextEditingController _promoController = TextEditingController();
  String _selectedMethodId = 'upi';
  String? _appliedPromo;
  double _discount = 0;
  bool _isApplyingPromo = false;
  bool _isProcessing = false;
  bool _isSuccess = false;

  late final RazorpayService _razorpayService;
  String? _razorpayOrderId;

  double get _subtotal => _baseFare + _distanceFare + _timeFare + _surgeCharges;
  double get _gst => _subtotal * AppConstants.defaultGstPercent / 100;
  double get _total {
    final value = _subtotal + _gst - _discount;
    return value < 0 ? 0 : value;
  }

  _PaymentOption get _selectedMethod => _methods.firstWhere(
    (method) => method.id == _selectedMethodId,
    orElse: () => _methods.first,
  );

  @override
  void initState() {
    super.initState();
    _razorpayService = RazorpayService();
    _razorpayService.setCallbacks(
      onSuccess: _handlePaymentSuccess,
      onError: _handlePaymentError,
      onExternalWallet: _handleExternalWallet,
    );
  }

  @override
  void dispose() {
    _promoController.dispose();
    _razorpayService.dispose();
    super.dispose();
  }

  String _rupees(double value) => '₹${value.toStringAsFixed(0)}';

  Future<void> _applyPromo() async {
    if (_isApplyingPromo) return;
    final code = _promoController.text.trim().toUpperCase();
    if (code.isEmpty) {
      AppToast.info(context, AppStrings.couponCodeHint);
      return;
    }

    setState(() => _isApplyingPromo = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _isApplyingPromo = false);

    if (code == _flatPromoCode) {
      setState(() {
        _discount = 50;
        _appliedPromo = code;
      });
      AppToast.success(context, AppStrings.couponApplied);
    } else if (code == _percentPromoCode) {
      setState(() {
        _discount = (_subtotal * 0.1).clamp(0.0, 100.0).toDouble();
        _appliedPromo = code;
      });
      AppToast.success(context, AppStrings.couponApplied);
    } else {
      AppToast.error(context, AppStrings.invalidCoupon);
    }
  }

  void _removePromo() {
    setState(() {
      _discount = 0;
      _appliedPromo = null;
      _promoController.clear();
    });
    AppToast.info(context, 'Coupon removed');
  }

  Future<void> _openOffersSheet() async {
    final selectedCode = await showAppBottomSheet<String>(
      context: context,
      title: AppStrings.coupons,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final offer in _offers)
            _OfferTile(
              offer: offer,
              onTap: () => Navigator.of(sheetContext).maybePop(offer.code),
            ),
        ],
      ),
    );
    if (selectedCode == null || !mounted) return;
    _promoController.text = selectedCode;
    await _applyPromo();
  }

  Future<void> _createRazorpayOrder() async {
    try {
      // Call the Cloud Function to create a Razorpay order
      // For now, we'll simulate this by generating a local order ID
      // In production, this would call: createRazorpayOrder Cloud Function
      _razorpayOrderId = 'order_${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Failed to create payment order: $e');
      }
    }
  }

  Future<void> _pay() async {
    if (_isProcessing || _isSuccess) return;

    // If COD or Wallet, handle differently
    if (_selectedMethodId == 'cod' || _selectedMethodId == 'wallet') {
      await _handleOfflinePayment();
      return;
    }

    // For online payments (UPI, Card, Netbanking), use Razorpay
    await _createRazorpayOrder();
    if (_razorpayOrderId == null) return;

    setState(() => _isProcessing = true);

    // Get user info for prefill (in real app, get from auth state)
    _razorpayService.openCheckout(
      amount: _total,
      orderId: _razorpayOrderId!,
      description: 'PickDrop booking payment',
      customerName: 'Customer Name',
      customerEmail: 'customer@example.com',
      customerPhone: '+919876543210',
    );
  }

  Future<void> _handleOfflinePayment() async {
    setState(() => _isProcessing = true);
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _isSuccess = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    context.go(RouteNames.customerHome);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    setState(() => _isProcessing = false);

    // Verify payment with server
    _verifyPayment(response);
  }

  Future<void> _verifyPayment(PaymentSuccessResponse response) async {
    try {
      // Call verifyPayment Cloud Function
      // In production, this would call the verifyPayment function
      // For demo, we'll simulate success
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;

      setState(() => _isSuccess = true);

      await Future<void>.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      context.go(RouteNames.customerHome);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, 'Payment verification failed: $e');
      setState(() => _isProcessing = false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isProcessing = false);
    AppToast.error(context, 'Payment failed: ${response.message}');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    AppToast.info(context, 'External wallet: ${response.walletName}');
  }

  void _selectMethod(String methodId) {
    setState(() => _selectedMethodId = methodId);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (_isSuccess) return _buildSuccessView(context);

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colors.surface,
        surfaceTintColor: colors.transparent,
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) context.pop();
          },
          tooltip: AppStrings.back,
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: AppDimensions.iconSm,
            color: colors.onSurface,
          ),
        ),
        title: Text(
          'Payment',
          style: AppTextStyles.headlineSmall.copyWith(color: colors.onSurface),
        ),
      ),
      body: OverlayLoader(
        isLoading: _isProcessing,
        message: AppStrings.pleaseWait,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.spacingLg,
            AppDimensions.spacingSm,
            AppDimensions.spacingLg,
            AppDimensions.spacingXl,
          ),
          children: [
            _buildSummarySection(context),
            const SizedBox(height: AppDimensions.spacingLg),
            _buildPromoSection(context),
            const SizedBox(height: AppDimensions.spacingLg),
            _buildMethodsSection(context),
            const SizedBox(height: AppDimensions.spacingLg),
            _buildSecureNote(context),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildSummarySection(BuildContext context) {
    final colors = context.colors;

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      borderRadius: AppDimensions.radiusLg,
      color: colors.surfaceCard,
      elevation: AppDimensions.elevationSm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long_rounded,
                size: AppDimensions.iconSm,
                color: colors.primary,
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              Text(
                AppStrings.fareBreakdown,
                style: AppTextStyles.headlineSmall.copyWith(
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          _fareRow(context, label: AppStrings.baseFare, amount: _baseFare),
          _fareRow(
            context,
            label: AppStrings.distanceFare,
            amount: _distanceFare,
          ),
          _fareRow(context, label: AppStrings.timeFare, amount: _timeFare),
          _fareRow(
            context,
            label: AppStrings.surgeCharges,
            amount: _surgeCharges,
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          DividerWidget(color: colors.outlineVariant),
          const SizedBox(height: AppDimensions.spacingSm),
          _fareRow(context, label: AppStrings.gst, amount: _gst),
          if (_discount > 0)
            _fareRow(
              context,
              label: AppStrings.discount,
              amount: -_discount,
              isDiscount: true,
            ),
          const SizedBox(height: AppDimensions.spacingMd),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingLg,
              vertical: AppDimensions.spacingMd,
            ),
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.totalPayable,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: colors.onPrimary,
                  ),
                ),
                Text(
                  _rupees(_total),
                  style: AppTextStyles.priceSmall.copyWith(
                    color: colors.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fareRow(
    BuildContext context, {
    required String label,
    required double amount,
    bool isDiscount = false,
  }) {
    final colors = context.colors;
    final display = amount < 0 ? '-${_rupees(amount.abs())}' : _rupees(amount);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingXxs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingSm),
          Text(
            display,
            style: AppTextStyles.titleMedium.copyWith(
              color: isDiscount ? colors.success : colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoSection(BuildContext context) {
    final colors = context.colors;

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      color: colors.surfaceCard,
      elevation: AppDimensions.elevationSm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_offer_outlined,
                    size: AppDimensions.iconSm,
                    color: colors.primary,
                  ),
                  const SizedBox(width: AppDimensions.spacingSm),
                  Text(
                    AppStrings.applyCoupon,
                    style: AppTextStyles.titleLarge.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
              TextButtonWidget(
                text: 'View offers',
                textColor: colors.primary,
                onPressed: _openOffersSheet,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: SizedBox(
                  height: AppDimensions.inputHeightMd,
                  child: CustomTextField(
                    controller: _promoController,
                    hint: AppStrings.couponCodeHint,
                    enabled: !_isApplyingPromo,
                    textCapitalization: TextCapitalization.characters,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spacingMd,
                    ),
                    suffixIcon: Icon(
                      Icons.confirmation_number_outlined,
                      size: AppDimensions.iconSm,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              OutlinedPrimaryButton(
                text: 'Apply',
                isLoading: _isApplyingPromo,
                isFullWidth: false,
                onPressed: _applyPromo,
              ),
            ],
          ),
          if (_appliedPromo != null) ...[
            const SizedBox(height: AppDimensions.spacingMd),
            Row(
              children: [
                StatusChip(
                  label: '$_appliedPromo applied',
                  status: AppChipStatus.success,
                  icon: Icons.check_rounded,
                ),
                const Spacer(),
                TextButtonWidget(
                  text: 'Remove',
                  textColor: colors.error,
                  onPressed: _removePromo,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMethodsSection(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: AppStrings.paymentMethod,
          subtitle: 'Choose how you want to pay',
          showDivider: true,
        ),
        const SizedBox(height: AppDimensions.spacingMd),
        AppCard(
          padding: const EdgeInsets.all(AppDimensions.spacingMd),
          color: colors.surfaceCard,
          elevation: AppDimensions.elevationSm,
          child: Column(
            children: [
              for (var index = 0; index < _methods.length; index++) ...[
                if (index > 0) const SizedBox(height: AppDimensions.spacingSm),
                _buildMethodTile(context, _methods[index], index),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMethodTile(
    BuildContext context,
    _PaymentOption method,
    int index,
  ) {
    final colors = context.colors;
    final isSelected = _selectedMethodId == method.id;

    return Material(
          color: colors.transparent,
          child: InkWell(
            onTap: () => _selectMethod(method.id),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            child: AnimatedContainer(
              duration: AppConstants.mediumAnimation,
              curve: AppConstants.defaultCurve,
              padding: const EdgeInsets.all(AppDimensions.spacingMd),
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.primaryContainer
                    : colors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(
                  color: isSelected ? colors.primary : colors.outline,
                  width: isSelected ? 1.6 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.18),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.spacingSm),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.primary
                          : colors.surfaceElevated,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(AppDimensions.radiusSm),
                      ),
                    ),
                    child: Icon(
                      method.icon,
                      size: AppDimensions.iconSm,
                      color: isSelected
                          ? colors.onPrimary
                          : colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          method.title,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacingXxs),
                        Text(
                          method.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingSm),
                  AnimatedContainer(
                    duration: AppConstants.shortAnimation,
                    curve: AppConstants.defaultCurve,
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? colors.primary : colors.transparent,
                      border: Border.all(
                        color: isSelected ? colors.primary : colors.outline,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        )
        .animate(delay: (index * 60).ms)
        .fadeIn(duration: AppConstants.mediumAnimation)
        .slideX(begin: 0.08, end: 0);
  }

  Widget _buildSecureNote(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingMd,
        vertical: AppDimensions.spacingSm,
      ),
      decoration: BoxDecoration(
        color: colors.successLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: colors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.verified_user_outlined,
            size: AppDimensions.iconSm,
            color: colors.success,
          ),
          const SizedBox(width: AppDimensions.spacingSm),
          Expanded(
            child: Text(
              '100% secure payment • Encrypted end to end',
              style: AppTextStyles.labelMedium.copyWith(color: colors.success),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.spacingLg,
            AppDimensions.spacingMd,
            AppDimensions.spacingLg,
            AppDimensions.spacingSm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.totalPayable,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXxs),
                    Text(
                      _rupees(_total),
                      style: AppTextStyles.priceMedium.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.spacingLg),
              GradientButton(
                text: 'Pay ${_rupees(_total)}',
                trailingIcon: Icons.lock_outline_rounded,
                isLoading: _isProcessing,
                isFullWidth: false,
                onPressed: _pay,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingXl),
            child: GlassCard(
              radius: AppDimensions.radiusXl,
              showShadow: true,
              padding: const EdgeInsets.all(AppDimensions.spacingXxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                        width: 132,
                        height: 132,
                        child: Lottie.asset(
                          'assets/animations/payment_success.json',
                          width: 132,
                          height: 132,
                          repeat: false,
                          fit: BoxFit.contain,
                          frameRate: FrameRate.max,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: AppConstants.mediumAnimation)
                      .scale(
                        begin: const Offset(0.5, 0.5),
                        end: const Offset(1, 1),
                        duration: AppConstants.dramaticAnimation,
                        curve: Curves.elasticOut,
                      ),
                  const SizedBox(height: AppDimensions.spacingXl),
                  Text(
                    AppStrings.paymentSuccessful,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingSm),
                  Text(
                    '${_rupees(_total)} paid via ${_selectedMethod.title}',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingLg),
                  const StatusChip(
                    label: 'PAID',
                    status: AppChipStatus.success,
                  ),
                  const SizedBox(height: AppDimensions.spacingXl),
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: Lottie.asset(
                      'assets/animations/loading.json',
                      width: 56,
                      height: 56,
                      repeat: true,
                      fit: BoxFit.contain,
                      frameRate: FrameRate.max,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingMd),
                  Text(
                    'Taking you home...',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentOption {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;

  const _PaymentOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _OfferCode {
  final String code;
  final String description;

  const _OfferCode({required this.code, required this.description});
}

class _OfferTile extends StatelessWidget {
  final _OfferCode offer;
  final VoidCallback onTap;

  const _OfferTile({required this.offer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
          padding: const EdgeInsets.all(AppDimensions.spacingMd),
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(color: colors.outline),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingSm,
                  vertical: AppDimensions.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(AppDimensions.radiusXs),
                  ),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  offer.code,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: colors.primary,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Expanded(
                child: Text(
                  offer.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              Icon(
                Icons.north_east_rounded,
                size: AppDimensions.iconSm,
                color: colors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
