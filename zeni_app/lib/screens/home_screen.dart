import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/tts_service.dart';
import '../services/voice_service.dart';
import '../widgets/zeni_bubble.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final voice = VoiceService();
  final tts = TTSService();

  bool listening = false;

  @override
  void initState() {
    super.initState();
    startSystem();
  }

  void startSystem() async {
    await voice.init();
    listenLoop();
  }

  void listenLoop() {
    setState(() => listening = true);

    voice.start((text) async {
      setState(() => listening = false);

      final res = await ApiService.post("voice", {
        "text": text
      });

      final type = res["type"];
      final reply = res["reply"];

      await tts.speak(reply);

      // PHONE ACTIONS
      if (type == "phone") {
        // future: integrate intent launching
      }

      // PC ACTIONS
      if (type == "pc") {
        await ApiService.post("sendToPC", {
          "command": res["command"]
        });
      }

      listenLoop(); // 🔥 keep listening forever
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ZeniBubble(
          isListening: listening,
          onClose: () {},
        ),
      ),
    );
  }
}