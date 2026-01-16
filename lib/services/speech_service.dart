import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;

  Future<bool> init() async {
    if (!_isInitialized) {
      _isInitialized = await _speech.initialize(
        onError: (val) => print('onError: $val'),
        onStatus: (val) => print('onStatus: $val'),
      );
    }
    return _isInitialized;
  }

  Future<void> startListening({required Function(String) onResult}) async {
    if (_isInitialized) {
      await _speech.listen(
        onResult: (val) => onResult(val.recognizedWords),
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: 'en_US',
        cancelOnError: true,
        listenMode: ListenMode.dictation,
      );
    }
  }

  Future<void> stop() async {
    if (_isInitialized) {
      await _speech.stop();
    }
  }

  bool get isListening => _speech.isListening;
}
