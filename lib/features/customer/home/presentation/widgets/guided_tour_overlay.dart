import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../core/constants/colors.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/widgets/buttons/buttons.dart';

class CoachMark {
  final GlobalKey key;
  final String title;
  final String message;

  const CoachMark({
    required this.key,
    required this.title,
    required this.message,
  });
}

class GuidedTour {
  GuidedTour._();

  static const String completedKey = 'guided_tour_completed';
  static const int maxSteps = 4;

  static Future<void> maybeShow(
    BuildContext context,
    List<CoachMark> marks,
  ) async {
    if (marks.isEmpty || !context.mounted) return;
    if (await _hasCompleted()) return;
    if (!context.mounted) return;
    await _show(context, marks, persist: true);
  }

  static Future<void> replay(
    BuildContext context,
    List<CoachMark> marks,
  ) async {
    if (marks.isEmpty || !context.mounted) return;
    await _show(context, marks, persist: false);
  }

  static Future<bool> _hasCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(completedKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(completedKey, true);
    } catch (_) {}
  }

  static Future<void> _show(
    BuildContext context,
    List<CoachMark> marks, {
    required bool persist,
  }) async {
    final overlay = Overlay.of(context, rootOverlay: true);
    final completer = Completer<void>();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _GuidedTourOverlay(
        marks: marks.take(maxSteps).toList(),
        onFinished: () {
          if (entry.mounted) entry.remove();
          if (persist) _persist();
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );
    overlay.insert(entry);
    await completer.future;
  }
}

class _GuidedTourOverlay extends StatefulWidget {
  final List<CoachMark> marks;
  final VoidCallback onFinished;

  const _GuidedTourOverlay({
    required this.marks,
    required this.onFinished,
  });

  @override
  State<_GuidedTourOverlay> createState() => _GuidedTourOverlayState();
}

class _GuidedTourOverlayState extends State<_GuidedTourOverlay> {
  int _index = 0;
  Rect? _target;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _resolveTarget();
  }

  void _resolveTarget() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _finished) return;
      setState(() => _target = _measure(widget.marks[_index].key));
    });
  }

  Rect? _measure(GlobalKey key) {
    final renderObject = key.currentContext?.findRenderObject();
    if (renderObject is! RenderBox) return null;
    if (!renderObject.attached || !renderObject.hasSize) return null;
    try {
      return renderObject.localToGlobal(Offset.zero) & renderObject.size;
    } catch (_) {
      return null;
    }
  }

  void _next() {
    if (_index >= widget.marks.length - 1) {
      _finish();
      return;
    }
    setState(() {
      _index += 1;
      _target = null;
    });
    _resolveTarget();
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    widget.onFinished();
  }

  Rect _tooltipPosition(Rect spotlight, Size view, EdgeInsets padding) {
    const margin = DesignTokens.space4;
    const gap = DesignTokens.space3;
    final width = math.min(300.0, view.width - margin * 2);
    final height = math.min(
      210.0,
      view.height - padding.top - padding.bottom - margin * 2,
    );
    final minTop = padding.top + margin;
    final maxTop = math.max(minTop, view.height - padding.bottom - margin - height);
    final minLeft = margin;
    final maxLeft = math.max(minLeft, view.width - margin - width);

    double top = spotlight.bottom + gap;
    if (top + height > maxTop) {
      top = spotlight.top - gap - height;
    }
    final clampedTop = top.clamp(minTop, maxTop).toDouble();
    final left = (spotlight.center.dx - width / 2)
        .clamp(minLeft, maxLeft)
        .toDouble();
    return Rect.fromLTWH(left, clampedTop, width, height);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final view = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final mark = widget.marks[_index];
    final isLast = _index == widget.marks.length - 1;
    final spotlight = _target ??
        Rect.fromCenter(
          center: Offset(view.width / 2, view.height * 0.45),
          width: 220,
          height: 96,
        );
    final tooltip = _tooltipPosition(spotlight, view, padding);

    return TweenAnimationBuilder<double>(
      key: ValueKey<int>(_index),
      tween: Tween<double>(begin: 0, end: 1),
      duration: DesignTokens.durationNormal,
      curve: DesignTokens.easeOutQuart,
      builder: (context, opacity, child) => Opacity(opacity: opacity, child: child),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _SpotlightPainter(
                hole: spotlight,
                scrim: DesignTokens.charcoal900.withValues(alpha: 0.74),
                border: colors.primary,
              ),
            ),
          ),
          Positioned(
            left: tooltip.left,
            top: tooltip.top,
            width: tooltip.width,
            child: _buildTooltip(context, mark, isLast),
          ),
        ],
      ),
    );
  }

  Widget _buildTooltip(BuildContext context, CoachMark mark, bool isLast) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.space4),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(color: colors.outline),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.shadowDark,
            blurRadius: DesignTokens.elevationLg,
            offset: const Offset(0, DesignTokens.space3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step ${_index + 1} of ${widget.marks.length}',
            style: TokenTextStyles.labelSmall(
              color: colors.primary,
              weight: DesignTokens.wSemiBold,
              letterSpacing: DesignTokens.lsWide,
            ),
          ),
          const SizedBox(height: DesignTokens.space2),
          Text(
            mark.title,
            style: TokenTextStyles.titleMedium(
              color: colors.onSurface,
              weight: DesignTokens.wSemiBold,
            ),
          ),
          const SizedBox(height: DesignTokens.space2),
          Text(
            mark.message,
            style: TokenTextStyles.bodySmall(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DesignTokens.space4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _finish,
                style: TextButton.styleFrom(
                  foregroundColor: colors.onSurfaceVariant,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.space3,
                  ),
                ),
                child: Text(
                  'Skip',
                  style: TokenTextStyles.labelLarge(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.space2),
              PrimaryButton(
                text: isLast ? 'Got it' : 'Next',
                isFullWidth: false,
                height: DesignTokens.buttonHeightMd,
                onPressed: _next,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect hole;
  final Color scrim;
  final Color border;

  const _SpotlightPainter({
    required this.hole,
    required this.scrim,
    required this.border,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = hole.inflate(6);
    final rrect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(DesignTokens.radiusLg),
    );
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(rrect);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.fill
        ..color = scrim,
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = DesignTokens.borderMedium
        ..color = border,
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.hole != hole ||
        oldDelegate.scrim != scrim ||
        oldDelegate.border != border;
  }
}
