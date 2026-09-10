import 'package:latlong2/latlong.dart';

enum FloodDataStatus {
  loading,
  live,
  stale,
  empty,
  error,
}

class FloodLiveMeta {
  final String source;
  final String dataType;
  final String status;
  final bool rasterLayer;
  final String note;
  final DateTime? updatedAt;

  FloodLiveMeta({
    required this.source,
    required this.dataType,
    required this.status,
    required this.rasterLayer,
    required this.note,
    this.updatedAt,
  });

  factory FloodLiveMeta.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return FloodLiveMeta(
        source: 'Official Flood Network',
        dataType: 'inundation',
        status: 'unknown',
        rasterLayer: true,
        note: '',
      );
    }
    return FloodLiveMeta(
      source: json['source'] as String? ?? 'CEMS Global Flood Monitoring',
      dataType: json['data_type'] as String? ?? 'observed flood extent',
      status: json['status'] as String? ?? 'near_real_time',
      rasterLayer: json['raster_layer'] as bool? ?? true,
      note: json['note'] as String? ?? '',
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }
}

class FloodFeatureItem {
  final String id;
  final LatLng point;
  final String title;
  final String description;
  final String severity;
  final Map<String, dynamic> properties;

  FloodFeatureItem({
    required this.id,
    required this.point,
    required this.title,
    required this.description,
    required this.severity,
    required this.properties,
  });

  factory FloodFeatureItem.fromJson(Map<String, dynamic> json) {
    final props = (json['properties'] as Map<String, dynamic>?) ?? {};
    final geom = (json['geometry'] as Map<String, dynamic>?) ?? {};
    final coords = geom['coordinates'];

    double lat = 0.0;
    double lng = 0.0;

    if (coords is List && coords.length >= 2) {
      // GeoJSON standard is [longitude, latitude]
      lng = (coords[0] as num).toDouble();
      lat = (coords[1] as num).toDouble();
    }

    return FloodFeatureItem(
      id: json['id']?.toString() ?? props['id']?.toString() ?? '',
      point: LatLng(lat, lng),
      title: props['title'] as String? ??
          props['station_name'] as String? ??
          props['event'] as String? ??
          'Flood Alert',
      description: props['description'] as String? ??
          props['details'] as String? ??
          props['instruction'] as String? ??
          '',
      severity: props['severity'] as String? ??
          props['level'] as String? ??
          'warning',
      properties: props,
    );
  }
}

class FloodLiveResponse {
  final List<FloodFeatureItem> features;
  final FloodLiveMeta meta;
  final DateTime receivedAt;

  FloodLiveResponse({
    required this.features,
    required this.meta,
    required this.receivedAt,
  });

  factory FloodLiveResponse.fromJson(Map<String, dynamic> json) {
    final featureList = <FloodFeatureItem>[];
    if (json['features'] is List) {
      for (final item in json['features'] as List) {
        if (item is Map<String, dynamic>) {
          try {
            featureList.add(FloodFeatureItem.fromJson(item));
          } catch (_) {}
        }
      }
    }

    return FloodLiveResponse(
      features: featureList,
      meta: FloodLiveMeta.fromJson(json['meta'] as Map<String, dynamic>?),
      receivedAt: DateTime.now(),
    );
  }
}

class LayersInfo {
  final bool floodInundationEnabled;
  final String floodInundationSource;
  final String floodInundationUrl;
  final bool governmentAlertsEnabled;
  final String governmentAlertsSource;
  final bool waterLevelsEnabled;
  final bool rainfallEnabled;

  LayersInfo({
    required this.floodInundationEnabled,
    required this.floodInundationSource,
    required this.floodInundationUrl,
    required this.governmentAlertsEnabled,
    required this.governmentAlertsSource,
    required this.waterLevelsEnabled,
    required this.rainfallEnabled,
  });

  factory LayersInfo.fromJson(Map<String, dynamic> json) {
    final flood = json['flood_inundation'] as Map<String, dynamic>?;
    final gov = json['government_alerts'] as Map<String, dynamic>?;
    final water = json['water_levels'] as Map<String, dynamic>?;
    final rain = json['rainfall'] as Map<String, dynamic>?;

    return LayersInfo(
      floodInundationEnabled: flood?['enabled'] == true,
      floodInundationSource: flood?['source'] as String? ?? 'CEMS GFM',
      floodInundationUrl: flood?['url'] as String? ?? '/api/tiles/gfm/{z}/{x}/{y}.png',
      governmentAlertsEnabled: gov?['enabled'] == true,
      governmentAlertsSource: gov?['source'] as String? ?? 'SACHET / NDMA',
      waterLevelsEnabled: water?['enabled'] == true,
      rainfallEnabled: rain?['enabled'] == true,
    );
  }
}
