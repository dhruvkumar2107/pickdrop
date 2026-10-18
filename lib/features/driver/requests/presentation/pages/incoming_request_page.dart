import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../config/router/route_names.dart';
import '../../../../../../core/constants/app_constants.dart';
import '../../../../../../core/constants/colors.dart';
import '../../../../../../core/constants/dimensions.dart';
import '../../../../../../core/constants/strings.dart';
import '../../../../../../core/widgets/app_toast.dart';
import '../../../../../../core/widgets/buttons/buttons.dart';
import '../../../../../../core/widgets/glass_card.dart';
import '../../../../../../core/widgets/gradient_button.dart';
import '../../../../../../core/widgets/status_chip.dart';
import '../../../../common/matching/services/driver_reliability_service.dart';
import '../../../shared/services/driver_commission_service.dart';
import '../../../shared/services/offline_action_queue.dart';

/// Readable foreground colour for a given accent (adapts to light/dark themes).
Color _onAccent(Color accent) =>
    accent.computeLuminance() > 0.45 ? const Color(0xFF062B2E) : Colors.white;

/// Darker companion colour used to finish driver accent gradients.
Color _accentEnd(Color accent) => Color.lerp(accent, Colors.black, 0.32)!;

class IncomingRequestPage extends StatefulWidget {
  const IncomingRequestPage({super.key});

  @override
  State<IncomingRequestPage> createState() => _IncomingRequestPageState();
}

class _IncomingRequestPageState extends State<IncomingRequestPage> {
  static const int _totalSeconds = AppConstants.defaultOfferTimeoutSeconds;
  static const String _pickup = 'Phoenix Marketcity, Viman Nagar, Pune';
  static const String _drop = 'Blueridge Phase 2, Hinjewadi, Pune';
  static const String _goods = '3 boxes • Glass appliances';
  static const String _customerNote = 'Please call when you reach the pickup gate.';
  static const double _distanceKm = 3.2;
  static const int _etaMinutes = 12;
  static const double _fare = 180;
  static const double _tip = 40;
  static const double _baseFare = 120;
  static const double _distanceFare = 60;
  static const double _pickupKm = 1.4;
  static const String _bookingId = 'PD1051';
  static const int _completedTrips = 8;

  int _secondsLeft = AppConstants.defaultOfferTimeoutSeconds;
  bool _isExpired = false;
  Timer? _timer;
  late Map<String, dynamic> _breakdown;
  DriverReliabilityModel? _reliability;

  double get _gross => (_breakdown['gross'] as num?)?.toDouble() ?? 0;

  double get _commission => (_breakdown['commission'] as num?)?.toDouble() ?? 0;

  double get _payout => (_breakdown['net'] as num?)?.toDouble() ?? 0;

  double get _rate => (_breakdown['rate'] as num?)?.toDouble() ?? 0;

  bool get _isFreeTier => _breakdown['isFreeTier'] == true;

  @override
  void initState() {
    super.initState();
    _breakdown = DriverCommissionService.breakdown(
      fare: _fare,
      completedTrips: _completedTrips,
      tip: _tip,
    );
    _timer = Timer.periodic(const Duration(seconds: 1), _onTick);
    _bootstrap();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onTick(Timer timer) {
    if (!mounted) return;
    if (_secondsLeft <= 1) {
      timer.cancel();
      setState(() {
        _secondsLeft = 0;
        _isExpired = true;
      });
      _handleExpiry();
      return;
    }
    setState(() => _secondsLeft--);
  }

  Future<void> _handleExpiry() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    AppToast.warning(context, 'The offer expired before you responded');
    context.go(RouteNames.driverHome);
  }

  Future<void> _bootstrap() async {
    await _loadReliability();
    await DriverCommissionService.loadConfig();
    if (!mounted) return;
    setState(() {
      _breakdown = DriverCommissionService.breakdown(
        fare: _fare,
        completedTrips: _completedTrips,
        tip: _tip,
      );
    });
  }

  Future<void> _loadReliability() async {
    var model = DriverReliabilityModel.fromMap(<String, dynamic>{});
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('driverScores')
            .doc(uid)
            .get();
        final data = snapshot.data();
        if (data != null) {
          model = DriverReliabilityModel.fromMap(data);
        }
      } catch (_) {
        model = DriverReliabilityModel.fromMap(<String, dynamic>{});
      }
    }
    if (!mounted) return;
    setState(() => _reliability = model);
  }

  Future<void> _accept() async {
    if (_isExpired) return;
    _timer?.cancel();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    await OfflineActionQueue.enqueue(
      OfflineActionQueue.acceptTrip,
      <String, dynamic>{
        'bookingId': _bookingId,
        'driverId': uid,
        'pickup': _pickup,
        'drop': _drop,
        'gross': _gross,
        'tip': _tip,
      },
    );
    if (!mounted) return;
    unawaited(
      OfflineActionQueue.flush(FirebaseFirestore.instance),
    );
    AppToast.success(context, 'Trip accepted — head to the pickup point');
    context.go(RouteNames.driverHome);
  }

  void _decline() {
    _timer?.cancel();
    AppToast.info(context, 'Request declined');
    context.go(RouteNames.driverHome);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final onAccent = _onAccent(colors.driverAccent);

    return Scaffold(
      backgroundColor: colors.surface,
      body: Column(
        children: [
          _buildHeader(context, colors, onAccent),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildRouteCard(colors),
                  const SizedBox(height: AppDimensions.spacingMd),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoTile(
                          icon: Icons.near_me_outlined,
                          label: 'Distance',
                          value: '$_distanceKm km',
                          color: colors.driverAccent,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingMd),
                      Expanded(
                        child: _InfoTile(
                          icon: Icons.schedule_rounded,
                          label: AppStrings.eta,
                          value: '$_etaMinutes min',
                          color: colors.info,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingMd),
                      Expanded(
                        child: _InfoTile(
                          icon: Icons.payments_outlined,
                          label: AppStrings.estimatedFare,
                          value: '₹${_fare.toStringAsFixed(0)}',
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacingMd),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoTile(
                          icon: Icons.volunteer_activism_outlined,
                          label: 'Customer tip',
                          value: '₹${_tip.toStringAsFixed(0)}',
                          color: colors.success,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingMd),
                      Expanded(
                        child: _InfoTile(
                          icon: Icons.percent_rounded,
                          label: _isFreeTier
                              ? 'Commission (0%)'
                              : 'Commission (${(_rate * 100).toStringAsFixed(0)}%)',
                          value: '−₹${_commission.toStringAsFixed(0)}',
                          color: _isFreeTier ? colors.success : colors.error,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingMd),
                      Expanded(
                        child: _InfoTile(
                          icon: Icons.account_balance_wallet_outlined,
                          label: AppStrings.netEarnings,
                          value: '₹${_payout.toStringAsFixed(0)}',
                          color: colors.driverAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacingMd),
                  _buildBreakdown(colors),
                  const SizedBox(height: AppDimensions.spacingMd),
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.spacingMd),
                    decoration: BoxDecoration(
                      color: colors.infoLight,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      border: Border.all(color: colors.info.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.sticky_note_2_outlined,
                          size: AppDimensions.iconSm,
                          color: colors.info,
                        ),
                        const SizedBox(width: AppDimensions.spacingMd),
                        Expanded(
                          child: Text(
                            'Note from customer: $_customerNote',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: colors.info,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: AppConstants.mediumAnimation),
                  const SizedBox(height: AppDimensions.spacingMd),
                  _buildReliability(colors),
                ],
              ),
            ),
          ),
          _buildActions(context, colors),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppColorsExtension colors,
    Color onAccent,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppDimensions.spacingLg,
        MediaQuery.of(context).padding.top + AppDimensions.spacingSm,
        AppDimensions.spacingLg,
        AppDimensions.spacingLg,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.driverAccent, _accentEnd(colors.driverAccent)],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButtonWidget(
                icon: Icons.arrow_back_rounded,
                color: onAccent,
                backgroundColor: onAccent.withValues(alpha: 0.14),
                onPressed: () {
                  if (!mounted) return;
                  context.go(RouteNames.driverHome);
                },
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              Expanded(
                child: Text(
                  AppStrings.incomingRequest,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.25,
                    color: onAccent,
                  ),
                ),
              ),
              StatusChip(
                label: 'New request',
                status: AppChipStatus.upcoming,
                dense: true,
                showDot: false,
                backgroundColor: onAccent.withValues(alpha: 0.18),
                foregroundColor: onAccent,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          GlassCard(
            padding: const EdgeInsets.all(AppDimensions.spacingMd),
            radius: AppDimensions.radiusMd,
            color: onAccent.withValues(alpha: 0.12),
            borderColor: onAccent.withValues(alpha: 0.28),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      _isExpired ? Icons.timer_off_outlined : Icons.timer_outlined,
                      size: AppDimensions.iconSm,
                      color: onAccent,
                    ),
                    const SizedBox(width: AppDimensions.spacingSm),
                    Expanded(
                      child: Text(
                        _isExpired ? 'Offer expired' : 'Offer expires in',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: onAccent.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                    Text(
                      '${_secondsLeft}s',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.25,
                        color: onAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingMd),
                _buildCountdownBar(colors, onAccent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownBar(AppColorsExtension colors, Color onAccent) {
    final fraction = (_secondsLeft / _totalSeconds).clamp(0.0, 1.0);
    final barColor = _secondsLeft <= 5 ? colors.error : colors.warning;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 1, end: fraction),
          duration: const Duration(milliseconds: 850),
          curve: Curves.linear,
          builder: (context, value, child) {
            return Stack(
              children: [
                Container(
                  width: maxWidth,
                  height: 8,
                  decoration: BoxDecoration(
                    color: onAccent.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                ),
                Container(
                  width: maxWidth * value,
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [barColor, barColor.withValues(alpha: 0.55)],
                    ),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRouteCard(AppColorsExtension colors) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingSm),
                decoration: BoxDecoration(
                  color: colors.driverAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Icon(
                  Icons.local_shipping_outlined,
                  size: AppDimensions.iconSm,
                  color: colors.driverAccent,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery request',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _goods,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              StatusChip.fromStatus('ACCEPTED', dense: true, label: 'Prepaid'),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Row(
            children: [
              Icon(
                Icons.near_me_outlined,
                size: AppDimensions.iconSm,
                color: colors.info,
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              Expanded(
                child: Text(
                  'Pickup is $_pickupKm km from you right now',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: colors.info,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          _RouteRow(
            icon: Icons.radio_button_checked,
            iconColor: colors.success,
            label: 'PICKUP',
            address: _pickup,
            colors: colors,
          ),
          Padding(
            padding: const EdgeInsets.only(left: AppDimensions.spacingMd + 5),
            child: Container(
              width: 2,
              height: AppDimensions.spacingSm,
              decoration: BoxDecoration(
                color: colors.outline,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
            ),
          ),
          _RouteRow(
            icon: Icons.location_on_rounded,
            iconColor: colors.driverAccent,
            label: 'DROP',
            address: _drop,
            colors: colors,
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Container(height: 1, color: colors.outlineVariant),
          const SizedBox(height: AppDimensions.spacingMd),
          Row(
            children: [
              Icon(
                Icons.payments_outlined,
                size: AppDimensions.iconSm,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              Text(
                AppStrings.payCash,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                'Collect ₹${_fare.toStringAsFixed(0)} at drop',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: AppConstants.mediumAnimation)
        .slideY(begin: 0.08, end: 0, duration: AppConstants.mediumAnimation);
  }

  Widget _buildBreakdown(AppColorsExtension colors) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Fare breakdown',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
              ),
              StatusChip(
                label: _isFreeTier
                    ? '0% commission'
                    : '${(_rate * 100).toStringAsFixed(0)}% commission',
                status:
                    _isFreeTier ? AppChipStatus.success : AppChipStatus.neutral,
                dense: true,
                showDot: false,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          _BreakdownRow(
            label: 'Base fare',
            value: '₹${_baseFare.toStringAsFixed(0)}',
          ),
          _BreakdownRow(
            label: 'Distance · $_distanceKm km',
            value: '₹${_distanceFare.toStringAsFixed(0)}',
          ),
          _BreakdownRow(
            label: 'Customer tip',
            value: '+ ₹${_tip.toStringAsFixed(0)}',
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(
              vertical: AppDimensions.spacingSm,
            ),
            color: colors.outlineVariant,
          ),
          _BreakdownRow(
            label: 'You take home',
            value: '₹${_payout.toStringAsFixed(0)}',
            highlight: true,
          ),
          if (_isFreeTier)
            Padding(
              padding: const EdgeInsets.only(top: AppDimensions.spacingXxs),
              child: Text(
                'New driver benefit — your first 20 trips pay 0% commission '
                '(${_breakdown['freeTripsRemaining']} trips to go).',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: colors.success,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReliability(AppColorsExtension colors) {
    final model = _reliability;
    if (model == null) {
      return Container(
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.surfaceCard,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    final score = model.compositeScore;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: AppDimensions.avatarLg,
            height: AppDimensions.avatarLg,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.driverAccent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Text(
              score.toStringAsFixed(0),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.driverAccent,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Your reliability score',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                    StatusChip(
                      label: score >= 80 ? 'Strong' : 'Building',
                      status: score >= 80
                          ? AppChipStatus.success
                          : AppChipStatus.info,
                      dense: true,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Acceptance ${model.acceptanceRate.toStringAsFixed(0)}% · '
                  'On-time ${model.onTimeRate.toStringAsFixed(0)}% · '
                  '${model.rating.toStringAsFixed(1)}★ · '
                  '${model.totalTrips} trips',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, AppColorsExtension colors) {
    final accent = colors.driverAccent;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.spacingLg,
        AppDimensions.spacingMd,
        AppDimensions.spacingLg,
        MediaQuery.of(context).padding.bottom + AppDimensions.spacingLg,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isExpired) ...[
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacingMd),
              decoration: BoxDecoration(
                color: colors.errorLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: colors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.hourglass_bottom_rounded,
                    size: AppDimensions.iconSm,
                    color: colors.error,
                  ),
                  const SizedBox(width: AppDimensions.spacingMd),
                  Expanded(
                    child: Text(
                      'This offer is no longer available. Taking you back…',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.spacingMd),
          ],
          Row(
            children: [
              Expanded(
                child: GradientButton(
                  text: AppStrings.accept,
                  leadingIcon: Icons.check_rounded,
                  gradient: LinearGradient(
                    colors: [accent, _accentEnd(accent)],
                  ),
                  onPressed: _isExpired ? null : _accept,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Expanded(
                child: OutlinedPrimaryButton(
                  text: AppStrings.reject,
                  leadingIcon: Icons.close_rounded,
                  height: AppDimensions.buttonHeightLg,
                  borderRadius: AppDimensions.radiusMd,
                  borderColor: colors.error,
                  textColor: colors.error,
                  onPressed: _decline,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          Text(
            'Accepting within the timer keeps your acceptance rate healthy',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: AppConstants.mediumAnimation, delay: 200.ms)
        .slideY(begin: 0.2, end: 0, duration: AppConstants.mediumAnimation);
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppDimensions.iconSm, color: color),
          const SizedBox(height: AppDimensions.spacingSm),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.25,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXxs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.address,
    required this.colors,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String address;
  final AppColorsExtension colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: AppDimensions.iconSm, color: iconColor),
        const SizedBox(width: AppDimensions.spacingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: colors.onSurfaceVariant,
                ),
              ),
              Text(
                address,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: highlight ? FontWeight.w600 : FontWeight.w400,
                color: highlight ? colors.onSurface : colors.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: highlight ? colors.success : colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
