import 'native_control.dart';

class LocalCommands {
  static Future<bool> execute(String text) async {
    text = text.toLowerCase();

    // 📞 CALL NUMBER
    final numberMatch = RegExp(r'call\s+(\d{6,15})').firstMatch(text);
    if (numberMatch != null) {
      await NativeControl.dialNumber(numberMatch.group(1)!);
      return true;
    }

    // 📞 CALL CONTACT
    if (text.startsWith("call ")) {
      final name = text.replaceFirst("call ", "").trim();
      return await NativeControl.callContact(name);
    }

    // 📱 OPEN APPS
    if (text.contains("open youtube")) {
      await NativeControl.openApp("com.google.android.youtube");
      return true;
    }

    if (text.contains("open chrome")) {
      await NativeControl.openApp("com.android.chrome");
      return true;
    }

    // ⚙️ SETTINGS
    if (text.contains("open settings")) {
      await NativeControl.openSettings();
      return true;
    }

    // 🔦 FLASHLIGHT
    if (text.contains("flash on")) {
      await NativeControl.flashOn();
      return true;
    }

    if (text.contains("flash off")) {
      await NativeControl.flashOff();
      return true;
    }

    // 🔊 VOLUME
    if (text.contains("volume max")) {
      await NativeControl.setVolume(15);
      return true;
    }

    if (text.contains("volume low")) {
      await NativeControl.setVolume(3);
      return true;
    }

    return false;
  }
}