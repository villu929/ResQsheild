import 'package:flutter/material.dart';

class DamCoordinationScreen extends StatefulWidget {
  const DamCoordinationScreen({super.key});

  @override
  State<DamCoordinationScreen> createState() => _DamCoordinationScreenState();
}

class _DamCoordinationScreenState extends State<DamCoordinationScreen> {
  String _selectedDam = 'Idamalayar Dam (Periyar River)';

  // Dam metrics
  final double _currentLevel = 168.40;
  final double _fullReservoirLevel = 169.00;
  final double _warningLevel = 167.50;
  final int _inflowCusecs = 18450;
  final int _currentOutflow = 6200;

  // Release Schedule Form inputs
  final TextEditingController _dischargeController = TextEditingController(text: '12000');
  final TextEditingController _shuttersController = TextEditingController(text: '4');
  TimeOfDay _releaseTime = const TimeOfDay(hour: 6, minute: 0);

  final List<_DownstreamVillageImpact> _downstreamVillages = [
    _DownstreamVillageImpact(
      name: 'Boothathankettu Settlement',
      distanceKm: 14.2,
      estimatedArrival: '1 hr 10 min',
      riskTier: 'IMMEDIATE IMPACT',
      color: const Color(0xFFDC2626),
      population: 4800,
    ),
    _DownstreamVillageImpact(
      name: 'Aluva Riverside',
      distanceKm: 38.5,
      estimatedArrival: '2 hrs 45 min',
      riskTier: 'HIGH VULNERABILITY',
      color: const Color(0xFFEA580C),
      population: 16400,
    ),
    _DownstreamVillageImpact(
      name: 'Varapuzha Estuary',
      distanceKm: 52.0,
      estimatedArrival: '4 hrs 15 min',
      riskTier: 'MODERATE SURGE',
      color: const Color(0xFFF59E0B),
      population: 14300,
    ),
    _DownstreamVillageImpact(
      name: 'Paravur Coastline',
      distanceKm: 64.0,
      estimatedArrival: '5 hrs 30 min',
      riskTier: 'MONITOR TIDAL FLOW',
      color: const Color(0xFF0284C7),
      population: 22100,
    ),
  ];

  @override
  void dispose() {
    _dischargeController.dispose();
    _shuttersController.dispose();
    super.dispose();
  }

  void _confirmAndScheduleRelease() {
    final cusecs = _dischargeController.text;
    final shutters = _shuttersController.text;
    final timeFormatted = _releaseTime.format(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: const [
            Icon(Icons.water_damage_rounded, color: Color(0xFFDC2626), size: 24),
            SizedBox(width: 8),
            Text('Confirm Dam Release', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Logging this planned discharge will trigger automatic high-priority broadcast alerts to all downstream district collectors, SDMA units, and riverbank villages:',
              style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 12),
            Text('• Dam: $_selectedDam', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            Text('• Planned Release Time: $timeFormatted IST', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            Text('• Planned Discharge: $cusecs cusecs ($shutters Shutters)', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            Text('• Downstream Communities Notified: ${_downstreamVillages.length} Villages (~57,600 Citizens)', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _broadcastDamReleaseAlert(timeFormatted, cusecs, shutters);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('CONFIRM & AUTO-NOTIFY'),
          ),
        ],
      ),
    );
  }

  void _broadcastDamReleaseAlert(String timeStr, String cusecs, String shutters) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Dam release of $cusecs cusecs logged! Automated downstream evacuation advisories dispatched to 4 villages.'),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pctFull = (_currentLevel / _fullReservoirLevel).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF013973)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'DAM COORDINATION PANEL',
              style: TextStyle(
                color: Color(0xFF013973),
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              'Reservoir Storage, Controlled Release & Downstream Warning System',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dam Selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedDam,
                  isExpanded: true,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  items: [
                    'Idamalayar Dam (Periyar River)',
                    'Mullaperiyar Dam (Periyar Basin)',
                    'Bhoothathankettu Barrage',
                    'Idukki Arch Dam',
                  ].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                  onChanged: (val) => setState(() => _selectedDam = val!),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 1. CURRENT DAM WATER LEVEL + SAFE THRESHOLD GAUGE CARD
            _sectionHeader('RESERVOIR STORAGE & LIVE SENSORS', Icons.water_damage_rounded),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 3))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Current Water Level', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text('${_currentLevel}m', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFFDC2626))),
                        ],
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Full Reservoir Level (FRL)', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text('${_fullReservoirLevel}m', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Visual Storage Gauge Bar
                  Row(
                    children: [
                      Text('${(pctFull * 100).toStringAsFixed(1)}% Capacity Filled', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFDC2626))),
                      const Spacer(),
                      Text('Warning: ${_warningLevel.toStringAsFixed(2)}m (BREACHED)', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFFEA580C))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: pctFull,
                      minHeight: 12,
                      backgroundColor: const Color(0xFFE2E8F0),
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _telemetryTile('Live Inflow', '$_inflowCusecs cusecs', Icons.south_west_rounded, const Color(0xFF0284C7)),
                      const SizedBox(width: 8),
                      _telemetryTile('Current Outflow', '$_currentOutflow cusecs', Icons.north_east_rounded, const Color(0xFF16A34A)),
                      const SizedBox(width: 8),
                      _telemetryTile('Active Shutters', '2 of 4 Open (0.2m)', Icons.water_damage_rounded, const Color(0xFFEA580C)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. RELEASE SCHEDULE INPUT PANEL
            _sectionHeader('SCHEDULE PLANNED WATER RELEASE', Icons.schedule_send_rounded),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 3))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Planned Discharge (cusecs)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _dischargeController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                              decoration: InputDecoration(
                                suffixText: 'cusecs',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Shutters to Open', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _shuttersController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                              decoration: InputDecoration(
                                suffixText: 'Shutters',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Time Picker Button
                  Row(
                    children: [
                      const Text('Planned Release Time:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final picked = await showTimePicker(context: context, initialTime: _releaseTime);
                          if (picked != null) setState(() => _releaseTime = picked);
                        },
                        icon: const Icon(Icons.access_time_rounded, size: 16),
                        label: Text(_releaseTime.format(context), style: const TextStyle(fontWeight: FontWeight.w800)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF1F5F9),
                          foregroundColor: const Color(0xFF007AEB),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _confirmAndScheduleRelease,
                      icon: const Icon(Icons.notification_add_rounded, size: 18),
                      label: const Text(
                        'LOG RELEASE & AUTO-NOTIFY DOWNSTREAM',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007AEB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. AUTO-NOTIFIED DOWNSTREAM VILLAGES IMPACT PREVIEW
            _sectionHeader('DOWNSTREAM IMPACT ZONES (AUTO-NOTIFICATION PATH)', Icons.route_rounded),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _downstreamVillages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final v = _downstreamVillages[i];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: v.color.withValues(alpha: 0.12), shape: BoxShape.circle),
                        child: Icon(Icons.location_on_rounded, color: v.color, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(v.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A))),
                            Text('${v.distanceKm} km downstream • Pop: ${v.population}', style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: v.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
                            child: Text(v.riskTier, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: v.color)),
                          ),
                          const SizedBox(height: 2),
                          Text('Wave Lead: ${v.estimatedArrival}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF007AEB)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF013973)),
        ),
      ],
    );
  }

  Widget _telemetryTile(String title, String val, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 4),
                Expanded(child: Text(title, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B), fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 4),
            Text(val, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      ),
    );
  }
}

class _DownstreamVillageImpact {
  final String name;
  final double distanceKm;
  final String estimatedArrival;
  final String riskTier;
  final Color color;
  final int population;

  _DownstreamVillageImpact({
    required this.name,
    required this.distanceKm,
    required this.estimatedArrival,
    required this.riskTier,
    required this.color,
    required this.population,
  });
}
