import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../services/api_constants.dart';
import 'role_selection_screen.dart';
import '../models/incident_models.dart';
import '../services/incident_coordinator.dart';
import '../widgets/role_quick_switcher.dart';
import 'citizen/citizen_shelters_view.dart';
import 'relief_camp_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN SYSTEM & THEME CONSTANTS (JalGuard Official Palette)
// ─────────────────────────────────────────────────────────────────────────────
class _C {
  static const navy = Color(0xFF0B2341);
  static const govBlue = Color(0xFF005EA8);
  static const actionBlue = Color(0xFF087BE7);
  static const pageBg = Color(0xFFF4F7FA);
  static const cardLight = Colors.white;
  static const textPrimary = Color(0xFF172033);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFF94A3B8);
  static const safe = Color(0xFF16A34A);
  static const warning = Color(0xFFD97706);
  static const critical = Color(0xFFDC2626);

  // Tactical dark map surfaces
  static const mapCard = Color(0xFF163352);
  static const mapDivider = Color(0xFF1E4976);
}

// ─────────────────────────────────────────────────────────────────────────────
// 8-STAGE SEQUENTIAL MISSION LIFECYCLE
// ─────────────────────────────────────────────────────────────────────────────
const List<String> _kMissionLifecycle = [
  'Assigned',
  'Accepted',
  'Ready',
  'En Route',
  'Reached',
  'Rescue in Progress',
  'Transporting',
  'Completed',
];

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────
class _Mission {
  final String id;
  final String title;
  final String incidentType;
  final String location;
  final String coordinates;
  final String priority;
  final String distance;
  final String eta;
  final String assignedAuthority;
  final String safeRouteSummary;
  int trapped;
  int evacuated;
  int medicalCount;
  int missingCount;
  int childrenCount;
  int elderlyCount;
  int disabledCount;
  final String floodDepth;
  final String waterFlow;
  final String landslideRisk;
  final String roadBridgeCondition;
  final List<String> requiredEquipment;
  final String recommendedShelter;
  final String recommendedHospital;
  int stepIndex;
  final Map<int, String> stepTimestamps;

  _Mission({
    required this.id,
    required this.title,
    required this.incidentType,
    required this.location,
    required this.coordinates,
    required this.priority,
    required this.distance,
    required this.eta,
    required this.assignedAuthority,
    required this.safeRouteSummary,
    required this.trapped,
    this.evacuated = 0,
    required this.medicalCount,
    this.missingCount = 0,
    required this.childrenCount,
    required this.elderlyCount,
    this.disabledCount = 1,
    required this.floodDepth,
    required this.waterFlow,
    required this.landslideRisk,
    required this.roadBridgeCondition,
    required this.requiredEquipment,
    required this.recommendedShelter,
    required this.recommendedHospital,
    this.stepIndex = 1,
    Map<int, String>? stepTimestamps,
  }) : stepTimestamps = stepTimestamps ??
            {
              0: '16:45',
              1: '16:48',
            };
}

class _SOSAlert {
  final String id;
  final String callerName;
  final String location;
  final String distance;
  final String emergencyType;
  final int peopleCount;
  final bool hasElderly;
  final bool hasChildren;
  final bool hasMedical;
  final String receivedTime;
  final String priority;
  bool acknowledged;
  bool assigned = false;

  _SOSAlert({
    required this.id,
    required this.callerName,
    required this.location,
    required this.distance,
    required this.emergencyType,
    required this.peopleCount,
    required this.hasElderly,
    required this.hasChildren,
    required this.hasMedical,
    required this.receivedTime,
    required this.priority,
    this.acknowledged = false,
  });
}

class _AssetItem {
  final String name;
  final List<String> tags; // e.g. ['Water Rescue', 'Boat']
  final String code;
  String status; // Available, Assigned, In Use, Low Stock, Low Battery, Damaged
  final int quantity;
  final String unit;
  final String assignedTo; // e.g. 'Team 04' or 'Mission #RS-202'
  final String locationLabel; // 'Assigned to' | 'Location' | 'Available'
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  _AssetItem({
    required this.name,
    required this.tags,
    required this.code,
    required this.status,
    required this.quantity,
    required this.unit,
    this.assignedTo = '',
    this.locationLabel = 'Location',
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });
}

class _OfflineQueueItem {
  final String id;
  final String title;
  final String category;
  final String timestamp;
  String status = 'Queued'; // Queued, Syncing, Synced, Failed

  _OfflineQueueItem({
    required this.id,
    required this.title,
    required this.category,
    required this.timestamp,
  });
}

class _HazardReportItem {
  final String id;
  final String type;
  final String severity;
  final String location;
  final String time;
  final String description;
  final bool hasPhoto;

  _HazardReportItem({
    required this.id,
    required this.type,
    required this.severity,
    required this.location,
    required this.time,
    required this.description,
    required this.hasPhoto,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SCREEN WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class FieldResponderView extends StatefulWidget {
  const FieldResponderView({super.key});

  @override
  State<FieldResponderView> createState() => _FieldResponderViewState();
}

class _FieldResponderViewState extends State<FieldResponderView>
    with TickerProviderStateMixin {
  // ── Navigation ─────────────────────────────────────────────────────────────
  int _tab = 0; // 0=Live Map, 1=Missions, 2=SOS Desk, 3=Assets, 4=Profile

  // ── Tactical Operational State ─────────────────────────────────────────────
  bool _onDuty = true;
  bool _isOffline = false;
  bool _syncing = false;
  DateTime _lastSyncTime = DateTime.now().subtract(const Duration(minutes: 4));
  bool _routeHazardActive = true;
  bool _alternateRouteSelected = false;

  // ── Map Filter Toggles ─────────────────────────────────────────────────────
  String _selectedMapFilter = 'All';
  int _mapLayerIndex = 0; // 0=Topographic Terrain, 1=Satellite, 2=Tactical Dark
  final TransformationController _mapTransformCtrl = TransformationController();
  final MapController _mapController = MapController();
  bool _isNavigating = false;
  final Map<String, bool> _mapFilters = {
    'SOS': true,
    'Mission': true,
    'Flood': true,
    'Roads': true,
    'Shelters': true,
    'Hospitals': true,
  };

  // ── Animations ─────────────────────────────────────────────────────────────
  late AnimationController _radarCtrl;
  late Animation<double> _radarAnim;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // ── Datasets ───────────────────────────────────────────────────────────────
  late List<_Mission> _missions;
  int _activeMissionIdx = 0;
  late List<_SOSAlert> _sosList;
  late List<_AssetItem> _assetsList;
  late List<_OfflineQueueItem> _offlineQueue;
  late List<_HazardReportItem> _recentHazards;

  // ── Filter & Sort states ───────────────────────────────────────────────────
  String _missionsFilter = 'Active'; // Active, Pending, Completed
  String _sosFilter = 'All'; // All, Critical, Nearby, Unassigned, Assigned
  String _assetFilter = 'All'; // All, Ready, In Use, Low, Maintenance
  String _assetSearch = '';
  bool _assetGridView = false;

  // ── Mission Lifecycle Tracking ─────────────────────────────────────────────
  int _newlyCompletedCount = 0; // Badge count for completed tab
  String? _recentlyCompletedId; // ID of last completed mission for highlight

  // ── Readiness Checklist ────────────────────────────────────────────────────
  final Map<String, bool> _readinessChecklist = {
    'Team Assembled & Briefed': true,
    'Rescue Boat & Motor Checked': true,
    'Life Jackets & Helmets Equipped': true,
    'First Aid & Trauma Kit Packed': true,
    'VHF Radios Active on Tac-4': true,
    'Spare Batteries & High-beam Torches': true,
    'Vehicle Fuel & Winch Inspected': true,
    '50m Throw-Bags & Ropes Checked': false,
  };

  StreamSubscription<LiveEvent>? _coordEventSub;

  @override
  void initState() {
    super.initState();

    _radarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _radarAnim = CurvedAnimation(parent: _radarCtrl, curve: Curves.easeInOut);

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.88, end: 1.0).animate(_pulseCtrl);

    _initData();

    IncidentCoordinator.instance.addListener(_onIncidentCoordUpdate);
    _coordEventSub =
        IncidentCoordinator.instance.eventStream.listen(_onLiveEventReceived);
  }

  void _initData() {
    _missions = [
      _Mission(
        id: '#RS-204',
        title: 'Mawphlang Riverbank Flood Extraction',
        incidentType: 'Flood Rescue',
        location: 'Lower Catchment Sector 4, Mawphlang',
        coordinates: '25.4678° N, 91.7539° E',
        priority: 'CRITICAL',
        distance: '2.8 km',
        eta: '9 min',
        assignedAuthority: 'District Emergency Operations Centre (DEOC)',
        safeRouteSummary: 'Via West High Ridge Bypass (Bridge #3 avoided)',
        trapped: 12,
        evacuated: 4,
        medicalCount: 1,
        missingCount: 0,
        childrenCount: 3,
        elderlyCount: 2,
        disabledCount: 1,
        floodDepth: '1.4 m',
        waterFlow: 'Fast Current (2.1 m/s)',
        landslideRisk: 'Medium Risk at Slope 3',
        roadBridgeCondition: 'Eastern Bridge Submerged - Unusable',
        requiredEquipment: [
          'Inflatable Rescue Boat',
          'PFD Level III Life Jackets',
          'Trauma First Aid Kit',
          'Tow Rope & Stretcher'
        ],
        recommendedShelter: 'Government Relief Centre #2 (1.6 km • 38 capacity)',
        recommendedHospital: 'District Civil Hospital (2.4 km • Trauma Ready)',
        stepIndex: 3, // En Route
        stepTimestamps: {
          0: '16:30',
          1: '16:34',
          2: '16:40',
          3: '16:48',
        },
      ),
      _Mission(
        id: '#RS-205',
        title: 'Bus Passengers Stranded at Submerged Culvert',
        incidentType: 'Flash Flood Vehicle Trapped',
        location: 'Damodar River Culvert #4, NH-15 KM 24',
        coordinates: '25.4892° N, 91.7812° E',
        priority: 'CRITICAL',
        distance: '4.2 km',
        eta: '16 min',
        assignedAuthority: 'State Disaster Response Force HQ',
        safeRouteSummary: 'High clearance vehicle route via Sector 2',
        trapped: 18,
        evacuated: 0,
        medicalCount: 3,
        missingCount: 1,
        childrenCount: 5,
        elderlyCount: 4,
        disabledCount: 0,
        floodDepth: '1.6 m',
        waterFlow: 'Turbulent (2.8 m/s)',
        landslideRisk: 'Low',
        roadBridgeCondition: 'Culvert submerged by 40 cm overtopping',
        requiredEquipment: [
          'High Clearance Rescue Truck',
          'Heavy Winch Ropes',
          'Medical Stretcher',
          'Oxygen Cylinder'
        ],
        recommendedShelter: 'Ward 7 Community Shelter (2.1 km)',
        recommendedHospital: 'District Civil Hospital (3.9 km)',
        stepIndex: 0, // Pending – Not yet accepted by responder
        stepTimestamps: {
          0: '17:15', // Assigned at 17:15
        },
      ),
      _Mission(
        id: '#RS-202',
        title: 'Elderly Care Facility Evacuation',
        incidentType: 'Preventive Evacuation',
        location: 'Old Town Lowlands, Lane 5',
        coordinates: '25.4510° N, 91.7401° E',
        priority: 'HIGH',
        distance: '5.1 km',
        eta: 'Completed',
        assignedAuthority: 'Local Civil Administration',
        safeRouteSummary: 'Paved safe road via Ring Expressway',
        trapped: 8,
        evacuated: 8,
        medicalCount: 2,
        missingCount: 0,
        childrenCount: 0,
        elderlyCount: 8,
        disabledCount: 2,
        floodDepth: '0.6 m',
        waterFlow: 'Slow (0.5 m/s)',
        landslideRisk: 'None',
        roadBridgeCondition: 'Passable with caution',
        requiredEquipment: ['Ambulance', 'Wheelchairs', 'Paramedic Unit'],
        recommendedShelter: 'Government Relief Centre #1',
        recommendedHospital: 'District Civil Hospital',
        stepIndex: 7, // Completed
        stepTimestamps: {
          0: '14:00',
          1: '14:05',
          2: '14:15',
          3: '14:20',
          4: '14:35',
          5: '14:40',
          6: '15:10',
          7: '15:45',
        },
      ),
    ];

    _sosList = [
      _SOSAlert(
        id: 'SOS-912',
        callerName: 'Sunita Sangma',
        location: 'Sector 4, Lane 12 near Mawphlang',
        distance: '0.6 km',
        emergencyType: 'Medical Emergency • Pregnant Woman',
        peopleCount: 4,
        hasElderly: false,
        hasChildren: true,
        hasMedical: true,
        receivedTime: '2 min ago',
        priority: 'CRITICAL',
      ),
      _SOSAlert(
        id: 'SOS-908',
        callerName: 'Rajesh Bordoloi',
        location: 'Damodar Culvert East Side',
        distance: '2.1 km',
        emergencyType: 'Rooftop Trapped • Water Rising Fast',
        peopleCount: 7,
        hasElderly: true,
        hasChildren: true,
        hasMedical: false,
        receivedTime: '6 min ago',
        priority: 'CRITICAL',
      ),
      _SOSAlert(
        id: 'SOS-899',
        callerName: 'Bipul Roy',
        location: 'Old Market Alley, Ward 3',
        distance: '3.4 km',
        emergencyType: 'Stranded in Ground Floor Shop',
        peopleCount: 2,
        hasElderly: false,
        hasChildren: false,
        hasMedical: false,
        receivedTime: '15 min ago',
        priority: 'HIGH',
      ),
      _SOSAlert(
        id: 'SOS-891',
        callerName: 'Kavita Das',
        location: 'PWD Colony House #14',
        distance: '4.8 km',
        emergencyType: 'Power Outage • Insulin Need',
        peopleCount: 1,
        hasElderly: true,
        hasChildren: false,
        hasMedical: true,
        receivedTime: '28 min ago',
        priority: 'NORMAL',
        acknowledged: true,
      ),
    ];

    _assetsList = [
      _AssetItem(
        name: 'Inflatable Rescue Boat (IRB)',
        tags: ['Water Rescue', 'Boat'],
        code: 'BOAT-04',
        status: 'In Use',
        quantity: 2,
        unit: 'boats',
        assignedTo: 'Team 04',
        locationLabel: 'Assigned to',
        icon: Icons.directions_boat_rounded,
        iconBg: const Color(0xFFDBEAFE),
        iconColor: const Color(0xFF2563EB),
      ),
      _AssetItem(
        name: 'Emergency Ambulance Unit',
        tags: ['Medical Transport', 'Ambulance'],
        code: 'AMB-12',
        status: 'Assigned',
        quantity: 1,
        unit: 'vehicle',
        assignedTo: 'Mission #RS-202',
        locationLabel: 'Assigned to',
        icon: Icons.local_hospital_rounded,
        iconBg: const Color(0xFFFFE4E6),
        iconColor: const Color(0xFFDC2626),
      ),
      _AssetItem(
        name: '4WD Rescue Vehicle',
        tags: ['Transport', '4WD'],
        code: 'VEH-03',
        status: 'Available',
        quantity: 2,
        unit: 'trucks',
        assignedTo: 'Base Camp',
        locationLabel: 'Location',
        icon: Icons.directions_car_rounded,
        iconBg: const Color(0xFFDCFCE7),
        iconColor: const Color(0xFF16A34A),
      ),
      _AssetItem(
        name: 'VHF Handheld Radios',
        tags: ['Communications', 'Radio'],
        code: 'RAD-SST-4',
        status: 'Available',
        quantity: 6,
        unit: 'radios',
        assignedTo: 'Team 04',
        locationLabel: 'Location',
        icon: Icons.radio_rounded,
        iconBg: const Color(0xFFEDE9FE),
        iconColor: const Color(0xFF7C3AED),
      ),
      _AssetItem(
        name: 'GPS Handheld Units',
        tags: ['Navigation', 'GPS'],
        code: 'GPS-NAW',
        status: 'Available',
        quantity: 4,
        unit: 'units',
        assignedTo: 'Team 04',
        locationLabel: 'Location',
        icon: Icons.gps_fixed_rounded,
        iconBg: const Color(0xFFCCFBF1),
        iconColor: const Color(0xFF0D9488),
      ),
      _AssetItem(
        name: 'PFD Level III Life Jackets',
        tags: ['Safety', 'Life Jacket'],
        code: 'PFD-03',
        status: 'Low Stock',
        quantity: 36,
        unit: 'vests',
        assignedTo: '8 vests',
        locationLabel: 'Available',
        icon: Icons.safety_divider_rounded,
        iconBg: const Color(0xFFFFF7ED),
        iconColor: const Color(0xFFEA580C),
      ),
      _AssetItem(
        name: '50m Static Rescue Ropes',
        tags: ['Rigging', 'Rope'],
        code: 'ROP-50',
        status: 'Low Stock',
        quantity: 3,
        unit: 'spools',
        assignedTo: '3 spools',
        locationLabel: 'Available',
        icon: Icons.cable_rounded,
        iconBg: const Color(0xFFFFF7ED),
        iconColor: const Color(0xFFEA580C),
      ),
      _AssetItem(
        name: 'Trauma First-Aid Packs',
        tags: ['Medical', 'First Aid'],
        code: 'MED-FA',
        status: 'Available',
        quantity: 8,
        unit: 'kits',
        assignedTo: 'Base Camp',
        locationLabel: 'Location',
        icon: Icons.medical_services_rounded,
        iconBg: const Color(0xFFFFE4E6),
        iconColor: const Color(0xFFDC2626),
      ),
      _AssetItem(
        name: 'Portable Medical Oxygen',
        tags: ['Medical', 'Oxygen'],
        code: 'O2-CYL',
        status: 'Low Stock',
        quantity: 2,
        unit: 'cylinders',
        assignedTo: '2 cylinders',
        locationLabel: 'Available',
        icon: Icons.air_rounded,
        iconBg: const Color(0xFFFFF7ED),
        iconColor: const Color(0xFFEA580C),
      ),
      _AssetItem(
        name: 'Aerial Recon Drone',
        tags: ['Recon', 'Drone'],
        code: 'DRN-02',
        status: 'Maintenance',
        quantity: 1,
        unit: 'drone',
        assignedTo: 'Repair Bay',
        locationLabel: 'Location',
        icon: Icons.flight_rounded,
        iconBg: const Color(0xFFF1F5F9),
        iconColor: const Color(0xFF64748B),
      ),
      _AssetItem(
        name: 'Portable Dewatering Pump',
        tags: ['Drainage', 'Pump'],
        code: 'PMP-400',
        status: 'Available',
        quantity: 2,
        unit: 'pumps',
        assignedTo: 'Base Camp',
        locationLabel: 'Location',
        icon: Icons.water_drop_rounded,
        iconBg: const Color(0xFFDBEAFE),
        iconColor: const Color(0xFF2563EB),
      ),
      _AssetItem(
        name: 'Chainsaw (Rescue Grade)',
        tags: ['Rescue', 'Cutting'],
        code: 'CSW-01',
        status: 'Available',
        quantity: 2,
        unit: 'units',
        assignedTo: 'Equipment Bay',
        locationLabel: 'Location',
        icon: Icons.handyman_rounded,
        iconBg: const Color(0xFFDCFCE7),
        iconColor: const Color(0xFF16A34A),
      ),
    ];

    _offlineQueue = [
      _OfflineQueueItem(
        id: 'Q-101',
        title: 'Hazard: Eastern Bridge Structural Crack Reported',
        category: 'Hazard Report',
        timestamp: '17:12:04',
      ),
      _OfflineQueueItem(
        id: 'Q-102',
        title: 'Rescue Count: 4 Persons Evacuated to Boat',
        category: 'Rescue Count',
        timestamp: '17:18:22',
      ),
      _OfflineQueueItem(
        id: 'Q-103',
        title: 'Infrastructure: Road B Marked Blocked',
        category: 'Road Status',
        timestamp: '17:24:50',
      ),
    ];

    _recentHazards = [
      _HazardReportItem(
        id: 'HZD-802',
        type: 'Bridge Damage',
        severity: 'Critical',
        location: 'Mawphlang Eastern Bridge',
        time: '12 min ago',
        description:
            'Cracks observed on pillar 2. Water flowing 20cm above deck.',
        hasPhoto: true,
      ),
      _HazardReportItem(
        id: 'HZD-799',
        type: 'Flooded Road',
        severity: 'High',
        location: 'NH-15 KM 24 Culvert Area',
        time: '24 min ago',
        description: 'Water depth 1.4m. Impassable for light vehicles.',
        hasPhoto: true,
      ),
      _HazardReportItem(
        id: 'HZD-791',
        type: 'Landslide',
        severity: 'Medium',
        location: 'Slope Sector 3 Hill Road',
        time: '45 min ago',
        description: 'Mud and loose boulders on northern shoulder.',
        hasPhoto: false,
      ),
    ];
  }

  @override
  void dispose() {
    IncidentCoordinator.instance.removeListener(_onIncidentCoordUpdate);
    _coordEventSub?.cancel();
    _mapTransformCtrl.dispose();
    _radarCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _onIncidentCoordUpdate() {
    if (!mounted) return;
    setState(() {
      final activeM = IncidentCoordinator.instance.activeTeamMission;
      if (activeM != null) {
        final localM = _missions.where((m) =>
            m.id.replaceAll('#', '').contains(activeM.id.replaceAll('#', '')) ||
            activeM.id.replaceAll('#', '').contains(m.id.replaceAll('#', ''))).firstOrNull;
        if (localM != null) {
          localM.stepIndex = activeM.stepIndex;
          localM.trapped = activeM.trapped;
          localM.evacuated = activeM.evacuated;
          localM.medicalCount = activeM.medicalCount;
        }
      }
    });
  }

  void _onLiveEventReceived(LiveEvent event) {
    if (!mounted) return;
    if (event.type == LiveEventType.teamAssigned) {
      final mission = event.payload as MissionAssignment;
      _showIncomingMissionAlert(mission);
    } else if (event.type == LiveEventType.shelterUpdated) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.night_shelter_rounded, color: Color(0xFF38BDF8), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${event.title}: ${event.message}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'VIEW',
            textColor: const Color(0xFF38BDF8),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CitizenSheltersView(isResponder: true),
                ),
              );
            },
          ),
        ),
      );
    }
  }

  void _showIncomingMissionAlert(MissionAssignment mission) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF38BDF8), width: 1.8),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Color(0xFF38BDF8), size: 26),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '🚨 NEW CRITICAL MISSION ${mission.id}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mission.title,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              'Linked SOS: ${mission.linkedSosId}',
              style: const TextStyle(
                  color: Color(0xFF38BDF8),
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
            ),
            Text(
              'Location: ${mission.location}',
              style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
            ),
            Text(
              'Trapped: ${mission.trapped} people • Medical: ${mission.medicalCount}',
              style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
            ),
            Text(
              'Distance: ${mission.initialDistance} • Priority: ${mission.priority}',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('View', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              IncidentCoordinator.instance.acceptMission(mission.id);
              final localM = _missions.where((m) =>
                  m.id.replaceAll('#', '') == mission.id.replaceAll('#', '')).firstOrNull;
              if (localM != null) {
                _acceptMission(localM);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
            ),
            child: const Text('ACCEPT MISSION',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Mission Getters & Handlers ─────────────────────────────────────────────
  _Mission get _activeMission => _missions[_activeMissionIdx];

  void _advanceMissionLifecycle() {
    final m = _activeMission;
    if (m.stepIndex < _kMissionLifecycle.length - 1) {
      setState(() {
        m.stepIndex++;
        final now = TimeOfDay.now();
        final formatted =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        m.stepTimestamps[m.stepIndex] = formatted;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _C.govBlue,
          duration: const Duration(seconds: 2),
          content: Text(
            'Mission updated: ${_kMissionLifecycle[m.stepIndex]} at ${m.stepTimestamps[m.stepIndex]}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }

  Future<void> _triggerSync() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    await Future.delayed(const Duration(milliseconds: 1600));
    if (mounted) {
      setState(() {
        _syncing = false;
        _lastSyncTime = DateTime.now();
        for (var item in _offlineQueue) {
          item.status = 'Synced';
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: _C.safe,
          duration: Duration(seconds: 2),
          content: Text('All pending ground reports synchronized to Authority'),
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MAIN BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return RoleQuickSwitcherOverlay(
      currentRole: CurrentDashboardRole.fieldResponder,
      child: Scaffold(
        backgroundColor: _C.pageBg,
        body: SafeArea(
          child: IndexedStack(
            index: _tab,
            children: [
              _buildLiveMapTab(),
              _buildMissionsTab(),
              _buildSOSDeskTab(),
              _buildAssetsTab(),
              _buildProfileTab(),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 5-DESTINATION BOTTOM NAVIGATION BAR
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    final destinations = [
      {'label': 'Live Map', 'icon': Icons.map_rounded},
      {'label': 'Missions', 'icon': Icons.assignment_outlined},
      {'label': 'SOS Desk', 'icon': Icons.sos_rounded},
      {'label': 'Assets', 'icon': Icons.inventory_2_outlined},
      {'label': 'Profile', 'icon': Icons.person_outline_rounded},
    ];

    final unackSOS = _sosList.where((s) => !s.acknowledged).length;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: ColoredBox(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
            children: List.generate(destinations.length, (i) {
              final selected = _tab == i;
              final d = destinations[i];
              final isSOS = i == 2;

              return Expanded(
                child: InkWell(
                  onTap: () => setState(() => _tab = i),
                  splashColor: _C.actionBlue.withValues(alpha: 0.08),
                  highlightColor: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 3),
                              decoration: BoxDecoration(
                                color: selected
                                    ? _C.actionBlue.withValues(alpha: 0.10)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                d['icon'] as IconData,
                                color: selected
                                    ? _C.actionBlue
                                    : const Color(0xFF94A3B8),
                                size: 22,
                              ),
                            ),
                            if (isSOS && (unackSOS > 0 || true))
                              Positioned(
                                right: 6,
                                top: -2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDC2626),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${unackSOS > 0 ? unackSOS : 3}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          d['label'] as String,
                          style: TextStyle(
                            color: selected
                                ? _C.actionBlue
                                : const Color(0xFF94A3B8),
                            fontSize: 10,
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 0 — LIVE MAP (ACTION WORKSPACE)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildLiveMapTab() {
    return Column(
      children: [
        _buildAppHeader(),
        _buildOfflineBanner(),
        _buildActiveMissionTopCard(),
        if (_routeHazardActive) _buildRouteHazardWarningBanner(),
        Expanded(
          child: Stack(
            children: [
              _buildTacticalMap(),
              Positioned(
                top: 8,
                left: 10,
                right: 10,
                child: _buildMapFilterChips(),
              ),
              Positioned(
                right: 12,
                top: 56,
                child: _buildFloatingMapControls(),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildMapActionDock(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Header: JalGuard Field Operations ──────────────────────────────────────
  Widget _buildAppHeader() {
    return Container(
      color: const Color(0xFF0C2340),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // ── Back to Role button ──────────────────────────────────────────
          GestureDetector(
            onTap: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => const RoleSelectionScreen(),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18), width: 1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white70, size: 13),
                  SizedBox(width: 4),
                  Text(
                    'Back to Role',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // JalGuard shield icon
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFF163352),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: const Color(0xFF38BDF8), width: 1.2),
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: Color(0xFF38BDF8),
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          // Team & Org title
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'JalGuard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  'Field Operations',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Online dot indicator
          GestureDetector(
            onTap: () => setState(() => _onDuty = !_onDuty),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: _onDuty ? const Color(0xFF22C55E) : _C.critical,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_onDuty ? const Color(0xFF22C55E) : _C.critical)
                            .withValues(alpha: 0.6),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _onDuty ? 'Online' : 'Offline',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Notification Bell with red dot
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFF0C2340),
                  content: Text('DEOC Dispatch: 3 High-priority flood alerts in Sector 4'),
                ),
              );
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                Positioned(
                  top: -1,
                  right: -1,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF0C2340), width: 1.2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Offline Warning Banner (cached data notice) ───────────────────────────
  Widget _buildOfflineBanner() {
    if (!_isOffline) return const SizedBox.shrink();
    final diff = DateTime.now().difference(_lastSyncTime).inMinutes;
    return Container(
      width: double.infinity,
      color: _C.warning,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Offline • Last synced $diff min ago • Using cached operational map',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _isOffline = false),
            child: const Text(
              'Go Online',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Active Mission Top Card ────────────────────────────────────────────────
  Widget _buildActiveMissionTopCard() {
    final m = _activeMission;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFCA5A5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on, color: Colors.white, size: 11),
                    SizedBox(width: 3),
                    Text(
                      'ACTIVE MISSION',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                m.id,
                style: const TextStyle(
                  color: Color(0xFF0B213B),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  m.priority,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            m.title,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded,
                    color: Color(0xFF475569), size: 13),
                const SizedBox(width: 3),
                Text(
                  '${m.trapped} people trapped',
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text('  •  ',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5)),
                const Icon(Icons.person_rounded,
                    color: Color(0xFF475569), size: 13),
                const SizedBox(width: 3),
                Text(
                  '${m.elderlyCount} elderly',
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (m.medicalCount > 0) ...[
                  const Text('  •  ',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5)),
                  const Icon(Icons.medical_services_rounded,
                      color: Color(0xFF475569), size: 12),
                  const SizedBox(width: 3),
                  Text(
                    '${m.medicalCount} medical',
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                const Icon(Icons.navigation_rounded,
                    color: Color(0xFF475569), size: 13),
                const SizedBox(width: 4),
                Text(
                  '${m.distance}    |    ETA ${m.eta}',
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _tab = 1);
                  },
                  icon: const Icon(Icons.explore_outlined,
                      color: Color(0xFF0066D6), size: 16),
                  label: const Text(
                    'View Mission',
                    style: TextStyle(
                      color: Color(0xFF0066D6),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                        color: Color(0xFF0066D6), width: 1.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _isNavigating = !_isNavigating);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF0066D6),
                        content: Text(
                          _isNavigating
                              ? 'Turn-by-turn navigation started to ${m.location}'
                              : 'Navigation paused',
                        ),
                      ),
                    );
                  },
                  icon: Icon(
                    _isNavigating
                        ? Icons.navigation_rounded
                        : Icons.navigation_outlined,
                    color: Colors.white,
                    size: 16,
                  ),
                  label: Text(
                    _isNavigating ? 'Navigating...' : 'Navigate',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066D6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMissionLeftDetails(_Mission m) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.crisis_alert_rounded,
                color: Color(0xFFDC2626),
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _C.critical,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'ACTIVE MISSION',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        m.id,
                        style: const TextStyle(
                          color: _C.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    m.title,
                    style: const TextStyle(
                      color: Color(0xFF013973),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F7F0),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                m.priority == 'CRITICAL' ? 'PRIORITY 1' : m.priority,
                style: const TextStyle(
                  color: Color(0xFF0E5C38),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.location_on_rounded, color: _C.textMuted, size: 14),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '${m.location} (${m.distance} • ETA ${m.eta})',
                style: const TextStyle(color: _C.textSecondary, fontSize: 11.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            _metricChip(Icons.people_rounded, '${m.trapped} Trapped', _C.navy),
            _metricChip(Icons.child_care_rounded, '${m.childrenCount} Children',
                _C.govBlue),
            _metricChip(
                Icons.elderly_rounded, '${m.elderlyCount} Elderly', _C.warning),
            if (m.medicalCount > 0)
              _metricChip(Icons.medical_services_rounded,
                  '${m.medicalCount} Medical', _C.critical),
          ],
        ),
      ],
    );
  }

  Widget _buildMissionLifecycleRightPanel(_Mission m, int step5) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Key Stats Grid matching user's exact specification
        Row(
          children: [
            _buildMissionStat(
                '👥 Trapped', '${m.trapped} People', const Color(0xFF0F172A)),
            _buildMissionStat(
                '🆘 SOS Count', '6 Calls', const Color(0xFFDC2626)),
            _buildMissionStat(
                '🌊 Flood Depth', m.floodDepth, const Color(0xFF007AEB)),
            _buildMissionStat(
                '🛣️ Route', 'Boat Route 2', const Color(0xFF15945C)),
          ],
        ),
        const SizedBox(height: 14),

        // Interactive Mission Status Stepper
        const Text(
          'Mission Lifecycle Tracker:',
          style: TextStyle(
            color: Color(0xFF013973),
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        _buildMissionLifecycleStepper(step5),
        const SizedBox(height: 14),

        // Action Buttons Row matching user's exact specification
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _advance5Step(m),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF15945C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: const Size(0, 44),
                ),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: Text(
                  _fiveStepButtonLabel(step5),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: () => setState(() => _tab = 0),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF007AEB),
                side: const BorderSide(color: Color(0xFF007AEB), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                minimumSize: const Size(0, 44),
              ),
              icon: const Icon(Icons.map_rounded,
                  color: Color(0xFF007AEB), size: 18),
              label: const Text(
                'Live Map',
                style: TextStyle(
                  color: Color(0xFF007AEB),
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMissionStat(String title, String value, Color valueColor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionLifecycleStepper(int currentStep) {
    const steps = ['Assigned', 'Accepted', 'En Route', 'Reached', 'Completed'];
    return Row(
      children: List.generate(steps.length, (index) {
        final bool isPassed = index <= currentStep;
        final bool isCurrent = index == currentStep;

        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 3,
                      color: index == 0
                          ? Colors.transparent
                          : (index <= currentStep
                              ? const Color(0xFF15945C)
                              : const Color(0xFFE2E8F0)),
                    ),
                  ),
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPassed
                          ? const Color(0xFF15945C)
                          : const Color(0xFFE2E8F0),
                      border: isCurrent
                          ? Border.all(
                              color: const Color(0xFF10B981), width: 3)
                          : null,
                    ),
                    child: isPassed
                        ? const Center(
                            child: Icon(Icons.check,
                                color: Colors.white, size: 11),
                          )
                        : null,
                  ),
                  Expanded(
                    child: Container(
                      height: 3,
                      color: index == steps.length - 1
                          ? Colors.transparent
                          : (index < currentStep
                              ? const Color(0xFF15945C)
                              : const Color(0xFFE2E8F0)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                steps[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isCurrent
                      ? const Color(0xFF15945C)
                      : (isPassed
                          ? const Color(0xFF013973)
                          : const Color(0xFF94A3B8)),
                  fontSize: 9.5,
                  fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  int _to5Step(int step8) {
    if (step8 <= 0) return 0; // Assigned
    if (step8 <= 2) return 1; // Accepted
    if (step8 == 3) return 2; // En Route
    if (step8 <= 6) return 3; // Reached
    return 4; // Completed
  }

  void _advance5Step(_Mission m) {
    final cur5 = _to5Step(m.stepIndex);
    if (cur5 < 4) {
      setState(() {
        if (cur5 == 0) {
          m.stepIndex = 1; // Accepted
        } else if (cur5 == 1) {
          m.stepIndex = 3; // En Route
        } else if (cur5 == 2) {
          m.stepIndex = 4; // Reached
        } else if (cur5 == 3) {
          m.stepIndex = 7; // Completed
        }
        final now = TimeOfDay.now();
        m.stepTimestamps[m.stepIndex] =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      });
      const labels = [
        'Assigned',
        'Accepted',
        'En Route',
        'Reached',
        'Completed'
      ];
      final next5 = _to5Step(m.stepIndex);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF15945C),
          content: Text('Mission Status Updated: ${labels[next5]}'),
        ),
      );
    }
  }

  String _fiveStepButtonLabel(int step5) {
    switch (step5) {
      case 1:
        return 'Depart (En Route)';
      case 2:
        return 'Mark Reached';
      case 3:
        return 'Mark Completed';
      default:
        return 'Mission Done';
    }
  }

  // ── Accept Mission (Pending → Active) ─────────────────────────────────────
  void _acceptMission(_Mission m) {
    final now = TimeOfDay.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final cleanId = m.id.replaceAll('#', '');
    IncidentCoordinator.instance.acceptMission(
        cleanId.startsWith('RS') ? cleanId : 'RS-204');

    setState(() {
      m.stepIndex = 1; // Accepted
      m.stepTimestamps[1] = timeStr;
      _missionsFilter = 'Active'; // Switch to Active tab
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _C.safe,
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Mission ${m.id} accepted at $timeStr — Lifecycle tracker activated',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Advance Active Mission lifecycle ──────────────────────────────────────
  void _advanceActiveMission(_Mission m) {
    final cur5 = _to5Step(m.stepIndex);
    if (cur5 >= 4) return; // Already completed
    final now = TimeOfDay.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final cleanId = m.id.replaceAll('#', '');
    final coordMissionId =
        cleanId.startsWith('RS') ? cleanId : 'RS-204';

    if (cur5 == 1) {
      IncidentCoordinator.instance.startNavigation(coordMissionId);
    } else if (cur5 == 2) {
      IncidentCoordinator.instance.arriveOnSite(coordMissionId);
    } else if (cur5 == 3) {
      IncidentCoordinator.instance.completeMission(coordMissionId);
    }

    setState(() {
      if (cur5 == 1) {
        m.stepIndex = 3; // En Route
      } else if (cur5 == 2) {
        m.stepIndex = 4; // Reached
      } else if (cur5 == 3) {
        m.stepIndex = 7; // Completed
        _newlyCompletedCount++;
        _recentlyCompletedId = m.id;
      }
      m.stepTimestamps[m.stepIndex] = timeStr;
    });

    const labels = ['Assigned', 'Accepted', 'En Route', 'Reached', 'Completed'];
    final next5 = _to5Step(m.stepIndex);
    final isCompleted = m.stepIndex == 7;

    if (isCompleted) {
      // Switch to Completed tab after a short delay
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          setState(() => _missionsFilter = 'Completed');
        }
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isCompleted ? _C.safe : _C.govBlue,
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Icon(
              isCompleted
                  ? Icons.task_alt_rounded
                  : Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isCompleted
                    ? 'Mission ${m.id} completed at $timeStr — Great work!'
                    : 'Mission status: ${labels[next5]} at $timeStr',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Route Hazard Alert Banner ─────────────────────────────────────────────
  Widget _buildRouteHazardWarningBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 2, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97706).withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Color(0xFFD97706),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: Colors.white, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Route Hazard',
                  style: TextStyle(
                    color: Color(0xFFD97706),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  _alternateRouteSelected
                      ? 'Bypassing Eastern bridge via West High Ridge'
                      : 'Eastern bridge reported unsafe • Water overtopping',
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              setState(() {
                _alternateRouteSelected = !_alternateRouteSelected;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF0066D6),
                  content: Text(
                    _alternateRouteSelected
                        ? 'Safe alternate route activated: via West Ridge Bypass'
                        : 'Reverted to primary planned route',
                  ),
                ),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _alternateRouteSelected ? 'Primary' : 'Alt Route',
                  style: const TextStyle(
                    color: Color(0xFF0066D6),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_forward_rounded,
                    size: 13, color: Color(0xFF0066D6)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tactical Emergency Map (Real Live Map API) ───────────────────────────
  Widget _buildTacticalMap() {
    final showFlood = _selectedMapFilter == 'All' || _selectedMapFilter == 'Flood';
    final showHazard = _selectedMapFilter == 'All' || _selectedMapFilter == 'Roads';
    final showRoute = _selectedMapFilter == 'All' || _selectedMapFilter == 'Mission' || _selectedMapFilter == 'Roads';
    final showSOS = _selectedMapFilter == 'All' || _selectedMapFilter == 'SOS';
    final showShelters = _selectedMapFilter == 'All' || _selectedMapFilter == 'Shelters';

    final tileUrl = _mapLayerIndex == 1
        ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
        : (_mapLayerIndex == 2
            ? 'https://cartodb-basemaps-a.global.ssl.fastly.net/dark_all/{z}/{x}/{y}.png'
            : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png');

    return FlutterMap(
      mapController: _mapController,
      options: const MapOptions(
        initialCenter: LatLng(25.5685, 91.8760),
        initialZoom: 13.5,
        minZoom: 9.0,
        maxZoom: 18.0,
        interactionOptions: InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        // 1. Base Map Tile Layer (OSM / Satellite / Dark)
        TileLayer(
          urlTemplate: tileUrl,
          userAgentPackageName: 'com.resqshield.app',
          maxZoom: 19,
        ),

        // 2. Live CEMS GFM Flood Inundation WMS-T Raster Layer from Railway API
        if (showFlood)
          TileLayer(
            urlTemplate: ApiConstants.floodTileTemplate,
            userAgentPackageName: 'com.resqshield.app',
          ),

        // 3. Flood Inundation Danger Polygon (Mawphlang Riverbank)
        if (showFlood)
          PolygonLayer(
            polygons: <Polygon>[
              Polygon(
                points: const [
                  LatLng(25.5750, 91.8680),
                  LatLng(25.5780, 91.8740),
                  LatLng(25.5760, 91.8820),
                  LatLng(25.5710, 91.8850),
                  LatLng(25.5660, 91.8790),
                  LatLng(25.5680, 91.8710),
                ],
                color: const Color(0xFFDC2626).withValues(alpha: 0.28),
                borderColor: const Color(0xFFDC2626).withValues(alpha: 0.8),
                borderStrokeWidth: 2.0,
              ),
            ],
          ),

        // 4. Safe Routes & Detour Polylines
        if (showRoute)
          PolylineLayer(
            polylines: [
              // Primary Safe Green Path
              Polyline(
                points: const [
                  LatLng(25.5672, 91.8831), // Responder location
                  LatLng(25.5695, 91.8800),
                  LatLng(25.5710, 91.8760),
                  LatLng(25.5725, 91.8710),
                  LatLng(25.5710, 91.8680), // Target SOS
                ],
                color: const Color(0xFF16A34A),
                strokeWidth: 4.8,
              ),
              // Blue Approach Segment
              Polyline(
                points: const [
                  LatLng(25.5672, 91.8831),
                  LatLng(25.5685, 91.8750),
                  LatLng(25.5710, 91.8680),
                ],
                color: const Color(0xFF0066D6),
                strokeWidth: 4.0,
              ),
              // Hazard / Alternate Detour
              if (_alternateRouteSelected)
                Polyline(
                  points: const [
                    LatLng(25.5672, 91.8831),
                    LatLng(25.5630, 91.8810),
                    LatLng(25.5620, 91.8720),
                    LatLng(25.5680, 91.8680),
                  ],
                  color: const Color(0xFF0284C7),
                  strokeWidth: 3.8,
                  pattern: const StrokePattern.dotted(),
                )
              else if (showHazard)
                Polyline(
                  points: const [
                    LatLng(25.5695, 91.8800),
                    LatLng(25.5705, 91.8840), // Unsafe Eastern bridge
                  ],
                  color: const Color(0xFFDC2626),
                  strokeWidth: 3.5,
                ),
            ],
          ),

        // 5. Tactical Markers Layer
        MarkerLayer(
          markers: [
            // Responder Location Marker with Animated Radar Pulse
            Marker(
              point: const LatLng(25.5672, 91.8831),
              width: 54,
              height: 54,
              child: AnimatedBuilder(
                animation: _radarAnim,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer animated radar pulse ring
                      Container(
                        width: 24 + (_radarAnim.value * 28),
                        height: 24 + (_radarAnim.value * 28),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF0066D6).withValues(
                              alpha: (1.0 - _radarAnim.value) * 0.7,
                            ),
                            width: 2.0,
                          ),
                        ),
                      ),
                      // Soft blue halo
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                        ),
                      ),
                      // Solid center white & blue dot
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0066D6),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black38,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // SOS Teardrop Pins
            if (showSOS) ...[
              Marker(
                point: const LatLng(25.5710, 91.8680),
                width: 44,
                height: 48,
                alignment: Alignment.topCenter,
                child: _buildTeardropSOSMarker('SOS'),
              ),
              Marker(
                point: const LatLng(25.5735, 91.8780),
                width: 44,
                height: 48,
                alignment: Alignment.topCenter,
                child: _buildTeardropSOSMarker('SOS'),
              ),
            ],

            // Eastern Bridge Caution Marker
            if (showHazard) ...[
              Marker(
                point: const LatLng(25.5705, 91.8840),
                width: 38,
                height: 38,
                child: _buildCircularHazardMarker(
                  icon: Icons.warning_rounded,
                  bgColor: const Color(0xFFEA580C),
                ),
              ),
              Marker(
                point: const LatLng(25.5680, 91.8825),
                width: 34,
                height: 34,
                child: _buildCircularHazardMarker(
                  icon: Icons.do_not_disturb_on_rounded,
                  bgColor: const Color(0xFFDC2626),
                ),
              ),
              Marker(
                point: const LatLng(25.5645, 91.8690),
                width: 32,
                height: 32,
                child: _buildCircularHazardMarker(
                  icon: Icons.priority_high_rounded,
                  bgColor: const Color(0xFF0F172A),
                ),
              ),
            ],

            // Shelter Marker
            if (showShelters)
              Marker(
                point: const LatLng(25.5610, 91.8880),
                width: 36,
                height: 36,
                child: _buildCircularHazardMarker(
                  icon: Icons.night_shelter_rounded,
                  bgColor: const Color(0xFF0284C7),
                ),
              ),

            // Town Label Marker ("Mawphlang")
            Marker(
              point: const LatLng(25.5625, 91.8790),
              width: 100,
              height: 24,
              child: const Center(
                child: Text(
                  'Mawphlang',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 12.0,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                    shadows: [
                      Shadow(color: Colors.white, blurRadius: 4),
                      Shadow(color: Colors.white, blurRadius: 8),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Teardrop SOS Marker Widget ─────────────────────────────────────────────
  Widget _buildTeardropSOSMarker(String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFDC2626),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.sos_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        CustomPaint(
          size: const Size(10, 6),
          painter: _TrianglePointerPainter(color: const Color(0xFFDC2626)),
        ),
      ],
    );
  }

  // ── Circular Hazard / Shelter Marker Widget ────────────────────────────────
  Widget _buildCircularHazardMarker({
    required IconData icon,
    required Color bgColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  // ── Map Filter Chips ───────────────────────────────────────────────────────
  Widget _buildMapFilterChips() {
    const filterList = ['All', 'SOS', 'Mission', 'Flood', 'Roads', 'Shelters'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filterList.map((filter) {
          final isSelected = _selectedMapFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedMapFilter = filter;
                  if (filter == 'All') {
                    for (final k in _mapFilters.keys) {
                      _mapFilters[k] = true;
                    }
                  } else {
                    for (final k in _mapFilters.keys) {
                      _mapFilters[k] = (k == filter);
                    }
                  }
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6.5),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0066D6) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF0066D6)
                        : const Color(0xFFCBD5E1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1.5),
                    ),
                  ],
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF1E293B),
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Floating Map Controls on Right ─────────────────────────────────────────
  Widget _buildFloatingMapControls() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.layers_rounded,
                color: Color(0xFF1E293B), size: 20),
            tooltip: 'Toggle Map Layer',
            onPressed: () {
              setState(() {
                _mapLayerIndex = (_mapLayerIndex + 1) % 3;
              });
              final names = [
                'Topographic Terrain',
                'Satellite Imagery',
                'Tactical Dark'
              ];
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  duration: const Duration(seconds: 1),
                  backgroundColor: const Color(0xFF0B213B),
                  content: Text('Map Style: ${names[_mapLayerIndex]}'),
                ),
              );
            },
          ),
          IconButton(
            constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.my_location_rounded,
                color: Color(0xFF1E293B), size: 20),
            tooltip: 'Center on Team',
            onPressed: () {
              try {
                _mapController.move(const LatLng(25.5672, 91.8831), 13.5);
              } catch (_) {}
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  duration: Duration(seconds: 1),
                  backgroundColor: Color(0xFF0066D6),
                  content: Text('Centered on Team Bravo GPS'),
                ),
              );
            },
          ),
          const Divider(
              height: 6,
              thickness: 1,
              indent: 6,
              endIndent: 6,
              color: Color(0xFFE2E8F0)),
          IconButton(
            constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.add_rounded,
                color: Color(0xFF1E293B), size: 22),
            tooltip: 'Zoom In',
            onPressed: () {
              try {
                _mapController.move(
                  _mapController.camera.center,
                  _mapController.camera.zoom + 0.8,
                );
              } catch (_) {}
            },
          ),
          IconButton(
            constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.remove_rounded,
                color: Color(0xFF1E293B), size: 22),
            tooltip: 'Zoom Out',
            onPressed: () {
              try {
                _mapController.move(
                  _mapController.camera.center,
                  _mapController.camera.zoom - 0.8,
                );
              } catch (_) {}
            },
          ),
        ],
      ),
    );
  }

  // ── Map Bottom Action Dock matching Screenshot 1 ───────────────────────────
  Widget _buildMapActionDock() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionDockCircleBtn(
            icon: Icons.phone_rounded,
            label: 'Request\nBackup',
            circleColor: const Color(0xFFDC2626),
            onTap: _openRequestBackupSheet,
          ),
          _buildActionDockCircleBtn(
            icon: Icons.warning_rounded,
            label: 'Report\nHazard',
            circleColor: const Color(0xFFEA580C),
            onTap: _openReportHazardSheet,
          ),
          _buildActionDockCircleBtn(
            icon: Icons.phone_in_talk_rounded,
            label: 'Control\nRoom',
            circleColor: const Color(0xFF0066D6),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFF0066D6),
                  content:
                      Text('Connecting to DEOC Control Room on VHF Tac-4...'),
                ),
              );
            },
          ),
          _buildActionDockCircleBtn(
            icon: Icons.location_on_rounded,
            label: 'Share\nLocation',
            circleColor: const Color(0xFF16A34A),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFF16A34A),
                  content: Text(
                      'GPS coordinates 25.5672° N, 91.8831° E broadcasted'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionDockCircleBtn({
    required IconData icon,
    required String label,
    required Color circleColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: circleColor.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 1 — MISSIONS (Realistic Lifecycle)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildMissionsTab() {
    final activeMissions =
        _missions.where((m) => m.stepIndex >= 1 && m.stepIndex < 7).toList();
    final pendingMissions =
        _missions.where((m) => m.stepIndex == 0).toList();
    final completedMissions =
        _missions.where((m) => m.stepIndex == 7).toList();

    return Column(
      children: [
        _buildSectionHeader(
          title: 'Mission Assignments',
          icon: Icons.assignment_rounded,
          subtitle: '${_missions.length} assigned operations',
        ),
        // ── Filter Tab Bar ──────────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildMissionFilterTab(
                label: 'Active',
                count: activeMissions.length,
                badgeColor: _C.actionBlue,
              ),
              const SizedBox(width: 8),
              _buildMissionFilterTab(
                label: 'Pending',
                count: pendingMissions.length,
                badgeColor: _C.warning,
              ),
              const SizedBox(width: 8),
              _buildMissionFilterTab(
                label: 'Completed',
                count: completedMissions.length,
                badgeColor: _C.safe,
                newCount: _newlyCompletedCount,
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        Expanded(
          child: _missionsFilter == 'Active'
              ? _buildActiveView(activeMissions)
              : _missionsFilter == 'Pending'
                  ? _buildPendingView(pendingMissions)
                  : _buildCompletedView(completedMissions),
        ),
      ],
    );
  }

  // ── Filter Tab Button ────────────────────────────────────────────────────
  Widget _buildMissionFilterTab({
    required String label,
    required int count,
    required Color badgeColor,
    int newCount = 0,
  }) {
    final selected = _missionsFilter == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _missionsFilter = label;
            if (label == 'Completed') _newlyCompletedCount = 0;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? badgeColor : _C.pageBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? badgeColor : const Color(0xFFE2E8F0),
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? Colors.white : _C.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$count',
                    style: TextStyle(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.85)
                          : badgeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              if (newCount > 0)
                Positioned(
                  top: 0,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: _C.critical,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '+$newCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── ACTIVE VIEW — Missions in progress ──────────────────────────────────
  Widget _buildActiveView(List<_Mission> missions) {
    if (missions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.directions_run_rounded,
        message: 'No active missions',
        sub: 'Accept a pending assignment to begin',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: missions.length,
      itemBuilder: (_, i) => _buildActiveMissionCard(missions[i]),
    );
  }

  Widget _buildActiveMissionCard(_Mission m) {
    final step5 = _to5Step(m.stepIndex);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD6E6F2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF013973).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF013973).withValues(alpha: 0.04),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: _C.actionBlue,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text(
                    'ACTIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  m.id,
                  style: const TextStyle(
                    color: _C.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: m.priority == 'CRITICAL'
                        ? _C.critical.withValues(alpha: 0.1)
                        : _C.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    m.priority,
                    style: TextStyle(
                      color: m.priority == 'CRITICAL'
                          ? _C.critical
                          : _C.warning,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── Mission Info ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.title,
                  style: const TextStyle(
                    color: Color(0xFF013973),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: _C.textMuted, size: 13),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        m.location,
                        style: const TextStyle(
                            color: _C.textSecondary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _metricChip(Icons.people_rounded,
                        '${m.trapped} Trapped', _C.navy),
                    _metricChip(Icons.child_care_rounded,
                        '${m.childrenCount} Children', _C.govBlue),
                    _metricChip(Icons.elderly_rounded,
                        '${m.elderlyCount} Elderly', _C.warning),
                    if (m.medicalCount > 0)
                      _metricChip(Icons.medical_services_rounded,
                          '${m.medicalCount} Medical', _C.critical),
                  ],
                ),
              ],
            ),
          ),
          // ── Lifecycle Tracker ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MISSION LIFECYCLE',
                  style: TextStyle(
                    color: _C.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                _buildMissionLifecycleStepper(step5),
                const SizedBox(height: 6),
                // Timestamp row
                _buildTimestampRow(m),
              ],
            ),
          ),
          // ── Action Buttons ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(
              children: [
                // Top row: advance + details
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: step5 < 4
                            ? () => _advanceActiveMission(m)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF15945C),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              const Color(0xFF15945C).withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          minimumSize: const Size(0, 44),
                        ),
                        icon: Icon(
                          step5 == 3
                              ? Icons.check_circle_rounded
                              : Icons.arrow_forward_rounded,
                          size: 18,
                        ),
                        label: Text(
                          _fiveStepButtonLabel(step5),
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _openMissionDetailSheet(m),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _C.govBlue,
                        side: const BorderSide(color: _C.govBlue, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 12),
                        minimumSize: const Size(0, 44),
                      ),
                      icon: const Icon(Icons.info_outline_rounded,
                          color: _C.govBlue, size: 16),
                      label: const Text(
                        'Details',
                        style: TextStyle(
                            color: _C.govBlue,
                            fontWeight: FontWeight.w800,
                            fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Bottom row: Get Route + Navigate
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showRouteMapSheet(m),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF7C3AED),
                          side: const BorderSide(
                              color: Color(0xFF7C3AED), width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          minimumSize: const Size(0, 44),
                        ),
                        icon: const Icon(Icons.route_rounded,
                            color: Color(0xFF7C3AED), size: 18),
                        label: const Text(
                          'Get Route',
                          style: TextStyle(
                              color: Color(0xFF7C3AED),
                              fontWeight: FontWeight.w800,
                              fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showRouteMapSheet(m, navigate: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _C.actionBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          minimumSize: const Size(0, 44),
                        ),
                        icon: const Icon(Icons.navigation_rounded, size: 18),
                        label: const Text(
                          'Navigate',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Timestamp row under stepper ─────────────────────────────────────────
  Widget _buildTimestampRow(_Mission m) {
    final ts = m.stepTimestamps;
    final labels = <String>[
      'Assigned: ${ts[0] ?? '--:--'}',
      'Accepted: ${ts[1] ?? '--:--'}',
      'En Route: ${ts[3] ?? '--:--'}',
      'Reached: ${ts[4] ?? '--:--'}',
      'Done: ${ts[7] ?? '--:--'}',
    ];
    return Row(
      children: labels.asMap().entries.map((e) {
        final active = _to5Step(m.stepIndex) >= e.key;
        return Expanded(
          child: Text(
            e.value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? const Color(0xFF15945C) : _C.textMuted,
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Route / Navigate Map Bottom Sheet ───────────────────────────────────
  void _showRouteMapSheet(_Mission m, {bool navigate = false}) {
    // Parse coordinates: "25.4678° N, 91.7539° E" → LatLng
    LatLng? destLatLng;
    try {
      final coordStr = m.coordinates
          .replaceAll('°', '')
          .replaceAll('N', '')
          .replaceAll('S', '')
          .replaceAll('E', '')
          .replaceAll('W', '');
      final parts = coordStr.split(',');
      destLatLng = LatLng(
        double.parse(parts[0].trim()),
        double.parse(parts[1].trim()),
      );
    } catch (_) {
      destLatLng = const LatLng(25.4678, 91.7539);
    }
    // Current responder position (slightly offset for demo)
    final myLatLng = LatLng(
        destLatLng.latitude - 0.018, destLatLng.longitude - 0.022);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RouteMapSheet(
        mission: m,
        myLocation: myLatLng,
        destination: destLatLng!,
        navigateMode: navigate,
      ),
    );
  }

  // ── PENDING VIEW — Assigned but not accepted ─────────────────────────────
  Widget _buildPendingView(List<_Mission> missions) {
    if (missions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.assignment_rounded,
        message: 'No pending assignments',
        sub: 'All assignments have been accepted',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: missions.length,
      itemBuilder: (_, i) => _buildPendingMissionCard(missions[i]),
    );
  }

  Widget _buildPendingMissionCard(_Mission m) {
    final assignedAt = m.stepTimestamps[0] ?? '--:--';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.warning.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _C.warning.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _C.warning.withValues(alpha: 0.07),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: _C.warning,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text(
                    'AWAITING ACCEPT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  m.id,
                  style: const TextStyle(
                    color: _C.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 13, color: _C.textMuted),
                    const SizedBox(width: 3),
                    Text(
                      'Assigned $assignedAt',
                      style: const TextStyle(
                          color: _C.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ── Mission Info ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.title,
                  style: const TextStyle(
                    color: _C.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: _C.textMuted, size: 13),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${m.location}  •  ${m.distance}  •  ETA ${m.eta}',
                        style: const TextStyle(
                            color: _C.textSecondary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Assigned by: ${m.assignedAuthority}',
                  style: const TextStyle(
                    color: _C.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _metricChip(Icons.people_rounded,
                        '${m.trapped} Trapped', _C.navy),
                    _metricChip(Icons.child_care_rounded,
                        '${m.childrenCount} Children', _C.govBlue),
                    _metricChip(Icons.elderly_rounded,
                        '${m.elderlyCount} Elderly', _C.warning),
                    if (m.medicalCount > 0)
                      _metricChip(Icons.medical_services_rounded,
                          '${m.medicalCount} Medical', _C.critical),
                  ],
                ),
                const SizedBox(height: 10),
                // Safe Route
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _C.safe.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: _C.safe.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_rounded,
                          color: _C.safe, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Safe Route: ${m.safeRouteSummary}',
                          style: const TextStyle(
                            color: _C.safe,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ── Lifecycle Preview (collapsed / locked) ───────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _C.pageBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_clock_rounded,
                      color: _C.textMuted, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Mission Lifecycle Tracker unlocks after you accept this assignment',
                      style: TextStyle(
                          color: _C.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── Accept / Decline / Navigate Buttons ──────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(
              children: [
                // Row 1: Accept (primary)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _acceptMission(m),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.safe,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.check_circle_rounded, size: 20),
                    label: const Text(
                      'Accept Mission',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Row 2: View Details + Navigate
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openMissionDetailSheet(m),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _C.govBlue,
                          side: const BorderSide(color: _C.govBlue, width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          minimumSize: const Size(0, 44),
                        ),
                        icon: const Icon(Icons.info_outline_rounded,
                            color: _C.govBlue, size: 16),
                        label: const Text(
                          'View Details',
                          style: TextStyle(
                              color: _C.govBlue,
                              fontWeight: FontWeight.w800,
                              fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showRouteMapSheet(m, navigate: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _C.actionBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          minimumSize: const Size(0, 44),
                        ),
                        icon: const Icon(Icons.navigation_rounded, size: 16),
                        label: const Text(
                          'Navigate',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── COMPLETED VIEW — Finished missions with timeline ─────────────────────
  Widget _buildCompletedView(List<_Mission> missions) {
    if (missions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.task_alt_rounded,
        message: 'No completed missions yet',
        sub: 'Completed missions will appear here with full timeline',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: missions.length,
      itemBuilder: (_, i) => _buildCompletedMissionCard(missions[i]),
    );
  }

  Widget _buildCompletedMissionCard(_Mission m) {
    final ts = m.stepTimestamps;
    final assignedAt = ts[0];
    final acceptedAt = ts[1];
    final enRouteAt = ts[3];
    final reachedAt = ts[4];
    final completedAt = ts[7];
    final isNewlyCompleted = m.id == _recentlyCompletedId;

    // Compute duration
    String duration = '';
    if (assignedAt != null && completedAt != null) {
      try {
        final start = _parseTime(assignedAt);
        final end = _parseTime(completedAt);
        final diff = end.difference(start);
        final h = diff.inHours;
        final min = diff.inMinutes.remainder(60);
        duration = h > 0 ? '${h}h ${min}m' : '${min}m';
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isNewlyCompleted
              ? _C.safe
              : const Color(0xFFE2E8F0),
          width: isNewlyCompleted ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _C.safe.withValues(alpha: isNewlyCompleted ? 0.12 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _C.safe.withValues(alpha: 0.07),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: _C.safe,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text(
                    'COMPLETED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  m.id,
                  style: const TextStyle(
                    color: _C.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (isNewlyCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: _C.safe,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.new_releases_rounded,
                            color: Colors.white, size: 11),
                        SizedBox(width: 3),
                        Text(
                          'JUST COMPLETED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (duration.isNotEmpty)
                  Text(
                    'Duration: $duration',
                    style: const TextStyle(
                      color: _C.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          // ── Mission Title & Location ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.title,
                  style: const TextStyle(
                    color: _C.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: _C.textMuted, size: 13),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        m.location,
                        style: const TextStyle(
                            color: _C.textSecondary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _metricChip(Icons.people_rounded,
                        '${m.evacuated} Evacuated', _C.safe),
                    _metricChip(Icons.people_outline_rounded,
                        '${m.trapped} Rescued', _C.govBlue),
                    if (m.medicalCount > 0)
                      _metricChip(Icons.medical_services_rounded,
                          '${m.medicalCount} Medical', _C.critical),
                  ],
                ),
              ],
            ),
          ),
          // ── Full Timeline ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MISSION TIMELINE',
                  style: TextStyle(
                    color: _C.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                _buildTimelineRow(
                    Icons.assignment_ind_rounded,
                    'Assigned',
                    assignedAt ?? '--:--',
                    'Assigned by authority',
                    _C.govBlue,
                    true),
                _buildTimelineRow(
                    Icons.check_circle_rounded,
                    'Accepted',
                    acceptedAt ?? '--:--',
                    'Mission accepted by responder',
                    _C.safe,
                    acceptedAt != null),
                _buildTimelineRow(
                    Icons.directions_car_rounded,
                    'En Route',
                    enRouteAt ?? '--:--',
                    'Departed for rescue site',
                    _C.actionBlue,
                    enRouteAt != null),
                _buildTimelineRow(
                    Icons.flag_rounded,
                    'Reached Site',
                    reachedAt ?? '--:--',
                    'Arrived at incident location',
                    const Color(0xFF7C3AED),
                    reachedAt != null),
                _buildTimelineRow(
                    Icons.task_alt_rounded,
                    'Completed',
                    completedAt ?? '--:--',
                    duration.isNotEmpty
                        ? 'Total duration: $duration'
                        : 'Mission completed',
                    _C.safe,
                    completedAt != null,
                    isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  // ── Single timeline event row ─────────────────────────────────────────────
  Widget _buildTimelineRow(
    IconData icon,
    String label,
    String time,
    String subLabel,
    Color color,
    bool completed, {
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: completed
                        ? color.withValues(alpha: 0.12)
                        : _C.pageBg,
                    border: Border.all(
                      color: completed ? color : const Color(0xFFCBD5E1),
                      width: completed ? 2 : 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 14,
                    color: completed ? color : _C.textMuted,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: completed
                          ? color.withValues(alpha: 0.3)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: completed ? _C.textPrimary : _C.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        time,
                        style: TextStyle(
                          color: completed ? color : _C.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subLabel,
                    style: const TextStyle(
                        color: _C.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty state helper ───────────────────────────────────────────────────
  Widget _buildEmptyState(
      {required IconData icon,
      required String message,
      required String sub}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: _C.textMuted),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                color: _C.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              sub,
              style: const TextStyle(color: _C.textMuted, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Parse time string "HH:mm" to DateTime ────────────────────────────────
  DateTime _parseTime(String t) {
    final parts = t.split(':');
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day,
        int.parse(parts[0]), int.parse(parts[1]));
  }

  Widget _buildMissionCard(_Mission m) {
    final isSelected = m.id == _activeMission.id;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeMissionIdx = _missions.indexOf(m);
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? _C.actionBlue : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? _C.actionBlue.withValues(alpha: 0.08)
                  : const Color(0xFFF8FAFC),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: m.priority == 'CRITICAL' ? _C.critical : _C.warning,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    m.priority,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  m.id,
                  style: const TextStyle(
                    color: _C.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  _kMissionLifecycle[m.stepIndex],
                  style: TextStyle(
                    color: m.stepIndex == 7 ? _C.safe : _C.actionBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.title,
                  style: const TextStyle(
                    color: _C.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: _C.textMuted, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        m.location,
                        style: const TextStyle(
                            color: _C.textSecondary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Population Demographics Chips
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _metricChip(
                        Icons.people_rounded, '${m.trapped} Trapped', _C.navy),
                    _metricChip(Icons.child_care_rounded,
                        '${m.childrenCount} Children', _C.govBlue),
                    _metricChip(Icons.elderly_rounded,
                        '${m.elderlyCount} Elderly', _C.warning),
                    if (m.medicalCount > 0)
                      _metricChip(Icons.medical_services_rounded,
                          '${m.medicalCount} Medical', _C.critical),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Safe Route: ${m.safeRouteSummary}',
                  style: const TextStyle(
                    color: _C.safe,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _openMissionDetailSheet(m),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _C.govBlue,
                          side: const BorderSide(color: _C.govBlue),
                          minimumSize: const Size(0, 42),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                        ),
                        child: const Text('View Details',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _activeMissionIdx = _missions.indexOf(m);
                            _tab = 0; // go to map
                          });
                          _openSafeNavigationSheet(m);
                        },
                        icon: const Icon(Icons.navigation_rounded, size: 14),
                        label: const Text('Navigate',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _C.actionBlue,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 42),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  }

  Widget _metricChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 2 — SOS DESK (OPERATIONAL INBOX)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSOSDeskTab() {
    final criticalCount = _sosList.where((s) => s.priority == 'CRITICAL').length;
    final highCount = _sosList.where((s) => s.priority == 'HIGH').length;
    final normalCount = _sosList.where((s) => s.priority == 'NORMAL').length;

    final filtered = _sosList.where((s) {
      if (_sosFilter == 'Critical') return s.priority == 'CRITICAL';
      if (_sosFilter == 'Unassigned') return !s.assigned;
      if (_sosFilter == 'Assigned') return s.assigned;
      return true;
    }).toList();

    return Column(
      children: [
        _buildSectionHeader(
          title: 'SOS Operational Inbox',
          icon: Icons.sos_rounded,
          subtitle: 'Distress calls prioritized for field action',
        ),
        // Top Counters
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              _sosCounterCard('Critical', '$criticalCount', _C.critical),
              const SizedBox(width: 8),
              _sosCounterCard('High', '$highCount', _C.warning),
              const SizedBox(width: 8),
              _sosCounterCard('Normal', '$normalCount', _C.govBlue),
            ],
          ),
        ),
        // Filter row
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Critical', 'Nearby', 'Unassigned', 'Assigned']
                  .map((f) {
                final active = _sosFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: active,
                    onSelected: (val) {
                      if (val) setState(() => _sosFilter = f);
                    },
                    selectedColor: _C.navy,
                    backgroundColor: _C.pageBg,
                    labelStyle: TextStyle(
                      color: active ? Colors.white : _C.textSecondary,
                      fontSize: 11,
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: filtered.length,
            itemBuilder: (context, idx) {
              final item = filtered[idx];
              return _buildSOSCard(item);
            },
          ),
        ),
      ],
    );
  }

  Widget _sosCounterCard(String label, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSOSCard(_SOSAlert s) {
    final isCrit = s.priority == 'CRITICAL';
    final cardColor = isCrit ? _C.critical : _C.warning;

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, child) {
        return Transform.scale(
          scale: isCrit && !s.acknowledged ? _pulseAnim.value : 1.0,
          child: child,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: s.acknowledged ? const Color(0xFFCBD5E1) : cardColor,
            width: s.acknowledged ? 1 : 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      s.priority,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    s.id,
                    style: const TextStyle(
                      color: _C.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    s.receivedTime,
                    style:
                        const TextStyle(color: _C.textMuted, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                s.callerName,
                style: const TextStyle(
                  color: _C.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                s.emergencyType,
                style: TextStyle(
                  color: isCrit ? _C.critical : _C.govBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded,
                      color: _C.textMuted, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${s.location} (${s.distance})',
                      style: const TextStyle(
                          color: _C.textSecondary, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: [
                  _metricChip(Icons.people_rounded, '${s.peopleCount} people',
                      _C.navy),
                  if (s.hasElderly)
                    _metricChip(Icons.elderly_rounded, 'Elderly', _C.warning),
                  if (s.hasChildren)
                    _metricChip(
                        Icons.child_care_rounded, 'Children', _C.govBlue),
                  if (s.hasMedical)
                    _metricChip(Icons.medical_services_rounded, 'Medical Case',
                        _C.critical),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() => s.acknowledged = true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: _C.safe,
                            content: Text(
                                'SOS ${s.id} acknowledged by SDRF Bravo'),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _C.safe,
                        side: const BorderSide(color: _C.safe),
                        minimumSize: const Size(0, 40),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                      ),
                      child: Text(
                        s.acknowledged ? 'Acknowledged' : 'Accept SOS',
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Capacity check: if already on a critical mission
                        if (_activeMission.stepIndex > 0 &&
                            _activeMission.stepIndex < 7 &&
                            !s.assigned) {
                          _showCapacityGuardDialog(s);
                        } else {
                          setState(() {
                            s.assigned = true;
                            _tab = 0;
                          });
                        }
                      },
                      icon: const Icon(Icons.navigation_rounded, size: 14),
                      label: const Text('Navigate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.actionBlue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 40),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCapacityGuardDialog(_SOSAlert s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: _C.warning),
            SizedBox(width: 8),
            Text(
              'Team Capacity Guard',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Your team is currently engaged in Critical Mission ${_activeMission.id} (${_activeMission.trapped} trapped). Accepting an additional critical operation may exceed team capability.',
          style: const TextStyle(fontSize: 13, color: _C.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: _C.govBlue,
                  content: Text(
                      'SOS ${s.id} forwarded to nearest available unit SDRF Delta'),
                ),
              );
            },
            child: const Text('Forward to Unit Delta'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                s.assigned = true;
                _tab = 0;
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: _C.critical),
            child: const Text('Add to Queue'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 3 — ASSETS & EQUIPMENT INVENTORY
  // ═══════════════════════════════════════════════════════════════════════════
  // ─────────────────── ASSETS TAB HELPERS ────────────────────────────────────
  Color _assetStatusColor(_AssetItem a) {
    switch (a.status) {
      case 'Available':
        return const Color(0xFF16A34A);
      case 'In Use':
        return const Color(0xFF2563EB);
      case 'Assigned':
        return const Color(0xFF2563EB);
      case 'Low Stock':
        return const Color(0xFFD97706);
      case 'Maintenance':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFFDC2626);
    }
  }

  Widget _buildAssetsTab() {
    // ── Counts by status ──────────────────────────────────────────────────────
    final total = _assetsList.length;
    final readyCount =
        _assetsList.where((a) => a.status == 'Available').length;
    final inUseCount = _assetsList
        .where((a) => a.status == 'In Use' || a.status == 'Assigned')
        .length;
    final lowCount = _assetsList.where((a) => a.status == 'Low Stock').length;
    final maintCount =
        _assetsList.where((a) => a.status == 'Maintenance').length;

    // ── Filter + Search ───────────────────────────────────────────────────────
    final filtered = _assetsList.where((a) {
      final matchFilter = () {
        switch (_assetFilter) {
          case 'Ready':
            return a.status == 'Available';
          case 'In Use':
            return a.status == 'In Use' || a.status == 'Assigned';
          case 'Low':
            return a.status == 'Low Stock';
          case 'Maintenance':
            return a.status == 'Maintenance';
          default:
            return true;
        }
      }();
      final q = _assetSearch.toLowerCase();
      final matchSearch = q.isEmpty ||
          a.name.toLowerCase().contains(q) ||
          a.code.toLowerCase().contains(q) ||
          a.tags.any((t) => t.toLowerCase().contains(q));
      return matchFilter && matchSearch;
    }).toList();

    // ── Filter Chips data ─────────────────────────────────────────────────────
    final chips = [
      {'label': 'All ($total)', 'key': 'All', 'dot': const Color(0xFF0B2341)},
      {
        'label': 'Ready ($readyCount)',
        'key': 'Ready',
        'dot': const Color(0xFF16A34A)
      },
      {
        'label': 'In Use ($inUseCount)',
        'key': 'In Use',
        'dot': const Color(0xFF2563EB)
      },
      {
        'label': 'Low ($lowCount)',
        'key': 'Low',
        'dot': const Color(0xFFD97706)
      },
      {
        'label': 'Maintenance ($maintCount)',
        'key': 'Maintenance',
        'dot': const Color(0xFF64748B)
      },
    ];

    return Column(
      children: [
        // ── Dark blue header ────────────────────────────────────────────────
        Container(
          color: const Color(0xFF0B2341),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.inventory_2_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Team Equipment & Assets',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Operational gear assigned to SDRF Bravo',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // + Add Asset button
              GestureDetector(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Add asset – coming soon')),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: _C.actionBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text('Add Asset',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.more_vert_rounded,
                  color: Colors.white54, size: 20),
            ],
          ),
        ),

        // ── Filter chips row ────────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: chips.map((chip) {
                final key = chip['key'] as String;
                final selected = _assetFilter == key;
                final dot = chip['dot'] as Color;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _assetFilter = key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected ? _C.actionBlue : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? _C.actionBlue
                              : const Color(0xFFE2E8F0),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!selected)
                            Padding(
                              padding: const EdgeInsets.only(right: 5),
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                    color: dot, shape: BoxShape.circle),
                              ),
                            ),
                          Text(
                            chip['label'] as String,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : _C.textPrimary,
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),

        // ── Search + view toggle ────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F7FA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _assetSearch = v),
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF172033)),
                    decoration: const InputDecoration(
                      hintText: 'Search equipment, code or type...',
                      hintStyle: TextStyle(
                          color: Color(0xFF94A3B8), fontSize: 13),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: Color(0xFF94A3B8), size: 18),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // List / Grid toggle
              _buildViewToggleBtn(
                icon: Icons.list_rounded,
                active: !_assetGridView,
                onTap: () => setState(() => _assetGridView = false),
              ),
              const SizedBox(width: 4),
              _buildViewToggleBtn(
                icon: Icons.grid_view_rounded,
                active: _assetGridView,
                onTap: () => setState(() => _assetGridView = true),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),

        // ── Asset list / grid ───────────────────────────────────────────────
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(12),
            children: [
              // ── Shelter Camps Quick Access Banner ──────────────────────────
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CitizenSheltersView(isResponder: true),
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF005EA8), Color(0xFF0B2341)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF005EA8).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(Icons.night_shelter_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Nearby Shelter Camps',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${IncidentCoordinator.instance.shelters.where((s) => s.status.toUpperCase() == "OPEN" || s.available > 0).length} open camps with food, water & medical',
                              style: const TextStyle(
                                color: Color(0xFF93C5FD),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
                    ],
                  ),
                ),
              ),

              // ── Asset list or grid ──────────────────────────────────────────
              if (_assetGridView)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _buildAssetGridCard(filtered[i]),
                )
              else
                ...filtered.map((asset) => _buildAssetCard(asset)).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildViewToggleBtn({
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: active ? _C.navy : const Color(0xFFF4F7FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: active ? _C.navy : const Color(0xFFE2E8F0)),
        ),
        child: Icon(icon,
            color: active ? Colors.white : _C.textSecondary, size: 18),
      ),
    );
  }

  Widget _buildAssetCard(_AssetItem a) {
    final statusColor = _assetStatusColor(a);
    final isLow = a.status == 'Low Stock';
    final isMaint = a.status == 'Maintenance';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLow
              ? const Color(0xFFD97706).withValues(alpha: 0.25)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── 1. Icon ────────────────────────────────────────────────────────
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: a.iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(a.icon, color: a.iconColor, size: 26),
          ),
          const SizedBox(width: 12),

          // ── 2. Name + Code/Qty + Tags (Left) ──────────────────────────────
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  a.name,
                  style: const TextStyle(
                    color: Color(0xFF172033),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  'Code: ${a.code}  |  Qty: ${a.quantity} ${a.unit}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 5,
                  runSpacing: 4,
                  children: a.tags
                      .map((tag) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                color: Color(0xFF2563EB),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // ── 3. Status Badge + Location/Assigned (Center) ──────────────────
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: isMaint
                        ? const Color(0xFFF1F5F9)
                        : statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                            color: statusColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          a.status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                // Location / Assigned label
                Text(
                  a.locationLabel,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // Assigned / Location value
                Text(
                  a.assignedTo,
                  style: const TextStyle(
                    color: Color(0xFF172033),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // ── 4. 3-Dot (top) + Manage Button (bottom) (Far Right) ───────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => _showAssetActionDialog(a),
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.only(top: 2, right: 2),
                  child: Icon(
                    Icons.more_vert_rounded,
                    size: 20,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => _showAssetActionDialog(a),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFBFDBFE),
                      width: 1.2,
                    ),
                  ),
                  child: const Text(
                    'Manage',
                    style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssetGridCard(_AssetItem a) {
    final statusColor = _assetStatusColor(a);
    return GestureDetector(
      onTap: () => _showAssetActionDialog(a),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: a.iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(a.icon, color: a.iconColor, size: 20),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    a.status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              a.name,
              style: const TextStyle(
                color: Color(0xFF172033),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '${a.quantity} ${a.unit}  •  ${a.code}',
              style: const TextStyle(
                  color: Color(0xFF94A3B8), fontSize: 10),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    a.assignedTo,
                    style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFF94A3B8), size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAssetActionDialog(_AssetItem a) {
    final statusColor = _assetStatusColor(a);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Asset header
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: a.iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(a.icon, color: a.iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF172033),
                        ),
                      ),
                      Text(
                        'Code: ${a.code}  •  ${a.quantity} ${a.unit}',
                        style: const TextStyle(
                            color: Color(0xFF64748B), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    a.status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFE2E8F0)),
            const SizedBox(height: 8),
            _assetAction(
              icon: Icons.assignment_turned_in_rounded,
              color: _C.safe,
              label: 'Mark as Available / Ready',
              onTap: () {
                setState(() => a.status = 'Available');
                Navigator.pop(ctx);
              },
            ),
            _assetAction(
              icon: Icons.play_circle_filled_rounded,
              color: _C.actionBlue,
              label: 'Assign to Active Mission',
              onTap: () {
                setState(() => a.status = 'In Use');
                Navigator.pop(ctx);
              },
            ),
            _assetAction(
              icon: Icons.report_problem_rounded,
              color: _C.warning,
              label: 'Report Low Stock / Issue',
              onTap: () {
                setState(() => a.status = 'Low Stock');
                Navigator.pop(ctx);
              },
            ),
            _assetAction(
              icon: Icons.build_rounded,
              color: const Color(0xFF64748B),
              label: 'Send to Maintenance',
              onTap: () {
                setState(() => a.status = 'Maintenance');
                Navigator.pop(ctx);
              },
            ),
            _assetAction(
              icon: Icons.cancel_rounded,
              color: _C.critical,
              label: 'Request Replacement from Base Camp',
              onTap: () {
                setState(() => a.status = 'Maintenance');
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: _C.critical,
                    content: Text(
                        'Replacement requested for ${a.name} from Base Camp'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _assetAction({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF172033),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFFCBD5E1), size: 20),
          ],
        ),
      ),
    );
  }


  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 4 — PROFILE & TEAM IDENTITY
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildProfileTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildResponderIdentityCard(),
        const SizedBox(height: 14),
        _buildDutyToggleCard(),
        const SizedBox(height: 14),
        _buildReadinessChecklistWidget(),
        const SizedBox(height: 14),
        _buildTeamRosterCard(),
        const SizedBox(height: 14),
        _buildCommsAndOfflinePacksCard(),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: _C.navy,
                content: Text('Logged out of JalGuard Field Operations'),
              ),
            );
          },
          icon: const Icon(Icons.logout_rounded, size: 16),
          label: const Text('Sign Out of Field Duty'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _C.navy,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildResponderIdentityCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: _C.govBlue.withValues(alpha: 0.15),
            child: const Icon(Icons.person_rounded,
                color: _C.govBlue, size: 34),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inspector Arjun Mehta',
                  style: TextStyle(
                    color: _C.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Team Leader • SDRF Bravo Unit',
                  style: TextStyle(color: _C.textSecondary, fontSize: 12),
                ),
                Text(
                  'ID: RES-2247 • Sector 4, Mawphlang',
                  style: TextStyle(
                    color: _C.actionBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDutyToggleCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(
            _onDuty ? Icons.verified_user_rounded : Icons.shield_outlined,
            color: _onDuty ? _C.safe : _C.textMuted,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _onDuty ? 'ON DUTY (Active)' : 'OFF DUTY',
                  style: TextStyle(
                    color: _onDuty ? _C.safe : _C.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _onDuty
                      ? 'Receiving field alerts & authority assignments'
                      : 'Not receiving new dispatches',
                  style: const TextStyle(color: _C.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Switch(
            value: _onDuty,
            onChanged: (v) => setState(() => _onDuty = v),
            activeThumbColor: _C.safe,
            activeTrackColor: _C.safe.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildReadinessChecklistWidget() {
    final completed = _readinessChecklist.values.where((v) => v).length;
    final total = _readinessChecklist.length;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fact_check_rounded,
                  color: _C.govBlue, size: 18),
              const SizedBox(width: 8),
              const Text(
                'MISSION READINESS CHECKLIST',
                style: TextStyle(
                  color: _C.govBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                '$completed / $total',
                style: const TextStyle(
                  color: _C.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: completed / total,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation(
                  completed == total ? _C.safe : _C.warning),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 10),
          ..._readinessChecklist.entries.map((e) {
            return GestureDetector(
              onTap: () {
                setState(() => _readinessChecklist[e.key] = !e.value);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      e.value
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      color: e.value ? _C.safe : _C.textMuted,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        e.key,
                        style: TextStyle(
                          color: e.value ? _C.textPrimary : _C.textSecondary,
                          fontSize: 12,
                          fontWeight:
                              e.value ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTeamRosterCard() {
    final roster = [
      {'name': 'Vikram Singh', 'role': 'Medical Specialist / Paramedic', 'status': 'Ready'},
      {'name': 'Rahul Das', 'role': 'Boat Operator & Diver', 'status': 'Ready'},
      {'name': 'Pranay Gogoi', 'role': 'Comms & Drone Operator', 'status': 'On Recon'},
      {'name': 'Deepak Sharma', 'role': 'Rigging & Extraction Tech', 'status': 'Ready'},
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.groups_rounded, color: _C.navy, size: 18),
              SizedBox(width: 8),
              Text(
                'TEAM BRAVO ROSTER (4 Responders)',
                style: TextStyle(
                  color: _C.navy,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...roster.map((m) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: const Color(0xFFE2E8F0),
                    child: const Icon(Icons.person,
                        size: 16, color: _C.navy),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m['name']!,
                          style: const TextStyle(
                            color: _C.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          m['role']!,
                          style: const TextStyle(
                              color: _C.textSecondary, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _C.safe.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      m['status']!,
                      style: const TextStyle(
                        color: _C.safe,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCommsAndOfflinePacksCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.wifi_tethering_rounded, color: _C.navy, size: 18),
              SizedBox(width: 8),
              Text(
                'COMMUNICATIONS & MAP PACKS',
                style: TextStyle(
                  color: _C.navy,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _detailRow(
              'Radio Channel', 'VHF Tac-4 (156.800 MHz)', Icons.cell_tower_rounded),
          _detailRow('Control Room Direct', '+91 364 222-DEOC (Priority #1)',
              Icons.phone_in_talk_rounded),
          _detailRow('Offline Map Pack',
              'East Khasi Hills (42 MB) • Downloaded', Icons.download_done_rounded),
          _detailRow('Live Tracking', 'Active via GPS + SAT Relay',
              Icons.share_location_rounded),
        ],
      ),
    );
  }

  Widget _detailRow(String title, String val, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 15, color: _C.actionBlue),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  color: _C.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(val,
              style: const TextStyle(
                  color: _C.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 8 OPERATIONAL MODALS / SHEETS
  // ═══════════════════════════════════════════════════════════════════════════

  // ── 1. Mission Detail Workflow (Full 8-Step Lifecycle) ─────────────────────
  void _openMissionDetailSheet(_Mission m) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.90,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                // Modal Header
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  decoration: const BoxDecoration(
                    color: _C.navy,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'MISSION ${m.id}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: m.priority == 'CRITICAL'
                                      ? _C.critical
                                      : _C.warning,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  m.priority,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            m.incidentType,
                            style: const TextStyle(
                                color: Color(0xFF94A3B8), fontSize: 12),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white),
                      ),
                    ],
                  ),
                ),

                // Scrollable content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Sequential Lifecycle Tracker with Timestamps
                      _buildLifecycleStepperWidget(m),
                      const SizedBox(height: 16),

                      // Location & Coordinates
                      _buildSectionTitle('OPERATIONAL TARGET'),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.location,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: _C.textPrimary)),
                            Text('GPS: ${m.coordinates}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: _C.actionBlue,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('Distance: ${m.distance} • Estimated ETA: ${m.eta}',
                                style: const TextStyle(
                                    fontSize: 11, color: _C.textSecondary)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Demographics Breakdown
                      _buildSectionTitle('TRAPPED POPULATION DEMOGRAPHICS'),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _statColumn('Trapped', '${m.trapped}', _C.critical),
                            _statColumn(
                                'Children', '${m.childrenCount}', _C.govBlue),
                            _statColumn(
                                'Elderly', '${m.elderlyCount}', _C.warning),
                            _statColumn('Injured', '${m.medicalCount}', _C.safe),
                            _statColumn(
                                'Disabled', '${m.disabledCount}', _C.navy),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Ground Hazards
                      _buildSectionTitle('GROUND HAZARD TELEMETRY'),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            _hazardRow('Flood Water Depth', m.floodDepth,
                                Icons.water_rounded),
                            _hazardRow('Water Current Velocity', m.waterFlow,
                                Icons.waves_rounded),
                            _hazardRow('Landslide Risk', m.landslideRisk,
                                Icons.terrain_rounded),
                            _hazardRow('Access Route Condition',
                                m.roadBridgeCondition, Icons.alt_route_rounded),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Required Equipment
                      _buildSectionTitle('REQUIRED TACTICAL EQUIPMENT'),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: m.requiredEquipment.map((eq) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                              border:
                                  Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    size: 14, color: _C.govBlue),
                                const SizedBox(width: 6),
                                Text(eq,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: _C.navy,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      // Recommended Safe Evacuation Destination
                      _buildSectionTitle('RECOMMENDED EVACUATION DESTINATION'),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _C.safe.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: _C.safe.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.domain_rounded,
                                color: _C.safe, size: 24),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m.recommendedShelter,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _C.safe),
                                  ),
                                  const Text(
                                    'Medical Trauma Cases -> District Civil Hospital',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: _C.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Sequential Step Action Button
                      _buildSequentialActionButton(m, () {
                        _advanceMissionLifecycle();
                        setSheetState(() {});
                      }),
                      const SizedBox(height: 10),

                      // Secondary Operational Actions
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _openRequestBackupSheet();
                              },
                              icon: const Icon(Icons.support_agent_rounded,
                                  size: 14),
                              label: const Text('Request Backup'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _C.critical,
                                side: const BorderSide(color: _C.critical),
                                minimumSize: const Size(0, 44),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _openRescueStatusSheet(m);
                              },
                              icon: const Icon(Icons.edit_note_rounded,
                                  size: 14),
                              label: const Text('Update Counts'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _C.govBlue,
                                side: const BorderSide(color: _C.govBlue),
                                minimumSize: const Size(0, 44),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          color: _C.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _statColumn(String label, String val, Color color) {
    return Column(
      children: [
        Text(val,
            style: TextStyle(
                color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: _C.textSecondary, fontSize: 10)),
      ],
    );
  }

  Widget _hazardRow(String label, String val, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: _C.actionBlue),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(color: _C.textSecondary, fontSize: 11)),
          const Spacer(),
          Text(val,
              style: const TextStyle(
                  color: _C.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildLifecycleStepperWidget(_Mission m) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('CURRENT LIFECYCLE STAGE',
                  style: TextStyle(
                      color: _C.navy,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(
                'Stage ${m.stepIndex + 1} of 8',
                style: const TextStyle(color: _C.textMuted, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_kMissionLifecycle.length, (i) {
                final isDone = m.stepIndex > i;
                final isCurrent = m.stepIndex == i;
                final time = m.stepTimestamps[i];

                return Row(
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDone
                                ? _C.safe
                                : (isCurrent ? _C.actionBlue : Colors.white),
                            border: Border.all(
                              color: isDone || isCurrent
                                  ? Colors.transparent
                                  : const Color(0xFFCBD5E1),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: isDone
                                ? const Icon(Icons.check,
                                    size: 13, color: Colors.white)
                                : Text(
                                    '${i + 1}',
                                    style: TextStyle(
                                      color: isCurrent
                                          ? Colors.white
                                          : _C.textMuted,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _kMissionLifecycle[i],
                          style: TextStyle(
                            color: isCurrent ? _C.navy : _C.textSecondary,
                            fontSize: 9,
                            fontWeight:
                                isCurrent ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if (time != null)
                          Text(
                            time,
                            style: const TextStyle(
                                color: _C.safe, fontSize: 8),
                          ),
                      ],
                    ),
                    if (i < _kMissionLifecycle.length - 1)
                      Container(
                        width: 20,
                        height: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        color: isDone ? _C.safe : const Color(0xFFCBD5E1),
                      ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSequentialActionButton(_Mission m, VoidCallback onAdvance) {
    String label;
    IconData icon;
    Color btnColor;

    switch (m.stepIndex) {
      case 0:
        label = 'Accept Mission';
        icon = Icons.assignment_turned_in_rounded;
        btnColor = _C.actionBlue;
        break;
      case 1:
        label = 'Mark Ready (Checklist Complete)';
        icon = Icons.checklist_rounded;
        btnColor = _C.govBlue;
        break;
      case 2:
        label = 'Start Navigation';
        icon = Icons.navigation_rounded;
        btnColor = _C.actionBlue;
        break;
      case 3:
        label = 'I Have Arrived (On Site)';
        icon = Icons.place_rounded;
        btnColor = _C.warning;
        break;
      case 4:
        label = 'Start Rescue Operation';
        icon = Icons.crisis_alert_rounded;
        btnColor = _C.critical;
        break;
      case 5:
        label = 'Start Transporting to Relief Destination';
        icon = Icons.directions_boat_rounded;
        btnColor = _C.govBlue;
        break;
      case 6:
        label = 'Complete Mission & Notify Authority';
        icon = Icons.check_circle_rounded;
        btnColor = _C.safe;
        break;
      default:
        label = 'Mission Completed';
        icon = Icons.verified_rounded;
        btnColor = _C.safe;
    }

    return ElevatedButton.icon(
      onPressed: m.stepIndex < 7 ? onAdvance : null,
      icon: Icon(icon, size: 18),
      label: Text(label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: btnColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ── 2. Safe Navigation Screen / Sheet ──────────────────────────────────────
  void _openSafeNavigationSheet(_Mission m) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: _C.navy,
              child: Row(
                children: [
                  const Icon(Icons.navigation_rounded,
                      color: _C.actionBlue, size: 22),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Safe Navigation Dispatch',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Optimized for Passable Roads & High Ground',
                        style:
                            TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon:
                        const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
            // Dynamic Route Hazard Alert Banner
            Container(
              width: double.infinity,
              color: const Color(0xFFFEF3C7),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.warning_rounded,
                      color: _C.warning, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Route changed — Eastern bridge blocked. Recommended route via West Ridge Bypass.',
                      style: TextStyle(
                          color: _C.warning,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Distance & ETA Panel
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(m.distance,
                                style: const TextStyle(
                                    color: _C.navy,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold)),
                            const Text('Distance',
                                style: TextStyle(
                                    color: _C.textSecondary, fontSize: 11)),
                          ],
                        ),
                        Container(
                            width: 1,
                            height: 36,
                            color: const Color(0xFFCBD5E1)),
                        Column(
                          children: [
                            Text(m.eta,
                                style: const TextStyle(
                                    color: _C.actionBlue,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold)),
                            const Text('Estimated ETA',
                                style: TextStyle(
                                    color: _C.textSecondary, fontSize: 11)),
                          ],
                        ),
                        Container(
                            width: 1,
                            height: 36,
                            color: const Color(0xFFCBD5E1)),
                        const Column(
                          children: [
                            Text('SAFE',
                                style: TextStyle(
                                    color: _C.safe,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold)),
                            Text('Route Security',
                                style: TextStyle(
                                    color: _C.textSecondary, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionTitle('WAYPOINT DIRECTIONS (SAFETY FIRST)'),
                  _waypointStep(1, 'Depart Base Camp Sector 4',
                      'High clearance path clear', Icons.trip_origin_rounded),
                  _waypointStep(
                      2,
                      'Turn right at Mawphlang Ridge road',
                      'Avoid lower canal embankment (submerged)',
                      Icons.turn_right_rounded),
                  _waypointStep(
                      3,
                      'Cross West Culvert #2 (Safe • 10cm clearance)',
                      'Bridge structural sensor verified: OK',
                      Icons.alt_route_rounded),
                  _waypointStep(
                      4,
                      'Arrive at Target Zone: Lower Catchment',
                      'Coordinates: 25.4678° N, 91.7539° E',
                      Icons.flag_rounded),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      _advanceMissionLifecycle();
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text('I Have Arrived (On Site)',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.safe,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _waypointStep(
      int num, String title, String sub, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: _C.actionBlue.withValues(alpha: 0.15),
            child: Text('$num',
                style: const TextStyle(
                    color: _C.actionBlue,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _C.textPrimary)),
                Text(sub,
                    style: const TextStyle(
                        fontSize: 11, color: _C.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. Rescue Status Screen / Sheet (Interactive Headcounts) ───────────────
  void _openRescueStatusSheet(_Mission m) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setRescueState) {
          final progress =
              (m.evacuated / (m.trapped > 0 ? m.trapped : 1)).clamp(0.0, 1.0);

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: _C.navy,
                  child: Row(
                    children: [
                      const Icon(Icons.people_alt_rounded,
                          color: _C.safe, size: 22),
                      const SizedBox(width: 8),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Operational Rescue Counts',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Field count synced live to Authority Dashboard',
                            style: TextStyle(
                                color: Color(0xFF94A3B8), fontSize: 11),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Evacuation Progress Bar
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('EVACUATION PROGRESS',
                                    style: TextStyle(
                                        color: _C.navy,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                                Text(
                                  '${(progress * 100).toInt()}% Rescued (${m.evacuated}/${m.trapped})',
                                  style: const TextStyle(
                                      color: _C.safe,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: const Color(0xFFE2E8F0),
                                valueColor:
                                    const AlwaysStoppedAnimation(_C.safe),
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Large Step Counters
                      _countAdjuster('People Located & Secured', m.trapped,
                          _C.navy, (delta) {
                        setRescueState(() {
                          m.trapped = (m.trapped + delta).clamp(0, 100);
                        });
                      }),
                      _countAdjuster('Evacuated / Rescued', m.evacuated,
                          _C.safe, (delta) {
                        setRescueState(() {
                          m.evacuated = (m.evacuated + delta).clamp(0, 100);
                        });
                      }),
                      _countAdjuster(
                          'Need Immediate Medical', m.medicalCount, _C.critical,
                          (delta) {
                        setRescueState(() {
                          m.medicalCount =
                              (m.medicalCount + delta).clamp(0, 100);
                        });
                      }),
                      _countAdjuster('Missing / Unaccounted', m.missingCount,
                          _C.warning, (delta) {
                        setRescueState(() {
                          m.missingCount =
                              (m.missingCount + delta).clamp(0, 100);
                        });
                      }),
                      const SizedBox(height: 16),

                      // Destination Recommendation Card
                      _buildSectionTitle('DESTINATION RECOMMENDATION'),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: m.medicalCount > 0
                              ? _C.critical.withValues(alpha: 0.08)
                              : _C.safe.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: m.medicalCount > 0
                                ? _C.critical.withValues(alpha: 0.3)
                                : _C.safe.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              m.medicalCount > 0
                                  ? Icons.local_hospital_rounded
                                  : Icons.domain_rounded,
                              color: m.medicalCount > 0
                                  ? _C.critical
                                  : _C.safe,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m.medicalCount > 0
                                        ? 'Recommended Destination: District Hospital'
                                        : 'Recommended Destination: Relief Centre #2',
                                    style: TextStyle(
                                      color: m.medicalCount > 0
                                          ? _C.critical
                                          : _C.safe,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    m.medicalCount > 0
                                        ? '${m.medicalCount} patients need trauma care • 14 beds open • 2.4 km via safe road'
                                        : '38 spaces available • Food/Water ready • 1.6 km via West Bypass',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: _C.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      ElevatedButton(
                        onPressed: () {
                          final cleanId = m.id.replaceAll('#', '');
                          IncidentCoordinator.instance.updateRescueProgress(
                            cleanId.startsWith('RS') ? cleanId : 'RS-204',
                            rescued: m.evacuated,
                            trapped: m.trapped,
                            medical: m.medicalCount,
                          );
                          if (m.evacuated > 0) {
                            IncidentCoordinator.instance.transportToShelter(
                              missionId:
                                  cleanId.startsWith('RS') ? cleanId : 'RS-204',
                              shelterId: 'SH-01',
                              evacueeCount: m.evacuated,
                            );
                          }
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: _C.safe,
                              content: Text(
                                  'Rescue count & shelter update transmitted to Authority Dashboard'),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _C.actionBlue,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Update & Transmit Counts',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _countAdjuster(
      String label, int val, Color color, ValueChanged<int> onDelta) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: _C.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => onDelta(-1),
            icon: const Icon(Icons.remove_circle_outline_rounded,
                color: _C.textSecondary, size: 24),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$val',
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => onDelta(1),
            icon: const Icon(Icons.add_circle_outline_rounded,
                color: _C.actionBlue, size: 24),
          ),
        ],
      ),
    );
  }

  // ── 4. Report Hazard Sheet (Fast Field Actions) ────────────────────────────
  void _openReportHazardSheet() {
    String selectedType = 'Flooded Road';

    final hazardItems = [
      {
        'title': 'Flooded Road',
        'icon': Icons.waves_rounded,
        'color': const Color(0xFF0284C7),
        'bgColor': const Color(0xFFE0F2FE),
      },
      {
        'title': 'Landslide',
        'icon': Icons.terrain_rounded,
        'color': const Color(0xFFEA580C),
        'bgColor': const Color(0xFFFFF7ED),
      },
      {
        'title': 'Road Blocked',
        'icon': Icons.block_rounded,
        'color': const Color(0xFFDC2626),
        'bgColor': const Color(0xFFFEF2F2),
      },
      {
        'title': 'Bridge Damage',
        'icon': Icons.commit_rounded,
        'color': const Color(0xFF9333EA),
        'bgColor': const Color(0xFFFAF5FF),
      },
      {
        'title': 'Building Damage',
        'icon': Icons.home_work_rounded,
        'color': const Color(0xFF9A3412),
        'bgColor': const Color(0xFFFDF8F6),
      },
      {
        'title': 'People Trapped',
        'icon': Icons.groups_rounded,
        'color': const Color(0xFFE11D48),
        'bgColor': const Color(0xFFFDF2F8),
      },
      {
        'title': 'Water Level Rising',
        'icon': Icons.trending_up_rounded,
        'color': const Color(0xFF0891B2),
        'bgColor': const Color(0xFFECFEFF),
      },
      {
        'title': 'Road Clear / Safe',
        'icon': Icons.check_circle_rounded,
        'color': const Color(0xFF16A34A),
        'bgColor': const Color(0xFFF0FDF4),
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header bar matching Screenshot 2: Dark blue with back arrow
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    color: const Color(0xFF0C2340),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.pop(ctx),
                          borderRadius: BorderRadius.circular(20),
                          child: const Padding(
                            padding: EdgeInsets.all(2),
                            child: Icon(Icons.arrow_back_rounded,
                                color: Colors.white, size: 22),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Report Hazard',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content Body
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 8 Hazard Category Cards (Grid matching screenshot 2)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final cardWidth =
                                (constraints.maxWidth - 16) / 3;
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: hazardItems.map((item) {
                                final title = item['title'] as String;
                                final icon = item['icon'] as IconData;
                                final color = item['color'] as Color;
                                final bgColor = item['bgColor'] as Color;
                                final isSelected = selectedType == title;

                                return InkWell(
                                  onTap: () =>
                                      setSheetState(() => selectedType = title),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    width: cardWidth,
                                    height: 66,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFEBF5FF)
                                          : bgColor,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF0066D6)
                                            : const Color(0xFFE2E8F0),
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 4),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(icon, color: color, size: 22),
                                        const SizedBox(height: 3),
                                        Text(
                                          title,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: isSelected
                                                ? const Color(0xFF0066D6)
                                                : const Color(0xFF0F172A),
                                            fontSize: 9.5,
                                            fontWeight: isSelected
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                            height: 1.1,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                        const SizedBox(height: 14),

                        // Add Photo (Required) + Location (Auto) Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left photo upload thumbnails
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Add Photo (Required)',
                                    style: TextStyle(
                                      color: Color(0xFF475569),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      // Blue Camera button
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE0F2FE),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: const Color(0xFF93C5FD)),
                                        ),
                                        child: const Icon(
                                            Icons.camera_alt_rounded,
                                            color: Color(0xFF0066D6),
                                            size: 20),
                                      ),
                                      const SizedBox(width: 6),
                                      // Photo Thumbnail
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.asset(
                                          'assets/images/flood_banner_bg.jpg',
                                          width: 44,
                                          height: 44,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                            width: 44,
                                            height: 44,
                                            color: const Color(0xFFCBD5E1),
                                            child: const Icon(
                                                Icons.image_rounded,
                                                color: Color(0xFF64748B),
                                                size: 18),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      // Add "+" button
                                      Container(
                                        width: 40,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: const Color(0xFFE2E8F0)),
                                        ),
                                        child: const Icon(Icons.add_rounded,
                                            color: Color(0xFF64748B), size: 20),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Right Location (Auto) Telemetry
                            Expanded(
                              flex: 5,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: const Color(0xFFE2E8F0)),
                                ),
                                child: const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.person_outline_rounded,
                                            color: Color(0xFF64748B), size: 12),
                                        SizedBox(width: 4),
                                        Text(
                                          'Location (Auto)',
                                          style: TextStyle(
                                            color: Color(0xFF64748B),
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on_outlined,
                                            color: Color(0xFF0066D6), size: 13),
                                        SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            '25.5672, 91.8831',
                                            style: TextStyle(
                                              color: Color(0xFF0F172A),
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Icon(Icons.my_location_rounded,
                                            color: Color(0xFF0066D6), size: 13),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Full-width Submit Report Button
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              final report = _HazardReportItem(
                                id: 'HZD-${DateTime.now().millisecond}',
                                type: selectedType,
                                severity: 'Critical',
                                location: '25.5672° N, 91.8831° E • Mawphlang',
                                time: 'Just now',
                                description:
                                    'Ground hazard reported: $selectedType at Mawphlang Riverbank',
                                hasPhoto: true,
                              );
                              setState(() {
                                _recentHazards.insert(0, report);
                                _offlineQueue.add(_OfflineQueueItem(
                                  id: 'Q-${DateTime.now().millisecond}',
                                  title: 'Hazard: $selectedType',
                                  category: 'Hazard Report',
                                  timestamp:
                                      '${TimeOfDay.now().hour}:${TimeOfDay.now().minute}',
                                ));
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: const Color(0xFF0066D6),
                                  content: Text(
                                      'Hazard report submitted: $selectedType'),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0066D6),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Submit Report',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── 5. Request Backup Sheet (Instant 1-Tap Reasons) ───────────────────────
  void _openRequestBackupSheet() {
    String selectedReason = 'More rescuers needed';
    String urgency = 'Immediate (Life Threat)';

    final reasons = [
      'More rescuers needed',
      'Medical emergency',
      'Water too deep / Need boat',
      'Route blocked / Need machinery',
      'Equipment failure',
      'Team safety risk',
      'Other',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setBackupState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: _C.critical,
                  child: Row(
                    children: [
                      const Icon(Icons.support_agent_rounded,
                          color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Request Backup Dispatch',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Alerts DEOC and Nearest Field Units',
                            style: TextStyle(
                                color: Color(0xFFFFD1D1), fontSize: 11),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSectionTitle('SELECT BACKUP REASON'),
                      ...reasons.map((r) {
                        final selected = selectedReason == r;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: selected
                                ? _C.critical.withValues(alpha: 0.06)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selected
                                  ? _C.critical
                                  : const Color(0xFFE2E8F0),
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          child: InkWell(
                            onTap: () =>
                                setBackupState(() => selectedReason = r),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              child: Row(
                                children: [
                                  Icon(
                                    selected
                                        ? Icons.radio_button_checked_rounded
                                        : Icons.radio_button_off_rounded,
                                    color: selected
                                        ? _C.critical
                                        : _C.textMuted,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      r,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: selected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: selected
                                            ? _C.critical
                                            : _C.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                      _buildSectionTitle('DISPATCH URGENCY'),
                      Row(
                        children: [
                          'Immediate (Life Threat)',
                          'Priority (Within 30m)'
                        ].map((u) {
                          final sel = urgency == u;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setBackupState(() => urgency = u),
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 4),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? _C.critical.withValues(alpha: 0.15)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: sel
                                        ? _C.critical
                                        : const Color(0xFFCBD5E1),
                                  ),
                                ),
                                child: Text(
                                  u,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: sel ? _C.critical : _C.textSecondary,
                                    fontSize: 10,
                                    fontWeight: sel
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: _C.critical,
                              content: Text(
                                  'BACKUP SIGNAL SENT: Reason "$selectedReason" broadcasted with GPS to DEOC'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.send_rounded, size: 16),
                        label: const Text('Send Backup Request to Control Room',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _C.critical,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── 6. Offline Sync Manager Sheet ─────────────────────────────────────────
  void _openOfflineSyncSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSyncState) {
          final diff = DateTime.now().difference(_lastSyncTime).inMinutes;

          return Container(
            height: MediaQuery.of(context).size.height * 0.70,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: _C.navy,
                  child: Row(
                    children: [
                      const Icon(Icons.sync_rounded,
                          color: _C.actionBlue, size: 22),
                      const SizedBox(width: 8),
                      const Text(
                        'Offline Sync Manager',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Status card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isOffline
                                  ? Icons.wifi_off_rounded
                                  : Icons.cloud_done_rounded,
                              color: _isOffline ? _C.warning : _C.safe,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isOffline
                                        ? 'Local Mode (Offline)'
                                        : 'Online • Connected to DEOC',
                                    style: TextStyle(
                                      color:
                                          _isOffline ? _C.warning : _C.safe,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Last sync: $diff min ago • Zero data loss guaranteed',
                                    style: const TextStyle(
                                        color: _C.textSecondary, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionTitle('PENDING OPERATIONS QUEUE'),
                          Text(
                            '${_offlineQueue.where((q) => q.status != 'Synced').length} pending',
                            style: const TextStyle(
                                color: _C.warning,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      ..._offlineQueue.map((item) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item.status == 'Synced'
                                    ? Icons.check_circle_rounded
                                    : Icons.pending_actions_rounded,
                                color: item.status == 'Synced'
                                    ? _C.safe
                                    : _C.warning,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _C.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '${item.category} • Recorded: ${item.timestamp}',
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: _C.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                item.status,
                                style: TextStyle(
                                  color: item.status == 'Synced'
                                      ? _C.safe
                                      : _C.warning,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setState(() => _isOffline = !_isOffline);
                                setSyncState(() {});
                              },
                              icon: Icon(_isOffline
                                  ? Icons.wifi_rounded
                                  : Icons.wifi_off_rounded),
                              label: Text(_isOffline
                                  ? 'Simulate Online'
                                  : 'Simulate Offline'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _C.govBlue,
                                side: const BorderSide(color: _C.govBlue),
                                minimumSize: const Size(0, 48),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _syncing
                                  ? null
                                  : () async {
                                      await _triggerSync();
                                      setSyncState(() {});
                                    },
                              icon: _syncing
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.sync_rounded, size: 16),
                              label: Text(_syncing ? 'Syncing...' : 'Sync Now'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _C.actionBlue,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 48),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Helper: Section Header ────────────────────────────────────────────────
  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required String subtitle,
  }) {
    return Container(
      color: _C.navy,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Icon(icon, color: _C.actionBlue, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TACTICAL EMERGENCY MAP PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _TacticalMapPainter extends CustomPainter {
  final double radarPhase;
  final bool showFlood;
  final bool showHazard;
  final bool showRoute;
  final bool showSOS;
  final bool showShelters;
  final bool showHospitals;
  final bool useAlternateRoute;
  final int layerIndex;
  final bool isNavigating;

  const _TacticalMapPainter({
    required this.radarPhase,
    required this.showFlood,
    required this.showHazard,
    required this.showRoute,
    required this.showSOS,
    required this.showShelters,
    required this.showHospitals,
    required this.useAlternateRoute,
    this.layerIndex = 0,
    this.isNavigating = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    if (layerIndex == 2) {
      // Tactical Dark Mode
      _drawDarkTacticalBase(canvas, w, h);
    } else if (layerIndex == 1) {
      // Satellite Imagery Mode
      _drawSatelliteBase(canvas, w, h);
    } else {
      // Topographic Relief Mode (Default matching Screenshot 1)
      _drawTopographicBase(canvas, w, h);
    }

    // Mawphlang River & Water Network
    _drawMawphlangRiver(canvas, w, h);

    // Flood Inundation Polygon
    if (showFlood) {
      _drawFloodZone(canvas, w, h);
    }

    // Road Network
    _drawRoadNetwork(canvas, w, h);

    // Operational Navigation Routes
    if (showRoute) {
      _drawNavigationRoutes(canvas, w, h);
    }

    // Operational Hazard & Caution Markers
    if (showHazard) {
      _drawHazardMarkers(canvas, w, h);
    }

    // SOS Distress Markers
    if (showSOS) {
      _drawSOSMarkers(canvas, w, h);
    }

    // Responder (Team Bravo) Location Marker
    _drawResponderLocation(canvas, Offset(w * 0.34, h * 0.64));

    // Town & Sector Labels
    _drawTownLabel(canvas, 'Mawphlang', Offset(w * 0.58, h * 0.63));
  }

  // ── Topographic Terrain Base (Realistic Green Relief & Contours) ──────────
  void _drawTopographicBase(Canvas canvas, double w, double h) {
    // Soft topographic terrain background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFFDFE9D5),
    );

    // Mountain hill shading (Elevation clusters)
    final hillPaint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF86A875).withValues(alpha: 0.8),
          const Color(0xFFA2C492).withValues(alpha: 0.5),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
          center: Offset(w * 0.15, h * 0.25), radius: w * 0.45));
    canvas.drawCircle(Offset(w * 0.15, h * 0.25), w * 0.45, hillPaint1);

    final hillPaint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF759765).withValues(alpha: 0.75),
          const Color(0xFF9EBF8E).withValues(alpha: 0.45),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
          center: Offset(w * 0.82, h * 0.22), radius: w * 0.5));
    canvas.drawCircle(Offset(w * 0.82, h * 0.22), w * 0.5, hillPaint2);

    final hillPaint3 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF8BAF79).withValues(alpha: 0.7),
          const Color(0xFFB5D1A6).withValues(alpha: 0.4),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
          center: Offset(w * 0.35, h * 0.82), radius: w * 0.45));
    canvas.drawCircle(Offset(w * 0.35, h * 0.82), w * 0.45, hillPaint3);

    // Topographic Elevation Contour Lines
    final contourPaint = Paint()
      ..color = const Color(0xFF5D7F50).withValues(alpha: 0.28)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 6; i++) {
      final cp = Path()
        ..moveTo(0, h * (0.15 + i * 0.08))
        ..cubicTo(w * 0.22, h * (0.12 + i * 0.07), w * 0.48,
            h * (0.28 + i * 0.08), w, h * (0.18 + i * 0.09));
      canvas.drawPath(cp, contourPaint);
    }
    for (int i = 0; i < 5; i++) {
      final cp = Path()
        ..moveTo(0, h * (0.65 + i * 0.08))
        ..cubicTo(w * 0.30, h * (0.68 + i * 0.07), w * 0.65,
            h * (0.78 + i * 0.06), w, h * (0.72 + i * 0.08));
      canvas.drawPath(cp, contourPaint);
    }
  }

  // ── Satellite Imagery Base ────────────────────────────────────────────────
  void _drawSatelliteBase(Canvas canvas, double w, double h) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFF1C3426),
    );
    final forestPaint = Paint()
      ..color = const Color(0xFF294D38).withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.3, h * 0.3), width: w * 0.7, height: h * 0.4),
      forestPaint,
    );
  }

  // ── Tactical Dark Mode Base ───────────────────────────────────────────────
  void _drawDarkTacticalBase(Canvas canvas, double w, double h) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFF0B2341),
    );
    final gridPaint = Paint()
      ..color = const Color(0xFF1E3A5F).withValues(alpha: 0.6)
      ..strokeWidth = 0.6;
    for (double x = 0; x < w; x += w / 8) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (double y = 0; y < h; y += h / 10) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }
  }

  // ── Mawphlang River & Water Network ───────────────────────────────────────
  void _drawMawphlangRiver(Canvas canvas, double w, double h) {
    // Shoreline soft tint / riparian corridor
    final riparianPaint = Paint()
      ..color = const Color(0xFF7BAAB8).withValues(alpha: 0.4)
      ..strokeWidth = 28.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final mainRiverPath = Path()
      ..moveTo(0, h * 0.48)
      ..cubicTo(w * 0.18, h * 0.46, w * 0.32, h * 0.56, w * 0.46, h * 0.58)
      ..cubicTo(w * 0.60, h * 0.60, w * 0.74, h * 0.52, w, h * 0.54);

    canvas.drawPath(mainRiverPath, riparianPaint);

    // Deep water main stream
    final waterPaint = Paint()
      ..color = const Color(0xFF4A90C4)
      ..strokeWidth = 18.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(mainRiverPath, waterPaint);

    // Northern River Arm / Basin Branch
    final northBranch = Path()
      ..moveTo(w * 0.24, h * 0.49)
      ..cubicTo(w * 0.32, h * 0.44, w * 0.42, h * 0.42, w * 0.54, h * 0.46)
      ..cubicTo(w * 0.64, h * 0.50, w * 0.76, h * 0.46, w, h * 0.48);

    final branchPaint = Paint()
      ..color = const Color(0xFF5BA2D4)
      ..strokeWidth = 12.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(northBranch, branchPaint);

    // Water Shoreline Highlights
    final shoreHighlight = Paint()
      ..color = const Color(0xFF90C8EF).withValues(alpha: 0.7)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    canvas.drawPath(mainRiverPath, shoreHighlight);
  }

  // ── Flood Inundation Zone (Salmon/Red Polygon) ─────────────────────────────
  void _drawFloodZone(Canvas canvas, double w, double h) {
    final floodPath = Path()
      ..moveTo(w * 0.24, h * 0.54)
      ..cubicTo(w * 0.22, h * 0.44, w * 0.28, h * 0.34, w * 0.38, h * 0.32)
      ..cubicTo(w * 0.46, h * 0.30, w * 0.55, h * 0.34, w * 0.56, h * 0.42)
      ..cubicTo(w * 0.58, h * 0.50, w * 0.48, h * 0.58, w * 0.36, h * 0.59)
      ..close();

    // Semi-transparent salmon fill
    final fillPaint = Paint()
      ..color = const Color(0xFFE57373).withValues(alpha: 0.42)
      ..style = PaintingStyle.fill;
    canvas.drawPath(floodPath, fillPaint);

    // Red boundary outline
    final borderPaint = Paint()
      ..color = const Color(0xFFDC2626).withValues(alpha: 0.65)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    canvas.drawPath(floodPath, borderPaint);

    // Inundation wave texture
    final wavePaint = Paint()
      ..color = const Color(0xFFDC2626).withValues(alpha: 0.35)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
        Offset(w * 0.34, h * 0.42), Offset(w * 0.44, h * 0.42), wavePaint);
    canvas.drawLine(
        Offset(w * 0.38, h * 0.46), Offset(w * 0.48, h * 0.46), wavePaint);
  }

  // ── Road Network ──────────────────────────────────────────────────────────
  void _drawRoadNetwork(Canvas canvas, double w, double h) {
    final roadCasing = Paint()
      ..color = const Color(0xFF888888).withValues(alpha: 0.4)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final roadCore = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Southern Highway
    final southRoad = Path()
      ..moveTo(0, h * 0.68)
      ..cubicTo(w * 0.30, h * 0.66, w * 0.50, h * 0.68, w, h * 0.64);
    canvas.drawPath(southRoad, roadCasing);
    canvas.drawPath(southRoad, roadCore);

    // Mountain Bypass Road Loop
    final bypassRoad = Path()
      ..moveTo(w * 0.28, h * 0.67)
      ..cubicTo(w * 0.24, h * 0.58, w * 0.30, h * 0.48, w * 0.38, h * 0.47)
      ..cubicTo(w * 0.48, h * 0.46, w * 0.58, h * 0.52, w * 0.67, h * 0.53)
      ..cubicTo(w * 0.72, h * 0.54, w * 0.80, h * 0.58, w, h * 0.59);
    canvas.drawPath(bypassRoad, roadCasing);
    canvas.drawPath(bypassRoad, roadCore);
  }

  // ── Operational Navigation Routes ─────────────────────────────────────────
  void _drawNavigationRoutes(Canvas canvas, double w, double h) {
    // 1. Blue Responder Route from Team Bravo
    final respBluePath = Path()
      ..moveTo(w * 0.34, h * 0.64)
      ..lineTo(w * 0.28, h * 0.59);

    final bluePaint = Paint()
      ..color = const Color(0xFF0066D6)
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(respBluePath, bluePaint);

    // 2. Green Safe Extraction Route
    final greenPath = Path()
      ..moveTo(w * 0.28, h * 0.59)
      ..cubicTo(w * 0.32, h * 0.58, w * 0.42, h * 0.57, w * 0.50, h * 0.56)
      ..cubicTo(w * 0.58, h * 0.54, w * 0.64, h * 0.52, w * 0.69, h * 0.50);

    final greenPaint = Paint()
      ..color = const Color(0xFF16A34A)
      ..strokeWidth = 4.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(greenPath, greenPaint);

    // 3. Red Unsafe Eastern Bridge Detour Segment
    final redBridgePath = Path()
      ..moveTo(w * 0.28, h * 0.59)
      ..cubicTo(w * 0.25, h * 0.56, w * 0.20, h * 0.55, w * 0.19, h * 0.54);

    final redPaint = Paint()
      ..color = const Color(0xFFDC2626)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(redBridgePath, redPaint);
  }

  // ── Hazard & Warning Markers ──────────────────────────────────────────────
  void _drawHazardMarkers(Canvas canvas, double w, double h) {
    // Orange Caution Circle at (w * 0.69, h * 0.50)
    _drawCircleIconMarker(
      canvas,
      Offset(w * 0.69, h * 0.50),
      const Color(0xFFEA580C),
      Icons.warning_amber_rounded,
      13.0,
    );

    // Red Hazard Circle at (w * 0.63, h * 0.58)
    _drawCircleIconMarker(
      canvas,
      Offset(w * 0.63, h * 0.58),
      const Color(0xFFDC2626),
      Icons.remove_road_rounded,
      12.0,
    );

    // Dark Caution Circle at (w * 0.12, h * 0.67)
    _drawCircleIconMarker(
      canvas,
      Offset(w * 0.12, h * 0.67),
      const Color(0xFF0F172A),
      Icons.priority_high_rounded,
      11.0,
    );
  }

  // ── SOS Teardrop Markers ──────────────────────────────────────────────────
  void _drawSOSMarkers(Canvas canvas, double w, double h) {
    // 1. Red SOS Teardrop Pin in center of flooded zone
    _drawTeardropPin(
        canvas, Offset(w * 0.39, h * 0.48), const Color(0xFFDC2626), 'SOS');

    // 2. Red SOS Teardrop Pin at west riverbank
    _drawTeardropPin(
        canvas, Offset(w * 0.20, h * 0.54), const Color(0xFFDC2626), 'SOS');
  }

  // ── Teardrop Pin Shape (Exact Match to Screenshot 1) ──────────────────────
  void _drawTeardropPin(Canvas canvas, Offset tip, Color color, String text) {
    final center = tip - const Offset(0, 16);
    const radius = 11.0;

    final path = Path();
    path.addArc(Rect.fromCircle(center: center, radius: radius), math.pi * 0.22,
        math.pi * 1.56);
    path.lineTo(tip.dx, tip.dy);
    path.close();

    // Shadow
    canvas.drawShadow(path, Colors.black, 4.0, true);

    // Pin body
    canvas.drawPath(path, Paint()..color = color);

    // White outline
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    // Inner White Text
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  // ── Circular Icon Marker ───────────────────────────────────────────────────
  void _drawCircleIconMarker(Canvas canvas, Offset center, Color color,
      IconData icon, double radius) {
    // Drop shadow
    canvas.drawCircle(
      center + const Offset(0, 2),
      radius,
      Paint()..color = Colors.black.withValues(alpha: 0.28),
    );

    // Filled circle
    canvas.drawCircle(center, radius, Paint()..color = color);

    // White border
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Inner icon
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: radius * 1.25,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  // ── Responder Location (Blue Glowing Concentric Ring) ─────────────────────
  void _drawResponderLocation(Canvas canvas, Offset center) {
    // Animated outer pulsating halo wave
    canvas.drawCircle(
      center,
      12 + (radarPhase * 16),
      Paint()
        ..color = const Color(0xFF0066D6)
            .withValues(alpha: (1.0 - radarPhase) * 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Outer soft blue glow
    canvas.drawCircle(
      center,
      13,
      Paint()..color = const Color(0xFF38BDF8).withValues(alpha: 0.4),
    );

    // Crisp white ring
    canvas.drawCircle(
      center,
      9,
      Paint()..color = Colors.white,
    );

    // Solid blue center dot
    canvas.drawCircle(
      center,
      6.5,
      Paint()..color = const Color(0xFF0066D6),
    );
  }

  // ── Town Label ─────────────────────────────────────────────────────────────
  void _drawTownLabel(Canvas canvas, String label, Offset pos) {
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: const Color(0xFF0F172A),
          fontSize: 12.0,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
          shadows: [
            Shadow(
              color: Colors.white.withValues(alpha: 0.95),
              blurRadius: 4,
              offset: const Offset(0, 0),
            ),
            Shadow(
              color: Colors.white.withValues(alpha: 0.95),
              blurRadius: 6,
              offset: const Offset(0, 0),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _TacticalMapPainter old) {
    return old.radarPhase != radarPhase ||
        old.showFlood != showFlood ||
        old.showHazard != showHazard ||
        old.showRoute != showRoute ||
        old.showSOS != showSOS ||
        old.showShelters != showShelters ||
        old.showHospitals != showHospitals ||
        old.useAlternateRoute != useAlternateRoute ||
        old.layerIndex != layerIndex ||
        old.isNavigating != isNavigating;
  }
}

class _TrianglePointerPainter extends CustomPainter {
  final Color color;
  const _TrianglePointerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// ROUTE MAP BOTTOM SHEET
// Slides up from the bottom showing FlutterMap with route polyline
// ─────────────────────────────────────────────────────────────────────────────
class _RouteMapSheet extends StatefulWidget {
  final _Mission mission;
  final LatLng myLocation;
  final LatLng destination;
  final bool navigateMode;

  const _RouteMapSheet({
    required this.mission,
    required this.myLocation,
    required this.destination,
    required this.navigateMode,
  });

  @override
  State<_RouteMapSheet> createState() => _RouteMapSheetState();
}

class _RouteMapSheetState extends State<_RouteMapSheet>
    with SingleTickerProviderStateMixin {
  late final MapController _ctrl;
  late final AnimationController _dashCtrl;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _ctrl = MapController();
    _dashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    if (widget.navigateMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _isNavigating = true);
      });
    }
  }

  @override
  void dispose() {
    _dashCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final dist = widget.mission.distance;
    final eta = widget.mission.eta;

    // Midpoint for initial map center
    final midLat =
        (widget.myLocation.latitude + widget.destination.latitude) / 2;
    final midLng =
        (widget.myLocation.longitude + widget.destination.longitude) / 2;

    return Container(
      height: screenH * 0.78,
      decoration: const BoxDecoration(
        color: Color(0xFF0B2341),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // ── Handle ───────────────────────────────────────────────────────
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 10),

          // ── Header ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _isNavigating
                        ? const Color(0xFF087BE7)
                        : const Color(0xFF7C3AED),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isNavigating
                            ? Icons.navigation_rounded
                            : Icons.route_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _isNavigating ? 'NAVIGATING' : 'ROUTE PREVIEW',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.mission.title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.white54, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // ── Route Info Bar ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  _routeInfoChip(
                      Icons.location_on_rounded,
                      widget.mission.location,
                      Colors.redAccent),
                  const SizedBox(width: 12),
                  _routeInfoChip(
                      Icons.straighten_rounded, dist, Colors.amberAccent),
                  const SizedBox(width: 12),
                  _routeInfoChip(
                      Icons.access_time_rounded, 'ETA $eta', Colors.greenAccent),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── Map ───────────────────────────────────────────────────────────
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(20)),
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _ctrl,
                    options: MapOptions(
                      initialCenter: LatLng(midLat, midLng),
                      initialZoom: 13.5,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.resqshield.app',
                      ),
                      // Route polyline (dashed appearance via AnimatedBuilder)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: [
                              widget.myLocation,
                              LatLng(
                                (widget.myLocation.latitude +
                                        widget.destination.latitude) /
                                    2 +
                                    0.005,
                                (widget.myLocation.longitude +
                                        widget.destination.longitude) /
                                    2 -
                                    0.003,
                              ),
                              widget.destination,
                            ],
                            strokeWidth: 5,
                            color: _isNavigating
                                ? const Color(0xFF087BE7)
                                : const Color(0xFF7C3AED),
                            borderStrokeWidth: 2,
                            borderColor: Colors.white.withValues(alpha: 0.4),
                          ),
                        ],
                      ),
                      // Markers
                      MarkerLayer(
                        markers: [
                          // My location
                          Marker(
                            point: widget.myLocation,
                            width: 44,
                            height: 44,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF087BE7),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF087BE7)
                                        .withValues(alpha: 0.5),
                                    blurRadius: 10,
                                  )
                                ],
                              ),
                              child: const Icon(Icons.my_location_rounded,
                                  color: Colors.white, size: 22),
                            ),
                          ),
                          // Destination
                          Marker(
                            point: widget.destination,
                            width: 44,
                            height: 56,
                            child: Column(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade600,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red
                                            .withValues(alpha: 0.5),
                                        blurRadius: 12,
                                      )
                                    ],
                                  ),
                                  child: const Icon(Icons.place_rounded,
                                      color: Colors.white, size: 22),
                                ),
                                Container(
                                  width: 2,
                                  height: 12,
                                  color: Colors.red.shade600,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Safe Route Banner
                  Positioned(
                    top: 10,
                    left: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B2341).withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFF16A34A).withValues(alpha: 0.6)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.shield_rounded,
                              color: Color(0xFF16A34A), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.mission.safeRouteSummary,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom Actions ────────────────────────────────────────────────
          Container(
            color: const Color(0xFF0B2341),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Close',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _isNavigating = !_isNavigating);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isNavigating
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF087BE7),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    icon: Icon(
                      _isNavigating
                          ? Icons.stop_circle_rounded
                          : Icons.navigation_rounded,
                      size: 20,
                    ),
                    label: Text(
                      _isNavigating ? 'Stop Navigation' : 'Start Navigation',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _routeInfoChip(IconData icon, String text, Color iconColor) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 13),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
