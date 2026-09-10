import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'alert_dispatch_screen.dart';

class HazardMapScreen extends StatefulWidget {
  const HazardMapScreen({super.key});

  @override
  State<HazardMapScreen> createState() => _HazardMapScreenState();
}

class _HazardMapScreenState extends State<HazardMapScreen> {
  // Layer toggles
  bool _showRiver = true;
  bool _showRainfall = true;
  bool _showDam = true;
  bool _showGlof = false;
  bool _showLandslide = false;

  final MapController _mapController = MapController();
  final LatLng _initialCenter = const LatLng(10.1076, 76.3516); // Kochi / Aluva basin

  final List<_VillageRiskPoint> _villages = [
    _VillageRiskPoint(
      name: 'Aluva Riverside',
      district: 'Ernakulam',
      location: const LatLng(10.1076, 76.3516),
      risk: _RiskLevel.high,
      leadTime: '1 hr 15 min',
      waterLevel: '8.4 m',
      dangerLevel: '7.2 m',
      rainfall: '142 mm',
      population: '16,400',
      isCutOff: true,
    ),
    _VillageRiskPoint(
      name: 'Paravur Lowlands',
      district: 'Ernakulam',
      location: const LatLng(10.1450, 76.2300),
      risk: _RiskLevel.high,
      leadTime: '1 hr 45 min',
      waterLevel: '5.8 m',
      dangerLevel: '5.0 m',
      rainfall: '130 mm',
      population: '22,100',
      isCutOff: false,
    ),
    _VillageRiskPoint(
      name: 'Varapuzha Bridge',
      district: 'Ernakulam',
      location: const LatLng(10.0750, 76.2800),
      risk: _RiskLevel.moderate,
      leadTime: '3 hrs 10 min',
      waterLevel: '4.2 m',
      dangerLevel: '5.0 m',
      rainfall: '98 mm',
      population: '14,300',
      isCutOff: false,
    ),
    _VillageRiskPoint(
      name: 'Chalakudy North',
      district: 'Thrissur',
      location: const LatLng(10.3070, 76.3330),
      risk: _RiskLevel.moderate,
      leadTime: '4 hrs 00 min',
      waterLevel: '6.1 m',
      dangerLevel: '7.0 m',
      rainfall: '110 mm',
      population: '18,800',
      isCutOff: false,
    ),
    _VillageRiskPoint(
      name: 'Perumbavoor East',
      district: 'Ernakulam',
      location: const LatLng(10.1150, 76.4780),
      risk: _RiskLevel.safe,
      leadTime: '> 12 hrs',
      waterLevel: '2.8 m',
      dangerLevel: '6.5 m',
      rainfall: '45 mm',
      population: '28,000',
      isCutOff: false,
    ),
    _VillageRiskPoint(
      name: 'Kochi Hill Crest',
      district: 'Ernakulam',
      location: const LatLng(10.0250, 76.3080),
      risk: _RiskLevel.safe,
      leadTime: 'No Flood Risk',
      waterLevel: '1.4 m',
      dangerLevel: '6.0 m',
      rainfall: '62 mm',
      population: '45,200',
      isCutOff: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'LIVE HAZARD MAP',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'GIS District Multi-Hazard Spatial Monitoring',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded, color: Color(0xFF38BDF8)),
            tooltip: 'Recenter Basin',
            onPressed: () => _mapController.move(_initialCenter, 11),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Full-Screen Interactive GIS Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: 11.0,
              minZoom: 8.0,
              maxZoom: 17.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.resqshield.app',
              ),
              // Simulated Hazard Overlay Circles
              CircleLayer(
                circles: [
                  if (_showRiver)
                    CircleMarker(
                      point: const LatLng(10.1076, 76.3516),
                      radius: 3500,
                      useRadiusInMeter: true,
                      color: const Color(0xFFDC2626).withValues(alpha: 0.25),
                      borderColor: const Color(0xFFDC2626),
                      borderStrokeWidth: 2,
                    ),
                  if (_showRainfall)
                    CircleMarker(
                      point: const LatLng(10.1450, 76.2300),
                      radius: 5000,
                      useRadiusInMeter: true,
                      color: const Color(0xFF0284C7).withValues(alpha: 0.18),
                      borderColor: const Color(0xFF0284C7),
                      borderStrokeWidth: 1.5,
                    ),
                  if (_showLandslide)
                    CircleMarker(
                      point: const LatLng(10.0250, 76.4500),
                      radius: 2000,
                      useRadiusInMeter: true,
                      color: const Color(0xFFD97706).withValues(alpha: 0.25),
                      borderColor: const Color(0xFFD97706),
                      borderStrokeWidth: 2,
                    ),
                ],
              ),
              // Village Risk Markers
              MarkerLayer(
                markers: _villages.map((village) {
                  return Marker(
                    point: village.location,
                    width: 70,
                    height: 70,
                    child: GestureDetector(
                      onTap: () => _showVillageDetails(village),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: village.color.withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                              border: Border.all(color: village.color, width: 2),
                            ),
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: village.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              village.name.split(' ').first,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // 2. Layer Toggles Bar (Top Overlay)
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _layerChip(
                    label: 'River Level',
                    icon: Icons.water_rounded,
                    isActive: _showRiver,
                    activeColor: const Color(0xFFEF4444),
                    onTap: () => setState(() => _showRiver = !_showRiver),
                  ),
                  const SizedBox(width: 6),
                  _layerChip(
                    label: 'Rainfall Radar',
                    icon: Icons.cloud_download_rounded,
                    isActive: _showRainfall,
                    activeColor: const Color(0xFF0284C7),
                    onTap: () => setState(() => _showRainfall = !_showRainfall),
                  ),
                  const SizedBox(width: 6),
                  _layerChip(
                    label: 'Dam Level',
                    icon: Icons.water_damage_rounded,
                    isActive: _showDam,
                    activeColor: const Color(0xFF8B5CF6),
                    onTap: () => setState(() => _showDam = !_showDam),
                  ),
                  const SizedBox(width: 6),
                  _layerChip(
                    label: 'GLOF Risk',
                    icon: Icons.terrain_rounded,
                    isActive: _showGlof,
                    activeColor: const Color(0xFF06B6D4),
                    onTap: () => setState(() => _showGlof = !_showGlof),
                  ),
                  const SizedBox(width: 6),
                  _layerChip(
                    label: 'Landslide',
                    icon: Icons.landscape_rounded,
                    isActive: _showLandslide,
                    activeColor: const Color(0xFFF59E0B),
                    onTap: () => setState(() => _showLandslide = !_showLandslide),
                  ),
                ],
              ),
            ),
          ),

          // 3. Risk Legend (Bottom Left Overlay)
          Positioned(
            bottom: 20,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
                boxShadow: const [
                  BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'VILLAGE RISK INDEX',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _legendItem(const Color(0xFFEF4444), 'High Risk (Inundation Imminent)'),
                  const SizedBox(height: 4),
                  _legendItem(const Color(0xFFF59E0B), 'Moderate Risk (Watch Stage)'),
                  const SizedBox(height: 4),
                  _legendItem(const Color(0xFF10B981), 'Safe Zone (Normal Elevation)'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _layerChip({
    required String label,
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? activeColor : const Color(0xFF1E293B).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.white : const Color(0xFF475569),
            width: 1.2,
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: activeColor.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  void _showVillageDetails(_VillageRiskPoint village) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: village.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.location_city_rounded, color: village.color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        village.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'District: ${village.district} • Pop: ${village.population}',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: village.color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    village.riskLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Lead-time banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_rounded, color: Color(0xFF0284C7), size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Estimated Inundation Lead-Time:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                  const Spacer(),
                  Text(
                    village.leadTime,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: village.color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Live Sensor readings
            const Text(
              'LIVE SENSOR TELEMETRY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _telemetryMiniCard(
                    title: 'Water Level',
                    value: village.waterLevel,
                    sub: 'Danger: ${village.dangerLevel}',
                    color: const Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _telemetryMiniCard(
                    title: 'Rainfall 6h',
                    value: village.rainfall,
                    sub: 'Heavy Inflow',
                    color: const Color(0xFF0284C7),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _telemetryMiniCard(
                    title: 'Cut-off Status',
                    value: village.isCutOff ? 'CUT-OFF' : 'ACCESSIBLE',
                    sub: village.isCutOff ? 'Bridges Submerged' : 'Clear Route',
                    color: village.isCutOff ? const Color(0xFFDC2626) : const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Action button linking to Alert Dispatch
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AlertDispatchScreen(preselectedVillage: village.name),
                    ),
                  );
                },
                icon: const Icon(Icons.broadcast_on_personal_rounded),
                label: Text('Dispatch Emergency Alert to ${village.name}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _telemetryMiniCard({
    required String title,
    required String value,
    required String sub,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 9, color: Color(0xFF475569))),
        ],
      ),
    );
  }
}

enum _RiskLevel { safe, moderate, high }

class _VillageRiskPoint {
  final String name;
  final String district;
  final LatLng location;
  final _RiskLevel risk;
  final String leadTime;
  final String waterLevel;
  final String dangerLevel;
  final String rainfall;
  final String population;
  final bool isCutOff;

  _VillageRiskPoint({
    required this.name,
    required this.district,
    required this.location,
    required this.risk,
    required this.leadTime,
    required this.waterLevel,
    required this.dangerLevel,
    required this.rainfall,
    required this.population,
    required this.isCutOff,
  });

  Color get color {
    switch (risk) {
      case _RiskLevel.high:
        return const Color(0xFFEF4444);
      case _RiskLevel.moderate:
        return const Color(0xFFF59E0B);
      case _RiskLevel.safe:
        return const Color(0xFF10B981);
    }
  }

  String get riskLabel {
    switch (risk) {
      case _RiskLevel.high:
        return 'HIGH RISK';
      case _RiskLevel.moderate:
        return 'MODERATE';
      case _RiskLevel.safe:
        return 'SAFE';
    }
  }
}
