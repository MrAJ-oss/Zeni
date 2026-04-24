import 'package:device_apps/device_apps.dart';

class AppService {
  static Future<void> openApp(String name) async {
    List apps = await DeviceApps.getInstalledApplications();

    for (var app in apps) {
      if (app.appName.toLowerCase().contains(name.toLowerCase())) {
        DeviceApps.openApp(app.packageName);
        return;
      }
    }
  }
}