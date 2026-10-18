import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/router/route_names.dart';
import '../../../../../core/constants/colors.dart';
import '../../../../../core/constants/dimensions.dart';
import '../../../../../core/theme/text_styles.dart';

class ActiveTripPage extends StatefulWidget {
  final String pickupAddress;
  final String dropAddress;
  final String customerName;
  final String otp;

  const ActiveTripPage({
    super.key,
    this.pickupAddress = '12, MG Road, Bangalore',
    this.dropAddress = 'Whitefield, Bangalore',
    this.customerName = 'Dhruv M',
    this.otp = '4521',
  });

  @override
  State<ActiveTripPage> createState() => _ActiveTripPageState();
}

class _ActiveTripPageState extends State<ActiveTripPage> {
  int _step = 0; // 0=go to pickup, 1=picked up, 2=delivered

  final List<_TripStep> _steps = [
    _TripStep(
      label: 'Head to Pickup',
      sublabel: 'Navigate to pickup location',
      icon: Icons.directions_rounded,
      color: AppColors.primary,
      actionLabel: 'Arrived at Pickup',
    ),
    _TripStep(
      label: 'Pickup Package',
      sublabel: 'Collect the package from sender',
      icon: Icons.inventory_2_rounded,
      color: Color(0xFF2563EB),
      actionLabel: 'Package Picked Up',
    ),
    _TripStep(
      label: 'Deliver Package',
      sublabel: 'Navigate to drop location',
      icon: Icons.local_shipping_rounded,
      color: Color(0xFF16A34A),
      actionLabel: 'Package Delivered',
    ),
  ];

  void _showDriverRatingSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DriverRatingSheet(
        customerName: widget.customerName,
        onSubmit: (rating, review) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Rating submitted: $rating stars')),
          );
          context.go(RouteNames.driverHome);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = _steps[_step.clamp(0, _steps.length - 1)];
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF14161A),
      body: Stack(
        children: [
          // Map bg
          Container(
            color: const Color(0xFF1E2028),
            child: const Center(
              child: Icon(Icons.map, size: 80, color: Color(0xFF2D3038)),
            ),
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingLg),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingLg,
                    vertical: AppDimensions.spacingMd),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2028),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: currentStep.color.withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusSm),
                      ),
                      child: Icon(currentStep.icon,
                          color: currentStep.color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(currentStep.label,
                              style: AppTextStyles.titleLarge
                                  .copyWith(color: Colors.white)),
                          Text(currentStep.sublabel,
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.white60)),
                        ],
                      ),
                    ),
                    Text(
                      '${_step + 1}/${_steps.length}',
                      style: AppTextStyles.labelMedium
                          .copyWith(color: Colors.white60),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  AppDimensions.spacingXl,
                  AppDimensions.spacingXl,
                  AppDimensions.spacingXl,
                  AppDimensions.spacingXl + safeBottom),
              decoration: const BoxDecoration(
                color: Color(0xFF1E2028),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppDimensions.radiusLg),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3D3D4A),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusFull),
                    ),
                  ),

                  // Customer info
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            widget.customerName[0],
                            style: AppTextStyles.headlineSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.customerName,
                                style: AppTextStyles.titleLarge
                                    .copyWith(color: Colors.white)),
                            Text('Customer',
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: Colors.white60)),
                          ],
                        ),
                      ),
                      // Call button
                      GestureDetector(
                        onTap: () => HapticFeedback.lightImpact(),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.call_rounded,
                              color: Color(0xFF22C55E), size: 22),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacingLg),

                  // OTP (show on first step)
                  if (_step == 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_rounded,
                              color: AppColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Text('Pickup OTP: ',
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: Colors.white70)),
                          Text(
                            widget.otp,
                            style: AppTextStyles.titleLarge.copyWith(
                              color: AppColors.primary,
                              letterSpacing: 4,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingLg),
                  ],

                  // Swipe / confirm button
                  _SwipeButton(
                    label: currentStep.actionLabel,
                    color: currentStep.color,
                    onConfirm: () {
                      HapticFeedback.heavyImpact();
                      if (_step < _steps.length - 1) {
                        setState(() => _step++);
                      } else {
                        _showDriverRatingSheet(context);
                      }
                    },
                  ),
                ],
              ),
            ).animate().slideY(begin: 1, end: 0, curve: Curves.easeOutCubic),
          ),
        ],
      ),
    );
  }
}

class _TripStep {
  final String label;
  final String sublabel;
  final IconData icon;
  final Color color;
  final String actionLabel;

  const _TripStep({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.color,
    required this.actionLabel,
  });
}

class _SwipeButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onConfirm;

  const _SwipeButton({
    required this.label,
    required this.color,
    required this.onConfirm,
  });

  @override
  State<_SwipeButton> createState() => _SwipeButtonState();
}

class _SwipeButtonState extends State<_SwipeButton> {
  double _dragX = 0;
  static const double _buttonHeight = 60;
  static const double _thumbSize = 48;
  static const double _padding = 6;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      final trackWidth = constraints.maxWidth;
      final maxDrag = trackWidth - _thumbSize - _padding * 2;
      final progress = (_dragX / maxDrag).clamp(0.0, 1.0);

      return GestureDetector(
        onHorizontalDragUpdate: (d) {
          setState(() {
            _dragX = (_dragX + d.delta.dx).clamp(0, maxDrag);
          });
        },
        onHorizontalDragEnd: (_) {
          if (progress > 0.8) {
            widget.onConfirm();
            setState(() => _dragX = 0);
          } else {
            setState(() => _dragX = 0);
          }
        },
        child: Container(
          height: _buttonHeight,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(_buttonHeight / 2),
            border: Border.all(
                color: widget.color.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Stack(
            children: [
              // Fill
              Positioned(
                left: _padding,
                top: _padding,
                bottom: _padding,
                width: _thumbSize + _dragX * 0.9,
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(_buttonHeight / 2),
                  ),
                ),
              ),
              // Label
              Center(
                child: Opacity(
                  opacity: (1 - progress * 1.5).clamp(0.0, 1.0),
                  child: Text(
                    'Swipe → ${widget.label}',
                    style: AppTextStyles.labelLarge
                        .copyWith(color: Colors.white70),
                  ),
                ),
              ),
              // Thumb
              Positioned(
                left: _padding + _dragX,
                top: _padding,
                bottom: _padding,
                width: _thumbSize,
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.chevron_right_rounded,
                      color: Colors.white, size: 28),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _DriverRatingSheet extends StatefulWidget {
  final String customerName;
  final void Function(int rating, String review) onSubmit;

  const _DriverRatingSheet({
    required this.customerName,
    required this.onSubmit,
  });

  @override
  State<_DriverRatingSheet> createState() => _DriverRatingSheetState();
}

class _DriverRatingSheetState extends State<_DriverRatingSheet> {
  int _rating = 0;
  final TextEditingController _reviewController = TextEditingController();

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1E2028),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF3D3D4A),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Rate ${widget.customerName}',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'How was the pickup experience?',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Colors.white60,
              ),
            ),
            const SizedBox(height: 24),
            _buildStarPicker(context),
            const SizedBox(height: 24),
            TextField(
              controller: _reviewController,
              maxLines: 3,
              minLines: 2,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: 'Write a review (optional)',
                hintStyle: TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF2D3038),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _rating == 0
                    ? null
                    : () => widget.onSubmit(_rating, _reviewController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  disabledBackgroundColor: Colors.white12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Submit Rating',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStarPicker(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final selected = index < _rating;

        return GestureDetector(
          onTap: () => setState(() => _rating = index + 1),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              selected ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 44,
              color: selected ? const Color(0xFFFBBF24) : Colors.white38,
            )
                .animate(delay: (index * 70).ms)
                .fadeIn(duration: 300.ms)
                .scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1.0, 1.0),
                  duration: 500.ms,
                  curve: Curves.easeOutBack,
                ),
          ),
        );
      }),
    );
  }
}
