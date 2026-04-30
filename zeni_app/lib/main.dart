import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

import 'services/wake_word_service.dart';
import 'services/device_service.dart';
import 'services/phone_control_service.dart';

void main() {
  runApp(const ZeniApp());
}

class ZeniApp extends StatelessWidget {
  const ZeniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const ZeniHome(),
    );
  }
}

class ZeniHome extends StatefulWidget {
  const ZeniHome({super.key});

  @override
  State<ZeniHome> createState() => _ZeniHomeState();
}

class _ZeniHomeState extends State<ZeniHome> {
  final tts = FlutterTts();
  final wake = WakeWordService();

  final String baseUrl = "https://zeni-1.onrender.com";

  String status = "Starting...";
  String last = "";
  String reply = "";

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    await Permission.microphone.request();

    await DeviceService.init(baseUrl);

    await wake.init(baseUrl as Null Function());

    wake.onWakeWordDetected = () {
      setState(() => status = "Listening...");
    };

    wake.onCommand = (text) async {
      last = text;
      setState(() => status = "Thinking...");

      // 🔥 LOCAL PHONE COMMANDS
      if (text.contains("open youtube")) {
        await PhoneControlService.openApp("com.google.android.youtube");
        speak("Opening YouTube");
        return;
      }

      if (text.contains("open chrome")) {
        await PhoneControlService.openApp("com.android.chrome");
        speak("Opening Chrome");
        return;
      }

      if (text.contains("torch on")) {
        await PhoneControlService.toggleTorch(true);
        speak("Torch on");
        return;
      }

      if (text.contains("torch off")) {
        await PhoneControlService.toggleTorch(false);
        speak("Torch off");
        return;
      }

      if (text.contains("volume up")) {
        await PhoneControlService.changeVolume("up");
        speak("Volume increased");
        return;
      }

      if (text.contains("volume down")) {
        await PhoneControlService.changeVolume("down");
        speak("Volume decreased");
        return;
      }

      // 🌐 CLOUD
      final res = await http.post(
        Uri.parse("$baseUrl/api/voice"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "text": text,
          "deviceId": DeviceService.deviceId
        }),
      );

      final data = jsonDecode(res.body);

      reply = data["reply"];
      speak(reply);

      setState(() => status = "Say 'Hey Zeni'");
    };

    wake.startListening();

    setState(() => status = "Say 'Hey Zeni'");
  }

  Future<void> speak(String text) async {
    await tts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(status, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}