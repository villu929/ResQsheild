import 'package:resqshield/models/incident_models.dart';
import 'package:resqshield/services/incident_coordinator.dart';

/// A mock API service for Shelter Camps data.
/// This allows the UI to consume data as if it were coming from a backend.
/// Later, when the real API is available, you can easily replace the implementation
/// inside this class without affecting the UI components.
class ShelterApiService {
  /// Fetches a list of all available shelters.
  /// Currently mocks a network delay and returns data from the local IncidentCoordinator.
  static Future<List<ShelterOccupancy>> getShelters() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Return the fake data from the incident coordinator
    return IncidentCoordinator.instance.shelters;
  }

  /// Fetches the nearest or recommended shelter for a user.
  static Future<ShelterOccupancy?> getNearestShelter() async {
    final shelters = await getShelters();
    if (shelters.isEmpty) return null;
    
    // For now, just return the first shelter as the 'nearest' one.
    // In a real API, this would take user coordinates and query the backend.
    return shelters.first;
  }
}
