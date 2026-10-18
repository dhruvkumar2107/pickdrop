import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../config/router/route_names.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/constants/colors.dart';
import '../../../../../core/constants/strings.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/widgets/badges.dart';
import '../../../../../core/widgets/cards.dart';
import '../../../../../core/widgets/design_system.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../../../../core/widgets/dialogs/dialogs.dart';
import '../../../../../core/widgets/status_chip.dart';
import '../../../booking/presentation/widgets/anti_extra_cash_sheet.dart';
import '../../../booking/presentation/widgets/free_waiting_timer_widget.dart';
import '../../../home/presentation/widgets/live_activity_notification.dart';
import '../widgets/proof_of_delivery_sheet.dart';
import '../widgets/proactive_alert_service.dart';
import '../widgets/trip_action_row.dart';
import '../widgets/approach_monitoring_card.dart';

class LiveTrackingPage extends StatefulWidget {
  const LiveTrackingPage({
    super.key,
    this.bookingId,
    this.fare,
    this.pickupAddress,
    this.dropAddress,
    this.pickupLat,
    this.pickupLng,
    this.dropLat,
    this.dropLng,
    this.paymentMethod,
  });

  final String? bookingId;
  final double? fare;
  final String? pickupAddress;
  final String? dropAddress;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropLat;
  final double? dropLng;
  final String? paymentMethod;

  @override
  State<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> {
  static const int _lastStep = 6;
  static const Duration _stepDuration = Duration(seconds: 3);
  static const String _defaultPickup = '123 MG Road, Bengaluru 560001';
  static const String _defaultDrop = '456 Koramangala, Bengaluru 560034';
  static const String _driverName = 'Rajesh Kumar';
  static const String _driverInitials = 'RK';
  static const String _vehicleDetails = 'Tata Ace • KA 01 AB 1234';
  static const String _pickupOtp = '4821';

  static const LatLng _pickupPoint = LatLng(12.9716, 77.5946);
  static const LatLng _dropPoint = LatLng(12.9352, 77.6146);
  static const LatLng _driverStart = LatLng(12.9762, 77.5894);
  static const LatLng _cameraCenter = LatLng(12.9548, 77.6026);

  static const List<LatLng> _driverStops = <LatLng>[
    _driverStart,
    LatLng(12.9742, 77.5914),
    _pickupPoint,
    LatLng(12.9640, 77.6005),
    LatLng(12.9530, 77.6070),
    LatLng(12.9440, 77.6110),
    _dropPoint,
  ];

  static const List<LatLng> _routePoints = <LatLng>[
    _pickupPoint,
    LatLng(12.9640, 77.6005),
    LatLng(12.9530, 77.6070),
    LatLng(12.9440, 77.6110),
    _dropPoint,
  ];

  Timer? _timer;
  int _step = 0;
  int _holdTicks = 0;
  Duration _stoppedFor = Duration.zero;
  ProactiveAlert? _proactiveAlert;
  late final DateTime _expectedArrival;

  @override
  void initState() {
    super.initState();
    _expectedArrival = DateTime.now().add(const Duration(minutes: 25));
    _timer = Timer.periodic(_stepDuration, _onTick);
  }

  @override
  void dispose() {
    _timer?.cancel();
    LiveActivityNotification.instance.clear();
    super.dispose();
  }

  void _onTick(Timer timer) {
    if (!mounted) {
      timer.cancel();
      return;
    }

    if (_step >= _lastStep) {
      timer.cancel();
      LiveActivityNotification.instance.clear();
      _goToTripComplete();
      return;
    }

    final holding = _step == 3 && _holdTicks < 2;
    if (holding) {
      _holdTicks += 1;
      _stoppedFor = Duration(minutes: _holdTicks * 2);
    } else {
      setState(() => _step += 1);
      _stoppedFor = Duration.zero;
    }

    _runProactiveChecks();
    LiveActivityNotification.instance.show(
      etaMin: ((_lastStep - _step) * 3).clamp(1, 30),
      driverName: _driverName.split(' ').first,
      status: _step < 3 ? 'On the way to pickup' : 'Heading to your drop',
    );
  }

  void _runProactiveChecks() {
    final current = _driverStops[_step];
    final previous = _driverStops[_step > 0 ? _step - 1 : 0];
    final alerts = const ProactiveAlertService().evaluate(
      driverLat: current.latitude,
      driverLng: current.longitude,
      prevLat: previous.latitude,
      prevLng: previous.longitude,
      isStopped: _holdTicks > 0 && _step == 3,
      stoppedFor: _stoppedFor,
      expectedArrival: _expectedArrival,
      now: DateTime.now(),
    );

    if (alerts.isEmpty || _proactiveAlert != null) return;
    setState(() => _proactiveAlert = alerts.first);
  }

  void _goToTripComplete() {
    if (!mounted) return;

    final fare = (widget.fare ?? 399).toStringAsFixed(0);
    final driver = Uri.encodeComponent(_driverName);
    final payment = Uri.encodeComponent(widget.paymentMethod ?? 'cod');

    context.go('${RouteNames.tripComplete}?fare=$fare&driver=$driver&paymentMethod=$payment');
  }

  String get _status {
    if (_step >= 3) return AppConstants.statusInTransit;
    if (_step == 2) return AppConstants.statusArrived;
    return AppConstants.statusDriverAssigned;
  }

  String get _statusMessage {
    if (_status == AppConstants.statusInTransit) return AppStrings.inTransit;
    if (_status == AppConstants.statusArrived) return AppStrings.driverArrived;
    return AppStrings.driverArriving;
  }

  int get _statusIndex {
    if (_status == AppConstants.statusInTransit) return 2;
    if (_status == AppConstants.statusArrived) return 1;
    return 0;
  }

  String get _etaLabel {
    if (_status == AppConstants.statusArrived) return 'Arriving now';
    if (_status == AppConstants.statusInTransit) return '18 min to drop';
    return '8 min away';
  }

  double get _etaMinutes {
    if (_status == AppConstants.statusArrived) return 0;
    if (_status == AppConstants.statusInTransit) return 18;
    return 8;
  }

  String get _pickupLabel => widget.pickupAddress ?? _defaultPickup;
  String get _dropLabel => widget.dropAddress ?? _defaultDrop;

  void _shareTrip() async {
    final shareText = '''
🚚 PickDrop Trip Tracking

Driver: $_driverName
Vehicle: $_vehicleDetails
Pickup: $_pickupLabel
Drop: $_dropLabel
Status: $_statusMessage
ETA: $_etaLabel

Track live: https://pickdrop.in/track/${widget.pickupLat ?? 12.9716},${widget.pickupLng ?? 77.5946}
''';

    await SharePlus.instance.share(
      ShareParams(
        text: shareText,
        subject: 'Share my PickDrop trip',
      ),
    );
  }

  void _callDriver() {
    AppToast.info(context, 'Calling $_driverName...');
  }

  Future<void> _triggerSOS() async {
    final confirmed = await AppDialog.showConfirmation(
      context: context,
      title: 'Activate SOS?',
      message: 'This will share your live location with your emergency contact and alert support.',
      confirmText: 'Yes, activate SOS',
      isDestructive: true,
    );

    if (!mounted) return;
    if (confirmed ?? false) {
      AppToast.success(context, 'SOS activated! Emergency contact notified with your location.');
      final uri = Uri(scheme: 'tel', path: '112');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  void _showProofFlow() {
    final isPickup = _statusIndex < 2;
    ProofOfDeliverySheet.show(
      context,
      bookingId: widget.bookingId ?? 'PD_ACTIVE',
      isPickup: isPickup,
      onProofCompleted: () {
        if (!mounted) return;
        AppToast.success(
          context,
          isPickup ? 'Pickup proof verified successfully' : 'Delivery proof recorded successfully',
        );
      },
    );
  }

  Future<void> _cancelTrip() async {
    final confirmed = await AppDialog.showConfirmation(
      context: context,
      title: 'Cancel this trip?',
      message: 'Your driver is already on the way. A ₹50 fee applies after assignment.',
      confirmText: 'Cancel trip',
      isDestructive: true,
    );

    if (!mounted) return;
    if (confirmed ?? false) {
      _timer?.cancel();
      context.go(RouteNames.customerHome);
    }
  }

  Set<Marker> _buildMarkers() {
    return {
      Marker(
        markerId: const MarkerId('pickup'),
        position: _pickupPoint,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueGreen,
        ),
        infoWindow: InfoWindow(title: 'Pickup', snippet: _pickupLabel),
      ),
      Marker(
        markerId: const MarkerId('drop'),
        position: _dropPoint,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: 'Drop', snippet: _dropLabel),
      ),
      Marker(
        markerId: const MarkerId('driver'),
        position: _driverStops[_step],
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueOrange,
        ),
        infoWindow: const InfoWindow(title: 'Driver'),
      ),
    };
  }

  Set<Polyline> _buildPolylines(AppColorsExtension colors) {
    return {
      Polyline(
        polylineId: const PolylineId('approach'),
        points: const [_driverStart, _pickupPoint],
        color: colors.primary.withValues(alpha: 0.5),
        width: 3,
        patterns: [PatternItem.dash(14), PatternItem.gap(8)],
      ),
      Polyline(
        polylineId: const PolylineId('route'),
        points: _routePoints,
        color: colors.primary,
        width: 5,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    };
  }

  Widget _buildStep(
    AppColorsExtension colors, {
    required int index,
    required String label,
  }) {
    final done = index < _statusIndex;
    final current = index == _statusIndex;

    return Expanded(
      flex: 2,
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done
                  ? colors.success
                  : current
                      ? colors.primary
                      : colors.surfaceVariant,
            ),
            child: done
                ? Icon(
                    Icons.check_rounded,
                    size: DesignTokens.iconXs,
                    color: colors.onPrimary,
                  )
                : Text(
                    '${index + 1}',
                    style: TokenTextStyles.labelSmall(
                      color: current ? colors.onPrimary : colors.onSurfaceVariant,
                    ),
                  ),
          ),
          SizedBox(height: DesignTokens.spacingXxs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TokenTextStyles.labelSmall(
              color: done || current
                  ? colors.onSurface
                  : colors.onSurfaceVariant,
              fontWeight: done || current ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _cameraCenter,
              zoom: AppConstants.defaultMapZoom,
            ),
            markers: _buildMarkers(),
            polylines: _buildPolylines(colors),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTopBar(context, colors),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    DesignTokens.spacingLg,
                    DesignTokens.spacingSm,
                    DesignTokens.spacingLg,
                    0,
                  ),
                  child: _buildDriverPanel(context, colors),
                ),
                AnimatedSwitcher(
                  duration: DesignTokens.durationNormal,
                  switchInCurve: DesignTokens.springSmooth,
                  child: _status == AppConstants.statusInTransit
                      ? const SizedBox.shrink(key: ValueKey<String>('no-otp'))
                      : Padding(
                          key: const ValueKey<String>('otp'),
                          padding: EdgeInsets.fromLTRB(
                            DesignTokens.spacingLg,
                            DesignTokens.spacingMd,
                            DesignTokens.spacingLg,
                            0,
                          ),
                          child: _buildOtpCard(context, colors),
                        ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    DesignTokens.spacingLg,
                    DesignTokens.spacingMd,
                    DesignTokens.spacingLg,
                    0,
                  ),
                  child: TripActionRow(bookingId: widget.bookingId),
                ),
                if (_proactiveAlert != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      DesignTokens.spacingLg,
                      DesignTokens.spacingMd,
                      DesignTokens.spacingLg,
                      0,
                    ),
                    child: ProactiveAlertDialog(
                      key: ValueKey<String>(_proactiveAlert!.id),
                      alert: _proactiveAlert!,
                      onDismiss: () => setState(() => _proactiveAlert = null),
                      onAction: (action) {
                        switch (action) {
                          case ProactiveAlertAction.chatWithDriver:
                            context.push(
                              '${RouteNames.chat}?bookingId=${Uri.encodeComponent(widget.bookingId ?? 'active')}&peerName=Driver&role=driver',
                            );
                          case ProactiveAlertAction.callSupport:
                            context.push(
                              '${RouteNames.helpSupport}?bookingId=${Uri.encodeComponent(widget.bookingId ?? 'active')}&tripLabel=Live%20delivery',
                            );
                          case ProactiveAlertAction.autoRematch:
                            AppToast.success(
                              context,
                              'Re-matching you with a closer driver, priority boost applied.',
                            );
                            setState(() => _proactiveAlert = null);
                        }
                      },
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    DesignTokens.spacingLg,
                    DesignTokens.spacingSm,
                    DesignTokens.spacingLg,
                    0,
                  ),
                  child: ApproachMonitoringCard(
                    initialEtaMinutes: _etaMinutes,
                    isDriverStopped: _status == AppConstants.statusArrived,
                    onContactSupport: () => context.go(
                      '${RouteNames.helpSupport}?bookingId=${Uri.encodeComponent(widget.bookingId ?? 'active')}&tripLabel=Live%20delivery',
                    ),
                  ),
                ),
                const Spacer(),
                _buildBottomBar(context, colors),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, AppColorsExtension colors) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.spacingMd,
        DesignTokens.spacingSm,
        DesignTokens.spacingLg,
        DesignTokens.spacingXs,
      ),
      child: Row(
        children: [
          PDCard(
            variant: PDCardVariant.glass,
            padding: EdgeInsets.all(DesignTokens.spacingXs),
            radius: DesignTokens.radiusFull,
            onTap: () => context.pop(),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: DesignTokens.iconSm,
              color: colors.onSurface,
            ),
          ),
          SizedBox(width: DesignTokens.spacingMd),
          StatusChip.fromStatus(
            _status,
            label: _statusMessage,
          ),
          const Spacer(),
          PDCard(
            variant: PDCardVariant.glass,
            padding: EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingMd,
              vertical: DesignTokens.spacingXs,
            ),
            radius: DesignTokens.radiusFull,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.currency_rupee_rounded,
                  size: DesignTokens.iconXs,
                  color: colors.primary,
                ),
                const SizedBox(width: 2),
                Text(
                  (widget.fare ?? 399).toStringAsFixed(0),
                  style: TokenTextStyles.titleSmall(
                    color: colors.onSurface,
                    weight: DesignTokens.wBold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverPanel(BuildContext context, AppColorsExtension colors) {
    return PDCard(
      variant: PDCardVariant.glass,
      padding: EdgeInsets.all(DesignTokens.spacingMd),
      showShadow: true,
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: colors.primaryContainer,
            child: Text(
              _driverInitials,
              style: TokenTextStyles.titleMedium(
                color: colors.primary,
                weight: DesignTokens.wBold,
              ),
            ),
          ),
          SizedBox(width: DesignTokens.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _driverName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TokenTextStyles.titleMedium(color: colors.onSurface),
                      ),
                    ),
                    SizedBox(width: DesignTokens.spacingXs),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacingXs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.successLight,
                        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                      ),
                      child: Text(
                        'PRO',
                        style: TokenTextStyles.labelSmall(
                          color: colors.success,
                          weight: DesignTokens.wBold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2),
                Text(
                  _vehicleDetails,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TokenTextStyles.bodySmall(color: colors.onSurfaceVariant),
                ),
                SizedBox(height: DesignTokens.spacingXxs),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: Colors.amber,
                    ),
                    SizedBox(width: DesignTokens.spacingXxs),
                    Text(
                      '4.9',
                      style: TokenTextStyles.labelMedium(color: colors.onSurface),
                    ),
                    SizedBox(width: DesignTokens.spacingSm),
                    Text(
                      '2,184 trips',
                      style: TokenTextStyles.labelMedium(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PDCard(
            variant: PDCardVariant.glass,
            padding: EdgeInsets.all(DesignTokens.spacingXs),
            radius: DesignTokens.radiusFull,
            onTap: _shareTrip,
            child: Icon(
              Icons.share_outlined,
              size: DesignTokens.iconSm,
              color: colors.onSurface,
            ),
          ),
          SizedBox(width: DesignTokens.spacingSm),
          PDButton(
            text: '',
            leadingIcon: Icons.call_rounded,
            variant: PDButtonVariant.primary,
            size: PDButtonSize.sm,
            onPressed: _callDriver,
          ),
        ],
      ),
    );
  }

  Widget _buildOtpCard(BuildContext context, AppColorsExtension colors) {
    return PDCard(
      variant: PDCardVariant.glass,
      padding: EdgeInsets.all(DesignTokens.spacingLg),
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.pin_outlined,
                size: DesignTokens.iconSm,
                color: colors.primary,
              ),
              SizedBox(width: DesignTokens.spacingSm),
              Text(
                AppStrings.pickupOtp,
                style: TokenTextStyles.titleMedium(color: colors.onSurface),
              ),
              const Spacer(),
              PDBadge(
                label: _etaLabel,
                variant: PDBadgeVariant.info,
                size: PDBadgeSize.sm,
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spacingMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              return Container(
                width: 52,
                height: 56,
                margin: EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingXs,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  _pickupOtp[index],
                  style: TokenTextStyles.priceSmall(
                    color: colors.onSurface,
                    letterSpacing: 2,
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: DesignTokens.spacingMd),
          Center(
            child: Text(
              'Share this code with the driver to start the trip',
              textAlign: TextAlign.center,
              style: TokenTextStyles.bodySmall(color: colors.onSurfaceVariant),
            ),
          ),
          SizedBox(height: DesignTokens.spacingMd),
          FreeWaitingTimerWidget(
            freeMinutes: 10,
            perMinuteCharge: 3.0,
            isDrop: _statusIndex >= 2,
          ),
          SizedBox(height: DesignTokens.spacingSm),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                AntiExtraCashSheet.show(
                  context,
                  bookingId: widget.bookingId ?? 'PD_ACTIVE',
                  driverName: _driverName,
                );
              },
              icon: Icon(Icons.shield_outlined, size: 14, color: colors.error),
              label: Text(
                'Driver asked for extra cash?',
                style: TokenTextStyles.labelSmall(
                  color: colors.error,
                  weight: DesignTokens.wBold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, AppColorsExtension colors) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.spacingLg,
        DesignTokens.spacingLg,
        DesignTokens.spacingLg,
        DesignTokens.spacingSm,
      ),
      child: PDCard(
        variant: PDCardVariant.glass,
        padding: EdgeInsets.all(DesignTokens.spacingLg),
        radius: DesignTokens.radiusXl,
        showShadow: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _buildStep(
                  colors,
                  index: 0,
                  label: AppStrings.driverArriving,
                ),
                _buildConnector(colors, index: 0),
                _buildStep(
                  colors,
                  index: 1,
                  label: AppStrings.driverArrived,
                ),
                _buildConnector(colors, index: 1),
                _buildStep(
                  colors,
                  index: 2,
                  label: AppStrings.inTransit,
                ),
              ],
            ),
            SizedBox(height: DesignTokens.spacingMd),
            ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
              child: LinearProgressIndicator(
                value: (_step / _lastStep).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: colors.surfaceVariant,
                color: colors.primary,
              ),
            ),
            SizedBox(height: DesignTokens.spacingMd),
            Row(
              children: [
                Expanded(
                  child: PDButton(
                    text: 'SOS',
                    leadingIcon: Icons.emergency_outlined,
                    variant: PDButtonVariant.destructive,
                    size: PDButtonSize.md,
                    onPressed: _triggerSOS,
                  ),
                ),
                SizedBox(width: DesignTokens.spacingMd),
                Expanded(
                  child: PDButton(
                    text: AppStrings.shareTrip,
                    leadingIcon: Icons.share_outlined,
                    variant: PDButtonVariant.outline,
                    size: PDButtonSize.md,
                    onPressed: _shareTrip,
                  ),
                ),
                SizedBox(width: DesignTokens.spacingMd),
                Expanded(
                  child: PDButton(
                    text: AppStrings.callDriver,
                    leadingIcon: Icons.call_rounded,
                    variant: PDButtonVariant.primary,
                    size: PDButtonSize.md,
                    onPressed: _callDriver,
                  ),
                ),
              ],
            ),
            SizedBox(height: DesignTokens.spacingXs),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: _showProofFlow,
                  child: Text(
                    _statusIndex >= 2 ? 'Proof of delivery' : 'Capture pickup proof',
                    style: TokenTextStyles.labelLarge(color: colors.primary),
                  ),
                ),
                SizedBox(width: DesignTokens.spacingSm),
                TextButton(
                  onPressed: _cancelTrip,
                  child: Text(
                    'Cancel trip',
                    style: TokenTextStyles.labelLarge(color: colors.error),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnector(AppColorsExtension colors, {required int index}) {
    final filled = index < _statusIndex;

    return Expanded(
      flex: 1,
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: DesignTokens.spacingMd + 4),
        decoration: BoxDecoration(
          color: filled ? colors.success : colors.outline,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
