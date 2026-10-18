import 'package:speech_to_text/speech_to_text.dart';

class VoiceInputService {
  VoiceInputService._();

  static final VoiceInputService instance = VoiceInputService._();

  final SpeechToText _speech = SpeechToText();

  bool _initialized = false;
  bool _listening = false;

  bool get isAvailable => _initialized;

  bool get isListening => _listening;

  Future<bool> ensurePermission() async {
    try {
      if (!_initialized) {
        _initialized = await _speech.initialize();
      }
      if (!_initialized) return false;
      return await _speech.hasPermission;
    } catch (_) {
      return false;
    }
  }

  void start({
    required void Function(String text) onResult,
    String localeId = 'en_IN',
  }) {
    if (!_initialized) return;
    _listening = true;
    _beginListen(onResult, localeId);
  }

  Future<void> _beginListen(
    void Function(String text) onResult,
    String localeId,
  ) async {
    try {
      await _speech.listen(
        onResult: (result) {
          if (!result.finalResult) return;
          final words = result.recognizedWords.trim();
          _listening = false;
          if (words.isNotEmpty) onResult(words);
        },
        listenOptions: SpeechListenOptions(
          localeId: localeId,
          listenFor: const Duration(seconds: 15),
          pauseFor: const Duration(seconds: 4),
          partialResults: true,
          cancelOnError: true,
        ),
      );
    } catch (_) {
      _listening = false;
    }
  }

  void stop() {
    if (!_initialized) return;
    _listening = false;
    try {
      _speech.stop();
    } catch (_) {}
  }

  void cancel() {
    if (!_initialized) return;
    _listening = false;
    try {
      _speech.cancel();
    } catch (_) {}
  }
}
