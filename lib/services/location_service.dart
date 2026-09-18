import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// A singleton service that stores the "active" location used by
/// Nearby filters across the entire app.
///
/// Priority:
///   1. Manual selection (user searched/picked a location)
///   2. Browser/GPS position
///   3. null (no location available)
class LocationService extends ChangeNotifier {
  LocationService._();
  static final LocationService instance = LocationService._();

  // Browser / GPS position (auto-fetched)
  Position? _gpsPosition;

  // Manually selected position (user typed & picked a place)
  double? _manualLat;
  double? _manualLng;
  String? _manualName; // e.g. "Guwahati, Assam"

  bool _isFetchingGps = false;
  String? _locationError;

  // Getters
  double? get activeLat => _manualLat ?? _gpsPosition?.latitude;
  double? get activeLng => _manualLng ?? _gpsPosition?.longitude;
  String? get activeName => _manualName;
  bool get isFetchingGps => _isFetchingGps;
  bool get hasLocation => activeLat != null && activeLng != null;
  String? get locationError => _locationError;
  bool get isManual => _manualLat != null;

  Future<void> fetchGps() async {
    if (_isFetchingGps) return;
    _isFetchingGps = true;
    _locationError = null;
    notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _locationError = 'Location services disabled.';
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _locationError = 'Location permission denied.';
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      _gpsPosition = pos;
      debugPrint(
          'LocationService GPS: ${pos.latitude}, ${pos.longitude}  accuracy=${pos.accuracy}m');
    } catch (e) {
      _locationError = 'Unable to get location: $e';
      debugPrint('LocationService GPS error: $e');
    } finally {
      _isFetchingGps = false;
      notifyListeners();
    }
  }

  void setManualLocation(double lat, double lng, String name) {
    _manualLat = lat;
    _manualLng = lng;
    _manualName = name;
    _locationError = null;
    debugPrint('LocationService manual: $name  ($lat, $lng)');
    notifyListeners();
  }

  void clearManualLocation() {
    _manualLat = null;
    _manualLng = null;
    _manualName = null;
    notifyListeners();
  }
}
