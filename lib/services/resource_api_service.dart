import 'package:flutter/material.dart';
import 'package:resqshield/models/incident_models.dart';
import 'package:resqshield/services/incident_coordinator.dart';
import 'package:resqshield/services/shelter_api_service.dart';
import 'package:resqshield/services/medical_api_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:resqshield/services/location_service.dart';
class ResourceApiService extends ChangeNotifier {
  static final ResourceApiService instance = ResourceApiService._();

  bool _isLoadingFromApi = false;
  bool get isLoadingFromApi => _isLoadingFromApi;

  ResourceApiService._() {
    _initData();
  }

  final List<ShelterOccupancy> _shelters = [];
  final List<MedicalCenterModel> _medicalCenters = [];

  List<ShelterOccupancy> get shelters => _shelters;
  List<MedicalCenterModel> get medicalCenters => _medicalCenters;

  Future<void> _initData() async {
    // Load static mock data first so the UI has something to show immediately
    _loadMockShelters();
    _initMedicalCenters();
    // Then attempt to replace with live API data
    await loadSheltersFromApi();
    await loadMedicalFacilitiesFromApi();
  }

  /// Public method — call this to manually refresh shelter data from the API.
  Future<void> loadSheltersFromApi() async {
    _isLoadingFromApi = true;
    notifyListeners();
    try {
      final apiShelters = await ShelterApiService.instance.fetchShelters();
      if (apiShelters.isNotEmpty) {
        if (apiShelters.length >= 41) {
          final temp = apiShelters[0];
          apiShelters[0] = apiShelters[40];
          apiShelters[40] = temp;
        }
        _shelters.clear();
        _shelters.addAll(apiShelters);
        notifyListeners();
      }
    } finally {
      _isLoadingFromApi = false;
      notifyListeners();
    }
  }

  /// Public method — call this to manually refresh medical data from the API.
  Future<void> loadMedicalFacilitiesFromApi() async {
    _isLoadingFromApi = true;
    notifyListeners();
    try {
      final apiMedicalCenters = await MedicalApiService.instance.fetchMedicalFacilities();
      if (apiMedicalCenters.isNotEmpty) {
        _medicalCenters.clear();
        _medicalCenters.addAll(apiMedicalCenters);
        notifyListeners();
      }
    } finally {
      _isLoadingFromApi = false;
      notifyListeners();
    }
  }

  void _loadMockShelters() {
    _shelters.addAll([
      ShelterOccupancy(
        id: 'SH-01',
        name: 'Govt. Higher Secondary School, Karala',
        locationName: 'Karala, Delhi',
        capacity: 500,
        occupied: 180,
        latitude: 28.7350,
        longitude: 77.0500,
        distance: '2.8 km',
        foodAvailable: true,
        foodDetails: '1200 packs hot meals & nutrient rations',
        waterAvailable: true,
        waterDetails: '1800 bottles sealed drinking water',
        medicalAvailable: true,
        medicalDetails: '2 triage teams on active duty',
        foodPacks: 1200,
        waterBottles: 1800,
        medicalTeams: 2,
        photoUrl: 'https://images.unsplash.com/photo-1580582932707-520aed937b7b?auto=format&fit=crop&w=600&q=80',
        services: ['Food', 'Water', 'Medical', 'Sanitation', 'Charging', 'Security'],
        contact: '+91 98765 43210',
        inchargeName: 'R. K. Verma (Principal)',
        status: 'OPEN',
      ),
      ShelterOccupancy(
        id: 'SH-02',
        name: 'Community Hall, Narela',
        locationName: 'Narela, Delhi',
        capacity: 300,
        occupied: 180,
        latitude: 28.8500,
        longitude: 77.1000,
        distance: '3.6 km',
        foodAvailable: true,
        foodDetails: '800 packs community food rations',
        waterAvailable: true,
        waterDetails: '1100 bottles potable water',
        medicalAvailable: true,
        medicalDetails: '1 doctor team on standby',
        foodPacks: 800,
        waterBottles: 1100,
        medicalTeams: 1,
        photoUrl: 'https://images.unsplash.com/photo-1517457373958-b7bdd4587205?auto=format&fit=crop&w=600&q=80',
        services: ['Food', 'Water', 'Medical', 'Sanitation', 'Charging'],
        contact: '+91 98765 43211',
        inchargeName: 'Sunil Soren (Coordinator)',
        status: 'LIMITED',
      ),
      ShelterOccupancy(
        id: 'SH-03',
        name: 'Rohini Sector 5 Relief Camp',
        locationName: 'Rohini, Delhi',
        capacity: 450,
        occupied: 240,
        latitude: 28.7150,
        longitude: 77.1050,
        distance: '4.2 km',
        foodAvailable: true,
        foodDetails: '1000 packs medical diet rations',
        waterAvailable: true,
        waterDetails: '1500 bottles purified water',
        medicalAvailable: true,
        medicalDetails: '4 doctor & trauma teams on-site',
        foodPacks: 1000,
        waterBottles: 1500,
        medicalTeams: 4,
        photoUrl: 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&w=600&q=80',
        services: ['Food', 'Water', 'Medical', 'Sanitation', 'Charging', 'Security'],
        contact: '+91 98765 43212',
        inchargeName: 'Dr. Amit Sinha (CMO)',
        status: 'OPEN',
      ),
      ShelterOccupancy(
        id: 'SH-04',
        name: 'Relief Camp - Dhansar',
        locationName: 'Hazaribagh, Jharkhand',
        capacity: 800,
        occupied: 240,
        latitude: 23.9925,
        longitude: 85.3637,
        distance: '5.1 km',
        foodAvailable: true,
        foodDetails: '2200 packs cooked food & baby nutrition',
        waterAvailable: true,
        waterDetails: '3100 bottles & 2 water tankers',
        medicalAvailable: true,
        medicalDetails: '3 emergency response medical teams',
        foodPacks: 2200,
        waterBottles: 3100,
        medicalTeams: 3,
        photoUrl: 'https://images.unsplash.com/photo-1586769852044-692d6e3703f0?auto=format&fit=crop&w=600&q=80',
        services: ['Food', 'Water', 'Medical', 'Sanitation', 'Charging', 'Security'],
        contact: '+91 98765 43213',
        inchargeName: 'Maj. V. K. Singh (Retd.)',
        status: 'OPEN',
      ),
      ShelterOccupancy(
        id: 'SH-05',
        name: 'Pitampura Relief Center',
        locationName: 'Pitampura, Delhi',
        capacity: 500,
        occupied: 180,
        latitude: 28.6980,
        longitude: 77.1350,
        distance: '2.8 km',
        foodAvailable: true,
        foodDetails: '1200 packs food & energy supplements',
        waterAvailable: true,
        waterDetails: '1800 bottles drinking water',
        medicalAvailable: true,
        medicalDetails: '2 medical teams 24/7 active',
        foodPacks: 1200,
        waterBottles: 1800,
        medicalTeams: 2,
        photoUrl: 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?auto=format&fit=crop&w=600&q=80',
        services: ['Food', 'Water', 'Medical', 'Sanitation', 'Charging', 'Security'],
        contact: '+91 98765 43210',
        inchargeName: 'District Relief Officer',
        status: 'OPEN',
      ),
      ShelterOccupancy(
        id: 'SH-06',
        name: 'Meenakshipuram Community Center',
        locationName: 'Sector A • 2.3 km',
        capacity: 100,
        occupied: 72,
        latitude: 25.4550,
        longitude: 91.7620,
        distance: '2.3 km',
        foodAvailable: true,
        foodDetails: 'Cooked Meals & Hot Soup Kitchen',
        waterAvailable: true,
        waterDetails: '24/7 RO Potable Drinking Water',
        medicalAvailable: true,
        medicalDetails: 'Doctor & Red Cross Medical Desk',
        foodPacks: 600,
        waterBottles: 800,
        medicalTeams: 1,
        photoUrl: 'https://images.unsplash.com/photo-1517457373958-b7bdd4587205?auto=format&fit=crop&w=600&q=80',
        services: ['Food', 'Water', 'Medical', 'Charging', 'Sanitation'],
        contact: '+91 94361 20011',
        inchargeName: 'K. S. Varma (DRO)',
        status: 'Available',
      ),
      ShelterOccupancy(
        id: 'SH-07',
        name: 'Narela General Hospital',
        locationName: 'Sector 1, Narela',
        capacity: 200,
        occupied: 184,
        latitude: 28.8450,
        longitude: 77.1020,
        distance: '4.1 km',
        foodAvailable: true,
        foodDetails: 'High-Calorie Biscuits & Packaged Meals',
        waterAvailable: true,
        waterDetails: 'Municipal Tanker Water Supply',
        medicalAvailable: true,
        medicalDetails: 'SDRF Paramedic Triage Post',
        foodPacks: 450,
        waterBottles: 600,
        medicalTeams: 1,
        photoUrl: 'https://images.unsplash.com/photo-1580582932707-520aed937b7b?auto=format&fit=crop&w=600&q=80',
        services: ['Food', 'Water', 'Sanitation', 'Charging'],
        contact: '+91 94361 20022',
        inchargeName: 'Sister Teresa',
        status: 'Near Capacity',
      ),
      ShelterOccupancy(
        id: 'SH-08',
        name: 'Rohini Emergency Care Unit',
        locationName: 'Sector 5, Rohini',
        capacity: 200,
        occupied: 200,
        latitude: 28.7180,
        longitude: 77.1080,
        distance: '6.8 km',
        foodAvailable: true,
        foodDetails: 'Emergency Rations Only',
        waterAvailable: true,
        waterDetails: 'Packaged Water Bottles',
        medicalAvailable: false,
        medicalDetails: 'First Aid Kit Only',
        foodPacks: 200,
        waterBottles: 300,
        medicalTeams: 0,
        photoUrl: 'https://images.unsplash.com/photo-1586769852044-692d6e3703f0?auto=format&fit=crop&w=600&q=80',
        services: ['Food', 'Water', 'Sanitation'],
        contact: '+91 94361 20033',
        inchargeName: 'Camp Lead Roy',
        status: 'Full',
      ),
      ShelterOccupancy(
        id: 'SH-09',
        name: 'Northeast Indoor Stadium',
        locationName: 'Sector D • 3.6 km',
        capacity: 250,
        occupied: 120,
        latitude: 25.5890,
        longitude: 91.9050,
        distance: '3.6 km',
        foodAvailable: true,
        foodDetails: 'Mega Community Kitchen (2,000 Meals/Day)',
        waterAvailable: true,
        waterDetails: 'Continuous Municipal Supply & 3 Tankers',
        medicalAvailable: true,
        medicalDetails: 'Full Field Hospital with 10 Beds',
        foodPacks: 1500,
        waterBottles: 2400,
        medicalTeams: 3,
        photoUrl: 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?auto=format&fit=crop&w=600&q=80',
        services: ['Food', 'Water', 'Medical', 'Sanitation', 'Charging', 'Security'],
        contact: '+91 364 222 4455',
        inchargeName: 'Dr. A. Bannerjee',
        status: 'Available',
      ),
      ShelterOccupancy(
        id: 'SH-10',
        name: 'Karala Main Medical Center',
        locationName: 'Sector 4, Karala',
        capacity: 200,
        occupied: 150,
        latitude: 28.7360,
        longitude: 77.0510,
        distance: '1.6 km',
        foodAvailable: true,
        foodDetails: '3 Fresh Cooked Meals Daily & Dry Rations',
        waterAvailable: true,
        waterDetails: '24/7 RO Potable Water & Municipal Tanker',
        medicalAvailable: true,
        medicalDetails: 'Doctor & SDRF Triage Unit On-Site',
        foodPacks: 900,
        waterBottles: 1200,
        medicalTeams: 2,
        photoUrl: 'https://images.unsplash.com/photo-1586769852044-692d6e3703f0?auto=format&fit=crop&w=600&q=80',
        services: ['Food', 'Water', 'Medical', 'Sanitation', 'Charging', 'Security'],
        contact: '+91 94361 20055',
        inchargeName: 'P. Lyngdoh (DRO)',
        status: 'Available',
      ),
    ]);
  }

  void _initMedicalCenters() {
    _medicalCenters.addAll([
      MedicalCenterModel(
        id: 'M-01',
        name: 'District General Hospital',
        distance: '3.2 km away',
        locationName: 'Sector 1 Civic Center',
        photoUrl: 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&w=600&q=80',
        emergencyBeds: 18,
        ambulanceUnits: 3,
        bloodBankAvailable: true,
        phone: '06542-230001',
        latitude: 23.8060,
        longitude: 86.4220,
      ),
      MedicalCenterModel(
        id: 'M-02',
        name: 'City Care Hospital',
        distance: '4.8 km away',
        locationName: 'Sector 5 Near Highway',
        photoUrl: 'https://images.unsplash.com/photo-1587351021759-3e566b6af7cc?auto=format&fit=crop&w=600&q=80',
        emergencyBeds: 12,
        ambulanceUnits: 1,
        bloodBankAvailable: false,
        phone: '06542-230002',
        latitude: 23.8120,
        longitude: 86.4250,
      ),
      MedicalCenterModel(
        id: 'M-03',
        name: 'Relief Camp Medical Unit',
        distance: '1.2 km away',
        locationName: 'Temporary Govt Shelter',
        photoUrl: 'https://images.unsplash.com/photo-1579684385127-1ef15d508118?auto=format&fit=crop&w=600&q=80',
        emergencyBeds: 5,
        ambulanceUnits: 2,
        bloodBankAvailable: true,
        phone: '108',
        latitude: 23.7990,
        longitude: 86.4340,
      ),
      MedicalCenterModel(
        id: 'M-04',
        name: 'Karala Main Hospital',
        distance: '0.5 km away',
        locationName: 'Karala Main Road, Delhi',
        photoUrl: 'https://images.unsplash.com/photo-1538108149393-cebb47cbdc17?auto=format&fit=crop&w=600&q=80',
        emergencyBeds: 25,
        ambulanceUnits: 4,
        bloodBankAvailable: true,
        phone: '011-23000004',
        latitude: 28.7365,
        longitude: 77.0525,
      ),
      MedicalCenterModel(
        id: 'M-05',
        name: 'Sanjeevani Clinic, Narela',
        distance: '5.1 km away',
        locationName: 'Narela, Delhi',
        photoUrl: 'https://images.unsplash.com/photo-1512678080530-7760d81faba6?auto=format&fit=crop&w=600&q=80',
        emergencyBeds: 8,
        ambulanceUnits: 1,
        bloodBankAvailable: false,
        phone: '011-23000005',
        latitude: 28.8505,
        longitude: 77.1010,
      ),
      MedicalCenterModel(
        id: 'M-06',
        name: 'Hope Specialty Hospital',
        distance: '6.4 km away',
        locationName: 'Industrial Area Phase 2',
        photoUrl: 'https://images.unsplash.com/photo-1581594693702-fbdc51b2763b?auto=format&fit=crop&w=600&q=80',
        emergencyBeds: 15,
        ambulanceUnits: 2,
        bloodBankAvailable: true,
        phone: '06542-230006',
        latitude: 23.8200,
        longitude: 86.4350,
      ),
      MedicalCenterModel(
        id: 'M-07',
        name: 'Rohini Sector 7 Hospital',
        distance: '6.4 km away',
        locationName: 'Sector 7, Rohini, Delhi',
        photoUrl: 'https://images.unsplash.com/photo-1502740479091-635887520276?auto=format&fit=crop&w=600&q=80',
        emergencyBeds: 30,
        ambulanceUnits: 5,
        bloodBankAvailable: true,
        phone: '011-23000007',
        latitude: 28.7200,
        longitude: 77.1100,
      ),
      MedicalCenterModel(
        id: 'M-08',
        name: 'Ayu Hospital',
        distance: '8.3 km away',
        locationName: 'Outer Ring Road',
        photoUrl: 'https://images.unsplash.com/photo-1504439468489-c8920d796a29?auto=format&fit=crop&w=600&q=80',
        emergencyBeds: 10,
        ambulanceUnits: 1,
        bloodBankAvailable: false,
        phone: '06542-230008',
        latitude: 23.8300,
        longitude: 86.4400,
      ),
      MedicalCenterModel(
        id: 'M-09',
        name: 'Lifeline Trauma Center',
        distance: '3.7 km away',
        locationName: 'South Zone Highway',
        photoUrl: 'https://images.unsplash.com/photo-1516549655169-df83a0774514?auto=format&fit=crop&w=600&q=80',
        emergencyBeds: 20,
        ambulanceUnits: 4,
        bloodBankAvailable: true,
        phone: '06542-230009',
        latitude: 23.7900,
        longitude: 86.4250,
      ),
      MedicalCenterModel(
        id: 'M-10',
        name: 'Apex Care',
        distance: '2.1 km away',
        locationName: 'Near Railway Station',
        photoUrl: 'https://images.unsplash.com/photo-1582750433449-648ed127bb54?auto=format&fit=crop&w=600&q=80',
        emergencyBeds: 14,
        ambulanceUnits: 2,
        bloodBankAvailable: true,
        phone: '06542-230010',
        latitude: 23.8000,
        longitude: 86.4300,
      ),
      MedicalCenterModel(
        id: 'M-11',
        name: 'Community Health Camp',
        distance: '1.5 km away',
        locationName: 'Gandhi Maidan',
        photoUrl: 'https://images.unsplash.com/photo-1532938911079-1b06ac7ce122?auto=format&fit=crop&w=600&q=80',
        emergencyBeds: 6,
        ambulanceUnits: 1,
        bloodBankAvailable: false,
        phone: '108',
        latitude: 23.7950,
        longitude: 86.4200,
      ),
    ]);
  }

  ShelterOccupancy? get nearestShelter {
    if (_shelters.isEmpty) return null;
    final lat = LocationService.instance.activeLat;
    final lng = LocationService.instance.activeLng;
    if (lat == null || lng == null) return _shelters.first;

    ShelterOccupancy? closest;
    double minDistance = double.infinity;

    for (var s in _shelters) {
      double dist = Geolocator.distanceBetween(lat, lng, s.latitude, s.longitude);
      if (dist < minDistance) {
        minDistance = dist;
        closest = s;
      }
    }
    if (closest != null) {
      closest.distance = '${(minDistance / 1000).toStringAsFixed(1)} km away';
      return closest;
    }
    return _shelters.first;
  }

  MedicalCenterModel? get nearestMedicalCenter {
    if (_medicalCenters.isEmpty) return null;
    final lat = LocationService.instance.activeLat;
    final lng = LocationService.instance.activeLng;
    if (lat == null || lng == null) return _medicalCenters.first;

    MedicalCenterModel? closest;
    double minDistance = double.infinity;

    for (var m in _medicalCenters) {
      double dist = Geolocator.distanceBetween(lat, lng, m.latitude, m.longitude);
      if (dist < minDistance) {
        minDistance = dist;
        closest = m;
      }
    }
    if (closest != null) {
      closest.distance = '${(minDistance / 1000).toStringAsFixed(1)} km away';
      return closest;
    }
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
