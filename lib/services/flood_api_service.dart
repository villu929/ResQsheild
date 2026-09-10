import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/flood_data_models.dart';
import 'api_constants.dart';

class FloodApiService {
  static final FloodApiService _instance = FloodApiService._internal();
  factory FloodApiService() => _instance;
  FloodApiService._internal();

  final http.Client _client = http.Client();

  // Cached state
  FloodLiveResponse? _lastResponse;
  LayersInfo? _lastLayers;
  DateTime? _lastFetchTime;
  String? _lastErrorMessage;

  FloodLiveResponse? get lastResponse => _lastResponse;
  LayersInfo? get lastLayers => _lastLayers;
  DateTime? get lastFetchTime => _lastFetchTime;
  String? get lastErrorMessage => _lastErrorMessage;

  /// Fetches live flood monitoring data from backend.
  Future<FloodLiveResponse> fetchLiveFloods({double? lat, double? lng}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.floodsLive}');

    try {
      final response = await _client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'ResQshield-JalGuard/1.0',
            },
          )
          .timeout(ApiConstants.connectTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

        final result = FloodLiveResponse.fromJson(data);
        _lastResponse = result;
        _lastFetchTime = DateTime.now();
        _lastErrorMessage = null;
        return result;
      } else {
        throw Exception(
          'Failed to load flood data (HTTP ${response.statusCode})',
        );
      }
    } on TimeoutException {
      _lastErrorMessage = 'Connection timed out while contacting flood API.';
      throw Exception(_lastErrorMessage);
    } catch (e) {
      _lastErrorMessage = e.toString().replaceAll('Exception: ', '');
      rethrow;
    }
  }

  /// Fetches layer status configurations.
  Future<LayersInfo> fetchLayers() async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.layers}');

    try {
      final response = await _client
          .get(
            uri,
            headers: {'Accept': 'application/json'},
          )
          .timeout(ApiConstants.connectTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final layers = LayersInfo.fromJson(data);
        _lastLayers = layers;
        return layers;
      }
    } catch (_) {}

    // Safe fallback if layers endpoint is unreachable
    return LayersInfo(
      floodInundationEnabled: true,
      floodInundationSource: 'CEMS GFM',
      floodInundationUrl: '/api/tiles/gfm/{z}/{x}/{y}.png',
      governmentAlertsEnabled: true,
      governmentAlertsSource: 'SACHET / NDMA',
      waterLevelsEnabled: false,
      rainfallEnabled: false,
    );
  }

  /// Fetches active government disaster alerts if available.
  Future<List<FloodFeatureItem>> fetchGovernmentAlerts() async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.floodsAlerts}');

    try {
      final response = await _client
          .get(
            uri,
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final alerts = <FloodFeatureItem>[];
        if (data['features'] is List) {
          for (final f in data['features'] as List) {
            if (f is Map<String, dynamic>) {
              alerts.add(FloodFeatureItem.fromJson(f));
            }
          }
        }
        return alerts;
      }
    } catch (_) {}
    return [];
  }

  /// Evaluates whether current data is truly LIVE, STALE, EMPTY, or ERROR.
  /// Strictly ensures stale data is NEVER labeled as "Live".
  FloodDataStatus evaluateStatus({
    required FloodLiveResponse? response,
    required bool isLoading,
    required bool hasError,
  }) {
    if (isLoading && response == null) return FloodDataStatus.loading;
    if (hasError && response == null) return FloodDataStatus.error;
    if (response == null) return FloodDataStatus.empty;

    // Check if meta status indicates stale or test
    final metaStatus = response.meta.status.toLowerCase();
    if (metaStatus.contains('stale') ||
        metaStatus.contains('historical') ||
        metaStatus.contains('outdated')) {
      return FloodDataStatus.stale;
    }

    // If fetched more than 30 minutes ago without fresh sync
    if (_lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!).inMinutes > 30) {
      return FloodDataStatus.stale;
    }

    return FloodDataStatus.live;
  }
}
