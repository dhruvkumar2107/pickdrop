import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../../../core/constants/colors.dart';
import '../../../../../core/constants/dimensions.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/text_styles.dart';

enum ProactiveAlertSeverity { info, warning, critical }

enum ProactiveAlertAction { autoRematch, chatWithDriver, callSupport }

class ProactiveAlert {
  final String id;
  final String title;
  final String message;
  final ProactiveAlertSeverity severity;
  final List<ProactiveAlertAction> suggestedOptions;
  final DateTime detectedAt;

  const ProactiveAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.suggestedOptions,
    required this.detectedAt,
  });
}

class ProactiveAlertService {
  const ProactiveAlertService();

  static const double deviationThresholdKm = 1.5;
  static const Duration stoppedThreshold = Duration(minutes: 3);
  static const Duration criticalStopThreshold = Duration(minutes: 10);

  static const List<ProactiveAlertAction> _defaultOptions = [
    ProactiveAlertAction.autoRematch,
    ProactiveAlertAction.chatWithDriver,
    ProactiveAlertAction.callSupport,
  ];

  List<ProactiveAlert> evaluate({
    double? driverLat,
    double? driverLng,
    double? prevLat,
    double? prevLng,
    DateTime? expectedArrival,
    DateTime? destinationEta,
    bool isStopped = false,
    Duration stoppedFor = Duration.zero,
    DateTime? now,
  }) {
    final detectedAt = now ?? DateTime.now();
    final alerts = <ProactiveAlert>[];

    if (isStopped && stoppedFor > stoppedThreshold) {
      alerts.add(
        ProactiveAlert(
          id: 'driver_stopped',
          title: 'Your driver has stopped',
          message:
              'No movement for ${stoppedFor.inMinutes} min. It could be traffic or a halt - we can step in right away.',
          severity: stoppedFor > criticalStopThreshold
              ? ProactiveAlertSeverity.critical
              : ProactiveAlertSeverity.warning,
          suggestedOptions: _defaultOptions,
          detectedAt: detectedAt,
        ),
      );
    }

    if (driverLat != null &&
        driverLng != null &&
        prevLat != null &&
        prevLng != null) {
      final deviationKm = _haversine(driverLat, driverLng, prevLat, prevLng);
      if (deviationKm > deviationThresholdKm) {
        alerts.add(
          ProactiveAlert(
            id: 'route_deviation',
            title: 'Off the expected route',
            message:
                'Your driver is ${deviationKm.toStringAsFixed(1)} km away from the last confirmed point on the route.',
            severity: deviationKm > deviationThresholdKm * 3
                ? ProactiveAlertSeverity.critical
                : ProactiveAlertSeverity.warning,
            suggestedOptions: _defaultOptions,
            detectedAt: detectedAt,
          ),
        );
      }
    }

    if (expectedArrival != null &&
        destinationEta != null &&
        destinationEta.isAfter(expectedArrival)) {
      final lateBy = destinationEta.difference(expectedArrival);
      if (lateBy > const Duration(minutes: 2)) {
        alerts.add(
          ProactiveAlert(
            id: 'late_delivery',
            title: 'Delivery running late',
            message:
                '${_humanDuration(lateBy)} behind schedule. You can rematch for a faster driver.',
            severity: lateBy > const Duration(minutes: 15)
                ? ProactiveAlertSeverity.critical
                : ProactiveAlertSeverity.info,
            suggestedOptions: _defaultOptions,
            detectedAt: detectedAt,
          ),
        );
      }
    }

    return alerts;
  }

  String _humanDuration(Duration duration) {
    if (duration.inHours >= 1) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      return minutes == 0 ? '$hours hr' : '$hours hr $minutes min';
    }
    return '${duration.inMinutes} min';
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) * math.cos(lat2 * p) * (1 - math.cos((lon2 - lon1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a));
  }
}

class ProactiveAlertDialog extends StatelessWidget {
  final ProactiveAlert alert;
  final ValueChanged<ProactiveAlertAction>? onAction;
  final VoidCallback? onDismiss;

  const ProactiveAlertDialog({
    super.key,
    required this.alert,
    this.onAction,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (tone, icon) = switch (alert.severity) {
      ProactiveAlertSeverity.info => (colors.info, Icons.info_outline_rounded),
      ProactiveAlertSeverity.warning => (colors.warning, Icons.warning_amber_rounded),
      ProactiveAlertSeverity.critical => (colors.error, Icons.error_outline_rounded),
    };
    final background = switch (alert.severity) {
      ProactiveAlertSeverity.info => colors.infoLight,
      ProactiveAlertSeverity.warning => colors.warningLight,
      ProactiveAlertSeverity.critical => colors.errorLight,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: tone, width: DesignTokens.borderThin),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: AppDimensions.iconMd, color: tone),
              const SizedBox(width: AppDimensions.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXs),
                    Text(
                      alert.message,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colors.onSurfaceVariant,
                        height: DesignTokens.lhRelaxed,
                      ),
                    ),
                  ],
                ),
              ),
              if (onDismiss != null)
                GestureDetector(
                  onTap: onDismiss,
                  child: Icon(
                    Icons.close_rounded,
                    size: AppDimensions.iconSm,
                    color: colors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          Wrap(
            spacing: AppDimensions.spacingSm,
            runSpacing: AppDimensions.spacingSm,
            children: alert.suggestedOptions
                .map((option) => _optionChip(colors, tone, option))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _optionChip(
    AppColorsExtension colors,
    Color tone,
    ProactiveAlertAction option,
  ) {
    final (icon, label) = switch (option) {
      ProactiveAlertAction.autoRematch => (Icons.sync_rounded, 'Auto-rematch'),
      ProactiveAlertAction.chatWithDriver => (
          Icons.chat_bubble_outline_rounded,
          'Chat with driver',
        ),
      ProactiveAlertAction.callSupport => (Icons.support_agent_rounded, 'Call support'),
    };

    return Material(
      color: tone.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      child: InkWell(
        onTap: () => onAction?.call(option),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingMd,
            vertical: AppDimensions.spacingSm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppDimensions.iconSm, color: tone),
              const SizedBox(width: AppDimensions.spacingXs),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
