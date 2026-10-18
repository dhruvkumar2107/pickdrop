import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/colors.dart';
import '../../../../../core/constants/dimensions.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../../../../core/widgets/gradient_button.dart';
import '../../../../../../features/customer/coupons/data/datasources/coupons_remote_datasource.dart';

class CouponsPage extends ConsumerStatefulWidget {
  const CouponsPage({super.key});

  @override
  ConsumerState<CouponsPage> createState() => _CouponsPageState();
}

class _CouponsPageState extends ConsumerState<CouponsPage> {
  final TextEditingController _codeController = TextEditingController();
  String? _appliedCouponId;
  List<Coupon> _coupons = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  Future<void> _loadCoupons() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final coupons = await ref.read(couponsRemoteDataSourceProvider).getAvailableCoupons();
      if (mounted) {
        setState(() {
          _coupons = coupons;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load coupons: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _applyCouponCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      AppToast.info(context, 'Enter a coupon code');
      return;
    }

    // For demo, we'll just check against loaded coupons
    final coupon = _coupons.firstWhere(
      (c) => c.code == code,
      orElse: () => Coupon(
        id: '',
        code: '',
        type: '',
        value: 0,
        minOrderValue: 0,
        usageLimit: 0,
        usedCount: 0,
        validFrom: DateTime.now(),
        validUntil: DateTime.now(),
        isActive: false,
      ),
    );

    if (coupon.id.isEmpty || !coupon.isActive) {
      AppToast.error(context, 'Invalid or expired coupon');
      return;
    }

    if (coupon.usedCount >= coupon.usageLimit) {
      AppToast.error(context, 'Coupon usage limit reached');
      return;
    }

    final now = DateTime.now();
    if (now.isBefore(coupon.validFrom) || now.isAfter(coupon.validUntil)) {
      AppToast.error(context, 'Coupon has expired');
      return;
    }

    setState(() => _appliedCouponId = coupon.id);
    AppToast.success(context, 'Coupon ${coupon.code} applied!');
    FocusScope.of(context).unfocus();
  }

  void _removeAppliedCoupon() {
    setState(() => _appliedCouponId = null);
    _codeController.clear();
    AppToast.info(context, 'Coupon removed');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surfaceCard,
        elevation: 0,
        title: Text('Coupons & Offers', style: AppTextStyles.headlineSmall),
        iconTheme: IconThemeData(color: colors.onSurface),
      ),
      body: Column(
        children: [
          // Code entry row
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingXl),
            color: colors.surfaceCard,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      hintText: 'Enter coupon code',
                      hintStyle: AppTextStyles.bodyMedium
                          .copyWith(color: colors.onSurfaceVariant),
                      filled: true,
                      fillColor: colors.surfaceVariant,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusSm),
                        borderSide: BorderSide(color: colors.outline),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusSm),
                        borderSide: BorderSide(color: colors.outline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusSm),
                        borderSide: BorderSide(color: colors.primary, width: 2),
                      ),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
                const SizedBox(width: 12),
                GradientButton(
                  text: 'Apply',
                  onPressed: _applyCouponCode,
                  leadingIcon: Icons.check_rounded,
                  isFullWidth: false,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Applied coupon banner
          if (_appliedCouponId != null) ...[
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacingMd),
              margin: const EdgeInsets.all(AppDimensions.spacingMd),
              decoration: BoxDecoration(
                color: colors.successLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: colors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: colors.success),
                  const SizedBox(width: AppDimensions.spacingMd),
                  Expanded(
                    child: Text(
                      'Coupon applied successfully!',
                      style: AppTextStyles.bodyMedium.copyWith(color: colors.success),
                    ),
                  ),
                  TextButton(
                    onPressed: _removeAppliedCoupon,
                    child: Text('Remove', style: AppTextStyles.labelLarge.copyWith(color: colors.error)),
                  ),
                ],
              ),
            ),
          ],

          // Coupon list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: colors.error),
                            const SizedBox(height: AppDimensions.spacingMd),
                            Text(_error!, style: AppTextStyles.bodyMedium),
                            const SizedBox(height: AppDimensions.spacingMd),
                            GradientButton(
                              text: 'Retry',
                              onPressed: _loadCoupons,
                              leadingIcon: Icons.refresh,
                            ),
                          ],
                        ),
                      )
                    : _coupons.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.local_offer_outlined, size: 64, color: colors.onSurfaceVariant),
                                const SizedBox(height: AppDimensions.spacingMd),
                                Text('No coupons available',
                                    style: AppTextStyles.headlineSmall.copyWith(color: colors.onSurfaceVariant)),
                                const SizedBox(height: AppDimensions.spacingSm),
                                Text('Check back later for new offers',
                                    style: AppTextStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(AppDimensions.spacingXl),
                            itemCount: _coupons.length,
                            itemBuilder: (_, i) {
                              final c = _coupons[i];
                              final isApplied = _appliedCouponId == c.id;
                              return _CouponCard(
                                coupon: c,
                                isApplied: isApplied,
                                onApply: () => _applyCouponCode(),
                              ).animate(delay: Duration(milliseconds: i * 80)).fadeIn().slideY(begin: 0.1, end: 0);
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

// Provider for the coupons data source
final couponsRemoteDataSourceProvider = Provider<CouponsRemoteDataSource>((ref) {
  return CouponsRemoteDataSource();
});

class _CouponCard extends StatelessWidget {
  final Coupon coupon;
  final bool isApplied;
  final VoidCallback onApply;

  const _CouponCard({
    required this.coupon,
    required this.isApplied,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final discountText = coupon.type == 'percentage'
        ? '${coupon.value.toInt()}%'
        : '₹${coupon.value.toInt()}';

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingLg),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isApplied ? colors.primary : colors.outline,
          width: isApplied ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isApplied
                ? colors.primary.withValues(alpha: 0.1)
                : colors.shadow.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingLg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Discount badge
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: Center(
                    child: Text(
                      discountText,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: discountText.length > 3 ? 12 : 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(coupon.code, style: AppTextStyles.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        '${coupon.type == 'percentage' ? coupon.value.toInt() : ''} off on orders above ₹${coupon.minOrderValue.toInt()}',
                        style: AppTextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Valid till ${_formatDate(coupon.validUntil)}',
                        style: AppTextStyles.labelSmall.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Dashed divider
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingLg,
                vertical: AppDimensions.spacingMd),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    border: Border.all(color: colors.outline, style: BorderStyle.solid),
                  ),
                  child: Text(
                    coupon.code,
                    style: AppTextStyles.labelMedium.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: isApplied ? null : onApply,
                  style: TextButton.styleFrom(
                    foregroundColor: isApplied ? colors.success : colors.primary,
                  ),
                  child: Text(
                    isApplied ? '✓ Applied' : 'Apply',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: isApplied ? colors.success : colors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
