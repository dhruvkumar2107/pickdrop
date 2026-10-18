import 'package:flutter/material.dart';
import '../../../../../../core/constants/colors.dart';
import '../../../../../../core/constants/dimensions.dart';
import '../../../../../../core/theme/text_styles.dart';
import '../../../../../../core/widgets/app_toast.dart';
import '../../../../../../core/widgets/gradient_button.dart';

class ProofOfDeliverySheet extends StatefulWidget {
  final String bookingId;
  final bool isPickup;
  final VoidCallback onProofCompleted;

  const ProofOfDeliverySheet({
    super.key,
    required this.bookingId,
    required this.isPickup,
    required this.onProofCompleted,
  });

  static Future<void> show(
    BuildContext context, {
    required String bookingId,
    required bool isPickup,
    required VoidCallback onProofCompleted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProofOfDeliverySheet(
        bookingId: bookingId,
        isPickup: isPickup,
        onProofCompleted: onProofCompleted,
      ),
    );
  }

  @override
  State<ProofOfDeliverySheet> createState() => _ProofOfDeliverySheetState();
}

class _ProofOfDeliverySheetState extends State<ProofOfDeliverySheet> {
  bool _photoCaptured = false;
  final _receiverNameController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _receiverNameController.dispose();
    super.dispose();
  }

  void _simulateCapturePhoto() {
    setState(() => _photoCaptured = true);
    AppToast.success(context, 'Goods photo captured with GPS watermark');
  }

  void _submitProof() {
    if (!_photoCaptured) {
      AppToast.warning(context, 'Please capture goods photo first');
      return;
    }

    setState(() => _isSubmitting = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      Navigator.of(context).pop();
      widget.onProofCompleted();
      AppToast.success(
        context,
        widget.isPickup ? 'Pickup proof verified successfully' : 'Delivery proof & digital receipt recorded!',
      );
    });
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
                  color: colors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.isPickup ? Icons.camera_alt_outlined : Icons.verified_outlined,
                  color: colors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isPickup ? 'Mandatory Pickup Goods Photo' : 'Proof of Delivery (POD)',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      widget.isPickup
                          ? 'Capture loaded goods in truck bed to guarantee condition'
                          : 'Photo + receiver acknowledgment for dispute-free delivery',
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
          GestureDetector(
            onTap: _simulateCapturePhoto,
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _photoCaptured ? colors.successLight : colors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(
                  color: _photoCaptured ? colors.success : colors.outline,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _photoCaptured ? Icons.check_circle_rounded : Icons.add_a_photo_rounded,
                      size: 36,
                      color: _photoCaptured ? colors.success : colors.primary,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _photoCaptured ? 'Photo Attached (GPS & Timestamped)' : 'Tap to Take Goods Photo',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: _photoCaptured ? colors.success : colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!widget.isPickup) ...[
            const SizedBox(height: AppDimensions.spacingMd),
            Text(
              'Receiver Name / Signature',
              style: AppTextStyles.labelMedium.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: AppDimensions.spacingXs),
            TextField(
              controller: _receiverNameController,
              decoration: InputDecoration(
                hintText: 'e.g. Ramesh (Warehouse Manager)',
                filled: true,
                fillColor: colors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppDimensions.spacingXl),
          GradientButton(
            text: widget.isPickup ? 'Confirm Pickup Photo' : 'Complete Delivery with POD',
            isLoading: _isSubmitting,
            onPressed: _submitProof,
          ),
        ],
      ),
    );
  }
}
