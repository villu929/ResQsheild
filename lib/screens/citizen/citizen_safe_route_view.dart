import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class CitizenSafeRouteView extends StatefulWidget {
  final bool isHindi;

  const CitizenSafeRouteView({super.key, this.isHindi = false});

  @override
  State<CitizenSafeRouteView> createState() => _CitizenSafeRouteViewState();
}

class _CitizenSafeRouteViewState extends State<CitizenSafeRouteView> {
  bool _isNavigating = false;

  final LatLng userPos = const LatLng(23.7957, 86.4304);
  final LatLng waypointPos = const LatLng(23.7990, 86.4340);
  final LatLng shelterPos = const LatLng(23.8030, 86.4380);

  final List<Map<String, String>> _steps = [
    {
      'instruction': 'Head North on Ward 7 Lane towards Bypass Road',
      'distance': '350 meters',
      'elevation': '+4m elevation gain (Dry)',
    },
    {
      'instruction': 'Turn right on Elevated Highway Bridge (Avoid Underpass)',
      'distance': '500 meters',
      'elevation': 'High ground (+10m safe ridge)',
    },
    {
      'instruction': 'Arrive at Govt Senior Secondary School Shelter Gate 1',
      'distance': '250 meters',
      'elevation': 'Designated Safe Haven',
    },
  ];

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
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF013973)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isHindi ? 'सुरक्षित निकासी मार्ग' : 'Safe Evacuation Route',
          style: const TextStyle(
            color: Color(0xFF013973),
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Column(
        children: [
          // 1. Interactive Route Map Preview (Height ~220)
          SizedBox(
            height: 220,
            width: double.infinity,
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: const LatLng(23.7990, 86.4340),
                    initialZoom: 14.5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.resqshield.app',
                    ),
                    // Safe Green Route Polyline
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: [userPos, waypointPos, shelterPos],
                          color: const Color(0xFF15945C),
                          strokeWidth: 5.0,
                        ),
                      ],
                    ),
                    // Route Markers
                    MarkerLayer(
                      markers: [
                        // User GPS
                        Marker(
                          point: userPos,
                          width: 38,
                          height: 38,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF007AEB),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                            ),
                            child: const Icon(Icons.person, color: Colors.white, size: 20),
                          ),
                        ),
                        // Intermediate High-Ground Waypoint
                        Marker(
                          point: waypointPos,
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
                        // Shelter Destination
                        Marker(
                          point: shelterPos,
                          width: 44,
                          height: 44,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFE92828),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                            ),
                            child: const Icon(Icons.night_shelter_rounded, color: Colors.white, size: 24),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Top Badge on Map
                Positioned(
                  top: 10,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF013973).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.verified_rounded, size: 14, color: Color(0xFF00FF00)),
                        SizedBox(width: 6),
                        Text(
                          'NDMA Verified Safe Route',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Scrollable Safe Path Details
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Safe Path Overview Card: YOU -> Safe Road -> Shelter
                  Container(
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
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  '1.1 km • 14 mins walk',
                                  style: TextStyle(
                                    color: Color(0xFF013973),
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '+18m Elevation Rise (High & Dry)',
                                  style: TextStyle(
                                    color: Color(0xFF15945C),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF8F0),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF15945C)),
                              ),
                              child: const Text(
                                'DRY & CLEAR',
                                style: TextStyle(color: Color(0xFF15945C), fontSize: 11, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24, color: Color(0xFFE5E9EE)),

                        // Visual Breadcrumb Pipeline
                        _pathNode(
                          icon: Icons.person_pin_circle_rounded,
                          color: const Color(0xFF007AEB),
                          title: 'YOU (Current Location)',
                          subtitle: 'Ward 7, Sector 4 • Elevation: 218m',
                          isCurrent: true,
                        ),
                        _pathConnector(isDry: true),
                        _pathNode(
                          icon: Icons.alt_route_rounded,
                          color: const Color(0xFF15945C),
                          title: 'Elevated Bypass Road',
                          subtitle: 'Avoids Submerged Bridge #2 • Elevation: 228m',
                          isCurrent: false,
                        ),
                        _pathConnector(isDry: true),
                        _pathNode(
                          icon: Icons.night_shelter_rounded,
                          color: const Color(0xFFE92828),
                          title: 'Govt Senior Secondary School Shelter',
                          subtitle: 'Safe Haven • Capacity: 450 • Elevation: 236m',
                          isCurrent: false,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Warning note along the route
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEEEE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE92828).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.do_not_disturb_on_rounded, color: Color(0xFFE92828), size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'DO NOT USE Market Canal Road. It is currently under 3 feet of moving water.',
                            style: TextStyle(
                              color: Color(0xFFE92828),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Big Prominent "START SAFE ROUTE" Button
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _isNavigating = !_isNavigating);
                      _showMessage(_isNavigating
                          ? 'Starting Safe Turn-by-Turn GPS Guidance...'
                          : 'Navigation paused');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isNavigating ? const Color(0xFF15945C) : const Color(0xFF007AEB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 4,
                      shadowColor: const Color(0xFF007AEB).withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_isNavigating ? Icons.check_circle_rounded : Icons.navigation_rounded, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          _isNavigating
                              ? (widget.isHindi ? 'नेविगेशन सक्रिय है (1.1 किमी)' : 'SAFE NAVIGATION ACTIVE')
                              : (widget.isHindi ? 'सुरक्षित मार्ग शुरू करें' : 'START SAFE ROUTE'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Turn-by-turn preview
                  const Text(
                    'TURN-BY-TURN DIRECTIONS',
                    style: TextStyle(
                      color: Color(0xFF013973),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._steps.asMap().entries.map((entry) {
                    final index = entry.key;
                    final step = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD6E8F7)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: const Color(0xFF007AEB).withValues(alpha: 0.15),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(color: Color(0xFF007AEB), fontSize: 11, fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  step['instruction']!,
                                  style: const TextStyle(
                                    color: Color(0xFF013973),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${step['distance']} • ${step['elevation']}',
                                  style: const TextStyle(color: Color(0xFF537392), fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pathNode({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool isCurrent,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: const Color(0xFF013973),
                  fontSize: 13,
                  fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF537392), fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pathConnector({required bool isDry}) {
    return Padding(
      padding: const EdgeInsets.only(left: 17),
      child: Container(
        width: 2,
        height: 22,
        color: isDry ? const Color(0xFF15945C) : const Color(0xFFBEDCF5),
      ),
    );
  }
}
