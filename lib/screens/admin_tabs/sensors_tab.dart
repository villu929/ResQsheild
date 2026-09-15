import 'package:flutter/material.dart';
import '../../widgets/admin/shared_admin_widgets.dart';

class SensorsTab extends StatefulWidget {
  const SensorsTab({Key? key}) : super(key: key);

  @override
  State<SensorsTab> createState() => _SensorsTabState();
}

class _SensorsTabState extends State<SensorsTab> {
  String _selectedNodeId = 'JG-RIVER-021';

  final List<Map<String, dynamic>> _sensorNodes = [
    {
      'id': 'JG-RIVER-021',
      'name': 'Tenughat Dam Inflow Station',
      'location': 'Damodar Basin Reach 3',
      'status': 'Online',
      'color': const Color(0xFF10B981),
      'battery': 78,
      'loraRssi': '-68 dBm (Strong)',
      'lastData': '12s ago',
      'waterLevel': 'Operational (🟢)',
      'rainGauge': 'Operational (🟢)',
      'flowSensor': 'Operational (🟢)',
      'tiltSensor': 'Operational (🟢)',
      'soilMoisture': 'Operational (🟢)',
    },
    {
      'id': 'JG-001',
      'name': 'Bokaro Bridge Pier Node',
      'location': 'Bokaro Sector 4',
      'status': 'Online',
      'color': const Color(0xFF10B981),
      'battery': 94,
      'loraRssi': '-72 dBm (Normal)',
      'lastData': '24s ago',
      'waterLevel': 'Operational (🟢)',
      'rainGauge': 'Operational (🟢)',
      'flowSensor': 'Operational (🟢)',
      'tiltSensor': 'Operational (🟢)',
      'soilMoisture': 'Operational (🟢)',
    },
    {
      'id': 'JG-002',
      'name': 'Dhanbad Culvert Gauge',
      'location': 'NH-18 Highway Mile 42',
      'status': 'Online',
      'color': const Color(0xFF10B981),
      'battery': 82,
      'loraRssi': '-64 dBm (Strong)',
      'lastData': '40s ago',
      'waterLevel': 'Operational (🟢)',
      'rainGauge': 'Operational (🟢)',
      'flowSensor': 'Operational (🟢)',
      'tiltSensor': 'Operational (🟢)',
      'soilMoisture': 'Operational (🟢)',
    },
    {
      'id': 'JG-003',
      'name': 'Upper Catchment Micro-Node',
      'location': 'Mawryngkneng Ridge Peak',
      'status': 'Offline',
      'color': const Color(0xFFEF4444),
      'battery': 4,
      'loraRssi': 'Disconnected (No Packet)',
      'lastData': '42m ago',
      'waterLevel': 'Fault (🔴)',
      'rainGauge': 'No Signal (🔴)',
      'flowSensor': 'Offline (🔴)',
      'tiltSensor': 'Offline (🔴)',
      'soilMoisture': 'Offline (🔴)',
    },
    {
      'id': 'JG-004',
      'name': 'Embankment Slump Gauge',
      'location': 'Garga Reservoir Spur 2',
      'status': 'Online',
      'color': const Color(0xFF10B981),
      'battery': 88,
      'loraRssi': '-76 dBm (Normal)',
      'lastData': '1m ago',
      'waterLevel': 'Operational (🟢)',
      'rainGauge': 'Operational (🟢)',
      'flowSensor': 'Operational (🟢)',
      'tiltSensor': 'Operational (🟢)',
      'soilMoisture': 'Operational (🟢)',
    },
    {
      'id': 'JG-021',
      'name': 'Catchment Sub-Station Alpha',
      'location': 'Berm B7, South Sector',
      'status': 'Warning',
      'color': const Color(0xFFF59E0B),
      'battery': 18,
      'loraRssi': '-89 dBm (Weak)',
      'lastData': '3m ago',
      'waterLevel': 'Low Voltage (🟠)',
      'rainGauge': 'Operational (🟢)',
      'flowSensor': 'Operational (🟢)',
      'tiltSensor': 'Degraded (🟠)',
      'soilMoisture': 'Operational (🟢)',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final activeNode = _sensorNodes.firstWhere(
      (n) => n['id'] == _selectedNodeId,
      orElse: () => _sensorNodes[0],
    );

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(14),
      children: [
        // Sensor Network Counts Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x050F172A),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SENSOR NETWORK SUMMARY',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _buildHardwareStat('🟢 Online', '248 Nodes', const Color(0xFF10B981)),
                  _buildHardwareStat('🟠 Warning', '3 Nodes', const Color(0xFFF59E0B)),
                  _buildHardwareStat('🔴 Offline', '1 Node', const Color(0xFFEF4444)),
                  _buildHardwareStat('📡 LoRa Packets', '99.2%', const Color(0xFF007AEB)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const SectionHeader(
          icon: Icons.developer_board_rounded,
          title: 'Node Telemetry Inspector',
          iconColor: Color(0xFF7351D8),
        ),
        const SizedBox(height: 12),

        // Deep-dive Selected Node Inspection Card
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: Container(
            key: ValueKey<String>(activeNode['id'] as String),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F0F172A),
                  blurRadius: 10,
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (activeNode['color'] as Color).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.router_rounded,
                        color: activeNode['color'] as Color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activeNode['name'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${activeNode['id']} • ${activeNode['location']}',
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedStatusChip(
                      label: activeNode['status'] as String,
                      color: activeNode['color'] as Color,
                    ),
                  ],
                ),
                const Divider(height: 28, color: Color(0xFF334155)),

                // Sensor Sub-modules telemetry
                _buildSensorSubRow('🌊 Ultrasonic Water Level', activeNode['waterLevel'] as String),
                _buildSensorSubRow('🌧️ Tipping Bucket Rain Gauge', activeNode['rainGauge'] as String),
                _buildSensorSubRow('💨 Flow Velocity Sensor', activeNode['flowSensor'] as String),
                _buildSensorSubRow('📐 MEMS Tilt Inclinometer', activeNode['tiltSensor'] as String),
                _buildSensorSubRow('🌱 Volumetric Soil Moisture', activeNode['soilMoisture'] as String),

                const Divider(height: 24, color: Color(0xFF334155)),

                // Telemetry status
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.battery_charging_full_rounded, color: Color(0xFFCBD5E1), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${activeNode['battery']}%',
                            style: const TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.wifi_rounded, color: Color(0xFFCBD5E1), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${activeNode['loraRssi']}',
                            style: const TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.timer_rounded, color: Color(0xFF4ADE80), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${activeNode['lastData']}',
                          style: const TextStyle(
                            color: Color(0xFF4ADE80),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Node Selector List
        const SectionHeader(
          icon: Icons.list_alt_rounded,
          title: 'Select Node for Telemetry Audit',
        ),
        const SizedBox(height: 12),

        ..._sensorNodes.map((n) => _buildNodeListTile(n)),
      ],
    );
  }

  Widget _buildHardwareStat(String title, String val, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            val,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorSubRow(String sensor, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            sensor,
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            status,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeListTile(Map<String, dynamic> n) {
    final bool isSelected = n['id'] == _selectedNodeId;
    final Color statusColor = n['color'] as Color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedNodeId = n['id'] as String),
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFF3F0FC) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? const Color(0xFF7351D8) : const Color(0xFFE2E8F0),
                width: isSelected ? 1.6 : 1.0,
              ),
              boxShadow: [
                if (isSelected)
                  const BoxShadow(
                    color: Color(0x117351D8),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor,
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.4),
                        blurRadius: 4,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${n['id']} • ${n['name']}',
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        n['location'] as String,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: n['battery'] < 20 ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Batt: ${n['battery']}%',
                    style: TextStyle(
                      color: n['battery'] < 20
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isSelected ? const Color(0xFF7351D8) : const Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
