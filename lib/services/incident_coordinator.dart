import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/incident_models.dart';
import '../models/evacuation_models.dart';

/// Central Reactive Incident Coordinator
/// Connects Citizen App, Authority Command Center, and Field Responder Portal.
class IncidentCoordinator extends ChangeNotifier {
  static final IncidentCoordinator instance = IncidentCoordinator._();

  IncidentCoordinator._() {
    _initDefaultData();
  }

  final StreamController<LiveEvent> _eventController =
      StreamController<LiveEvent>.broadcast();
  Stream<LiveEvent> get eventStream => _eventController.stream;

  // ── Collections ────────────────────────────────────────────────────────────
  final List<SOSRequest> _sosRequests = [
    SOSRequest(
      id: '#284',
      callerName: 'Citizen 284',
      village: 'Mawphlang Riverfront',
      latitude: 25.4485,
      longitude: 91.7582,
      peopleCount: 6,
      elderlyCount: 1,
      childrenCount: 0,
      hasMedical: true,
      emergencyType: 'Medical Urgency',
      status: IncidentStatus.teamAssigned,
      assignedTeamId: 'SDRF-BRAVO-04',
      assignedTeamName: 'Team 02 (SDRF Bravo)',
      timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
    ),
    SOSRequest(
      id: '#281',
      callerName: 'Citizen 281',
      village: 'Nongstoin Valley Lowland',
      latitude: 25.5215,
      longitude: 91.2678,
      peopleCount: 4,
      elderlyCount: 0,
      childrenCount: 0,
      hasMedical: false,
      emergencyType: 'General SOS',
      status: IncidentStatus.teamAssigned,
      assignedTeamId: 'SDRF-BRAVO-04',
      assignedTeamName: 'Team 02 (SDRF Bravo)',
      timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
    ),
    SOSRequest(
      id: '#279',
      callerName: 'Citizen 279',
      village: 'Pynursla Riverbed Sector',
      latitude: 25.3023,
      longitude: 91.8953,
      peopleCount: 11,
      elderlyCount: 3,
      childrenCount: 0,
      hasMedical: true,
      emergencyType: 'Medical Urgency',
      status: IncidentStatus.teamAssigned,
      assignedTeamId: 'NDRF-ALPHA-07',
      assignedTeamName: 'Team 01 (NDRF Alpha)',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    SOSRequest(
      id: '#275',
      callerName: 'Citizen 275',
      village: 'Cherrapunjee Foothills',
      latitude: 25.2891,
      longitude: 91.7335,
      peopleCount: 3,
      elderlyCount: 1,
      childrenCount: 0,
      hasMedical: false,
      emergencyType: 'General SOS',
      status: IncidentStatus.teamAssigned,
      assignedTeamId: 'CIVIL-DEF-03',
      assignedTeamName: 'Team 03 (Civil Defense)',
      timestamp: DateTime.now().subtract(const Duration(minutes: 24)),
    ),
  ];
  final List<MissionAssignment> _missions = [];
  final List<ResponderTeamLocation> _responderTeams = [];
  final List<FieldHazardReport> _hazardReports = [];
  final List<AssignmentStatusHistoryItem> _statusHistory = [];
  final List<EvacuationOperation> _activeEvacuations = [];

  Timer? _movementSimulationTimer;

  // ── Getters ────────────────────────────────────────────────────────────────
  List<SOSRequest> get sosRequests => List.unmodifiable(_sosRequests);
  List<MissionAssignment> get missions => List.unmodifiable(_missions);
  List<ResponderTeamLocation> get responderTeams =>
      List.unmodifiable(_responderTeams);
  List<FieldHazardReport> get hazardReports =>
      List.unmodifiable(_hazardReports);
  List<AssignmentStatusHistoryItem> get statusHistory =>
      List.unmodifiable(_statusHistory);
  List<EvacuationOperation> get activeEvacuations => List.unmodifiable(_activeEvacuations);

  /// Mutable mission list for field responder  // ── Local Mock Assignments for Responder App ───────────
  String missionAssignmentsFilter = 'Active';

  /// Get current user's active SOS (if any)
  SOSRequest? get activeCitizenSos {
    try {
      return _sosRequests.firstWhere(
        (s) => s.status != IncidentStatus.closed,
      );
    } catch (_) {
      return null;
    }
  }

  /// Get active mission for Field Responder Team 04
  MissionAssignment? get activeTeamMission {
    try {
      return _missions.firstWhere(
        (m) =>
            m.teamId == 'SDRF-BRAVO-04' &&
            m.status != IncidentStatus.completed &&
            m.status != IncidentStatus.closed,
      );
    } catch (_) {
      return _missions.isNotEmpty ? _missions.first : null;
    }
  }
  
  EvacuationOperation? getEvacuationForArea(String areaName) {
    try {
      return _activeEvacuations.firstWhere((e) => e.areaName == areaName && e.status == 'active');
    } catch (_) {
      return null;
    }
  }

  void issueEvacuationOrder(EvacuationOperation op) {
    _activeEvacuations.add(op);
    _eventController.add(LiveEvent(
      type: LiveEventType.evacOrderIssued,
      title: 'EVAC_ORDER_ISSUED',
      message: 'Evacuation order issued for ${op.areaName}',
      payload: op,
    ));
    notifyListeners();
  }

  void updateEvacuationOperation() {
    notifyListeners();
  }

  // ── Seed Initial Data ──────────────────────────────────────────────────────
  void _initDefaultData() {
    // 1. Teams
    _responderTeams.addAll([
      ResponderTeamLocation(
        teamId: 'SDRF-BRAVO-04',
        name: 'SDRF Bravo - Team 04',
        unit: 'Water Rescue Unit',
        status: 'Available',
        latitude: 25.4490,
        longitude: 91.7580,
        batteryLevel: 88,
        membersCount: 8,
        boatCount: 2,
        ambulanceCount: 1,
        lastUpdate: DateTime.now(),
      ),
      ResponderTeamLocation(
        teamId: 'NDRF-ALPHA-07',
        name: 'NDRF Alpha - Team 07',
        unit: 'Heavy Flood Ops',
        status: 'On Mission',
        latitude: 25.4620,
        longitude: 91.7450,
        batteryLevel: 74,
        membersCount: 12,
        boatCount: 3,
        ambulanceCount: 1,
        lastUpdate: DateTime.now(),
      ),
      ResponderTeamLocation(
        teamId: 'LOCAL-RESCUE-09',
        name: 'Mawphlang Volunteer Unit 09',
        unit: 'Local Evacuation',
        status: 'Available',
        latitude: 25.4550,
        longitude: 91.7650,
        batteryLevel: 92,
        membersCount: 6,
        boatCount: 0,
        ambulanceCount: 0,
        lastUpdate: DateTime.now(),
      ),
      ResponderTeamLocation(
        teamId: 'POLICE-TAC-01',
        name: 'State Police Tac-01',
        unit: 'Perimeter & Traffic',
        status: 'Available',
        latitude: 25.4380,
        longitude: 91.7700,
        batteryLevel: 82,
        membersCount: 4,
        boatCount: 0,
        ambulanceCount: 0,
        lastUpdate: DateTime.now(),
      ),
    ]);

    // 2. Seed initial missions so FieldResponderView doesn't crash on empty list
    final now = DateTime.now();
    _missions.addAll([
      MissionAssignment(
        id: 'RS-204',
        linkedSosId: '#284',
        teamId: 'SDRF-BRAVO-04',
        teamName: 'SDRF Bravo - Team 04',
        title: 'Mawphlang Riverfront Flood Extraction',
        incidentType: 'Medical Urgency',
        location: 'Mawphlang Riverfront',
        latitude: 25.4485,
        longitude: 91.7582,
        priority: 'CRITICAL',
        initialDistance: '2.8 km',
        currentDistance: '2.8 km',
        eta: '9 min',
        assignedAuthority: 'State Emergency Ops Centre',
        safeRouteSummary: 'Safe Route via Hill Road Bypass (Sector A Open)',
        status: IncidentStatus.teamAssigned,
        stepIndex: 0,
        trapped: 6,
        medicalCount: 1,
        elderlyCount: 1,
        childrenCount: 0,
        recommendedShelter: 'Mawphlang Relief Centre',
        recommendedHospital: 'District Hospital',
        floodDepth: '1.4 m',
        waterFlow: 'Moderate',
        landslideRisk: 'Low',
        roadBridgeCondition: 'Passable via bypass',
        requiredEquipment: ['Rescue Boat', 'Life Jackets', 'First Aid Kit'],
        stepTimestamps: {0: '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}'},
      ),
      MissionAssignment(
        id: 'RS-201',
        linkedSosId: '#279',
        teamId: 'NDRF-ALPHA-07',
        teamName: 'NDRF Alpha - Team 07',
        title: 'Pynursla Riverbed Flood Rescue',
        incidentType: 'General SOS',
        location: 'Pynursla Riverbed Sector',
        latitude: 25.3023,
        longitude: 91.8953,
        priority: 'HIGH',
        initialDistance: '5.2 km',
        currentDistance: '5.2 km',
        eta: '18 min',
        assignedAuthority: 'State Emergency Ops Centre',
        safeRouteSummary: 'Safe Route via NH-6 to Pynursla Junction',
        status: IncidentStatus.responderAccepted,
        stepIndex: 1,
        trapped: 11,
        medicalCount: 0,
        elderlyCount: 3,
        childrenCount: 2,
        recommendedShelter: 'Pynursla Community Hall',
        recommendedHospital: 'Civil Hospital Shillong',
        floodDepth: '0.9 m',
        waterFlow: 'Slow',
        landslideRisk: 'Medium',
        roadBridgeCondition: 'Damaged — use alternate',
        requiredEquipment: ['Rope', 'Life Jackets', 'Stretcher'],
        stepTimestamps: {
          0: '${now.subtract(const Duration(minutes: 20)).hour.toString().padLeft(2, '0')}:${now.subtract(const Duration(minutes: 20)).minute.toString().padLeft(2, '0')}',
          1: '${now.subtract(const Duration(minutes: 15)).hour.toString().padLeft(2, '0')}:${now.subtract(const Duration(minutes: 15)).minute.toString().padLeft(2, '0')}',
        },
      ),
    ]);
  }

  // ── Workflows ──────────────────────────────────────────────────────────────

  /// Step 1: Citizen Triggers SOS
  SOSRequest createSos({
    required String callerName,
    required String village,
    required double latitude,
    required double longitude,
    required int peopleCount,
    int elderlyCount = 0,
    int childrenCount = 0,
    required bool hasMedical,
    required String emergencyType,
    String message = '',
  }) {
    final newId = '#${280 + _sosRequests.length + 4}'; // e.g. #284
    final sos = SOSRequest(
      id: newId,
      callerName: callerName,
      village: village,
      latitude: latitude,
      longitude: longitude,
      peopleCount: peopleCount,
      elderlyCount: elderlyCount,
      childrenCount: childrenCount,
      hasMedical: hasMedical,
      emergencyType: emergencyType,
      message: message,
      timestamp: DateTime.now(),
      status: IncidentStatus.newSos,
    );

    _sosRequests.insert(0, sos);

    broadcastEvent(LiveEvent(
      type: LiveEventType.newSos,
      title: '🔴 NEW CRITICAL SOS $newId',
      message:
          '$callerName at $village reports $peopleCount trapped ($elderlyCount elderly, ${hasMedical ? "Medical Emergency" : "Stable"}).',
      payload: sos,
    ));

    notifyListeners();
    return sos;
  }

  /// Step 2: Authority assigns a Rescue Team to the SOS
  MissionAssignment assignMission({
    required String sosId,
    required String teamId,
  }) {
    final sos = _sosRequests.firstWhere((s) => s.id == sosId);
    final team = _responderTeams.firstWhere((t) => t.teamId == teamId);

    final missionId = 'RS-${200 + _missions.length + 4}'; // e.g. RS-204

    sos.status = IncidentStatus.teamAssigned;
    sos.assignedTeamId = team.teamId;
    sos.assignedTeamName = team.name;
    sos.assignedMissionId = missionId;

    team.status = 'On Mission';
    team.currentMissionId = missionId;

    final mission = MissionAssignment(
      id: missionId,
      linkedSosId: sos.id,
      teamId: team.teamId,
      teamName: team.name,
      title: '${sos.village} Flood Extraction',
      incidentType: sos.emergencyType,
      location: sos.village,
      latitude: sos.latitude,
      longitude: sos.longitude,
      priority: 'CRITICAL',
      trapped: sos.peopleCount,
      medicalCount: sos.hasMedical ? 1 : 0,
      childrenCount: sos.childrenCount,
      elderlyCount: sos.elderlyCount,
      stepIndex: 0,
      status: IncidentStatus.teamAssigned,
      stepTimestamps: {0: _formatTime(DateTime.now())},
    );

    _statusHistory.insert(
      0,
      AssignmentStatusHistoryItem(
        missionId: missionId,
        status: IncidentStatus.teamAssigned,
        timestamp: DateTime.now(),
        note: 'Assigned ${team.name} to SOS ${sos.id}',
      ),
    );

    _missions.insert(0, mission);

    broadcastEvent(LiveEvent(
      type: LiveEventType.teamAssigned,
      title: '🔵 TEAM DISPATCHED: ${team.name}',
      message: 'Assigned to SOS ${sos.id} (${sos.village}) - ETA: ${team.etaEstimate}',
      payload: mission,
    ));

    notifyListeners();
    return mission;
  }

  /// Step 3: Field Responder accepts the mission
  void acceptMission(String missionId) {
    final now = DateTime.now();
    try {
      final mission = _missions.firstWhere((m) => m.id == missionId);
      mission.status = IncidentStatus.responderAccepted;
      mission.stepIndex = 1;
      mission.acceptedAt = now;
      mission.stepTimestamps[1] = _formatTime(now);

      final sos = _findSos(mission.linkedSosId);
      if (sos != null) {
        sos.status = IncidentStatus.responderAccepted;
      }

      _statusHistory.insert(
        0,
        AssignmentStatusHistoryItem(
          missionId: missionId,
          status: IncidentStatus.responderAccepted,
          timestamp: now,
          note: '${mission.teamName} accepted mission',
        ),
      );

      broadcastEvent(LiveEvent(
        type: LiveEventType.missionAccepted,
        title: '✓ MISSION ACCEPTED: $missionId',
        message: '${mission.teamName} accepted mission at ${_formatTime(now)}. ETA: ${mission.eta}',
        payload: mission,
      ));
      notifyListeners();
      return;
    } catch (_) {}

    // Check evacuation missions
    for (var op in _activeEvacuations) {
      try {
        final rMission = op.missions.firstWhere((m) => m.id == missionId);
        rMission.status = 'accepted';
        op.status = 'active'; // Ensure active
        
        broadcastEvent(LiveEvent(
          type: LiveEventType.missionAccepted,
          title: '✓ EVAC MISSION ACCEPTED: $missionId',
          message: '${rMission.assignedTeam} accepted evac mission at ${_formatTime(now)}.',
          payload: rMission,
        ));
        notifyListeners();
        return;
      } catch (_) {}
    }
  }



  void startNavigation(String missionId) {
    final now = DateTime.now();
    try {
      final mission = _missions.firstWhere((m) => m.id == missionId);
      final team = _responderTeams.firstWhere((t) => t.teamId == mission.teamId);
      
      mission.status = IncidentStatus.enRoute;
      mission.stepIndex = 3;
      mission.enRouteAt = now;
      mission.stepTimestamps[2] = _formatTime(now.subtract(const Duration(minutes: 1)));
      mission.stepTimestamps[3] = _formatTime(now);

      team.status = 'En Route';
      team.speedKmh = 24.0;

      final sos = _findSos(mission.linkedSosId);
      if (sos != null) {
        sos.status = IncidentStatus.enRoute;
      }
      
      _statusHistory.insert(0, AssignmentStatusHistoryItem(missionId: missionId, status: IncidentStatus.enRoute, timestamp: now, note: '${team.name} en route at 24 km/h. ETA 7 min.'));
      broadcastEvent(LiveEvent(type: LiveEventType.responderMoving, title: '🚒 TEAM EN ROUTE: ${team.name}', message: 'Navigation initiated toward ${mission.location}. Speed 24 km/h.', payload: mission));
      _startMovementSimulation(mission, team);
      notifyListeners();
      return;
    } catch (_) {}

    for (var op in _activeEvacuations) {
      try {
        final rMission = op.missions.firstWhere((m) => m.id == missionId);
        rMission.status = 'enRoute';
        notifyListeners();
        return;
      } catch (_) {}
    }
  }



  void _startMovementSimulation(MissionAssignment mission, ResponderTeamLocation team) {
    _movementSimulationTimer?.cancel();
    int tick = 0;
    _movementSimulationTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      tick++;
      if (mission.status != IncidentStatus.enRoute || tick > 6) {
        timer.cancel();
        return;
      }
      // Nudge coordinates closer to mission target
      team.latitude += (mission.latitude - team.latitude) * 0.15;
      team.longitude += (mission.longitude - team.longitude) * 0.15;
      team.lastUpdate = DateTime.now();
      mission.currentDistance = '${(2.8 - (tick * 0.4)).clamp(0.4, 2.8).toStringAsFixed(1)} km';
      mission.eta = '${(9 - (tick * 1.5)).clamp(1, 9).toInt()} min';

      broadcastEvent(LiveEvent(
        type: LiveEventType.responderMoving,
        title: '📍 GPS TELEMETRY UPDATE',
        message: '${team.name}: ${mission.currentDistance} away, ETA ${mission.eta}',
        payload: team,
      ));
      notifyListeners();
    });
  }

  /// Step 5: Field Responder reports Road/Bridge Hazard
  FieldHazardReport reportHazard({
    required String reportedByTeam,
    required String title, // e.g. 'Eastern Bridge Unsafe'
    required String hazardType, // e.g. 'Bridge Flooded'
    required double latitude,
    required double longitude,
    required String bypassRoute,
  }) {
    final report = FieldHazardReport(
      id: 'HAZ-${_hazardReports.length + 1}',
      reportedByTeam: reportedByTeam,
      title: title,
      hazardType: hazardType,
      isBlocked: true,
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      bypassRoute: bypassRoute,
    );

    _hazardReports.insert(0, report);

    // Update active mission safe route
    for (final m in _missions) {
      m.safeRouteSummary = 'Rerouted via Hill Road Bypass ($title avoided)';
    }

    broadcastEvent(LiveEvent(
      type: LiveEventType.hazardReported,
      title: '⚠️ FIELD UPDATE: $title',
      message:
          'Reported unsafe by $reportedByTeam. Rerouting traffic via $bypassRoute.',
      payload: report,
    ));

    notifyListeners();
    return report;
  }

  /// Step 6: Responder arrives on site
  void arriveOnSite(String missionId) {
    _movementSimulationTimer?.cancel();
    final now = DateTime.now();
    try {
      final mission = _missions.firstWhere((m) => m.id == missionId);
      final team = _responderTeams.firstWhere((t) => t.teamId == mission.teamId);

      mission.status = IncidentStatus.onSite;
      mission.stepIndex = 4;
      mission.arrivedAt = now;
      mission.stepTimestamps[4] = _formatTime(now);
      mission.currentDistance = '0.0 km';
      mission.eta = 'Arrived';

      team.status = 'On Site';
      team.speedKmh = 0.0;

      final sos = _findSos(mission.linkedSosId);
      if (sos != null) {
        sos.status = IncidentStatus.onSite;
      }

      _statusHistory.insert(
        0,
        AssignmentStatusHistoryItem(
          missionId: missionId,
          status: IncidentStatus.onSite,
          timestamp: now,
          note: '${team.name} reached incident scene at ${_formatTime(now)}',
        ),
      );

      broadcastEvent(LiveEvent(
        type: LiveEventType.onSiteArrived,
        title: '📍 TEAM ON SITE: ${team.name}',
        message: 'Rescue team has reached ${mission.location}. Extraction underway.',
        payload: mission,
      ));

      notifyListeners();
      return;
    } catch (_) {}

    for (var op in _activeEvacuations) {
      try {
        final rMission = op.missions.firstWhere((m) => m.id == missionId);
        rMission.status = 'inProgress';
        notifyListeners();
        return;
      } catch (_) {}
    }
  }

  /// Step 7: Update Rescue Progress Tally
  void updateRescueProgress(
    String missionId, {
    required int rescued,
    required int trapped,
    int? medical,
  }) {
    final mission = _missions.firstWhere((m) => m.id == missionId);

    mission.evacuated = rescued;
    mission.trapped = trapped;
    if (medical != null) mission.medicalCount = medical;
    mission.status = IncidentStatus.rescueInProgress;
    mission.stepIndex = 5;
    mission.stepTimestamps[5] = _formatTime(DateTime.now());

    final sos = _findSos(mission.linkedSosId);
    if (sos != null) {
      sos.status = IncidentStatus.rescueInProgress;
    }

    broadcastEvent(LiveEvent(
      type: LiveEventType.rescueUpdated,
      title: '👥 RESCUE PROGRESS: $missionId',
      message:
          'Rescued: $rescued / ${rescued + trapped} | Remaining Trapped: $trapped | Medical: ${mission.medicalCount}',
      payload: mission,
    ));

    notifyListeners();
  }

  /// Step 8: Report Medical Support Needed
  void reportMedicalEmergency(String missionId, int count) {
    final mission = _missions.firstWhere((m) => m.id == missionId);
    mission.medicalCount = count;

    broadcastEvent(LiveEvent(
      type: LiveEventType.medicalDispatched,
      title: '🚑 MEDICAL SUPPORT REQUIRED',
      message:
          'Mission $missionId reports $count casualties requiring ambulance dispatch to ${mission.recommendedHospital}.',
      payload: mission,
    ));

    notifyListeners();
  }

  /// Authority Dispatches Ambulance
  void dispatchAmbulance(String missionId) {
    final mission = _missions.firstWhere((m) => m.id == missionId);

    broadcastEvent(LiveEvent(
      type: LiveEventType.medicalDispatched,
      title: '🚑 AMBULANCE AMB-12 DISPATCHED',
      message:
          'Ambulance AMB-12 assigned to Mission $missionId. Destination: District Hospital (3.2 km).',
      payload: mission,
    ));

    notifyListeners();
  }

  /// Step 9: Transport Evacuees to Shelter & Update Capacity
  void transportToShelter({
    required String missionId,
    required String shelterId,
    required int evacueeCount,
  }) {
    final mission = _missions.firstWhere((m) => m.id == missionId);
    final now = DateTime.now();

    mission.status = IncidentStatus.transporting;
    mission.stepIndex = 6;
    mission.stepTimestamps[6] = _formatTime(now);

    // Note: Shelter occupancy logic is handled in ResourceApiService now.
    // We would need to call ResourceApiService to update the shelter.

    final sos = _findSos(mission.linkedSosId);
    if (sos != null) {
      sos.status = IncidentStatus.transporting;
    }

    _statusHistory.insert(
      0,
      AssignmentStatusHistoryItem(
        missionId: missionId,
        status: IncidentStatus.transporting,
        timestamp: now,
        note: 'Transporting $evacueeCount evacuees to shelter.',
      ),
    );

    broadcastEvent(LiveEvent(
      type: LiveEventType.shelterUpdated,
      title: '🏠 SHELTER OCCUPANCY UPDATED',
      message:
          'Shelter: +$evacueeCount evacuees arrived.',
      payload: mission,
    ));

    notifyListeners();
  }

  /// Step 10: Complete Mission
  void completeMission(String missionId) {
    final now = DateTime.now();
    try {
      final mission = _missions.firstWhere((m) => m.id == missionId);
      final team = _responderTeams.firstWhere((t) => t.teamId == mission.teamId);

      mission.status = IncidentStatus.completed;
      mission.stepIndex = 7;
      mission.completedAt = now;
      mission.stepTimestamps[7] = _formatTime(now);
      mission.evacuated = mission.trapped + mission.evacuated;
      mission.trapped = 0;

      team.status = 'Available';
      team.currentMissionId = null;

      final sos = _findSos(mission.linkedSosId);
      if (sos != null) {
        sos.status = IncidentStatus.completed;
      }

      _statusHistory.insert(
        0,
        AssignmentStatusHistoryItem(
          missionId: missionId,
          status: IncidentStatus.completed,
          timestamp: now,
          note: 'Mission completed by ${team.name}. All victims evacuated.',
        ),
      );

      broadcastEvent(LiveEvent(
        type: LiveEventType.missionCompleted,
        title: '✓ MISSION COMPLETED: $missionId',
        message:
            'All ${mission.evacuated} victims evacuated safely to ${mission.recommendedShelter}. Mission marked COMPLETED.',
        payload: mission,
      ));
      notifyListeners();
      return;
    } catch (_) {}

    for (var op in _activeEvacuations) {
      try {
        final rMission = op.missions.firstWhere((m) => m.id == missionId);
        rMission.status = 'completed';
        rMission.evacuated = rMission.targetPopulation; // Assume all evacuated
        notifyListeners();
        return;
      } catch (_) {}
    }
  }

  /// Step 11: Authority Closes Incident
  void closeIncident(String sosId) {
    final sos = _findSos(sosId);
    if (sos != null) {
      sos.status = IncidentStatus.closed;
    }

    broadcastEvent(LiveEvent(
      type: LiveEventType.incidentClosed,
      title: '🔒 INCIDENT CLOSED: $sosId',
      message: 'SOS $sosId has been fully resolved and archived.',
      payload: sos,
    ));

    notifyListeners();
  }



  // ── Helpers ────────────────────────────────────────────────────────────────
  SOSRequest? _findSos(String id) {
    try {
      return _sosRequests.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  void broadcastEvent(LiveEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, "0")}:${dt.minute.toString().padLeft(2, "0")}';
  }

  @override
  void dispose() {
    _movementSimulationTimer?.cancel();
    _eventController.close();
    super.dispose();
  }
}
