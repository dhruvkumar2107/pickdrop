import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../../../config/router/route_names.dart';
import '../../../../../config/env/env_config.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/constants/colors.dart';
import '../../../../../core/constants/dimensions.dart';
import '../../../../../core/constants/strings.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../../../../core/widgets/cards/cards.dart';
import '../../../../../core/widgets/gradient_button.dart';
import '../../../../../core/widgets/inputs/inputs.dart';
import '../../../../../core/widgets/status_chip.dart';

class TripCompletePage extends StatefulWidget {
  const TripCompletePage({
    super.key,
    this.fare,
    this.driverName,
    this.paymentMethod,
    this.bookingId,
    this.driverId,
  });

  final double? fare;
  final String? driverName;
  final String? paymentMethod;
  final String? bookingId;
  final String? driverId;

  @override
  State<TripCompletePage> createState() => _TripCompletePageState();
}

class _TripCompletePageState extends State<TripCompletePage> {
  static const double _distanceFare = 128;
  static const double _timeFare = 46;
  static const double _surgeFare = 30;
  static const String _driverInitials = 'RS';
  static const String _vehicleDetails = 'TVS Jupiter • KA 01 HB 2456';
  static const String _bookingId = 'PD-2481';

  final ConfettiController _confettiController = ConfettiController(
    duration: const Duration(seconds: 5),
  );
  final TextEditingController _reviewController = TextEditingController();

  int _rating = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _confettiController.play();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  double get _subtotal => _distanceFare + _timeFare + _surgeFare;

  double get _gst => _subtotal * AppConstants.defaultGstPercent / 100;

  double get _total => widget.fare ?? (_subtotal + _gst);

  String get _driverName => widget.driverName ?? 'Rahul Sharma';

  bool get _paidOnline =>
      (widget.paymentMethod ?? AppConstants.paymentRazorpay) !=
      AppConstants.paymentCod;

  String get _ratingLabel {
    switch (_rating) {
      case 5:
        return AppStrings.excellent;
      case 4:
        return AppStrings.good;
      case 3:
        return AppStrings.average;
      case 2:
        return AppStrings.poor;
      case 1:
        return AppStrings.terrible;
      default:
        return 'Tap a star to rate your driver';
    }
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      AppToast.warning(context, 'Please select a star rating first');
      return;
    }

    final bookingId = widget.bookingId;
    if (FirebaseAuth.instance.currentUser == null ||
        bookingId == null ||
        bookingId.isEmpty) {
      AppToast.error(
        context,
        'This trip cannot be rated because its booking details are missing.',
      );
      return;
    }
    final review = _reviewController.text.trim();
    try {
      await FirebaseFunctions.instanceFor(region: EnvConfig.functionsRegion)
          .httpsCallable('submitTripRating')
          .call({'bookingId': bookingId, 'rating': _rating, 'review': review});
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      AppToast.error(
        context,
        e.code == 'already-exists'
            ? 'You already rated this trip.'
            : (e.message ?? 'Could not submit your rating.'),
      );
      return;
    } catch (_) {
      if (!mounted) return;
      AppToast.error(
        context,
        'Could not submit your rating. Please try again.',
      );
      return;
    }

    if (!mounted) return;
    AppToast.success(context, 'Thanks! Your rating was submitted');
    context.go(RouteNames.customerHome);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spacingLg,
                AppDimensions.spacingXl,
                AppDimensions.spacingLg,
                AppDimensions.spacingXl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSuccessHeader(context, colors),
                  const SizedBox(height: AppDimensions.spacingXl),
                  _buildReceiptCard(context, colors),
                  const SizedBox(height: AppDimensions.spacingXl),
                  _buildRatingSection(context, colors),
                  const SizedBox(height: AppDimensions.spacingXl),
                  GradientButton(
                    text: AppStrings.submitRating,
                    onPressed: _submitRating,
                    trailingIcon: Icons.arrow_forward_rounded,
                  ),
                  const SizedBox(height: AppDimensions.spacingMd),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go(RouteNames.customerHome),
                      child: Text(
                        'Back to home',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.06,
                numberOfParticles: 14,
                gravity: 0.35,
                maxBlastForce: 28,
                minBlastForce: 8,
                colors: [
                  colors.primary,
                  colors.primaryEnd,
                  colors.success,
                  colors.warning,
                  colors.info,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessHeader(BuildContext context, AppColorsExtension colors) {
    return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
                  width: 128,
                  height: 128,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        colors.success.withValues(alpha: 0.25),
                        colors.success.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                  child: SizedBox(
                    width: 112,
                    height: 112,
                    child: Lottie.asset(
                      'assets/animations/trip_complete.json',
                      width: 112,
                      height: 112,
                      repeat: false,
                      fit: BoxFit.contain,
                      frameRate: FrameRate.max,
                    ),
                  ),
                )
                .animate()
                .fadeIn(duration: AppConstants.mediumAnimation)
                .scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1.0, 1.0),
                  duration: AppConstants.dramaticAnimation,
                  curve: Curves.elasticOut,
                ),
            const SizedBox(height: AppDimensions.spacingLg),
            Text(
              AppStrings.tripCompleted,
              textAlign: TextAlign.center,
              style: AppTextStyles.displaySmall.copyWith(
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingXs),
            Text(
              'Your goods were delivered safely to the drop location',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        )
        .animate(delay: 150.ms)
        .fadeIn(duration: AppConstants.mediumAnimation)
        .slideY(begin: 0.15, end: 0);
  }

  Widget _buildReceiptCard(BuildContext context, AppColorsExtension colors) {
    return AppCard(
      color: colors.surfaceCard,
      border: Border.all(color: colors.outlineVariant, width: 1),
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.receipt,
                style: AppTextStyles.headlineSmall.copyWith(
                  color: colors.onSurface,
                ),
              ),
              StatusChip(
                label: _paidOnline ? 'Paid online' : 'Pay by cash',
                status: AppChipStatus.success,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingXxs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Booking #$_bookingId',
                style: AppTextStyles.bodySmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              Text(
                _paidOnline ? 'UPI / Card' : AppStrings.payCash,
                style: AppTextStyles.bodySmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Container(
            height: 1,
            decoration: BoxDecoration(
              color: colors.outlineVariant,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          _buildRow(
            colors,
            label: AppStrings.distanceFare,
            value: '₹${_distanceFare.toStringAsFixed(0)}',
          ),
          _buildRow(
            colors,
            label: AppStrings.timeFare,
            value: '₹${_timeFare.toStringAsFixed(0)}',
          ),
          _buildRow(
            colors,
            label: AppStrings.surgeCharges,
            value: '₹${_surgeFare.toStringAsFixed(0)}',
          ),
          _buildRow(
            colors,
            label: AppStrings.gst,
            value: '₹${_gst.toStringAsFixed(0)}',
          ),
          _buildRow(
            colors,
            label: AppStrings.discount,
            value: '−₹0',
            valueColor: colors.onSurfaceVariant,
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          Container(
            height: 1,
            decoration: BoxDecoration(
              color: colors.outlineVariant,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.totalPayable,
                style: AppTextStyles.titleMedium.copyWith(
                  color: colors.onSurface,
                ),
              ),
              Text(
                '₹${_total.toStringAsFixed(0)}',
                style: AppTextStyles.priceMedium.copyWith(
                  color: colors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    AppColorsExtension colors, {
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingXxs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.titleSmall.copyWith(
              color: valueColor ?? colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection(BuildContext context, AppColorsExtension colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.rateYourDriver,
          style: AppTextStyles.headlineSmall.copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: AppDimensions.spacingXxs),
        Text(
          'Your feedback keeps our drivers sharp',
          style: AppTextStyles.bodySmall.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingMd),
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: colors.primaryContainer,
              child: Text(
                _driverInitials,
                style: AppTextStyles.titleMedium.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _driverName,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _vehicleDetails,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            StatusChip(
              label: AppStrings.rateExperience,
              status: AppChipStatus.active,
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingLg),
        _buildStarPicker(context, colors),
        const SizedBox(height: AppDimensions.spacingSm),
        Center(
          child: Text(
            _ratingLabel,
            style: AppTextStyles.titleSmall.copyWith(
              color: _rating == 0 ? colors.onSurfaceVariant : colors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spacingLg),
        MultilineTextField(
          controller: _reviewController,
          label: AppStrings.writeReview,
          hint: 'How was the pickup, handling and delivery?',
          maxLines: 4,
          minLines: 3,
          maxLength: 240,
        ),
      ],
    );
  }

  Widget _buildStarPicker(BuildContext context, AppColorsExtension colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final selected = index < _rating;

        return GestureDetector(
          onTap: () => setState(() => _rating = index + 1),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingSm,
            ),
            child:
                Icon(
                      selected
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 46,
                      color: selected ? Colors.amber : colors.outline,
                    )
                    .animate(delay: (index * 70).ms)
                    .fadeIn(duration: AppConstants.mediumAnimation)
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1.0, 1.0),
                      duration: AppConstants.longAnimation,
                      curve: Curves.easeOutBack,
                    ),
          ),
        );
      }),
    );
  }
}
