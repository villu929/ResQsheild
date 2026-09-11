import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'role_selection_screen.dart';
import 'authority/alert_dispatch_screen.dart';
import 'authority/village_risk_table_screen.dart';
import 'authority/hazard_map_screen.dart';
import 'authority/resource_shelter_map_screen.dart';
import 'authority/trends_forecast_screen.dart';
import 'authority/dam_coordination_screen.dart';
import 'authority/coordination_log_screen.dart';
import 'authority/widgets/animated_ring_chart.dart';
import 'authority/widgets/animated_trend_graph.dart';

// ============================================================================
// COLOR PALETTE — GOVERNMENT & COMMAND CENTER GRADE
// ============================================================================
class CmdColors {
  static const Color navy = Color(0xFF0A192F);
  static const Color slateDark = Color(0xFF1E293B);
  static const Color slateBorder = Color(0xFF334155);
  static const Color slateLight = Color(0xFF475569);

  static const Color bg = Color(0xFFF1F5F9);
  static const Color cardBg = Colors.white;
  static const Color cardBorder = Color(0xFFE2E8F0);

  static const Color primaryBlue = Color(0xFF0284C7);
  static const Color deepBlue = Color(0xFF013973);
  static const Color cyanAccent = Color(0xFF06B6D4);

  static const Color criticalRed = Color(0xFFDC2626);
  static const Color warningOrange = Color(0xFFEA580C);
  static const Color cautionAmber = Color(0xFFD97706);
  static const Color safeGreen = Color(0xFF16A34A);
  static const Color normalBlue = Color(0xFF2563EB);

  static const Color redLight = Color(0xFFFEF2F2);
  static const Color orangeLight = Color(0xFFFFF7ED);
  static const Color greenLight = Color(0xFFF0FDF4);
  static const Color blueLight = Color(0xFFF0F9FF);
  static const Color purpleLight = Color(0xFFFAF5FF);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);
}

// ============================================================================
// DATA MODELS FOR AUTHORITY OPERATIONS
// ============================================================================
class _SosItem {
  final String id;
  final String village;
  final String district;
  final int people;
  final int elderly;
  final int children;
  final bool medical;
  final String timeAgo;
  String status; // 'Unassigned', 'Team Assigned', 'In Progress', 'Resolved', 'Active'
  String? assignedTeam;
  final LatLng coords;
  final String severity; // 'Critical', 'High', 'Normal'

  _SosItem({
    required this.id,
    required this.village,
    this.district = 'East Khasi Hills',
    required this.people,
    required this.elderly,
    required this.children,
    required this.medical,
    required this.timeAgo,
    required this.status,
    this.assignedTeam,
    required this.coords,
    required this.severity,
  });
}

class _RescueTeam {
  final String id;
  final String name;
  final String unit;
  String status; // 'Available', 'On Mission', 'Offline'
  final int members;
  final int boats;
  final int ambulances;
  final String location;
  String mission;
  final String eta;

  _RescueTeam({
    required this.id,
    required this.name,
    required this.unit,
    required this.status,
    required this.members,
    required this.boats,
    required this.ambulances,
    required this.location,
    required this.mission,
    required this.eta,
  });
}

class _ShelterItem {
  final String name;
  final int capacity;
  int occupied;
  final String food;
  final String water;
  final bool medical;
  final LatLng coords;

  _ShelterItem({
    required this.name,
    required this.capacity,
    required this.occupied,
    required this.food,
    required this.water,
    required this.medical,
    required this.coords,
  });

  String get status {
    final ratio = occupied / capacity;
    if (ratio >= 1.0) return 'Full';
    if (ratio >= 0.85) return 'Near Capacity';
    return 'Available';
  }

  Color get statusColor {
    final ratio = occupied / capacity;
    if (ratio >= 1.0) return CmdColors.criticalRed;
    if (ratio >= 0.85) return CmdColors.warningOrange;
    return CmdColors.safeGreen;
  }
}

// ============================================================================
// MAIN AUTHORITY COMMAND DASHBOARD SCREEN
// ============================================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // Navigation
  int _activeNavIndex = 0; // 0: Overview, 1: Map, 2: SOS, 3: Evacuation, 4: Shelters, 5: Reports

  // Jurisdiction
  String _selectedDistrict = 'East Khasi Hills District';
  String _selectedState = 'Meghalaya';

  // Overall Situation dynamic status
  String _situationStatus = 'CRITICAL'; // 'NORMAL', 'WATCH', 'WARNING', 'CRITICAL'

  // Map Controller & Active Center (East Khasi Hills river basin)
  final MapController _mapController = MapController();
  final LatLng _centerCoords = const LatLng(25.5788, 91.8933);

  // Map layer filter toggles
  bool _layerFlood = true;
  bool _layerRainfall = true;
  bool _layerRiver = true;
  bool _layerLandslide = false;
  bool _layerGlof = false;
  bool _layerDam = false;
  bool _layerSos = true;
  bool _layerShelters = true;
  bool _layerHospitals = false;
  bool _layerRoads = true;
  bool _layerTeams = true;

  // Pulse animation for critical alerts & pins
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  // Evacuation Sector A progress
  int _evacuatedPop = 1920;
  final int _totalSectorPop = 2840;

  // Operational Lists
  late List<_SosItem> _sosList;
  late List<_RescueTeam> _rescueTeams;
  late List<_ShelterItem> _shelters;
  late List<String> _actionLogs;

  // SOS Triage Filter & Search
  String _sosFilter = 'All'; // 'All', 'Critical', 'Medical', 'Unassigned'
  String _sosSearchQuery = '';
  final TextEditingController _sosSearchController = TextEditingController();

  // Relief stocks
  int _foodAvailable = 8400;
  final int _foodRequired = 11000;
  int _waterAvailable = 12000;
  final int _waterRequired = 15000;
  final int _medKits = 450;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _sosSearchController.dispose();
    super.dispose();
  }

  void _initData() {
    _sosList = [
      _SosItem(
        id: '#284',
        village: 'Mawphlang Riverfront',
        district: 'East Khasi Hills',
        people: 6,
        elderly: 1,
        children: 0,
        medical: true,
        timeAgo: '4 min ago',
        status: 'Active',
        assignedTeam: 'Team 02 (SDRF Bravo)',
        coords: const LatLng(25.4512, 91.7589),
        severity: 'Critical',
      ),
      _SosItem(
        id: '#281',
        village: 'Nongstoin Valley Lowland',
        district: 'West Khasi Hills',
        people: 4,
        elderly: 0,
        children: 2,
        medical: false,
        timeAgo: '8 min ago',
        status: 'Active',
        assignedTeam: null,
        coords: const LatLng(25.5230, 91.2680),
        severity: 'Critical',
      ),
      _SosItem(
        id: '#279',
        village: 'Pynursla Riverbed Sector',
        district: 'East Khasi Hills',
        people: 11,
        elderly: 3,
        children: 1,
        medical: true,
        timeAgo: '15 min ago',
        status: 'Active',
        assignedTeam: 'Team 01 (NDRF Alpha)',
        coords: const LatLng(25.3094, 91.9022),
        severity: 'High',
      ),
      _SosItem(
        id: '#275',
        village: 'Cherrapunjee Foothills',
        people: 3,
        elderly: 1,
        children: 0,
        medical: false,
        timeAgo: '24 min ago',
        status: 'In Progress',
        assignedTeam: 'Team 03 (Civil Defense)',
        coords: const LatLng(25.2986, 91.7324),
        severity: 'High',
      ),
      _SosItem(
        id: '#270',
        village: 'Mawkdok Bridge Junction',
        people: 2,
        elderly: 0,
        children: 0,
        medical: false,
        timeAgo: '35 min ago',
        status: 'Resolved',
        assignedTeam: 'Team 01 (NDRF Alpha)',
        coords: const LatLng(25.4120, 91.7912),
        severity: 'Normal',
      ),
    ];

    _rescueTeams = [
      _RescueTeam(
        id: 'T-01',
        name: 'Team 01',
        unit: 'NDRF Unit Alpha',
        status: 'Available',
        members: 8,
        boats: 2,
        ambulances: 1,
        location: 'Sector 1 Staging Ground',
        mission: 'Standby for priority evacuation',
        eta: 'Immediate',
      ),
      _RescueTeam(
        id: 'T-02',
        name: 'Team 02',
        unit: 'SDRF Bravo',
        status: 'On Mission',
        members: 10,
        boats: 3,
        ambulances: 1,
        location: 'En route Mawphlang',
        mission: 'Assigned to SOS #284 (Mawphlang)',
        eta: '8 min',
      ),
      _RescueTeam(
        id: 'T-03',
        name: 'Team 03',
        unit: 'Civil Defense Quick Team',
        status: 'Available',
        members: 6,
        boats: 1,
        ambulances: 0,
        location: 'Staging Area North',
        mission: 'Clear road obstruction on bypass',
        eta: 'Standby',
      ),
      _RescueTeam(
        id: 'T-04',
        name: 'Team 04',
        unit: 'Army Quick Response',
        status: 'Offline',
        members: 12,
        boats: 2,
        ambulances: 2,
        location: 'Base Camp (Transit)',
        mission: 'Heavy amphibious transport',
        eta: '25 min',
      ),
    ];

    _shelters = [
      _ShelterItem(
        name: 'Mawphlang Community Center',
        capacity: 100,
        occupied: 72,
        food: 'High',
        water: 'Good',
        medical: true,
        coords: const LatLng(25.4550, 91.7620),
      ),
      _ShelterItem(
        name: 'St. Anthony Relief Hall',
        capacity: 200,
        occupied: 184,
        food: 'Moderate',
        water: 'Low',
        medical: true,
        coords: const LatLng(25.5650, 91.8820),
      ),
      _ShelterItem(
        name: 'Valley Govt High School',
        capacity: 200,
        occupied: 200,
        food: 'Low',
        water: 'Critical',
        medical: false,
        coords: const LatLng(25.5180, 91.2750),
      ),
      _ShelterItem(
        name: 'Northeast Indoor Stadium',
        capacity: 350,
        occupied: 120,
        food: 'High',
        water: 'Good',
        medical: true,
        coords: const LatLng(25.5890, 91.9050),
      ),
    ];

    _actionLogs = [
      '19:42 — Evacuation order broadcast issued for Mawphlang Sector by Capt. R. Sharma',
      '19:37 — Team 02 (SDRF Bravo) assigned to SOS #284 (Medical Emergency)',
      '19:30 — Shelter B (St. Anthony Relief Hall) activated at 92% capacity',
      '19:18 — Emergency multi-channel alert sent via App + SMS + Siren to 21,400 citizens',
      '19:04 — Main Valley Bridge closed due to high water velocity & structural inspection',
      '18:55 — Umiam River level reached 7.42m (+18 cm/hr rise rate trigger)',
    ];
  }

  // ==========================================================================
  // TOP APP BAR (Section 1)
  // ==========================================================================
  PreferredSizeWidget _buildTopBar() {
    return AppBar(
      backgroundColor: CmdColors.navy,
      elevation: 3,
      toolbarHeight: 70,
      titleSpacing: 0,
      leadingWidth: 96,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
            onPressed: _handleLogout,
            tooltip: 'Back to Role Selection',
          ),
          Builder(
            builder: (context) => IconButton(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 22),
              onPressed: () => Scaffold.of(context).openDrawer(),
              tooltip: 'Open Command Menu',
            ),
          ),
        ],
      ),
      title: Row(
        children: [
          // Logo & Title
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: CmdColors.primaryBlue.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: CmdColors.cyanAccent.withValues(alpha: 0.5),
                width: 1.2,
              ),
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: CmdColors.cyanAccent,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 2,
                  children: [
                    const Text(
                      'JalGuard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: CmdColors.cyanAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: CmdColors.cyanAccent.withValues(alpha: 0.5),
                          width: 0.8,
                        ),
                      ),
                      child: const Text(
                        'AUTHORITY COMMAND',
                        style: TextStyle(
                          color: CmdColors.cyanAccent,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                // Jurisdiction Dropdown
                GestureDetector(
                  onTap: _showJurisdictionPicker,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFF94A3B8),
                        size: 13,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          '$_selectedDistrict ($selectedStateShort)',
                          style: const TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_drop_down_rounded,
                        color: Color(0xFF94A3B8),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Live System Online Indicator
        Container(
          margin: const EdgeInsets.symmetric(vertical: 20),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF16A34A).withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF22C55E).withValues(alpha: 0.6),
              width: 0.9,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (context, child) {
                  return Container(
                    width: 7 * _pulseAnim.value,
                    height: 7 * _pulseAnim.value,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
                      shape: BoxShape.circle,
                    ),
                  );
                },
              ),
              const SizedBox(width: 5),
              const Text(
                'LIVE',
                style: TextStyle(
                  color: Color(0xFF86EFAC),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),

        // Notification Bell with badge 7
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_active_outlined,
                color: Colors.white,
                size: 22,
              ),
              onPressed: _showNotificationsSheet,
              tooltip: 'Critical Alerts & Logs',
            ),
            Positioned(
              top: 13,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: CmdColors.criticalRed,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: const Center(
                  child: Text(
                    '7',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Officer Profile Pill
        IconButton(
          icon: const CircleAvatar(
            radius: 15,
            backgroundColor: CmdColors.primaryBlue,
            child: Icon(Icons.person_rounded, color: Colors.white, size: 18),
          ),
          onPressed: _showOfficerProfileDialog,
          tooltip: 'Officer Profile',
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  String get selectedStateShort =>
      _selectedState == 'Meghalaya' ? 'ML' : _selectedState;

  // ==========================================================================
  // DRAWER NAVIGATION (Section 30 & Sidebar)
  // ==========================================================================
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: CmdColors.navy,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: CmdColors.slateBorder, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [CmdColors.primaryBlue, CmdColors.cyanAccent],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'JalGuard DDMA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Disaster Operations Center',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _drawerTile(
                    0,
                    Icons.dashboard_rounded,
                    'Overview Command',
                    'Real-time situational feed',
                  ),
                  _drawerTile(
                    1,
                    Icons.map_rounded,
                    'Live Disaster Map',
                    '10+ GIS intelligence layers',
                  ),
                  _drawerTile(
                    2,
                    Icons.emergency_rounded,
                    'Active SOS & Incidents',
                    '27 Active triage missions',
                  ),
                  _drawerTile(
                    3,
                    Icons.departure_board_rounded,
                    'Evacuation & Teams',
                    '67% Evacuated · 7 Teams',
                  ),
                  _drawerTile(
                    4,
                    Icons.night_shelter_rounded,
                    'Shelters & Relief',
                    '18 Shelters · Food & Water',
                  ),
                  _drawerTile(
                    5,
                    Icons.broadcast_on_personal_rounded,
                    'Alerts & Broadcast',
                    'SMS · Siren · App Push',
                  ),
                  _drawerTile(
                    6,
                    Icons.analytics_rounded,
                    'SITREP & Reports',
                    'Instant 1-Click Operations SITREP',
                  ),
                  _drawerTile(
                    7,
                    Icons.history_edu_rounded,
                    'Action Audit Log',
                    'Official timeline of orders',
                  ),
                  const Divider(color: CmdColors.slateBorder, height: 24),
                  // Deep-dive modules from authority sub-screens
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Text(
                      'SPECIALIZED MODULES',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.table_chart_rounded,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                    title: const Text(
                      'Village Risk Matrix',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const VillageRiskTableScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.layers_rounded,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                    title: const Text(
                      'Hazard Flood Severity Map',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HazardMapScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.apartment_rounded,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                    title: const Text(
                      'Shelter & Relief GIS Hub',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ResourceShelterMapScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.water_drop_rounded,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                    title: const Text(
                      'Dam Discharge Telemetry',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DamCoordinationScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.trending_up_rounded,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                    title: const Text(
                      'Hydrological Trends & AI Forecast',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TrendsForecastScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.history_rounded,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                    title: const Text(
                      'Inter-Agency Coordination Log',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CoordinationLogScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Bottom Profile & Logout
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: CmdColors.slateBorder, width: 1),
                ),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 17,
                    backgroundColor: CmdColors.primaryBlue,
                    child: Text(
                      'RS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Capt. R. Sharma',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'District Relief Officer',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFEF4444),
                      size: 20,
                    ),
                    tooltip: 'Logout / Switch Role',
                    onPressed: _handleLogout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerTile(
    int index,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final isSelected = _activeNavIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? CmdColors.primaryBlue.withValues(alpha: 0.22)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isSelected
            ? Border.all(
                color: CmdColors.cyanAccent.withValues(alpha: 0.6),
                width: 1,
              )
            : null,
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          color: isSelected ? CmdColors.cyanAccent : const Color(0xFF94A3B8),
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFFE2E8F0),
            fontSize: 13.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isSelected
                ? const Color(0xFF7DD3FC)
                : const Color(0xFF64748B),
            fontSize: 10.5,
          ),
        ),
        onTap: () {
          setState(() {
            _activeNavIndex = index;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  // ==========================================================================
  // TOP PRIORITY — OVERALL SITUATION CARD (Section 2)
  // ==========================================================================
  Widget _buildTopPrioritySituationCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB91C1C), Color(0xFF991B1B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CmdColors.criticalRed.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 10),
            child: Row(
              children: [
                // Pulsing Alert Badge
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.6),
                            blurRadius: 8 * _pulseAnim.value,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: CmdColors.criticalRed,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _situationStatus,
                            style: const TextStyle(
                              color: CmdColors.criticalRed,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Spacer(),
                const Text(
                  'CURRENT SITUATION',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),

          // Main Headline & Narrative
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🔴 CRITICAL FLOOD RISK',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'River levels are rising rapidly in downstream areas (+18 cm/hr). 3 villages are currently under immediate evacuation priority.',
                  style: TextStyle(
                    color: Color(0xFFFFE4E6),
                    fontSize: 12.5,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Situation Stats Quick Grid (Full width 5-column layout with vertical dividers matching reference design)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(12),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 540;
                if (isCompact) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        SizedBox(width: 95, child: _situationMicroStat('3', 'Villages Evac')),
                        _verticalDivider(),
                        SizedBox(width: 105, child: _situationMicroStat('12,480', 'People at Risk')),
                        _verticalDivider(),
                        SizedBox(width: 95, child: _situationMicroStat('7', 'SOS Active')),
                        _verticalDivider(),
                        SizedBox(width: 100, child: _situationMicroStat('4', 'Roads Blocked')),
                        _verticalDivider(),
                        SizedBox(width: 95, child: _situationMicroStat('2', 'Shelters Full')),
                      ],
                    ),
                  );
                }

                return Row(
                  children: [
                    Expanded(child: _situationMicroStat('3', 'Villages Evac')),
                    _verticalDivider(),
                    Expanded(child: _situationMicroStat('12,480', 'People at Risk')),
                    _verticalDivider(),
                    Expanded(child: _situationMicroStat('7', 'SOS Active')),
                    _verticalDivider(),
                    Expanded(child: _situationMicroStat('4', 'Roads Blocked')),
                    _verticalDivider(),
                    Expanded(child: _situationMicroStat('2', 'Shelters Full')),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Action Buttons: View Critical Areas & Issue Evacuation Order
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: CmdColors.criticalRed,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(
                      Icons.warning_amber_rounded,
                      color: CmdColors.criticalRed,
                      size: 18,
                    ),
                    label: const Text(
                      'VIEW CRITICAL AREAS',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                    onPressed: () {
                      _showCriticalVillagesModal();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.35),
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70, width: 1),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(
                    Icons.campaign_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text(
                    'ISSUE ORDER',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                  onPressed: _showIssueEvacuationDialog,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.white.withValues(alpha: 0.22),
    );
  }

  Widget _situationMicroStat(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFE2E8F0),
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ==========================================================================
  // KEY STATISTICS CARDS (Section 3)
  // ==========================================================================
  Widget _buildKeyStatisticsCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Flexible(
                child: Text(
                  'OPERATIONAL INDICATORS',
                  style: TextStyle(
                    color: CmdColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Updated 1 min ago',
                style: TextStyle(
                  color: CmdColors.textMuted,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _kpiCard(
                  icon: Icons.warning_amber_rounded,
                  iconColor: CmdColors.criticalRed,
                  value: '12,480',
                  label: 'At Risk',
                  badge: '+1.2k 2h',
                  bgColor: CmdColors.redLight,
                  borderColor: const Color(0xFFFEE2E2),
                  onTap: () => setState(() => _activeNavIndex = 2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _kpiCard(
                  icon: Icons.people_alt_rounded,
                  iconColor: CmdColors.primaryBlue,
                  value: '3,820',
                  label: 'Evacuated',
                  badge: '67% Sec A',
                  bgColor: CmdColors.blueLight,
                  borderColor: const Color(0xFFDBEAFE),
                  onTap: () => setState(() => _activeNavIndex = 4),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _kpiCard(
                  icon: Icons.emergency_rounded,
                  iconColor: CmdColors.criticalRed,
                  value: '27',
                  label: 'Active SOS',
                  badge: '8 Critical',
                  bgColor: CmdColors.redLight,
                  borderColor: const Color(0xFFFEE2E2),
                  onTap: () => setState(() => _activeNavIndex = 3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _kpiCard(
                  icon: Icons.night_shelter_rounded,
                  iconColor: CmdColors.safeGreen,
                  value: '18',
                  label: 'Shelters',
                  badge: '2 Near Cap',
                  bgColor: CmdColors.greenLight,
                  borderColor: const Color(0xFFDCFCE7),
                  onTap: () => setState(() => _activeNavIndex = 5),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _kpiCard(
                  icon: Icons.alt_route_rounded,
                  iconColor: CmdColors.warningOrange,
                  value: '12',
                  label: 'Roads Blocked',
                  badge: '3 Bridges',
                  bgColor: CmdColors.orangeLight,
                  borderColor: const Color(0xFFFEF3C7),
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _kpiCard(
                  icon: Icons.health_and_safety_rounded,
                  iconColor: CmdColors.primaryBlue,
                  value: '7',
                  label: 'Teams Active',
                  badge: '3 Standby',
                  bgColor: CmdColors.blueLight,
                  borderColor: const Color(0xFFDBEAFE),
                  onTap: () => setState(() => _activeNavIndex = 3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kpiCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required String badge,
    required Color bgColor,
    required Color borderColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: CmdColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CmdColors.cardBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Icon(icon, color: iconColor, size: 16),
                ),
                const Spacer(),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        color: iconColor,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: CmdColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: CmdColors.textSecondary,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // 60/40 SPLIT: LIVE DISASTER MAP (60%) & 4 ANIMATED PIE CHARTS (40%)
  // ==========================================================================
  Widget _buildMapAndAnalyticsSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 850) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 60% Map Container (Map + Satellite Intelligence Feed)
                  Expanded(
                    flex: 6,
                    child: _buildLiveDisasterMapSection(isEmbedded: true),
                  ),
                  const SizedBox(width: 12),
                  // 40% 4 Pie Charts in 2x2 Grid with matching bottom height
                  Expanded(
                    flex: 4,
                    child: _buildRingChartsOverviewPanel(isFlexible: true),
                  ),
                ],
              ),
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Column(
              children: [
                _buildLiveDisasterMapSection(isEmbedded: true),
                const SizedBox(height: 12),
                _buildRingChartsOverviewPanel(isFlexible: false),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildRingChartsOverviewPanel({bool isFlexible = true}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CmdColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CmdColors.cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: CmdColors.blueLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.donut_large_rounded,
                  color: CmdColors.primaryBlue,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'CRITICAL RESPONSE METRICS',
                  style: TextStyle(
                    color: CmdColors.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: CmdColors.greenLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFDCFCE7)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: CmdColors.safeGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Live Telemetry',
                      style: TextStyle(
                        color: CmdColors.safeGreen,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 2x2 Grid of 4 Animated Ring Charts (2 per line)
          // Row 1 (2 charts)
          if (isFlexible)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: AnimatedRingChart(
                      percentage: 76,
                      title: 'Evacuation Target',
                      centerText: '76%',
                      primaryColor: const Color(0xFF2563EB),
                      icon: Icons.directions_run_rounded,
                      badgeText: 'Active',
                      badgeColor: const Color(0xFF2563EB),
                      metric: '3,820 / 5,000',
                      subInfo: 'Sector A & B Done',
                      chartSize: 100,
                      isExpanded: true,
                      onTap: () => setState(() => _activeNavIndex = 4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AnimatedRingChart(
                      percentage: 85,
                      title: 'Shelter Capacity',
                      centerText: '85%',
                      primaryColor: const Color(0xFFEA580C),
                      icon: Icons.night_shelter_rounded,
                      badgeText: 'Near Cap',
                      badgeColor: const Color(0xFFEA580C),
                      metric: '1,530 / 1,800 Beds',
                      subInfo: '2 Full | 16 Available',
                      chartSize: 100,
                      isExpanded: true,
                      onTap: () => setState(() => _activeNavIndex = 5),
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: AnimatedRingChart(
                    percentage: 76,
                    title: 'Evacuation Target',
                    centerText: '76%',
                    primaryColor: const Color(0xFF2563EB),
                    icon: Icons.directions_run_rounded,
                    badgeText: 'Active',
                    badgeColor: const Color(0xFF2563EB),
                    metric: '3,820 / 5,000',
                    subInfo: 'Sector A & B Done',
                    chartSize: 100,
                    isExpanded: false,
                    onTap: () => setState(() => _activeNavIndex = 4),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AnimatedRingChart(
                    percentage: 85,
                    title: 'Shelter Capacity',
                    centerText: '85%',
                    primaryColor: const Color(0xFFEA580C),
                    icon: Icons.night_shelter_rounded,
                    badgeText: 'Near Cap',
                    badgeColor: const Color(0xFFEA580C),
                    metric: '1,530 / 1,800 Beds',
                    subInfo: '2 Full | 16 Available',
                    chartSize: 100,
                    isExpanded: false,
                    onTap: () => setState(() => _activeNavIndex = 5),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 10),

          // Row 2 (2 charts)
          if (isFlexible)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: AnimatedRingChart(
                      percentage: 70,
                      title: 'SOS Resolution',
                      centerText: '70%',
                      primaryColor: const Color(0xFFDC2626),
                      icon: Icons.emergency_rounded,
                      badgeText: '8 Pending',
                      badgeColor: const Color(0xFFDC2626),
                      metric: '19 / 27 Dispatched',
                      subInfo: '7 Teams On-Site',
                      chartSize: 100,
                      isExpanded: true,
                      onTap: () => setState(() => _activeNavIndex = 3),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AnimatedRingChart(
                      percentage: 92,
                      title: 'Relief Readiness',
                      centerText: '92%',
                      primaryColor: const Color(0xFF16A34A),
                      icon: Icons.inventory_2_rounded,
                      badgeText: '48h Safe',
                      badgeColor: const Color(0xFF16A34A),
                      metric: '11 / 12 Units Ready',
                      subInfo: 'Rations, Kits & Boats',
                      chartSize: 100,
                      isExpanded: true,
                      onTap: () => setState(() => _activeNavIndex = 5),
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: AnimatedRingChart(
                    percentage: 70,
                    title: 'SOS Resolution',
                    centerText: '70%',
                    primaryColor: const Color(0xFFDC2626),
                    icon: Icons.emergency_rounded,
                    badgeText: '8 Pending',
                    badgeColor: const Color(0xFFDC2626),
                    metric: '19 / 27 Dispatched',
                    subInfo: '7 Teams On-Site',
                    chartSize: 100,
                    isExpanded: false,
                    onTap: () => setState(() => _activeNavIndex = 3),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AnimatedRingChart(
                    percentage: 92,
                    title: 'Relief Readiness',
                    centerText: '92%',
                    primaryColor: const Color(0xFF16A34A),
                    icon: Icons.inventory_2_rounded,
                    badgeText: '48h Safe',
                    badgeColor: const Color(0xFF16A34A),
                    metric: '11 / 12 Units Ready',
                    subInfo: 'Rations, Kits & Boats',
                    chartSize: 100,
                    isExpanded: false,
                    onTap: () => setState(() => _activeNavIndex = 5),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ==========================================================================
  // LIVE DISASTER MAP CENTERPIECE (Section 4 & 5)
  // ==========================================================================
  Widget _buildLiveDisasterMapSection({bool isFullScreen = false, bool isEmbedded = false}) {
    return Container(
      margin: (isFullScreen || isEmbedded)
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: CmdColors.cardBg,
        borderRadius: BorderRadius.circular(isFullScreen ? 0 : 16),
        border: isFullScreen
            ? null
            : Border.all(color: CmdColors.cardBorder, width: 1.2),
        boxShadow: isFullScreen
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map Header & Action Bar
          if (!isFullScreen)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.map_rounded,
                    color: CmdColors.deepBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'LIVE DISASTER GIS MAP',
                    style: TextStyle(
                      color: CmdColors.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  // Fullscreen toggle button
                  IconButton(
                    icon: const Icon(
                      Icons.fullscreen_rounded,
                      color: CmdColors.primaryBlue,
                      size: 22,
                    ),
                    onPressed: () => setState(() => _activeNavIndex = 1),
                    tooltip: 'Expand Map',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

          // Layer Toggle Pills (Section 4 left filters)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                _layerToggleChip(
                  '🌊 Flood',
                  _layerFlood,
                  (v) => setState(() => _layerFlood = v),
                ),
                _layerToggleChip(
                  '🌧️ Rainfall',
                  _layerRainfall,
                  (v) => setState(() => _layerRainfall = v),
                ),
                _layerToggleChip(
                  '🌊 River Level',
                  _layerRiver,
                  (v) => setState(() => _layerRiver = v),
                ),
                _layerToggleChip(
                  '🚨 SOS (27)',
                  _layerSos,
                  (v) => setState(() => _layerSos = v),
                ),
                _layerToggleChip(
                  '🏠 Shelters',
                  _layerShelters,
                  (v) => setState(() => _layerShelters = v),
                ),
                _layerToggleChip(
                  '🚒 Rescue Teams',
                  _layerTeams,
                  (v) => setState(() => _layerTeams = v),
                ),
                _layerToggleChip(
                  '🚧 Blocked Roads',
                  _layerRoads,
                  (v) => setState(() => _layerRoads = v),
                ),
                _layerToggleChip(
                  '🏥 Hospitals',
                  _layerHospitals,
                  (v) => setState(() => _layerHospitals = v),
                ),
                _layerToggleChip(
                  '⛰️ Landslide',
                  _layerLandslide,
                  (v) => setState(() => _layerLandslide = v),
                ),
                _layerToggleChip(
                  '🏔️ GLOF',
                  _layerGlof,
                  (v) => setState(() => _layerGlof = v),
                ),
                _layerToggleChip(
                  '🏗️ Dam',
                  _layerDam,
                  (v) => setState(() => _layerDam = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Interactive FlutterMap
          if (isFullScreen)
            Expanded(child: _buildFlutterMapWidget())
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 360,
                width: double.infinity,
                child: _buildFlutterMapWidget(),
              ),
            ),

          // Satellite Intelligence Overlay Card (Section 5)
          if (!isFullScreen) _buildSatelliteIntelligenceBar(),
        ],
      ),
    );
  }

  Widget _layerToggleChip(String label, bool active, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        selected: active,
        label: Text(label),
        labelStyle: TextStyle(
          color: active ? Colors.white : CmdColors.textSecondary,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
        selectedColor: CmdColors.deepBlue,
        backgroundColor: CmdColors.bg,
        checkmarkColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: active ? CmdColors.deepBlue : CmdColors.cardBorder,
            width: 1,
          ),
        ),
        onSelected: onChanged,
      ),
    );
  }

  Widget _buildFlutterMapWidget() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _centerCoords,
            initialZoom: 11.2,
            minZoom: 6.0,
            maxZoom: 17.0,
          ),
          children: [
            // Standard Base OpenStreetMap Tiles
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.resqshield.app',
            ),

            // Flood Inundation Polygon Overlays (Section 4)
            if (_layerFlood)
              PolygonLayer(
                polygons: [
                  // Mawphlang River Inundation Area
                  Polygon(
                    points: const [
                      LatLng(25.4450, 91.7480),
                      LatLng(25.4600, 91.7530),
                      LatLng(25.4680, 91.7700),
                      LatLng(25.4520, 91.7820),
                      LatLng(25.4380, 91.7650),
                    ],
                    color: CmdColors.criticalRed.withValues(alpha: 0.35),
                    borderColor: CmdColors.criticalRed,
                    borderStrokeWidth: 2.2,
                  ),
                  // Umiam Basin High Water Spread
                  Polygon(
                    points: const [
                      LatLng(25.6500, 91.8700),
                      LatLng(25.6700, 91.8900),
                      LatLng(25.6600, 91.9200),
                      LatLng(25.6350, 91.9050),
                    ],
                    color: CmdColors.warningOrange.withValues(alpha: 0.32),
                    borderColor: CmdColors.warningOrange,
                    borderStrokeWidth: 1.8,
                  ),
                ],
              ),

            // Evacuation Routes Polylines (Section 21)
            if (_layerRoads)
              PolylineLayer(
                polylines: [
                  // Route A (Safe Recommended - Green)
                  Polyline(
                    points: const [
                      LatLng(25.4512, 91.7589),
                      LatLng(25.4720, 91.7750),
                      LatLng(25.4950, 91.8000),
                      LatLng(25.5650, 91.8820),
                    ],
                    color: CmdColors.safeGreen,
                    strokeWidth: 4.0,
                  ),
                  // Route C (Flooded Blocked - Red dashed feel)
                  Polyline(
                    points: const [
                      LatLng(25.4512, 91.7589),
                      LatLng(25.4300, 91.7400),
                      LatLng(25.4120, 91.7100),
                    ],
                    color: CmdColors.criticalRed,
                    strokeWidth: 3.5,
                  ),
                ],
              ),

            // Markers Layer (SOS, Shelters, Teams, Hazards)
            MarkerLayer(
              markers: [
                // 1. Critical SOS Markers
                if (_layerSos)
                  ..._sosList
                      .where((s) => s.status != 'Resolved')
                      .map(
                        (sos) => Marker(
                          point: sos.coords,
                          width: 44,
                          height: 44,
                          child: GestureDetector(
                            onTap: () => _showSosDetailSheet(sos),
                            child: AnimatedBuilder(
                              animation: _pulseAnim,
                              builder: (context, child) {
                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 40 * _pulseAnim.value,
                                      height: 40 * _pulseAnim.value,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: CmdColors.criticalRed.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: const BoxDecoration(
                                        color: CmdColors.criticalRed,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.emergency_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                // 2. Shelter Markers
                if (_layerShelters)
                  ..._shelters.map(
                    (sh) => Marker(
                      point: sh.coords,
                      width: 38,
                      height: 38,
                      child: GestureDetector(
                        onTap: () => _showShelterDetailSheet(sh),
                        child: Container(
                          decoration: BoxDecoration(
                            color: sh.statusColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [
                              BoxShadow(color: Colors.black38, blurRadius: 4),
                            ],
                          ),
                          child: const Icon(
                            Icons.night_shelter_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),

                // 3. Rescue Team Markers
                if (_layerTeams)
                  Marker(
                    point: const LatLng(25.4800, 91.7700),
                    width: 36,
                    height: 36,
                    child: Container(
                      decoration: BoxDecoration(
                        color: CmdColors.deepBlue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.directions_boat_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),

                // 4. Blocked Bridge Marker
                if (_layerRoads)
                  Marker(
                    point: const LatLng(25.4120, 91.7912),
                    width: 34,
                    height: 34,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: CmdColors.warningOrange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.do_not_disturb_on_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),

        // Floating Map Controls (Zoom, Re-center, Legend)
        Positioned(
          top: 10,
          right: 10,
          child: Column(
            children: [
              _mapActionButton(
                icon: Icons.add,
                onPressed: () {
                  final zoom = _mapController.camera.zoom + 1;
                  _mapController.move(_mapController.camera.center, zoom);
                },
              ),
              const SizedBox(height: 6),
              _mapActionButton(
                icon: Icons.remove,
                onPressed: () {
                  final zoom = _mapController.camera.zoom - 1;
                  _mapController.move(_mapController.camera.center, zoom);
                },
              ),
              const SizedBox(height: 6),
              _mapActionButton(
                icon: Icons.my_location_rounded,
                onPressed: () {
                  _mapController.move(_centerCoords, 11.2);
                },
              ),
            ],
          ),
        ),

        // Map Legend Quick Indicator
        Positioned(
          bottom: 10,
          left: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MapLegendDot(color: CmdColors.criticalRed, label: 'SOS'),
                SizedBox(width: 8),
                _MapLegendDot(color: CmdColors.safeGreen, label: 'Shelter OK'),
                SizedBox(width: 8),
                _MapLegendDot(color: CmdColors.warningOrange, label: 'Near Cap'),
                SizedBox(width: 8),
                _MapLegendDot(color: CmdColors.deepBlue, label: 'Team'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _mapActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: IconButton(
        icon: Icon(icon, color: CmdColors.slateDark, size: 18),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }

  // ==========================================================================
  // SATELLITE ANALYSIS CARD (Section 5)
  // ==========================================================================
  Widget _buildSatelliteIntelligenceBar() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CmdColors.navy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CmdColors.cyanAccent.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.satellite_alt_rounded,
                color: CmdColors.cyanAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'SATELLITE INTELLIGENCE FEED',
                style: TextStyle(
                  color: CmdColors.cyanAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: CmdColors.slateDark,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '14 min ago (Sentinel-1 SAR)',
                  style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 9.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _satMetric('Flood Extent', '+12%', CmdColors.criticalRed),
              _satMetric('Inundated Area', '18.4 km²', Colors.white),
              _satMetric('New Inundation', '2 Villages', CmdColors.warningOrange),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: CmdColors.cyanAccent, width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(
                Icons.radar_rounded,
                color: CmdColors.cyanAccent,
                size: 16,
              ),
              label: const Text(
                'VIEW SATELLITE ANALYSIS',
                style: TextStyle(
                  color: CmdColors.cyanAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              onPressed: _showSatelliteAnalysisModal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _satMetric(String label, String value, Color valColor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: valColor,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // FLOOD / RIVER & RAINFALL MONITORING (Sections 6 & 7)
  // ==========================================================================
  // RIVER & RAINFALL TELEMETRY DUAL CARDS (1 ROW, 2 GRAPHS)
  // ==========================================================================
  Widget _buildRiverAndRainfallSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 850) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: RiverTelemetryCard()),
                SizedBox(width: 14),
                Expanded(child: RainfallTelemetryCard()),
              ],
            ),
          );
        } else {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Column(
              children: [
                RiverTelemetryCard(),
                SizedBox(height: 14),
                RainfallTelemetryCard(),
              ],
            ),
          );
        }
      },
    );
  }

  // ==========================================================================
  // AI RISK ENGINE & PRIORITY RANKING (Sections 8, 9, 10)
  // ==========================================================================
  Widget _buildAiRiskAndPrioritySection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CmdColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CmdColors.cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.psychology_rounded,
                  color: Color(0xFF7C3AED),
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI RISK ASSESSMENT & PRIORITY ENGINE',
                      style: TextStyle(
                        color: CmdColors.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                    Text(
                      'Multi-factor decision matrix (Risk + Vulnerability + Access)',
                      style: TextStyle(
                        color: CmdColors.textSecondary,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'CONFIDENCE 87%',
                  style: TextStyle(
                    color: Color(0xFF7C3AED),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // AI Prediction Box (Section 8 - Matching executive screenshot)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF5FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFDDD6FE),
                width: 1.2,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 1250;
                final leftInfo = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.psychology_rounded,
                        color: Color(0xFF7C3AED),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI RISK ASSESSMENT & DECISION SUPPORT',
                          style: TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'High flood probability · Downstream surge detected',
                          style: TextStyle(
                            color: Color(0xFF5B21B6),
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 1),
                        Text(
                          'Multi-factor decision matrix (Risk + Vulnerability + Access)',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                );

                final keyFactors = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Key Factors',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _aiFactorChip(Icons.umbrella_rounded, 'Heavy rainfall'),
                        _aiFactorChip(Icons.water_drop_rounded, 'Rapid river rise (+18cm/hr)'),
                        _aiFactorChip(Icons.satellite_alt_rounded, 'Satellite water spread (+12%)'),
                        _aiFactorChip(Icons.waves_rounded, 'Upstream catchment runoff'),
                      ],
                    ),
                  ],
                );

                final rightBoxes = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFEE2E2)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estimated risk window',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9),
                          ),
                          SizedBox(height: 1),
                          Text(
                            'Next 2 – 4 hours',
                            style: TextStyle(color: Color(0xFFDC2626), fontSize: 13, fontWeight: FontWeight.w900),
                          ),
                          SizedBox(height: 1),
                          Text(
                            'Recommended pre-emptive evacuation',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFDDD6FE)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Confidence',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '87%',
                            style: TextStyle(color: Color(0xFF7C3AED), fontSize: 18, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                  ],
                );

                if (isWide) {
                  return Row(
                    children: [
                      leftInfo,
                      const SizedBox(width: 16),
                      Expanded(child: keyFactors),
                      const SizedBox(width: 12),
                      rightBoxes,
                    ],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      leftInfo,
                      const SizedBox(height: 10),
                      keyFactors,
                      const SizedBox(height: 10),
                      rightBoxes,
                    ],
                  );
                }
              },
            ),
          ),

          const SizedBox(height: 14),

          // Critical Villages Priority List (Section 9 & 10)
          const Text(
            'EVACUATION PRIORITY RANKING',
            style: TextStyle(
              color: CmdColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),

          // Priority 1 — Mawphlang
          _villagePriorityCard(
            rank: '1',
            villageName: 'Mawphlang Sector',
            severity: 'Critical',
            badgeColor: CmdColors.criticalRed,
            priorityScore: '94 / 100',
            population: '2,840',
            vulnerable: '380 (Elderly & Kids)',
            sosCount: '8 SOS',
            roadAccess: 'Road Blocked',
            onView: () {
              _mapController.move(const LatLng(25.4512, 91.7589), 13.5);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Centered on Mawphlang Critical Evacuation Zone'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            onOrderEvac: _showIssueEvacuationDialog,
          ),

          const SizedBox(height: 8),

          // Priority 2 — Village B
          _villagePriorityCard(
            rank: '2',
            villageName: 'Nongstoin Valley Lowland',
            severity: 'High',
            badgeColor: CmdColors.warningOrange,
            priorityScore: '78 / 100',
            population: '1,920',
            vulnerable: '210',
            sosCount: '3 SOS',
            roadAccess: 'Passable (Caution)',
            onView: () {
              _mapController.move(const LatLng(25.5230, 91.2680), 13.0);
            },
          ),

          const SizedBox(height: 8),

          // Priority 3 — Village C
          _villagePriorityCard(
            rank: '3',
            villageName: 'Pynursla Riverbed Basin',
            severity: 'High',
            badgeColor: CmdColors.cautionAmber,
            priorityScore: '65 / 100',
            population: '1,450',
            vulnerable: '160',
            sosCount: '1 SOS',
            roadAccess: 'Open',
            onView: () {
              _mapController.move(const LatLng(25.3094, 91.9022), 13.0);
            },
          ),
        ],
      ),
    );
  }

  Widget _villagePriorityCard({
    required String rank,
    required String villageName,
    required String severity,
    required Color badgeColor,
    required String priorityScore,
    required String population,
    required String vulnerable,
    required String sosCount,
    required String roadAccess,
    VoidCallback? onView,
    VoidCallback? onOrderEvac,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CmdColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CmdColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    'P$rank',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      villageName,
                      style: const TextStyle(
                        color: CmdColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '$population people · Vulnerable: $vulnerable',
                      style: const TextStyle(
                        color: CmdColors.textSecondary,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Score: $priorityScore',
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    roadAccess,
                    style: TextStyle(
                      color: roadAccess.contains('Blocked')
                          ? CmdColors.criticalRed
                          : CmdColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Action Buttons: View on Map & Order Evacuation
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: CmdColors.redLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  sosCount,
                  style: const TextStyle(
                    color: CmdColors.criticalRed,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              if (onView != null)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(50, 28),
                  ),
                  icon: const Icon(
                    Icons.location_searching_rounded,
                    size: 14,
                    color: CmdColors.primaryBlue,
                  ),
                  label: const Text(
                    'VIEW',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: CmdColors.primaryBlue,
                    ),
                  ),
                  onPressed: onView,
                ),
              if (onOrderEvac != null) ...[
                const SizedBox(width: 6),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CmdColors.criticalRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    minimumSize: const Size(60, 28),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: onOrderEvac,
                  child: const Text(
                    'ORDER EVAC',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _aiFactorChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: const Color(0xFF7C3AED)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // POPULATION AT RISK CARD (Section 11)
  // ==========================================================================
  // ==========================================================================
  // POPULATION AT RISK DEMOGRAPHICS (Section 11)
  // ==========================================================================
  Widget _buildPopulationAtRiskSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  color: Color(0xFF0F172A),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Population at Risk Demographics',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Critical population groups that may require prioritized assistance during emergencies',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Total: ',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(
                      text: '12,480',
                      style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Exactly 5 boxes in a single line (ek line mei 5 dabbe)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 960;
              final cards = [
                _popDemographicCard(
                  icon: Icons.groups_rounded,
                  iconColor: const Color(0xFF0284C7),
                  iconBg: const Color(0xFFE0F2FE),
                  cardBg: const Color(0xFFF0F9FF),
                  borderColor: const Color(0xFFBAE6FD),
                  title: 'Children',
                  count: '2,180',
                  countColor: const Color(0xFF0284C7),
                ),
                _popDemographicCard(
                  icon: Icons.elderly_rounded,
                  iconColor: const Color(0xFFDC2626),
                  iconBg: const Color(0xFFFEE2E2),
                  cardBg: const Color(0xFFFEF2F2),
                  borderColor: const Color(0xFFFECACA),
                  title: 'Older Adults',
                  count: '1,420',
                  countColor: const Color(0xFFDC2626),
                ),
                _popDemographicCard(
                  icon: Icons.accessible_rounded,
                  iconColor: const Color(0xFFD97706),
                  iconBg: const Color(0xFFFEF3C7),
                  cardBg: const Color(0xFFFFFBEB),
                  borderColor: const Color(0xFFFDE68A),
                  title: 'Persons with Disabilities',
                  count: '310',
                  countColor: const Color(0xFFD97706),
                ),
                _popDemographicCard(
                  icon: Icons.pregnant_woman_rounded,
                  iconColor: const Color(0xFF9333EA),
                  iconBg: const Color(0xFFF3E8FF),
                  cardBg: const Color(0xFFFAF5FF),
                  borderColor: const Color(0xFFE9D5FF),
                  title: 'Pregnant',
                  count: '95',
                  countColor: const Color(0xFF9333EA),
                ),
                _popDemographicCard(
                  icon: Icons.people_alt_rounded,
                  iconColor: const Color(0xFF0F172A),
                  iconBg: const Color(0xFFE2E8F0),
                  cardBg: const Color(0xFFF8FAFC),
                  borderColor: const Color(0xFFE2E8F0),
                  title: 'General Population',
                  count: '8,475',
                  countColor: const Color(0xFF0F172A),
                ),
              ];

              if (isWide) {
                return Row(
                  children: [
                    for (int i = 0; i < cards.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(child: cards[i]),
                    ],
                  ],
                );
              } else {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (int i = 0; i < cards.length; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        SizedBox(
                          width: i == 2 ? 215 : 185,
                          child: cards[i],
                        ),
                      ],
                    ],
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _popDemographicCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required Color cardBg,
    required Color borderColor,
    required String title,
    required String count,
    required Color countColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF334155),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                Text(
                  count,
                  style: TextStyle(
                    color: countColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // ACTIVE CITIZEN SOS TRIAGE (Section 12)
  // ==========================================================================
  Widget _buildSosManagementSection() {
    final allActive = _sosList.where((s) => s.status != 'Resolved').toList();
    final criticalCount = allActive.where((s) => s.severity == 'Critical').length;

    // Filter by tab and search
    final filteredList = allActive.where((sos) {
      if (_sosFilter == 'Critical' && sos.severity != 'Critical') return false;
      if (_sosFilter == 'Medical' && !sos.medical) return false;
      if (_sosFilter == 'Unassigned' && (sos.assignedTeam != null && sos.assignedTeam!.isNotEmpty)) return false;
      if (_sosSearchQuery.isNotEmpty) {
        final q = _sosSearchQuery.toLowerCase();
        final match = sos.id.toLowerCase().contains(q) ||
            sos.village.toLowerCase().contains(q) ||
            sos.district.toLowerCase().contains(q) ||
            (sos.assignedTeam?.toLowerCase().contains(q) ?? false);
        if (!match) return false;
      }
      return true;
    }).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: Color(0xFFDC2626),
                size: 26,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Citizen SOS Triage',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Real-time citizen distress calls requiring response and support',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Right side badges: 4 Active & 8 Critical
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFEE2E2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDC2626),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${allActive.length} Active',
                      style: const TextStyle(
                        color: Color(0xFFDC2626),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.warning_rounded,
                      color: Color(0xFFDC2626),
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$criticalCount Critical',
                      style: const TextStyle(
                        color: Color(0xFFDC2626),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Search, Filters & Sort Controls Bar
          Row(
            children: [
              // Search input pill
              Expanded(
                flex: 3,
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _sosSearchController,
                          onChanged: (val) {
                            setState(() {
                              _sosSearchQuery = val.trim();
                            });
                          },
                          style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A)),
                          decoration: const InputDecoration(
                            hintText: 'Search by location, ID or keyword...',
                            hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      if (_sosSearchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _sosSearchController.clear();
                            setState(() {
                              _sosSearchQuery = '';
                            });
                          },
                          child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Filter pills
              _filterTabPill('All', isSelected: _sosFilter == 'All'),
              const SizedBox(width: 6),
              _filterTabPill(
                'Critical',
                isSelected: _sosFilter == 'Critical',
                leading: Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 5),
                  decoration: const BoxDecoration(color: Color(0xFFDC2626), shape: BoxShape.circle),
                ),
              ),
              const SizedBox(width: 6),
              _filterTabPill(
                'Medical',
                isSelected: _sosFilter == 'Medical',
                leading: const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(Icons.add, size: 14, color: Color(0xFF0284C7)),
                ),
              ),
              const SizedBox(width: 6),
              _filterTabPill(
                'Unassigned',
                isSelected: _sosFilter == 'Unassigned',
                leading: Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 5),
                  decoration: const BoxDecoration(color: Color(0xFF64748B), shape: BoxShape.circle),
                ),
              ),

              const Spacer(),

              // Sort dropdown pill
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.swap_vert_rounded, size: 16, color: Color(0xFF64748B)),
                    SizedBox(width: 4),
                    Text(
                      'Newest First',
                      style: TextStyle(
                        color: Color(0xFF334155),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Triage Table Grid (Horizontal scrollable for perfect column alignment)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 1405),
              child: Column(
                children: [
                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(width: 55, child: Text('#', style: _tableHeaderStyle)),
                        SizedBox(width: 200, child: Text('Location', style: _tableHeaderStyle)),
                        SizedBox(width: 260, child: Text('Details', style: _tableHeaderStyle)),
                        SizedBox(width: 95, child: Text('Status', style: _tableHeaderStyle)),
                        SizedBox(width: 175, child: Text('Assigned Team', style: _tableHeaderStyle)),
                        SizedBox(width: 100, child: Text('Last Updated', style: _tableHeaderStyle)),
                        SizedBox(width: 520, child: Text('Actions', style: _tableHeaderStyle)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Rows
                  if (filteredList.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      child: const Text(
                        'No citizen SOS calls match the current search / filter.',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    )
                  else
                    ...filteredList.map((sos) => _buildSosTableRow(sos)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),
          // Bottom View All link
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () {
                setState(() {
                  _activeNavIndex = 2; // Jump to dedicated SOS tab
                });
              },
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View All Incidents',
                      style: TextStyle(
                        color: Color(0xFF0284C7),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 15, color: Color(0xFF0284C7)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const TextStyle _tableHeaderStyle = TextStyle(
    color: Color(0xFF475569),
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );

  Widget _filterTabPill(String title, {required bool isSelected, Widget? leading}) {
    return InkWell(
      onTap: () {
        setState(() {
          _sosFilter = title;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ?leading,
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF334155),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSosTableRow(_SosItem sos) {
    final isUnassigned = sos.assignedTeam == null || sos.assignedTeam!.isEmpty || sos.status == 'Unassigned';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isUnassigned ? const Color(0xFFFEF2F2) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUnassigned ? const Color(0xFFFEE2E2) : const Color(0xFFF1F5F9),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          // # ID
          SizedBox(
            width: 55,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                sos.id,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Location
          SizedBox(
            width: 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  sos.village,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  sos.district,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Details
          SizedBox(
            width: 260,
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _detailBadge(
                  icon: Icons.people_alt_rounded,
                  label: '${sos.people} People',
                  bg: const Color(0xFFEFF6FF),
                  color: const Color(0xFF2563EB),
                ),
                if (sos.elderly > 0)
                  _detailBadge(
                    icon: Icons.elderly_rounded,
                    label: '${sos.elderly} Elderly',
                    bg: const Color(0xFFFEF2F2),
                    color: const Color(0xFFDC2626),
                  ),
                if (sos.medical)
                  _detailBadge(
                    icon: Icons.add_circle_outline_rounded,
                    label: 'Medical Urgency',
                    bg: const Color(0xFFFEF2F2),
                    color: const Color(0xFFDC2626),
                  ),
              ],
            ),
          ),

          // Status
          SizedBox(
            width: 95,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFEE2E2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDC2626),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'Active',
                    style: TextStyle(
                      color: Color(0xFFDC2626),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Assigned Team
          SizedBox(
            width: 175,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isUnassigned ? const Color(0xFFF1F5F9) : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isUnassigned ? const Color(0xFFE2E8F0) : const Color(0xFFFEF3C7),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.groups_rounded,
                    size: 14,
                    color: isUnassigned ? const Color(0xFF475569) : const Color(0xFFD97706),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      isUnassigned ? 'Unassigned' : sos.assignedTeam!,
                      style: TextStyle(
                        color: isUnassigned ? const Color(0xFF475569) : const Color(0xFFD97706),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Last Updated
          SizedBox(
            width: 100,
            child: Text(
              sos.timeAgo,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Actions
          SizedBox(
            width: 520,
            child: Row(
              children: [
                _actionBtn(
                  icon: Icons.person_add_alt_1_rounded,
                  label: 'Assign Team',
                  color: const Color(0xFF0284C7),
                  onTap: () => _showAssignTeamModal(sos),
                ),
                const SizedBox(width: 10),
                _actionBtn(
                  icon: Icons.location_on_rounded,
                  label: 'View Location',
                  color: const Color(0xFF0284C7),
                  onTap: () {
                    _mapController.move(sos.coords, 14.0);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Centered map on SOS ${sos.id} (${sos.village})'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 10),
                _actionBtn(
                  icon: Icons.check_circle_rounded,
                  label: 'Resolve',
                  color: const Color(0xFF16A34A),
                  onTap: () => _markSosResolved(sos),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.more_horiz_rounded, size: 18, color: Color(0xFF94A3B8)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'More Details',
                  onPressed: () => _showSosDetailSheet(sos),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailBadge({
    required IconData icon,
    required String label,
    required Color bg,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // RESCUE TEAMS MANAGEMENT (Section 13)
  // ==========================================================================
  Widget _buildRescueTeamsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CmdColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CmdColors.cardBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.sailing_rounded,
                color: CmdColors.deepBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'RESCUE TEAMS DEPLOYMENT',
                style: TextStyle(
                  color: CmdColors.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                '${_rescueTeams.where((t) => t.status == 'Available').length} Available / ${_rescueTeams.length} Total',
                style: const TextStyle(
                  color: CmdColors.safeGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          ..._rescueTeams.map((team) => _rescueTeamTile(team)),
        ],
      ),
    );
  }

  Widget _rescueTeamTile(_RescueTeam team) {
    Color statusColor = CmdColors.safeGreen;
    if (team.status == 'On Mission') statusColor = CmdColors.warningOrange;
    if (team.status == 'Offline') statusColor = CmdColors.criticalRed;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: CmdColors.bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: statusColor.withValues(alpha: 0.15),
            child: Icon(
              Icons.directions_boat_filled_rounded,
              color: statusColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${team.name} (${team.unit})',
                      style: const TextStyle(
                        color: CmdColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        team.status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${team.members} Members · ${team.boats} Boats · ${team.ambulances} Amb · ETA: ${team.eta}',
                  style: const TextStyle(
                    color: CmdColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
                Text(
                  'Mission: ${team.mission}',
                  style: const TextStyle(
                    color: CmdColors.deepBlue,
                    fontSize: 10,
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

  // ==========================================================================
  // EVACUATION MANAGEMENT & ROUTES (Section 14 & 21)
  // ==========================================================================
  Widget _buildEvacuationSection() {
    final double evacProgress = _evacuatedPop / _totalSectorPop;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CmdColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CmdColors.cardBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.departure_board_rounded,
                color: CmdColors.deepBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'EVACUATION MANAGEMENT (SECTOR A)',
                style: TextStyle(
                  color: CmdColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: CmdColors.redLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'ORDER ACTIVE',
                  style: TextStyle(
                    color: CmdColors.criticalRed,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Evacuation Progress Bar
          Row(
            children: [
              Text(
                '${(evacProgress * 100).toInt()}% Evacuated',
                style: const TextStyle(
                  color: CmdColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                '$_evacuatedPop / $_totalSectorPop (Remaining: ${_totalSectorPop - _evacuatedPop})',
                style: const TextStyle(
                  color: CmdColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: evacProgress,
              backgroundColor: CmdColors.bg,
              valueColor: const AlwaysStoppedAnimation<Color>(
                CmdColors.primaryBlue,
              ),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 12),

          // Evacuation Route Status (Section 21)
          const Text(
            'EVACUATION ROUTES STATUS',
            style: TextStyle(
              color: CmdColors.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          _routeItem(
            'Route A → Shelter 01 (Mawphlang North)',
            '🟢 Safe · Recommended (High Ground)',
            CmdColors.safeGreen,
          ),
          const SizedBox(height: 4),
          _routeItem(
            'Route B → Shelter 02 (Valley East)',
            '🟡 Moderate Risk (15cm Waterlogging)',
            CmdColors.cautionAmber,
          ),
          const SizedBox(height: 4),
          _routeItem(
            'Route C → Shelter 03 (River Bridge)',
            '🔴 Flooded · Impassable',
            CmdColors.criticalRed,
          ),

          const SizedBox(height: 12),

          // Actions Row
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CmdColors.deepBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 15),
                  label: const Text(
                    'NOTIFY CITIZENS',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                  onPressed: _showBroadcastAlertModal,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CmdColors.deepBlue,
                    side: const BorderSide(color: CmdColors.deepBlue, width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.navigation_rounded, size: 15),
                  label: const Text(
                    'VIEW SAFE ROUTE',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                  onPressed: () {
                    _mapController.move(const LatLng(25.4720, 91.7750), 12.5);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Displaying Safe Route A on Live Map'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _routeItem(String title, String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: CmdColors.bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: CmdColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // SHELTER, HOSPITAL & RELIEF SECTION (Sections 16, 17, 18, 19, 20)
  // ==========================================================================
  Widget _buildShelterAndReliefSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CmdColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CmdColors.cardBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shelters Header
          Row(
            children: [
              const Icon(
                Icons.night_shelter_rounded,
                color: CmdColors.deepBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'SHELTERS & RELIEF RESOURCES',
                style: TextStyle(
                  color: CmdColors.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              const Text(
                '18 Active Shelters',
                style: TextStyle(
                  color: CmdColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Shelter list items
          ..._shelters.map((sh) => _shelterTile(sh)),

          const Divider(height: 20, color: CmdColors.cardBorder),

          // Relief Supplies Summary (Section 18 & 19)
          const Text(
            'RELIEF INVENTORY & SHORTAGES',
            style: TextStyle(
              color: CmdColors.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              _reliefItem(
                'FOOD MEALS',
                '$_foodAvailable / $_foodRequired',
                '🔴 Shortage: 2,600',
                CmdColors.criticalRed,
              ),
              const SizedBox(width: 8),
              _reliefItem(
                'POTABLE WATER',
                '${(_waterAvailable / 1000).toStringAsFixed(0)}k / ${(_waterRequired / 1000).toStringAsFixed(0)}k L',
                '🟠 Low: 3,000 L',
                CmdColors.warningOrange,
              ),
              const SizedBox(width: 8),
              _reliefItem(
                'MED KITS',
                '$_medKits Kits',
                '🟢 Sufficient',
                CmdColors.safeGreen,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Dispatch Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: CmdColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.local_shipping_rounded, size: 16),
              label: const Text(
                'DISPATCH RELIEF CONVOY TO MAWPHLANG',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
              ),
              onPressed: _showDispatchReliefDialog,
            ),
          ),

          const Divider(height: 20, color: CmdColors.cardBorder),

          // Infrastructure Status (Section 20)
          const Text(
            'CRITICAL INFRASTRUCTURE STATUS',
            style: TextStyle(
              color: CmdColors.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _infraPill('🚧 Roads', '82 Open · 12 Blocked', CmdColors.warningOrange),
              const SizedBox(width: 8),
              _infraPill('🌉 Bridges', '14 Safe · 3 Closed', CmdColors.criticalRed),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _infraPill('⚡ Power', '4 Substations Offline', CmdColors.criticalRed),
              const SizedBox(width: 8),
              _infraPill('📡 Telecom', '7 Towers on Battery', CmdColors.cautionAmber),
            ],
          ),
        ],
      ),
    );
  }

  Widget _shelterTile(_ShelterItem sh) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: CmdColors.bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.home_work_rounded, color: sh.statusColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sh.name,
                  style: const TextStyle(
                    color: CmdColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Food: ${sh.food} · Water: ${sh.water} · Med: ${sh.medical ? "Yes" : "No"}',
                  style: const TextStyle(
                    color: CmdColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${sh.occupied} / ${sh.capacity}',
                style: TextStyle(
                  color: sh.statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                sh.status,
                style: TextStyle(
                  color: sh.statusColor,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reliefItem(String title, String val, String status, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: CmdColors.bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: CmdColors.textMuted, fontSize: 9),
            ),
            const SizedBox(height: 2),
            Text(
              val,
              style: const TextStyle(
                color: CmdColors.textPrimary,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              status,
              style: TextStyle(
                color: color,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infraPill(String title, String val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: CmdColors.bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: CmdColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    val,
                    style: TextStyle(
                      color: color,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
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

  // ==========================================================================
  // SITREP GENERATOR & AUDIT LOG BAR (Sections 28 & 29)
  // ==========================================================================
  Widget _buildSitrepAndAuditSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CmdColors.navy,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.description_rounded,
                color: CmdColors.cyanAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'DISASTER OPERATIONS SITREP',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: CmdColors.cyanAccent,
                  foregroundColor: CmdColors.navy,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.print_rounded, size: 15),
                label: const Text(
                  'GENERATE SITREP',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                ),
                onPressed: _showSitrepModal,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'LATEST ACTION AUDIT LOG',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          ..._actionLogs.take(3).map(
                (log) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '• ',
                        style: TextStyle(color: CmdColors.cyanAccent),
                      ),
                      Expanded(
                        child: Text(
                          log,
                          style: const TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  // ==========================================================================
  // MAIN BODY ROUTER BASED ON NAVIGATION INDEX
  // ==========================================================================
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleLogout();
      },
      child: Scaffold(
        backgroundColor: CmdColors.bg,
        appBar: _buildTopBar(),
        drawer: _buildDrawer(),
        body: _buildCurrentView(),
        bottomNavigationBar: _buildBottomCommandBar(),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_activeNavIndex) {
      case 1:
        // Fullscreen Disaster Map View
        return _buildLiveDisasterMapSection(isFullScreen: true);
      case 2:
        // SOS & Incident Management Dedicated View
        return SingleChildScrollView(
          child: Column(
            children: [
              _buildSosManagementSection(),
              _buildRescueTeamsSection(),
              _buildIncidentTimelineSection(),
            ],
          ),
        );
      case 3:
        // Evacuation & Teams Dedicated View
        return SingleChildScrollView(
          child: Column(
            children: [
              _buildEvacuationSection(),
              _buildRescueTeamsSection(),
              _buildAiRiskAndPrioritySection(),
            ],
          ),
        );
      case 4:
        // Shelters, Medical & Relief Dedicated View
        return SingleChildScrollView(
          child: Column(
            children: [
              _buildShelterAndReliefSection(),
              _buildHospitalSection(),
            ],
          ),
        );
      case 5:
        // Broadcast Alert Screen launcher
        return _buildBroadcastTab();
      case 6:
        // SITREP & Reports Tab
        return _buildSitrepTab();
      case 7:
        // Full Action Audit Log
        return _buildAuditLogTab();
      case 0:
      default:
        // Home Overview Command Dashboard (All 30 Sections integrated)
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopPrioritySituationCard(),
              _buildKeyStatisticsCards(),
              _buildMapAndAnalyticsSection(),
              _buildRiverAndRainfallSection(),
              _buildAiRiskAndPrioritySection(),
              _buildPopulationAtRiskSection(),
              _buildSosManagementSection(),
              _buildRescueTeamsSection(),
              _buildEvacuationSection(),
              _buildShelterAndReliefSection(),
              _buildSitrepAndAuditSection(),
            ],
          ),
        );
    }
  }

  // ==========================================================================
  // BOTTOM NAVIGATION BAR
  // ==========================================================================
  Widget _buildBottomCommandBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: CmdColors.cardBorder, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _activeNavIndex > 4 ? 0 : _activeNavIndex,
        onTap: (index) => setState(() => _activeNavIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: CmdColors.deepBlue,
        unselectedItemColor: CmdColors.textMuted,
        selectedLabelStyle: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Command',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_rounded),
            label: 'GIS Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emergency_rounded),
            label: 'SOS (27)',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.departure_board_rounded),
            label: 'Evacuation',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.night_shelter_rounded),
            label: 'Shelters',
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // INCIDENT TIMELINE SECTION (Section 26)
  // ==========================================================================
  Widget _buildIncidentTimelineSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CmdColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CmdColors.cardBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.assignment_late_rounded,
                color: CmdColors.deepBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'INCIDENT LOG: INC-2026-042',
                style: TextStyle(
                  color: CmdColors.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: CmdColors.orangeLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'STATUS: ACTIVE',
                  style: TextStyle(
                    color: CmdColors.warningOrange,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _timelineRow('18:42', 'Flash Flood detected in Mawphlang Sector', true),
          _timelineRow('18:50', 'Warning Level 2 issued across SMS & Sirens', true),
          _timelineRow('19:02', 'Sector A evacuation commenced via Route A', true),
          _timelineRow('19:18', 'Team 02 deployed with 3 inflatable boats', true),
          _timelineRow('19:32', '420 citizens evacuated to Shelter 01', false),
        ],
      ),
    );
  }

  Widget _timelineRow(String time, String desc, bool hasLine) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: CmdColors.primaryBlue,
                shape: BoxShape.circle,
              ),
            ),
            if (hasLine)
              Container(
                width: 2,
                height: 24,
                color: CmdColors.cardBorder,
              ),
          ],
        ),
        const SizedBox(width: 10),
        Text(
          time,
          style: const TextStyle(
            color: CmdColors.primaryBlue,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            desc,
            style: const TextStyle(
              color: CmdColors.textPrimary,
              fontSize: 11.5,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // HOSPITAL MANAGEMENT (Section 17)
  // ==========================================================================
  Widget _buildHospitalSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CmdColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CmdColors.cardBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HOSPITAL & TRAUMA NETWORK',
            style: TextStyle(
              color: CmdColors.textPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          _hospitalCard(
            'District Civil Hospital (Shillong)',
            'Operational',
            CmdColors.safeGreen,
            '42 Available',
            '6 Available',
            '2 Ready',
          ),
          const SizedBox(height: 8),
          _hospitalCard(
            'Bethany Trauma Center',
            'Overloaded · Rerouting',
            CmdColors.criticalRed,
            '0 Beds',
            '0 ICU',
            '0 Ready',
          ),
        ],
      ),
    );
  }

  Widget _hospitalCard(
    String name,
    String status,
    Color statusColor,
    String beds,
    String icu,
    String amb,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: CmdColors.bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: CmdColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'Beds: $beds · ICU: $icu · Ambulances: $amb',
                style: const TextStyle(
                  color: CmdColors.textSecondary,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // DEDICATED TABS (Broadcast, SITREP, Audit)
  // ==========================================================================
  Widget _buildBroadcastTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'EMERGENCY BROADCAST CONSOLE',
            style: TextStyle(
              color: CmdColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Direct authorization to dispatch Siren, App Alert, and Cell Broadcast SMS across affected districts.',
            style: TextStyle(color: CmdColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: CmdColors.criticalRed,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.campaign_rounded),
            label: const Text(
              'OPEN ALERT DISPATCH CONSOLE',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AlertDispatchScreen(
                    preselectedVillage: 'Mawphlang',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSitrepTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DISTRICT DISASTER OPERATIONS SITREP',
            style: TextStyle(
              color: CmdColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Generate formal situation reports for State Disaster Management Authority (SDMA) and National Disaster Response Force (NDRF).',
            style: TextStyle(color: CmdColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: CmdColors.deepBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.print_rounded),
            label: const Text(
              'GENERATE & PREVIEW SITREP REPORT',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            onPressed: _showSitrepModal,
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLogTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: _actionLogs.length,
      itemBuilder: (context, idx) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CmdColors.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: CmdColors.cardBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.verified_user_rounded,
                color: CmdColors.primaryBlue,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _actionLogs[idx],
                  style: const TextStyle(
                    color: CmdColors.textPrimary,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================================
  // INTERACTIVE MODALS & DIALOGS
  // ==========================================================================

  void _showJurisdictionPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: CmdColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SELECT JURISDICTION COMMAND',
                style: TextStyle(
                  color: CmdColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(
                  Icons.account_balance_rounded,
                  color: CmdColors.deepBlue,
                ),
                title: const Text('Meghalaya State HQ (All Districts)'),
                onTap: () {
                  setState(() {
                    _selectedState = 'Meghalaya';
                    _selectedDistrict = 'State Disaster HQ';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.location_city_rounded,
                  color: CmdColors.primaryBlue,
                ),
                title: const Text('East Khasi Hills District'),
                subtitle: const Text('Active Flood Alert Zone'),
                trailing: const Icon(Icons.check_circle, color: CmdColors.safeGreen),
                onTap: () {
                  setState(() {
                    _selectedDistrict = 'East Khasi Hills District';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.place_rounded),
                title: const Text('West Khasi Hills'),
                onTap: () {
                  setState(() {
                    _selectedDistrict = 'West Khasi Hills';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.place_rounded),
                title: const Text('Ri-Bhoi District'),
                onTap: () {
                  setState(() {
                    _selectedDistrict = 'Ri-Bhoi District';
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: CmdColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.notifications_active_rounded,
                    color: CmdColors.criticalRed,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '7 CRITICAL NOTIFICATIONS',
                    style: TextStyle(
                      color: CmdColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              _notificationItem('🔴 3 SOS requests unassigned in Mawphlang Sector', '2 min ago'),
              _notificationItem('🟠 River Umiam rate of rise increased to +18 cm/hr', '6 min ago'),
              _notificationItem('🚧 Main Valley Bridge closed due to water overflow', '12 min ago'),
              _notificationItem('🏠 St. Anthony Relief Hall reached 92% capacity', '18 min ago'),
            ],
          ),
        );
      },
    );
  }

  Widget _notificationItem(String text, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: CmdColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            time,
            style: const TextStyle(color: CmdColors.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  void _showOfficerProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: CmdColors.deepBlue,
              child: Icon(Icons.person, color: Colors.white),
            ),
            SizedBox(width: 10),
            Text(
              'Officer Profile',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: Capt. R. Sharma'),
            Text('Designation: District Relief Officer'),
            Text('Jurisdiction: East Khasi Hills District'),
            Text('Authorization Level: Level 3 Incident Commander'),
            SizedBox(height: 8),
            Text('Department: State Disaster Management Authority'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCriticalVillagesModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: CmdColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CRITICAL VILLAGES REQUIRING ATTENTION',
              style: TextStyle(
                color: CmdColors.criticalRed,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            _criticalVillageRow('1. Mawphlang', '🔴 Critical', '2,840 people · 8 SOS · Road Blocked'),
            _criticalVillageRow('2. Nongstoin Valley', '🟠 High', '1,920 people · 3 SOS · Road Passable'),
            _criticalVillageRow('3. Pynursla Riverbed', '🟠 High', '1,450 people · 1 SOS · Road Open'),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: CmdColors.criticalRed,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
              ),
              onPressed: () {
                Navigator.pop(context);
                _showIssueEvacuationDialog();
              },
              child: const Text(
                'ISSUE PRIORITY EVACUATION ORDER',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _criticalVillageRow(String name, String level, String details) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
              const Spacer(),
              Text(
                level,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ],
          ),
          Text(
            details,
            style: const TextStyle(color: CmdColors.textSecondary, fontSize: 11),
          ),
          const Divider(height: 12),
        ],
      ),
    );
  }

  void _showSatelliteAnalysisModal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CmdColors.navy,
        title: const Row(
          children: [
            Icon(Icons.satellite_alt_rounded, color: CmdColors.cyanAccent),
            SizedBox(width: 8),
            Text(
              'Satellite SAR Analysis',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sensor: Sentinel-1 C-Band SAR + RISAT-1A', style: TextStyle(color: Color(0xFFCBD5E1))),
            SizedBox(height: 6),
            Text('Observation: 14 min ago (Cloud-penetrating radar)', style: TextStyle(color: Color(0xFFCBD5E1))),
            SizedBox(height: 6),
            Text('Flood Extent Delta: +12% since previous pass (6h)', style: TextStyle(color: CmdColors.criticalRed, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text('Total Inundated Area: 18.4 km²', style: TextStyle(color: Colors.white)),
            SizedBox(height: 6),
            Text('Soil Moisture Saturation: 94% (Near full runoff)', style: TextStyle(color: CmdColors.warningOrange)),
            SizedBox(height: 6),
            Text('Predicted Inundation: 2 Villages downstream within 2h', style: TextStyle(color: Color(0xFFCBD5E1))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: CmdColors.cyanAccent)),
          ),
        ],
      ),
    );
  }

  void _showSosDetailSheet(_SosItem sos) {
    showModalBottomSheet(
      context: context,
      backgroundColor: CmdColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'SOS ${sos.id} — ${sos.village}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
                const Spacer(),
                Text(
                  sos.status,
                  style: TextStyle(
                    color: sos.status == 'Unassigned'
                        ? CmdColors.criticalRed
                        : CmdColors.warningOrange,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Affected: ${sos.people} People (${sos.elderly} Elderly, ${sos.children} Children)'),
            Text('Medical Emergency: ${sos.medical ? "YES - Priority Urgent" : "None reported"}'),
            Text('Received: ${sos.timeAgo}'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CmdColors.deepBlue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _showAssignTeamModal(sos);
                    },
                    child: const Text('Assign Rescue Team'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _markSosResolved(sos);
                  },
                  child: const Text('Resolve'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showShelterDetailSheet(_ShelterItem sh) {
    showModalBottomSheet(
      context: context,
      backgroundColor: CmdColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sh.name,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text('Capacity: ${sh.occupied} / ${sh.capacity} (${sh.capacity - sh.occupied} spots available)'),
            Text('Food Status: ${sh.food}'),
            Text('Water Supply: ${sh.water}'),
            Text('Medical Station: ${sh.medical ? "Active" : "None"}'),
            const SizedBox(height: 14),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: CmdColors.primaryBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 40),
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Rerouted evacuees to ${sh.name}')),
                );
              },
              child: const Text('Reroute Evacuees Here'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignTeamModal(_SosItem sos) {
    showModalBottomSheet(
      context: context,
      backgroundColor: CmdColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ASSIGN TEAM TO SOS ${sos.id}',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
            ),
            const SizedBox(height: 10),
            ..._rescueTeams.map(
              (team) => ListTile(
                leading: Icon(
                  Icons.directions_boat,
                  color: team.status == 'Available'
                      ? CmdColors.safeGreen
                      : CmdColors.warningOrange,
                ),
                title: Text('${team.name} (${team.unit})'),
                subtitle: Text('Status: ${team.status} · ETA: ${team.eta}'),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CmdColors.deepBlue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      sos.status = 'Team Assigned';
                      sos.assignedTeam = '${team.name} (${team.unit})';
                      team.status = 'On Mission';
                      team.mission = 'Assigned to SOS ${sos.id}';
                      _actionLogs.insert(
                        0,
                        '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, "0")} — Assigned ${team.name} to SOS ${sos.id} (${sos.village})',
                      );
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${team.name} assigned to SOS ${sos.id} successfully!',
                        ),
                      ),
                    );
                  },
                  child: const Text('Deploy'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _markSosResolved(_SosItem sos) {
    setState(() {
      sos.status = 'Resolved';
      _actionLogs.insert(
        0,
        '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, "0")} — SOS ${sos.id} resolved by field team',
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('SOS ${sos.id} marked as RESOLVED')),
    );
  }

  void _showIssueEvacuationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.campaign_rounded, color: CmdColors.criticalRed),
            SizedBox(width: 8),
            Text('Issue Evacuation Order'),
          ],
        ),
        content: const Text(
          'Are you sure you want to broadcast an IMMEDIATE LEVEL 3 EVACUATION ORDER for Mawphlang Sector?\n\nThis will trigger sirens, Cell Broadcast SMS, and app notifications to 21,400 registered residents.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: CmdColors.criticalRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _situationStatus = 'CRITICAL';
                _evacuatedPop += 150;
                if (_evacuatedPop > _totalSectorPop) _evacuatedPop = _totalSectorPop;
                _actionLogs.insert(
                  0,
                  '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, "0")} — Level 3 Evacuation Order re-broadcasted for Mawphlang Sector',
                );
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: CmdColors.criticalRed,
                  content: Text(
                    'EVACUATION ORDER BROADCASTED ACROSS ALL CHANNELS!',
                  ),
                ),
              );
            },
            child: const Text('CONFIRM BROADCAST'),
          ),
        ],
      ),
    );
  }

  void _showBroadcastAlertModal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AlertDispatchScreen(
          preselectedVillage: 'Mawphlang',
        ),
      ),
    );
  }

  void _showDispatchReliefDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dispatch Relief Convoy'),
        content: const Text(
          'Confirm dispatching 2,500 food packets and 5,000 L potable water to Mawphlang Sector Staging Center?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: CmdColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _foodAvailable += 2500;
                _waterAvailable += 5000;
                _actionLogs.insert(
                  0,
                  '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, "0")} — Dispatched 2,500 food meals & 5,000L water convoy to Mawphlang',
                );
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Relief Convoy Dispatched to Mawphlang!'),
                ),
              );
            },
            child: const Text('DISPATCH NOW'),
          ),
        ],
      ),
    );
  }

  void _showSitrepModal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.assignment_rounded, color: CmdColors.deepBlue),
            SizedBox(width: 8),
            Text(
              'SITUATION REPORT (SITREP)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'GOVERNMENT OF MEGHALAYA\nDISTRICT DISASTER MANAGEMENT AUTHORITY (DDMA)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              ),
              const Divider(),
              Text('Report ID: SITREP-2026-EKH-09\nDate: ${DateTime.now().toIso8601String().substring(0, 10)} | Time: 19:45 IST'),
              const SizedBox(height: 6),
              const Text('Jurisdiction: East Khasi Hills District\nThreat Level: 🔴 CRITICAL (Level 3 Flash Flood)'),
              const SizedBox(height: 8),
              const Text(
                '1. POPULATION & EVACUATION SUMMARY:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              ),
              Text('• Total At Risk: 12,480 people across 3 villages\n• Evacuated: $_evacuatedPop (67% of Sector A)\n• Remaining: ${_totalSectorPop - _evacuatedPop}\n• Active SOS: ${_sosList.where((s) => s.status != "Resolved").length}'),
              const SizedBox(height: 8),
              const Text(
                '2. OPERATIONAL DEPLOYMENTS:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              ),
              Text('• Rescue Teams Active: ${_rescueTeams.length} (Team 02 deployed to Mawphlang)\n• Shelters Active: ${_shelters.length} (2 near capacity, 1 full)\n• Critical Lifeline: Route A verified operational'),
              const SizedBox(height: 8),
              const Text(
                '3. CRITICAL RELIEF DEFICIT:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              ),
              const Text('• 2,600 Food Meals deficit\n• 3,000 Litres Potable Water deficit within 4 hours'),
              const SizedBox(height: 8),
              const Text(
                '4. ACTIONABLE RECOMMENDATIONS:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              ),
              const Text('• Expedite amphibious craft for 920 citizens in Mawphlang.\n• Reroute incoming evacuees to Northeast Indoor Stadium.\n• Deploy secondary generator to Substation Sector 3.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(
                const ClipboardData(
                  text:
                      'SITREP-2026-EKH-09: 12,480 at risk. 67% evacuated. 7 teams active. 18 shelters. Route A safe.',
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('SITREP copied to clipboard!')),
              );
            },
            child: const Text('Copy SITREP'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: CmdColors.deepBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleLogout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      (route) => false,
    );
  }
}

// ============================================================================
// HELPER WIDGET FOR MAP LEGEND
// ============================================================================
class _MapLegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _MapLegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
