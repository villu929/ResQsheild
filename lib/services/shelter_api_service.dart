import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/incident_models.dart';

/// Service to fetch shelter data from the real backend API.
/// Maps backend JSON fields to [ShelterOccupancy] model used across the app.
class ShelterApiService {
  ShelterApiService._();
  static final ShelterApiService instance = ShelterApiService._();

  /// Backend base URL — change this if you deploy to a different host.
  static const String _baseUrl = 'http://localhost:3000';

  /// Fetches all shelters from /api/shelters.
  /// Returns an empty list on error (app falls back to static mock data).
  Future<List<ShelterOccupancy>> fetchShelters() async {
    try {
      final uri = Uri.parse('$_baseUrl/api/shelters');
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        return [];
      }

      final Map<String, dynamic> body = json.decode(response.body);
      final List<dynamic> rawList = body['shelters'] ?? [];

      return rawList.asMap().entries
          .map((e) => _fromJson(e.value as Map<String, dynamic>, index: e.key))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Maps a single shelter JSON object from the backend to [ShelterOccupancy].
  ShelterOccupancy _fromJson(Map<String, dynamic> json, {int index = -1}) {
    final String id = json['id']?.toString() ?? '';
    final String name = json['name']?.toString() ?? 'Unknown Shelter';

    // Build a human-readable location string: "District, State"
    final String district = json['district']?.toString() ?? '';
    final String state = json['state']?.toString() ?? '';
    final String locationName =
        [district, state].where((s) => s.isNotEmpty).join(', ');
    final String address = json['address']?.toString() ?? '';

    // Coordinates
    double lat = 0.0;
    double lng = 0.0;
    if (json['location'] is Map) {
      lat = (json['location']['lat'] as num?)?.toDouble() ?? 0.0;
      lng = (json['location']['lng'] as num?)?.toDouble() ?? 0.0;
    }

    // Capacity
    final int totalCapacity = (json['total_capacity'] as num?)?.toInt() ?? 0;
    final int occupied = (json['occupied'] as num?)?.toInt() ?? 0;

    // Status mapping — API: "open" | "closed" | "standby"
    final String rawStatus =
        (json['status']?.toString() ?? 'open').toLowerCase();
    final String status = _mapStatus(rawStatus, totalCapacity, occupied);

    // Provisions — Food
    final bool foodAvailable = json['food_available'] == true;
    final int foodPackets =
        (json['food_packets_per_day'] as num?)?.toInt() ?? 0;
    final String mealsType = json['meals_type']?.toString() ?? '';
    final String foodDetails = foodAvailable
        ? '${foodPackets > 0 ? '$foodPackets packets/day' : 'Available'}'
            '${mealsType.isNotEmpty ? ' - $mealsType' : ''}'
        : 'Not available';

    // Provisions — Water
    final bool waterAvailable = json['water_available'] == true;
    final String waterSource = json['water_source']?.toString() ?? '';
    final String waterDetails = waterAvailable
        ? waterSource.isNotEmpty
            ? waterSource
            : 'Available'
        : 'Not available';

    // Provisions — Medical
    final bool medicalAvailable = json['medical_facility'] == true;
    final String medicalDetails =
        json['medical_details']?.toString() ?? '';

    // Contact
    final String contactPerson = json['contact_person']?.toString() ?? '';
    final String contactNumber = json['contact_number']?.toString() ?? '';
    final String alternateContact =
        json['alternate_contact']?.toString() ?? '';
    final String contact = [contactNumber, alternateContact]
        .where((s) => s.isNotEmpty)
        .join(' / ');

    // Images — use first image from array, fallback to Unsplash
    String photoUrl =
        'https://images.unsplash.com/photo-1586769852044-692d6e3703f0?auto=format&fit=crop&w=600&q=80';
    if (json['images'] is List && (json['images'] as List).isNotEmpty) {
      final firstImg = (json['images'] as List).first?.toString() ?? '';
      if (firstImg.startsWith('http')) {
        photoUrl = firstImg;
      }
    }

    // Override shelters with local assets (repeats the 75 images up to 150 containers)
    final List<String> localImages = [
      'assets/images/shelter_community.jpg',
      'assets/images/hospital_ranchi.jpg',
      'assets/images/shelter_school.jpg',
      'assets/images/hospital_dhanbad.jpg',
      'assets/images/hospital_giridih.jpg',
      'assets/images/shelter_images/photo_6.avif',
      'assets/images/shelter_images/photo_7.jpg',
      'assets/images/shelter_images/photo_8.jpg',
      'assets/images/shelter_images/photo_9.jpg',
      'assets/images/shelter_images/photo_10.jpg',
      'assets/images/shelter_images/photo_11.jpg',
      'assets/images/shelter_images/photo_12.jpg',
      'assets/images/shelter_images/photo_13.jpg',
      'assets/images/shelter_images/photo_14.jpg',
      'assets/images/shelter_images/photo_15.jpg',
      'assets/images/shelter_images/photo_16.jpg',
      'assets/images/shelter_images/photo_17.jpg',
      'assets/images/shelter_images/photo_18.jpg',
      'assets/images/shelter_images/photo_19.jpg',
      'assets/images/shelter_images/photo_20.avif',
      'assets/images/shelter_images/21.jpg',
      'assets/images/shelter_images/22.jpg',
      'assets/images/shelter_images/23.jpg',
      'assets/images/shelter_images/24.jpg',
      'assets/images/shelter_images/25.jpg',
      'assets/images/shelter_images/26.jpg',
      'assets/images/shelter_images/27.jpg',
      'assets/images/shelter_images/28.jpg',
      'assets/images/shelter_images/29.jpg',
      'assets/images/shelter_images/30.jpg',
      'assets/images/shelter_images/31.jpg',
      'assets/images/shelter_images/32.jpg',
      'assets/images/shelter_images/33.jpg',
      'assets/images/shelter_images/34.jpg',
      'assets/images/shelter_images/35.jpg',
      'assets/images/shelter_images/36.jpg',
      'assets/images/shelter_images/37.jpg',
      'assets/images/shelter_images/38.jpg',
      'assets/images/shelter_images/39.jpg',
      'assets/images/shelter_images/40.jpg',
      'assets/images/shelter_images/41.jpg',
      'assets/images/shelter_images/42.jpg',
      'assets/images/shelter_images/43.jpg',
      'assets/images/shelter_images/44.jpg',
      'assets/images/shelter_images/45.jpg',
      'assets/images/shelter_images/46.jpg',
      'assets/images/shelter_images/47.jpg',
      'assets/images/shelter_images/48.jpg',
      'assets/images/shelter_images/49.jpg',
      'assets/images/shelter_images/50.jpg',
      'assets/images/shelter_images/51.jpg',
      'assets/images/shelter_images/52.jpg',
      'assets/images/shelter_images/53.jpg',
      'assets/images/shelter_images/54.jpg',
      'assets/images/shelter_images/55.jpg',
      'assets/images/shelter_images/56.jpg',
      'assets/images/shelter_images/57.jpg',
      'assets/images/shelter_images/58.jpg',
      'assets/images/shelter_images/59.jpg',
      'assets/images/shelter_images/60.jpg',
      'assets/images/shelter_images/61.jpg',
      'assets/images/shelter_images/62.jpg',
      'assets/images/shelter_images/63.jpg',
      'assets/images/shelter_images/64.jpg',
      'assets/images/shelter_images/65.jpg',
      'assets/images/shelter_images/66.jpg',
      'assets/images/shelter_images/67.jpg',
      'assets/images/shelter_images/68.jpg',
      'assets/images/shelter_images/69.jpg',
      'assets/images/shelter_images/70.jpg',
      'assets/images/shelter_images/71.jpg',
      'assets/images/shelter_images/72.jpg',
      'assets/images/shelter_images/73.jpg',
      'assets/images/shelter_images/74.jpg',
      'assets/images/shelter_images/75.jpg',
    ];

    if (index >= 0 && index < 150) {
      photoUrl = localImages[index % 75];
    }

    // Services list built from provisions
    final List<String> services = [];
    if (foodAvailable) services.add('Food');
    if (waterAvailable) services.add('Water');
    if (medicalAvailable) services.add('Medical');

    // Last updated timestamp
    DateTime lastUpdated = DateTime.now();
    try {
      final rawDate = json['last_updated']?.toString() ?? '';
      if (rawDate.isNotEmpty) lastUpdated = DateTime.parse(rawDate);
    } catch (_) {}

    return ShelterOccupancy(
      id: id,
      name: name,
      locationName: locationName.isNotEmpty ? locationName : address,
      capacity: totalCapacity,
      occupied: occupied,
      latitude: lat,
      longitude: lng,
      distance: 'N/A',
      foodAvailable: foodAvailable,
      foodDetails: foodDetails,
      waterAvailable: waterAvailable,
      waterDetails: waterDetails,
      medicalAvailable: medicalAvailable,
      medicalDetails:
          medicalDetails.isNotEmpty ? medicalDetails : 'Not available',
      photoUrl: photoUrl,
      services: services,
      contact: contact.isNotEmpty ? contact : 'N/A',
      inchargeName:
          contactPerson.isNotEmpty ? contactPerson : 'Camp In-charge',
      status: status,
      foodPacks: foodPackets,
      waterBottles: 0,
      medicalTeams: medicalAvailable ? 1 : 0,
      isFavorite: false,
      lastUpdated: lastUpdated,
    );
  }

  /// Maps API status string to ShelterOccupancy status constants.
  String _mapStatus(String raw, int capacity, int occupied) {
    switch (raw) {
      case 'open':
        if (capacity > 0) {
          final pct = occupied / capacity;
          if (pct >= 1.0) return 'FULL';
          if (pct >= 0.85) return 'NEAR FULL';
        }
        return 'OPEN';
      case 'closed':
        return 'FULL';
      case 'standby':
        return 'STANDBY';
      default:
        return 'OPEN';
    }
  }
}
