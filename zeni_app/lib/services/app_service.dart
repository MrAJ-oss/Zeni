// ignore: unused_import
// ignore_for_file: strict_top_level_inference

// ignore: unused_import
import 'package:device_apps_plus/device_apps_plus.dart';

class AppService {
  // ignore: non_constant_identifier_names
  static get DeviceApps => null;

  static Future<void> openApp(String name) async {
    List apps = await DeviceApps.getInstalledApplications();

    for (var app in apps) {
      if (app.appName.toLowerCase().contains(name.toLowerCase())) {
        await DeviceApps.openApp(app.packageName);
        return;
      }
    }
  }
}

