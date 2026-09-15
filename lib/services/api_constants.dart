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
  // NOTE: The Railway backend currently returns `text/xml` (WMS GetCapabilities
  // or error XML) instead of PNG tiles, causing ImageCodecException in Flutter.
  // Set [floodTilesAvailable] to true only when the backend serves valid
  // image/png tiles at this endpoint.
  static String floodTileUrl(int z, int x, int y) =>
      '$baseUrl/api/tiles/gfm/$z/$x/$y.png';

  static String floodTileTemplate =
      '$baseUrl/api/tiles/gfm/{z}/{x}/{y}.png';

  /// Set to true when the flood tile endpoint returns valid PNG tiles.
  /// Currently false because the server returns text/xml (WMS error XML),
  /// which causes [ImageCodecException] in flutter_map's TileLayer.
  static const bool floodTilesAvailable = false;

  // Network timeout configurations
  static const Duration connectTimeout = Duration(seconds: 12);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
