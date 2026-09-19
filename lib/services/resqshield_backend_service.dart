import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for interacting with the FastAPI disaster intelligence backend.
class ResqshieldBackendService {
  ResqshieldBackendService._();
  static final ResqshieldBackendService instance = ResqshieldBackendService._();

  static const String _baseUrl = 'http://127.0.0.1:8000/api/v1';

  /// Fetch health and data source status
  Future<Map<String, dynamic>?> fetchHealth() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/health')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) { print('API ERROR: $e'); }
    return null;
  }

  /// Fetch high flood risk districts
  Future<List<Map<String, dynamic>>> fetchFloodRiskDistricts({int limit = 3}) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/risk/districts?limit=$limit')).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['data'] != null && body['data'] is List) {
          return List<Map<String, dynamic>>.from(body['data']);
        }
      }
    } catch (e) { print('API ERROR: $e'); }
    return [];
  }

  /// Fetch active landslide zones
  Future<List<Map<String, dynamic>>> fetchLandslideDistricts({int limit = 3}) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/landslide/districts?limit=$limit')).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['data'] != null && body['data'] is List) {
          return List<Map<String, dynamic>>.from(body['data']);
        }
      }
    } catch (e) { print('API ERROR: $e'); }
    return [];
  }

  /// Fetch intelligence summary
  Future<Map<String, dynamic>?> fetchIntelligenceSummary() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/intelligence/summary')).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) { print('API ERROR: $e'); }
    return null;
  }
  /// Fetch hazards summary
  Future<Map<String, dynamic>?> fetchHazardsSummary() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/hazards/summary')).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) { print('API ERROR: $e'); }
    return null;
  }

  /// Fetch active hazards districts
  Future<List<Map<String, dynamic>>> fetchHazardsDistricts({int limit = 3}) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/hazards/districts?limit=$limit')).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['data'] != null && body['data'] is List) {
          return List<Map<String, dynamic>>.from(body['data']);
        }
      }
    } catch (e) { print('API ERROR: $e'); }
    return [];
  }

  /// Fetch GPM summary
  Future<Map<String, dynamic>?> fetchGpmSummary() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/gpm/summary')).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) { print('API ERROR: $e'); }
    return null;
  }

  /// Fetch GPM rainfall at location
  Future<Map<String, dynamic>?> fetchGpmRainfall({required double lat, required double lon}) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/gpm/rainfall?lat=$lat&lon=$lon')).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) { print('API ERROR: $e'); }
    return null;
  }

  /// Fetch risk at location
  Future<Map<String, dynamic>?> fetchLocationRisk({required double lat, required double lon}) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/risk/location?lat=$lat&lon=$lon')).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) { print('API ERROR: $e'); }
    return null;
  }
}
