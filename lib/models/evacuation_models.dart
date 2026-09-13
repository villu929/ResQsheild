class ResponderMission {
  final String id;
  final String clusterName;
  final int targetPopulation;
  int located;
  int evacuated;
  int medical;
  int missing;
  String assignedTeam;
  String status; // 'assigned', 'accepted', 'ready', 'enRoute', 'onSite', 'evacuating', 'transporting', 'completed'

  ResponderMission({
    required this.id,
    required this.clusterName,
    required this.targetPopulation,
    required this.assignedTeam,
    this.located = 0,
    this.evacuated = 0,
    this.medical = 0,
    this.missing = 0,
    this.status = 'assigned',
  });
}

class EvacuationOperation {
  final String id;
  final String areaName;
  String status; // 'planning', 'active', 'completed'
  final int targetPopulation;
  final String primaryShelter;
  final String safeRoute;
  final List<ResponderMission> missions;

  EvacuationOperation({
    required this.id,
    required this.areaName,
    required this.targetPopulation,
    required this.primaryShelter,
    required this.safeRoute,
    this.status = 'active',
    this.missions = const [],
  });

  int get totalEvacuated => missions.fold(0, (sum, m) => sum + m.evacuated);
  int get totalLocated => missions.fold(0, (sum, m) => sum + m.located);
  int get activeTeamsCount => missions.where((m) => m.status != 'completed' && m.status != 'assigned').length;
  int get completedTeamsCount => missions.where((m) => m.status == 'completed').length;
}
