import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

import 'citizen_localization.dart';
import 'citizen_safe_route_view.dart';
import 'citizen_shelters_view.dart';
import 'citizen_hazard_report_view.dart';
import 'citizen_alerts_view.dart';

enum CitizenThreatLevel {
  safe,
  watch,
  warning,
  evacuation,
}

class CitizenDashboardScreen extends StatefulWidget {
  const CitizenDashboardScreen({super.key});

  @override
  State<CitizenDashboardScreen> createState() => _CitizenDashboardScreenState();
}

class _CitizenDashboardScreenState extends State<CitizenDashboardScreen> {
  // Navigation & Localization
  int _currentTab = 0;
  bool _isHindi = false;
  String _currentLocation = 'Shillong, Meghalaya';

  // Dynamic Safety State (Safe / Watch / Warning / Critical)
  CitizenThreatLevel _threatLevel = CitizenThreatLevel.safe;
  bool _isSosActive = false;
  int _activeAlertIndex = 0;

  // Map Controllers
  late final MapController _mapController;
  late final MapController _fullMapController;
  bool _isMapDragEnabled = false;
  String _fullMapFilter = 'All';

  // Key Coordinates (Local Basin)
  final LatLng _userPos = const LatLng(23.7957, 86.4304);
  final LatLng _waypointPos = const LatLng(23.7990, 86.4340);
  final LatLng _shelterPos1 = const LatLng(23.8030, 86.4380);
  final LatLng _shelterPos2 = const LatLng(23.7920, 86.4250);
  final LatLng _hospitalPos = const LatLng(23.8060, 86.4220);
  final LatLng _roadBlockPos = const LatLng(23.7975, 86.4390);
  final LatLng _rescueTeamPos = const LatLng(23.8010, 86.4290);

  // Family Safety Data
  final List<Map<String, dynamic>> _familyMembers = [
    {'name': 'Father', 'nameHi': 'पिताजी', 'status': 'Safe', 'statusHi': 'सुरक्षित', 'icon': Icons.elderly_rounded, 'isSafe': true, 'time': 'Updated 5m ago'},
    {'name': 'Mother', 'nameHi': 'माताजी', 'status': 'Safe', 'statusHi': 'सुरक्षित', 'icon': Icons.face_3_rounded, 'isSafe': true, 'time': 'Updated 10m ago'},
    {'name': 'Brother', 'nameHi': 'भाई', 'status': 'Last seen 15 min ago', 'statusHi': '15 मिनट पहले देखा गया', 'icon': Icons.boy_rounded, 'isSafe': false, 'time': 'Last seen 15m ago'},
    {'name': 'Sister', 'nameHi': 'बहन', 'status': 'Safe', 'statusHi': 'सुरक्षित', 'icon': Icons.girl_rounded, 'isSafe': true, 'time': 'Updated 2m ago'},
  ];

  // Active Alerts List
  final List<Map<String, dynamic>> _activeAlerts = [
    {
      'title': 'Heavy Rainfall + Rising River Alert',
      'titleHi': 'भारी बारिश + नदी जलस्तर वृद्धि चेतावनी',
      'distance': '2.4 km from you',
      'distanceHi': 'आपसे 2.4 किमी दूर',
      'time': 'Updated 5 min ago',
      'timeHi': '5 मिनट पहले अपडेट',
      'impact': 'Low-lying sectors may experience flash flooding within 2 hours.',
      'impactHi': 'निचले क्षेत्रों में अगले 2 घंटों में बाढ़ की संभावना है।',
      'badge': 'FLOOD WARNING',
      'badgeHi': 'बाढ़ चेतावनी',
      'color': Color(0xFFE92828),
    },
    {
      'title': 'High Water Discharge from Upstream Dam',
      'titleHi': 'बांध से अतिरिक्त पानी छोड़ा गया',
      'distance': '6.1 km upstream',
      'distanceHi': '6.1 किमी ऊपर की ओर',
      'time': 'Updated 18 min ago',
      'timeHi': '18 मिनट पहले अपडेट',
      'impact': 'River velocity elevated. Avoid low-ground causeways and riverbanks.',
      'impactHi': 'नदी की गति तेज है। पुल और नदी तट से दूर रहें।',
      'badge': 'DAM SURGE',
      'badgeHi': 'डैम सर्ज',
      'color': Color(0xFFF39A20),
    },
  ];

  // Notifications List
  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'Flood Warning for Sector 4 & 5',
      'body': 'Water level Damodar river reached 214.6m. Stay alert.',
      'type': 'Emergency',
      'time': '10 mins ago',
      'isRead': false,
    },
    {
      'title': 'Relief Shelter Open: Govt Senior Secondary',
      'body': 'Capacity 72% full. Clean food, drinking water & doctors available.',
      'type': 'Shelter',
      'time': '25 mins ago',
      'isRead': false,
    },
    {
      'title': 'Damodar River Bridge Closed',
      'body': 'Structural safety precaution. Use High Ridge bypass.',
      'type': 'Road',
      'time': '1 hour ago',
      'isRead': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _fullMapController = MapController();
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF013973),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ==========================================================================
  // MAIN BUILD
  // ==========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9F4FB),
      appBar: _buildTopAppBar(),
      body: _buildCurrentTabBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildCurrentTabBody() {
    switch (_currentTab) {
      case 0:
        return _buildHomeDashboardTab();
      case 1:
        return _buildFullMapTab();
      case 2:
        return CitizenAlertsView(isHindi: _isHindi);
      case 3:
        return _buildHelpHubTab();
      case 4:
        return _buildProfileTab();
      default:
        return _buildHomeDashboardTab();
    }
  }

  // ==========================================================================
  // 1. TOP APP BAR (Location + Notifications + Language + Profile)
  // ==========================================================================
  PreferredSizeWidget _buildTopAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      titleSpacing: 8,
      leadingWidth: 42,
      leading: IconButton(
        icon: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF0F172A), size: 20),
        tooltip: CitizenStrings.get('changeRole', isHindi: _isHindi),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ResQShield Logo with Pulse
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.shield_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'ResQShield',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _isHindi ? 'सतर्क रहें • सुरक्षित रहें • तैयार रहें' : 'Be Aware • Be Safe • Be Prepared',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Location Pill (Opens picker)
        InkWell(
          onTap: _showLocationPickerModal,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF2563EB)),
                const SizedBox(width: 3),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 95),
                  child: Text(
                    _currentLocation,
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 3),

        // Language Toggle
        GestureDetector(
          onTap: () {
            setState(() => _isHindi = !_isHindi);
            _showMessage(_isHindi ? 'भाषा बदली गई: हिंदी' : 'Language switched to English');
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Text(
              _isHindi ? 'EN' : 'हिं',
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 2),

        // Notifications Bell with Badge
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF1E293B), size: 21),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: _showNotificationsSheet,
              tooltip: _isHindi ? 'सूचनाएं' : 'Notifications',
            ),
            Positioned(
              right: 1,
              top: 5,
              child: Container(
                padding: const EdgeInsets.all(3.5),
                decoration: const BoxDecoration(
                  color: Color(0xFFDC2626),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${_notifications.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 4),

        // Profile Avatar Icon
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: GestureDetector(
            onTap: () => setState(() => _currentTab = 4),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Icon(Icons.person_rounded, size: 18, color: Color(0xFF2563EB)),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // TAB 0: HOME DASHBOARD (SCROLLABLE MAP + COMPLETE ACTION ORDER)
  // ==========================================================================
  Widget _buildHomeDashboardTab() {
    return Column(
      children: [
        // Offline Mesh Banner
        _buildOfflineBanner(),

        // Active SOS Banner (if SOS sent)
        if (_isSosActive) _buildActiveSosBanner(),

        // Scrollable Dashboard Content
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Live Disaster Map Preview (~220px high, scrolls with dashboard)
                _buildMapSection(),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 2. HERO SAFETY STATUS CARD (🟢 SAFE / 🟡 WATCH / 🟠 WARNING / 🔴 CRITICAL)
                      _buildSafetyStatusHeroCard(),

                      const SizedBox(height: 14),

                      // Simulation Chips (Allows testing all 4 states on demand)
                      _buildThreatLevelSimulatorChips(),

                      const SizedBox(height: 14),

                      // 3. ACTIVE EMERGENCY ALERT CARD
                      _buildActiveAlertCard(),

                      const SizedBox(height: 16),

                      // 4. QUICK ACTIONS (6 TILES)
                      _buildQuickActionGrid(),

                      const SizedBox(height: 18),

                      // 5. NEAREST SAFE SHELTER CARD
                      _buildNearestSafeShelterCard(),

                      const SizedBox(height: 16),

                      // 6. FAMILY SAFETY CARD
                      _buildFamilySafetyCard(),

                      const SizedBox(height: 16),

                      // 7. LOCAL CONDITIONS (Clean & Non-Technical)
                      _buildLocalConditionsCard(),

                      const SizedBox(height: 16),

                      // 8. WEATHER & RAINFALL FORECAST
                      _buildWeatherForecastCard(),

                      const SizedBox(height: 16),

                      // 9. LOCAL ROAD CONDITIONS
                      _buildRoadStatusCard(),

                      const SizedBox(height: 16),

                      // 10. NEARBY MEDICAL / HOSPITAL HELP
                      _buildMedicalHelpCard(),

                      const SizedBox(height: 16),

                      // 11. DYNAMIC SAFETY INSTRUCTIONS ("What You Should Do")
                      _buildSafetyInstructionsCard(),

                      const SizedBox(height: 16),

                      // 12. EMERGENCY CONTACTS ROW
                      _buildEmergencyContactsRow(),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // OFFLINE BANNER
  // --------------------------------------------------------------------------
  Widget _buildOfflineBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF1B4D89),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4D89).withValues(alpha: 0.22),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.sensors_rounded, color: Color(0xFF38BDF8), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isHindi
                  ? 'ऑफलाइन सेफ्टी मोड • कैश्ड मैप, शेल्टर निर्देशांक व रेडियो सिंक'
                  : 'Offline Safety Mode • Cached map, shelter coordinates & radio sync',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 18),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // ACTIVE SOS STATE BANNER
  // --------------------------------------------------------------------------
  Widget _buildActiveSosBanner() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFE92828),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.emergency_rounded, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isHindi ? '🚨 आपातकालीन SOS सक्रिय' : '🚨 EMERGENCY SOS ACTIVE',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                ),
                Text(
                  _isHindi
                      ? 'स्थान राहत दल से साझा किया गया • स्थिति: बचाव दल रवाना'
                      : 'GPS shared with Response Unit • Status: Rescue team dispatched',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() => _isSosActive = false);
              _showMessage(_isHindi ? 'SOS समाप्त किया गया' : 'SOS Cancelled');
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
            child: Text(
              _isHindi ? 'रद्द करें' : 'Resolve',
              style: const TextStyle(color: Color(0xFFE92828), fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // LIVE DISASTER MAP PREVIEW (SCROLLABLE WITH DASHBOARD)
  // --------------------------------------------------------------------------
  Widget _buildMapSection() {
    return SizedBox(
      height: 220,
      width: double.infinity,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(23.7990, 86.4340),
              initialZoom: 14.0,
              minZoom: 10.0,
              maxZoom: 18.0,
              interactionOptions: InteractionOptions(
                flags: _isMapDragEnabled ? InteractiveFlag.all : (InteractiveFlag.all & ~InteractiveFlag.drag),
              ),
            ),
            children: [
              // OpenStreetMap Standard Tiles
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.resqshield.app',
              ),

              // Safe Route Polyline Overlay (Green)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [_userPos, _waypointPos, _shelterPos1],
                    color: const Color(0xFF15945C),
                    strokeWidth: 4.5,
                  ),
                ],
              ),

              // Map Markers (Clean non-technical pins)
              MarkerLayer(
                markers: [
                  // User GPS Marker
                  Marker(
                    point: _userPos,
                    width: 42,
                    height: 42,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AEB),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))],
                      ),
                      child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 22),
                    ),
                  ),

                  // Waypoint Marker
                  Marker(
                    point: _waypointPos,
                    width: 32,
                    height: 32,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF15945C),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.alt_route, color: Colors.white, size: 16),
                    ),
                  ),

                  // Designated Primary Shelter
                  Marker(
                    point: _shelterPos1,
                    width: 44,
                    height: 44,
                    child: GestureDetector(
                      onTap: _showShelterDetailsModal,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFE92828),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))],
                        ),
                        child: const Icon(Icons.night_shelter_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                  ),

                  // District Hospital Marker
                  Marker(
                    point: _hospitalPos,
                    width: 36,
                    height: 36,
                    child: GestureDetector(
                      onTap: _showMedicalDetailsModal,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                        child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),

                  // Road Block / Flood Zone Marker
                  Marker(
                    point: _roadBlockPos,
                    width: 34,
                    height: 34,
                    child: GestureDetector(
                      onTap: _showRoadConditionsModal,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF39A20),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.block_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ),

                  // Secondary Shelter Marker
                  Marker(
                    point: _shelterPos2,
                    width: 36,
                    height: 36,
                    child: GestureDetector(
                      onTap: _showShelterDetailsModal,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF39A20),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.night_shelter_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),

                  // Rescue Team Standby Marker
                  Marker(
                    point: _rescueTeamPos,
                    width: 36,
                    height: 36,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF013973),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.support_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Pinned Map Legend
          Positioned(
            top: 10,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD6E8F7)),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF007AEB)),
                  const SizedBox(width: 4),
                  Text(
                    _isHindi ? 'लाइव आपदा मानचित्र' : 'Live Disaster Map',
                    style: const TextStyle(color: Color(0xFF013973), fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),

          // Floating Controls (Recenter, Pan Toggle, Open Full Map)
          Positioned(
            top: 10,
            right: 12,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.my_location_rounded, size: 18, color: Color(0xFF013973)),
                    onPressed: () {
                      _mapController.move(_userPos, 14.5);
                      _showMessage(_isHindi ? 'आपके स्थान पर केंद्रित' : 'Centered on your GPS position');
                    },
                    tooltip: 'Recenter on You',
                  ),
                ),
                const SizedBox(height: 6),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: _isMapDragEnabled ? const Color(0xFF013973) : Colors.white,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      _isMapDragEnabled ? Icons.pan_tool_rounded : Icons.pan_tool_outlined,
                      size: 18,
                      color: _isMapDragEnabled ? Colors.white : const Color(0xFF013973),
                    ),
                    onPressed: () {
                      setState(() => _isMapDragEnabled = !_isMapDragEnabled);
                      _showMessage(
                        _isMapDragEnabled
                            ? (_isHindi ? 'मैप ड्रैग सक्रिय' : 'Map pan enabled (drag map)')
                            : (_isHindi ? 'पेज स्क्रॉल सक्रिय' : 'Scroll mode active (drag to scroll)'),
                      );
                    },
                    tooltip: _isMapDragEnabled ? 'Lock Map (Scroll Page)' : 'Unlock Map Pan',
                  ),
                ),
                const SizedBox(height: 6),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.fullscreen_rounded, size: 20, color: Color(0xFF15945C)),
                    onPressed: () => setState(() => _currentTab = 1),
                    tooltip: 'Open Full Screen Map',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 2. SABSE IMPORTANT: CURRENT SAFETY STATUS HERO CARD
  // --------------------------------------------------------------------------
  Widget _buildSafetyStatusHeroCard() {
    Color cardColor;
    Color borderColor;
    Color textColor;
    IconData icon;
    String statusTitle;
    String riskLabel;
    String statusDesc;
    Widget? actionWidget;

    switch (_threatLevel) {
      case CitizenThreatLevel.safe:
        cardColor = const Color(0xFFEAF8F0);
        borderColor = const Color(0xFF86EFAC);
        textColor = const Color(0xFF15945C);
        icon = Icons.check_circle_rounded;
        statusTitle = _isHindi ? 'आप सुरक्षित हैं' : 'YOU ARE CURRENTLY SAFE';
        riskLabel = _isHindi ? 'जोखिम स्तर: निम्न (कम)' : 'Risk Level: LOW';
        statusDesc = _isHindi
            ? 'वर्तमान में कोई तात्कालिक निकासी की आवश्यकता नहीं है। मौसम और जलस्तर सुरक्षित सीमा में हैं।'
            : 'No immediate evacuation required. Based on rainfall, river gauge telemetry and local verified reports.';
        actionWidget = null;
        break;

      case CitizenThreatLevel.watch:
        cardColor = const Color(0xFFFEFCE8);
        borderColor = const Color(0xFFFDE047);
        textColor = const Color(0xFFB45309);
        icon = Icons.visibility_rounded;
        statusTitle = _isHindi ? 'सतर्क रहें' : 'STAY ALERT (WATCH)';
        riskLabel = _isHindi ? 'जोखिम स्तर: मध्यम' : 'Risk Level: MODERATE';
        statusDesc = _isHindi
            ? 'आपके क्षेत्र में जलस्तर बढ़ रहा है। सुरक्षा निर्देशों की समीक्षा करें और तैयार रहें।'
            : 'Water levels are rising near your sector. Review safety instructions and keep essential items ready.';
        actionWidget = OutlinedButton.icon(
          onPressed: _showSafetyInstructionsModal,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFB45309), width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.shield_outlined, size: 16, color: Color(0xFFB45309)),
          label: Text(
            _isHindi ? 'सुरक्षा निर्देश देखें' : 'View Safety Instructions',
            style: const TextStyle(color: Color(0xFFB45309), fontWeight: FontWeight.w800, fontSize: 12),
          ),
        );
        break;

      case CitizenThreatLevel.warning:
        cardColor = const Color(0xFFFFF7ED);
        borderColor = const Color(0xFFFDBA74);
        textColor = const Color(0xFFC2410C);
        icon = Icons.warning_amber_rounded;
        statusTitle = _isHindi ? 'निकासी की तैयारी करें' : 'PREPARE TO EVACUATE';
        riskLabel = _isHindi ? 'जोखिम स्तर: उच्च' : 'Risk Level: HIGH';
        statusDesc = _isHindi
            ? 'निचले क्षेत्रों में बाढ़ का खतरा बढ़ रहा है। सुरक्षित निकासी मार्ग की पहचान करें।'
            : 'Flood risk increasing rapidly near your location. Identify your designated evacuation corridor.';
        actionWidget = ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CitizenSafeRouteView(isHindi: _isHindi)),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC2410C),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.alt_route_rounded, size: 16, color: Colors.white),
          label: Text(
            _isHindi ? 'सुरक्षित मार्ग देखें' : 'View Safe Route',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
          ),
        );
        break;

      case CitizenThreatLevel.evacuation:
        cardColor = const Color(0xFFFEF2F2);
        borderColor = const Color(0xFFFCA5A5);
        textColor = const Color(0xFFE92828);
        icon = Icons.crisis_alert_rounded;
        statusTitle = _isHindi ? 'तुरंत सुरक्षित स्थान जाएं' : 'EVACUATE NOW';
        riskLabel = _isHindi ? 'जोखिम स्तर: गंभीर (क्रिटिकल)' : 'Risk Level: CRITICAL';
        statusDesc = _isHindi
            ? 'आपका क्षेत्र उच्च बाढ़ जोखिम में है। तुरंत 1.8 किमी दूर स्थित सरकारी राहत शिविर में पहुंचे।'
            : 'Your area is at severe flood risk. Move immediately to Government Relief Centre (1.8 km).';
        actionWidget = SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CitizenSafeRouteView(isHindi: _isHindi)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE92828),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.directions_run_rounded, color: Colors.white, size: 24),
            label: Text(
              _isHindi ? 'तत्काल निकासी शुरू करें' : 'START EVACUATION',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.8),
            ),
          ),
        );
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: textColor.withValues(alpha: 0.08),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor),
                ),
                child: Icon(icon, color: textColor, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusTitle,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      riskLabel,
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            statusDesc,
            style: const TextStyle(
              color: Color(0xFF0F2642),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          if (actionWidget != null) ...[
            const SizedBox(height: 12),
            actionWidget,
          ],
        ],
      ),
    );
  }

  // Simulator chips so user/evaluator can easily test all 4 states
  Widget _buildThreatLevelSimulatorChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD6E8F7)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Text(
              _isHindi ? 'स्थिति सिमुलेशन:' : 'Simulate:',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF537392)),
            ),
            const SizedBox(width: 8),
            _buildSimChip('🟢 Safe', CitizenThreatLevel.safe),
            const SizedBox(width: 6),
            _buildSimChip('🟡 Watch', CitizenThreatLevel.watch),
            const SizedBox(width: 6),
            _buildSimChip('🟠 Warning', CitizenThreatLevel.warning),
            const SizedBox(width: 6),
            _buildSimChip('🔴 Evac', CitizenThreatLevel.evacuation),
          ],
        ),
      ),
    );
  }

  Widget _buildSimChip(String label, CitizenThreatLevel level) {
    final isSelected = _threatLevel == level;
    return GestureDetector(
      onTap: () => setState(() => _threatLevel = level),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF013973) : const Color(0xFFF3F8FD),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.white : const Color(0xFF013973),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 3. ACTIVE EMERGENCY ALERT CARD
  // --------------------------------------------------------------------------
  Widget _buildActiveAlertCard() {
    final alert = _activeAlerts[_activeAlertIndex];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDBA74)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: alert['color'],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_rounded, color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      _isHindi ? alert['badgeHi'] : alert['badge'],
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '${_activeAlertIndex + 1} of ${_activeAlerts.length}',
                style: const TextStyle(color: Color(0xFF537392), fontSize: 11, fontWeight: FontWeight.bold),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF013973), size: 20),
                onPressed: () {
                  setState(() {
                    _activeAlertIndex = (_activeAlertIndex + 1) % _activeAlerts.length;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isHindi ? alert['titleHi'] : alert['title'],
            style: const TextStyle(color: Color(0xFF013973), fontSize: 13.5, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.near_me_rounded, size: 12, color: Color(0xFF537392)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  _isHindi ? alert['distanceHi'] : alert['distance'],
                  style: const TextStyle(color: Color(0xFF537392), fontSize: 11, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF537392)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  _isHindi ? alert['timeHi'] : alert['time'],
                  style: const TextStyle(color: Color(0xFF537392), fontSize: 11, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isHindi ? alert['impactHi'] : alert['impact'],
            style: const TextStyle(color: Color(0xFF0F2642), fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentTab = 2),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: const BorderSide(color: Color(0xFF013973)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    _isHindi ? 'अलर्ट विवरण देखें' : 'View Alert',
                    style: const TextStyle(color: Color(0xFF013973), fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _showSafetyInstructionsModal,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    backgroundColor: const Color(0xFF013973),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    _isHindi ? 'सुरक्षा निर्देश' : 'Safety Instructions',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 4. QUICK ACTIONS (6 TILES - REDESIGNED UI)
  // --------------------------------------------------------------------------
  Widget _buildQuickActionGrid() {
    final List<_QuickActionItem> items = [
      _QuickActionItem(
        title: _isHindi ? 'एसओएस' : 'SOS',
        subtitle: _isHindi
            ? 'अपने स्थान के साथ आपातकालीन अलर्ट भेजें'
            : 'Send emergency alert with your location',
        chipLabel: _isHindi ? 'त्वरित पहुंच' : 'Quick Access',
        icon: Icons.crisis_alert_rounded,
        chipIcon: Icons.emergency_rounded,
        accentColor: const Color(0xFFE92828),
        softBgColor: const Color(0xFFFFECEC),
        waveColor: const Color(0xFFFEE2E2).withValues(alpha: 0.45),
        onTap: _showSosConfirmationDialog,
      ),
      _QuickActionItem(
        title: _isHindi ? 'सुरक्षित मार्ग' : 'Safe Route',
        subtitle: _isHindi
            ? 'अपने गंतव्य के लिए सबसे सुरक्षित मार्ग खोजें'
            : 'Find safest route to your destination',
        chipLabel: _isHindi ? 'सुरक्षित नेविगेट करें' : 'Navigate Safely',
        icon: Icons.alt_route_rounded,
        chipIcon: Icons.map_rounded,
        accentColor: const Color(0xFF059669),
        softBgColor: const Color(0xFFE6F7F0),
        waveColor: const Color(0xFFD1FAE5).withValues(alpha: 0.45),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CitizenSafeRouteView(isHindi: _isHindi)),
          );
        },
      ),
      _QuickActionItem(
        title: _isHindi ? 'राहत शिविर' : 'Shelters',
        subtitle: _isHindi
            ? 'नजदीकी सुरक्षित शिविर व राहत केंद्र खोजें'
            : 'Find nearby safe shelters and relief centers',
        chipLabel: _isHindi ? 'पास में देखें' : 'View Nearby',
        icon: Icons.night_shelter_rounded,
        chipIcon: Icons.home_rounded,
        accentColor: const Color(0xFF2563EB),
        softBgColor: const Color(0xFFEFF6FF),
        waveColor: const Color(0xFFDBEAFE).withValues(alpha: 0.5),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CitizenSheltersView(isHindi: _isHindi)),
          );
        },
      ),
      _QuickActionItem(
        title: _isHindi ? 'चिकित्सा सहायता' : 'Medical',
        subtitle: _isHindi
            ? 'अस्पताल, क्लीनिक और चिकित्सा सहायता खोजें'
            : 'Locate hospitals, clinics and medical help',
        chipLabel: _isHindi ? 'मदद प्राप्त करें' : 'Get Help',
        icon: Icons.add_box_rounded,
        chipIcon: Icons.medical_services_rounded,
        accentColor: const Color(0xFF0891B2),
        softBgColor: const Color(0xFFECFEFF),
        waveColor: const Color(0xFFCFFAFE).withValues(alpha: 0.5),
        onTap: _showMedicalDetailsModal,
      ),
      _QuickActionItem(
        title: _isHindi ? 'परिवार सुरक्षा' : 'Family',
        subtitle: _isHindi
            ? 'परिवार को ट्रैक करें और जुड़े रहें'
            : 'Track and stay connected with your family',
        chipLabel: _isHindi ? 'जुड़े रहें' : 'Stay Connected',
        icon: Icons.groups_rounded,
        chipIcon: Icons.groups_rounded,
        accentColor: const Color(0xFF7C3AED),
        softBgColor: const Color(0xFFF5F3FF),
        waveColor: const Color(0xFFEDE9FE).withValues(alpha: 0.5),
        onTap: _showFamilySafetyModal,
      ),
      _QuickActionItem(
        title: _isHindi ? 'आपदा रिपोर्ट' : 'Report',
        subtitle: _isHindi
            ? 'घटनाओं, खतरों या आपात स्थिति की रिपोर्ट करें'
            : 'Report incidents, hazards or emergencies',
        chipLabel: _isHindi ? 'रिपोर्ट भेजें' : 'Submit Report',
        icon: Icons.camera_alt_rounded,
        chipIcon: Icons.description_rounded,
        accentColor: const Color(0xFFEA580C),
        softBgColor: const Color(0xFFFFF7ED),
        waveColor: const Color(0xFFFFEDD5).withValues(alpha: 0.5),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CitizenHazardReportView(isHindi: _isHindi)),
          );
        },
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              _isHindi ? 'त्वरित कार्य' : 'QUICK ACTIONS',
              style: const TextStyle(
                color: Color(0xFF013973),
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final int crossAxisCount;
            final double childAspectRatio;

            if (screenWidth >= 760) {
              crossAxisCount = 3;
              childAspectRatio = 1.32;
            } else if (screenWidth >= 520) {
              crossAxisCount = 2;
              childAspectRatio = 1.25;
            } else {
              crossAxisCount = 1;
              childAspectRatio = 2.05;
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: childAspectRatio,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return _buildQuickActionCard(items[index]);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(_QuickActionItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0).withValues(alpha: 0.8),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: item.accentColor.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Top-right subtle pastel organic wave
            Positioned.fill(
              child: CustomPaint(
                painter: _CardWavePainter(color: item.waveColor),
              ),
            ),

            // Left vertical accent indicator bar
            Positioned(
              left: 0,
              top: 14,
              bottom: 14,
              child: Container(
                width: 4.5,
                decoration: BoxDecoration(
                  color: item.accentColor,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(4),
                    bottomRight: Radius.circular(4),
                  ),
                ),
              ),
            ),

            // Card content & ripple tap
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.circular(20),
                splashColor: item.accentColor.withValues(alpha: 0.1),
                highlightColor: item.accentColor.withValues(alpha: 0.05),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top icon + title + description
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: item.softBgColor,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              item.icon,
                              color: item.accentColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            item.title,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.subtitle,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),

                      // Bottom action row: Chip + Arrow button
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: item.softBgColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(item.chipIcon, size: 13, color: item.accentColor),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      item.chipLabel,
                                      style: TextStyle(
                                        color: item.accentColor,
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
                          const SizedBox(width: 8),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: item.softBgColor,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 15,
                              color: item.accentColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 5. NEAREST SAFE SHELTER CARD
  // --------------------------------------------------------------------------
  Widget _buildNearestSafeShelterCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD6E8F7)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF15945C).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.night_shelter_rounded, color: Color(0xFF15945C), size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isHindi ? 'नजदीकी सुरक्षित शिविर' : 'NEAREST SAFE SHELTER',
                      style: const TextStyle(color: Color(0xFF537392), fontSize: 10.5, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      _isHindi ? 'सरकारी राहत केंद्र (सेक्टर 4)' : 'Government Relief Centre',
                      style: const TextStyle(color: Color(0xFF013973), fontSize: 14, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF8F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF15945C), shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text(
                      _isHindi ? 'खुला है' : 'OPEN',
                      style: const TextStyle(color: Color(0xFF15945C), fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.place_rounded, size: 14, color: Color(0xFF007AEB)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _isHindi ? '1.8 किमी दूर • सेक्टर 4' : '1.8 km away • Sector 4 High Ground',
                  style: const TextStyle(color: Color(0xFF0F2642), fontSize: 12, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _isHindi ? '72 / 100 लोग (72% क्षमता)' : '72 / 100 people (72%)',
                style: const TextStyle(color: Color(0xFF537392), fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.72,
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF15945C)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildAmenityBadge(Icons.rice_bowl_rounded, _isHindi ? 'भोजन' : 'Food'),
              _buildAmenityBadge(Icons.water_drop_rounded, _isHindi ? 'स्वच्छ जल' : 'Water'),
              _buildAmenityBadge(Icons.medical_services_rounded, _isHindi ? 'चिकित्सा' : 'Medical'),
              _buildAmenityBadge(Icons.bolt_rounded, _isHindi ? 'बिजली' : 'Power'),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showShelterDetailsModal,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: const BorderSide(color: Color(0xFF013973)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF013973)),
                  label: Text(
                    _isHindi ? 'विवरण देखें' : 'View Details',
                    style: const TextStyle(color: Color(0xFF013973), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CitizenSafeRouteView(isHindi: _isHindi)),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    backgroundColor: const Color(0xFF15945C),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.navigation_rounded, size: 16, color: Colors.white),
                  label: Text(
                    _isHindi ? 'नेविगेट करें' : 'Navigate',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmenityBadge(IconData icon, String title) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF007AEB)),
        const SizedBox(width: 4),
        Text(
          title,
          style: const TextStyle(color: Color(0xFF013973), fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // 6. FAMILY SAFETY CARD
  // --------------------------------------------------------------------------
  Widget _buildFamilySafetyCard() {
    final safeCount = _familyMembers.where((m) => m['isSafe'] == true).length;
    final totalCount = _familyMembers.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD6E8F7)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7351D8).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.family_restroom_rounded, color: Color(0xFF7351D8), size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isHindi ? 'परिवार सुरक्षा स्थिति' : 'FAMILY SAFETY',
                      style: const TextStyle(color: Color(0xFF537392), fontSize: 10.5, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      _isHindi ? '$safeCount / $totalCount सदस्य सुरक्षित हैं' : '$safeCount / $totalCount members safe',
                      style: const TextStyle(color: Color(0xFF013973), fontSize: 14, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _showFamilySafetyModal,
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: Text(
                  _isHindi ? 'पूरा देखें' : 'View Family',
                  style: const TextStyle(color: Color(0xFF007AEB), fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Column(
            children: _familyMembers.map((member) {
              final isSafe = member['isSafe'] as bool;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: const Color(0xFFF3F8FD),
                      child: Icon(member['icon'], size: 16, color: const Color(0xFF013973)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _isHindi ? member['nameHi'] : member['name'],
                        style: const TextStyle(color: Color(0xFF013973), fontWeight: FontWeight.w800, fontSize: 12.5),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isSafe ? const Color(0xFFEAF8F0) : const Color(0xFFFFF5E7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSafe ? Icons.check_circle_rounded : Icons.access_time_rounded,
                            size: 12,
                            color: isSafe ? const Color(0xFF15945C) : const Color(0xFFF39A20),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isHindi ? member['statusHi'] : member['status'],
                            style: TextStyle(
                              color: isSafe ? const Color(0xFF15945C) : const Color(0xFFF39A20),
                              fontWeight: FontWeight.w800,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 7. LOCAL CONDITIONS (NON-TECHNICAL INDICATORS)
  // --------------------------------------------------------------------------
  Widget _buildLocalConditionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD6E8F7)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.explore_rounded, color: Color(0xFF007AEB), size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _isHindi ? 'आपके क्षेत्र की स्थिति' : 'LOCAL CONDITIONS (YOUR AREA)',
                  style: const TextStyle(color: Color(0xFF013973), fontSize: 12, fontWeight: FontWeight.w900),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _isHindi ? 'लाइव रिपोर्ट' : 'Live Report',
                style: const TextStyle(color: Color(0xFF15945C), fontSize: 10, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildConditionTile(
                  icon: Icons.water_drop_rounded,
                  iconColor: const Color(0xFF007AEB),
                  title: _isHindi ? 'बारिश' : 'Rainfall',
                  value: _isHindi ? 'भारी (Heavy)' : 'Heavy',
                  subtitle: _isHindi ? 'निरंतर जारी' : 'Continuous',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildConditionTile(
                  icon: Icons.waves_rounded,
                  iconColor: const Color(0xFFE92828),
                  title: _isHindi ? 'नदी जलस्तर' : 'River Level',
                  value: _isHindi ? 'तेजी से बढ़ रहा' : 'Rising rapidly',
                  subtitle: _isHindi ? 'दामोदर नदी' : 'Damodar River',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildConditionTile(
                  icon: Icons.thermostat_rounded,
                  iconColor: const Color(0xFFF39A20),
                  title: _isHindi ? 'तापमान' : 'Temperature',
                  value: '24°C',
                  subtitle: _isHindi ? 'नमी: 94%' : 'Humidity: 94%',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildConditionTile(
                  icon: Icons.air_rounded,
                  iconColor: const Color(0xFF537392),
                  title: _isHindi ? 'हवा की गति' : 'Wind Speed',
                  value: '18 km/h',
                  subtitle: _isHindi ? 'हवा का रुख: पूर्व' : 'Heading East',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConditionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 4),
              Text(
                title,
                style: const TextStyle(color: Color(0xFF537392), fontSize: 10.5, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: Color(0xFF013973), fontSize: 13, fontWeight: FontWeight.w900),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF537392), fontSize: 9.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 8. WEATHER & RAIN FORECAST CARD
  // --------------------------------------------------------------------------
  Widget _buildWeatherForecastCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD6E8F7)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_sync_rounded, color: Color(0xFF007AEB), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isHindi ? 'मौसम पूर्वानुमान (अगले 3 घंटे)' : 'WEATHER & RAIN FORECAST',
                  style: const TextStyle(color: Color(0xFF013973), fontSize: 12, fontWeight: FontWeight.w900),
                ),
              ),
              TextButton(
                onPressed: _showWeatherForecastModal,
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: Text(
                  _isHindi ? 'विस्तार से' : 'View Forecast',
                  style: const TextStyle(color: Color(0xFF007AEB), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _isHindi ? 'आज: भारी बारिश का पूर्वानुमान' : 'Today: Heavy rainfall expected across low basins',
            style: const TextStyle(color: Color(0xFF013973), fontSize: 13, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFDBA74)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFC2410C), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isHindi
                        ? '⚠️ अगले 3 घंटों में अत्यधिक वर्षा बाढ़ का जोखिम बढ़ा सकती है।'
                        : '⚠️ Heavy rainfall in the next 3 hours may surge flood risks.',
                    style: const TextStyle(color: Color(0xFFC2410C), fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 9. LOCAL ROAD STATUS CARD
  // --------------------------------------------------------------------------
  Widget _buildRoadStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD6E8F7)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.traffic_rounded, color: Color(0xFF013973), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isHindi ? 'आस-पास के सड़कों की स्थिति' : 'NEARBY ROAD CONDITIONS',
                  style: const TextStyle(color: Color(0xFF013973), fontSize: 12, fontWeight: FontWeight.w900),
                ),
              ),
              TextButton(
                onPressed: _showRoadConditionsModal,
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: Text(
                  _isHindi ? 'सभी देखें' : 'View Roads',
                  style: const TextStyle(color: Color(0xFF007AEB), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildRoadItem(
            name: _isHindi ? 'मुख्य बायपास रोड' : 'Main Bypass Highway',
            status: _isHindi ? 'खुला है' : 'Open',
            statusColor: const Color(0xFF15945C),
            icon: Icons.check_circle_outline_rounded,
          ),
          const Divider(height: 12),
          _buildRoadItem(
            name: _isHindi ? 'हिल रिज रोड' : 'Hill Ridge Road',
            status: _isHindi ? 'धीमी गति / जोखिम' : 'Slow / Risky',
            statusColor: const Color(0xFFF39A20),
            icon: Icons.error_outline_rounded,
          ),
          const Divider(height: 12),
          _buildRoadItem(
            name: _isHindi ? 'दामोदर नदी पुल' : 'Damodar River Bridge',
            status: _isHindi ? 'बंद / जलमग्न' : 'Closed (Submerged)',
            statusColor: const Color(0xFFE92828),
            icon: Icons.block_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildRoadItem({
    required String name,
    required String status,
    required Color statusColor,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: statusColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(color: Color(0xFF013973), fontSize: 12.5, fontWeight: FontWeight.w800),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            status,
            style: TextStyle(color: statusColor, fontSize: 10.5, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // 10. NEARBY MEDICAL / HOSPITAL HELP CARD
  // --------------------------------------------------------------------------
  Widget _buildMedicalHelpCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD6E8F7)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.local_hospital_rounded, color: Color(0xFF0284C7), size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isHindi ? 'नजदीकी चिकित्सा सहायता' : 'NEARBY MEDICAL HELP',
                      style: const TextStyle(color: Color(0xFF537392), fontSize: 10.5, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      _isHindi ? 'जिला सामान्य अस्पताल' : 'District General Hospital',
                      style: const TextStyle(color: Color(0xFF013973), fontSize: 14, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF8F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _isHindi ? 'उपलब्ध' : 'OPERATIONAL',
                  style: const TextStyle(color: Color(0xFF15945C), fontSize: 9.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.near_me_rounded, size: 13, color: Color(0xFF537392)),
              const SizedBox(width: 4),
              Text(
                _isHindi ? '3.2 किमी दूर' : '3.2 km away',
                style: const TextStyle(color: Color(0xFF0F2642), fontSize: 11.5, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.bed_rounded, size: 14, color: Color(0xFF15945C)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _isHindi ? 'इमरजेंसी बेड उपलब्ध' : 'Emergency beds ready',
                  style: const TextStyle(color: Color(0xFF15945C), fontSize: 11.5, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showMessage(_isHindi ? 'अस्पताल को कॉल कर रहे हैं...' : 'Dialing Hospital: 06542-230001'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: const BorderSide(color: Color(0xFF0284C7)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.phone_in_talk_rounded, size: 16, color: Color(0xFF0284C7)),
                  label: Text(
                    _isHindi ? 'कॉल करें' : 'Call Hospital',
                    style: const TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showMedicalDetailsModal,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    backgroundColor: const Color(0xFF0284C7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.map_rounded, size: 16, color: Colors.white),
                  label: Text(
                    _isHindi ? 'विवरण' : 'Details',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 11. DYNAMIC SAFETY INSTRUCTIONS ("WHAT YOU SHOULD DO")
  // --------------------------------------------------------------------------
  Widget _buildSafetyInstructionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD6E8F7)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_rounded, color: Color(0xFF15945C), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isHindi ? 'आपको क्या करना चाहिए (सुरक्षा नियम)' : 'WHAT YOU SHOULD DO (SAFETY RULES)',
                  style: const TextStyle(color: Color(0xFF013973), fontSize: 12, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildRuleItem('❌', _isHindi ? 'बहते बाढ़ के पानी में बिल्कुल न चलें या गाड़ी न ले जाएं' : "Don't walk or drive through moving water"),
          _buildRuleItem('⚡', _isHindi ? 'बिजली के खंभों और गिरे तारों से कम से कम 10 मीटर दूर रहें' : 'Stay away from electrical poles & downed lines'),
          _buildRuleItem('🎒', _isHindi ? 'दवाइयां, टॉर्च और जरूरी दस्तावेज वाटरप्रूफ बैग में रखें' : 'Keep emergency kit, medications & ID dry in ziplock'),
          _buildRuleItem('📱', _isHindi ? 'फोन को बैटरी सेवर पर रखें; आपातकालीन हेल्पलाइन याद रखें' : 'Keep mobile on battery saver; keep radio mesh on'),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _showSafetyInstructionsModal,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFF3F8FD),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                _isHindi ? 'पूरी सुरक्षा गाइड पढ़ें' : 'View Full Safety Guide',
                style: const TextStyle(color: Color(0xFF013973), fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFF0F2642), fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 12. EMERGENCY CONTACTS ROW
  // --------------------------------------------------------------------------
  Widget _buildEmergencyContactsRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD6E8F7)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.phone_in_talk_rounded, color: Color(0xFFE92828), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isHindi ? 'आपातकालीन संपर्क (हेल्पलाइन)' : 'EMERGENCY HELPLINES (1-TAP CALL)',
                  style: const TextStyle(color: Color(0xFF013973), fontSize: 12, fontWeight: FontWeight.w900),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildContactPill('🚨 Emergency', '112', const Color(0xFFE92828)),
                const SizedBox(width: 8),
                _buildContactPill('👮 Police', '100', const Color(0xFF013973)),
                const SizedBox(width: 8),
                _buildContactPill('🚒 Fire', '101', const Color(0xFFC2410C)),
                const SizedBox(width: 8),
                _buildContactPill('🚑 Ambulance', '108', const Color(0xFF15945C)),
                const SizedBox(width: 8),
                _buildContactPill('🏛️ Disaster Control', '1077', const Color(0xFF7351D8)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactPill(String label, String number, Color color) {
    return InkWell(
      onTap: () => _showMessage(_isHindi ? '$label ($number) को कॉल किया जा रहा है...' : 'Dialing $label ($number)...'),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                number,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // TAB 1: FULL DISASTER MAP TAB (FILTERS & CONTROLS)
  // ==========================================================================
  Widget _buildFullMapTab() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _fullMapController,
          options: MapOptions(
            initialCenter: const LatLng(23.7990, 86.4340),
            initialZoom: 13.5,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.resqshield.app',
            ),
            // Safe Corridor Polyline
            PolylineLayer(
              polylines: [
                Polyline(
                  points: [_userPos, _waypointPos, _shelterPos1],
                  color: const Color(0xFF15945C),
                  strokeWidth: 5.0,
                ),
              ],
            ),
            // Filterable Markers
            MarkerLayer(
              markers: [
                // User Marker
                Marker(
                  point: _userPos,
                  width: 44,
                  height: 44,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AEB),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                    ),
                    child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 24),
                  ),
                ),
                // Shelter 1
                if (_fullMapFilter == 'All' || _fullMapFilter == 'Shelters')
                  Marker(
                    point: _shelterPos1,
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: _showShelterDetailsModal,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFE92828),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                        child: const Icon(Icons.night_shelter_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                // Hospital
                if (_fullMapFilter == 'All' || _fullMapFilter == 'Hospitals')
                  Marker(
                    point: _hospitalPos,
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: _showMedicalDetailsModal,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                        child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                // Road Block
                if (_fullMapFilter == 'All' || _fullMapFilter == 'Roads')
                  Marker(
                    point: _roadBlockPos,
                    width: 38,
                    height: 38,
                    child: GestureDetector(
                      onTap: _showRoadConditionsModal,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF39A20),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.block_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),

        // Filter Chips on Top of Map
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Flood Zone', 'Roads', 'Shelters', 'Hospitals'].map((filter) {
                final isSelected = _fullMapFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(
                      filter,
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF013973),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    selectedColor: const Color(0xFF013973),
                    backgroundColor: Colors.white.withValues(alpha: 0.95),
                    onSelected: (_) => setState(() => _fullMapFilter = filter),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Floating Action Button to launch Full Safe Route
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CitizenSafeRouteView(isHindi: _isHindi)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF15945C),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 6,
            ),
            icon: const Icon(Icons.directions_run_rounded, color: Colors.white, size: 22),
            label: Text(
              _isHindi ? 'सुरक्षित मार्ग नेविगेशन शुरू करें' : 'START SAFE ROUTE NAVIGATION',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // TAB 3: HELP HUB TAB (EMERGENCY-FOCUSED)
  // ==========================================================================
  Widget _buildHelpHubTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Need Help Header
          Text(
            _isHindi ? '🚨 आपातकालीन मदद की आवश्यकता है?' : '🚨 Need Immediate Help?',
            style: const TextStyle(color: Color(0xFF013973), fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            _isHindi
                ? 'यदि आप या आपका परिवार खतरे में है, तो नीचे दिए गए लाल SOS बटन को दबाएं।'
                : 'If you or someone around you is in immediate peril, trigger the Emergency SOS below.',
            style: const TextStyle(color: Color(0xFF537392), fontSize: 13),
          ),
          const SizedBox(height: 18),

          // Big Emergency SOS Button
          SizedBox(
            height: 100,
            child: ElevatedButton(
              onPressed: _showSosConfirmationDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE92828),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 6,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emergency_share_rounded, color: Colors.white, size: 40),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isHindi ? 'आपातकालीन SOS भेजें' : 'TRANSMIT SOS NOW',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                      Text(
                        _isHindi ? 'लाइव जीपीएस सीधे राहत दल को जाएगा' : 'Shares exact GPS with nearby NDRF / Police',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Quick Action Cards
          _buildHelpTile(
            icon: Icons.alt_route_rounded,
            color: const Color(0xFF15945C),
            title: _isHindi ? 'सुरक्षित मार्ग खोजें' : 'Find Safe Evacuation Route',
            subtitle: _isHindi ? 'बाढ़ से मुक्त ऊंचे मार्गों की नेविगेशन' : 'GPS route avoiding submerged roads & bridges',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CitizenSafeRouteView(isHindi: _isHindi)),
              );
            },
          ),
          const SizedBox(height: 10),
          _buildHelpTile(
            icon: Icons.night_shelter_rounded,
            color: const Color(0xFF007AEB),
            title: _isHindi ? 'निकटतम राहत शिविर खोजें' : 'Locate Nearest Relief Shelter',
            subtitle: _isHindi ? 'भोजन, पानी और बिस्तर की उपलब्धता' : 'Food, clean water, medical aid & bed capacity',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CitizenSheltersView(isHindi: _isHindi)),
              );
            },
          ),
          const SizedBox(height: 10),
          _buildHelpTile(
            icon: Icons.local_hospital_rounded,
            color: const Color(0xFF0284C7),
            title: _isHindi ? 'अस्पताल व प्राथमिक चिकित्सा' : 'Hospitals & Medical Care',
            subtitle: _isHindi ? 'सक्रिय स्वास्थ्य केंद्र एवं एम्बुलेंस' : 'Emergency clinics & on-call trauma units',
            onTap: _showMedicalDetailsModal,
          ),
          const SizedBox(height: 10),
          _buildHelpTile(
            icon: Icons.shield_rounded,
            color: const Color(0xFF7351D8),
            title: _isHindi ? 'सुरक्षा गाइड और निर्देश' : 'Disaster Survival Guide',
            subtitle: _isHindi ? 'बाढ़ के दौरान क्या करें और क्या न करें' : 'Step-by-step checklist during flash floods',
            onTap: _showSafetyInstructionsModal,
          ),
          const SizedBox(height: 10),
          _buildHelpTile(
            icon: Icons.add_a_photo_rounded,
            color: const Color(0xFFF39A20),
            title: _isHindi ? 'आपदा या खतरा दर्ज करें' : 'Report Incident or Hazard',
            subtitle: _isHindi ? 'टूटे पुल, जलभराव या मलबे की फोटो भेजें' : 'Report blocked roads or stranded persons',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CitizenHazardReportView(isHindi: _isHindi)),
              );
            },
          ),
          const SizedBox(height: 20),

          // Helplines
          _buildEmergencyContactsRow(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHelpTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD6E8F7)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Color(0xFF013973), fontSize: 13.5, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Color(0xFF537392), fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF537392), size: 16),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // TAB 4: PROFILE & SETTINGS TAB
  // ==========================================================================
  Widget _buildProfileTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD6E8F7)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFF013973),
                  child: Icon(Icons.person, size: 36, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rohit Kumar',
                        style: TextStyle(color: Color(0xFF013973), fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '+91 98765 43210 • Citizen',
                        style: TextStyle(color: Color(0xFF537392), fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF8F0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _isHindi ? '🟢 जीपीएस सत्यापित' : '🟢 GPS Location Verified',
                          style: const TextStyle(color: Color(0xFF15945C), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Menu Section 1: Family & SOS
          _buildProfileMenuSection(
            title: _isHindi ? 'परिवार एवं आपातकालीन' : 'FAMILY & EMERGENCY',
            items: [
              _buildProfileMenuItem(
                icon: Icons.family_restroom_rounded,
                title: _isHindi ? 'परिवार सदस्य सूची एवं चेक-इन' : 'Family Safety & Check-in',
                subtitle: _isHindi ? '3/4 सदस्य सुरक्षित' : '3 / 4 members marked safe',
                onTap: _showFamilySafetyModal,
              ),
              _buildProfileMenuItem(
                icon: Icons.contact_phone_rounded,
                title: _isHindi ? 'आपातकालीन संपर्क सूची' : 'Emergency Contacts',
                subtitle: _isHindi ? '112, पुलिस, एम्बुलेंस' : '112, Police, NDRF',
                onTap: () => _showMessage('Emergency contacts up to date'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Menu Section 2: Data & Connectivity
          _buildProfileMenuSection(
            title: _isHindi ? 'डेटा एवं ऑफ़लाइन' : 'OFFLINE DATA & ACCESS',
            items: [
              _buildProfileMenuItem(
                icon: Icons.download_done_rounded,
                title: _isHindi ? 'डाउनलोड किए गए मैप और डेटा' : 'Downloaded Offline Data',
                subtitle: _isHindi ? 'बोकारो व शिलांग बेसिन (14 MB)' : 'Bokaro & Shillong Basins (14 MB cached)',
                onTap: () => _showMessage('Offline maps are cached and ready'),
              ),
              _buildProfileMenuItem(
                icon: Icons.wifi_tethering_rounded,
                title: _isHindi ? 'लोरा रेडियो मेश सेटिंग्स' : 'LoRa Mesh Sync Settings',
                subtitle: _isHindi ? 'ऑटोमैटिक पियर-टू-पियर चालू' : 'P2P background synchronization active',
                onTap: () => _showMessage('LoRa Mesh is active in background'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Menu Section 3: Preferences
          _buildProfileMenuSection(
            title: _isHindi ? 'प्राथमिकताएं' : 'PREFERENCES',
            items: [
              _buildProfileMenuItem(
                icon: Icons.language_rounded,
                title: _isHindi ? 'भाषा (Language)' : 'App Language',
                subtitle: _isHindi ? 'वर्तमान: हिन्दी (टैप करें बदलने के लिए)' : 'Current: English (tap to switch)',
                onTap: () {
                  setState(() => _isHindi = !_isHindi);
                  _showMessage(_isHindi ? 'भाषा: हिन्दी' : 'Language: English');
                },
              ),
              _buildProfileMenuItem(
                icon: Icons.notifications_active_rounded,
                title: _isHindi ? 'आपातकालीन अलर्ट सायरन' : 'Emergency Alert Sound',
                subtitle: _isHindi ? 'उच्च प्राथमिकता सायरन चालू' : 'Loud siren on Critical Evacuation: ON',
                onTap: () => _showMessage('Siren test completed'),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProfileMenuSection({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Color(0xFF537392), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.6),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFD6E8F7)),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF013973)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Color(0xFF013973), fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Color(0xFF537392), fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF537392), size: 14),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // BOTTOM NAVIGATION BAR (5 TABS)
  // ==========================================================================
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFD6E8F7), width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (idx) => setState(() => _currentTab = idx),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF013973),
        unselectedItemColor: const Color(0xFF64748B),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10.5),
        elevation: 0,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_rounded),
            label: _isHindi ? 'होम' : 'Home',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.map_rounded),
            label: _isHindi ? 'मानचित्र' : 'Map',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.campaign_rounded),
            label: _isHindi ? 'अलर्ट्स' : 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.emergency_rounded),
            label: _isHindi ? 'मदद' : 'Help',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_rounded),
            label: _isHindi ? 'प्रोफ़ाइल' : 'Profile',
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // INTERACTIVE MODALS & SHEETS
  // ==========================================================================

  // 1. SOS CONFIRMATION & ACTIVE TRANSMIT MODAL
  void _showSosConfirmationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_rounded, color: Color(0xFFE92828), size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _isHindi ? 'आपातकालीन SOS' : 'Emergency SOS',
                style: const TextStyle(color: Color(0xFF013973), fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isHindi
                  ? 'क्या आप या आपके साथ के लोग तात्कालिक खतरे में हैं?'
                  : 'Are you in immediate danger? Triggering SOS will dispatch your exact GPS coordinates to the nearest NDRF & police rescue team.',
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEEEE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.group_rounded, color: Color(0xFFE92828), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isHindi ? 'साथ में लोग: 3 सदस्य' : 'People with you: 3 members',
                      style: const TextStyle(color: Color(0xFFE92828), fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              _isHindi ? 'रद्द करें' : 'CANCEL',
              style: const TextStyle(color: Color(0xFF537392), fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _isSosActive = true;
                _threatLevel = CitizenThreatLevel.evacuation;
              });
              _showMessage(_isHindi ? '🚨 SOS भेजा गया! राहत दल को सूचित किया गया है।' : '🚨 SOS Transmitted! Relief team assigned.');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE92828),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              _isHindi ? 'SOS भेजें' : 'SEND SOS',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  // 2. LOCATION PICKER MODAL
  void _showLocationPickerModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.my_location_rounded, color: Color(0xFF007AEB)),
                const SizedBox(width: 8),
                Text(
                  _isHindi ? 'स्थान चुनें' : 'Select Location',
                  style: const TextStyle(color: Color(0xFF013973), fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...['Shillong, Meghalaya', 'Bokaro Basin, Jharkhand', 'Ranchi, Jharkhand', 'Guwahati, Assam'].map((loc) {
              final isSel = _currentLocation == loc;
              return ListTile(
                leading: Icon(
                  isSel ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isSel ? const Color(0xFF007AEB) : const Color(0xFF537392),
                ),
                title: Text(loc, style: TextStyle(fontWeight: isSel ? FontWeight.w900 : FontWeight.w600)),
                onTap: () {
                  setState(() => _currentLocation = loc);
                  Navigator.pop(ctx);
                  _showMessage(_isHindi ? 'स्थान बदला गया: $loc' : 'Location updated: $loc');
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  // 3. NOTIFICATIONS SHEET
  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.65,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active_rounded, color: Color(0xFF013973)),
                const SizedBox(width: 8),
                Text(
                  _isHindi ? 'सूचनाएं (नोटिफिकेशन्स)' : 'Notifications (${_notifications.length})',
                  style: const TextStyle(color: Color(0xFF013973), fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showMessage(_isHindi ? 'सभी सूचनाएं पढ़ी गईं' : 'All marked as read');
                  },
                  child: Text(_isHindi ? 'पढ़ा हुआ मार्क करें' : 'Mark all read'),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView.separated(
                itemCount: _notifications.length,
                separatorBuilder: (_, _) => const Divider(height: 12),
                itemBuilder: (_, idx) {
                  final notif = _notifications[idx];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: notif['type'] == 'Emergency' ? const Color(0xFFFFEEEE) : const Color(0xFFE9F4FB),
                      child: Icon(
                        notif['type'] == 'Emergency' ? Icons.warning_rounded : Icons.info_rounded,
                        color: notif['type'] == 'Emergency' ? const Color(0xFFE92828) : const Color(0xFF007AEB),
                      ),
                    ),
                    title: Text(notif['title'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    subtitle: Text(notif['body'], style: const TextStyle(fontSize: 11)),
                    trailing: Text(notif['time'], style: const TextStyle(fontSize: 10, color: Color(0xFF537392))),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 4. FAMILY SAFETY & CHECK-IN MODAL
  void _showFamilySafetyModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            padding: const EdgeInsets.all(20),
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.family_restroom_rounded, color: Color(0xFF7351D8), size: 24),
                    const SizedBox(width: 8),
                    Text(
                      _isHindi ? 'परिवार सुरक्षा चेक-इन' : 'Family Safety & Check-in',
                      style: const TextStyle(color: Color(0xFF013973), fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _isHindi
                      ? 'आपदा के समय अपने परिवार के सदस्यों की सुरक्षा स्थिति ट्रैक करें या स्वयं को सुरक्षित मार्क करें।'
                      : 'Real-time sync of family member check-ins. Works offline via LoRa broadcast.',
                  style: const TextStyle(color: Color(0xFF537392), fontSize: 12),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showMessage(_isHindi ? 'आपने खुद को सुरक्षित मार्क किया!' : 'You marked yourself SAFE!');
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF15945C),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                    label: Text(
                      _isHindi ? 'मैं सुरक्षित हूँ (चेक-इन करें)' : 'I AM SAFE (BROADCAST CHECK-IN)',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const Divider(height: 24),
                Expanded(
                  child: ListView.builder(
                    itemCount: _familyMembers.length,
                    itemBuilder: (_, i) {
                      final m = _familyMembers[i];
                      final isSafe = m['isSafe'] as bool;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xFFE9F4FB),
                              child: Icon(m['icon'], color: const Color(0xFF013973)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isHindi ? m['nameHi'] : m['name'],
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                  ),
                                  Text(
                                    _isHindi ? m['statusHi'] : m['status'],
                                    style: TextStyle(
                                      color: isSafe ? const Color(0xFF15945C) : const Color(0xFFF39A20),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.phone_rounded, color: Color(0xFF007AEB)),
                              onPressed: () => _showMessage('Calling ${m['name']}...'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 5. SHELTER DETAILS MODAL
  void _showShelterDetailsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.night_shelter_rounded, color: Color(0xFF15945C), size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isHindi ? 'सरकारी राहत केंद्र' : 'Government Relief Centre',
                        style: const TextStyle(color: Color(0xFF013973), fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                      const Text('Sector 4 High Ground, Bokaro • 1.8 km', style: TextStyle(color: Color(0xFF537392), fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Text(
              _isHindi ? 'शिविर सुविधाएं एवं स्थिति' : 'Shelter Amenities & Readiness',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF013973)),
            ),
            const SizedBox(height: 10),
            _buildShelterRow(Icons.groups_rounded, _isHindi ? 'क्षमता' : 'Occupancy', '72 / 100 Beds Occupied (28 Remaining)'),
            _buildShelterRow(Icons.rice_bowl_rounded, _isHindi ? 'भोजन' : 'Clean Food', 'Hot Meals & Drinking Water Stocked'),
            _buildShelterRow(Icons.medical_services_rounded, _isHindi ? 'चिकित्सा' : 'Medical Staff', '1 Doctor & 2 Registered Nurses On-Duty'),
            _buildShelterRow(Icons.bolt_rounded, _isHindi ? 'पावर' : 'Generator', 'Emergency Diesel Generator Active'),
            _buildShelterRow(Icons.wifi_rounded, _isHindi ? 'संचार' : 'Radio Mesh', 'LoRa Relay + Satellite Phone Hub'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CitizenSafeRouteView(isHindi: _isHindi)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF15945C),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.directions_run_rounded, color: Colors.white),
                label: Text(
                  _isHindi ? 'इस शिविर का सुरक्षित मार्ग शुरू करें' : 'NAVIGATE SAFE CORRIDOR TO SHELTER',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShelterRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF007AEB)),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5, color: Color(0xFF013973))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 11.5, color: Color(0xFF0F2642)))),
        ],
      ),
    );
  }

  // 6. MEDICAL / HOSPITAL MODAL
  void _showMedicalDetailsModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_hospital_rounded, color: Color(0xFF0284C7), size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isHindi ? 'जिला सामान्य अस्पताल' : 'District General Hospital',
                        style: const TextStyle(color: Color(0xFF013973), fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                      const Text('Sector 1 Civic Center • 3.2 km away', style: TextStyle(color: Color(0xFF537392), fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            _buildShelterRow(Icons.bed_rounded, _isHindi ? 'इमरजेंसी बेड' : 'Emergency Beds', '18 Trauma Beds Available'),
            _buildShelterRow(Icons.local_shipping_rounded, _isHindi ? 'एम्बुलेंस' : 'Ambulance Units', '3 High-Water Ambulances On Standby'),
            _buildShelterRow(Icons.bloodtype_rounded, _isHindi ? 'ब्लड बैंक' : 'Blood Bank', 'All Types Available in Emergency Reserve'),
            _buildShelterRow(Icons.phone_in_talk_rounded, _isHindi ? 'हेल्पलाइन' : 'Direct Helpline', '06542-230001 / 108'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showMessage('Calling 06542-230001...');
                    },
                    icon: const Icon(Icons.phone, size: 16),
                    label: Text(_isHindi ? 'कॉल करें' : 'Call Hospital'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showMessage('Routing to District Hospital');
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                    icon: const Icon(Icons.directions, color: Colors.white, size: 16),
                    label: Text(_isHindi ? 'नेविगेट' : 'Directions', style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 7. ROAD CONDITIONS MODAL
  void _showRoadConditionsModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.traffic_rounded, color: Color(0xFF013973), size: 24),
                const SizedBox(width: 8),
                Text(
                  _isHindi ? 'सड़क एवं पुल स्थिति रिपोर्ट' : 'Local Road & Bridge Report',
                  style: const TextStyle(color: Color(0xFF013973), fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const Divider(height: 20),
            _buildRoadItem(
              name: 'Main Bypass Highway (Sector 1 to 4)',
              status: 'OPEN & CLEAR',
              statusColor: const Color(0xFF15945C),
              icon: Icons.check_circle_rounded,
            ),
            const SizedBox(height: 8),
            _buildRoadItem(
              name: 'Hill Ridge Elevation Road',
              status: 'SLOW / WATER POOLING',
              statusColor: const Color(0xFFF39A20),
              icon: Icons.warning_rounded,
            ),
            const SizedBox(height: 8),
            _buildRoadItem(
              name: 'Damodar River Causeway Bridge',
              status: 'SUBMERGED - STRICTLY CLOSED',
              statusColor: const Color(0xFFE92828),
              icon: Icons.cancel_rounded,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF8F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _isHindi
                    ? '💡 सलाह: राहत केंद्र पहुंचने के लिए केवल ग्रीन सुरक्षित मार्ग (हाईवे बायपास) का ही उपयोग करें।'
                    : '💡 Safe Corridor Recommendation: Stick strictly to the green Safe Route along high ground.',
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF15945C), fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 8. WEATHER FORECAST MODAL
  void _showWeatherForecastModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_sync_rounded, color: Color(0xFF007AEB), size: 24),
                const SizedBox(width: 8),
                Text(
                  _isHindi ? 'मौसम एवं वर्षा पूर्वानुमान' : 'Weather & Radar Forecast',
                  style: const TextStyle(color: Color(0xFF013973), fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const Divider(height: 20),
            Text(
              _isHindi ? 'अगले 6 घंटे का अनुमान (IMD डॉप्लर रडार)' : 'Next 6 Hours Outlook (Doppler Radar)',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF013973)),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildHourlyRain('Now', '🌧️🌧️', '35 mm/h', 'High'),
                _buildHourlyRain('+1 hr', '🌧️🌧️🌧️', '48 mm/h', 'Peak'),
                _buildHourlyRain('+2 hr', '🌧️🌧️', '30 mm/h', 'High'),
                _buildHourlyRain('+3 hr', '🌧️', '14 mm/h', 'Moderate'),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _isHindi
                  ? 'चेतावनी: पिक ऑवर (+1 घंटा) के दौरान नदी तट के निचले वार्डों में पानी 15-25 सेमी बढ़ सकता है।'
                  : 'Notice: Peak rain influx will hit at +1 hr. Low-lying riverside wards should expect 15-25cm rise.',
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF537392)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyRain(String time, String icon, String rain, String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F8FD),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(time, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF013973))),
          const SizedBox(height: 4),
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(rain, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
          Text(tag, style: const TextStyle(color: Color(0xFFE92828), fontSize: 9.5, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // 9. FULL SAFETY INSTRUCTIONS MODAL
  void _showSafetyInstructionsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shield_rounded, color: Color(0xFF15945C), size: 26),
                const SizedBox(width: 8),
                Text(
                  _isHindi ? 'आपदा सुरक्षा गाइड (NDMA)' : 'Citizen Safety Guide (NDMA)',
                  style: const TextStyle(color: Color(0xFF013973), fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const Divider(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildSafetySection(
                    _isHindi ? '1. बाढ़ से पहले क्या करें (तैयारी)' : '1. Before Flood Waters Rise (Preparation)',
                    [
                      'Keep emergency documents, IDs & prescription medicines in water-sealed bags.',
                      'Store at least 3 days of potable water and non-perishable rations.',
                      'Charge power banks and cellphones fully; memorize helpline 112.',
                      'Know your designated high-ground shelter & evacuation corridor.',
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildSafetySection(
                    _isHindi ? '2. बाढ़ के दौरान क्या करें (निकासी)' : '2. During Flooding (Evacuation & Survival)',
                    [
                      'Never drive or wade through floodwaters — 15 cm of moving water can knock you down.',
                      'Disconnect main power switches before water enters your house.',
                      'Do not touch electric wires, fallen transformers, or submerged poles.',
                      'Move immediately to first floor or roof if evacuation route is compromised, and broadcast SOS.',
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildSafetySection(
                    _isHindi ? '3. बाढ़ के बाद क्या करें (सुरक्षित वापसी)' : '3. After Flood Waters Recede',
                    [
                      'Do not drink tap or well water until officially verified as potable.',
                      'Beware of venomous snakes and reptiles that seek shelter in dry buildings.',
                      'Report damaged structures and broken electrical cables to authorities.',
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

  Widget _buildSafetySection(String title, List<String> points) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Color(0xFF013973), fontWeight: FontWeight.w900, fontSize: 13.5)),
        const SizedBox(height: 6),
        ...points.map((p) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: Color(0xFF007AEB), fontWeight: FontWeight.bold, fontSize: 14)),
                  Expanded(child: Text(p, style: const TextStyle(fontSize: 12, color: Color(0xFF0F2642), height: 1.3))),
                ],
              ),
            )),
      ],
    );
  }
}

class _QuickActionItem {
  final String title;
  final String subtitle;
  final String chipLabel;
  final IconData icon;
  final IconData chipIcon;
  final Color accentColor;
  final Color softBgColor;
  final Color waveColor;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.title,
    required this.subtitle,
    required this.chipLabel,
    required this.icon,
    required this.chipIcon,
    required this.accentColor,
    required this.softBgColor,
    required this.waveColor,
    required this.onTap,
  });
}

class _CardWavePainter extends CustomPainter {
  final Color color;

  const _CardWavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width * 0.48, 0);
    path.cubicTo(
      size.width * 0.58,
      size.height * 0.28,
      size.width * 0.72,
      size.height * 0.12,
      size.width,
      size.height * 0.56,
    );
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CardWavePainter oldDelegate) => oldDelegate.color != color;
}

