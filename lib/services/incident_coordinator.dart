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
  final List<SOSRequest> _sosRequests = [];
  final List<MissionAssignment> _missions = [];
  final List<ResponderTeamLocation> _responderTeams = [];
  final List<FieldHazardReport> _hazardReports = [];
  final List<ShelterOccupancy> _shelters = [];
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
  List<ShelterOccupancy> get shelters => List.unmodifiable(_shelters);
  List<AssignmentStatusHistoryItem> get statusHistory =>
      List.unmodifiable(_statusHistory);
  List<EvacuationOperation> get activeEvacuations => List.unmodifiable(_activeEvacuations);

  /// Mutable mission list for field responder view (local _Mission wrappers are inserted here)
  final List<dynamic> _missionAssignments = [];
  List<dynamic> get missionAssignments => _missionAssignments;

  /// Current filter used by field responder's mission tab ('Active', 'Pending', 'Completed')
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

    // 2. Shelters
    _shelters.addAll([
      ShelterOccupancy(
        id: 'SH-01',
        name: 'Govt. Higher Secondary School',
        locationName: 'Bokaro, Jharkhand',
        capacity: 500,
        occupied: 180,
        latitude: 23.6693,
        longitude: 86.1511,
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
        name: 'Community Hall, Kurma',
        locationName: 'Giridih, Jharkhand',
        capacity: 300,
        occupied: 180,
        latitude: 24.1860,
        longitude: 86.3090,
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
        name: 'Ranchi Sadar Hospital',
        locationName: 'Ranchi, Jharkhand',
        capacity: 450,
        occupied: 240,
        latitude: 23.3441,
        longitude: 85.3096,
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
        name: 'Bokaro Relief Camp',
        locationName: 'Bokaro, Jharkhand',
        capacity: 500,
        occupied: 180,
        latitude: 23.6650,
        longitude: 86.1550,
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
        name: 'St. Anthony Relief Hall',
        locationName: 'Sector B • 4.1 km',
        capacity: 200,
        occupied: 184,
        latitude: 25.5650,
        longitude: 91.8820,
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
        name: 'Valley Convent High School',
        locationName: 'Sector C • 6.8 km',
        capacity: 200,
        occupied: 200,
        latitude: 25.5180,
        longitude: 91.2750,
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
        name: 'Mawphlang Relief Centre',
        locationName: 'Sector 4 High Ground, Mawphlang',
        capacity: 200,
        occupied: 150,
        latitude: 25.4520,
        longitude: 91.7610,
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

    _broadcastEvent(LiveEvent(
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

    _missions.insert(0, mission);

    _statusHistory.insert(
      0,
      AssignmentStatusHistoryItem(
        missionId: missionId,
        status: IncidentStatus.teamAssigned,
        timestamp: DateTime.now(),
        note: 'Assigned ${team.name} to SOS ${sos.id}',
      ),
    );

    _broadcastEvent(LiveEvent(
      type: LiveEventType.teamAssigned,
      title: '🚨 MISSION ASSIGNED: $missionId',
      message: '${team.name} assigned to SOS ${sos.id} (${sos.village})',
      payload: mission,
    ));

    notifyListeners();
    return mission;
  }

  void acceptMission(String missionId) {
    final now = DateTime.now();

    // Check standalone missions first
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

      _broadcastEvent(LiveEvent(
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
        
        _broadcastEvent(LiveEvent(
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
      _broadcastEvent(LiveEvent(type: LiveEventType.responderMoving, title: '🚒 TEAM EN ROUTE: ${team.name}', message: 'Navigation initiated toward ${mission.location}. Speed 24 km/h.', payload: mission));
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

      _broadcastEvent(LiveEvent(
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

    _broadcastEvent(LiveEvent(
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

      _broadcastEvent(LiveEvent(
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

    _broadcastEvent(LiveEvent(
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

    _broadcastEvent(LiveEvent(
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

    _broadcastEvent(LiveEvent(
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
    final shelter = _shelters.firstWhere((s) => s.id == shelterId);
    final now = DateTime.now();

    mission.status = IncidentStatus.transporting;
    mission.stepIndex = 6;
    mission.stepTimestamps[6] = _formatTime(now);

    // Update Shelter Capacity (e.g. 150/200 + 8 = 158/200)
    shelter.occupied = (shelter.occupied + evacueeCount).clamp(0, shelter.capacity);

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
        note: 'Transporting $evacueeCount evacuees to ${shelter.name}. Capacity: ${shelter.occupied}/${shelter.capacity}',
      ),
    );

    _broadcastEvent(LiveEvent(
      type: LiveEventType.shelterUpdated,
      title: '🏠 SHELTER OCCUPANCY UPDATED',
      message:
          '${shelter.name}: +$evacueeCount evacuees arrived. Occupancy: ${shelter.occupied}/${shelter.capacity} (${shelter.available} available).',
      payload: shelter,
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

      _broadcastEvent(LiveEvent(
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

    _broadcastEvent(LiveEvent(
      type: LiveEventType.incidentClosed,
      title: '🔒 INCIDENT CLOSED: $sosId',
      message: 'SOS $sosId has been fully resolved and archived.',
      payload: sos,
    ));

    notifyListeners();
  }

  // ── Shelter Management Workflows (Authority Add & Update) ──────────────────

  /// Authority Adds a New Relief Shelter Camp
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

    _broadcastEvent(LiveEvent(
      type: LiveEventType.shelterUpdated,
      title: '🏠 NEW RELIEF SHELTER OPENED',
      message: '$name opened at $locationName with $capacity bed capacity. Food, water, and medical provisions active.',
      payload: shelter,
    ));

    notifyListeners();
    return shelter;
  }

  /// Authority Updates Existing Relief Shelter
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

    _broadcastEvent(LiveEvent(
      type: LiveEventType.shelterUpdated,
      title: '🏠 SHELTER DETAILS UPDATED',
      message: '${updated.name}: Capacity ${updated.occupied}/${updated.capacity} (${updated.available} available). Provisions & Medical facilities updated.',
      payload: updated,
    ));

    notifyListeners();
  }

  /// Toggle Favorite Bookmark
  void toggleFavoriteShelter(String id) {
    final index = _shelters.indexWhere((s) => s.id == id);
    if (index == -1) return;
    _shelters[index].isFavorite = !_shelters[index].isFavorite;
    notifyListeners();
  }

  /// Authority Removes or Decommissions a Shelter
  void deleteShelter(String id) {
    final index = _shelters.indexWhere((s) => s.id == id);
    if (index == -1) return;
    final removed = _shelters.removeAt(index);

    _broadcastEvent(LiveEvent(
      type: LiveEventType.shelterUpdated,
      title: '🏠 SHELTER DECOMMISSIONED',
      message: '${removed.name} has been archived/decommissioned.',
      payload: removed,
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

  void _broadcastEvent(LiveEvent event) {
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
