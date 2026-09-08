import 'package:flutter/material.dart';

class FieldResponderView extends StatefulWidget {
  const FieldResponderView({super.key});

  @override
  State<FieldResponderView> createState() => _FieldResponderViewState();
}

class _FieldResponderViewState extends State<FieldResponderView> {
  bool _isOnDuty = true;
  int _evacuatedCount = 142;

  // Tactical operational tasks
  final List<Map<String, dynamic>> _missions = [
    {
      'id': 'MSN-8841',
      'title': 'Submerged Road Extraction',
      'location': 'Damodar River Culvert #4, Dhanbad',
      'priority': 'CRITICAL',
      'status': 'In Progress',
      'assignedTeam': 'NDRF Team Bravo (6 Responders)',
      'distance': '1.2 km away',
      'time': '10 mins ago',
      'icon': Icons.warning_amber_rounded,
      'color': Color(0xFFE92828),
    },
    {
      'id': 'MSN-8840',
      'title': 'Elderly & Patient Evacuation',
      'location': 'Ward 7 Community Hall to St. Xavier Shelter',
      'priority': 'HIGH',
      'status': 'En Route',
      'assignedTeam': 'SDRF Quick Response #2',
      'distance': '2.8 km away',
      'time': '25 mins ago',
      'icon': Icons.transfer_within_a_station_rounded,
      'color': Color(0xFFF39A20),
    },
    {
      'id': 'MSN-8839',
      'title': 'Tree & Power Cable Clearance',
      'location': 'State Highway 18, Bypass Road',
      'priority': 'MODERATE',
      'status': 'Dispatched',
      'assignedTeam': 'PWD Rapid Clear Team 3',
      'distance': '4.5 km away',
      'time': '40 mins ago',
      'icon': Icons.handyman_rounded,
      'color': Color(0xFF007AEB),
    },
    {
      'id': 'MSN-8838',
      'title': 'Potable Water Distribution Point',
      'location': 'Govt High School Relief Camp, Bokaro',
      'priority': 'RESOLVED',
      'status': 'Completed',
      'assignedTeam': 'Civil Defence & Red Cross',
      'distance': '6.1 km away',
      'time': '1 hr ago',
      'icon': Icons.check_circle_outline_rounded,
      'color': Color(0xFF15945C),
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

  void _showReportIncidentDialog() {
    final titleController = TextEditingController();
    final locationController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: const [
            Icon(Icons.add_alert_rounded, color: Color(0xFFE92828)),
            SizedBox(width: 8),
            Text(
              'Report Field Incident',
              style: TextStyle(
                color: Color(0xFF013973),
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
              'Broadcast live hazards to Command Center & nearby field teams:',
              style: TextStyle(color: Color(0xFF537392), fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Incident Type / Title',
                hintText: 'e.g., Embankment breach, road collapsed',
                filled: true,
                fillColor: const Color(0xFFF3F8FD),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD6E8F7)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: locationController,
              decoration: InputDecoration(
                labelText: 'Location / Landmark',
                hintText: 'e.g., Near Bokaro bridge pillar 3',
                filled: true,
                fillColor: const Color(0xFFF3F8FD),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD6E8F7)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF537392))),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _showMessage('Incident reported and synced via LoRa Mesh telemetry');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007AEB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Broadcast'),
          ),
        ],
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
          tooltip: 'Back to Role Selection',
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Field Responder Portal',
              style: TextStyle(
                color: Color(0xFF013973),
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              'Tactical Ground Unit • NDRF & Responders',
              style: TextStyle(
                color: Color(0xFF537392),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          // On-Duty Toggle Badge
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                setState(() => _isOnDuty = !_isOnDuty);
                _showMessage(_isOnDuty ? 'Status: Active On-Duty' : 'Status: On Standby');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _isOnDuty ? const Color(0xFFEAF8F0) : const Color(0xFFFFF5E7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isOnDuty ? const Color(0xFF15945C) : const Color(0xFFF39A20),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isOnDuty ? const Color(0xFF15945C) : const Color(0xFFF39A20),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isOnDuty ? 'ACTIVE' : 'STANDBY',
                      style: TextStyle(
                        color: _isOnDuty ? const Color(0xFF15945C) : const Color(0xFFF39A20),
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
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Tactical Telemetry Bar
            _buildTelemetryBar(),

            const SizedBox(height: 14),

            // 2. Unit Identity & Stats Card
            _buildUnitHeaderCard(),

            const SizedBox(height: 16),

            // 3. Quick Frontline Action Tiles
            const Text(
              'TACTICAL ACTIONS',
              style: TextStyle(
                color: Color(0xFF013973),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            _buildQuickActionGrid(),

            const SizedBox(height: 20),

            // 4. Mission Dispatch List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ASSIGNED MISSIONS',
                  style: TextStyle(
                    color: Color(0xFF013973),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AEB).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_missions.length} Missions Active',
                    style: const TextStyle(
                      color: Color(0xFF007AEB),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ..._missions.map((m) => _buildMissionCard(m)),

            const SizedBox(height: 20),

            // 5. Equipment & Gear Readiness
            _buildEquipmentCard(),

            const SizedBox(height: 24),

            // 6. Return / Switch Role Button
            Center(
              child: TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                label: const Text('Switch to Different Operational Role'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF013973),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TELEMETRY BAR
  // --------------------------------------------------------------------------
  Widget _buildTelemetryBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF013973),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF013973).withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _telemetryItem(Icons.my_location_rounded, 'GPS Fix', '23.79°N, 86.43°E'),
          Container(width: 1, height: 26, color: Colors.white24),
          _telemetryItem(Icons.wifi_tethering_rounded, 'LoRa Mesh', 'CH-04 Online'),
          Container(width: 1, height: 26, color: Colors.white24),
          _telemetryItem(Icons.battery_charging_full_rounded, 'Battery', '89% Healthy'),
        ],
      ),
    );
  }

  Widget _telemetryItem(IconData icon, String title, String val) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF38BDF8), size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w600),
            ),
            Text(
              val,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // UNIT HEADER CARD
  // --------------------------------------------------------------------------
  Widget _buildUnitHeaderCard() {
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
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF15945C).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shield_rounded, color: Color(0xFF15945C), size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NDRF Tactical Unit 09',
                  style: TextStyle(
                    color: Color(0xFF013973),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Sector Command: Dhanbad & Damodar Valley Basin',
                  style: TextStyle(
                    color: Color(0xFF537392),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.people_alt_rounded, size: 14, color: Color(0xFF007AEB)),
                    const SizedBox(width: 4),
                    Text(
                      '$_evacuatedCount Citizens Safely Relocated',
                      style: const TextStyle(
                        color: Color(0xFF007AEB),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // QUICK ACTION GRID
  // --------------------------------------------------------------------------
  Widget _buildQuickActionGrid() {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            icon: Icons.add_alert_rounded,
            label: 'Report Incident',
            color: const Color(0xFFE92828),
            onTap: _showReportIncidentDialog,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionButton(
            icon: Icons.person_add_alt_1_rounded,
            label: 'Log Evacuee',
            color: const Color(0xFF15945C),
            onTap: () {
              setState(() => _evacuatedCount += 1);
              _showMessage('Evacuee logged. Total relocated: $_evacuatedCount');
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionButton(
            icon: Icons.alt_route_rounded,
            label: 'Route Blocked',
            color: const Color(0xFFF39A20),
            onTap: () => _showMessage('Marking current waypoint as non-passable to central dispatch'),
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD6E8F7)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF0F2642),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // MISSION CARD
  // --------------------------------------------------------------------------
  Widget _buildMissionCard(Map<String, dynamic> m) {
    final Color priorityColor = m['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD6E8F7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  m['priority'],
                  style: TextStyle(
                    color: priorityColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 12, color: const Color(0xFF537392)),
                  const SizedBox(width: 4),
                  Text(
                    m['time'],
                    style: const TextStyle(color: Color(0xFF537392), fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            m['title'],
            style: const TextStyle(
              color: Color(0xFF013973),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF537392)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  m['location'],
                  style: const TextStyle(color: Color(0xFF537392), fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F8FD),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  m['assignedTeam'],
                  style: const TextStyle(
                    color: Color(0xFF013973),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  m['distance'],
                  style: const TextStyle(
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
    );
  }

  // --------------------------------------------------------------------------
  // EQUIPMENT READINESS
  // --------------------------------------------------------------------------
  Widget _buildEquipmentCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD6E8F7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.inventory_2_rounded, color: Color(0xFF013973), size: 18),
              SizedBox(width: 8),
              Text(
                'Unit Gear Readiness',
                style: TextStyle(
                  color: Color(0xFF013973),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _gearBadge('4 IRBs (Boats)', Icons.directions_boat_rounded),
              const SizedBox(width: 8),
              _gearBadge('12 Life Buoys', Icons.health_and_safety_rounded),
              const SizedBox(width: 8),
              _gearBadge('2 SatPhones', Icons.phone_in_talk_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _gearBadge(String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F8FD),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD6E8F7)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: const Color(0xFF007AEB)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF013973),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
