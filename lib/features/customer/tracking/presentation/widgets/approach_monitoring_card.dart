import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../../../core/constants/colors.dart';
import '../../../../../../core/constants/dimensions.dart';
import '../../../../../../core/theme/text_styles.dart';

class ApproachMonitoringCard extends StatefulWidget {
  final double initialEtaMinutes;
  final bool isDriverStopped;
  final VoidCallback onContactSupport;

  const ApproachMonitoringCard({
    super.key,
    required this.initialEtaMinutes,
    this.isDriverStopped = false,
    required this.onContactSupport,
  });

  @override
  State<ApproachMonitoringCard> createState() => _ApproachMonitoringCardState();
}

class _ApproachMonitoringCardState extends State<ApproachMonitoringCard> {
  int _stoppedSeconds = 0;
  Timer? _stopTimer;

  @override
  void initState() {
    super.initState();
    if (widget.isDriverStopped) {
      _startStoppedTimer();
    }
  }

  @override
  void didUpdateWidget(covariant ApproachMonitoringCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDriverStopped && !oldWidget.isDriverStopped) {
      _startStoppedTimer();
    } else if (!widget.isDriverStopped && oldWidget.isDriverStopped) {
      _stopTimer?.cancel();
      _stoppedSeconds = 0;
    }
  }

  void _startStoppedTimer() {
    _stopTimer?.cancel();
    _stoppedSeconds = 0;
    _stopTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _stoppedSeconds++;
      });
    });
  }

  @override
  void dispose() {
    _stopTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isStoppedAlert = widget.isDriverStopped || _stoppedSeconds > 180; // > 3 min

    if (!isStoppedAlert) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMd,
          vertical: AppDimensions.spacingSm,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceCard,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: colors.success,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingSm),
            Expanded(
              child: Text(
                'Live approach active • ETA ${widget.initialEtaMinutes.toStringAsFixed(0)} mins',
                style: AppTextStyles.labelMedium.copyWith(color: colors.onSurface),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: const Color(0xFFEF4444)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 20),
              const SizedBox(width: AppDimensions.spacingSm),
              Expanded(
                child: Text(
                  'Driver Stopped on Route (> 3 mins)',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: const Color(0xFFB91C1C),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingXs),
          Text(
            'We noticed your driver hasn\'t moved in a while due to heavy traffic or a stop. Would you like us to intervene or auto-rematch?',
            style: AppTextStyles.bodySmall.copyWith(
              color: const Color(0xFF7F1D1D),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: widget.onContactSupport,
              icon: const Icon(Icons.support_agent_rounded, size: 14),
              label: const Text('Priority Support / Rematch'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
