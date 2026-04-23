// ignore_for_file: deprecated_member_use

import 'package:flutter_background_service/flutter_background_service.dart';
// ignore: unnecessary_import
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'services/local_commands.dart';
import 'services/network.dart';
import 'package:flutter_tts/flutter_tts.dart';

void onStart(ServiceInstance service) async {
  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
  }

  FlutterTts tts = FlutterTts();

  stt.SpeechToText speech = stt.SpeechToText();
  await speech.initialize();

  speech.listen(
    listenMode: stt.ListenMode.dictation,
    partialResults: true,
    onResult: (result) async {
      String text = result.recognizedWords.toLowerCase();

      if (!text.contains("zeni")) return;

      bool online = await NetworkCheck.isOnline();

      if (!online) {
        await LocalCommands.execute(text);
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      String deviceId = prefs.getString("deviceId") ?? "";

      final response = await http.post(
        Uri.parse("http://10.241.123.58:3000/api/voice"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "text": text,
          "deviceId": deviceId
        }),
      );

      final data = jsonDecode(response.body);

      await tts.speak(data["reply"]);
    },
  );
}