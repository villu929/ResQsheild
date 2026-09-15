import 'dart:async';
import 'dart:math' as math;
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
import 'citizen/citizen_shelters_view.dart';
import 'relief_camp_detail_screen.dart';
import '../models/incident_models.dart';
import '../models/evacuation_models.dart';
import '../services/flood_api_service.dart';
import '../services/resource_api_service.dart';
import '../services/incident_coordinator.dart';
import '../widgets/dos_donts_section.dart';
import '../widgets/role_quick_switcher.dart';

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
  static const Color divider = Color(0xFFE2E8F0);
}

// ============================================================================
// MAIN AUTHORITY COMMAND DASHBOARD SCREEN — (Data models are in incident_models.dart)
// ============================================================================

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
  bool _showAllRescueTeams = false;

  // Pulse animation for critical alerts & pins
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  // Evacuation Sector A progress
  int _evacuatedPop = 1903;
  final int _totalSectorPop = 2840;

  // Operational Lists
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

  StreamSubscription<LiveEvent>? _coordEventSub;

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

    IncidentCoordinator.instance.addListener(_onIncidentCoordUpdate);
    _coordEventSub = IncidentCoordinator.instance.eventStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    IncidentCoordinator.instance.removeListener(_onIncidentCoordUpdate);
    _coordEventSub?.cancel();
    _pulseController.dispose();
    _sosSearchController.dispose();
    super.dispose();
  }

  void _onIncidentCoordUpdate() {
    if (!mounted) return;
    setState(() {});
  }

  void _showCriticalSosPopup(SOSRequest sos) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFDC2626), width: 2),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_rounded,
                  color: Color(0xFFDC2626), size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🔴 NEW CRITICAL SOS ${sos.id}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900),
                  ),
                  Text(
                    'Received ${sos.timeAgoFormatted}',
                    style:
                        const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location: ${sos.village}',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              'Trapped: ${sos.peopleCount} people (${sos.elderlyCount} elderly, ${sos.childrenCount} children)',
              style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              'Medical Urgency: ${sos.hasMedical ? "YES - Critical" : "None reported"}',
              style: TextStyle(
                color: sos.hasMedical
                    ? const Color(0xFFF87171)
                    : const Color(0xFF34D399),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Coordinates: ${sos.coordinatesFormatted}',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _mapController.move(LatLng(sos.latitude, sos.longitude), 14.0);
            },
            child: const Text('View Location',
                style: TextStyle(color: Color(0xFF38BDF8))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              final sosItem = IncidentCoordinator.instance.sosRequests.firstWhere(
                (s) => s.id == sos.id,
                orElse: () => IncidentCoordinator.instance.sosRequests.first,
              );
              _showAssignTeamModal(sosItem);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Assign Team',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

    void _initData() {
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

          // Situation Stats Quick Grid
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
                  onPressed: () => _showIssueEvacuationDialog(context, 'Mawphlang Sector', 2840, 380, '8 SOS', 'Road Blocked', 94),
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
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => _buildAtRiskDetailsScreen(context))),
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
                  onTap: () => setState(() => _activeNavIndex = 10),
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
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CitizenSheltersView(isAuthority: true))),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: const TextStyle(
                        color: CmdColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: CmdColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  color: iconColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
                  Expanded(
                    flex: 6,
                    child: _buildLiveDisasterMapSection(isEmbedded: true),
                  ),
                  const SizedBox(width: 12),
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
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.scrollWheelZoom,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.resqshield.app',
            ),

            if (_layerFlood)
              PolygonLayer(
                polygons: [
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

            if (_layerRoads)
              PolylineLayer(
                polylines: [
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

            MarkerLayer(
              markers: [
                if (_layerSos)
                  ...IncidentCoordinator.instance.sosRequests
                      .where((s) => s.status != IncidentStatus.closed)
                      .map(
                        (sos) => Marker(
                          point: LatLng(sos.latitude, sos.longitude),
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

                if (_layerShelters)
                  ...ResourceApiService.instance.shelters.map(
                    (sh) => Marker(
                      point: LatLng(sh.latitude, sh.longitude),
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

          // AI Prediction Box (Section 8)
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

          // Priority Ranking Section
          _buildPriorityRankingSection(),
        ],
      ),
    );
  }

  Widget _buildPriorityRankingSection() {
    return ListenableBuilder(
      listenable: IncidentCoordinator.instance,
      builder: (context, _) {
        final op = IncidentCoordinator.instance.getEvacuationForArea('Mawphlang Sector');
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 14),
          padding: const EdgeInsets.all(16),
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
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFDC2626),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Evacuation Decision Queue',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          'AI ranked areas requiring immediate attention',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    'JALGUARD • PROTECTING PEOPLE, SAFER TOMORROWS',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Priority 1 — Mawphlang
              _villagePriorityCard(
                rank: '1',
                villageName: 'Mawphlang Sector',
                severity: 'Critical',
                badgeColor: const Color(0xFFDC2626),
                priorityScore: '94 / 100',
                population: '2,840',
                vulnerable: '380 (Elderly & Kids)',
                sosCount: '8 SOS',
                roadAccess: 'Road Blocked',
                activeOp: op,
                onView: () {
                  _mapController.move(const LatLng(25.4512, 91.7589), 13.5);
                },
                onOrderEvac: op == null ? () => _showIssueEvacuationDialog(context, 'Mawphlang Sector', 2840, 380, '8 SOS', 'Road Blocked', 94) : null,
              ),

              const SizedBox(height: 8),

              // Priority 2 — Village B
              _villagePriorityCard(
                rank: '2',
                villageName: 'Nongstoin Valley Lowland',
                severity: 'High',
                badgeColor: const Color(0xFFEA580C),
                priorityScore: '78 / 100',
                population: '1,920',
                vulnerable: '210',
                sosCount: '3 SOS',
                roadAccess: 'Possible (Caution)',
                onView: () {
                  _mapController.move(const LatLng(25.5230, 91.2680), 13.0);
                },
                onOrderEvac: () {},
                actionLabel: 'Prepare',
              ),

              const SizedBox(height: 8),

              // Priority 3 — Village C
              _villagePriorityCard(
                rank: '3',
                villageName: 'Pynursla Riverbed Basin',
                severity: 'High',
                badgeColor: const Color(0xFFD97706),
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
      },
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
    EvacuationOperation? activeOp,
    VoidCallback? onView,
    VoidCallback? onOrderEvac,
    String? actionLabel,
  }) {
    bool isEvacActive = activeOp != null;

    String statusText = '';
    Color statusColor = const Color(0xFF0284C7);
    Color statusBgColor = const Color(0xFF0284C7).withValues(alpha: 0.1);

    if (isEvacActive) {
      final teamStr = activeOp.missions.length == 1 ? activeOp.missions.first.assignedTeam.toUpperCase() : 'MULTIPLE TEAMS';
      if (activeOp.stepIndex == 0) {
        statusText = 'ASSIGNED TO $teamStr';
      } else if (activeOp.stepIndex == 1) {
        statusText = 'ACKNOWLEDGED BY $teamStr';
      } else if (activeOp.stepIndex == 2) {
        statusText = 'EN ROUTE ($teamStr)';
      } else if (activeOp.stepIndex == 3) {
        statusText = 'REACHED SITE ($teamStr)';
      } else if (activeOp.stepIndex == 4) {
        statusText = 'EVACUATING: ${activeOp.evacuatedCount} / ${activeOp.targetPopulation}';
        statusColor = const Color(0xFF9333EA);
        statusBgColor = const Color(0xFF9333EA).withValues(alpha: 0.1);
      } else {
        statusText = 'COMPLETED: ${activeOp.evacuatedCount} EVACUATED';
        statusColor = const Color(0xFF16A34A);
        statusBgColor = const Color(0xFF16A34A).withValues(alpha: 0.1);
      }
    }

    final String scoreStr = priorityScore.split(' ')[0]; // e.g. '94'
    final double scoreVal = double.tryParse(scoreStr) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: badgeColor, width: 4)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. P Badge
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'P$rank',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // 2. Info Block
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      villageName,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.people_alt_rounded, size: 12, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(
                          '$population people',
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text('|', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11)),
                        ),
                        const Icon(Icons.group_rounded, size: 12, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(
                          'Vulnerable: $vulnerable',
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people_alt_rounded, size: 12, color: Color(0xFFDC2626)),
                          const SizedBox(width: 4),
                          Text(
                            sosCount,
                            style: const TextStyle(color: Color(0xFFDC2626), fontSize: 11, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Score Block
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Score',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Text(
                          scoreStr,
                          style: TextStyle(color: badgeColor, fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                        const Text(
                          ' / 100',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: scoreVal / 100,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(badgeColor),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 24),

              // 4. Status Pill
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: roadAccess.contains('Blocked')
                          ? const Color(0xFFFEF2F2)
                          : roadAccess.contains('Caution') || roadAccess.contains('Possible')
                              ? const Color(0xFFFFFBEB)
                              : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          roadAccess.contains('Blocked')
                              ? Icons.block_rounded
                              : roadAccess.contains('Caution') || roadAccess.contains('Possible')
                                  ? Icons.warning_amber_rounded
                                  : Icons.check_circle_rounded,
                          size: 14,
                          color: roadAccess.contains('Blocked')
                              ? const Color(0xFFDC2626)
                              : roadAccess.contains('Caution') || roadAccess.contains('Possible')
                                  ? const Color(0xFFD97706)
                                  : const Color(0xFF16A34A),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          roadAccess,
                          style: TextStyle(
                            color: roadAccess.contains('Blocked')
                                ? const Color(0xFFDC2626)
                                : roadAccess.contains('Caution') || roadAccess.contains('Possible')
                                    ? const Color(0xFFD97706)
                                    : const Color(0xFF16A34A),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 5. Actions
              Expanded(
                flex: 3,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onView != null) ...[
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFEFF6FF),
                          foregroundColor: const Color(0xFF2563EB),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                        label: const Text('View', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                        onPressed: onView,
                      ),
                      const SizedBox(width: 8),
                    ],
                    
                    if (onOrderEvac != null)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: actionLabel != null ? const Color(0xFFEA580C) : const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        icon: Icon(actionLabel != null ? Icons.assignment_rounded : Icons.security_rounded, size: 16),
                        label: Text('${actionLabel ?? 'Order Evac'} →', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                        onPressed: actionLabel == 'Prepare' 
                            ? () {
                                IncidentCoordinator.instance.issuePrepareAlert(villageName);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Prepare Alert sent to Citizens in $villageName!')),
                                );
                              }
                            : onOrderEvac,
                      )
                    else if (isEvacActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w900),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatText(String value, String label) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: '$value ', style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w900)),
          TextSpan(text: label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600)),
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
  Widget _buildSosManagementSection({bool isDashboard = false}) {
    final allActive = IncidentCoordinator.instance.sosRequests.where((s) => s.status != IncidentStatus.closed).toList();
    final criticalCount = allActive.where((s) => s.hasMedical).length;

    // Filter by tab and search
    final filteredList = allActive.where((sos) {
      if (_sosFilter == 'Critical' && !sos.hasMedical) return false;
      if (_sosFilter == 'Medical' && !sos.hasMedical) return false;
      if (_sosFilter == 'Unassigned' && (sos.assignedTeamName != null && sos.assignedTeamName!.isNotEmpty)) return false;
      if (_sosSearchQuery.isNotEmpty) {
        final q = _sosSearchQuery.toLowerCase();
        final match = sos.id.toLowerCase().contains(q) ||
            sos.village.toLowerCase().contains(q) ||
            sos.village.toLowerCase().contains(q) ||
            (sos.assignedTeamName?.toLowerCase().contains(q) ?? false);
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
          LayoutBuilder(
            builder: (context, filterConstraints) {
              final isNarrow = filterConstraints.maxWidth < 850;

              final searchBox = Container(
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
              );

              final filterPills = SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                  ],
                ),
              );

              final sortDropdown = Container(
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
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    searchBox,
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: filterPills),
                        const SizedBox(width: 8),
                        sortDropdown,
                      ],
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(flex: 3, child: searchBox),
                  const SizedBox(width: 10),
                  filterPills,
                  const Spacer(),
                  sortDropdown,
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          // Triage Table Grid (Fills full container width with horizontal scroll safety)
          LayoutBuilder(
            builder: (context, tableConstraints) {
              final availableWidth = tableConstraints.maxWidth;
              final tableWidth = math.max(availableWidth, 1250.0);

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  width: tableWidth,
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
                        child: _buildSosRowContent(
                          id: const Text('#', style: _tableHeaderStyle),
                          location: const Text('Location', style: _tableHeaderStyle),
                          details: const Text('Details', style: _tableHeaderStyle),
                          status: const Text('Status', style: _tableHeaderStyle),
                          team: const Text('Assigned Team', style: _tableHeaderStyle),
                          time: const Text('Last Updated', style: _tableHeaderStyle),
                          actions: const Text('Actions', style: _tableHeaderStyle),
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
                        ...(isDashboard ? filteredList.take(4) : filteredList).map((sos) => _buildSosTableRow(sos)),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 10),
          // Bottom View All link
          if (isDashboard)
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _activeNavIndex = 10; // Jump to dedicated SOS tab
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

  Widget _buildSosRowContent({
    required Widget id,
    required Widget location,
    required Widget details,
    required Widget status,
    required Widget team,
    required Widget time,
    required Widget actions,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: 56, child: id),
        const SizedBox(width: 12),
        Expanded(flex: 18, child: location),
        const SizedBox(width: 12),
        Expanded(flex: 32, child: details),
        const SizedBox(width: 12),
        Expanded(flex: 9, child: status),
        const SizedBox(width: 12),
        Expanded(flex: 15, child: team),
        const SizedBox(width: 12),
        Expanded(flex: 9, child: time),
        const SizedBox(width: 14),
        Expanded(flex: 33, child: actions),
      ],
    );
  }

  Widget _buildSosTableRow(SOSRequest sos) {
    final isUnassigned = sos.assignedTeamId == null || sos.status == IncidentStatus.newSos;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isUnassigned ? const Color(0xFFFFF5F5) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUnassigned ? const Color(0xFFFEE2E2) : const Color(0xFFF1F5F9),
          width: 1.0,
        ),
      ),
      child: _buildSosRowContent(
        id: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              sos.id,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        location: Column(
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
            const Text(
              'East Khasi Hills',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        details: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailBadge(
                icon: Icons.people_alt_rounded,
                label: '${sos.peopleCount} People',
                bg: const Color(0xFFEFF6FF),
                color: const Color(0xFF2563EB),
              ),
              if (sos.elderlyCount > 0) ...[
                const SizedBox(width: 6),
                _detailBadge(
                  icon: Icons.elderly_rounded,
                  label: '${sos.elderlyCount} Elderly',
                  bg: const Color(0xFFFEF2F2),
                  color: const Color(0xFFDC2626),
                ),
              ],
              if (sos.hasMedical) ...[
                const SizedBox(width: 6),
                _detailBadge(
                  icon: Icons.add_circle_outline_rounded,
                  label: 'Medical Urgency',
                  bg: const Color(0xFFFEF2F2),
                  color: const Color(0xFFDC2626),
                ),
              ],
            ],
          ),
        ),
        status: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Container(
          child: _buildDynamicStatusPill(sos.status),
        ),
        ),
        team: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
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
                Text(
                  isUnassigned 
                      ? 'Unassigned' 
                      : (sos.status.index >= IncidentStatus.responderAccepted.index 
                          ? 'Accepted by ${sos.assignedTeamName ?? ''}' 
                          : sos.assignedTeamName ?? ''),
                  style: TextStyle(
                    color: isUnassigned ? const Color(0xFF475569) : const Color(0xFFD97706),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        time: Text(
          sos.timeAgoFormatted,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
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
                  _mapController.move(LatLng(sos.latitude, sos.longitude), 14.0);
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
      ),
    );
  }

  Widget _buildDynamicStatusPill(IncidentStatus status) {
    Color color;
    Color bg;
    String text;

    switch (status) {
      case IncidentStatus.newSos:
        color = const Color(0xFFDC2626);
        bg = const Color(0xFFFEF2F2);
        text = 'Active';
        break;
      case IncidentStatus.authorityAcknowledged:
        color = const Color(0xFFD97706);
        bg = const Color(0xFFFFFBEB);
        text = 'Verifying';
        break;
      case IncidentStatus.teamAssigned:
        color = const Color(0xFF0284C7);
        bg = const Color(0xFFF0F9FF);
        text = 'Assigned';
        break;
      case IncidentStatus.responderAccepted:
        color = const Color(0xFF4F46E5);
        bg = const Color(0xFFEEF2FF);
        text = 'Team Accepted';
        break;
      case IncidentStatus.enRoute:
        color = const Color(0xFF7C3AED);
        bg = const Color(0xFFF5F3FF);
        text = 'En Route';
        break;
      case IncidentStatus.onSite:
        color = const Color(0xFF059669);
        bg = const Color(0xFFECFDF5);
        text = 'On Scene';
        break;
      case IncidentStatus.rescueInProgress:
        color = const Color(0xFFEA580C);
        bg = const Color(0xFFFFF7ED);
        text = 'Extracting';
        break;
      case IncidentStatus.completed:
        color = const Color(0xFF16A34A);
        bg = const Color(0xFFF0FDF4);
        text = 'Resolved';
        break;
      default:
        color = const Color(0xFF64748B);
        bg = const Color(0xFFF8FAFC);
        text = status.name;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            text,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
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
      ),
    );
  }

  // ==========================================================================
  // RESCUE TEAMS MANAGEMENT (Section 13)
  // ==========================================================================
  Widget _buildRescueTeamsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9), // Light grayish blue
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.sailing_rounded,
                    color: Color(0xFF1E293B),
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RESCUE TEAMS DEPLOYMENT',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'On-ground teams and quick response units',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${IncidentCoordinator.instance.responderTeams.where((t) => t.status == 'Available').length} Available',
                style: const TextStyle(
                  color: Color(0xFF16A34A),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                ' / ${IncidentCoordinator.instance.responderTeams.length} Total',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _showAllRescueTeams = !_showAllRescueTeams;
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF007AEB),
                  side: const BorderSide(color: Color(0xFF007AEB), width: 1.2),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _showAllRescueTeams ? 'Show Less' : 'View Teams',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 4),
                    Icon(_showAllRescueTeams ? Icons.keyboard_arrow_up_rounded : Icons.arrow_forward_rounded, size: 14),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              final isMedium = constraints.maxWidth >= 560;
              final display = _showAllRescueTeams 
                  ? IncidentCoordinator.instance.responderTeams
                  : IncidentCoordinator.instance.responderTeams.take(4).toList();

              if (isWide) {
                const spacing = 12.0;
                final cardW = (constraints.maxWidth - spacing * 3) / 4;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: display.map((t) => SizedBox(width: cardW, child: _rescueTeamTile(t))).toList(),
                );
              } else if (isMedium) {
                const spacing = 10.0;
                final cardW = (constraints.maxWidth - spacing) / 2;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: display.map((t) => SizedBox(width: cardW, child: _rescueTeamTile(t))).toList(),
                );
              } else {
                return Column(
                  children: display.map((t) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _rescueTeamTile(t))).toList(),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _rescueTeamTile(ResponderTeamLocation team) {
    Color statusColor = const Color(0xFF16A34A);
    Color statusBg = const Color(0xFFDCFCE7);
    if (team.status == 'On Mission') {
      statusColor = const Color(0xFFD97706);
      statusBg = const Color(0xFFFEF3C7);
    }
    if (team.status == 'Offline') {
      statusColor = const Color(0xFFDC2626);
      statusBg = const Color(0xFFFEE2E2);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusBg, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: statusBg,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.sailing_rounded,
                    color: statusColor,
                    size: 19,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.name,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '(${team.unit})',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  team.status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            children: [
              _buildTeamStatItem(Icons.people_alt_rounded, '${team.membersCount} Members'),
              _buildTeamStatItem(Icons.directions_boat_filled_rounded, '${team.boatCount} Boats'),
              _buildTeamStatItem(Icons.local_shipping_rounded, '${team.ambulanceCount} Amb'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, color: Color(0xFF64748B), size: 14),
              const SizedBox(width: 6),
              Text(
                'ETA: ${team.etaEstimate}',
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: Color(0xFFE2E8F0), height: 1),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.my_location_rounded, color: Color(0xFF64748B), size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                    children: [
                      const TextSpan(text: 'Mission: '),
                      TextSpan(
                        text: team.currentMissionId ?? "Standby",
                        style: const TextStyle(
                          color: Color(0xFF007AEB),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamStatItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF64748B), size: 14),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF475569),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // 14 & 21. MODERN EVACUATION MANAGEMENT & ROUTES (MATCHING SCREENSHOT)
  // ==========================================================================
  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  Widget _buildEvacuationSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        if (isWide) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 11,
                  child: _buildEvacuationManagementCard(),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 9,
                  child: _buildEvacuationRoutesCard(),
                ),
              ],
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEvacuationManagementCard(),
                const SizedBox(height: 12),
                _buildEvacuationRoutesCard(),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildEvacuationManagementCard() {
    final double evacProgress = (_evacuatedPop / _totalSectorPop).clamp(0.0, 1.0);
    final int remainingPop = _totalSectorPop - _evacuatedPop;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
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
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFE0F2FE),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.groups_rounded,
                    color: Color(0xFF0284C7),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'EVACUATION MANAGEMENT (SECTOR A)',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Overall progress of evacuation and relief operations',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFECACA), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.notifications_active_rounded,
                      color: Color(0xFFDC2626),
                      size: 13,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'HIGH PRIORITY',
                      style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Progress Header: "67% Evacuated" and "1,903 / 2,840" "Remaining: 937"
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(evacProgress * 100).toInt()}% Evacuated',
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 15.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_formatNumber(_evacuatedPop)} / ${_formatNumber(_totalSectorPop)}',
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Remaining: ${_formatNumber(remainingPop)}',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Sleek Rounded Progress Bar
          Container(
            height: 10,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: evacProgress,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 4 Metric Tiles below progress bar
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 460;
              final tile1 = _buildEvacStatTile(
                icon: Icons.groups_rounded,
                iconColor: const Color(0xFF10B981),
                iconBgColor: const Color(0xFFECFDF5),
                title: 'People Evacuated',
                value: _formatNumber(_evacuatedPop),
                subtext: '↑ +12% from last hour',
                subtextColor: const Color(0xFF10B981),
              );
              final tile2 = _buildEvacStatTile(
                icon: Icons.person_rounded,
                iconColor: const Color(0xFFF97316),
                iconBgColor: const Color(0xFFFFF7ED),
                title: 'People Remaining',
                value: _formatNumber(remainingPop),
                subtext: '↓ -8% from last hour',
                subtextColor: const Color(0xFFEA580C),
              );
              final tile3 = _buildEvacStatTile(
                icon: Icons.flag_rounded,
                iconColor: const Color(0xFF8B5CF6),
                iconBgColor: const Color(0xFFF5F3FF),
                title: 'Total Capacity',
                value: _formatNumber(_totalSectorPop),
                subtext: '',
                subtextColor: Colors.transparent,
              );
              final tile4 = _buildEvacStatTile(
                icon: Icons.apartment_rounded,
                iconColor: const Color(0xFF3B82F6),
                iconBgColor: const Color(0xFFEFF6FF),
                title: 'Sectors Covered',
                value: '3 / 5',
                subtext: 'Sector A - In Progress',
                subtextColor: const Color(0xFF2563EB),
              );

              if (compact) {
                return Column(
                  children: [
                    Row(children: [Expanded(child: tile1), const SizedBox(width: 8), Expanded(child: tile2)]),
                    const SizedBox(height: 8),
                    Row(children: [Expanded(child: tile3), const SizedBox(width: 8), Expanded(child: tile4)]),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: tile1),
                  const SizedBox(width: 8),
                  Expanded(child: tile2),
                  const SizedBox(width: 8),
                  Expanded(child: tile3),
                  const SizedBox(width: 8),
                  Expanded(child: tile4),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEvacStatTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String value,
    required String subtext,
    required Color subtextColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(icon, color: iconColor, size: 16),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (subtext.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtext,
              style: TextStyle(
                color: subtextColor,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ] else ...[
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }

  Widget _buildEvacuationRoutesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFE0F2FE),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.alt_route_rounded,
                    color: Color(0xFF0284C7),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'EVACUATION ROUTES STATUS',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: () {
                  _mapController.move(const LatLng(25.4720, 91.7750), 12.5);
                  setState(() => _activeNavIndex = 1);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBAE6FD), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'View on Map',
                        style: TextStyle(
                          color: Color(0xFF0284C7),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Color(0xFF0284C7),
                        size: 13,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 3 Route Items
          _buildModernRouteItem(
            name: 'Route A  —  Shelter 1 (Nearbying Kott)',
            dotColor: const Color(0xFF16A34A),
            badgeText: 'Safe',
            badgeTextColor: const Color(0xFF15803D),
            badgeBgColor: const Color(0xFFECFDF5),
            badgeBorderColor: const Color(0xFFA7F3D0),
            tagText: 'Recommended >',
            tagColor: const Color(0xFF15803D),
          ),
          const SizedBox(height: 8),
          _buildModernRouteItem(
            name: 'Route B  —  Shelter 2 (Valley East)',
            dotColor: const Color(0xFFF59E0B),
            badgeText: 'Moderate Risk',
            badgeTextColor: const Color(0xFFB45309),
            badgeBgColor: const Color(0xFFFFFBEB),
            badgeBorderColor: const Color(0xFFFDE68A),
            tagText: 'Use with Caution >',
            tagColor: const Color(0xFFB45309),
          ),
          const SizedBox(height: 8),
          _buildModernRouteItem(
            name: 'Route C  —  Shelter 3 (River Bridge)',
            dotColor: const Color(0xFFEF4444),
            badgeText: 'Blocked',
            badgeTextColor: const Color(0xFFDC2626),
            badgeBgColor: const Color(0xFFFEF2F2),
            badgeBorderColor: const Color(0xFFFECACA),
            tagText: 'Impassable >',
            tagColor: const Color(0xFFDC2626),
          ),

          const SizedBox(height: 16),

          // 2 Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A3981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.send_rounded, size: 15, color: Colors.white),
                  label: const Text(
                    'NOTIFY CITIZENS',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  onPressed: _showBroadcastAlertModal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0A3981),
                    side: const BorderSide(color: Color(0xFF0A3981), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.map_rounded, size: 15, color: Color(0xFF0A3981)),
                  label: const Text(
                    'VIEW SAFE ROUTE',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
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

  Widget _buildModernRouteItem({
    required String name,
    required Color dotColor,
    required String badgeText,
    required Color badgeTextColor,
    required Color badgeBgColor,
    required Color badgeBorderColor,
    required String tagText,
    required Color tagColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeBgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: badgeBorderColor, width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: badgeTextColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeTextColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            tagText,
            style: TextStyle(
              color: tagColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // 16-20. MODERN SHELTERS & RELIEF RESOURCES (MATCHING SCREENSHOT)
  // ==========================================================================
  Widget _buildShelterAndReliefSection() {
    final liveShelters = ResourceApiService.instance.shelters;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Shelters Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFFE0F2FE),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.night_shelter_rounded,
                    color: Color(0xFF007AEB),
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SHELTERS & RELIEF RESOURCES',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: const [
                        Text(
                          '18 Active Shelters',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '  •  Total Capacity: 2,150  •  Occupied: 1,374 (64%)',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ResourceShelterMapScreen(initialTabIndex: 1),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AEB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text(
                  'Add Shelter',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CitizenSheltersView(isAuthority: true),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF007AEB),
                  side: const BorderSide(color: Color(0xFF007AEB), width: 1.2),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'View All',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 14),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 2. Metrics Summary Row (Matching Screenshot)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 950;
              return _buildShelterMetricsRow(isWide);
            },
          ),

          const SizedBox(height: 16),

          // 3. Shelter Cards — fixed single row of exactly 4
          LayoutBuilder(
            builder: (context, constraints) {
              final show4 = constraints.maxWidth >= 900;
              final show2 = constraints.maxWidth >= 560;
              // Show the 4 primary display shelters — rest visible via View All
              const _primaryIds = {'SH-06', 'SH-07', 'SH-08', 'SH-09'};
              final display = liveShelters.where((s) => _primaryIds.contains(s.id)).take(4).toList();

              if (show4) {
                // Single row: 4 equal-width cards
                const spacing = 12.0;
                final cardW = (constraints.maxWidth - spacing * 3) / 4;
                return Row(
                  children: [
                    for (int i = 0; i < display.length; i++) ...[
                      if (i > 0) const SizedBox(width: spacing),
                      SizedBox(width: cardW, child: _buildModernShelterCard(display[i])),
                    ],
                  ],
                );
              } else if (show2) {
                const spacing = 10.0;
                final cardW = (constraints.maxWidth - spacing) / 2;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: display.map((s) => SizedBox(width: cardW, child: _buildModernShelterCard(s))).toList(),
                );
              } else {
                return Column(
                  children: display
                      .map((s) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _buildModernShelterCard(s)))
                      .toList(),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShelterMetricsRow(bool isWide) {
    // 6 equal-width metric tiles dividing full screen width
    Widget _metricTile({
      required IconData icon,
      required Color iconColor,
      required Color iconBg,
      required Color cardBg,
      required Color borderColor,
      required String number,
      required String title,
      required String subtitle,
      required Color subColor,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: borderColor, width: 1.1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                  child: Center(child: Icon(icon, color: iconColor, size: 16)),
                ),
                const SizedBox(width: 6),
                Text(
                  number,
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: subColor,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    const gap = SizedBox(width: 8);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _metricTile(
              icon: Icons.night_shelter_rounded,
              iconColor: const Color(0xFF16A34A),
              iconBg: const Color(0xFFDCFCE7),
              cardBg: const Color(0xFFF2FBF5),
              borderColor: const Color(0xFFDCFCE7),
              number: '14',
              title: 'Available',
              subtitle: '≥ 30% space',
              subColor: const Color(0xFF16A34A),
            ),
          ),
          gap,
          Expanded(
            child: _metricTile(
              icon: Icons.people_alt_rounded,
              iconColor: const Color(0xFFD97706),
              iconBg: const Color(0xFFFEF3C7),
              cardBg: const Color(0xFFFFFDF5),
              borderColor: const Color(0xFFFEF3C7),
              number: '3',
              title: 'Near Cap.',
              subtitle: '≤ 30% space',
              subColor: const Color(0xFFD97706),
            ),
          ),
          gap,
          Expanded(
            child: _metricTile(
              icon: Icons.warning_rounded,
              iconColor: const Color(0xFFDC2626),
              iconBg: const Color(0xFFFEE2E2),
              cardBg: const Color(0xFFFEF5F5),
              borderColor: const Color(0xFFFEE2E2),
              number: '1',
              title: 'At Limit',
              subtitle: 'No space',
              subColor: const Color(0xFFDC2626),
            ),
          ),
          gap,
          Expanded(
            child: _metricTile(
              icon: Icons.restaurant_rounded,
              iconColor: const Color(0xFF16A34A),
              iconBg: const Color(0xFFDCFCE7),
              cardBg: const Color(0xFFF2FBF5),
              borderColor: const Color(0xFFDCFCE7),
              number: '2',
              title: 'Food Shortage',
              subtitle: 'Needs resupply',
              subColor: const Color(0xFF16A34A),
            ),
          ),
          gap,
          Expanded(
            child: _metricTile(
              icon: Icons.water_drop_rounded,
              iconColor: const Color(0xFF0284C7),
              iconBg: const Color(0xFFE0F2FE),
              cardBg: const Color(0xFFF0F9FF),
              borderColor: const Color(0xFFBAE6FD),
              number: '1',
              title: 'Water Shortage',
              subtitle: 'Critical supply',
              subColor: const Color(0xFF0284C7),
            ),
          ),
          gap,
          Expanded(
            child: _metricTile(
              icon: Icons.medical_services_rounded,
              iconColor: const Color(0xFFDC2626),
              iconBg: const Color(0xFFFEE2E2),
              cardBg: const Color(0xFFFEF5F5),
              borderColor: const Color(0xFFFEE2E2),
              number: '1',
              title: 'Medical Support',
              subtitle: 'Needed',
              subColor: const Color(0xFFDC2626),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMetricCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required Color cardBg,
    required Color borderColor,
    required String number,
    required String title,
    required String subtitle,
    required Color subColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(icon, color: iconColor, size: 19),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      number,
                      style: TextStyle(
                        color: iconColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: subColor,
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

  Widget _buildShortageItem(IconData icon, Color color, String count, String label) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  count,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernShelterCard(ShelterOccupancy s) {
    final isNearCap = s.name.contains('St. Anthony') || s.status.toLowerCase().contains('near');
    final isFull = s.name.contains('Valley Convent') || s.status.toUpperCase() == 'FULL' || s.available == 0;

    final statusColor = isFull
        ? const Color(0xFFDC2626)
        : isNearCap
            ? const Color(0xFFD97706)
            : const Color(0xFF16A34A);

    final statusBg = isFull
        ? const Color(0xFFFEE2E2)
        : isNearCap
            ? const Color(0xFFFEF3C7)
            : const Color(0xFFDCFCE7);

    final statusText = isFull
        ? 'Full'
        : isNearCap
            ? 'Near Capacity'
            : 'Open';

    final double ratio = s.capacity > 0 ? (s.occupied / s.capacity).clamp(0.0, 1.0) : 0.0;

    final bool foodShortage = s.name.contains('Community Hall');
    final bool waterShortage = s.name.contains('St. Anthony') || s.name.contains('Valley Convent');
    final bool doctorShortage = s.name.contains('Valley Convent');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Circular Icon, Title, Location, Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: statusBg,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.night_shelter_rounded,
                    color: statusColor,
                    size: 19,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.name,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${s.locationName} • ${s.distance}',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 2. Capacity & Progress Bar Row
          Row(
            children: [
              Text(
                '${s.occupied} / ${s.capacity}',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 7.0,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 3. Provision tags (Food, Water, Doctor)
          Row(
            children: [
              _buildAmenityChip(
                Icons.restaurant_rounded,
                foodShortage ? 'Food !' : 'Food ✓',
                foodShortage,
              ),
              const SizedBox(width: 5),
              _buildAmenityChip(
                Icons.water_drop_rounded,
                waterShortage ? 'Water !' : 'Water ✓',
                waterShortage,
                isWater: true,
              ),
              const SizedBox(width: 5),
              _buildAmenityChip(
                Icons.medical_services_rounded,
                doctorShortage ? 'Doctor !' : 'Doctor ✓',
                doctorShortage,
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 4. Centered View Details button with location pin
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReliefCampDetailScreen(shelterId: s.id, isAuthority: true),
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFF007AEB),
                    size: 15,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'View Details',
                    style: TextStyle(
                      color: Color(0xFF007AEB),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
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

  Widget _buildAmenityChip(IconData icon, String label, bool isShortage, {bool isWater = false}) {
    final Color baseColor = isShortage
        ? const Color(0xFFD97706)
        : isWater
            ? const Color(0xFF0284C7)
            : const Color(0xFF16A34A);

    final Color bgColor = isShortage
        ? const Color(0xFFFFFBEB)
        : isWater
            ? const Color(0xFFF0F9FF)
            : const Color(0xFFF0FDF4);

    final Color borderColor = isShortage
        ? const Color(0xFFFEF3C7)
        : isWater
            ? const Color(0xFFBAE6FD)
            : const Color(0xFFDCFCE7);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor, width: 0.8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 11, color: baseColor),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: baseColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // 28 & 29. MODERN DISASTER OPERATIONS SITREP (MATCHING SCREENSHOT)
  // ==========================================================================
  Widget _buildSitrepAndAuditSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1E36),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E3A5F), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.description_rounded,
                    color: Color(0xFF38BDF8),
                    size: 19,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'DISASTER OPERATIONS SITREP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Latest action updates and critical information',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38BDF8),
                  foregroundColor: const Color(0xFF0F1E36),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.download_rounded, size: 15),
                label: const Text(
                  'GENERATE SITREP',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                ),
                onPressed: _showSitrepModal,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Content Columns (Timeline Feeds + Weather Alert Box)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 850;

              final feedCol1 = Column(
                children: [
                  _buildSitrepTimelineItem(
                    time: '11:45',
                    dotColor: const Color(0xFF10B981),
                    text: 'Rescue team reached Sector C and is assisting 42 residents.',
                  ),
                  const SizedBox(height: 10),
                  _buildSitrepTimelineItem(
                    time: '10:30',
                    dotColor: const Color(0xFF38BDF8),
                    text: 'Water level at Damodar River crossed warning mark (8.2m).',
                  ),
                  const SizedBox(height: 10),
                  _buildSitrepTimelineItem(
                    time: '08:15',
                    dotColor: const Color(0xFFF97316),
                    text: 'Additional relief supplies dispatched to Valley East.',
                  ),
                ],
              );

              final feedCol2 = Column(
                children: [
                  _buildSitrepTimelineItem(
                    time: '07:50',
                    dotColor: const Color(0xFF38BDF8),
                    text: 'Medical team deployed to Shelter 2.',
                  ),
                  const SizedBox(height: 10),
                  _buildSitrepTimelineItem(
                    time: '06:30',
                    dotColor: const Color(0xFF10B981),
                    text: 'All primary evacuation routes are operational except Route C.',
                  ),
                  const SizedBox(height: 10),
                  _buildSitrepTimelineItem(
                    time: '05:10',
                    dotColor: const Color(0xFFF97316),
                    text: 'Heavy rainfall expected in next 6 hours. Stay alert.',
                  ),
                ],
              );

              final alertBox = Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF16253D),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF263D5C), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.cloudy_snowing,
                      color: Color(0xFF38BDF8),
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B151E),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF881337), width: 1),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFFE11D48),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    'Heavy Rainfall Alert',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Next 6-8 hours',
                                    style: TextStyle(
                                      color: Color(0xFFFDA4AF),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: feedCol1),
                    Container(
                      height: 80,
                      width: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 14),
                      color: const Color(0xFF1E3A5F),
                    ),
                    Expanded(flex: 5, child: feedCol2),
                    const SizedBox(width: 14),
                    Expanded(flex: 4, child: alertBox),
                  ],
                );
              } else {
                return Column(
                  children: [
                    feedCol1,
                    const SizedBox(height: 10),
                    feedCol2,
                    const SizedBox(height: 12),
                    alertBox,
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSitrepTimelineItem({
    required String time,
    required Color dotColor,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            time,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
      child: RoleQuickSwitcherOverlay(
        currentRole: CurrentDashboardRole.authority,
        child: Scaffold(
          backgroundColor: CmdColors.bg,
          appBar: _buildTopBar(),
          drawer: _buildDrawer(),
          body: _buildCurrentView(),
          bottomNavigationBar: _buildBottomCommandBar(),
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_activeNavIndex) {
      case 10:
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: _buildSosManagementSection(isDashboard: false),
          ),
        );
      case 1:
        // Fullscreen Disaster Map View
        return _buildLiveDisasterMapSection(isFullScreen: true);
      case 2:
        // SOS & Incident Management Dedicated View
        return SingleChildScrollView(
          child: Column(
            children: [
              _buildSosManagementSection(isDashboard: false),
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
        // Home Overview Command Dashboard (Prominently displaying Evacuation, Shelters, and SITREP matching design)
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopPrioritySituationCard(),
              _buildKeyStatisticsCards(),
              _buildMapAndAnalyticsSection(),
              _buildRiverAndRainfallSection(),
              _buildRescueTeamsSection(),
              _buildAiRiskAndPrioritySection(),
              _buildPopulationAtRiskSection(),
              _buildSosManagementSection(isDashboard: true),
              _buildEvacuationSection(),
              _buildShelterAndReliefSection(),
              _buildSitrepAndAuditSection(),
            ],
          ),
        );
    }
  }

  // ==========================================================================
  // BOTTOM NAVIGATION BAR (MATCHING SCREENSHOT)
  // ==========================================================================
  Widget _buildBottomCommandBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
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
        selectedItemColor: const Color(0xFF0066CC),
        unselectedItemColor: const Color(0xFF64748B),
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
        ),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Dashboard',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.map_rounded),
            label: 'Live Map',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_rounded),
                Positioned(
                  right: -6,
                  top: -3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(minWidth: 14, minHeight: 12),
                    child: const Text(
                      '12',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            label: 'Alerts (12)',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_rounded),
            label: 'Resources',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
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
                    _showIssueEvacuationDialog(context, 'Mawphlang Sector', 2840, 380, '8 SOS', 'Road Blocked', 94);
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

  void _showSosDetailSheet(SOSRequest sos) {
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
                  sos.status.name.toUpperCase(),
                  style: TextStyle(
                    color: sos.status == IncidentStatus.newSos
                        ? CmdColors.criticalRed
                        : CmdColors.warningOrange,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Affected: ${sos.peopleCount} People (${sos.elderlyCount} Elderly, ${sos.childrenCount} Children)'),
            Text('Medical Emergency: ${sos.hasMedical ? "YES - Priority Urgent" : "None reported"}'),
            Text('Received: ${sos.timeAgoFormatted}'),
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

  void _showShelterDetailSheet(ShelterOccupancy sh) {
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
            Text('Food Status: ${sh.foodDetails}'),
            Text('Water Supply: ${sh.waterDetails}'),
            Text('Medical Station: ${sh.medicalAvailable ? "Active" : "None"}'),
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

  void _showAssignTeamModal(SOSRequest sos) {
    showModalBottomSheet(
      context: context,
      backgroundColor: CmdColors.cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ASSIGN TEAM TO SOS ${sos.id}',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: IncidentCoordinator.instance.responderTeams.map(
                  (team) => ListTile(
                    leading: Icon(
                  Icons.directions_boat,
                  color: team.status == 'Available'
                      ? CmdColors.safeGreen
                      : CmdColors.warningOrange,
                ),
                title: Text('${team.name} (${team.unit})'),
                subtitle: Text('Status: ${team.status} · ETA: ${team.etaEstimate}'),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CmdColors.deepBlue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final targetTeamId =
                        team.teamId == 'T-04' || team.name == 'Team 04'
                            ? 'SDRF-BRAVO-04'
                            : (team.unit.contains('NDRF')
                                ? 'NDRF-ALPHA-07'
                                : 'LOCAL-RESCUE-09');

                    final coordSos = IncidentCoordinator.instance.sosRequests
                        .where((s) => s.id == sos.id)
                        .firstOrNull;
                    if (coordSos != null) {
                      IncidentCoordinator.instance.assignMission(
                        sosId: sos.id,
                        teamId: targetTeamId,
                      );
                    } else {
                      final newSos = IncidentCoordinator.instance.createSos(
                        callerName: 'Citizen ${sos.id}',
                        village: sos.village,
                        latitude: LatLng(sos.latitude, sos.longitude).latitude,
                        longitude: LatLng(sos.latitude, sos.longitude).longitude,
                        peopleCount: sos.peopleCount,
                        elderlyCount: sos.elderlyCount,
                        childrenCount: sos.childrenCount,
                        hasMedical: sos.hasMedical,
                        emergencyType: 'Flash Flood Evacuation',
                      );
                      IncidentCoordinator.instance.assignMission(
                        sosId: newSos.id,
                        teamId: targetTeamId,
                      );
                    }

                    setState(() {
                      sos.status = IncidentStatus.teamAssigned;
                      sos.assignedTeamName = '${team.name} (${team.unit})';
                      team.status = 'On Mission';
                      team.currentMissionId = 'Assigned to SOS ${sos.id}';
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
            ).toList(),
          ),
        ),
          ],
        ),
      ),
    );
  }

  void _showAssignEvacTeamsModal(EvacuationOperation op) {
    showModalBottomSheet(
      context: context,
      backgroundColor: CmdColors.cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ASSIGN TEAMS TO EVACUATION: ${op.areaName.toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView(
                    children: IncidentCoordinator.instance.responderTeams.map(
                      (team) => ListTile(
                        leading: Icon(
                          Icons.directions_boat,
                          color: team.status == 'Available'
                              ? CmdColors.safeGreen
                              : CmdColors.warningOrange,
                        ),
                        title: Text('${team.name} (${team.unit})'),
                        subtitle: Text('Status: ${team.status} · ETA: ${team.etaEstimate}'),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: team.status == 'Available' ? CmdColors.deepBlue : Colors.grey,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: team.status == 'Available' ? () {
                            setState(() {
                              team.status = 'On Mission';
                              team.currentMissionId = 'Evacuating ${op.areaName}';
                              _actionLogs.insert(
                                0,
                                '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, "0")} — Assigned ${team.name} to Evacuation ${op.areaName}',
                              );
                            });
                            // Update modal state to reflect changes without closing
                            setModalState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${team.name} assigned to Evacuation ${op.areaName} successfully!',
                                ),
                              ),
                            );
                          } : null,
                          child: const Text('Assign'),
                        ),
                      ),
                    ).toList(),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  void _markSosResolved(SOSRequest sos) {
    IncidentCoordinator.instance.closeIncident(sos.id);
    setState(() {
      sos.status = IncidentStatus.closed;
      _actionLogs.insert(
        0,
        '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, "0")} — SOS ${sos.id} resolved by field team',
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('SOS ${sos.id} marked as RESOLVED')),
    );
  }

  void _showIssueEvacuationDialog(BuildContext context, String areaName, int population, int vulnerable, String sosCount, String roadAccess, int score) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: CmdColors.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.85,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_rounded, color: CmdColors.criticalRed, size: 28),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'EVACUATION PLAN REVIEW',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: CmdColors.textPrimary),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24, color: CmdColors.divider),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPlanRow('Area', areaName, isBold: true),
                      _buildPlanRow('Population', '$population people'),
                      _buildPlanRow('Vulnerable', '$vulnerable'),
                      _buildPlanRow('Hazard', 'Flash Flood — Critical', valueColor: CmdColors.criticalRed),
                      _buildPlanRow('Estimated Impact', '35 min', valueColor: CmdColors.warningOrange),
                      const SizedBox(height: 16),
                      
                      const Text('Primary Shelter', style: TextStyle(fontWeight: FontWeight.w700, color: CmdColors.textSecondary)),
                      const SizedBox(height: 4),
                      const Text('Mawphlang Community Centre\n312 / 500 occupied\n188 spaces available', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),

                      const Text('Secondary Shelter', style: TextStyle(fontWeight: FontWeight.w700, color: CmdColors.textSecondary)),
                      const SizedBox(height: 4),
                      const Text('Govt. High School\n120 / 400 occupied', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),

                      _buildPlanRow('Recommended Route', 'Road C — SAFE (4.2 km)', valueColor: CmdColors.safeGreen),
                      _buildPlanRow('Avoid', 'Eastern Bridge — Unsafe', valueColor: CmdColors.criticalRed),
                      const SizedBox(height: 16),
                      
                      const Text('Available Teams', style: TextStyle(fontWeight: FontWeight.w700, color: CmdColors.textSecondary)),
                      const SizedBox(height: 8),
                      ...[
                        {'name': 'SDRF Bravo', 'dist': '2.1 km'},
                        {'name': 'NDRF Alpha', 'dist': '4.8 km'},
                        {'name': 'Local Rescue 03', 'dist': '3.4 km'},
                      ].map((team) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: CmdColors.cardBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: CmdColors.divider),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(team['name']!, style: const TextStyle(fontWeight: FontWeight.w700, color: CmdColors.textPrimary)),
                                Text(team['dist']!, style: const TextStyle(fontSize: 12, color: CmdColors.textSecondary)),
                              ],
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: CmdColors.deepBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                              ),
                              onPressed: () {
                                final op = EvacuationOperation(
                                  id: 'EVAC-2026-041',
                                  areaName: areaName,
                                  targetPopulation: population,
                                  primaryShelter: 'Mawphlang Community Centre',
                                  safeRoute: 'Road C',
                                  missions: [
                                    ResponderMission(
                                      id: 'RS-208',
                                      clusterName: 'Assigned Area',
                                      targetPopulation: population,
                                      assignedTeam: team['name']!,
                                    )
                                  ],
                                );
                                IncidentCoordinator.instance.issueEvacuationOrder(op);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${team['name']} assigned! Alert sent to field responder.')),
                                );
                              },
                              child: const Text('Assign task of evacuation', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      )).toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: CmdColors.divider),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(color: CmdColors.textPrimary, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CmdColors.criticalRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        // Create backend operation
                        final op = EvacuationOperation(
                          id: 'EVAC-2026-041',
                          areaName: areaName,
                          targetPopulation: population,
                          primaryShelter: 'Mawphlang Community Centre',
                          safeRoute: 'Road C',
                          missions: [
                            ResponderMission(id: 'RS-204', clusterName: 'North Cluster', targetPopulation: 820, assignedTeam: 'SDRF Bravo 04'),
                            ResponderMission(id: 'RS-205', clusterName: 'Riverfront Cluster', targetPopulation: 640, assignedTeam: 'NDRF Alpha 02'),
                            ResponderMission(id: 'RS-206', clusterName: 'School / Market Cluster', targetPopulation: 760, assignedTeam: 'Local Rescue 03'),
                            ResponderMission(id: 'RS-207', clusterName: 'Vulnerable Population', targetPopulation: 620, assignedTeam: 'Medical + SDRF Team'),
                          ],
                        );
                        IncidentCoordinator.instance.issueEvacuationOrder(op);
                        
                        Navigator.pop(context);
                        _showAssignEvacTeamsModal(op);
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: CmdColors.criticalRed,
                            content: Text('EVACUATION ORDER ISSUED FOR $areaName!'),
                          ),
                        );
                      },
                      child: const Text('ISSUE EVACUATION ORDER', style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlanRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: CmdColors.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
                color: valueColor ?? CmdColors.textPrimary,
                fontSize: 14,
              ),
            ),
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
              Text('• Total At Risk: 12,480 people across 3 villages\n• Evacuated: $_evacuatedPop (67% of Sector A)\n• Remaining: ${_totalSectorPop - _evacuatedPop}\n• Active SOS: ${IncidentCoordinator.instance.sosRequests.where((s) => s.status != "Resolved").length}'),
              const SizedBox(height: 8),
              const Text(
                '2. OPERATIONAL DEPLOYMENTS:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              ),
              Text('• Rescue Teams Active: ${IncidentCoordinator.instance.responderTeams.length} (Team 02 deployed to Mawphlang)\n• Shelters Active: ${ResourceApiService.instance.shelters.length} (2 near capacity, 1 full)\n• Critical Lifeline: Route A verified operational'),
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
  Widget _buildAtRiskDetailsScreen(BuildContext context) {
    final evacs = IncidentCoordinator.instance.activeEvacuations;
    EvacuationOperation? getOp(String name) {
      try {
        return evacs.firstWhere((e) => e.areaName.toLowerCase().contains(name.toLowerCase()));
      } catch (_) {
        return null;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEFF6FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEFF6FC),
        elevation: 0,
        iconTheme: const IconThemeData(color: CmdColors.textPrimary),
        title: const Text(
          'AT RISK POPULATION BREAKDOWN',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: CmdColors.textPrimary,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total: 12,480 People • Region: Jharkhand',
                style: TextStyle(color: CmdColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 16),
              
              _villagePriorityCard(
                rank: '1',
                villageName: 'Sahibganj (Diara Area)',
                severity: 'Critical',
                badgeColor: const Color(0xFFDC2626),
                priorityScore: '98 / 100',
                population: '4,520',
                vulnerable: '1,200',
                sosCount: '15 SOS',
                roadAccess: 'Road Blocked',
                activeOp: getOp('Sahibganj'),
                onView: () {
                  Navigator.pop(context); // Go back to map
                  _mapController.move(const LatLng(25.2425, 87.6449), 13.0);
                },
                onOrderEvac: () => _showIssueEvacuationDialog(context, 'Sahibganj (Diara Area)', 4520, 1200, '15 SOS', 'Road Blocked', 98),
              ),

              _villagePriorityCard(
                rank: '2',
                villageName: 'Dumka (Masanjore Downstream)',
                severity: 'Critical',
                badgeColor: const Color(0xFFEA580C),
                priorityScore: '88 / 100',
                population: '3,100',
                vulnerable: '800',
                sosCount: '10 SOS',
                roadAccess: 'Possible (Caution)',
                activeOp: getOp('Dumka'),
                onView: () {
                  Navigator.pop(context);
                  _mapController.move(const LatLng(24.2683, 87.2483), 13.0);
                },
                onOrderEvac: () => _showIssueEvacuationDialog(context, 'Dumka (Masanjore Downstream)', 3100, 800, '10 SOS', 'Possible (Caution)', 88),
                actionLabel: 'Prepare',
              ),

              _villagePriorityCard(
                rank: '3',
                villageName: 'Godda (Low lying sectors)',
                severity: 'High',
                badgeColor: const Color(0xFFEA580C),
                priorityScore: '75 / 100',
                population: '2,840',
                vulnerable: '500',
                sosCount: '5 SOS',
                roadAccess: 'Possible (Caution)',
                activeOp: getOp('Godda'),
                onView: () {
                  Navigator.pop(context);
                  _mapController.move(const LatLng(24.8273, 87.2114), 13.0);
                },
                onOrderEvac: () => _showIssueEvacuationDialog(context, 'Godda (Low lying sectors)', 2840, 500, '5 SOS', 'Possible (Caution)', 75),
                actionLabel: 'Prepare',
              ),

              _villagePriorityCard(
                rank: '4',
                villageName: 'Pakur (River banks)',
                severity: 'Moderate',
                badgeColor: const Color(0xFFD97706),
                priorityScore: '60 / 100',
                population: '1,200',
                vulnerable: '200',
                sosCount: '2 SOS',
                roadAccess: 'Open',
                activeOp: getOp('Pakur'),
                onView: () {
                  Navigator.pop(context);
                  _mapController.move(const LatLng(24.6335, 87.8493), 13.0);
                },
                onOrderEvac: () => _showIssueEvacuationDialog(context, 'Pakur (River banks)', 1200, 200, '2 SOS', 'Open', 60),
                actionLabel: 'Prepare',
              ),

              _villagePriorityCard(
                rank: '5',
                villageName: 'Ranchi (Urban Flooding)',
                severity: 'Moderate',
                badgeColor: const Color(0xFFD97706),
                priorityScore: '55 / 100',
                population: '820',
                vulnerable: '150',
                sosCount: '1 SOS',
                roadAccess: 'Open',
                activeOp: getOp('Ranchi'),
                onView: () {
                  Navigator.pop(context);
                  _mapController.move(const LatLng(23.3441, 85.3096), 13.0);
                },
              ),
            ],
          ),
        ),
      ),
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
