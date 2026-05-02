import 'package:flutter/services.dart';

class OverlayController {
  static const channel = MethodChannel("zeni/overlay");

  static Future<void> show() async {
    await channel.invokeMethod("showBubble");
  }
}