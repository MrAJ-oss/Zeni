// ignore_for_file: avoid_print

import 'package:flutter/services.dart';
import 'api_service.dart';

class OverlayService {
  static const _channel = MethodChannel('zeni.phone');

  // Check if overlay permission is granted
  static Future<bool> hasPermission() async {
    try {
      final result = await _channel.invokeMethod('checkOverlayPermission');
      return result == true;
    } catch (e) {
      return false;
    }
  }

  // Ask user to grant overlay permission
  static Future<void> requestPermission() async {
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } catch (e) {
      print("Overlay permission error: $e");
    }
  }

  // Start the floating mic button
  static Future<String> start() async {
    try {
      final hasPerms = await hasPermission();
      if (!hasPerms) {
        await requestPermission();
        return "permission_needed";
      }
      final result = await _channel.invokeMethod('startOverlay', {
        'deviceId': ApiService.deviceId,
      });
      return result ?? "started";
    } catch (e) {
      print("Start overlay error: $e");
      return "error";
    }
  }

  // Stop the floating mic button
  static Future<void> stop() async {
    try {
      await _channel.invokeMethod('stopOverlay');
    } catch (e) {
      print("Stop overlay error: $e");
    }
  }

  // Check if overlay is currently running
  static Future<bool> isRunning() async {
    try {
      final result = await _channel.invokeMethod('isOverlayRunning');
      return result == true;
    } catch (e) {
      return false;
    }
  }
}