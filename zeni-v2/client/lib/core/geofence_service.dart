import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeofenceService {
  final void Function() onEnteredHome;
  StreamSubscription<Position>? _sub;
  bool _wasInside = true; // assume inside on start so first fix doesn't fire a false trigger

  GeofenceService({required this.onEnteredHome});

  Future<bool> start() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('geofence_enabled') ?? false;
    final lat = prefs.getDouble('home_lat');
    final lng = prefs.getDouble('home_lng');
    final radius = prefs.getDouble('home_radius_m') ?? 100;
    if (!enabled || lat == null || lng == null) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return false;
    }

    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, distanceFilter: 25),
    ).listen((pos) {
      final distance = Geolocator.distanceBetween(pos.latitude, pos.longitude, lat, lng);
      final isInside = distance <= radius;
      if (isInside && !_wasInside) {
        onEnteredHome();
      }
      _wasInside = isInside;
    });

    return true;
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  static Future<void> setHomeToCurrentLocation({double radiusMeters = 100}) async {
    final pos = await Geolocator.getCurrentPosition();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('home_lat', pos.latitude);
    await prefs.setDouble('home_lng', pos.longitude);
    await prefs.setDouble('home_radius_m', radiusMeters);
  }
}
