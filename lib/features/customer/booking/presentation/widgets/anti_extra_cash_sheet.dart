import 'package:flutter/material.dart';
import '../../../../../../core/constants/colors.dart';
import '../../../../../../core/constants/dimensions.dart';
import '../../../../../../core/theme/text_styles.dart';
import '../../../../../../core/widgets/app_toast.dart';
import '../../../../../../core/widgets/gradient_button.dart';
import '../../data/datasources/price_lock_remote_datasource.dart';

class AntiExtraCashSheet extends StatefulWidget {
  final String bookingId;
  final String driverName;

  const AntiExtraCashSheet({
    super.key,
    required this.bookingId,
    required this.driverName,
  });

  static Future<void> show(BuildContext context, {
    required String bookingId,
    required String driverName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AntiExtraCashSheet(
        bookingId: bookingId,
        driverName: driverName,
      ),
    );
  }

  @override
  State<AntiExtraCashSheet> createState() => _AntiExtraCashSheetState();
}

class _AntiExtraCashSheetState extends State<AntiExtraCashSheet> {
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      AppToast.warning(context, 'Please enter the extra amount requested');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final ds = PriceLockRemoteDataSource();
      await ds.reportExtraCashRequested(
        bookingId: widget.bookingId,
        driverId: 'driver_active',
        extraCashAmount: amount,
        reason: _reasonController.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      AppToast.success(
        context,
        'Report registered. ₹${amount.toStringAsFixed(0)} auto-refunded to wallet guarantee.',
      );
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Could not file report: $e');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.spacingXl,
        AppDimensions.spacingLg,
        AppDimensions.spacingXl,
        AppDimensions.spacingXl + bottomInset,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.outline,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingSm),
                decoration: BoxDecoration(
                  color: colors.errorLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.shield_outlined, color: colors.error, size: 22),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Anti-Extra-Cash Guarantee',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      'Drivers are never allowed to demand cash beyond the Price Lock',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colors.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          Text(
            'How much extra cash did the driver demand?',
            style: AppTextStyles.labelMedium.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: AppDimensions.spacingXs),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              prefixText: '₹ ',
              hintText: 'e.g. 100',
              filled: true,
              fillColor: colors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Text(
            'Reason given by driver (optional)',
            style: AppTextStyles.labelMedium.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: AppDimensions.spacingXs),
          TextField(
            controller: _reasonController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'e.g. Asked for toll / fuel / unloading surcharge',
              filled: true,
              fillColor: colors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          GradientButton(
            text: 'Submit & Request Wallet Refund',
            isLoading: _isSubmitting,
            onPressed: _submitReport,
          ),
        ],
      ),
    );
  }
}
