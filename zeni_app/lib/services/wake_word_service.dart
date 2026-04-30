// ignore_for_file: avoid_print

import 'package:speech_to_text/speech_to_text.dart';

class WakeWordService {
final SpeechToText _speech = SpeechToText();
bool isListening = false;

Function()? onWakeWordDetected;
Function(String)? onCommand;

Future<void> init(Null Function() param0) async {
await _speech.initialize();
}

void startListening() async {
if (isListening) return;


isListening = true;

_speech.listen(
  // ignore: deprecated_member_use
  listenMode: ListenMode.dictation,
  onResult: (result) {
    String text = result.recognizedWords.toLowerCase();

    print("🎤 Heard: $text");

    if (text.contains("hey zeni")) {
      print("🔥 Wake word detected");

      onWakeWordDetected?.call();

      _speech.stop();
      isListening = false;

      _listenForCommand();
    }
  },
);


}

void _listenForCommand() async {
await Future.delayed(Duration(milliseconds: 300));


_speech.listen(
  // ignore: deprecated_member_use
  listenMode: ListenMode.dictation,
  onResult: (result) {
    String text = result.recognizedWords;

    print("🧠 Command: $text");

    onCommand?.call(text);

    _speech.stop();
    isListening = false;

    // restart wake listening
    startListening();
  },
);


}

void stop() {
_speech.stop();
isListening = false;
}
}
