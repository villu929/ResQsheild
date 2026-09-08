import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'citizen_localization.dart';
import 'citizen_risk_view.dart';
import 'citizen_safe_route_view.dart';
import 'citizen_shelters_view.dart';
import 'citizen_sos_dialog.dart';
import 'citizen_hazard_report_view.dart';
import 'citizen_alerts_view.dart';

enum CitizenThreatLevel {
  normal,
  warning,
  evacuation,
}

class CitizenDashboardScreen extends StatefulWidget {
  const CitizenDashboardScreen({super.key});

  @override
  State<CitizenDashboardScreen> createState() => _CitizenDashboardScreenState();
}

class _CitizenDashboardScreenState extends State<CitizenDashboardScreen> {
  bool _isHindi = false;
  CitizenThreatLevel _threatLevel = CitizenThreatLevel.warning;
  late final MapController _mapController;

  // Key Coordinates (Bokaro / Damodar River Basin)
  final LatLng _userPos = const LatLng(23.7957, 86.4304);
  final LatLng _waypointPos = const LatLng(23.7990, 86.4340);
  final LatLng _shelterPos1 = const LatLng(23.8030, 86.4380);
  final LatLng _shelterPos2 = const LatLng(23.7920, 86.4250);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9F4FB),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // 1. Offline Cache Banner (Feature 7)
          _buildOfflineBanner(),

          // 2. PINNED TOP SECTION: Interactive FlutterMap (~230px high)
          _buildPinnedMapSection(),

          // 3. SCROLLABLE BOTTOM SECTION
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 3a. BIG STATUS CARD (NORMAL / WARNING / EVACUATION)
                  _buildStatusCard(),

                  const SizedBox(height: 16),

                  // 3b. QUICK ACTION BUTTONS GRID (6 TILES)
                  _buildQuickActionGrid(),

                  const SizedBox(height: 18),

                  // 3c. NEAREST SAFE SHELTER & QUICK START SAFE ROUTE CARD
                  _buildSafeRouteBanner(),

                  const SizedBox(height: 16),

                  // 3d. EMERGENCY HELPLINE ROW
                  _buildHelplineRow(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // APP BAR
  // --------------------------------------------------------------------------
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF013973)),
        tooltip: CitizenStrings.get('changeRole', isHindi: _isHindi),
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
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
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
        ],
      ),
      actions: [
        // English / Hindi Language Switcher (Feature 7)
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () {
              setState(() => _isHindi = !_isHindi);
              _showMessage(_isHindi ? 'भाषा बदली गई: हिंदी' : 'Language switched to English');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F8FD),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFBEDCF5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.language_rounded, size: 14, color: const Color(0xFF007AEB)),
                  const SizedBox(width: 5),
                  Text(
                    _isHindi ? 'हिन्दी' : 'English',
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
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // OFFLINE MESH BANNER (Feature 7)
  // --------------------------------------------------------------------------
  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF013973),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_tethering_rounded, color: Color(0xFF38BDF8), size: 14),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              CitizenStrings.get('offlineBanner', isHindi: _isHindi),
              style: const TextStyle(
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

  // --------------------------------------------------------------------------
  // TOP PINNED INTERACTIVE MAP SECTION
  // --------------------------------------------------------------------------
  Widget _buildPinnedMapSection() {
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
            ),
            children: [
              // OpenStreetMap Standard Tiles
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.resqshield.app',
              ),

              // Safe Route Polyline Overlay
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [_userPos, _waypointPos, _shelterPos1],
                    color: const Color(0xFF15945C),
                    strokeWidth: 4.5,
                  ),
                ],
              ),

              // Map Markers
              MarkerLayer(
                markers: [
                  // Real GPS User Marker
                  Marker(
                    point: _userPos,
                    width: 42,
                    height: 42,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AEB),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                        ],
                      ),
                      child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 22),
                    ),
                  ),

                  // Waypoint Marker (Elevated Ridge)
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

                  // Designated Primary Shelter Marker
                  Marker(
                    point: _shelterPos1,
                    width: 44,
                    height: 44,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CitizenSheltersView(isHindi: _isHindi),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFE92828),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                          ],
                        ),
                        child: const Icon(Icons.night_shelter_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                  ),

                  // Secondary Shelter Marker
                  Marker(
                    point: _shelterPos2,
                    width: 36,
                    height: 36,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF39A20),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.night_shelter_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Pinned Map Legend / Location Indicator
          Positioned(
            top: 10,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD6E8F7)),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF007AEB)),
                  SizedBox(width: 4),
                  Text(
                    'Sector 4, Bokaro Basin',
                    style: TextStyle(
                      color: Color(0xFF013973),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Recenter & Layer Control Buttons
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
                      _showMessage('Centered on your GPS position');
                    },
                    tooltip: 'Recenter on You',
                  ),
                ),
                const SizedBox(height: 6),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.alt_route_rounded, size: 18, color: Color(0xFF15945C)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CitizenSafeRouteView(isHindi: _isHindi),
                        ),
                      );
                    },
                    tooltip: 'Open Full Safe Route',
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
  // 3a. STATUS CARD (NORMAL / WARNING / EVACUATION RECOMMENDED)
  // --------------------------------------------------------------------------
  Widget _buildStatusCard() {
    Color cardColor;
    Color borderColor;
    Color textColor;
    IconData icon;
    String statusTitle;
    String statusExplanation;

    switch (_threatLevel) {
      case CitizenThreatLevel.normal:
        cardColor = const Color(0xFFEAF8F0);
        borderColor = const Color(0xFF15945C);
        textColor = const Color(0xFF15945C);
        icon = Icons.check_circle_rounded;
        statusTitle = CitizenStrings.get('normalStatus', isHindi: _isHindi);
        statusExplanation = CitizenStrings.get('normalDesc', isHindi: _isHindi);
        break;

      case CitizenThreatLevel.warning:
        cardColor = const Color(0xFFFFF5E7);
        borderColor = const Color(0xFFF39A20);
        textColor = const Color(0xFFF39A20);
        icon = Icons.warning_amber_rounded;
        statusTitle = CitizenStrings.get('warningStatus', isHindi: _isHindi);
        statusExplanation = CitizenStrings.get('warningDesc', isHindi: _isHindi);
        break;

      case CitizenThreatLevel.evacuation:
        cardColor = const Color(0xFFFFEEEE);
        borderColor = const Color(0xFFE92828);
        textColor = const Color(0xFFE92828);
        icon = Icons.campaign_rounded;
        statusTitle = CitizenStrings.get('evacuateStatus', isHindi: _isHindi);
        statusExplanation = CitizenStrings.get('evacuateDesc', isHindi: _isHindi);
        break;
    }

    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} IST';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.8),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Status Chip & Dynamic Time
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
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              // Dynamic Time
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
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

          // Simple non-technical citizen guidance
          Text(
            statusExplanation,
            style: const TextStyle(
              color: Color(0xFF0F2642),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 10),

          // Demo State Toggle for SIH Hackathon Presentation
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                'Demo Level:',
                style: TextStyle(color: Color(0xFF537392), fontSize: 10, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 6),
              _demoStatusDot(CitizenThreatLevel.normal, '🟢', const Color(0xFF15945C)),
              const SizedBox(width: 4),
              _demoStatusDot(CitizenThreatLevel.warning, '🟠', const Color(0xFFF39A20)),
              const SizedBox(width: 4),
              _demoStatusDot(CitizenThreatLevel.evacuation, '🔴', const Color(0xFFE92828)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _demoStatusDot(CitizenThreatLevel lvl, String emoji, Color color) {
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

  // --------------------------------------------------------------------------
  // 3b. QUICK ACTION GRID (6 BUTTONS)
  // --------------------------------------------------------------------------
  Widget _buildQuickActionGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _actionCard(
                title: CitizenStrings.get('myRisk', isHindi: _isHindi),
                subtitle: 'Village GPS Risk',
                icon: Icons.shield_rounded,
                color: const Color(0xFF007AEB),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CitizenRiskView(isHindi: _isHindi),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _actionCard(
                title: CitizenStrings.get('safeRoute', isHindi: _isHindi),
                subtitle: 'Elevated Path',
                icon: Icons.alt_route_rounded,
                color: const Color(0xFF15945C),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CitizenSafeRouteView(isHindi: _isHindi),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _actionCard(
                title: CitizenStrings.get('shelters', isHindi: _isHindi),
                subtitle: 'Relief Camps',
                icon: Icons.night_shelter_rounded,
                color: const Color(0xFF7351D8),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CitizenSheltersView(isHindi: _isHindi),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _actionCard(
                title: CitizenStrings.get('sosHelp', isHindi: _isHindi),
                subtitle: 'Instant Beacon',
                icon: Icons.sos_rounded,
                color: const Color(0xFFE92828),
                isSos: true,
                onTap: () => CitizenSosDialog.show(context, isHindi: _isHindi),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _actionCard(
                title: CitizenStrings.get('reportHazard', isHindi: _isHindi),
                subtitle: 'Community Pin',
                icon: Icons.add_alert_rounded,
                color: const Color(0xFFF39A20),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CitizenHazardReportView(isHindi: _isHindi),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _actionCard(
                title: CitizenStrings.get('alertInbox', isHindi: _isHindi),
                subtitle: 'Official Timeline',
                icon: Icons.notifications_active_rounded,
                color: const Color(0xFF0A4F8A),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CitizenAlertsView(isHindi: _isHindi),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isSos = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: isSos ? const Color(0xFFFFEEEE) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSos ? const Color(0xFFE92828) : const Color(0xFFD6E8F7),
            width: isSos ? 1.6 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSos
                  ? const Color(0xFFE92828).withValues(alpha: 0.15)
                  : const Color(0xFF013973).withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: isSos ? 0.2 : 0.12),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSos ? const Color(0xFFE92828) : const Color(0xFF013973),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF537392),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 3c. NEAREST SHELTER & QUICK START SAFE ROUTE CARD
  // --------------------------------------------------------------------------
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF15945C).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.night_shelter_rounded, color: Color(0xFF15945C), size: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    CitizenStrings.get('nearestShelter', isHindi: _isHindi),
                    style: const TextStyle(
                      color: Color(0xFF013973),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF8F0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '0.8 km (10m walk)',
                  style: TextStyle(
                    color: Color(0xFF15945C),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          const Text(
            'Govt Senior Secondary School, Sector 4 High Ground',
            style: TextStyle(
              color: Color(0xFF0F2642),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Food, clean water, generators & medical doctor available on-site.',
            style: TextStyle(color: Color(0xFF537392), fontSize: 12),
          ),

          const SizedBox(height: 14),

          // START SAFE ROUTE BUTTON
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CitizenSafeRouteView(isHindi: _isHindi),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF15945C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.navigation_rounded, size: 18),
                const SizedBox(width: 8),
                Text(
                  CitizenStrings.get('startSafeRoute', isHindi: _isHindi),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 3d. EMERGENCY HELPLINE ROW
  // --------------------------------------------------------------------------
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
          _helplineItem('112', 'Integrated Police/Fire', () => _showMessage('Dialing 112...')),
          Container(width: 1, height: 24, color: const Color(0xFFE5E9EE)),
          _helplineItem('1070', 'NDMA Helpline', () => _showMessage('Dialing 1070...')),
          Container(width: 1, height: 24, color: const Color(0xFFE5E9EE)),
          _helplineItem('108', 'Ambulance', () => _showMessage('Dialing 108...')),
        ],
      ),
    );
  }

  Widget _helplineItem(String number, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          children: [
            const Icon(Icons.phone_in_talk_rounded, size: 14, color: Color(0xFFE92828)),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  number,
                  style: const TextStyle(
                    color: Color(0xFFE92828),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(color: Color(0xFF537392), fontSize: 9, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
