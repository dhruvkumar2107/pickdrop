import 'package:flutter/material.dart';

import '../../../../../core/constants/colors.dart';
import '../../../../../core/constants/dimensions.dart';
import '../../../../../core/theme/text_styles.dart';

class HoldToCallSosButton extends StatefulWidget {
  const HoldToCallSosButton({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<HoldToCallSosButton> createState() => _HoldToCallSosButtonState();
}

class _HoldToCallSosButtonState extends State<HoldToCallSosButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..addStatusListener(_onStatus);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _controller.reverse();
      widget.onComplete();
    }
  }

  void _start() {
    if (!_controller.isAnimating) _controller.forward();
  }

  void _stop() {
    if (_controller.status == AnimationStatus.forward) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onLongPressStart: (_) => _start(),
      onLongPressEnd: (_) => _stop(),
      onLongPressCancel: _stop,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            height: AppDimensions.buttonHeightLg,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: colors.errorLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: colors.error.withValues(alpha: 0.4)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: _controller.value,
                    child: Container(color: colors.error.withValues(alpha: 0.35)),
                  ),
                ),
                child!,
              ],
            ),
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emergency_outlined, size: AppDimensions.iconSm, color: colors.error),
            const SizedBox(width: AppDimensions.spacingSm),
            Text(
              'Hold to call 112',
              style: AppTextStyles.labelLarge.copyWith(color: colors.error),
            ),
          ],
        ),
      ),
    );
  }
}
