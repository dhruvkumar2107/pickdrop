import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../constants/colors.dart';
import '../constants/dimensions.dart';

enum AppToastType { success, error, warning, info }

/// Lightweight overlay toast. Only one toast is visible at a time.
class AppToast {
  AppToast._();

  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context,
    String message, {
    AppToastType type = AppToastType.info,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    dismiss();

    final overlay = Overlay.of(context, rootOverlay: true);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastView(
        message: message,
        type: type,
        icon: icon,
        duration: duration,
        actionLabel: actionLabel,
        onAction: onAction,
        onDismissed: () {
          if (identical(_currentEntry, entry)) {
            _currentEntry = null;
          }
          entry.remove();
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  static void success(BuildContext context, String message, {Duration duration = const Duration(seconds: 3)}) {
    show(context, message, type: AppToastType.success, duration: duration);
  }

  static void error(BuildContext context, String message, {Duration duration = const Duration(seconds: 4)}) {
    show(context, message, type: AppToastType.error, duration: duration);
  }

  static void warning(BuildContext context, String message, {Duration duration = const Duration(seconds: 3)}) {
    show(context, message, type: AppToastType.warning, duration: duration);
  }

  static void info(BuildContext context, String message, {Duration duration = const Duration(seconds: 3)}) {
    show(context, message, type: AppToastType.info, duration: duration);
  }

  static void dismiss() {
    final entry = _currentEntry;
    _currentEntry = null;
    entry?.remove();
  }
}

class _ToastView extends StatefulWidget {
  final String message;
  final AppToastType type;
  final IconData? icon;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismissed;

  const _ToastView({
    required this.message,
    required this.type,
    required this.icon,
    required this.duration,
    required this.actionLabel,
    required this.onAction,
    required this.onDismissed,
  });

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppConstants.mediumAnimation,
      reverseDuration: AppConstants.shortAnimation,
    )
      ..addStatusListener((status) {
        if (status == AnimationStatus.dismissed) {
          widget.onDismissed();
        }
      })
      ..forward();

    _timer = Timer(widget.duration, _dismiss);
  }

  void _dismiss() {
    if (!mounted) return;
    _controller.reverse();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  ({Color bg, Color fg, IconData icon}) get _style {
    final colors = context.colors;
    switch (widget.type) {
      case AppToastType.success:
        return (bg: colors.success, fg: colors.onPrimary, icon: Icons.check_circle_rounded);
      case AppToastType.error:
        return (bg: colors.error, fg: colors.onPrimary, icon: Icons.error_rounded);
      case AppToastType.warning:
        return (bg: colors.warning, fg: colors.onPrimary, icon: Icons.warning_rounded);
      case AppToastType.info:
        return (bg: colors.secondary, fg: colors.onSecondary, icon: Icons.info_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _style;

    return Positioned(
      top: MediaQuery.of(context).padding.top + AppDimensions.spacingMd,
      left: AppDimensions.spacingLg,
      right: AppDimensions.spacingLg,
      child: FadeTransition(
        opacity: _controller,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.6),
            end: Offset.zero,
          ).animate(_controller),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingLg,
                vertical: AppDimensions.spacingMd,
              ),
              decoration: BoxDecoration(
                color: style.bg,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                boxShadow: [
                  BoxShadow(
                    color: style.bg.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(widget.icon ?? style.icon, size: AppDimensions.iconMd, color: style.fg),
                  const SizedBox(width: AppDimensions.spacingMd),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: style.fg,
                      ),
                    ),
                  ),
                  if (widget.actionLabel != null)
                    GestureDetector(
                      onTap: () {
                        widget.onAction?.call();
                        _dismiss();
                      },
                      child: Text(
                        widget.actionLabel!,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: style.fg,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
