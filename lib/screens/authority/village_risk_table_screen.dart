import 'package:flutter/material.dart';
import 'alert_dispatch_screen.dart';

class VillageRiskTableScreen extends StatefulWidget {
  const VillageRiskTableScreen({super.key});

  @override
  State<VillageRiskTableScreen> createState() => _VillageRiskTableScreenState();
}

class _VillageRiskTableScreenState extends State<VillageRiskTableScreen> {
  String _selectedDistrict = 'All';
  String _selectedRisk = 'All';
  bool _onlyCutOff = false;
  String _sortBy = 'risk'; // 'risk', 'leadTime', 'population', 'name'
  bool _sortAscending = false;

  final List<_VillageData> _allVillages = [
    _VillageData(
      name: 'Aluva Riverside',
      district: 'Ernakulam',
      riskScore: 94,
      riskLevel: 'HIGH RISK',
      leadTimeHours: 1.25,
      leadTimeDisplay: '1h 15m',
      population: 16400,
      lastAlertSent: '12m ago',
      isCutOff: true,
      waterLevel: '8.4m',
      dangerThreshold: '7.2m',
    ),
    _VillageData(
      name: 'Paravur Lowlands',
      district: 'Ernakulam',
      riskScore: 88,
      riskLevel: 'HIGH RISK',
      leadTimeHours: 1.75,
      leadTimeDisplay: '1h 45m',
      population: 22100,
      lastAlertSent: '25m ago',
      isCutOff: false,
      waterLevel: '5.8m',
      dangerThreshold: '5.0m',
    ),
    _VillageData(
      name: 'Chalakudy West',
      district: 'Thrissur',
      riskScore: 82,
      riskLevel: 'HIGH RISK',
      leadTimeHours: 2.10,
      leadTimeDisplay: '2h 06m',
      population: 19500,
      lastAlertSent: '1h ago',
      isCutOff: true,
      waterLevel: '7.4m',
      dangerThreshold: '7.0m',
    ),
    _VillageData(
      name: 'Varapuzha Bridge',
      district: 'Ernakulam',
      riskScore: 65,
      riskLevel: 'MODERATE',
      leadTimeHours: 3.16,
      leadTimeDisplay: '3h 10m',
      population: 14300,
      lastAlertSent: '3h ago',
      isCutOff: false,
      waterLevel: '4.2m',
      dangerThreshold: '5.0m',
    ),
    _VillageData(
      name: 'Chalakudy North',
      district: 'Thrissur',
      riskScore: 58,
      riskLevel: 'MODERATE',
      leadTimeHours: 4.00,
      leadTimeDisplay: '4h 00m',
      population: 18800,
      lastAlertSent: '4h ago',
      isCutOff: false,
      waterLevel: '6.1m',
      dangerThreshold: '7.0m',
    ),
    _VillageData(
      name: 'Thodupuzha Riverbank',
      district: 'Idukki',
      riskScore: 52,
      riskLevel: 'MODERATE',
      leadTimeHours: 5.50,
      leadTimeDisplay: '5h 30m',
      population: 11200,
      lastAlertSent: '5h ago',
      isCutOff: false,
      waterLevel: '3.9m',
      dangerThreshold: '5.2m',
    ),
    _VillageData(
      name: 'Perumbavoor East',
      district: 'Ernakulam',
      riskScore: 22,
      riskLevel: 'SAFE',
      leadTimeHours: 14.0,
      leadTimeDisplay: '> 12h',
      population: 28000,
      lastAlertSent: 'None',
      isCutOff: false,
      waterLevel: '2.8m',
      dangerThreshold: '6.5m',
    ),
    _VillageData(
      name: 'Kochi Hill Crest',
      district: 'Ernakulam',
      riskScore: 10,
      riskLevel: 'SAFE',
      leadTimeHours: 99.0,
      leadTimeDisplay: 'Safe',
      population: 45200,
      lastAlertSent: 'None',
      isCutOff: false,
      waterLevel: '1.4m',
      dangerThreshold: '6.0m',
    ),
  ];

  List<_VillageData> get _filteredVillages {
    var list = _allVillages.where((v) {
      if (_selectedDistrict != 'All' && v.district != _selectedDistrict) return false;
      if (_selectedRisk != 'All' && v.riskLevel != _selectedRisk) return false;
      if (_onlyCutOff && !v.isCutOff) return false;
      return true;
    }).toList();

    list.sort((a, b) {
      int cmp = 0;
      switch (_sortBy) {
        case 'risk':
          cmp = a.riskScore.compareTo(b.riskScore);
          break;
        case 'leadTime':
          cmp = a.leadTimeHours.compareTo(b.leadTimeHours);
          break;
        case 'population':
          cmp = a.population.compareTo(b.population);
          break;
        case 'name':
          cmp = a.name.compareTo(b.name);
          break;
      }
      return _sortAscending ? cmp : -cmp;
    });

    return list;
  }

  void _exportOfflineBriefing() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.print_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Offline Situation Briefing PDF & CSV generated! Ready for field commanders.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final villages = _filteredVillages;

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
              'VILLAGE RISK TABLE',
              style: TextStyle(
                color: Color(0xFF013973),
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              'Sortable Basin Vulnerability & Lead-Time Matrix',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded, color: Color(0xFF007AEB)),
            tooltip: 'Export Offline Briefing (Print / PDF)',
            onPressed: _exportOfflineBriefing,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Controls Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    // District Dropdown
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedDistrict,
                            isExpanded: true,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                            items: ['All', 'Ernakulam', 'Thrissur', 'Idukki']
                                .map((d) => DropdownMenuItem(value: d, child: Text('Dist: $d')))
                                .toList(),
                            onChanged: (val) => setState(() => _selectedDistrict = val!),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Risk Dropdown
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedRisk,
                            isExpanded: true,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                            items: ['All', 'HIGH RISK', 'MODERATE', 'SAFE']
                                .map((r) => DropdownMenuItem(value: r, child: Text('Risk: $r')))
                                .toList(),
                            onChanged: (val) => setState(() => _selectedRisk = val!),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Cut-off filter chip
                    FilterChip(
                      label: const Text('⚠️ Only Cut-Off Villages', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      selected: _onlyCutOff,
                      selectedColor: const Color(0xFFFEE2E2),
                      checkmarkColor: const Color(0xFFDC2626),
                      onSelected: (val) => setState(() => _onlyCutOff = val),
                    ),
                    const Spacer(),
                    // Sort By selector
                    PopupMenuButton<String>(
                      tooltip: 'Sort Table',
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F3FD),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.sort_rounded, size: 14, color: Color(0xFF007AEB)),
                            const SizedBox(width: 4),
                            Text(
                              'Sort: $_sortBy',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF007AEB)),
                            ),
                          ],
                        ),
                      ),
                      onSelected: (val) {
                        setState(() {
                          if (_sortBy == val) {
                            _sortAscending = !_sortAscending;
                          } else {
                            _sortBy = val;
                            _sortAscending = false;
                          }
                        });
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'risk', child: Text('Sort by Risk Score')),
                        const PopupMenuItem(value: 'leadTime', child: Text('Sort by Lead Time')),
                        const PopupMenuItem(value: 'population', child: Text('Sort by Population')),
                        const PopupMenuItem(value: 'name', child: Text('Sort by Village Name')),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Count summary bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: const Color(0xFFF1F5F9),
            child: Row(
              children: [
                Text(
                  'SHOWING ${villages.length} OF ${_allVillages.length} MONITORED VILLAGES',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5),
                ),
                const Spacer(),
                const Text(
                  'Tap village to dispatch',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),

          // Table list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: villages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final v = villages[index];
                return _villageRowCard(v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _villageRowCard(_VillageData v) {
    Color riskColor;
    Color bgTint;
    switch (v.riskLevel) {
      case 'HIGH RISK':
        riskColor = const Color(0xFFDC2626);
        bgTint = const Color(0xFFFEF2F2);
        break;
      case 'MODERATE':
        riskColor = const Color(0xFFEA580C);
        bgTint = const Color(0xFFFFF7ED);
        break;
      case 'SAFE':
      default:
        riskColor = const Color(0xFF16A34A);
        bgTint = const Color(0xFFF0FDF4);
        break;
    }

    return InkWell(
      onTap: () => _showVillageActionDialog(v),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: v.isCutOff ? const Color(0xFFDC2626).withValues(alpha: 0.5) : const Color(0xFFE2E8F0),
            width: v.isCutOff ? 1.5 : 1.0,
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        v.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      if (v.isCutOff) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'CUT-OFF',
                            style: TextStyle(fontSize: 8.5, color: Colors.white, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: bgTint,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: riskColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    v.riskLevel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: riskColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              '${v.district} District • Pop: ${v.population.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            // Metrics row
            Row(
              children: [
                _metricPill('Lead-Time', v.leadTimeDisplay, Icons.timer_rounded, riskColor),
                const SizedBox(width: 8),
                _metricPill('Water Gauge', v.waterLevel, Icons.water_rounded, const Color(0xFF0284C7)),
                const SizedBox(width: 8),
                _metricPill('Last Alert', v.lastAlertSent, Icons.notifications_active_rounded, const Color(0xFF64748B)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricPill(String title, String val, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 8.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                  Text(val, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVillageActionDialog(_VillageData v) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.shield_rounded, color: Color(0xFF007AEB)),
            const SizedBox(width: 8),
            Text(v.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('District: ${v.district}'),
            Text('Population: ${v.population}'),
            Text('Current Risk Level: ${v.riskLevel} (${v.riskScore}/100)'),
            Text('Estimated Inundation Lead Time: ${v.leadTimeDisplay}'),
            Text('Water Level: ${v.waterLevel} (Threshold: ${v.dangerThreshold})'),
            Text('Isolated / Cut-Off: ${v.isCutOff ? "YES - Aerial/Boat rescue needed" : "NO - Road access open"}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AlertDispatchScreen(preselectedVillage: v.name),
                ),
              );
            },
            icon: const Icon(Icons.broadcast_on_personal_rounded, size: 16),
            label: const Text('Send Alert'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _VillageData {
  final String name;
  final String district;
  final int riskScore;
  final String riskLevel;
  final double leadTimeHours;
  final String leadTimeDisplay;
  final int population;
  final String lastAlertSent;
  final bool isCutOff;
  final String waterLevel;
  final String dangerThreshold;

  _VillageData({
    required this.name,
    required this.district,
    required this.riskScore,
    required this.riskLevel,
    required this.leadTimeHours,
    required this.leadTimeDisplay,
    required this.population,
    required this.lastAlertSent,
    required this.isCutOff,
    required this.waterLevel,
    required this.dangerThreshold,
  });
}
