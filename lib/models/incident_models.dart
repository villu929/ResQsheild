import 'package:flutter/material.dart';

/// Operational lifecycle state machine for incidents
enum IncidentStatus {
  newSos,
  authorityAcknowledged,
  teamAssigned,
  responderAccepted,
  teamReady,
  enRoute,
  onSite,
  rescueInProgress,
  transporting,
  completed,
  closed,
}

extension IncidentStatusExtension on IncidentStatus {
  String get displayName {
    switch (this) {
      case IncidentStatus.newSos:
        return 'NEW SOS';
      case IncidentStatus.authorityAcknowledged:
        return 'ACKNOWLEDGED';
      case IncidentStatus.teamAssigned:
        return 'TEAM ASSIGNED';
      case IncidentStatus.responderAccepted:
        return 'ACCEPTED';
      case IncidentStatus.teamReady:
        return 'TEAM READY';
      case IncidentStatus.enRoute:
        return 'EN ROUTE';
      case IncidentStatus.onSite:
        return 'ON SITE';
      case IncidentStatus.rescueInProgress:
        return 'RESCUE IN PROGRESS';
      case IncidentStatus.transporting:
        return 'TRANSPORTING';
      case IncidentStatus.completed:
        return 'COMPLETED';
      case IncidentStatus.closed:
        return 'CLOSED';
    }
  }

  Color get color {
    switch (this) {
      case IncidentStatus.newSos:
        return const Color(0xFFE92828);
      case IncidentStatus.authorityAcknowledged:
        return const Color(0xFFF59E0B);
      case IncidentStatus.teamAssigned:
        return const Color(0xFF3B82F6);
      case IncidentStatus.responderAccepted:
        return const Color(0xFF2563EB);
      case IncidentStatus.teamReady:
        return const Color(0xFF0284C7);
      case IncidentStatus.enRoute:
        return const Color(0xFF0D9488);
      case IncidentStatus.onSite:
        return const Color(0xFF16A34A);
      case IncidentStatus.rescueInProgress:
        return const Color(0xFF15803D);
      case IncidentStatus.transporting:
        return const Color(0xFF6366F1);
      case IncidentStatus.completed:
        return const Color(0xFF10B981);
      case IncidentStatus.closed:
        return const Color(0xFF64748B);
    }
  }
}

/// Citizen SOS Request model
class SOSRequest {
  final String id; // e.g. '#284'
  final String userId;
  final String callerName;
  final String phone;
  final String village;
  final double latitude;
  final double longitude;
  final int peopleCount;
  final int elderlyCount;
  final int childrenCount;
  final bool hasMedical;
  final String emergencyType;
  final String message;
  final DateTime timestamp;
  IncidentStatus status;
  String? assignedTeamId;
  String? assignedTeamName;
  String? assignedMissionId;

  SOSRequest({
    required this.id,
    this.userId = 'citizen_rohit',
    required this.callerName,
    this.phone = '+91 98765 43210',
    required this.village,
    required this.latitude,
    required this.longitude,
    required this.peopleCount,
    this.elderlyCount = 0,
    this.childrenCount = 0,
    required this.hasMedical,
    required this.emergencyType,
    this.message = '',
    required this.timestamp,
    this.status = IncidentStatus.newSos,
    this.assignedTeamId,
    this.assignedTeamName,
    this.assignedMissionId,
  });

  String get coordinatesFormatted =>
      '${latitude.toStringAsFixed(4)}° N, ${longitude.toStringAsFixed(4)}° E';

  String get timeAgoFormatted {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 60) return '${diff.inSeconds} sec ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    return '${diff.inHours} hr ago';
  }
}

/// Mission Assignment model linking SOS to Responder Team
class MissionAssignment {
  final String id; // e.g. 'RS-204'
  final String linkedSosId; // e.g. '#284'
  final String teamId; // e.g. 'SDRF-BRAVO-04'
  final String teamName; // e.g. 'SDRF Bravo - Team 04'
  final String title;
  final String incidentType;
  final String location;
  final double latitude;
  final double longitude;
  final String priority;
  final String initialDistance;
  String currentDistance;
  String eta;
  final String assignedAuthority;
  String safeRouteSummary;
  IncidentStatus status;
  int stepIndex; // 0..7 matching field responder lifecycle
  int trapped;
  int evacuated;
  int medicalCount;
  int missingCount;
  final int childrenCount;
  final int elderlyCount;
  String recommendedShelter;
  String recommendedHospital;
  final Map<int, String> stepTimestamps;
  DateTime? acceptedAt;
  DateTime? enRouteAt;
  DateTime? arrivedAt;
  DateTime? completedAt;

  // Computed helpers matching _Mission API for consistent usage
  String get missionTitle => title;
  String get village => location;
  int get trappedCount => trapped;
  int get etaMins => int.tryParse(eta.replaceAll(' min', '')) ?? 0;

  MissionAssignment({
    required this.id,
    required this.linkedSosId,
    required this.teamId,
    required this.teamName,
    required this.title,
    required this.incidentType,
    required this.location,
    required this.latitude,
    required this.longitude,
    this.priority = 'CRITICAL',
    this.initialDistance = '2.8 km',
    this.currentDistance = '2.8 km',
    this.eta = '9 min',
    this.assignedAuthority = 'State Emergency Ops Centre',
    this.safeRouteSummary = 'Safe Route via Hill Road Bypass (Sector A Open)',
    this.status = IncidentStatus.teamAssigned,
    this.stepIndex = 0,
    required this.trapped,
    this.evacuated = 0,
    required this.medicalCount,
    this.missingCount = 0,
    this.childrenCount = 0,
    this.elderlyCount = 0,
    this.recommendedShelter = 'Mawphlang Relief Centre',
    this.recommendedHospital = 'District Hospital',
    Map<int, String>? stepTimestamps,
    this.acceptedAt,
    this.enRouteAt,
    this.arrivedAt,
    this.completedAt,
  }) : stepTimestamps = stepTimestamps ?? {};
}

/// Audit trail for incident reconstruction
class AssignmentStatusHistoryItem {
  final String missionId;
  final IncidentStatus status;
  final DateTime timestamp;
  final String note;

  AssignmentStatusHistoryItem({
    required this.missionId,
    required this.status,
    required this.timestamp,
    required this.note,
  });

  String get timeFormatted =>
      '${timestamp.hour.toString().padLeft(2, "0")}:${timestamp.minute.toString().padLeft(2, "0")}';
}

/// Responder GPS and Telemetry model
class ResponderTeamLocation {
  final String teamId;
  final String name;
  final String unit;
  String status; // 'Available', 'On Mission', 'En Route', 'On Site', 'Offline'
  double latitude;
  double longitude;
  double speedKmh;
  int batteryLevel;
  int membersCount;
  int boatCount;
  int ambulanceCount;
  DateTime lastUpdate;
  String? currentMissionId;

  ResponderTeamLocation({
    required this.teamId,
    required this.name,
    required this.unit,
    this.status = 'Available',
    required this.latitude,
    required this.longitude,
    this.speedKmh = 0.0,
    this.batteryLevel = 88,
    this.membersCount = 8,
    this.boatCount = 2,
    this.ambulanceCount = 1,
    required this.lastUpdate,
    this.currentMissionId,
  });

  String get distanceToSosEstimate => '2.8 km';
  String get etaEstimate => '9 min';
}

/// Field Hazard and Road/Bridge condition report
class FieldHazardReport {
  final String id;
  final String reportedByTeam;
  final String title; // e.g. 'Eastern Bridge Unsafe'
  final String hazardType; // 'Bridge Flooded', 'Road Blocked', 'Landslide'
  final bool isBlocked;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String bypassRoute;
  final String photoUrl;

  FieldHazardReport({
    required this.id,
    required this.reportedByTeam,
    required this.title,
    required this.hazardType,
    this.isBlocked = true,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.bypassRoute,
    this.photoUrl = '',
  });

  String get timeAgoFormatted {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}

/// Shelter Capacity & Occupancy model
class ShelterOccupancy {
  final String id;
  String name;
  String locationName;
  int capacity;
  int occupied;
  double latitude;
  double longitude;
  String distance;
  bool foodAvailable;
  String foodDetails;
  bool waterAvailable;
  String waterDetails;
  bool medicalAvailable;
  String medicalDetails;
  String photoUrl;
  List<String> services; // ['Water', 'Food', 'Medical', 'Power', 'Sanitation', 'Bedding']
  String contact;
  String inchargeName;
  String status; // 'OPEN', 'NEAR FULL', 'FULL', 'STANDBY'
  int foodPacks;
  int waterBottles;
  int medicalTeams;
  bool isFavorite;
  DateTime lastUpdated;

  ShelterOccupancy({
    required this.id,
    required this.name,
    this.locationName = 'District Emergency Sector',
    required this.capacity,
    required this.occupied,
    required this.latitude,
    required this.longitude,
    this.distance = '1.5 km',
    this.foodAvailable = true,
    this.foodDetails = '3 Hot Meals Daily & Dry Rations',
    this.waterAvailable = true,
    this.waterDetails = '24/7 RO Potable Drinking Water',
    this.medicalAvailable = true,
    this.medicalDetails = 'Doctor & Paramedic Triage On-Site',
    this.photoUrl = 'assets/images/shelter_school.png',
    required this.services,
    this.contact = '+91 364 250 1111',
    this.inchargeName = 'Officer In-Charge',
    this.status = 'OPEN',
    this.foodPacks = 1200,
    this.waterBottles = 1800,
    this.medicalTeams = 2,
    this.isFavorite = false,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  int get available => (capacity - occupied).clamp(0, capacity);
  double get occupancyPercent =>
      capacity > 0 ? (occupied / capacity).clamp(0.0, 1.0) : 0.0;

  Color get statusColor {
    final pct = occupancyPercent;
    if (status == 'FULL' || pct >= 1.0) return const Color(0xFFDC2626);
    if (status == 'NEAR FULL' || pct >= 0.85) return const Color(0xFFEA580C);
    if (status == 'STANDBY') return const Color(0xFF64748B);
    return const Color(0xFF16A34A);
  }

  ShelterOccupancy copyWith({
    String? id,
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
    bool? isFavorite,
    DateTime? lastUpdated,
  }) {
    return ShelterOccupancy(
      id: id ?? this.id,
      name: name ?? this.name,
      locationName: locationName ?? this.locationName,
      capacity: capacity ?? this.capacity,
      occupied: occupied ?? this.occupied,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distance: distance ?? this.distance,
      foodAvailable: foodAvailable ?? this.foodAvailable,
      foodDetails: foodDetails ?? this.foodDetails,
      waterAvailable: waterAvailable ?? this.waterAvailable,
      waterDetails: waterDetails ?? this.waterDetails,
      medicalAvailable: medicalAvailable ?? this.medicalAvailable,
      medicalDetails: medicalDetails ?? this.medicalDetails,
      photoUrl: photoUrl ?? this.photoUrl,
      services: services ?? List.from(this.services),
      contact: contact ?? this.contact,
      inchargeName: inchargeName ?? this.inchargeName,
      status: status ?? this.status,
      foodPacks: foodPacks ?? this.foodPacks,
      waterBottles: waterBottles ?? this.waterBottles,
      medicalTeams: medicalTeams ?? this.medicalTeams,
      isFavorite: isFavorite ?? this.isFavorite,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }
}

/// Live Event types for cross-screen event broadcasting
enum LiveEventType {
  newSos,
  teamAssigned,
  missionAccepted,
  responderMoving,
  hazardReported,
  onSiteArrived,
  rescueUpdated,
  medicalDispatched,
  shelterUpdated,
  missionCompleted,
  incidentClosed,
  evacOrderIssued,
}

class LiveEvent {
  final LiveEventType type;
  final String title;
  final String message;
  final dynamic payload;
  final DateTime timestamp;

  LiveEvent({
    required this.type,
    required this.title,
    required this.message,
    this.payload,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Mock Model for Medical Centers / Hospitals
class MedicalCenterModel {
  final String id;
  final String name;
  final String distance;
  final String locationName;
  final String photoUrl;
  final int emergencyBeds;
  final int ambulanceUnits;
  final bool bloodBankAvailable;
  final String phone;
  final double latitude;
  final double longitude;
  final bool isOpen;

  MedicalCenterModel({
    required this.id,
    required this.name,
    required this.distance,
    required this.locationName,
    required this.photoUrl,
    required this.emergencyBeds,
    required this.ambulanceUnits,
    required this.bloodBankAvailable,
    required this.phone,
    required this.latitude,
    required this.longitude,
    this.isOpen = true,
  });
}

class RiverObservation {
  final DateTime timestamp;
  final double waterLevelM;

  RiverObservation({
    required this.timestamp,
    required this.waterLevelM,
  });
}

class RiverModel {
  final String id;
  final String name;
  final String stationId;
  final String stationName;
  final String location;
  
  // Gauge Thresholds
  final double normalMinM;
  final double normalMaxM;
  final double watchLevelM;
  final double warningLevelM;
  final double dangerLevelM;

  // Time-series data
  final List<RiverObservation> observations;
  final DateTime lastUpdated;
  final bool isOffline;

  // Calculated fields
  double get currentLevel => observations.isNotEmpty ? observations.last.waterLevelM : 0.0;

  double get rateOfRise {
    if (observations.length < 2) return 0.0;
    // Calculate rate over the last hour (assuming 1 hour intervals)
    return observations.last.waterLevelM - observations[observations.length - 2].waterLevelM;
  }

  String get trend {
    double rate = rateOfRise;
    if (rate > 0.02) return 'Rising';
    if (rate < -0.02) return 'Falling';
    return 'Stable';
  }

  String get status {
    double lvl = currentLevel;
    if (lvl >= dangerLevelM) return 'DANGER';
    if (lvl >= warningLevelM) return 'WARNING';
    if (lvl >= watchLevelM) return 'WATCH';
    return 'NORMAL';
  }

  RiverModel({
    required this.id,
    required this.name,
    required this.stationId,
    required this.stationName,
    required this.location,
    required this.normalMinM,
    required this.normalMaxM,
    required this.watchLevelM,
    required this.warningLevelM,
    required this.dangerLevelM,
    required this.observations,
    required this.lastUpdated,
    this.isOffline = false,
  });
}

class RainfallObservation {
  final DateTime timestamp;
  final double cumulativeMm;
  final double intervalMm;

  RainfallObservation({
    required this.timestamp,
    required this.cumulativeMm,
    required this.intervalMm,
  });
}

class RainfallModel {
  final String id;
  final String areaName;
  final String state;
  final double forecastMm; // Next 24 hours
  final String status; // 'LOW', 'MODERATE', 'HEAVY', 'DANGER'
  final String alertLevel; // 'Green', 'Yellow', 'Orange', 'Red'
  
  // Time-series data (12 hours)
  final List<RainfallObservation> observations;
  final DateTime lastUpdated;
  final bool isOffline;

  // Helper getters
  double get total12H => observations.isNotEmpty ? observations.last.cumulativeMm : 0;
  
  double get total6H {
    if (observations.isEmpty) return 0;
    if (observations.length <= 6) return total12H;
    double mm6hAgo = observations[observations.length - 7].cumulativeMm;
    return observations.last.cumulativeMm - mm6hAgo;
  }

  double get total1H {
    if (observations.isEmpty) return 0;
    return observations.last.intervalMm;
  }

  RainfallModel({
    required this.id,
    required this.areaName,
    required this.state,
    required this.forecastMm,
    required this.status,
    required this.alertLevel,
    required this.observations,
    required this.lastUpdated,
    this.isOffline = false,
  });
}

