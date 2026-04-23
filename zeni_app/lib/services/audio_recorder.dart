import 'package:record/record.dart';

class ZeniRecorder {
  final AudioRecorder _recorder = AudioRecorder();

  Future<void> startRecording() async {
    final hasPermission = await _recorder.hasPermission();

    if (hasPermission != true) {
      throw Exception("Mic permission denied");
    }

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        bitRate: 128000,
      ),
      path: 'zeni_audio.wav',
    );
  }

  Future<void> stopRecording() async {
    await _recorder.stop();
  }
}