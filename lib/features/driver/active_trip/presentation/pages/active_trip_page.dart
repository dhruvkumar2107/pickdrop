import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/router/route_names.dart';
import '../../../../customer/booking/data/datasources/booking_remote_datasource.dart';
import '../../../../../core/constants/colors.dart';
import '../../../../../core/constants/dimensions.dart';
import '../../../../../core/theme/text_styles.dart';

class ActiveTripPage extends StatefulWidget {
  final String bookingId;
  final String pickupAddress;
  final String dropAddress;
  final String customerName;

  const ActiveTripPage({
    super.key,
    required this.bookingId,
    this.pickupAddress = '12, MG Road, Bangalore',
    this.dropAddress = 'Whitefield, Bangalore',
    this.customerName = 'Customer',
  });

  @override
  State<ActiveTripPage> createState() => _ActiveTripPageState();
}

class _ActiveTripPageState extends State<ActiveTripPage> {
  int _step = 0; // 0=go to pickup, 1=picked up, 2=delivered
  final TextEditingController _otpController = TextEditingController();
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _bookingSub;
  bool _isWorking = false;
  List<Map<String, dynamic>> _intermediateStops = [];

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

  @override
  void initState() {
    super.initState();
    if (widget.bookingId.isNotEmpty) {
      _bookingSub = FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .snapshots()
          .listen((snapshot) {
            final data = snapshot.data();
            if (!mounted || data == null) return;
            final status = data['status'] as String? ?? '';
            final stops = (data['intermediateStops'] as List<dynamic>? ?? [])
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
            setState(() {
              _intermediateStops = stops;
              if (status == 'PICKED_UP') _step = 2;
            });
            if (status == 'DELIVERED') {
              context.go(RouteNames.driverHome);
            } else if (status == 'CANCELLED' || status == 'NO_DRIVER_FOUND') {
              context.go(RouteNames.driverHome);
            }
          });
    }
  }

  @override
  void dispose() {
    _bookingSub?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _confirmAction() async {
    if (_isWorking) return;
    if (widget.bookingId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A valid delivery is required.')),
      );
      return;
    }
    if (_step == 0) {
      setState(() => _step = 1);
      return;
    }
    final otp = _otpController.text.trim();
    if (otp.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter the 4-digit code from the customer.'),
        ),
      );
      return;
    }
    setState(() => _isWorking = true);
    try {
      if (_step == 1) {
        await BookingRemoteDataSource().verifyPickupOtp(widget.bookingId, otp);
      } else if (_nextStop != null) {
        await BookingRemoteDataSource().verifyIntermediateStopOtp(
          widget.bookingId,
          (_nextStop!['sequence'] as num).toInt(),
          otp,
        );
      } else {
        await BookingRemoteDataSource().verifyDropOtp(widget.bookingId, otp);
      }
      _otpController.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'The code was rejected or this delivery has changed. Try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Map<String, dynamic>? get _nextStop {
    for (final stop in _intermediateStops) {
      if (stop['otpVerified'] != true) return stop;
    }
    return null;
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
                  vertical: AppDimensions.spacingMd,
                ),
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
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusSm,
                        ),
                      ),
                      child: Icon(
                        currentStep.icon,
                        color: currentStep.color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentStep.label,
                            style: AppTextStyles.titleLarge.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            currentStep.sublabel,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${_step + 1}/${_steps.length}',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: Colors.white60,
                      ),
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
                AppDimensions.spacingXl + safeBottom,
              ),
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
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusFull,
                      ),
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
                            Text(
                              widget.customerName,
                              style: AppTextStyles.titleLarge.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Customer',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Call button
                      GestureDetector(
                        onTap: () => HapticFeedback.lightImpact(),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A)
                                .withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.call_rounded,
                            color: Color(0xFF22C55E),
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacingLg),

                  // OTP (show on first step)
                  if (_step > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMd,
                        ),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.lock_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _step == 1
                                ? 'Pickup code: '
                                : _nextStop != null
                                ? 'Stop ${_nextStop!['sequence']} code: '
                                : 'Drop code: ',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            '',
                            style: AppTextStyles.titleLarge.copyWith(
                              color: AppColors.primary,
                              letterSpacing: 4,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingMd),
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        hintText: 'Enter 4-digit code',
                        counterText: '',
                      ),
                    ),
                    if (_step == 2 && _nextStop != null) ...[
                      const SizedBox(height: AppDimensions.spacingSm),
                      Text(
                        'Intermediate stop ${_nextStop!['sequence']}: ${_nextStop!['address'] ?? 'Pinned stop'}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppDimensions.spacingLg),
                  ],

                  // Swipe / confirm button
                  _SwipeButton(
                    label: _step == 2 && _nextStop != null
                        ? 'Verify stop ${_nextStop!['sequence']} delivery'
                        : currentStep.actionLabel,
                    color: currentStep.color,
                    isLoading: _isWorking,
                    onConfirm: _confirmAction,
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
  final bool isLoading;

  const _SwipeButton({
    required this.label,
    required this.color,
    required this.onConfirm,
    this.isLoading = false,
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
    return LayoutBuilder(
      builder: (_, constraints) {
        final trackWidth = constraints.maxWidth;
        final maxDrag = trackWidth - _thumbSize - _padding * 2;
        final progress = (_dragX / maxDrag).clamp(0.0, 1.0);

        return GestureDetector(
          onHorizontalDragUpdate: (d) {
            if (widget.isLoading) return;
            setState(() {
              _dragX = (_dragX + d.delta.dx).clamp(0, maxDrag);
            });
          },
          onHorizontalDragEnd: (_) {
            if (widget.isLoading) return;
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
                color: widget.color.withValues(alpha: 0.3),
                width: 1.5,
              ),
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
                      style: AppTextStyles.labelLarge.copyWith(
                        color: Colors.white70,
                      ),
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
                    child: widget.isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
