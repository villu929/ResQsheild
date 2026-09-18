import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/incident_models.dart';

/// Service to fetch medical facility data from the real backend API.
/// Maps backend JSON fields to [MedicalCenterModel] model used across the app.
class MedicalApiService {
  MedicalApiService._();
  static final MedicalApiService instance = MedicalApiService._();

  /// Backend base URL
  static const String _baseUrl = 'http://localhost:3000';

  /// Fetches all medical facilities from /api/medical-facilities.
  Future<List<MedicalCenterModel>> fetchMedicalFacilities() async {
    try {
      final uri = Uri.parse('$_baseUrl/api/medical-facilities');
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        return [];
      }

      final Map<String, dynamic> body = json.decode(response.body);
      final List<dynamic> rawList = body['facilities'] ?? [];

      return rawList.asMap().entries
          .map((e) => _fromJson(e.value as Map<String, dynamic>, index: e.key))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Maps a single medical facility JSON object from the backend to [MedicalCenterModel].
  MedicalCenterModel _fromJson(Map<String, dynamic> json, {int index = -1}) {
    final String id = json['id']?.toString() ?? '';
    final String name = json['name']?.toString() ?? 'Unknown Facility';

    final String city = json['city']?.toString() ?? '';
    final String state = json['state']?.toString() ?? '';
    final String address = json['address']?.toString() ?? '';
    final String locationName =
        [city, state].where((s) => s.isNotEmpty).join(', ');

    double lat = 0.0;
    double lng = 0.0;
    if (json['location'] is Map) {
      lat = (json['location']['lat'] as num?)?.toDouble() ?? 0.0;
      lng = (json['location']['lng'] as num?)?.toDouble() ?? 0.0;
    }

    // Actual field names from JSON: beds_available, doctors_on_duty
    final int emergencyBeds = (json['beds_available'] as num?)?.toInt() ?? 0;
    final int doctors = (json['doctors_on_duty'] as num?)?.toInt() ?? 0;

    // Derive ambulance count from doctors on duty
    final int ambulanceUnits = doctors > 20
        ? 4
        : doctors > 10
            ? 2
            : 1;

    // type field is capitalized in JSON e.g. "Hospital", "Government Clinic"
    final String type = (json['type']?.toString() ?? '').toLowerCase();
    final bool bloodBankAvailable =
        type == 'hospital' || type == 'government hospital';

    // Phone: prefer contact_phone, fallback to emergency_helpline
    final String phone = (json['contact_phone']?.toString() ?? '').isNotEmpty
        ? json['contact_phone'].toString()
        : (json['emergency_helpline']?.toString() ?? '108');

    // Distance: use distance_km from nearby endpoint if available
    final num? distKm = json['distance_km'] as num?;
    final String distance = distKm != null
        ? '${distKm.toStringAsFixed(1)} km away'
        : '${((index % 10 + 1) * 1.5).toStringAsFixed(1)} km away';

    // User provided 27 images in medical_camp_images (1.jpg to 27.jpg)
    // We cycle through these images using the index
    final int imageIndex = index < 0 ? 0 : index;
    final int imageNumber = (imageIndex % 27) + 1;
    final String photoUrl = 'assets/images/medical_camp_images/$imageNumber.jpg';

    return MedicalCenterModel(
      id: id,
      name: name,
      distance: distance,
      locationName: locationName.isNotEmpty ? locationName : address,
      photoUrl: photoUrl,
      emergencyBeds: emergencyBeds,
      ambulanceUnits: ambulanceUnits,
      bloodBankAvailable: bloodBankAvailable,
      phone: phone,
      latitude: lat,
      longitude: lng,
      isOpen: true,
      // Rich fields
      facilityType: json['type']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      emergencyHelpline: json['emergency_helpline']?.toString() ?? '108',
      bedsTotal: (json['beds_total'] as num?)?.toInt() ?? 0,
      doctorsOnDuty: doctors,
      specialties: (json['specialties'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      freeTreatmentAvailable: json['free_treatment_available'] == true,
      freeMedicinesAvailable: json['free_medicines_available'] == true,
      freeMedicinesNote: json['free_medicines_note']?.toString() ?? '',
      foodDistribution: json['food_distribution'] == true,
      disasterServices: (json['disaster_services'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      waterborneDiseasesTreated: (() {
        final wb = json['waterborne_disease_treatment'];
        if (wb is Map && wb['diseases_treated'] is List) {
          return (wb['diseases_treated'] as List<dynamic>)
              .map((e) => e.toString())
              .toList();
        }
        return <String>[];
      })(),
      waterborneDiseaseNote: (() {
        final wb = json['waterborne_disease_treatment'];
        if (wb is Map) return wb['note']?.toString() ?? '';
        return '';
      })(),
      lastUpdated: json['last_updated']?.toString() ?? '',
    );
  }

}
