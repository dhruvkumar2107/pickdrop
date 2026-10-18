import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../../../config/router/route_names.dart';
import '../../../../../core/constants/colors.dart';
import '../../../../../core/constants/dimensions.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../../booking/presentation/providers/booking_providers.dart';

class FindingDriverPage extends ConsumerStatefulWidget {
  final String pickupAddress;
  final String dropAddress;
  final double fare;
  final double pickupLat;
  final double pickupLng;
  final double dropLat;
  final double dropLng;
  final String vehicleTypeId;
  final String vehicleType;
  final double distanceKm;
  final String paymentMethod;
  final String goodsType;
  final bool loadingHelper;
  final String couponCode;
  final double discount;
  final String bookingId;

  const FindingDriverPage({
    super.key,
    required this.pickupAddress,
    required this.dropAddress,
    this.fare = 0,
    this.pickupLat = 0,
    this.pickupLng = 0,
    this.dropLat = 0,
    this.dropLng = 0,
    this.vehicleTypeId = '',
    this.vehicleType = 'Bike',
    this.distanceKm = 0,
    this.paymentMethod = 'cod',
    this.goodsType = '',
    this.loadingHelper = false,
    this.couponCode = '',
    this.discount = 0,
    this.bookingId = '',
  });

  @override
  ConsumerState<FindingDriverPage> createState() => _FindingDriverPageState();
}

class _FindingDriverPageState extends ConsumerState<FindingDriverPage>
    with TickerProviderStateMixin {
  late AnimationController _radarController;
  late AnimationController _messageController;
  int _messageIndex = 0;
  Timer? _messageTimer;
  Timer? _matchTimer;
  StreamSubscription<String>? _statusSub;
  bool _driverFound = false;

  final List<String> _messages = [
    'Looking for drivers nearby...',
    'Almost there!',
    'Connecting you to a driver...',
    'Finding the best match for you...',
    'Great drivers in your area!',
  ];

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _messageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _messageTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _messageController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _messageIndex = (_messageIndex + 1) % _messages.length;
          });
          _messageController.forward();
        }
      });
    });
    _messageController.forward();

    if (widget.bookingId.isNotEmpty) {
      // Real Firestore booking: react to status transitions.
      _statusSub = ref
          .read(bookingRemoteDataSourceProvider)
          .watchBookingStatus(widget.bookingId)
          .listen(_onBookingStatus);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          AppToast.error(
            context,
            'A valid booking is required to find a driver.',
          );
          _goHome();
        }
      });
    }
  }

  void _onBookingStatus(String status) {
    if (!mounted || _driverFound) return;
    switch (status) {
      case 'DRIVER_ASSIGNED':
        _onDriverFound();
      case 'NO_DRIVER_FOUND':
        AppToast.error(context, 'No drivers available nearby');
        _goHome();
      case 'CANCELLED':
        _goHome();
      default:
        break;
    }
  }

  void _goHome() {
    if (mounted) context.go(RouteNames.customerHome);
  }

  Future<void> _onCancelSearch() async {
    HapticFeedback.mediumImpact();
    final bookingId = widget.bookingId;
    if (bookingId.isNotEmpty) {
      try {
        await ref
            .read(bookingRemoteDataSourceProvider)
            .cancelBooking(bookingId);
      } catch (e) {
        debugPrint('cancelBooking failed: $e');
      }
    }
    _goHome();
  }

  void _onDriverFound() {
    if (!mounted || _driverFound) return;
    _driverFound = true;
    HapticFeedback.mediumImpact();

    final q = <String, String>{
      'fare': widget.fare.toStringAsFixed(0),
      'pickupAddress': widget.pickupAddress,
      'dropAddress': widget.dropAddress,
      'pickupLat': widget.pickupLat.toString(),
      'pickupLng': widget.pickupLng.toString(),
      'dropLat': widget.dropLat.toString(),
      'dropLng': widget.dropLng.toString(),
      'paymentMethod': widget.paymentMethod,
      'bookingId': widget.bookingId,
    };
    final encoded = q.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    context.go('${RouteNames.liveTracking}?$encoded');
  }

  @override
  void dispose() {
    _radarController.dispose();
    _messageController.dispose();
    _messageTimer?.cancel();
    _matchTimer?.cancel();
    _statusSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // Radar animation full screen center
          Center(child: _RadarPulse(controller: _radarController)),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingLg),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _onCancelSearch,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomCard(
              pickupAddress: widget.pickupAddress,
              dropAddress: widget.dropAddress,
              message: _messages[_messageIndex],
              messageController: _messageController,
              onCancel: _onCancelSearch,
            ),
          ),
        ],
      ),
    );
  }
}

class _RadarPulse extends StatelessWidget {
  final AnimationController controller;
  const _RadarPulse({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) {
        return SizedBox(
          width: 300,
          height: 300,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(300, 300),
                painter: _RadarPainter(controller.value),
              ),
              SizedBox(
                width: 150,
                height: 150,
                child: Lottie.asset(
                  'assets/animations/searching_driver.json',
                  width: 150,
                  height: 150,
                  repeat: true,
                  fit: BoxFit.contain,
                  frameRate: FrameRate.max,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double progress;
  _RadarPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < 3; i++) {
      final p = (progress + i / 3) % 1.0;
      final radius = p * maxRadius;
      final opacity = (1.0 - p).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = AppColors.primary.withValues(alpha: opacity * 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, paint);

      final borderPaint = Paint()
        ..color = AppColors.primary.withValues(alpha: opacity * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(center, radius, borderPaint);
    }

    // Soft hub that sits behind the searching animation
    final hubPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 58, hubPaint);
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.progress != progress;
}

class _BottomCard extends StatelessWidget {
  final String pickupAddress;
  final String dropAddress;
  final String message;
  final AnimationController messageController;
  final VoidCallback onCancel;

  const _BottomCard({
    required this.pickupAddress,
    required this.dropAddress,
    required this.message,
    required this.messageController,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.spacingLg),
      padding: const EdgeInsets.all(AppDimensions.spacingXl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated message
          FadeTransition(
            opacity: messageController,
            child: Text(
              message,
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXl),

          // Route summary
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingLg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Column(
              children: [
                _AddressRow(
                  icon: Icons.circle,
                  iconColor: AppColors.primary,
                  label: pickupAddress,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Column(
                    children: List.generate(
                      3,
                      (_) => Container(
                        width: 2,
                        height: 6,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        color: AppColors.outline,
                      ),
                    ),
                  ),
                ),
                _AddressRow(
                  icon: Icons.location_on,
                  iconColor: const Color(0xFF16A34A),
                  label: dropAddress,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXl),

          // Cancel button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.outline),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
              ),
              child: Text(
                'Cancel Search',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    ).animate().slideY(begin: 1, end: 0, curve: Curves.easeOutCubic);
  }
}

class _AddressRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;

  const _AddressRow({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(width: AppDimensions.spacingSm),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

extension _RadarMath on math.Random {
  // ignore: unused_element
  double nextDouble() => 0;
}
