// ignore_for_file: avoid_print

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:battery_plus/battery_plus.dart';
// ignore: unused_import
import 'package:volume_controller/volume_controller.dart';

class DeviceCommandService {
  static const _channel = MethodChannel('zeni.phone');
  static final _battery = Battery();

  // ── App package map ───────────────────────────────────────────────
  static const Map<String, String> _appPackages = {
    'youtube': 'com.google.android.youtube',
    'instagram': 'com.instagram.android',
    'whatsapp': 'com.whatsapp',
    'spotify': 'com.spotify.music',
    'chrome': 'com.android.chrome',
    'gmail': 'com.google.android.gm',
    'maps': 'com.google.android.apps.maps',
    'settings': 'com.android.settings',
    'calculator': 'com.google.android.calculator',
    'twitter': 'com.twitter.android',
    'x': 'com.twitter.android',
    'facebook': 'com.facebook.katana',
    'snapchat': 'com.snapchat.android',
    'telegram': 'org.telegram.messenger',
    'netflix': 'com.netflix.mediaclient',
    'amazon': 'com.amazon.mShop.android.shopping',
    'flipkart': 'com.flipkart.android',
    'phonepe': 'com.phonepe.app',
    'paytm': 'net.one97.paytm',
    'gpay': 'com.google.android.apps.nbu.paisa.user',
    'zomato': 'com.application.zomato',
    'swiggy': 'in.swiggy.android',
    'camera': 'com.android.camera2',
    'gallery': 'com.google.android.apps.photos',
    'photos': 'com.google.android.apps.photos',
    'clock': 'com.google.android.deskclock',
    'alarm': 'com.google.android.deskclock',
    'contacts': 'com.google.android.contacts',
    'phone': 'com.google.android.dialer',
    'messages': 'com.google.android.apps.messaging',
    'drive': 'com.google.android.apps.docs',
    'docs': 'com.google.android.apps.docs.editors.docs',
    'sheets': 'com.google.android.apps.docs.editors.sheets',
    'meet': 'com.google.android.apps.meetings',
    'zoom': 'us.zoom.videomeetings',
    'discord': 'com.discord',
    'linkedin': 'com.linkedin.android',
    'reddit': 'com.reddit.frontpage',
    'tiktok': 'com.zhiliaoapp.musically',
    'hotstar': 'in.startv.hotstar',
    'prime': 'com.amazon.avod.thirdpartyclient',
  };

  // ── Main execute ──────────────────────────────────────────────────
  static Future<String> execute(String text) async {
    text = text.toLowerCase().trim();

    if (Platform.isAndroid) {
      return await _executeAndroid(text);
    } else if (Platform.isWindows) {
      return await _executeWindows(text);
    }

    return "Device commands not supported on this platform.";
  }

  // ── Android Commands ──────────────────────────────────────────────
  static Future<String> _executeAndroid(String text) async {
    try {

      // Volume
      if (text.contains('volume up') || text.contains('increase volume')) {
        await _channel.invokeMethod('volume', {'type': 'up'});
        return "Volume increased.";
      }
      if (text.contains('volume down') || text.contains('decrease volume')) {
        await _channel.invokeMethod('volume', {'type': 'down'});
        return "Volume decreased.";
      }
      if (text.contains('mute')) {
        await _channel.invokeMethod('volume', {'type': 'mute'});
        return "Muted.";
      }
      if (text.contains('unmute')) {
        await _channel.invokeMethod('volume', {'type': 'unmute'});
        return "Unmuted.";
      }

      // Brightness
      if (text.contains('brightness up') || text.contains('increase brightness')) {
        await _channel.invokeMethod('brightness', {'type': 'up'});
        return "Brightness increased.";
      }
      if (text.contains('brightness down') || text.contains('decrease brightness')) {
        await _channel.invokeMethod('brightness', {'type': 'down'});
        return "Brightness decreased.";
      }
      if (text.contains('max brightness') || text.contains('full brightness')) {
        await _channel.invokeMethod('brightness', {'type': 'max'});
        return "Brightness set to maximum.";
      }
      if (text.contains('min brightness') || text.contains('low brightness')) {
        await _channel.invokeMethod('brightness', {'type': 'min'});
        return "Brightness set to minimum.";
      }

      // Flashlight
      if (text.contains('flashlight on') || text.contains('torch on') || text.contains('turn on flashlight')) {
        await _channel.invokeMethod('torch', {'state': true});
        return "Flashlight on.";
      }
      if (text.contains('flashlight off') || text.contains('torch off') || text.contains('turn off flashlight')) {
        await _channel.invokeMethod('torch', {'state': false});
        return "Flashlight off.";
      }

      // Battery
      if (text.contains('battery')) {
        final level = await _battery.batteryLevel;
        final state = await _battery.batteryState;
        final stateText = state == BatteryState.charging ? " and charging" : "";
        return "Battery is at $level%$stateText.";
      }

      // WiFi
      if (text.contains('wifi') || text.contains('wi-fi')) {
        await _channel.invokeMethod('wifiSettings');
        return "Opening WiFi settings.";
      }

      // Bluetooth
      if (text.contains('bluetooth')) {
        await _channel.invokeMethod('bluetoothSettings');
        return "Opening Bluetooth settings.";
      }

      // Go Home
      if (text.contains('go home') || text.contains('home screen')) {
        await _channel.invokeMethod('goHome');
        return "Going to home screen.";
      }

      // Downloads
      if (text.contains('open downloads') || text.contains('open files') || text.contains('my files')) {
        await _channel.invokeMethod('openDownloads');
        return "Opening downloads.";
      }

      // Settings
      if (text.contains('open settings') || text.contains('go to settings')) {
        await _channel.invokeMethod('openSettings');
        return "Opening settings.";
      }

      // Call
      if (text.contains('call ')) {
        final name = text.replaceAll('call ', '').trim();
        await _channel.invokeMethod('call', {'number': name});
        return "Opening dialer for $name.";
      }

      // Alarm
      if (text.contains('alarm') || text.contains('wake me')) {
        final time = _parseTime(text);
        if (time != null) {
          await _channel.invokeMethod('setAlarm', {
            'hour': time['hour'],
            'minute': time['minute'],
          });
          return "Alarm set for ${_formatTime(time['hour']!, time['minute']!)}.";
        } else {
          // Open clock app
          await _channel.invokeMethod('openApp', {'package': 'com.google.android.deskclock'});
          return "Opening clock app. Set your alarm.";
        }
      }

      // Install app
      if (text.contains('install ')) {
        final appName = text.replaceAll('install ', '').trim();
        await _channel.invokeMethod('openPlayStore', {'query': appName});
        return "Opening Play Store for $appName.";
      }

      // Open app
      if (text.contains('open ')) {
        final appName = text.replaceAll('open ', '').trim();

        // Check app map first
        for (final entry in _appPackages.entries) {
          if (appName.contains(entry.key)) {
            await _channel.invokeMethod('openApp', {'package': entry.value});
            return "Opening ${entry.key}.";
          }
        }

        // Try as URL if it looks like a website
        if (appName.contains('.com') || appName.contains('.in') || appName.contains('.net')) {
          final url = appName.startsWith('http') ? appName : 'https://$appName';
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
          return "Opening $appName.";
        }

        // Try Play Store search
        await _channel.invokeMethod('openPlayStore', {'query': appName});
        return "Searching for $appName on Play Store.";
      }

      // Open website/YouTube search
      if (text.contains('search ') || text.contains('google ')) {
        final query = text.replaceAll('search ', '').replaceAll('google ', '').trim();
        final url = 'https://www.google.com/search?q=${Uri.encodeComponent(query)}';
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        return "Searching for $query.";
      }

      if (text.contains('youtube ') || text.contains('play ')) {
        final query = text.replaceAll('youtube ', '').replaceAll('play ', '').trim();
        final url = 'https://www.youtube.com/results?search_query=${Uri.encodeComponent(query)}';
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        return "Searching YouTube for $query.";
      }

      return "Sorry, I could not execute that command.";

    } catch (e) {
      print("Device command error: $e");
      return "Something went wrong executing that command.";
    }
  }

  // ── Windows Commands ──────────────────────────────────────────────
  static Future<String> _executeWindows(String text) async {
    try {

      // Volume
      if (text.contains('volume up') || text.contains('increase volume')) {
        await _runPowerShell(
          r'$wshShell = New-Object -ComObject wscript.shell; for($i=0;$i -lt 5;$i++){$wshShell.SendKeys([char]175)}'
        );
        return "Volume increased.";
      }
      if (text.contains('volume down') || text.contains('decrease volume')) {
        await _runPowerShell(
          r'$wshShell = New-Object -ComObject wscript.shell; for($i=0;$i -lt 5;$i++){$wshShell.SendKeys([char]174)}'
        );
        return "Volume decreased.";
      }
      if (text.contains('mute')) {
        await _runPowerShell(
          r'$wshShell = New-Object -ComObject wscript.shell; $wshShell.SendKeys([char]173)'
        );
        return "Muted.";
      }

      // Open browser with URL
      if (text.contains('open youtube') || text.contains('youtube')) {
        await launchUrl(Uri.parse('https://youtube.com'), mode: LaunchMode.externalApplication);
        return "Opening YouTube.";
      }
      if (text.contains('open google') || text.contains('google')) {
        await launchUrl(Uri.parse('https://google.com'), mode: LaunchMode.externalApplication);
        return "Opening Google.";
      }
      if (text.contains('open ') && (text.contains('.com') || text.contains('.in'))) {
        final site = text.replaceAll('open ', '').trim();
        final url = site.startsWith('http') ? site : 'https://$site';
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        return "Opening $site.";
      }

      // New tab
      if (text.contains('new tab')) {
        await _runPowerShell(
          r'$wshShell = New-Object -ComObject wscript.shell; $wshShell.SendKeys("^t")'
        );
        return "Opening new tab.";
      }

      // Close tab
      if (text.contains('close tab')) {
        await _runPowerShell(
          r'$wshShell = New-Object -ComObject wscript.shell; $wshShell.SendKeys("^w")'
        );
        return "Closing tab.";
      }

      // Open Downloads folder
      if (text.contains('open downloads') || text.contains('downloads folder')) {
        await Process.run('explorer', [
          '${Platform.environment['USERPROFILE']}\\Downloads'
        ]);
        return "Opening Downloads folder.";
      }

      // Open Documents folder
      if (text.contains('open documents') || text.contains('documents folder')) {
        await Process.run('explorer', [
          '${Platform.environment['USERPROFILE']}\\Documents'
        ]);
        return "Opening Documents folder.";
      }

      // Open Desktop folder
      if (text.contains('open desktop')) {
        await Process.run('explorer', [
          '${Platform.environment['USERPROFILE']}\\Desktop'
        ]);
        return "Opening Desktop.";
      }

      // Screenshot
      if (text.contains('screenshot') || text.contains('take screenshot')) {
        await _runPowerShell(
          r'''Add-Type -AssemblyName System.Windows.Forms;
          [System.Windows.Forms.SendKeys]::SendWait("%{PRTSC}");
          Start-Sleep -m 100;
          $img = [System.Windows.Forms.Clipboard]::GetImage();
          $path = "$env:USERPROFILE\Pictures\Zeni_Screenshot_$(Get-Date -Format 'yyyyMMdd_HHmmss').png";
          $img.Save($path);'''
        );
        return "Screenshot saved to Pictures folder.";
      }

      // Search
      if (text.contains('search ') || text.contains('google ')) {
        final query = text.replaceAll('search ', '').replaceAll('google ', '').trim();
        await launchUrl(
          Uri.parse('https://google.com/search?q=${Uri.encodeComponent(query)}'),
          mode: LaunchMode.externalApplication,
        );
        return "Searching for $query.";
      }

      // Open file explorer
      if (text.contains('open files') || text.contains('file explorer')) {
        await Process.run('explorer', []);
        return "Opening File Explorer.";
      }

      return "Sorry, I could not execute that command on Windows.";

    } catch (e) {
      print("Windows command error: $e");
      return "Something went wrong executing that command.";
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────
  static Future<void> _runPowerShell(String command) async {
    await Process.run('powershell', ['-command', command], runInShell: true);
  }

  static Map<String, int>? _parseTime(String text) {
    // Match patterns like "7am", "7:30am", "10pm", "7 am", "19:00"
    final regexColon = RegExp(r'(\d{1,2}):(\d{2})\s*(am|pm)?');
    final regexSimple = RegExp(r'(\d{1,2})\s*(am|pm)');

    var match = regexColon.firstMatch(text);
    if (match != null) {
      int hour = int.parse(match.group(1)!);
      int minute = int.parse(match.group(2)!);
      final period = match.group(3);
      if (period == 'pm' && hour != 12) hour += 12;
      if (period == 'am' && hour == 12) hour = 0;
      return {'hour': hour, 'minute': minute};
    }

    match = regexSimple.firstMatch(text);
    if (match != null) {
      int hour = int.parse(match.group(1)!);
      final period = match.group(2)!;
      if (period == 'pm' && hour != 12) hour += 12;
      if (period == 'am' && hour == 12) hour = 0;
      return {'hour': hour, 'minute': 0};
    }

    return null;
  }

  static String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final m = minute.toString().padLeft(2, '0');
    return "$h:$m $period";
  }
}