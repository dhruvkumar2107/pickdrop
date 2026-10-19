import 'dart:async';
import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/env/env_config.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/strings.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_toast.dart';

class SosButton extends StatefulWidget {
  const SosButton({super.key});

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton>
    with SingleTickerProviderStateMixin {
  static const String sosEventKey = 'last_sos_event';

  static const double ringSize = DesignTokens.avatarXxl;

  late final AnimationController _holdController;

  bool _firing = false;

  @override
  void initState() {
    super.initState();
    _holdController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..addStatusListener(_onHoldStatus);
  }

  @override
  void dispose() {
    _holdController.dispose();
    super.dispose();
  }

  void _onHoldStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_firing) {
      _firing = true;
      unawaited(_fireSos());
    }
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_firing) return;
    HapticFeedback.selectionClick();
    _holdController.forward();
  }

  void _onPointerUp(PointerUpEvent event) => _release();

  void _onPointerCancel(PointerCancelEvent event) => _release();

  void _release() {
    _firing = false;
    _holdController.reset();
  }

  Future<void> _fireSos() async {
    HapticFeedback.heavyImpact();
    final event = await _captureMetadata();
    await _persistEvent(event);
    unawaited(_sendReport(event));
    if (!mounted) return;
    AppToast.error(context, '${AppStrings.sosActivated} — ${AppStrings.sosMessage}');
    unawaited(_dialEmergency());
  }

  Future<Map<String, dynamic>> _captureMetadata() async {
    double? lat;
    double? lng;
    try {
      final position = await Geolocator.getLastKnownPosition();
      lat = position?.latitude;
      lng = position?.longitude;
    } catch (_) {
      lat = null;
      lng = null;
    }
    return <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'lat': lat,
      'lng': lng,
      'driverId': FirebaseAuth.instance.currentUser?.uid ?? '',
    };
  }

  Future<void> _persistEvent(Map<String, dynamic> event) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(sosEventKey, jsonEncode(event));
    } catch (_) {
      return;
    }
  }

  Future<void> _sendReport(Map<String, dynamic> event) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final lat = event['lat'];
    final lng = event['lng'];
    try {
      final callable = FirebaseFunctions.instanceFor(
        region: EnvConfig.functionsRegion,
      ).httpsCallable('createSosAlert');
      await callable.call(<String, dynamic>{
        if (lat is double) 'latitude': lat,
        if (lng is double) 'longitude': lng,
        'note': 'Driver SOS',
      });
    } catch (_) {
      return;
    }
  }

  Future<void> _dialEmergency() async {
    final uri = Uri.parse('tel:112');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      AppToast.warning(context, 'Could not open the dialer. Please call 112 manually.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingLg),
      decoration: BoxDecoration(
        color: colors.errorLight,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(color: colors.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRing(colors),
          const SizedBox(width: DesignTokens.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppStrings.sos} · Emergency help',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.error,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingXs),
                Text(
                  'Hold the button for 2 seconds to alert PickDrop support, '
                  'share your live location and open the dialer for 112.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    height: 1.4,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingSm),
                const _NightTripSwitch(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRing(AppColorsExtension colors) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: AnimatedBuilder(
        animation: _holdController,
        builder: (context, child) {
          return SizedBox(
            width: ringSize,
            height: ringSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(ringSize, ringSize),
                  painter: _RingPainter(
                    progress: _holdController.value,
                    trackColor: colors.error.withValues(alpha: 0.18),
                    progressColor: colors.error,
                  ),
                ),
                child!,
              ],
            ),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emergency_rounded,
              size: DesignTokens.iconLg,
              color: colors.error,
            ),
            const SizedBox(height: DesignTokens.spacingXs),
            Text(
              'HOLD',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: colors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  final double progress;

  final Color trackColor;

  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - 6) / 2;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);
    if (progress <= 0) return;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = progressColor;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5707963267948966,
      progress * 6.283185307179586,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.progressColor != progressColor;
}

class _NightTripSwitch extends StatefulWidget {
  const _NightTripSwitch();

  @override
  State<_NightTripSwitch> createState() => _NightTripSwitchState();
}

class _NightTripSwitchState extends State<_NightTripSwitch> {
  static const String nightTripKey = 'night_trip_alerts_enabled';

  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() => _enabled = prefs.getBool(nightTripKey) ?? false);
    } catch (_) {
      _enabled = false;
    }
  }

  Future<void> _toggle(bool value) async {
    setState(() => _enabled = value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(nightTripKey, value);
    } catch (_) {
      return;
    }
    if (!mounted) return;
    AppToast.info(
      context,
      value
          ? 'Night trip alerts on — extra check-ins between 10 PM and 5 AM'
          : 'Night trip alerts off',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Icon(
          Icons.nightlight_round,
          size: DesignTokens.iconSm,
          color: colors.info,
        ),
        const SizedBox(width: DesignTokens.spacingSm),
        Expanded(
          child: Text(
            'Night trip alerts (10 PM – 5 AM)',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        Switch(
          value: _enabled,
          onChanged: _toggle,
          activeTrackColor: colors.primary,
          inactiveTrackColor: colors.surfaceVariant,
        ),
      ],
    );
  }
}
