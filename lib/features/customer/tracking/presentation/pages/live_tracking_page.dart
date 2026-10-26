import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../config/router/route_names.dart';
import '../../../../../config/env/env_config.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/constants/colors.dart';
import '../../../../../core/constants/strings.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/utils/helpers.dart';
import '../../../../../core/widgets/badges.dart';
import '../../../../../core/widgets/cards.dart';
import '../../../../../core/widgets/design_system.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../../../../core/widgets/dialogs/dialogs.dart';
import '../../../../../core/widgets/status_chip.dart';
import '../../../booking/presentation/widgets/anti_extra_cash_sheet.dart';
import '../../../booking/data/datasources/booking_remote_datasource.dart';
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
  static const String _defaultPickup = '123 MG Road, Bengaluru 560001';
  static const String _defaultDrop = '456 Koramangala, Bengaluru 560034';
  LatLng get _pickupPoint =>
      LatLng(widget.pickupLat ?? 12.9716, widget.pickupLng ?? 77.5946);
  LatLng get _dropPoint =>
      LatLng(widget.dropLat ?? 12.9352, widget.dropLng ?? 77.6146);
  LatLng? _driverPoint;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _bookingSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _secretsSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _driverSub;
  int _step = 0;
  ProactiveAlert? _proactiveAlert;
  String _bookingStatus = 'SEARCHING';
  String _driverName = 'Your driver';
  String _driverId = '';
  String get _driverInitials {
    final parts = _driverName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty);
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  String _vehicleDetails = '';
  String _driverPhone = '';
  String _pickupOtp = '';
  String _dropOtp = '';
  List<Map<String, dynamic>> _intermediateStops = [];
  Map<String, String> _stopOtps = {};
  bool _completedRoute = false;

  @override
  void initState() {
    super.initState();
    final bookingId = widget.bookingId;
    if (bookingId != null && bookingId.isNotEmpty) {
      _bookingSub = FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .snapshots()
          .listen(
            _onBookingSnapshot,
            onError: (Object error) {
              if (mounted) {
                AppToast.error(
                  context,
                  'Could not load this delivery. Check your connection.',
                );
              }
            },
          );
      _secretsSub = FirebaseFirestore.instance
          .collection('bookingSecrets')
          .doc(bookingId)
          .snapshots()
          .listen(
            (secretDoc) {
              final secrets = secretDoc.data();
              if (!mounted || secrets == null) return;
              final stopCodes = secrets['intermediateStopOtps'];
              setState(() {
                _pickupOtp = (secrets['pickupOtp'] as String?) ?? '';
                _dropOtp = (secrets['dropOtp'] as String?) ?? '';
                _stopOtps = stopCodes is Map
                    ? stopCodes.map(
                        (key, value) =>
                            MapEntry(key.toString(), value.toString()),
                      )
                    : {};
              });
            },
            onError: (Object error) {
              if (mounted) {
                AppToast.error(
                  context,
                  'Could not load delivery verification codes.',
                );
              }
            },
          );
    }
  }

  @override
  void dispose() {
    _bookingSub?.cancel();
    _secretsSub?.cancel();
    _driverSub?.cancel();
    LiveActivityNotification.instance.clear();
    super.dispose();
  }

  void _onBookingSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null || !mounted) return;
    final status = (data['status'] as String? ?? '').toUpperCase();
    final pickupData = data['pickup'];
    final dropData = data['drop'];
    final stops = (data['intermediateStops'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final driverId = data['driverId'] as String?;
    setState(() {
      _bookingStatus = status;
      _pickupOtp = pickupData is Map
          ? (pickupData['otp'] as String? ?? _pickupOtp)
          : _pickupOtp;
      _dropOtp = dropData is Map
          ? (dropData['otp'] as String? ?? _dropOtp)
          : _dropOtp;
      _intermediateStops = stops;
      if (driverId != null && driverId.isNotEmpty) _driverId = driverId;
      _step = switch (status) {
        'DRIVER_ASSIGNED' => 0,
        'PICKED_UP' || 'IN_TRANSIT' => 3,
        'DELIVERED' => _lastStep,
        _ => 0,
      };
    });
    if (driverId != null && driverId.isNotEmpty && _driverSub == null) {
      _driverSub = FirebaseFirestore.instance
          .collection('drivers')
          .doc(driverId)
          .snapshots()
          .listen((driverDoc) {
            final driver = driverDoc.data();
            if (!mounted || driver == null) return;
            final loc = driver['currentLocation'];
            setState(() {
              if (loc is GeoPoint) {
                _driverPoint = LatLng(loc.latitude, loc.longitude);
              }
              _vehicleDetails =
                  [driver['vehicleModel'], driver['vehicleNumber']]
                      .whereType<String>()
                      .where((value) => value.isNotEmpty)
                      .join(' • ');
            });
            FirebaseFirestore.instance
                .collection('users')
                .doc(driverId)
                .get()
                .then((userDoc) {
                  if (!mounted) return;
                  final user = userDoc.data();
                  if (user != null) {
                    setState(() {
                      _driverName =
                          user['displayName'] as String? ?? 'Your driver';
                      _driverPhone = user['phoneNumber'] as String? ?? '';
                    });
                  }
                });
          });
    }
    if (status == 'DELIVERED' && !_completedRoute) {
      _completedRoute = true;
      LiveActivityNotification.instance.clear();
      _goToTripComplete(data);
    } else if (status == 'CANCELLED' || status == 'NO_DRIVER_FOUND') {
      LiveActivityNotification.instance.clear();
      context.go(RouteNames.customerHome);
    } else {
      LiveActivityNotification.instance.show(
        etaMin: _etaMinutes.round().clamp(0, 60),
        driverName: _driverName.split(' ').first,
        status: _statusMessage,
      );
    }
  }

  void _goToTripComplete([Map<String, dynamic>? booking]) {
    if (!mounted) return;

    final breakdown = booking?['fareBreakdown'];
    final savedFare = breakdown is Map ? breakdown['total'] : null;
    final fare = ((savedFare as num?)?.toDouble() ?? widget.fare ?? 0)
        .toStringAsFixed(0);
    final driver = Uri.encodeComponent(_driverName);
    final payment = Uri.encodeComponent(widget.paymentMethod ?? 'cod');

    context.go(
      '${RouteNames.tripComplete}?fare=$fare&driver=$driver&paymentMethod=$payment&bookingId=${Uri.encodeComponent(widget.bookingId ?? '')}&driverId=${Uri.encodeComponent(_driverId)}',
    );
  }

  String get _status {
    if (_bookingStatus == 'PICKED_UP' || _bookingStatus == 'IN_TRANSIT') {
      return AppConstants.statusInTransit;
    }
    if (_bookingStatus == 'DRIVER_ASSIGNED') {
      return AppConstants.statusDriverAssigned;
    }
    return 'Searching';
  }

  String get _statusMessage {
    if (_status == AppConstants.statusInTransit) return AppStrings.inTransit;
    return AppStrings.driverArriving;
  }

  int get _statusIndex {
    if (_status == AppConstants.statusInTransit) return 2;
    return 0;
  }

  String get _etaLabel {
    if (_status == AppConstants.statusInTransit) return 'Delivery in progress';
    if (_status == AppConstants.statusDriverAssigned) return 'Driver assigned';
    return 'Finding a driver';
  }

  double get _etaMinutes {
    final driver = _driverPoint;
    if (driver == null) return 0;
    final target = _status == AppConstants.statusInTransit
        ? _dropPoint
        : _pickupPoint;
    final metres = AppHelpers.calculateDistance(
      driver.latitude,
      driver.longitude,
      target.latitude,
      target.longitude,
    );
    // Assume ~25 km/h average city speed for a light delivery vehicle.
    const metresPerMinute = 25 * 1000 / 60;
    final minutes = metres / metresPerMinute;
    if (!minutes.isFinite || minutes < 0) return 0;
    return minutes;
  }

  String get _pickupLabel => widget.pickupAddress ?? _defaultPickup;
  String get _dropLabel => widget.dropAddress ?? _defaultDrop;

  Future<void> _shareTrip() async {
    final bookingId = widget.bookingId;
    if (bookingId == null || bookingId.isEmpty) {
      AppToast.error(context, 'This trip cannot be shared right now.');
      return;
    }
    try {
      final response = await FirebaseFunctions.instanceFor(
        region: EnvConfig.functionsRegion,
      )
          .httpsCallable('createPublicTrackingLink')
          .call({'bookingId': bookingId});
      final token = Map<String, dynamic>.from(response.data as Map)['token'] as String;
      final trackingUrl = '${EnvConfig.trackingBaseUrl}/track/$token';
      final shareText = '''
🚚 PickDrop Trip Tracking

Driver: $_driverName
Vehicle: $_vehicleDetails
Pickup: $_pickupLabel
Drop: $_dropLabel
Status: $_statusMessage
ETA: $_etaLabel

Track live: $trackingUrl
''';
      await SharePlus.instance.share(
        ShareParams(text: shareText, subject: 'Share my PickDrop trip'),
      );
    } catch (_) {
      if (mounted) AppToast.error(context, 'Could not create a tracking link. Try again.');
    }
  }

  void _callDriver() {
    if (_driverPhone.isEmpty) {
      AppToast.info(context, 'The driver has not shared a call number.');
      return;
    }
    launchUrl(Uri(scheme: 'tel', path: _driverPhone));
  }

  Future<void> _triggerSOS() async {
    final confirmed = await AppDialog.showConfirmation(
      context: context,
      title: 'Activate SOS?',
      message: 'PickDrop safety will be alerted with this trip and your location, then your phone will call 112.',
      confirmText: 'Yes, activate SOS',
      isDestructive: true,
    );

    if (!mounted || !(confirmed ?? false)) return;
    var alertRecorded = false;
    try {
      final payload = <String, dynamic>{};
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final position = await Geolocator.getLastKnownPosition();
        if (position != null) {
          payload['latitude'] = position.latitude;
          payload['longitude'] = position.longitude;
        }
      }
      await FirebaseFunctions.instanceFor(region: EnvConfig.functionsRegion)
          .httpsCallable('createSosAlert')
          .call(payload)
          .timeout(const Duration(seconds: 5));
      alertRecorded = true;
    } catch (_) {
      // The emergency call must still proceed if connectivity or location fails.
    }
    await launchUrl(
      Uri(scheme: 'tel', path: '112'),
      mode: LaunchMode.externalApplication,
    );
    if (!mounted) return;
    AppToast.warning(
      context,
      alertRecorded
          ? 'Safety alert recorded. Calling 112 now.'
          : 'Calling 112 now. Network alert could not be recorded.',
    );
  }

  void _showProofFlow() {
    final bookingId = widget.bookingId;
    if (bookingId == null || bookingId.isEmpty) return;
    ProofOfDeliverySheet.show(context, bookingId: bookingId);
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
      try {
        await BookingRemoteDataSource().cancelBooking(widget.bookingId ?? '');
        if (mounted) context.go(RouteNames.customerHome);
      } catch (_) {
        if (mounted) {
          AppToast.error(
            context,
            'Could not cancel. Check your connection and try again.',
          );
        }
      }
    }
  }

  Set<Marker> _buildMarkers() {
    return {
      Marker(
        markerId: const MarkerId('pickup'),
        position: _pickupPoint,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: 'Pickup', snippet: _pickupLabel),
      ),
      Marker(
        markerId: const MarkerId('drop'),
        position: _dropPoint,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: 'Drop', snippet: _dropLabel),
      ),
      if (_driverPoint != null)
        Marker(
          markerId: const MarkerId('driver'),
          position: _driverPoint!,
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
        points: [_driverPoint ?? _pickupPoint, _pickupPoint],
        color: colors.primary.withValues(alpha: 0.5),
        width: 3,
        patterns: [PatternItem.dash(14), PatternItem.gap(8)],
      ),
      Polyline(
        polylineId: const PolylineId('route'),
        points: [_pickupPoint, _dropPoint],
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
                      color: current
                          ? colors.onPrimary
                          : colors.onSurfaceVariant,
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
            initialCameraPosition: CameraPosition(
              target: LatLng(
                (_pickupPoint.latitude + _dropPoint.latitude) / 2,
                (_pickupPoint.longitude + _dropPoint.longitude) / 2,
              ),
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
          StatusChip.fromStatus(_status, label: _statusMessage),
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
                        style: TokenTextStyles.titleMedium(
                          color: colors.onSurface,
                        ),
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
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusFull,
                        ),
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
                  style: TokenTextStyles.bodySmall(
                    color: colors.onSurfaceVariant,
                  ),
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
                      style: TokenTextStyles.labelMedium(
                        color: colors.onSurface,
                      ),
                    ),
                    SizedBox(width: DesignTokens.spacingSm),
                    Text(
                      '2,184 trips',
                      style: TokenTextStyles.labelMedium(
                        color: colors.onSurfaceVariant,
                      ),
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
    final pendingStops = _intermediateStops
        .where((s) => s['otpVerified'] != true)
        .toList();
    final Map<String, dynamic>? pendingStop = pendingStops.isEmpty
        ? null
        : pendingStops.first;
    final showingPickup = _bookingStatus == 'DRIVER_ASSIGNED';
    final showingStop = !showingPickup && pendingStop != null;
    final shownCode = showingPickup
        ? _pickupOtp
        : showingStop
        ? (_stopOtps['${pendingStop['sequence']}'] ?? '')
        : _dropOtp;
    final codeLabel = showingPickup
        ? 'Pickup verification code'
        : showingStop
        ? 'Stop ${pendingStop['sequence']} delivery code'
        : 'Final delivery code';
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
                codeLabel,
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
                  index < shownCode.length ? shownCode[index] : '–',
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
              showingPickup
                  ? 'Share this code with the driver to start the trip'
                  : showingStop
                  ? 'Share this code when the driver reaches ${pendingStop['address'] ?? 'the stop'}'
                  : 'Share this code when the delivery reaches its final destination',
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
                _buildStep(colors, index: 0, label: AppStrings.driverArriving),
                _buildConnector(colors, index: 0),
                _buildStep(colors, index: 1, label: AppStrings.driverArrived),
                _buildConnector(colors, index: 1),
                _buildStep(colors, index: 2, label: AppStrings.inTransit),
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
                    'Goods photos',
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
