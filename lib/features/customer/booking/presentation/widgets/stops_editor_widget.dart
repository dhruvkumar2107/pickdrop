import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../../core/constants/colors.dart';
import '../../../../../core/constants/dimensions.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../../../../core/widgets/glass_card.dart';

class DeliveryStop {
  const DeliveryStop({
    required this.id,
    required this.label,
    required this.otp,
    this.lat = 0,
    this.lng = 0,
  });

  final String id;
  final String label;
  final String otp;
  final double lat;
  final double lng;

  bool get hasPosition => lat != 0 || lng != 0;

  DeliveryStop copyWith({String? label, double? lat, double? lng}) =>
      DeliveryStop(
        id: id,
        label: label ?? this.label,
        otp: otp,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
      );
}

class StopsEditorWidget extends StatelessWidget {
  const StopsEditorWidget({
    super.key,
    required this.value,
    required this.onChanged,
    this.baseDistanceKm = 0,
  });

  static const int maxStops = 5;
  static const double kmPerStop = 3.5;
  static const double farePerStop = 65;

  final List<DeliveryStop> value;
  final ValueChanged<List<DeliveryStop>> onChanged;
  final double baseDistanceKm;

  static DeliveryStop createStop() {
    final otp = Random().nextInt(10000).toString().padLeft(4, '0');
    return DeliveryStop(
      id: 'stop_${DateTime.now().microsecondsSinceEpoch}',
      label: '',
      otp: otp,
    );
  }

  static List<DeliveryStop> optimise(
    List<DeliveryStop> stops, {
    double fromLat = 0,
    double fromLng = 0,
  }) {
    if (stops.length < 2) return List<DeliveryStop>.of(stops);
    final positioned = [for (final stop in stops) if (stop.hasPosition) stop];
    final others = [for (final stop in stops) if (!stop.hasPosition) stop];
    if (positioned.length < 2) return List<DeliveryStop>.of(stops);
    final remaining = [...positioned];
    final ordered = <DeliveryStop>[];
    var cx = fromLat;
    var cy = fromLng;
    if (cx == 0 && cy == 0) {
      final seed = remaining.removeAt(0);
      ordered.add(seed);
      cx = seed.lat;
      cy = seed.lng;
    }
    while (remaining.isNotEmpty) {
      var bestIndex = 0;
      var bestDistance = double.infinity;
      for (var i = 0; i < remaining.length; i++) {
        final distance = _haversineKm(cx, cy, remaining[i].lat, remaining[i].lng);
        if (distance < bestDistance) {
          bestDistance = distance;
          bestIndex = i;
        }
      }
      final next = remaining.removeAt(bestIndex);
      ordered.add(next);
      cx = next.lat;
      cy = next.lng;
    }
    return [...ordered, ...others];
  }

  static double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    return earthRadiusKm * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _toRad(double degrees) => degrees * pi / 180;

  static double _routeKm(
    List<DeliveryStop> stops, {
    double fromLat = 0,
    double fromLng = 0,
  }) {
    var total = 0.0;
    var cx = fromLat;
    var cy = fromLng;
    for (final stop in stops) {
      if (!stop.hasPosition) continue;
      total += _haversineKm(cx, cy, stop.lat, stop.lng);
      cx = stop.lat;
      cy = stop.lng;
    }
    return total;
  }

  static double _minutes(double km, int stops) => km / 30 * 60 + stops;

  void _emit(List<DeliveryStop> next) => onChanged(List.unmodifiable(next));

  void _optimise(BuildContext context) {
    if (!value.any((stop) => stop.hasPosition)) {
      AppToast.info(context, 'Add stop locations to optimise the route');
      return;
    }
    final origin = value.firstWhere((stop) => stop.hasPosition);
    final next = optimise(value, fromLat: origin.lat, fromLng: origin.lng);
    final changed =
        next.map((stop) => stop.id).join('|') != value.map((stop) => stop.id).join('|');
    if (!changed) {
      AppToast.info(context, 'Route already optimal');
      return;
    }
    final before = _routeKm(value, fromLat: origin.lat, fromLng: origin.lng);
    final after = _routeKm(next, fromLat: origin.lat, fromLng: origin.lng);
    final saved = (_minutes(before, value.length) - _minutes(after, next.length))
        .round()
        .clamp(1, 999);
    _emit(next);
    AppToast.success(context, 'Route optimised — saves ~$saved min');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final totalKm = baseDistanceKm + value.length * kmPerStop;

    return GlassCard(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route_rounded, size: AppDimensions.iconSm, color: colors.primary),
              const SizedBox(width: AppDimensions.spacingSm),
              Expanded(
                child: Text(
                  'Intermediate stops',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelLarge.copyWith(color: colors.onSurface),
                ),
              ),
              if (value.length > 1)
                TextButton(
                  onPressed: () => _optimise(context),
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.spacingSm),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  child: Text(
                    'Optimise route',
                    style: AppTextStyles.labelSmall.copyWith(color: colors.primary),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingSm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Text(
                  '${value.length}/$maxStops',
                  style: AppTextStyles.labelSmall.copyWith(color: colors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          if (value.isEmpty)
            Text(
              'Add up to 5 stops — each gets its own OTP for proof of delivery.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: colors.onSurfaceVariant, fontSize: 11),
            ),
          for (var i = 0; i < value.length; i++) ...[
            if (i > 0) const SizedBox(height: AppDimensions.spacingSm),
            _StopRow(
              key: ValueKey(value[i].id),
              index: i,
              stop: value[i],
              isFirst: i == 0,
              isLast: i == value.length - 1,
              onLabelChanged: (text) {
                final next = [...value];
                next[i] = next[i].copyWith(label: text);
                _emit(next);
              },
              onRemove: () => _emit([...value]..removeAt(i)),
              onMoveUp: i == 0
                  ? null
                  : () {
                      final next = [...value];
                      final item = next.removeAt(i);
                      next.insert(i - 1, item);
                      _emit(next);
                    },
              onMoveDown: i == value.length - 1
                  ? null
                  : () {
                      final next = [...value];
                      final item = next.removeAt(i);
                      next.insert(i + 1, item);
                      _emit(next);
                    },
            ),
          ],
          const SizedBox(height: AppDimensions.spacingMd),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: value.length >= maxStops
                      ? null
                      : () => _emit([...value, createStop()]),
                  icon: const Icon(Icons.add_location_alt_outlined, size: 16),
                  label: Text(
                    value.length >= maxStops ? 'Stop limit reached' : 'Add stop',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.primary,
                    side: BorderSide(color: colors.primary),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.spacingSm,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (value.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingMd),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingMd,
                vertical: AppDimensions.spacingSm,
              ),
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Row(
                children: [
                  Icon(Icons.straighten_rounded,
                      size: 14, color: colors.onSurfaceVariant),
                  const SizedBox(width: AppDimensions.spacingSm),
                  Expanded(
                    child: Text(
                      'Running route: ${totalKm.toStringAsFixed(1)} km • '
                      '+₹${(value.length * farePerStop).toStringAsFixed(0)} for ${value.length} stop${value.length == 1 ? '' : 's'}',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: colors.onSurface, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StopRow extends StatefulWidget {
  const _StopRow({
    super.key,
    required this.index,
    required this.stop,
    required this.isFirst,
    required this.isLast,
    required this.onLabelChanged,
    required this.onRemove,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final int index;
  final DeliveryStop stop;
  final bool isFirst;
  final bool isLast;
  final ValueChanged<String> onLabelChanged;
  final VoidCallback onRemove;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  State<_StopRow> createState() => _StopRowState();
}

class _StopRowState extends State<_StopRow> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.stop.label);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingSm),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${widget.index + 1}',
              style: AppTextStyles.labelSmall.copyWith(color: colors.primary),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingSm),
          Expanded(
            child: TextField(
              key: ValueKey('field_${widget.stop.id}'),
              controller: _controller,
              onChanged: widget.onLabelChanged,
              style: AppTextStyles.bodySmall.copyWith(color: colors.onSurface),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Stop ${widget.index + 1} address',
                hintStyle: AppTextStyles.bodySmall
                    .copyWith(color: colors.onSurfaceVariant, fontSize: 11),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingXs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: colors.infoLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'OTP',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: colors.info, fontSize: 8),
                ),
                Text(
                  widget.stop.otp,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: colors.info,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded,
                size: AppDimensions.iconSm, color: colors.onSurfaceVariant),
            onSelected: (action) {
              if (action == 'up') widget.onMoveUp?.call();
              if (action == 'down') widget.onMoveDown?.call();
              if (action == 'remove') widget.onRemove();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'up',
                enabled: !widget.isFirst,
                child: const Text('Move up'),
              ),
              PopupMenuItem(
                value: 'down',
                enabled: !widget.isLast,
                child: const Text('Move down'),
              ),
              PopupMenuItem(value: 'remove', child: const Text('Remove stop')),
            ],
          ),
        ],
      ),
    );
  }
}
