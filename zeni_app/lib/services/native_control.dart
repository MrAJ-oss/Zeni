import 'package:flutter/services.dart';

class NativeControl {
  static const platform = MethodChannel('zeni/native');

  static Future<void> openApp(String package) async {
    await platform.invokeMethod("openApp", {"package": package});
  }

  static Future<void> openSettings() async {
    await platform.invokeMethod("openSettings");
  }

  static Future<void> setVolume(int level) async {
    await platform.invokeMethod("setVolume", {"level": level});
  }

  static Future<void> flashOn() async {
    await platform.invokeMethod("flashOn");
  }

  static Future<void> flashOff() async {
    await platform.invokeMethod("flashOff");
  }

  static Future<void> dialNumber(String number) async {
    await platform.invokeMethod("dialNumber", {"number": number});
  }

  static Future<bool> callContact(String name) async {
    final res = await platform.invokeMethod("callContact", {"name": name});
    return res == true;
  }
}