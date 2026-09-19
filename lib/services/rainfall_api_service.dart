import 'package:resqshield/models/incident_models.dart';
import 'package:resqshield/services/resqshield_backend_service.dart';
class RainfallApiService {
  static List<RainfallObservation> _generateObservations(List<double> cumulativeData) {
    final now = DateTime.now();
    List<RainfallObservation> obs = [];
    for (int i = 0; i < cumulativeData.length; i++) {
      int hoursAgo = cumulativeData.length - 1 - i;
      double interval = i == 0 ? cumulativeData[i] : cumulativeData[i] - cumulativeData[i - 1];
      obs.add(RainfallObservation(
        timestamp: now.subtract(Duration(hours: hoursAgo)),
        cumulativeMm: cumulativeData[i],
        intervalMm: interval,
      ));
    }
    return obs;
  }

  static final List<RainfallModel> _mockRainfallData = [
    RainfallModel(
      id: 'RF-01',
      areaName: 'Pynursla',
      state: 'Meghalaya',
      forecastMm: 5.0,
      status: 'LOW',
      alertLevel: 'Green',
      lastUpdated: DateTime.now().subtract(const Duration(minutes: 2)),
      observations: _generateObservations([0, 2, 4, 6, 9, 11, 12, 13, 15, 16, 17, 18, 18]), // 12 hours (13 points)
    ),
    RainfallModel(
      id: 'RF-02',
      areaName: 'Nongstoin',
      state: 'Meghalaya',
      forecastMm: 12.0,
      status: 'MODERATE',
      alertLevel: 'Yellow',
      lastUpdated: DateTime.now().subtract(const Duration(minutes: 5)),
      observations: _generateObservations([0, 3, 6, 9, 11, 13, 15, 18, 20, 22, 25, 26, 27]), 
    ),
    RainfallModel(
      id: 'RF-03',
      areaName: 'Mawphlang',
      state: 'Meghalaya',
      forecastMm: 25.0,
      status: 'HEAVY',
      alertLevel: 'Orange',
      lastUpdated: DateTime.now().subtract(const Duration(minutes: 1)),
      observations: _generateObservations([0, 3, 7, 11, 14, 16, 19, 22, 26, 29, 32, 34, 36]),
    ),
    RainfallModel(
      id: 'RF-04',
      areaName: 'Sohra',
      state: 'Meghalaya',
      forecastMm: 60.0,
      status: 'DANGER',
      alertLevel: 'Red',
      lastUpdated: DateTime.now().subtract(const Duration(minutes: 0)),
      observations: _generateObservations([0, 3, 7, 12, 15, 19, 24, 28, 33, 38, 43, 46, 48]),
    ),
    RainfallModel(
      id: 'RF-05',
      areaName: 'Shillong East',
      state: 'Meghalaya',
      forecastMm: 20.0,
      status: 'MODERATE',
      alertLevel: 'Yellow',
      lastUpdated: DateTime.now().subtract(const Duration(minutes: 12)),
      observations: _generateObservations([0, 2, 5, 8, 10, 13, 16, 19, 21, 23, 24, 24, 25]),
    ),
  ];

  static Future<List<RainfallModel>> fetchRainfallData() async {
    try {
      final data = await ResqshieldBackendService.instance.fetchFloodRiskDistricts(limit: 5);
      if (data.isNotEmpty) {
        List<RainfallModel> models = [];
        for (int i = 0; i < data.length; i++) {
          final d = data[i];
          final mmPerHour = (d['gpm']?['rainfall_mm_per_hour'] as num?)?.toDouble() ?? 0.0;
          String alert = 'Green';
          String status = 'LOW';
          if (mmPerHour > 15) { alert = 'Red'; status = 'DANGER'; }
          else if (mmPerHour > 8) { alert = 'Orange'; status = 'HEAVY'; }
          else if (mmPerHour > 3) { alert = 'Yellow'; status = 'MODERATE'; }
          
          models.add(RainfallModel(
            id: 'RF-API-$i',
            areaName: d['district'] ?? 'Unknown',
            state: d['state'] ?? 'Unknown',
            forecastMm: mmPerHour * 3,
            status: status,
            alertLevel: alert,
            lastUpdated: DateTime.now(),
            observations: _generateObservations([0, mmPerHour * 0.2, mmPerHour * 0.5, mmPerHour * 0.8, mmPerHour]),
          ));
        }
        if (models.isNotEmpty) return models;
      }
    } catch (_) {}
    return _mockRainfallData;
  }

  static Future<RainfallModel?> getRainfallByArea(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      return _mockRainfallData.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }
}
