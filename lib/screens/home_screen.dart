import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/custom_painters.dart';
import '../widgets/dos_donts_section.dart';
import '../widgets/live_flood_map_widget.dart';
import 'river_level_detail_screen.dart';
import 'rainfall_detail_screen.dart';
import 'affected_people_detail_screen.dart';
import 'rescue_teams_detail_screen.dart';
import 'authority/hazard_map_screen.dart';
import 'authority/village_risk_table_screen.dart';
import 'authority/alert_dispatch_screen.dart';
import 'authority/resource_shelter_map_screen.dart';
import 'authority/trends_forecast_screen.dart';
import 'authority/dam_coordination_screen.dart';
import 'authority/coordination_log_screen.dart';

// ============================================================
// COLORS
// ============================================================

class AppColors {
  // Unified light blue / white government-grade palette matching Login, OTP, & Permissions
  static const bgPrimary = Color(0xFFE9F4FB);
  static const bgTop = Color(0xFFE3F0F9);
  static const bgMain = Color(0xFFEAF4FB);
  static const bgLight = Color(0xFFF3F8FD);
  static const bgBottom = Color(0xFFE0EFF8);

  static const navy = Color(0xFF013973);        // Brand Deep Navy
  static const darkBlue = Color(0xFF0A4F8A);    // Secondary Blue
  static const blue = Color(0xFF007AEB);        // Primary Action Blue
  static const lightBlue = Color(0xFF38BDF8);   // Accent Sky Blue
  static const greenGlow = Color(0xFF00FF00);   // Brand 'Q' Green

  static const cardBg = Colors.white;
  static const cardBorder = Color(0xFFD6E8F7);
  static const white = Color(0xFFFFFFFF);
  static const text = Color(0xFF0F2642);        // Crisp Dark Slate Text
  static const muted = Color(0xFF537392);       // Muted Slate Text

  static const red = Color(0xFFE92828);
  static const orange = Color(0xFFF39A20);
  static const green = Color(0xFF15945C);
  static const purple = Color(0xFF7351D8);

  static const paleRed = Color(0xFFFFEEEE);
  static const paleOrange = Color(0xFFFFF5E7);
  static const paleGreen = Color(0xFFEAF8F0);
}

// ============================================================
// HOME SCREEN
// ============================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedBottomIndex = 0;

  // ------------------------------------------------------------------
  // LOCATION STATE
  // ------------------------------------------------------------------
  String _locationText = 'Locating...';
  double? _latitude;
  double? _longitude;
  bool _locationLoading = true;
  int _threatLevel = 1; // 0: Normal, 1: Warning, 2: Critical
  final MapController _mapController = MapController();

  LatLng get _effectiveCenter {
    if (_latitude != null && _longitude != null) {
      return LatLng(_latitude!, _longitude!);
    }
    return const LatLng(10.1076, 76.3516); // Kochi / Aluva basin default
  }

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    try {
      // Check if location service is on — 3s timeout
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled().timeout(
        const Duration(seconds: 3),
        onTimeout: () => false,
      );

      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _locationText = 'Location Service Off';
            _locationLoading = false;
          });
        }
        return;
      }

      // Check existing permission (no dialog, just reads current status)
      LocationPermission permission = await Geolocator.checkPermission()
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () => LocationPermission.denied,
          );

      // Only request if not already granted — 5s timeout
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission().timeout(
          const Duration(seconds: 5),
          onTimeout: () => LocationPermission.denied,
        );
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _locationText = 'Location Permission Denied';
            _locationLoading = false;
          });
        }
        return;
      }

      // Fetch actual GPS position — low accuracy is faster, 12s outer timeout
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 12),
      );

      if (mounted) {
        setState(() {
          _latitude = pos.latitude;
          _longitude = pos.longitude;
          _locationText =
              '${pos.latitude.toStringAsFixed(4)}°N, ${pos.longitude.toStringAsFixed(4)}°E';
          _locationLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationText = 'Unable to fetch location';
          _locationLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showEmergencyDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.paleRed,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.sos_rounded,
                color: AppColors.red,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Emergency Rescue',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Immediate Assistance Helplines:',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _emergencyCallTile('National Disaster Helpline', '1070'),
            _emergencyCallTile('State Control Room (Kerala)', '1077'),
            _emergencyCallTile('Medical Emergency & Ambulance', '108'),
            _emergencyCallTile('Police & Integrated Emergency', '112'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _showMessage('Broadcasting live GPS coordinates to NDRF team...');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.my_location_rounded, size: 18),
            label: const Text('Send SOS Alert'),
          ),
        ],
      ),
    );
  }

  Widget _emergencyCallTile(String title, String number) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E9EE)),
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
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  Text(
                    number,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.red,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.phone_in_talk_rounded,
                color: AppColors.green,
              ),
              onPressed: () => _showMessage('Dialing $number...'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9F4FB),
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            // 1. Unified Command Strip (matches citizen top strip)
            _buildCommandBanner(),

            // 2. PINNED TOP SECTION: Interactive Live Map (~225px high)
            _buildPinnedMapSection(),

            // 3. SCROLLABLE BOTTOM SECTION (matches citizen container flow)
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 3a. BIG STATUS CARD (NORMAL / WARNING / EVACUATION)
                    _buildStatusCard(),

                    const SizedBox(height: 14),

                    // 3b. LIVE SITUATION KA DABBA (Real-time river & rain telemetry container)
                    _buildLiveSituationContainer(),

                    const SizedBox(height: 14),

                    // 3c. LIVE ALERT & CRITICAL ALERTS KA DABBA
                    _buildCriticalAlertsContainer(),

                    const SizedBox(height: 14),

                    // 3d. 7 AUTHORITIES COMMAND MODULES (Mission Operations Consoles)
                    _buildAuthorityCommandHub(),

                    const SizedBox(height: 14),

                    // 3e. SINGLE SHELTER OPTION (clean card instead of huge full container)
                    _buildShelterOptionCard(),

                    const SizedBox(height: 10),

                    // 3e. SINGLE MEDICAL & AMBULANCE OPTION (clean card instead of huge full container)
                    _buildMedicalOptionCard(),

                    const SizedBox(height: 14),

                    // 3f. PRIORITY EVACUATION CORRIDOR CARD
                    _buildSafeRouteBanner(),

                    const SizedBox(height: 14),

                    // 3g. EMERGENCY HELPLINE ROW
                    _buildHelplineRow(),

                    const SizedBox(height: 20),

                    _buildBottomMessage(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // ==========================================================
  // APP BAR (MATCHING CITIZEN DASHBOARD)
  // ==========================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF013973)),
        tooltip: 'Change Role',
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/app_logo.png',
            width: 28,
            height: 28,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 8),
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Res',
                  style: TextStyle(
                    color: Color(0xFF013973),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                TextSpan(
                  text: 'Q',
                  style: TextStyle(
                    color: Color(0xFF00FF00),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(
                        color: Color(0x6600FF00),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                TextSpan(
                  text: 'Shield',
                  style: TextStyle(
                    color: Color(0xFF013973),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF013973).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: const Color(0xFF013973).withValues(alpha: 0.3),
              ),
            ),
            child: const Text(
              'AUTHORITY',
              style: TextStyle(
                color: Color(0xFF013973),
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8F0),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF15945C)),
            ),
            child: Row(
              children: const [
                Icon(Icons.radar_rounded, size: 14, color: Color(0xFF15945C)),
                SizedBox(width: 4),
                Text(
                  'LIVE TELEMETRY',
                  style: TextStyle(
                    color: Color(0xFF15945C),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // UNIFIED COMMAND BANNER (MATCHING CITIZEN OFFLINE BANNER)
  // ==========================================================

  Widget _buildCommandBanner() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF013973),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.shield_rounded, color: Color(0xFF38BDF8), size: 14),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              'NDRF & SDMA Unified Command Center • Live River Gauges Stream',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // PINNED MAP SECTION (ENLARGED & OVERFLOW-PROOFED)
  // ==========================================================

  Widget _buildPinnedMapSection() {
    final center = _effectiveCenter;
    final shelterPos =
        LatLng(center.latitude + 0.012, center.longitude + 0.015);
    final dangerZone =
        LatLng(center.latitude - 0.008, center.longitude - 0.006);

    return Container(
      height: 270,
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBEDCF5), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0E013973),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.5),
        child: Stack(
          children: [
            // 1. Direct FlutterMap (Fits container 100% without any overflow)
            Positioned.fill(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 13.0,
                  minZoom: 8.0,
                  maxZoom: 18.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.resqshield.app',
                  ),
                  // Inundation Danger Polygon Circle
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: dangerZone,
                        radius: 1200,
                        useRadiusInMeter: true,
                        color: const Color(0xFFDC2626).withValues(alpha: 0.28),
                        borderColor: const Color(0xFFDC2626),
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),
                  // Safe Route Polyline Corridor
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [
                          center,
                          LatLng(center.latitude + 0.005,
                              center.longitude + 0.008),
                          shelterPos,
                        ],
                        color: const Color(0xFF15945C),
                        strokeWidth: 4.0,
                      ),
                    ],
                  ),
                  // Map Markers
                  MarkerLayer(
                    markers: [
                      // User / Authority GPS Location Beacon
                      Marker(
                        point: center,
                        width: 44,
                        height: 44,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF007AEB),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 6,
                                  offset: Offset(0, 2)),
                            ],
                          ),
                          child: const Icon(Icons.my_location_rounded,
                              color: Colors.white, size: 22),
                        ),
                      ),
                      // River Flood Danger Marker
                      Marker(
                        point: dangerZone,
                        width: 36,
                        height: 36,
                        child: GestureDetector(
                          onTap: () => _showMessage(
                              'River Water Level: 8.4m (CRITICAL DANGER)'),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626),
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 2),
                              boxShadow: const [
                                BoxShadow(
                                    color: Colors.black26, blurRadius: 6),
                              ],
                            ),
                            child: const Icon(Icons.warning_amber_rounded,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                      // Safe Shelter Marker
                      Marker(
                        point: shelterPos,
                        width: 36,
                        height: 36,
                        child: GestureDetector(
                          onTap: () => _showMessage(
                              'Govt Shelter: 320 beds available'),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF15945C),
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 2),
                              boxShadow: const [
                                BoxShadow(
                                    color: Colors.black26, blurRadius: 6),
                              ],
                            ),
                            child: const Icon(Icons.night_shelter_rounded,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. Location Chip
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD6E8F7)),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_rounded,
                        size: 14, color: Color(0xFF007AEB)),
                    const SizedBox(width: 4),
                    Text(
                      _locationText,
                      style: const TextStyle(
                        color: Color(0xFF013973),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Top-Right Controls (GIS Map Button + Recenter)
            Positioned(
              top: 10,
              right: 10,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HazardMapScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF013973),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.fullscreen_rounded,
                              size: 15, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'GIS Map',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.my_location_rounded,
                          size: 16, color: Color(0xFF013973)),
                      onPressed: () {
                        _mapController.move(center, 13.0);
                        _showMessage('Recentered to GPS location');
                      },
                      tooltip: 'Recenter GPS',
                    ),
                  ),
                ],
              ),
            ),

            // 4. Bottom GIS Layers Indicator Chip
            Positioned(
              bottom: 8,
              right: 10,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HazardMapScreen(),
                    ),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.70),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.layers_rounded,
                          size: 12, color: Color(0xFF38BDF8)),
                      SizedBox(width: 4),
                      Text(
                        'GIS Layers & Village Lead-Times',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
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

  // ==========================================================
  // STATUS CARD (MATCHING CITIZEN STATUS CARD)
  // ==========================================================

  Widget _buildStatusCard() {
    Color cardColor;
    Color borderColor;
    Color textColor;
    IconData icon;
    String statusTitle;
    String statusExplanation;

    switch (_threatLevel) {
      case 0:
        cardColor = const Color(0xFFEAF8F0);
        borderColor = const Color(0xFF15945C);
        textColor = const Color(0xFF15945C);
        icon = Icons.check_circle_rounded;
        statusTitle = 'ALL GAUGE LEVELS NORMAL';
        statusExplanation =
            'Damodar & Barakar River gauges are flowing below warning threshold (68.40m). Runoff flow is stable.';
        break;
      case 1:
        cardColor = const Color(0xFFFFF7ED);
        borderColor = const Color(0xFFF97316);
        textColor = const Color(0xFFC2410C);
        icon = Icons.warning_amber_rounded;
        statusTitle = 'HIGH FLOOD ALERT • STAGE 2';
        statusExplanation =
            'Damodar River gauge at 74.80m (Danger: 74.00m). Sluice gates open. Evacuation standby in low-lying wards.';
        break;
      case 2:
      default:
        cardColor = const Color(0xFFFEF2F2);
        borderColor = const Color(0xFFEF4444);
        textColor = const Color(0xFFB91C1C);
        icon = Icons.dangerous_rounded;
        statusTitle = 'CRITICAL FLOOD EVACUATION';
        statusExplanation =
            'Immediate evacuation ordered for Flood Plain Sectors 1-6. NDRF QRT and SDRF units deployed on site.';
        break;
    }

    final time = DateTime.now();
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} IST';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: textColor, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    statusTitle,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Updated: $timeStr',
                  style: const TextStyle(
                    color: Color(0xFF013973),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            statusExplanation,
            style: const TextStyle(
              color: Color(0xFF0F2642),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                'Demo Level:',
                style: TextStyle(
                  color: Color(0xFF537392),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              _demoStatusDot(0, '🟢', const Color(0xFF15945C)),
              const SizedBox(width: 4),
              _demoStatusDot(1, '🟠', const Color(0xFFF39A20)),
              const SizedBox(width: 4),
              _demoStatusDot(2, '🔴', const Color(0xFFE92828)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _demoStatusDot(int lvl, String emoji, Color color) {
    final isSelected = _threatLevel == lvl;
    return GestureDetector(
      onTap: () => setState(() => _threatLevel = lvl),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: isSelected ? Border.all(color: color, width: 1.2) : null,
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  // ==========================================================
  // LIVE SITUATION CONTAINER (TELEMETRY HUB)
  // ==========================================================

  Widget _buildLiveSituationContainer() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD6E8F7), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C013973),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: Color(0xFF007AEB),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x66007AEB),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Live Situation',
                style: TextStyle(
                  color: Color(0xFF013973),
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F3FD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.sensors_rounded, size: 13, color: Color(0xFF007AEB)),
                    SizedBox(width: 4),
                    Text(
                      'Telemetry Stream',
                      style: TextStyle(
                        color: Color(0xFF007AEB),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _situationTile(
                  title: 'River Level',
                  value: '8.2 m',
                  subtitle: 'Critical Rising ↑',
                  icon: Icons.water_rounded,
                  accentColor: const Color(0xFFEF4444),
                  bgTint: const Color(0xFFFEF2F2),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RiverLevelDetailScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _situationTile(
                  title: 'Rainfall',
                  value: '128 mm',
                  subtitle: 'Past 6 Hours',
                  icon: Icons.cloud_download_rounded,
                  accentColor: const Color(0xFF0284C7),
                  bgTint: const Color(0xFFF0F9FF),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RainfallDetailScreen(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _situationTile(
                  title: 'Rescue Teams',
                  value: '14 Teams',
                  subtitle: 'Active On Ground',
                  icon: Icons.support_rounded,
                  accentColor: const Color(0xFF10B981),
                  bgTint: const Color(0xFFECFDF5),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RescueTeamsDetailScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _situationTile(
                  title: 'Affected People',
                  value: '12,450',
                  subtitle: 'In 18 Areas',
                  icon: Icons.people_alt_rounded,
                  accentColor: const Color(0xFFF59E0B),
                  bgTint: const Color(0xFFFFFBEB),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AffectedPeopleDetailScreen(),
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

  Widget _situationTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color bgTint,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgTint,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accentColor.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.15),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: accentColor, size: 16),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 11,
                  color: accentColor.withValues(alpha: 0.7),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF013973),
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: accentColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // LIVE CRITICAL ALERTS CONTAINER
  // ==========================================================

  Widget _buildCriticalAlertsContainer() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD6E8F7), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C013973),
            blurRadius: 14,
            offset: Offset(0, 4),
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
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFDC2626),
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Live Critical Alerts',
                style: TextStyle(
                  color: Color(0xFF013973),
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '3 ACTIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _criticalAlertTile(
            title: 'High Flood Risk Alert',
            area: 'Periyar & Damodar Basin • Sector 4 & 5',
            description:
                'River level at 8.2m (Danger: 7.4m). Evacuate low-lying riverbanks immediately.',
            severity: 'CRITICAL',
            time: '5m ago',
            color: const Color(0xFFDC2626),
            bgColor: const Color(0xFFFEF2F2),
            icon: Icons.flood_rounded,
          ),
          const SizedBox(height: 10),
          _criticalAlertTile(
            title: 'Heavy Rainfall Warning',
            area: 'Central Disaster Zone • Red Alert',
            description:
                'IMD forecasts 180-210mm torrential rain over next 12 hours. Severe waterlogging expected.',
            severity: 'RED ALERT',
            time: '20m ago',
            color: const Color(0xFFEA580C),
            bgColor: const Color(0xFFFFF7ED),
            icon: Icons.thunderstorm_rounded,
          ),
          const SizedBox(height: 10),
          _criticalAlertTile(
            title: 'Dam Water Release Notice',
            area: 'Idamalayar Reservoir & Sluice Gates',
            description:
                'Controlled discharge of 12,000 cusecs active. River surge expected downstream within 2 hours.',
            severity: 'WARNING',
            time: '45m ago',
            color: const Color(0xFFD97706),
            bgColor: const Color(0xFFFFFBEB),
            icon: Icons.water_damage_rounded,
          ),
        ],
      ),
    );
  }

  Widget _criticalAlertTile({
    required String title,
    required String area,
    required String description,
    required String severity,
    required String time,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return InkWell(
      onTap: () => _showMessage('$title: $area'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    severity,
                    style: TextStyle(
                      color: color,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  time,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              area,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // AUTHORITIES COMMAND CENTER: 7 MISSION MODULES
  // ==========================================================

  Widget _buildAuthorityCommandHub() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD6E8F7), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C013973),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F3FD),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.dashboard_customize_rounded,
                  color: Color(0xFF007AEB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'AUTHORITIES COMMAND HUB',
                    style: TextStyle(
                      color: Color(0xFF013973),
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Text(
                    '7 Integrated District Mission Consoles',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 1. Live Hazard Map (GIS)
          _commandTile(
            icon: Icons.map_rounded,
            title: '1. Live Hazard Map (GIS)',
            subtitle: 'District GIS layers, village risk zones & lead-times',
            badge: 'GIS ACTIVE',
            badgeColor: const Color(0xFF007AEB),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HazardMapScreen()),
            ),
          ),
          const SizedBox(height: 8),

          // 2. Village Risk Table
          _commandTile(
            icon: Icons.table_chart_rounded,
            title: '2. Village Risk Table',
            subtitle: 'Sortable matrix, cut-off isolation & offline briefing export',
            badge: '8 MONITORED',
            badgeColor: const Color(0xFFD97706),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VillageRiskTableScreen()),
            ),
          ),
          const SizedBox(height: 8),

          // 3. Alert Dispatch Panel
          _commandTile(
            icon: Icons.emergency_share_rounded,
            title: '3. Alert Dispatch Panel',
            subtitle: 'SMS, Cell Broadcast, IoT Sirens & Push Alert broadcast',
            badge: 'DISPATCH READY',
            badgeColor: const Color(0xFFDC2626),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AlertDispatchScreen()),
            ),
          ),
          const SizedBox(height: 8),

          // 4. Resource & Shelter Map
          _commandTile(
            icon: Icons.hub_rounded,
            title: '4. Resource & Shelter Map',
            subtitle: 'NDRF units, shelter capacities, ICU beds & road bridges',
            badge: 'LIVE TELEMETRY',
            badgeColor: const Color(0xFF16A34A),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ResourceShelterMapScreen()),
            ),
          ),
          const SizedBox(height: 8),

          // 5. Trends & Hydro Forecast
          _commandTile(
            icon: Icons.auto_graph_rounded,
            title: '5. Trends & Hydro Forecast',
            subtitle: '24-72h hyetograph, river graphs & AI risk trajectories',
            badge: 'FORECAST MODEL',
            badgeColor: const Color(0xFF7C3AED),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TrendsForecastScreen()),
            ),
          ),
          const SizedBox(height: 8),

          // 6. Dam Coordination Panel
          _commandTile(
            icon: Icons.water_damage_rounded,
            title: '6. Dam Coordination Panel',
            subtitle: 'Reservoir levels, release schedule & auto-downstream alert',
            badge: '96% CAPACITY',
            badgeColor: const Color(0xFFDC2626),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DamCoordinationScreen()),
            ),
          ),
          const SizedBox(height: 8),

          // 7. Agency Coordination Log
          _commandTile(
            icon: Icons.fact_check_rounded,
            title: '7. Agency Coordination Log',
            subtitle: 'Timestamped inter-agency dispatch records & accountability',
            badge: 'AUDIT TRAIL',
            badgeColor: const Color(0xFF0F172A),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CoordinationLogScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _commandTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: badgeColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                            color: Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 11, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // SINGLE COMPACT SHELTER OPTION
  // ==========================================================

  Widget _buildShelterOptionCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD6E8F7), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C013973),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE6F3FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.home_work_rounded,
              color: Color(0xFF007AEB),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Safe Shelters & Relief Camps',
                  style: TextStyle(
                    color: Color(0xFF013973),
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '28 Camps Active • 1,420 Available Beds',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _showSheltersModal,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007AEB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text(
              'View',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _showSheltersModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.72,
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Row(
                children: [
                  const Text(
                    'Nearby Safe Shelters',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF013973),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _modalShelterCard(
                    name: 'Govt. Higher Secondary School',
                    location: 'Kochi Central • 1.2 km away',
                    capacity: '500 Capacity (320 Available)',
                    status: 'OPEN',
                    phone: '0484-242231',
                  ),
                  const SizedBox(height: 10),
                  _modalShelterCard(
                    name: 'St. Mary Community Hall',
                    location: 'Aluva Riverside • 2.5 km away',
                    capacity: '300 Capacity (120 Available)',
                    status: 'OPEN',
                    phone: '0484-263341',
                  ),
                  const SizedBox(height: 10),
                  _modalShelterCard(
                    name: 'Municipal Indoor Stadium',
                    location: 'Ernakulam North • 3.8 km away',
                    capacity: '800 Capacity (450 Available)',
                    status: 'FILLING FAST',
                    phone: '0484-284451',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modalShelterCard({
    required String name,
    required String location,
    required String capacity,
    required String status,
    required String phone,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: Color(0xFF15803D),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            location,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
          Text(
            capacity,
            style: const TextStyle(
              color: Color(0xFF0284C7),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () =>
                    _showMessage('Calling shelter coordinator: $phone'),
                icon: const Icon(Icons.phone_rounded, size: 14),
                label:
                    Text('Call ($phone)', style: const TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showMessage('Navigating to $name'),
                icon: const Icon(Icons.directions_rounded, size: 14),
                label: const Text('Directions', style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AEB),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SINGLE COMPACT MEDICAL & AMBULANCE OPTION
  // ==========================================================

  Widget _buildMedicalOptionCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD6E8F7), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C013973),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_hospital_rounded,
              color: Color(0xFFEF4444),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Medical & Ambulance Dispatch',
                  style: TextStyle(
                    color: Color(0xFF013973),
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '12 Hospitals • ICU Ready • Dial 108',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () =>
                _showMessage('Emergency Ambulance Helpline: Dialing 108...'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Call 108',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SAFE ROUTE BANNER (MATCHING CITIZEN DASHBOARD)
  // ==========================================================

  Widget _buildSafeRouteBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD6E8F7)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF013973).withValues(alpha: 0.05),
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
                  color: const Color(0xFF15945C).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.alt_route_rounded,
                  color: Color(0xFF15945C),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Priority Corridor: Bypass NH-32 Highground',
                      style: TextStyle(
                        color: Color(0xFF013973),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Clear of water accumulation • 1.2 km to Safe Shelter',
                      style: TextStyle(
                        color: Color(0xFF537392),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () =>
                _showMessage('Tactical Safe Evacuation Routes Activated'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF15945C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.navigation_rounded, size: 18),
                SizedBox(width: 8),
                Text(
                  'Deploy Tactical Evacuation Path',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // EMERGENCY HELPLINE ROW (MATCHING CITIZEN DASHBOARD)
  // ==========================================================

  Widget _buildHelplineRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD6E8F7)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _helplineItem('112', 'Emergency Command',
              () => _showMessage('Dialing 112...')),
          Container(width: 1, height: 24, color: const Color(0xFFE5E9EE)),
          _helplineItem('1070', 'NDMA Helpline',
              () => _showMessage('Dialing 1070...')),
          Container(width: 1, height: 24, color: const Color(0xFFE5E9EE)),
          _helplineItem('108', 'Disaster Ambulance',
              () => _showMessage('Dialing 108...')),
        ],
      ),
    );
  }

  Widget _helplineItem(String number, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        children: [
          Text(
            number,
            style: const TextStyle(
              color: Color(0xFFE92828),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF537392),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // HEADER
  // ==========================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          _roundIconButton(
            icon: Icons.menu_rounded,
            onTap: () {
              _showMessage('Menu opened');
            },
          ),

          const Spacer(),

          Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    padding: const EdgeInsets.all(2),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Res',
                          style: TextStyle(
                            color: Color(0xFF013973),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        TextSpan(
                          text: 'Q',
                          style: TextStyle(
                            color: Color(0xFF00FF00),
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                            shadows: [
                              Shadow(
                                color: Color(0x5500FF00),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        TextSpan(
                          text: 'Shield',
                          style: TextStyle(
                            color: Color(0xFF013973),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                'Safer Routes. Stronger Communities.',
                style: TextStyle(
                  color: const Color(0xFF013973).withValues(alpha: 0.75),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),

          const Spacer(),

          Stack(
            clipBehavior: Clip.none,
            children: [
              _roundIconButton(
                icon: Icons.notifications_none_rounded,
                onTap: () {
                  _showMessage('3 new alerts');
                },
              ),

              Positioned(
                right: -1,
                top: -3,
                child: Container(
                  width: 19,
                  height: 19,
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22E92828),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      '3',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
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

  Widget _roundIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFD6E8F7), width: 1.1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C013973),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: onTap,
          child: Center(
            child: Icon(
              icon,
              color: const Color(0xFF013973),
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // LOCATION CARD
  // ==========================================================

  Widget _buildLocationCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFD6E8F7),
            width: 1.2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C013973),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFE6F3FD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFCCE4FA),
                  width: 1.0,
                ),
              ),
              child: const Icon(
                Icons.my_location_rounded,
                color: Color(0xFF007AEB),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Aapki Current Location',
                    style: TextStyle(
                      color: Color(0xFF537392),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  _locationLoading
                      ? Row(
                          children: [
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.8,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF007AEB),
                                ),
                              ),
                            ),
                            const SizedBox(width: 7),
                            const Text(
                              'Locating...',
                              style: TextStyle(
                                color: Color(0xFF537392),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          _locationText,
                          style: const TextStyle(
                            color: Color(0xFF013973),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                ],
              ),
            ),
            // Refresh button
            GestureDetector(
              onTap: () {
                setState(() {
                  _locationLoading = true;
                  _locationText = 'Locating...';
                });
                _fetchLocation();
              },
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F3FD),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFCCE4FA),
                    width: 1.0,
                  ),
                ),
                child: const Icon(
                  Icons.refresh_rounded,
                  color: Color(0xFF007AEB),
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // MAIN FLOOD ALERT
  // ==========================================================

  Widget _buildMainAlert() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFD6E8F7),
            width: 1.2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12007AEB),
              blurRadius: 14,
              offset: Offset(0, 5),
            ),
            BoxShadow(
              color: Color(0x0C013973),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 960 / 316,
                child: Image.asset(
                  'assets/images/flood_risk_high_banner.png',
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(19),
                    onTap: () {
                      _showMessage('Flood details opened');
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // LIVE SITUATION
  // ==========================================================

  Widget _buildLiveSituation() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFD6E8F7),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C013973),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF007AEB),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x66007AEB),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Live Situation',
                style: TextStyle(
                  color: Color(0xFF013973),
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  _showMessage('Map opened');
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'View Map',
                      style: TextStyle(
                        color: Color(0xFF007AEB),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 3),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Color(0xFF007AEB),
                      size: 13,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              _imageSituationCard(
                imagePath: 'assets/images/river_level_card.png',
                fallbackTitle: 'River Level',
                fallbackValue: '8.2 m',
                fallbackSub: 'Rising Fast ↑',
                fallbackAccent: const Color(0xFFEF4444),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RiverLevelDetailScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(width: 10),

              _imageSituationCard(
                imagePath: 'assets/images/rainfall_card.png',
                fallbackTitle: 'Rainfall',
                fallbackValue: '128 mm',
                fallbackSub: 'Last 6 hrs',
                fallbackAccent: const Color(0xFF3B82F6),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RainfallDetailScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              _imageSituationCard(
                imagePath: 'assets/images/affected_people_card.png',
                fallbackTitle: 'Affected People',
                fallbackValue: '12,450',
                fallbackSub: 'In 18 Areas',
                fallbackAccent: const Color(0xFFF59E0B),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AffectedPeopleDetailScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(width: 10),

              _imageSituationCard(
                imagePath: 'assets/images/rescue_teams_card.png',
                fallbackTitle: 'Rescue Teams',
                fallbackValue: '24',
                fallbackSub: 'Active',
                fallbackAccent: const Color(0xFFA855F7),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RescueTeamsDetailScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _imageSituationCard({
    required String imagePath,
    required String fallbackTitle,
    required String fallbackValue,
    required String fallbackSub,
    required Color fallbackAccent,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 1.28,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFD6E8F7),
                width: 1.2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A013973),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Image.asset(
                imagePath,
                fit: BoxFit.fill,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFF1F6FB),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fallbackTitle,
                        style: const TextStyle(
                          color: Color(0xFF013973),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fallbackValue,
                        style: const TextStyle(
                          color: Color(0xFF0F2642),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fallbackSub,
                        style: TextStyle(
                          color: fallbackAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // QUICK SITUATION
  // ==========================================================

  Widget _buildQuickSituation() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFD6E8F7),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C013973),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3.5,
                height: 17,
                decoration: BoxDecoration(
                  color: const Color(0xFF007AEB),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Quick Situation',
                style: TextStyle(
                  color: Color(0xFF013973),
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Color(0xFF007AEB),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _qsCard(
                imagePath: 'assets/images/qs_sos_card.png',
                accentColor: const Color(0xFFEF4444),
                onTap: () {
                  _showEmergencyDialog();
                },
              ),
              const SizedBox(width: 6),
              _qsCard(
                imagePath: 'assets/images/qs_shelter_card.png',
                accentColor: const Color(0xFF34D399),
                onTap: () {
                  _showMessage('Finding nearby shelters...');
                },
              ),
              const SizedBox(width: 6),
              _qsCard(
                imagePath: 'assets/images/qs_medical_card.png',
                accentColor: const Color(0xFF38BDF8),
                onTap: () {
                  _showMessage('Finding medical help...');
                },
              ),
              const SizedBox(width: 6),
              _qsCard(
                imagePath: 'assets/images/qs_safe_route_card.png',
                accentColor: const Color(0xFFA78BFA),
                onTap: () {
                  _showMessage('Safe route finder opened');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qsCard({
    required String imagePath,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.40),
            width: 1.1,
          ),
          boxShadow: [
            const BoxShadow(
              color: Color(0x0A013973),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
            BoxShadow(
              color: accentColor.withValues(alpha: 0.14),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 230 / 294,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFF1F6FB),
                  ),
                ),
              ),
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: onTap,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // FLOOD MAP
  // ==========================================================

  Widget _buildFloodMap() {
    return LiveFloodMapWidget(
      latitude: _latitude,
      longitude: _longitude,
      locationName: _locationText,
    );
  }

  // ==========================================================
  // SECTION CAPTION
  // ==========================================================

  Widget _buildSectionCaption({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFE6F3FD),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFCCE4FA),
                width: 1.0,
              ),
            ),
            child: Center(
              child: Icon(
                icon,
                color: const Color(0xFF007AEB),
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF013973),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF537392),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // LATEST ALERTS
  // ==========================================================

  Widget _buildLatestAlerts() {
    return Column(
      children: [
        _buildAlertImageCard('assets/images/alert_flood_risk_card.png', 'High Flood Risk alert'),
        const SizedBox(height: 14),
        _buildAlertImageCard('assets/images/alert_rainfall_card.png', 'Heavy Rainfall alert'),
        const SizedBox(height: 14),
        _buildAlertImageCard('assets/images/alert_dam_release_card.png', 'Dam Water Release alert'),
      ],
    );
  }

  Widget _buildAlertImageCard(String imagePath, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: GestureDetector(
        onTap: () {
          _showMessage(message);
        },
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFD6E8F7),
              width: 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C013973),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
              BoxShadow(
                color: Color(0x12007AEB),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // DOS AND DON'TS
  // ==========================================================

  Widget _buildDosDonts() {
    return DosDontsSection(
      onViewAll: () {
        _showMessage('Safety guidelines opened');
      },
      onShowMessage: (msg) => _showMessage(msg),
    );
  }

  // ==========================================================
  // ==========================================================
  // SHELTERS (MODERN CARD UI MATCHING SCREENSHOT)
  // ==========================================================

  Widget _buildNearbyShelters() {
    final shelters = [
      const _ShelterData(
        imagePath: 'assets/images/shelter_school.jpg',
        category: 'Government',
        categoryIcon: Icons.account_balance_outlined,
        categoryBg: Color(0xFFEBF5FF),
        categoryColor: Color(0xFF1D70B8),
        status: 'Open',
        isOpen: true,
        name: 'Govt. Higher Secondary School',
        location: 'Bokaro, Jharkhand',
        capacity: '500',
        available: '320',
        foodAvailable: true,
        foodWarning: false,
        waterAvailable: true,
        filterCategory: 'Govt.',
      ),
      const _ShelterData(
        imagePath: 'assets/images/shelter_community.jpg',
        category: 'Community',
        categoryIcon: Icons.groups_outlined,
        categoryBg: Color(0xFFE8F5E9),
        categoryColor: Color(0xFF2E7D32),
        status: 'Limited',
        isOpen: false,
        name: 'Community Hall, Kurma',
        location: 'Giridih, Jharkhand',
        capacity: '300',
        available: '120',
        foodAvailable: true,
        foodWarning: true,
        waterAvailable: true,
        filterCategory: 'Community',
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD6E8F7), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C013973),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Banner matching the relief header
          _buildSheltersHeader(),

          const SizedBox(height: 12),

          // 2 Shelter Cards
          ...shelters.map((shelter) => Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: _shelterCard(shelter),
              )),

          const SizedBox(height: 2),

          // View All Shelters Button
          _outlineButton(
            text: 'View All Shelters (28)',
            icon: Icons.home_work_rounded,
            onTap: () {
              _showMessage('All 28 relief shelters opened');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSheltersHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF072B4E), Color(0xFF0E4574), Color(0xFF135A94)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF072B4E).withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: Color(0xFF7DD3FC),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Nearby Shelters',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Find safe places near you',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              _showMessage('Opening live shelter map...');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.map_outlined,
                    color: Colors.white,
                    size: 12,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'View Map →',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
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

  Widget _shelterCard(_ShelterData data) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEF5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Real Photo
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 105,
              height: 112,
              child: Image.asset(
                data.imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFE2E8F0),
                  child: const Center(
                    child: Icon(
                      Icons.apartment_rounded,
                      color: Color(0xFF94A3B8),
                      size: 36,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Right Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Category + Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: data.categoryBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            data.categoryIcon,
                            size: 11,
                            color: data.categoryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            data.category,
                            style: TextStyle(
                              color: data.categoryColor,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: data.isOpen
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                        border: data.isOpen
                            ? null
                            : Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            data.isOpen
                                ? Icons.check_circle_rounded
                                : Icons.warning_amber_rounded,
                            size: 11,
                            color: data.isOpen
                                ? Colors.white
                                : const Color(0xFFD97706),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            data.status,
                            style: TextStyle(
                              color: data.isOpen
                                  ? Colors.white
                                  : const Color(0xFFD97706),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                // Name
                Text(
                  data.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 2),

                // Location
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 11,
                      color: Color(0xFF1D70B8),
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        data.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                // Stats: Capacity & Available + Arrow
                Row(
                  children: [
                    const Icon(
                      Icons.groups_rounded,
                      size: 13,
                      color: Color(0xFF1E3A5F),
                    ),
                    const SizedBox(width: 4),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Capacity',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 7.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          data.capacity,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.person_add_alt_1_rounded,
                      size: 13,
                      color: Color(0xFF16A34A),
                    ),
                    const SizedBox(width: 4),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Available',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 7.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          data.available,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFF1F5F9),
                      ),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Color(0xFF1E3A5F),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                // Amenities Capsule
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F7FD),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.restaurant_rounded,
                        size: 11,
                        color: Color(0xFF1E3A5F),
                      ),
                      const SizedBox(width: 3),
                      const Text(
                        'Food',
                        style: TextStyle(
                          fontSize: 9,
                          color: Color(0xFF334155),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        data.foodWarning
                            ? Icons.warning_rounded
                            : Icons.check_circle_rounded,
                        size: 11,
                        color: data.foodWarning
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF16A34A),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.water_drop_rounded,
                        size: 11,
                        color: Color(0xFF0284C7),
                      ),
                      const SizedBox(width: 3),
                      const Text(
                        'Water',
                        style: TextStyle(
                          fontSize: 9,
                          color: Color(0xFF334155),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 11,
                        color: Color(0xFF16A34A),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // ==========================================================
  // RELIEF CAMPS & DISTRIBUTION POINTS (MATCHING SCREENSHOT)
  // ==========================================================

  Widget _buildReliefPoints() {
    final reliefCamps = [
      const _ReliefCampData(
        imagePath: 'assets/images/relief_bokaro.jpg',
        name: 'Bokaro Relief Camp',
        location: 'Bokaro, Jharkhand',
        food: '1200 packets',
        water: '1800 bottles',
        distance: '2.8 km away',
        status: 'Active',
        isActive: true,
      ),
      const _ReliefCampData(
        imagePath: 'assets/images/relief_dhanbad.jpg',
        name: 'Dhanbad Relief Camp',
        location: 'Dhanbad, Jharkhand',
        food: '950 packets',
        water: '1500 bottles',
        distance: '3.6 km away',
        status: 'Low Stock',
        isActive: false,
      ),
      const _ReliefCampData(
        imagePath: 'assets/images/relief_giridih.jpg',
        name: 'Giridih Relief Camp',
        location: 'Giridih, Jharkhand',
        food: '700 packets',
        water: '1200 bottles',
        distance: '5.1 km away',
        status: 'Active',
        isActive: true,
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD6E8F7), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C013973),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Banner matching the screenshot
          _buildReliefHeader(),

          const SizedBox(height: 12),

          // 3 Relief Camp Cards
          ...reliefCamps.map((camp) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _reliefCampCard(camp),
              )),

          const SizedBox(height: 2),

          // View All Relief Camps Button
          _outlineButton(
            text: 'View All Relief Camps (36)',
            icon: Icons.holiday_village_rounded,
            onTap: () {
              _showMessage('All 36 relief distribution camps opened');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReliefHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF072B4E), Color(0xFF0E4574), Color(0xFF135A94)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF072B4E).withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: const Icon(
              Icons.holiday_village_rounded,
              color: Color(0xFF7DD3FC),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Relief Camps',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Find nearby relief camps with food, water and essential supplies.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              _showMessage('Showing camps for Jharkhand');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5.5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.location_on_rounded, color: Colors.white, size: 11),
                  SizedBox(width: 3),
                  Text(
                    'Jharkhand',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 13),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reliefCampCard(_ReliefCampData data) {
    return InkWell(
      onTap: () {
        _showMessage('Opening ${data.name} details...');
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(8.5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFCCE4EC), width: 1.1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                data.imagePath,
                width: 108,
                height: 82,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 108,
                    height: 82,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F2642).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.image_not_supported_rounded,
                      color: Color(0xFF64748B),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(width: 10),

            // Middle Details Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Status Badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF0B2238),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: data.isActive
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: data.isActive
                                ? const Color(0xFF86EFAC)
                                : const Color(0xFFFDE68A),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5.5,
                              height: 5.5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: data.isActive
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFD97706),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              data.status,
                              style: TextStyle(
                                color: data.isActive
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFD97706),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 3),

                  // Location
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 11.5,
                        color: Color(0xFF0284C7),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          data.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Food
                  Row(
                    children: [
                      const Icon(
                        Icons.roofing_rounded,
                        size: 12,
                        color: Color(0xFF0F2642),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Food:  ',
                        style: TextStyle(
                          fontSize: 9.5,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        data.food,
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 2.5),

                  // Water
                  Row(
                    children: [
                      const Icon(
                        Icons.water_drop_rounded,
                        size: 11.5,
                        color: Color(0xFF0284C7),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Water: ',
                        style: TextStyle(
                          fontSize: 9.5,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        data.water,
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 2.5),

                  // Distance
                  Row(
                    children: [
                      const Icon(
                        Icons.alt_route_rounded,
                        size: 11.5,
                        color: Color(0xFF0F2642),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        data.distance,
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 4),

            // Chevron Right Arrow
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF0284C7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // MEDICAL FACILITIES (MATCHING SCREENSHOT)
  // ==========================================================

  Widget _buildMedicalFacilities() {
    final hospitals = [
      const _HospitalData(
        imagePath: 'assets/images/hospital_ranchi.jpg',
        name: 'Ranchi Sadar Hospital',
        location: 'Kanke, Ranchi, Jharkhand',
        beds: '450 / 650',
        icuAvailable: '40 / 60',
        distance: '2.8 km away',
        status: 'Open',
        isOpen: true,
      ),
      const _HospitalData(
        imagePath: 'assets/images/hospital_dhanbad.jpg',
        name: 'Dhanbad Medical College & Hospital',
        location: 'Sindri Road, Dhanbad, Jharkhand',
        beds: '320 / 500',
        icuAvailable: '25 / 40',
        distance: '3.6 km away',
        status: 'Open',
        isOpen: true,
      ),
      const _HospitalData(
        imagePath: 'assets/images/hospital_giridih.jpg',
        name: 'Giridih Sadar Hospital',
        location: 'Giridih, Jharkhand',
        beds: '210 / 350',
        icuAvailable: '18 / 30',
        distance: '5.2 km away',
        status: 'Open',
        isOpen: true,
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD6E8F7), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C013973),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Banner matching the screenshot
          _buildMedicalHeader(),

          const SizedBox(height: 12),

          // 3 Hospital Cards
          ...hospitals.map((hospital) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _hospitalCard(hospital),
              )),

          const SizedBox(height: 2),

          // View All Hospitals Button
          _outlineButton(
            text: 'View All Hospitals (48)',
            icon: Icons.local_hospital_rounded,
            onTap: () {
              _showMessage('All 48 hospitals and healthcare centers opened');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF072B4E), Color(0xFF0E4574), Color(0xFF135A94)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF072B4E).withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: const Icon(
              Icons.local_hospital_rounded,
              color: Color(0xFF7DD3FC),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Medical Facilities',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Nearby hospitals and healthcare centers in flood-affected areas of Jharkhand.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              _showMessage('Showing medical facilities for Jharkhand');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5.5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.location_on_rounded, color: Colors.white, size: 11),
                  SizedBox(width: 3),
                  Text(
                    'Jharkhand',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 13),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hospitalCard(_HospitalData data) {
    return InkWell(
      onTap: () {
        _showMessage('Opening ${data.name} details & bed availability...');
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(8.5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFCCE4EC), width: 1.1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Hospital Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                data.imagePath,
                width: 108,
                height: 82,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 108,
                    height: 82,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F2642).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.local_hospital_rounded,
                      color: Color(0xFF64748B),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(width: 10),

            // Middle Details Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Status Badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF0B2238),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: data.isOpen
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: data.isOpen
                                ? const Color(0xFF86EFAC)
                                : const Color(0xFFFDE68A),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5.5,
                              height: 5.5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: data.isOpen
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFD97706),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              data.status,
                              style: TextStyle(
                                color: data.isOpen
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFD97706),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 3),

                  // Location
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 11.5,
                        color: Color(0xFF0284C7),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          data.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Beds
                  Row(
                    children: [
                      const Icon(
                        Icons.hotel_rounded,
                        size: 12,
                        color: Color(0xFF0F2642),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Beds:  ',
                        style: TextStyle(
                          fontSize: 9.5,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        data.beds,
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 2.5),

                  // ICU Available
                  Row(
                    children: [
                      const Icon(
                        Icons.personal_video_rounded,
                        size: 11.5,
                        color: Color(0xFF0284C7),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'ICU Available: ',
                        style: TextStyle(
                          fontSize: 9.5,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        data.icuAvailable,
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 2.5),

                  // Distance
                  Row(
                    children: [
                      const Icon(
                        Icons.alt_route_rounded,
                        size: 11.5,
                        color: Color(0xFF0F2642),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        data.distance,
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 4),

            // Chevron Right Arrow
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF0284C7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // AMBULANCES
  // ==========================================================

  Widget _buildAmbulances() {
    return _whiteCard(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.fromLTRB(13, 14, 13, 14),
      child: Column(
        children: [
          _cardHeader(
            title: 'Ambulance & Emergency Dispatch',
            action: 'Request Ambulance',
            onAction: () {
              _showMessage('Dispatching ambulance to your location...');
            },
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              const AmbulanceIllustration(width: 64, height: 54),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'NDRF Marine Rescue Unit #4',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Boat + ICU Ambulance Ready',
                      style: TextStyle(
                        color: AppColors.green,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'ETA: 8 minutes to Aluva Junction',
                      style: TextStyle(color: AppColors.muted, fontSize: 8),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SAFE ROUTES & INFRASTRUCTURE
  // ==========================================================

  Widget _buildSafeRoutes() {
    return _whiteCard(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.fromLTRB(13, 14, 13, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
            title: 'Safe Evacuation Routes',
            action: 'Navigation →',
            onAction: () {
              _showMessage('Evacuation navigation started');
            },
          ),

          const SizedBox(height: 10),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 140,
              width: double.infinity,
              child: CustomPaint(painter: SafeRoutesPainter()),
            ),
          ),

          const SizedBox(height: 10),

          _routeStatusRow(
            icon: Icons.check_circle_rounded,
            color: AppColors.green,
            route: 'NH 544 via Kalamassery',
            status: 'CLEAR (Recommended)',
          ),
          const SizedBox(height: 6),
          _routeStatusRow(
            icon: Icons.cancel_rounded,
            color: AppColors.red,
            route: 'Low Level Periyar Bridge',
            status: 'BLOCKED (Submerged 1.2m)',
          ),
        ],
      ),
    );
  }

  Widget _routeStatusRow({
    required IconData icon,
    required Color color,
    required String route,
    required String status,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(
          route,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Text(
          status,
          style: TextStyle(
            color: color,
            fontSize: 8.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // CITIZEN REPORTS & TOOLS
  // ==========================================================

  Widget _buildReportSituation() {
    return _whiteCard(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.blue.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              color: AppColors.blue,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Report Flood or Water Logging',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Submit photo, water level & geotag to alert rescue',
                  style: TextStyle(color: AppColors.muted, fontSize: 9),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _showMessage('Report flood feature opened'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text(
              'Report',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityReports() {
    return _whiteCard(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
            title: 'Citizen Field Feed',
            action: 'Submit +',
            onAction: () => _showMessage('Citizen report camera activated'),
          ),
          const SizedBox(height: 10),
          _feedItem(
            'Water logging near Aluva KSRTC stand',
            '2m ago • Verified by 14 users',
          ),
          const Divider(height: 12),
          _feedItem(
            'Power grid shut down at Desom area for safety',
            '18m ago • Official Notice',
          ),
        ],
      ),
    );
  }

  Widget _feedItem(String title, String sub) {
    return Row(
      children: [
        const Icon(Icons.shield_outlined, size: 16, color: AppColors.blue),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              Text(
                sub,
                style: const TextStyle(fontSize: 8, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMoreTools() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          _toolTile(
            Icons.opacity_rounded,
            'Water Quality',
            AppColors.lightBlue,
          ),
          const SizedBox(width: 8),
          _toolTile(
            Icons.cloud_sync_rounded,
            'Radar Weather',
            AppColors.purple,
          ),
          const SizedBox(width: 8),
          _toolTile(Icons.contact_phone_rounded, 'Helplines', AppColors.orange),
        ],
      ),
    );
  }

  Widget _toolTile(IconData icon, String label, Color color) {
    return Expanded(
      child: InkWell(
        onTap: () => _showMessage('$label opened'),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFD6E8F7), width: 1.1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A013973),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF013973),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomMessage() {
    return Center(
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/app_logo.png',
                width: 22,
                height: 22,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 7),
              const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Res',
                      style: TextStyle(
                        color: Color(0xFF013973),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    TextSpan(
                      text: 'Q',
                      style: TextStyle(
                        color: Color(0xFF00FF00),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(
                            color: Color(0x5500FF00),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    TextSpan(
                      text: 'Shield Emergency Network',
                      style: TextStyle(
                        color: Color(0xFF013973),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Government Disaster Mitigation & Early Warning Network',
            style: TextStyle(
              color: const Color(0xFF013973).withValues(alpha: 0.65),
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // BOTTOM NAVIGATION BAR
  // ==========================================================

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        border: const Border(
          top: BorderSide(color: Color(0xFFD6E8F7), width: 1.2),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D013973),
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: selectedBottomIndex,
        onTap: (index) {
          setState(() {
            selectedBottomIndex = index;
          });
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HazardMapScreen()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AlertDispatchScreen()),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ResourceShelterMapScreen()),
            );
          } else if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const CoordinationLogScreen()),
            );
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: const Color(0xFF007AEB),
        unselectedItemColor: const Color(0xFF64748B),
        selectedFontSize: 9.5,
        unselectedFontSize: 9.5,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Command',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_rounded),
            label: 'GIS Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emergency_share_rounded),
            label: 'Dispatch',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.hub_rounded),
            label: 'Resources',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fact_check_rounded),
            label: 'Audit Log',
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // HELPER COMPONENTS
  // ==========================================================

  Widget _whiteCard({
    required EdgeInsets margin,
    required EdgeInsets padding,
    required Widget child,
  }) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFD6E8F7),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C013973),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _cardHeader({
    required String title,
    required String action,
    required VoidCallback onAction,
  }) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onAction,
          child: Text(
            action,
            style: const TextStyle(
              color: AppColors.blue,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _outlineButton({
    required String text,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.blue,
        side: const BorderSide(color: AppColors.blue),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon, size: 16), const SizedBox(width: 6)],
          Text(
            text,
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ==========================================================
// ANIMATED RAINFALL WIDGET
// ==========================================================

class AnimatedRainfallWidget extends StatefulWidget {
  const AnimatedRainfallWidget({super.key});

  @override
  State<AnimatedRainfallWidget> createState() => _AnimatedRainfallWidgetState();
}

class _AnimatedRainfallWidgetState extends State<AnimatedRainfallWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 25,
      width: 32,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Cloud icon shifted slightly to the right
              const Positioned(
                top: 0,
                right: 2,
                child: Icon(
                  Icons.cloud_rounded,
                  color: Color(0xFF38BDF8),
                  size: 19,
                ),
              ),
              // Falling Rain Drops underneath
              Positioned(
                top: 13,
                right: 3,
                width: 18,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildDrop((progress) % 1.0),
                    _buildDrop((progress + 0.33) % 1.0),
                    _buildDrop((progress + 0.66) % 1.0),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDrop(double animVal) {
    final currentY = animVal * 9.0;
    final opacity = (1.0 - animVal).clamp(0.1, 1.0);

    return Transform.translate(
      offset: Offset(0, currentY),
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: 1.5,
          height: 5.5,
          decoration: BoxDecoration(
            color: const Color(0xFF60A5FA),
            borderRadius: BorderRadius.circular(1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.8),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShelterData {
  final String imagePath;
  final String category;
  final IconData categoryIcon;
  final Color categoryBg;
  final Color categoryColor;
  final String status;
  final bool isOpen;
  final String name;
  final String location;
  final String capacity;
  final String available;
  final bool foodAvailable;
  final bool foodWarning;
  final bool waterAvailable;
  final String filterCategory;

  const _ShelterData({
    required this.imagePath,
    required this.category,
    required this.categoryIcon,
    required this.categoryBg,
    required this.categoryColor,
    required this.status,
    required this.isOpen,
    required this.name,
    required this.location,
    required this.capacity,
    required this.available,
    required this.foodAvailable,
    required this.foodWarning,
    required this.waterAvailable,
    required this.filterCategory,
  });
}

class _ReliefCampData {
  final String imagePath;
  final String name;
  final String location;
  final String food;
  final String water;
  final String distance;
  final String status;
  final bool isActive;

  const _ReliefCampData({
    required this.imagePath,
    required this.name,
    required this.location,
    required this.food,
    required this.water,
    required this.distance,
    required this.status,
    required this.isActive,
  });
}

class _HospitalData {
  final String imagePath;
  final String name;
  final String location;
  final String beds;
  final String icuAvailable;
  final String distance;
  final String status;
  final bool isOpen;

  const _HospitalData({
    required this.imagePath,
    required this.name,
    required this.location,
    required this.beds,
    required this.icuAvailable,
    required this.distance,
    required this.status,
    required this.isOpen,
  });
}
