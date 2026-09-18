import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationApiService {
  LocationApiService._();
  static final LocationApiService instance = LocationApiService._();

  static const String _baseUrl = 'http://localhost:3000';

  Future<List<String>> fetchStates() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/locations/states'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(data['states'] ?? []);
      }
    } catch (_) {}
    return [];
  }

  Future<List<String>> fetchCities(String state) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/locations/cities').replace(queryParameters: {'state': state});
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(data['cities'] ?? []);
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, double>?> fetchCoordinates(String state, {String? city}) async {
    try {
      final queryParams = {'state': state};
      if (city != null && city.isNotEmpty) {
        queryParams['city'] = city;
      }
      final uri = Uri.parse('$_baseUrl/api/locations/coordinates').replace(queryParameters: queryParams);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['lat'] != null && data['lng'] != null) {
          return {
            'lat': (data['lat'] as num).toDouble(),
            'lng': (data['lng'] as num).toDouble(),
          };
        }
      }
    } catch (_) {}
    return null;
  }
}
