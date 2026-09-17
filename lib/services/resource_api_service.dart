import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:resqshield/models/incident_models.dart';
import 'package:resqshield/services/incident_coordinator.dart';
import 'package:resqshield/services/api_constants.dart';

class ResourceApiService extends ChangeNotifier {
  static final ResourceApiService instance = ResourceApiService._();

  ResourceApiService._() {
    fetchResources();
  }

  final List<ShelterOccupancy> _shelters = [];
  final List<MedicalCenterModel> _medicalCenters = [];

  List<ShelterOccupancy> get shelters => _shelters;
  List<MedicalCenterModel> get medicalCenters => _medicalCenters;

  Future<void> fetchResources() async {
    try {
      final shelterUri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.shelters}');
      final medicalUri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.medical}');

      final shelterRes = await http.get(shelterUri).timeout(ApiConstants.connectTimeout);
      final medicalRes = await http.get(medicalUri).timeout(ApiConstants.connectTimeout);

      if (shelterRes.statusCode == 200) {
        final json = jsonDecode(shelterRes.body);
        if (json['success'] == true) {
          final List data = json['data'] ?? [];
          _shelters.clear();
          for (var item in data) {
            _shelters.add(ShelterOccupancy(
              id: item['id']?.toString() ?? '',
              name: item['name']?.toString() ?? 'Unknown',
              locationName: '${item['city'] ?? ''}, ${item['state'] ?? ''}',
              capacity: item['capacity'] ?? 0,
              occupied: item['occupied'] ?? 0,
              latitude: (item['latitude'] ?? 0.0).toDouble(),
              longitude: (item['longitude'] ?? 0.0).toDouble(),
              distance: 'Unknown', // Default, updated via location services if needed
              foodAvailable: true,
              foodDetails: 'Standard Rations',
              waterAvailable: true,
              waterDetails: 'Available',
              medicalAvailable: true,
              medicalDetails: 'Basic First Aid',
              photoUrl: 'assets/images/shelter_school.png',
              services: ['Food', 'Water', 'Medical'],
              contact: item['contactNumber']?.toString() ?? 'N/A',
              inchargeName: 'Camp In-Charge',
              status: item['status']?.toString().toUpperCase() ?? 'OPEN',
              foodPacks: 100,
              waterBottles: 100,
              medicalTeams: 1,
            ));
          }
        }
      }

      if (medicalRes.statusCode == 200) {
        final json = jsonDecode(medicalRes.body);
        if (json['success'] == true) {
          final List data = json['data'] ?? [];
          _medicalCenters.clear();
          for (var item in data) {
            _medicalCenters.add(MedicalCenterModel(
              id: item['id']?.toString() ?? '',
              name: item['name']?.toString() ?? 'Unknown',
              distance: 'Unknown',
              locationName: '${item['city'] ?? ''}, ${item['state'] ?? ''}',
              photoUrl: 'assets/images/hospital_ranchi.jpg',
              emergencyBeds: item['emergencyBeds'] ?? 0,
              ambulanceUnits: item['ambulanceUnits'] ?? 0,
              bloodBankAvailable: item['bloodBankAvailable'] ?? false,
              phone: item['phone']?.toString() ?? '108',
              latitude: (item['latitude'] ?? 0.0).toDouble(),
              longitude: (item['longitude'] ?? 0.0).toDouble(),
              isOpen: item['isOpen'] ?? true,
            ));
          }
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching resources from API: $e');
    }
  }

  ShelterOccupancy? get nearestShelter {
    if (_shelters.isEmpty) return null;
    return _shelters.first;
  }

  MedicalCenterModel? get nearestMedicalCenter {
    if (_medicalCenters.isEmpty) return null;
    return _medicalCenters.first;
  }

  ShelterOccupancy addShelter({
    required String name,
    required String locationName,
    required int capacity,
    int occupied = 0,
    required double latitude,
    required double longitude,
    String distance = '2.0 km away',
    bool foodAvailable = true,
    String foodDetails = 'Hot Cooked Meals & Dry Rations',
    bool waterAvailable = true,
    String waterDetails = '24/7 RO Purified Water & Tankers',
    bool medicalAvailable = true,
    String medicalDetails = 'Doctor & Paramedic Triage Station',
    String photoUrl = 'https://images.unsplash.com/photo-1586769852044-692d6e3703f0?auto=format&fit=crop&w=600&q=80',
    List<String> services = const ['Meals', 'Drinking Water', 'Medical Station', 'Power Backup', 'Sanitation'],
    String contact = '+91 94361 20099',
    String inchargeName = 'Camp Commander',
    String status = 'OPEN',
    int foodPacks = 1200,
    int waterBottles = 1800,
    int medicalTeams = 2,
  }) {
    final newId = 'SH-${(_shelters.length + 1).toString().padLeft(2, "0")}';
    final shelter = ShelterOccupancy(
      id: newId,
      name: name,
      locationName: locationName,
      capacity: capacity,
      occupied: occupied,
      latitude: latitude,
      longitude: longitude,
      distance: distance,
      foodAvailable: foodAvailable,
      foodDetails: foodDetails,
      waterAvailable: waterAvailable,
      waterDetails: waterDetails,
      medicalAvailable: medicalAvailable,
      medicalDetails: medicalDetails,
      photoUrl: photoUrl,
      services: List.from(services),
      contact: contact,
      inchargeName: inchargeName,
      status: status,
      foodPacks: foodPacks,
      waterBottles: waterBottles,
      medicalTeams: medicalTeams,
      lastUpdated: DateTime.now(),
    );

    _shelters.insert(0, shelter);

    IncidentCoordinator.instance.broadcastEvent(LiveEvent(
      type: LiveEventType.shelterUpdated,
      title: '🏠 NEW RELIEF SHELTER OPENED',
      message: '$name opened at $locationName with $capacity bed capacity. Food, water, and medical provisions active.',
      payload: shelter,
    ));

    notifyListeners();
    return shelter;
  }

  void updateShelter({
    required String id,
    String? name,
    String? locationName,
    int? capacity,
    int? occupied,
    double? latitude,
    double? longitude,
    String? distance,
    bool? foodAvailable,
    String? foodDetails,
    bool? waterAvailable,
    String? waterDetails,
    bool? medicalAvailable,
    String? medicalDetails,
    String? photoUrl,
    List<String>? services,
    String? contact,
    String? inchargeName,
    String? status,
    int? foodPacks,
    int? waterBottles,
    int? medicalTeams,
  }) {
    final index = _shelters.indexWhere((s) => s.id == id);
    if (index == -1) return;

    final old = _shelters[index];
    final updated = old.copyWith(
      name: name,
      locationName: locationName,
      capacity: capacity,
      occupied: occupied,
      latitude: latitude,
      longitude: longitude,
      distance: distance,
      foodAvailable: foodAvailable,
      foodDetails: foodDetails,
      waterAvailable: waterAvailable,
      waterDetails: waterDetails,
      medicalAvailable: medicalAvailable,
      medicalDetails: medicalDetails,
      photoUrl: photoUrl,
      services: services,
      contact: contact,
      inchargeName: inchargeName,
      status: status,
      foodPacks: foodPacks,
      waterBottles: waterBottles,
      medicalTeams: medicalTeams,
      lastUpdated: DateTime.now(),
    );

    _shelters[index] = updated;

    IncidentCoordinator.instance.broadcastEvent(LiveEvent(
      type: LiveEventType.shelterUpdated,
      title: '🏠 SHELTER DETAILS UPDATED',
      message: '${updated.name}: Capacity ${updated.occupied}/${updated.capacity} (${updated.available} available). Provisions & Medical facilities updated.',
      payload: updated,
    ));

    notifyListeners();
  }

  void toggleFavoriteShelter(String id) {
    final index = _shelters.indexWhere((s) => s.id == id);
    if (index == -1) return;

    final old = _shelters[index];
    _shelters[index] = old.copyWith(
      isFavorite: !old.isFavorite,
    );
    notifyListeners();
  }

  void deleteShelter(String id) {
    final index = _shelters.indexWhere((s) => s.id == id);
    if (index == -1) return;
    final removed = _shelters.removeAt(index);

    IncidentCoordinator.instance.broadcastEvent(LiveEvent(
      type: LiveEventType.shelterUpdated,
      title: '🏠 SHELTER DECOMMISSIONED',
      message: '${removed.name} has been archived/decommissioned.',
      payload: removed,
    ));

    notifyListeners();
  }
}
