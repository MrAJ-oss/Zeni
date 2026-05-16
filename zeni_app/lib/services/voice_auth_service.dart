// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'api_service.dart';

class VoiceAuthService {
  static final AudioRecorder _recorder = AudioRecorder();

  // Set to true after:
  // 1. Deploying voice_auth to Render
  // 2. Adding VOICE_AUTH_URL to server .env
  // 3. Running enroll() once
  static const bool voiceAuthEnabled = false;

  static Future<String?> _recordAudio({int seconds = 3}) async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) return null;

      final dir = await getTemporaryDirectory();
      final path = "${dir.path}/zeni_voice_auth.wav";

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path,
      );

      await Future.delayed(Duration(seconds: seconds));
      await _recorder.stop();

      return path;
    } catch (e) {
      print("Voice record error: $e");
      return null;
    }
  }

  // Call once to save your voice print
  static Future<bool> enroll() async {
    try {
      final path = await _recordAudio(seconds: 4);
      if (path == null) return false;

      final bytes = await File(path).readAsBytes();
      final base64Audio = base64Encode(bytes);

      final res = await ApiService.post("voice-enroll", {
        "audioBase64": base64Audio,
        "deviceId": ApiService.deviceId,
      });

      return res["status"] == "enrolled";
    } catch (e) {
      print("Enroll error: $e");
      return false;
    }
  }

  // Returns true if voice matches or auth is disabled
  static Future<bool> verify() async {
    if (!voiceAuthEnabled) return true;

    try {
      final path = await _recordAudio(seconds: 3);
      if (path == null) return true;

      final bytes = await File(path).readAsBytes();
      final base64Audio = base64Encode(bytes);

      final res = await ApiService.post("voice-verify", {
        "audioBase64": base64Audio,
        "deviceId": ApiService.deviceId,
      });

      print("Voice auth: ${res["status"]}");
      return res["status"] == "allowed";
    } catch (e) {
      print("Voice verify error: $e");
      return true;
    }
  }
}