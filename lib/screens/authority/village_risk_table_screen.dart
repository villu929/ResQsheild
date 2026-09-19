import 'package:flutter/material.dart';
import 'alert_dispatch_screen.dart';
import '../../services/incident_coordinator.dart';
import '../../services/resqshield_backend_service.dart';
class VillageRiskTableScreen extends StatefulWidget {
  const VillageRiskTableScreen({super.key});

  @override
  State<VillageRiskTableScreen> createState() => _VillageRiskTableScreenState();
}

class _VillageRiskTableScreenState extends State<VillageRiskTableScreen> {
  List<_VillageData> _allVillages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVillageRisk();
  }

  Future<void> _fetchVillageRisk() async {
    final backend = ResqshieldBackendService.instance;
    final districts = await backend.fetchFloodRiskDistricts(limit: 10);
    
    if (!mounted) return;

    if (districts.isNotEmpty) {
      final List<_VillageData> apiVillages = districts.map((d) {
        final level = d['risk_level'] ?? 'LOW';
        String mappedLevel = 'YLW';
        if (level == 'CRITICAL') mappedLevel = 'RED';
        else if (level == 'HIGH') mappedLevel = 'ORG';
        
        final riskScoreDouble = (d['risk_score'] as num?)?.toDouble() ?? 0.0;
        
        return _VillageData(
          name: d['district'] ?? 'Unknown',
          district: d['state'] ?? 'Unknown',
          riskScore: (riskScoreDouble * 100).toInt(),
          riskLevel: mappedLevel,
          leadTimeDisplay: mappedLevel == 'RED' ? '30 min' : '60+ min',
          population: 1000 + (riskScoreDouble * 1000).toInt(),
          isCutOff: mappedLevel == 'RED',
          roadsStatus: mappedLevel == 'RED' ? '1 unsafe' : 'All safe',
          confidence: 80 + (riskScoreDouble * 15).toInt(),
        );
      }).toList();

      setState(() {
        _allVillages = apiVillages;
        _isLoading = false;
      });
    } else {
      // Fallback
      setState(() {
        _isLoading = false;
        _allVillages = [
          _VillageData(
            name: 'No data',
            district: '',
            riskScore: 0,
            riskLevel: 'GRN',
            leadTimeDisplay: '-',
            population: 0,
            isCutOff: false,
            roadsStatus: '-',
            confidence: 0,
          )
        ];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
              'Purpose: Kaun sa village pehle handle karna hai?',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const Divider(height: 1),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  dataRowMaxHeight: 65,
                  dataRowMinHeight: 55,
                  columnSpacing: 24,
                  columns: const [
                    DataColumn(label: Text('Village')),
                    DataColumn(label: Text('Risk\nLevel')),
                    DataColumn(label: Text('Pop.\nExposed')),
                    DataColumn(label: Text('Lead\nTime')),
                    DataColumn(label: Text('Roads\nStatus')),
                    DataColumn(label: Text('Conf.')),
                    DataColumn(label: Text('Priority\nScore')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: _allVillages.map((v) {
                    Color riskColor;
                    switch (v.riskLevel) {
                      case 'RED':
                        riskColor = const Color(0xFFDC2626);
                        break;
                      case 'ORG':
                        riskColor = const Color(0xFFEA580C);
                        break;
                      case 'YLW':
                      default:
                        riskColor = const Color(0xFFEAB308);
                        break;
                    }

                    return DataRow(
                      cells: [
                        DataCell(Text(v.name, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A)))),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(color: riskColor, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Text(v.riskLevel, style: TextStyle(color: riskColor, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        DataCell(Text(v.population.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},'))),
                        DataCell(Text(v.leadTimeDisplay)),
                        DataCell(Text(v.roadsStatus)),
                        DataCell(Text('${v.confidence}%')),
                        DataCell(Text('${v.riskScore}')),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _showAssignTeamModal(v),
                                icon: const Icon(Icons.group_add_rounded, size: 14),
                                label: const Text('Assign Team', style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0284C7),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                  elevation: 0,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => AlertDispatchScreen(preselectedVillage: v.name)),
                                  );
                                },
                                icon: const Icon(Icons.warning_amber_rounded, size: 14),
                                label: const Text('Evac Warning', style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFDC2626),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                  elevation: 0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAssignTeamModal(_VillageData v) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ASSIGN TEAM TO ${v.name.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            const SizedBox(height: 10),
            ...IncidentCoordinator.instance.responderTeams.map(
              (team) => ListTile(
                leading: Icon(
                  Icons.directions_boat,
                  color: team.status == 'Available' ? const Color(0xFF16A34A) : const Color(0xFFEA580C),
                ),
                title: Text('${team.name} (${team.unit})'),
                subtitle: Text('Status: ${team.status} · ETA: ${team.etaEstimate}'),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
                  onPressed: () {
                    final targetTeamId = team.teamId;

                    // Create SOS and assign so it reflects in field responder
                    final newSos = IncidentCoordinator.instance.createSos(
                      callerName: 'Authority - ${v.name}',
                      village: v.name,
                      latitude: 25.4485, // Dummy for Meghalaya
                      longitude: 91.7582,
                      peopleCount: v.population,
                      elderlyCount: 0,
                      childrenCount: 0,
                      hasMedical: false,
                      emergencyType: 'Evacuation',
                    );

                    IncidentCoordinator.instance.assignMission(
                      sosId: newSos.id,
                      teamId: targetTeamId,
                    );

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Team assigned to ${v.name}. Mission dispatched to Field Responder!')),
                    );
                  },
                  child: const Text('Assign'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VillageData {
  final String name;
  final String district;
  final int riskScore;
  final String riskLevel;
  final String leadTimeDisplay;
  final int population;
  final bool isCutOff;
  final String roadsStatus;
  final int confidence;

  _VillageData({
    required this.name,
    required this.district,
    required this.riskScore,
    required this.riskLevel,
    required this.leadTimeDisplay,
    required this.population,
    required this.isCutOff,
    required this.roadsStatus,
    required this.confidence,
  });
}
