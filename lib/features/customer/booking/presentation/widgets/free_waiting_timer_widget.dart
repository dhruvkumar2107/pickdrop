import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../../../core/constants/colors.dart';
import '../../../../../../core/constants/dimensions.dart';
import '../../../../../../core/theme/text_styles.dart';

class FreeWaitingTimerWidget extends StatefulWidget {
  final int freeMinutes;
  final double perMinuteCharge;
  final bool isDrop;

  const FreeWaitingTimerWidget({
    super.key,
    this.freeMinutes = 10,
    this.perMinuteCharge = 3.0,
    this.isDrop = false,
  });

  @override
  State<FreeWaitingTimerWidget> createState() => _FreeWaitingTimerWidgetState();
}

class _FreeWaitingTimerWidgetState extends State<FreeWaitingTimerWidget> {
  late int _remainingSeconds;
  int _extraMinutes = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.freeMinutes * 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          final elapsedExtraSec = (_remainingSeconds.abs() + 1);
          _remainingSeconds--;
          _extraMinutes = (elapsedExtraSec / 60).ceil();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isFreeTime = _remainingSeconds >= 0;
    final minutes = (_remainingSeconds.abs() ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds.abs() % 60).toString().padLeft(2, '0');
    final extraCost = _extraMinutes * widget.perMinuteCharge;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingMd,
        vertical: AppDimensions.spacingSm,
      ),
      decoration: BoxDecoration(
        color: isFreeTime ? colors.successLight : colors.errorLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isFreeTime
              ? colors.success.withValues(alpha: 0.4)
              : colors.error.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timer_outlined,
            size: 20,
            color: isFreeTime ? colors.success : colors.error,
          ),
          const SizedBox(width: AppDimensions.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isFreeTime
                      ? '${widget.isDrop ? "Drop" : "Pickup"} Free Waiting: $minutes:$seconds left'
                      : 'Extra Waiting: +₹${extraCost.toStringAsFixed(0)} (₹${widget.perMinuteCharge.toStringAsFixed(0)}/min)',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: isFreeTime ? colors.success : colors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  isFreeTime
                      ? 'First ${widget.freeMinutes} mins are 100% complimentary'
                      : 'Transparent waiting fee added only after free period',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
