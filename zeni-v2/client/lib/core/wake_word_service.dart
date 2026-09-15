import 'package:speech_to_text/speech_to_text.dart' as stt;

const String wakePhrase = 'zeni';
const List<String> stopPhrases = ['stop', 'cancel', 'never mind', 'that\'s enough'];

class WakeWordService {
  final stt.SpeechToText _speech;
  final void Function() onWakeDetected;
  final void Function() onStopPhraseDetected;
  bool _armed = false;

  WakeWordService(this._speech, {required this.onWakeDetected, required this.onStopPhraseDetected});

  bool get isArmed => _armed;

  // Foreground-only. Does not survive the app being backgrounded or the
  // screen locking — that requires a native background-audio implementation
  // this build does not include.
  Future<void> arm() async {
    if (_armed) return;
    _armed = true;
    await _listenCycle();
  }

  void disarm() {
    _armed = false;
    _speech.stop();
  }

  Future<void> _listenCycle() async {
    if (!_armed) return;
    await _speech.listen(
      onResult: (result) {
        final text = result.recognizedWords.toLowerCase();
        if (text.contains(wakePhrase)) {
          onWakeDetected();
        } else if (stopPhrases.any((p) => text.contains(p))) {
          onStopPhraseDetected();
        }
      },
      listenFor: const Duration(seconds: 8),
    );
    // speech_to_text stops after a pause; re-arm to keep listening.
    Future.delayed(const Duration(milliseconds: 500), _listenCycle);
  }
}
