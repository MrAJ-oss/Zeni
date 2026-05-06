import 'dart:io';
import 'package:http/http.dart' as http;

class VoiceAuthService {
  static Future<bool> verify(File audio) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse("http://YOUR_PC_IP:5000/verify"),
    );

    request.files.add(
      await http.MultipartFile.fromPath('audio', audio.path),
    );

    var res = await request.send();
    var body = await res.stream.bytesToString();

    return body.contains("allowed");
  }
}