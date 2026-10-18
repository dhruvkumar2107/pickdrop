import 'package:flutter/material.dart';
import '../../../../../../core/constants/colors.dart';
import '../../../../../../core/constants/dimensions.dart';
import '../../../../../../core/theme/text_styles.dart';
import '../../../../../../core/widgets/app_toast.dart';
import '../../../../../../core/widgets/gradient_button.dart';
import '../../data/datasources/price_lock_remote_datasource.dart';

class OfferYourPriceSheet extends StatefulWidget {
  final String bookingId;
  final double currentEstimatedFare;
  final double minimumFloorFare;
  final ValueChanged<double> onOfferAccepted;

  const OfferYourPriceSheet({
    super.key,
    required this.bookingId,
    required this.currentEstimatedFare,
    required this.minimumFloorFare,
    required this.onOfferAccepted,
  });

  static Future<void> show(
    BuildContext context, {
    required String bookingId,
    required double currentEstimatedFare,
    required double minimumFloorFare,
    required ValueChanged<double> onOfferAccepted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OfferYourPriceSheet(
        bookingId: bookingId,
        currentEstimatedFare: currentEstimatedFare,
        minimumFloorFare: minimumFloorFare,
        onOfferAccepted: onOfferAccepted,
      ),
    );
  }

  @override
  State<OfferYourPriceSheet> createState() => _OfferYourPriceSheetState();
}

class _OfferYourPriceSheetState extends State<OfferYourPriceSheet> {
  late double _proposedFare;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Default suggestion is 10% below current fare, bounded by floor
    _proposedFare = (widget.currentEstimatedFare * 0.9).clamp(
      widget.minimumFloorFare,
      widget.currentEstimatedFare * 2,
    );
  }

  void _adjustFare(double delta) {
    setState(() {
      final updated = _proposedFare + delta;
      if (updated >= widget.minimumFloorFare) {
        _proposedFare = updated;
      } else {
        AppToast.warning(
          context,
          'Minimum floor fare for driver is ₹${widget.minimumFloorFare.toStringAsFixed(0)}',
        );
      }
    });
  }

  Future<void> _submitOffer() async {
    setState(() => _isSubmitting = true);
    try {
      final ds = PriceLockRemoteDataSource();
      await ds.submitCustomFareOffer(
        bookingId: widget.bookingId,
        proposedFare: _proposedFare,
        minimumFloorFare: widget.minimumFloorFare,
      );

      if (!mounted) return;
      widget.onOfferAccepted(_proposedFare);
      Navigator.of(context).pop();
      AppToast.success(
        context,
        'Offer of ₹${_proposedFare.toStringAsFixed(0)} sent to nearby drivers!',
      );
    } catch (e) {
      if (mounted) {
        AppToast.error(context, e.toString());
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
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.outline,
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
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
                child: Icon(Icons.handshake_outlined, color: colors.primary, size: 22),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Offer Your Price Mode',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      'Name your own fare — nearby drivers can accept or counter',
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
          const SizedBox(height: AppDimensions.spacingXl),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingXl,
              vertical: AppDimensions.spacingLg,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => _adjustFare(-20),
                  icon: const Icon(Icons.remove_circle_outline_rounded, size: 36),
                  color: colors.primary,
                ),
                Column(
                  children: [
                    Text(
                      '₹${_proposedFare.toStringAsFixed(0)}',
                      style: AppTextStyles.priceLarge.copyWith(
                        color: colors.primary,
                        fontSize: 36,
                      ),
                    ),
                    Text(
                      'Standard: ₹${widget.currentEstimatedFare.toStringAsFixed(0)} (Min: ₹${widget.minimumFloorFare.toStringAsFixed(0)})',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => _adjustFare(20),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 36),
                  color: colors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXl),
          GradientButton(
            text: 'Send Offer to Drivers',
            isLoading: _isSubmitting,
            onPressed: _submitOffer,
          ),
        ],
      ),
    );
  }
}
