import 'voice_service.dart';

class WakeWordService {
  final VoiceService _voice = VoiceService();

  Function()? onWake;

  Future init(Function() wakeCallback) async {
    onWake = wakeCallback;
    await _voice.init();
    _startListening();
  }

  void _startListening() {
    _voice.startListening((text) {
      text = text.toLowerCase();

      if (text.contains("hey zeni") || text.contains("ok zeni")) {
        if (onWake != null) onWake!();
      }

      _startListening(); // keep looping
    });
  }
}