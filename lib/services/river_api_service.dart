import 'package:resqshield/models/incident_models.dart';

class RiverApiService {
  static List<RiverObservation> _generateObservations(List<double> levels) {
    final now = DateTime.now();
    List<RiverObservation> obs = [];
    for (int i = 0; i < levels.length; i++) {
      int hoursAgo = levels.length - 1 - i;
      obs.add(RiverObservation(
        timestamp: now.subtract(Duration(hours: hoursAgo)),
        waterLevelM: levels[i],
      ));
    }
    return obs;
  }

  static final List<RiverModel> _mockRiverData = [
    RiverModel(
      id: 'RV-01',
      name: 'Umngot River',
      stationId: 'UM-01',
      stationName: 'Station #1',
      location: 'Meghalaya',
      normalMinM: 22.0,
      normalMaxM: 30.0,
      watchLevelM: 34.0,
      warningLevelM: 39.0,
      dangerLevelM: 45.0,
      lastUpdated: DateTime.now().subtract(const Duration(minutes: 5)),
      observations: _generateObservations([
        25.8, 25.9, 26.0, 26.1, 26.3, 26.4, 26.5, 26.7, 26.9, 27.3, 27.5, 27.8, 28.4
      ]),
    ),
    RiverModel(
      id: 'RV-02',
      name: 'Damodar River',
      stationId: 'DM-02',
      stationName: 'Gauge #2',
      location: 'West Bengal',
      normalMinM: 35.0,
      normalMaxM: 42.0,
      watchLevelM: 45.0,
      warningLevelM: 48.0,
      dangerLevelM: 52.0,
      lastUpdated: DateTime.now().subtract(const Duration(minutes: 2)),
      observations: _generateObservations([
        38.5, 39.2, 39.5, 39.8, 40.2, 40.5, 41.2, 41.8, 42.5, 43.0, 44.1, 45.0, 46.1
      ]),
    ),
    RiverModel(
      id: 'RV-03',
      name: 'Umiam River',
      stationId: 'UM-04',
      stationName: 'Station #4',
      location: 'Meghalaya',
      normalMinM: 28.0,
      normalMaxM: 35.0,
      watchLevelM: 39.0,
      warningLevelM: 43.0,
      dangerLevelM: 48.0,
      lastUpdated: DateTime.now().subtract(const Duration(minutes: 1)),
      observations: _generateObservations([
        30.0, 31.0, 31.5, 32.0, 33.0, 34.0, 35.0, 36.0, 37.5, 39.0, 42.0, 46.0, 49.2
      ]),
    ),
    RiverModel(
      id: 'RV-04',
      name: 'Simsang River',
      stationId: 'SM-05',
      stationName: 'Gauge #5',
      location: 'Meghalaya',
      normalMinM: 90.0,
      normalMaxM: 105.0,
      watchLevelM: 110.0,
      warningLevelM: 116.0,
      dangerLevelM: 122.0,
      lastUpdated: DateTime.now().subtract(const Duration(minutes: 0)),
      observations: _generateObservations([
        96.5, 97.0, 97.2, 97.5, 97.8, 98.0, 98.4, 98.8, 99.1, 99.4, 100.0, 100.6, 101.4
      ]),
    ),
    RiverModel(
      id: 'RV-05',
      name: 'Myntdu River',
      stationId: 'MY-03',
      stationName: 'Station #3',
      location: 'Meghalaya',
      normalMinM: 15.0,
      normalMaxM: 20.0,
      watchLevelM: 22.0,
      warningLevelM: 24.0,
      dangerLevelM: 26.0,
      lastUpdated: DateTime.now().subtract(const Duration(minutes: 10)),
      observations: _generateObservations([
        16.0, 16.2, 16.4, 16.5, 16.6, 16.7, 16.9, 17.0, 17.2, 17.5, 17.8, 18.2, 18.8
      ]),
    ),
  ];

  static Future<List<RiverModel>> fetchRivers() async {
    await Future.delayed(const Duration(milliseconds: 900));
    return _mockRiverData;
  }
}
