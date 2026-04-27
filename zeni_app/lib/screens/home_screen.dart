import 'package:flutter/material.dart';
import '../services/voice_service.dart';
import '../services/tts_service.dart';
import '../services/api_service.dart';
import '../services/local_command_service.dart';
import '../services/wake_word_service.dart';
import '../services/tone_service.dart';
import '../services/voice_auth_service.dart';
import '../services/memory_service.dart';
import '../services/log_service.dart';
import '../widgets/zeni_bubble.dart';
import '../widgets/mic_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final voice = VoiceService();
  final tts = TTSService();
  final wake = WakeWordService();

  bool listening = false;

  @override
  void initState() {
    super.initState();

    voice.init();

    wake.init(() {
      startListening();
    });
  }

  void startListening() {
    setState(() => listening = true);

    voice.startListening((text) async {
      setState(() => listening = false);

      LogService.add("User said: $text");

      // 🔐 Voice auth
      bool allowed = await VoiceAuthService.verify(text);

      if (!allowed) {
        tts.speak("Access denied");
        LogService.add("Unauthorized access attempt");
        return;
      }

      // 🎭 Tone detection
      String tone = ToneService.detectTone(text);

      String response;

      try {
        final res = await ApiService.post("chat", {
          "message": text
        });

        response = res["reply"];
      } catch (e) {
        response = LocalCommandService.process(text);
      }

      response = ToneService.modifyResponse(response, tone);

      MemoryService.add("User: $text");
      MemoryService.add("Zeni: $response");

      tts.speak(response);
      LogService.add("Zeni replied: $response");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: ZeniBubble(isListening: listening)),
      floatingActionButton: MicButton(onTap: startListening),
    );
  }
}