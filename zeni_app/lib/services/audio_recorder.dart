import 'package:record/record.dart';

class ZeniRecorder {
  final Record _recorder = Record();

  Future<void> startRecording() async {
    // Check permission
    final hasPermission = await _recorder.hasPermission();

    if (!hasPermission) {
      throw Exception("Mic permission denied");
    }

    // Start recording
    await _recorder.start(
      path: 'zeni_audio.wav',
      encoder: AudioEncoder.wav,
      bitRate: 128000,
      samplingRate: 16000,
    );
  }

  Future<void> stopRecording() async {
    await _recorder.stop();
  }
}