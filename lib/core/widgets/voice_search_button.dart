import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/colors.dart';
import '../../shared/services/voice_input_service.dart';
import '../theme/design_tokens.dart';
import 'app_toast.dart';

class VoiceSearchButton extends StatefulWidget {
  final ValueChanged<String> onResult;
  final String localeId;
  final double size;
  final String tooltip;
  final Color? color;

  const VoiceSearchButton({
    super.key,
    required this.onResult,
    this.localeId = 'en_IN',
    this.size = 52,
    this.tooltip = 'Voice input',
    this.color,
  });

  @override
  State<VoiceSearchButton> createState() => _VoiceSearchButtonState();
}

class _VoiceSearchButtonState extends State<VoiceSearchButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  Timer? _safetyTimer;
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    _pulse.dispose();
    VoiceInputService.instance.stop();
    super.dispose();
  }

  Future<void> _toggle() async {
    HapticFeedback.selectionClick();
    if (_listening) {
      VoiceInputService.instance.stop();
      _reset();
      return;
    }

    final granted = await VoiceInputService.instance.ensurePermission();
    if (!mounted) return;
    if (!granted) {
      AppToast.show(
        context,
        'Voice input unavailable',
        type: AppToastType.warning,
        icon: Icons.mic_off_rounded,
      );
      return;
    }

    HapticFeedback.selectionClick();
    setState(() => _listening = true);
    _pulse.repeat(reverse: true);
    _safetyTimer?.cancel();
    _safetyTimer = Timer(const Duration(seconds: 14), _reset);
    VoiceInputService.instance.start(
      onResult: _handleResult,
      localeId: widget.localeId,
    );
  }

  void _handleResult(String text) {
    _reset();
    widget.onResult(text);
  }

  void _reset() {
    _safetyTimer?.cancel();
    if (!mounted) return;
    if (_listening) {
      setState(() => _listening = false);
    }
    _pulse.stop();
    _pulse.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = widget.color ?? colors.primary;

    return Tooltip(
      message: widget.tooltip,
      child: Semantics(
        button: true,
        label: widget.tooltip,
        child: Material(
          color: colors.transparent,
          child: Ink(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: _listening ? accent : colors.surfaceCard,
              shape: BoxShape.circle,
              border: Border.all(
                color: _listening ? accent : colors.outline,
                width: DesignTokens.borderThin,
              ),
              boxShadow: [
                BoxShadow(
                  color: _listening
                      ? accent.withValues(alpha: 0.4)
                      : colors.shadow.withValues(alpha: 0.12),
                  blurRadius: _listening ? 18 : 8,
                  spreadRadius: _listening ? 4 * _pulse.value : 0,
                ),
              ],
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _toggle,
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (context, child) => Transform.scale(
                  scale: _listening ? 1.0 + 0.12 * _pulse.value : 1.0,
                  child: child,
                ),
                child: Icon(
                  _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                  size: DesignTokens.iconLg,
                  color: _listening ? colors.onPrimary : accent,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
