/// JalGuard Backend API configuration constants.
/// Base URL is configurable via `--dart-define=API_BASE_URL=...`
/// Defaults to the deployed production backend.
class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://jalguard-flood-api-production.up.railway.app',
  );

  // Core endpoints
  static const String floodsLive = '/api/floods/live';
  static const String floodsSources = '/api/floods/sources';
  static const String floodsAlerts = '/api/floods/alerts';
  static const String waterLevels = '/api/water-levels';
  static const String rainfall = '/api/rainfall';
  static const String weatherWarnings = '/api/weather-warnings';
  static const String layers = '/api/layers';

  // Tile URL template for WMS raster flood inundation
  static String floodTileUrl(int z, int x, int y) =>
      '$baseUrl/api/tiles/gfm/$z/$x/$y.png';

  static String floodTileTemplate =
      '$baseUrl/api/tiles/gfm/{z}/{x}/{y}.png';

  // Network timeout configurations
  static const Duration connectTimeout = Duration(seconds: 12);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
