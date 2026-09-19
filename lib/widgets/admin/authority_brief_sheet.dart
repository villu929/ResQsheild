import 'package:flutter/material.dart';
import '../../services/resqshield_backend_service.dart';

class AuthorityBriefSheet extends StatefulWidget {
  const AuthorityBriefSheet({Key? key}) : super(key: key);

  @override
  State<AuthorityBriefSheet> createState() => _AuthorityBriefSheetState();
}

class _AuthorityBriefSheetState extends State<AuthorityBriefSheet> {
  String _status = 'DRAFT • NOT TRANSMITTED';
  String _priority = 'URGENT';
  String _recipient = 'District Authority';
  bool _isReady = false;
  final TextEditingController _noteController = TextEditingController();

  // API Data State
  bool _isLoadingIntelligence = true;
  List<Map<String, String>> _floodRiskItems = [];
  List<Map<String, String>> _landslideRiskItems = [];
  List<Map<String, String>> _extremeRainfallItems = [];
  String _satChangeText = '+18% surface water';
  String _satAffectedText = '14.2 sq km';

  final List<String> _priorities = ['ROUTINE', 'WATCH', 'URGENT', 'CRITICAL'];
  final List<String> _recipients = [
    'District Authority',
    'SDMA Control Room',
    'NDRF Control Room',
  ];

  void _sendToAuthority() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: const [
              Icon(Icons.satellite_alt_rounded, color: Color(0xFF6366F1)),
              SizedBox(width: 10),
              Text(
                'Prototype Mode',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Authority transmission is not connected in this prototype.',
              ),
              SizedBox(height: 10),
              Text(
                'This intelligence brief is ready for transmission. No data has been sent.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _status = 'READY FOR REVIEW';
                  _isReady = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Authority brief prepared — transmission pending integration.',
                    ),
                    backgroundColor: Color(0xFF6366F1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text(
                'Save as Ready for Review',
                style: TextStyle(
                  color: Color(0xFF6366F1),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchIntelligenceData();
  }

  Future<void> _fetchIntelligenceData() async {
    final backend = ResqshieldBackendService.instance;

    // Fetch in parallel
    final results = await Future.wait([
      backend.fetchFloodRiskDistricts(limit: 3),
      backend.fetchLandslideDistricts(limit: 3),
      backend.fetchIntelligenceSummary(),
    ]);

    final floodData = results[0] as List<Map<String, dynamic>>;
    final landslideData = results[1] as List<Map<String, dynamic>>;
    final intelData = results[2] as Map<String, dynamic>?;

    if (!mounted) return;

    setState(() {
      _isLoadingIntelligence = false;

      // Populate Floods
      if (floodData.isNotEmpty) {
        _floodRiskItems = floodData.map((d) {
          final loc = "${d['district']}, ${d['state']}";
          final score = (d['risk_score'] * 100).toInt();
          return {
            'location': loc,
            'score': 'Score: $score/100',
            'status': '${d['risk_level']} Risk',
          };
        }).toList();
      } else {
        _floodRiskItems = [
          {
            'location': 'Data unavailable',
            'score': 'N/A',
            'status': 'No flood risk data from API',
          },
        ];
      }

      // Populate Landslides
      if (landslideData.isNotEmpty) {
        _landslideRiskItems = landslideData.map((d) {
          final loc =
              "${d['district'] ?? 'Unknown'}, ${d['state'] ?? 'Unknown'}";
          final score = ((d['landslide_risk_score'] ?? 0.0) * 100).toInt();
          return {
            'location': loc,
            'score': 'Score: $score/100',
            'status': '${d['landslide_risk_level'] ?? 'HIGH'} Risk',
          };
        }).toList();
      } else {
        _landslideRiskItems = [
          {
            'location': 'Data unavailable',
            'score': 'N/A',
            'status': 'No landslide risk data from API',
          },
        ];
      }

      // Extreme Rainfall (Using GPM data from flood risk as fallback since no explicit rainfall alerts endpoint was provided, but user said "if available in risk payload")
      _extremeRainfallItems = [];
      for (var d in floodData) {
        if (d['gpm'] != null && d['gpm']['rainfall_mm_per_hour'] != null) {
          final mm = d['gpm']['rainfall_mm_per_hour'];
          if (mm > 5) {
            _extremeRainfallItems.add({
              'location': "${d['district']}, ${d['state']}",
              'score': '${mm.toStringAsFixed(1)} mm/hr',
              'status': 'Heavy Rainfall - GPM Detected',
            });
          }
        }
      }
      if (_extremeRainfallItems.isEmpty) {
        _extremeRainfallItems = [
          {
            'location': 'No extreme rainfall',
            'score': 'Normal',
            'status': 'Clear',
          },
        ];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 600, // Drawer width
      decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
      child: Column(
        children: [
          // HEADER
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Authority Intelligence Brief',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Generated from ResQShield Satellite Intelligence',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _isReady
                            ? const Color(0xFFE8F7F0)
                            : const Color(0xFFFFF3CD),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _status,
                        style: TextStyle(
                          color: _isReady
                              ? const Color(0xFF0E5C38)
                              : const Color(0xFF856404),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Priority Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _priority,
                          items: _priorities.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _priority = newValue!;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Recipient
                const Text(
                  'RECIPIENT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _recipient,
                      items: _recipients.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _recipient = newValue!;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // BODY
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              physics: const BouncingScrollPhysics(),
              children: [
                // 2. OBSERVATION DETAILS
                _buildSectionCard(
                  title: 'OBSERVATION DETAILS',
                  child: Column(
                    children: [
                      _buildDetailRow('Satellite Source', 'Sentinel-1 (SAR)'),
                      _buildDetailRow('Observation ID', 'RESQ-SAT-9942A'),
                      _buildDetailRow('Acquisition', 'Today, 14:15 IST'),
                      _buildDetailRow('Region', 'Damodar Lower Catchment'),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Data Freshness',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'FRESH',
                              style: TextStyle(
                                color: Color(0xFF0284C7),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow('Spatial Resolution', '10m / pixel'),
                      _buildDetailRow('Coverage', '94% Cloud-free equivalent'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. KEY SATELLITE FINDINGS
                _buildSectionCard(
                  title: 'KEY SATELLITE FINDINGS (PAN-INDIA)',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pan-India AI & Satellite Data
                      _buildRiskContainer(
                        title: 'High Flood Risk Areas',
                        icon: Icons.water_drop_rounded,
                        color: const Color(0xFF0284C7),
                        items: _isLoadingIntelligence
                            ? [
                                {
                                  'location': 'Loading data...',
                                  'score': 'Score: --/100',
                                  'status': 'Fetching latest satellite risk models...'
                                }
                              ]
                            : _floodRiskItems,
                      ),
                      _buildRiskContainer(
                        title: 'Active Landslide Zones',
                        icon: Icons.terrain_rounded,
                        color: const Color(0xFFB45309),
                        items: _isLoadingIntelligence
                            ? [
                                {
                                  'location': 'Loading data...',
                                  'score': 'Score: --/100',
                                  'status': 'Fetching latest satellite risk models...'
                                }
                              ]
                            : _landslideRiskItems,
                      ),
                      _buildRiskContainer(
                        title: 'Extreme Rainfall Alerts',
                        icon: Icons.thunderstorm_rounded,
                        color: const Color(0xFFDC2626),
                        items: _isLoadingIntelligence
                            ? [
                                {
                                  'location': 'Loading data...',
                                  'score': 'Score: --/100',
                                  'status': 'Fetching latest satellite risk models...'
                                }
                              ]
                            : _extremeRainfallItems,
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Divider(color: Color(0xFFE2E8F0)),
                      ),

                      // Local Data
                      const Text(
                        'Local Region: Significant water-spread expansion detected',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Flood extent has increased in the lower catchment compared with the previous observation. Expansion is concentrated near downstream road and bridge assets.',
                        style: TextStyle(color: Color(0xFF334155), height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      _buildMetricRow(
                        'Detected Change',
                        _isLoadingIntelligence ? 'Loading...' : _satChangeText,
                      ),
                      _buildMetricRow(
                        'Affected Area',
                        _isLoadingIntelligence
                            ? 'Loading...'
                            : _satAffectedText,
                      ),
                      _buildMetricRow(
                        'Satellite Evidence Confidence',
                        'HIGH (92%)',
                        color: const Color(0xFFB45309),
                      ),
                      _buildMetricRow(
                        'Change Detection Confidence',
                        'HIGH (89%)',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 4. SATELLITE EVIDENCE PREVIEW
                _buildSectionCard(
                  title: 'EVIDENCE PREVIEW',
                  child: Column(
                    children: [
                      Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(8),
                          image: const DecorationImage(
                            image: NetworkImage(
                              'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=600&q=80',
                            ), // Placeholder for map
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'SAT-MAP RENDERING',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.map, size: 18),
                        label: const Text('Open Full Evidence Map'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF6366F1),
                          side: const BorderSide(color: Color(0xFF6366F1)),
                          minimumSize: const Size.fromHeight(40),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 5. EVIDENCE CORROBORATION
                _buildSectionCard(
                  title: 'EVIDENCE CORROBORATION',
                  child: Column(
                    children: [
                      _buildCorroborationRow(
                        'Satellite flood extent',
                        'STRONG',
                        const Color(0xFF059669),
                      ),
                      _buildCorroborationRow(
                        'Upstream rainfall',
                        'EXTREME',
                        const Color(0xFFDC2626),
                      ),
                      _buildCorroborationRow(
                        'River rate-of-rise',
                        'CRITICAL',
                        const Color(0xFFDC2626),
                      ),
                      _buildCorroborationRow(
                        'Ground sensor agreement',
                        'HIGH',
                        const Color(0xFFD97706),
                      ),
                      _buildCorroborationRow(
                        'Verified field reports',
                        '2',
                        const Color(0xFF6366F1),
                      ),
                      const Divider(height: 24),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.check_circle,
                              color: Color(0xFF059669),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '4 of 5 available evidence channels support escalation.',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 6. POTENTIAL OPERATIONAL IMPACT
                _buildSectionCard(
                  title:
                      'CRITICAL INFRASTRUCTURE DAMAGE (HIMACHAL, BIHAR, JHARKHAND)',
                  child: Column(
                    children: [
                      _buildRiskContainer(
                        title: 'Blocked Routes & Highways',
                        icon: Icons.add_road_rounded,
                        color: const Color(0xFFDC2626),
                        items: [
                          {
                            'location': 'NH-3, Mandi (Himachal)',
                            'score': 'BLOCKED',
                            'status': 'Massive landslide debris on route.',
                          },
                          {
                            'location': 'NH-31, Patna (Bihar)',
                            'score': 'SUBMERGED',
                            'status': '4ft flood water over highway.',
                          },
                          {
                            'location': 'SH-24, Ranchi (Jharkhand)',
                            'score': 'COLLAPSED',
                            'status': 'Bridge washed away in flash flood.',
                          },
                        ],
                      ),
                      _buildRiskContainer(
                        title: 'Hospitals & Schools Affected',
                        icon: Icons.local_hospital_rounded,
                        color: const Color(0xFFB45309),
                        items: [
                          {
                            'location': 'Darbhanga Medical (Bihar)',
                            'score': 'EVACUATING',
                            'status': 'Ground floor completely flooded.',
                          },
                          {
                            'location': 'Govt High School, Kullu',
                            'score': 'DAMAGED',
                            'status': 'Roof damaged by landslide boulders.',
                          },
                          {
                            'location': 'Sadar Hospital, Deoghar',
                            'score': 'INACCESSIBLE',
                            'status': 'Surrounding area severely waterlogged.',
                          },
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.visibility, size: 18),
                        label: const Text(
                          'View full infrastructure damage report',
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF6366F1),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 7. WHY AUTHORITY SHOULD REVIEW THIS
                _buildSectionCard(
                  title: 'ANALYSIS SUMMARY',
                  child: const Text(
                    'Satellite imagery shows expanding surface water downstream while upstream rainfall and river-rise observations are also elevated. Evidence is consistent across multiple sources. Immediate public evacuation is not being issued from this screen; authority review is recommended.',
                    style: TextStyle(
                      color: Color(0xFF334155),
                      height: 1.5,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 8. RECOMMENDED AUTHORITY REVIEW
                _buildSectionCard(
                  title: 'RECOMMENDED ACTION CHECKLIST',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildChecklistItem('Inspect Rampur priority status'),
                      _buildChecklistItem('Verify Bridge B2 availability'),
                      _buildChecklistItem('Review evacuation route'),
                      _buildChecklistItem('Confirm nearby shelter capacity'),
                      _buildChecklistItem('Review current flood warning level'),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: const [
                            Text(
                              'Suggested Authority Action',
                              style: TextStyle(
                                color: Color(0xFFDC2626),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'REVIEW FOR WARNING ESCALATION',
                              style: TextStyle(
                                color: Color(0xFF991B1B),
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 9. ADMIN NOTE
                const Text(
                  'OPERATIONAL NOTE FOR AUTHORITY (OPTIONAL)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  maxLines: 3,
                  maxLength: 250,
                  decoration: InputDecoration(
                    hintText:
                        'Add contextual information, verification note or reason for review...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF6366F1)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 10. BOTTOM ACTION BAR
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              boxShadow: [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 10,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    foregroundColor: const Color(0xFF475569),
                  ),
                  child: const Text(
                    'Save Draft',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.preview, size: 18),
                  label: const Text('Preview as Authority'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    side: const BorderSide(color: Color(0xFF6366F1)),
                    foregroundColor: const Color(0xFF6366F1),
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _sendToAuthority,
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Send to Authority',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'DEMO MODE',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.white70,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x050F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskContainer({
    required String title,
    required IconData icon,
    required Color color,
    required List<Map<String, String>> items,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item['location']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                                fontSize: 13,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item['score']!,
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item['status']!,
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.arrow_right,
            size: 16,
            color: color ?? const Color(0xFF64748B),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF475569)),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color ?? const Color(0xFF0F172A),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorroborationRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontWeight: FontWeight.w500,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(
            Icons.check_box_outline_blank,
            size: 18,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF334155)),
            ),
          ),
        ],
      ),
    );
  }
}
