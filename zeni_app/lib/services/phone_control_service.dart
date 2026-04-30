import 'package:flutter/services.dart';

class PhoneControlService {
  static const platform = MethodChannel("zeni.phone");

  static Future<void> openApp(String package) async {
    await platform.invokeMethod("openApp", {"package": package});
  }

  static Future<void> openUrl(String url) async {
    await platform.invokeMethod("openUrl", {"url": url});
  }

  static Future<void> toggleTorch(bool on) async {
    await platform.invokeMethod("torch", {"state": on});
  }

  static Future<void> changeVolume(String type) async {
    await platform.invokeMethod("volume", {"type": type});
  }
}