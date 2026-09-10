import 'package:flutter/material.dart';

class AdminConsoleView extends StatefulWidget {
  const AdminConsoleView({super.key});

  @override
  State<AdminConsoleView> createState() => _AdminConsoleViewState();
}

class _AdminConsoleViewState extends State<AdminConsoleView> {
  // Active Navigation Tab: 0 = System Health & Services, 1 = Hardware & Sensors, 2 = Satellite & AI, 3 = Alerts & Logs
  int _selectedTabIndex = 0;

  // Selected sensor node for deep-dive inspection card
  String _selectedNodeId = 'JG-RIVER-021';

  // System States & Telemetry Data
  int _alertBroadcastCount = 14;

  // Sensor Hardware List
  final List<Map<String, dynamic>> _sensorNodes = [
    {
      'id': 'JG-RIVER-021',
      'name': 'Tenughat Dam Inflow Station',
      'location': 'Damodar Basin Reach 3',
      'status': 'Online',
      'color': Color(0xFF10B981),
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
      'color': Color(0xFF10B981),
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
      'color': Color(0xFF10B981),
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
      'color': Color(0xFFEF4444),
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
      'color': Color(0xFF10B981),
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
      'color': Color(0xFFF59E0B),
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

  // System Terminal Event Logs
  final List<Map<String, dynamic>> _systemLogs = [
    {
      'time': '12:31:04',
      'level': 'INFO',
      'source': 'Sensor Mesh Gateway',
      'message': 'Sensor JG-021 telemetry heartbeat verified via LoRa channel 3',
      'color': Color(0xFF10B981),
    },
    {
      'time': '12:29:48',
      'level': 'SUCCESS',
      'source': 'Satellite Pipeline',
      'message': 'Sentinel-1 SAR synthetic aperture radar tile ingested & orthorectified',
      'color': Color(0xFF007AEB),
    },
    {
      'time': '12:27:12',
      'level': 'SYS',
      'source': 'AI Engine Inference',
      'message': 'AI Flood Depth & Inundation prediction completed (latency 380ms)',
      'color': Color(0xFF7351D8),
    },
    {
      'time': '12:25:30',
      'level': 'INFO',
      'source': 'CAP Alert Relay',
      'message': 'Alert notification microservice worker pool refreshed and operational',
      'color': Color(0xFF10B981),
    },
    {
      'time': '12:20:15',
      'level': 'WARN',
      'source': 'Power Telemetry',
      'message': 'Node JG-021 battery dropped below 20% (solar charge degraded due to clouds)',
      'color': Color(0xFFF59E0B),
    },
    {
      'time': '12:14:02',
      'level': 'CRIT',
      'source': 'Hardware Daemon',
      'message': 'Sensor JG-003 timeout: 3 consecutive packets dropped. Flagged OFFLINE',
      'color': Color(0xFFEF4444),
    },
  ];

  void _showMessage(String msg, {Color bgColor = const Color(0xFF0F172A)}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showCapBroadcastDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text(
              'CAP Early Warning Override',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: const Text(
          'Simulate sending a Common Alerting Protocol (CAP v1.2) emergency payload across all active Citizen & Field Responder devices.',
          style: TextStyle(color: Color(0xFF537392), fontSize: 13, height: 1.3),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF537392))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _alertBroadcastCount += 1);
              _showMessage(
                'CAP Emergency Alert payload verified & dispatched to 42,000 devices',
                bgColor: const Color(0xFF7351D8),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7351D8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Execute Broadcast'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: _buildSysadminAppBar(),
      body: IndexedStack(
        index: _selectedTabIndex,
        children: [
          _buildSystemOverviewTab(),
          _buildSensorHardwareTab(),
          _buildSatelliteAndAiTab(),
          _buildAlertsAndLogsTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // ==========================================================================
  // TOP SYSADMIN APP BAR
  // ==========================================================================
  PreferredSizeWidget _buildSysadminAppBar() {
    return AppBar(
      elevation: 0.5,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF0F172A), size: 18),
        onPressed: () => Navigator.pop(context),
        tooltip: 'Exit to Role Selection',
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'JALGUARD SYSADMIN',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F0FC),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'ROOT CONSOLE',
                  style: TextStyle(
                    color: Color(0xFF7351D8),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: const [
              Icon(Icons.check_circle_rounded,
                  color: Color(0xFF10B981), size: 12),
              SizedBox(width: 4),
              Text(
                'Telemetry Active • 99.98% SLA',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: IconButton(
            icon: const Icon(Icons.broadcast_on_personal_rounded,
                color: Color(0xFF7351D8), size: 22),
            onPressed: _showCapBroadcastDialog,
            tooltip: 'Trigger CAP Broadcast',
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // TAB 0: SYSTEM HEALTH & SERVICES OVERVIEW
  // ==========================================================================
  Widget _buildSystemOverviewTab() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(14),
      children: [
        // 1. System Health Master Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x240F172A),
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
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.hub_rounded,
                      color: Color(0xFF4ADE80),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SYSTEM HEALTH TELEMETRY',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Core Infrastructure Operational',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF10B981)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.circle, color: Color(0xFF4ADE80), size: 7),
                        SizedBox(width: 5),
                        Text(
                          'NORMAL',
                          style: TextStyle(
                            color: Color(0xFF4ADE80),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: Color(0xFF334155)),

              // 6 Core Metrics Grid
              Row(
                children: [
                  _buildHealthItem('📡 Sensors', '248 / 252', '🟢 OK'),
                  _buildHealthItem('🛰️ Satellite', 'Sync Active', '🟢 OK'),
                  _buildHealthItem('☁️ Backend', '42ms Latency', '🟢 OK'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildHealthItem('🤖 AI Engine', 'v2.1 Running', '🟢 OK'),
                  _buildHealthItem('📱 Alerts', '98.4% Delivered', '🟢 OK'),
                  _buildHealthItem('🗄️ Database', 'Replica Synced', '🟢 OK'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Critical System Alerts Box
        Row(
          children: const [
            Icon(Icons.notifications_active_rounded,
                color: Color(0xFFF59E0B), size: 18),
            SizedBox(width: 8),
            Text(
              'Active System Alerts & Diagnostics',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 14.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        _buildAlertCard(
          '🔴 Hardware Node JG-003 Offline',
          '3 consecutive packets dropped • Solar battery empty • Field tech dispatched',
          const Color(0xFFFEE2E2),
          const Color(0xFFDC2626),
        ),
        _buildAlertCard(
          '🟠 Sensor Node JG-021 Low Voltage',
          'Battery at 18% • River gauge operating on backup capacitor',
          const Color(0xFFFEF3C7),
          const Color(0xFFD97706),
        ),
        _buildAlertCard(
          '🟠 Satellite Processing Queue Delayed',
          'Sentinel-2 multispectral tile ingest delayed by 4 minutes (Cloud API queue)',
          const Color(0xFFFEF3C7),
          const Color(0xFFD97706),
        ),
        _buildAlertCard(
          '🟢 Automated Database Snapshot Completed',
          'Hourly hot backup synced to encrypted offsite disaster vault',
          const Color(0xFFE8F7F0),
          const Color(0xFF0E5C38),
        ),
        const SizedBox(height: 16),

        // 3. System Services Architecture Grid
        Row(
          children: const [
            Icon(Icons.dns_rounded, color: Color(0xFF7351D8), size: 18),
            SizedBox(width: 8),
            Text(
              'Microservices & Pipeline Health',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 14.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              _buildServiceRow('REST & GraphQL API Gateway', '🟢 Operational',
                  '18ms', true),
              const Divider(height: 18, color: Color(0xFFF1F5F9)),
              _buildServiceRow('TimescaleDB Telemetry Store', '🟢 Operational',
                  '12ms', true),
              const Divider(height: 18, color: Color(0xFFF1F5F9)),
              _buildServiceRow(
                  'MFA & Role Auth Cluster', '🟢 Operational', '24ms', true),
              const Divider(height: 18, color: Color(0xFFF1F5F9)),
              _buildServiceRow('GIS Vector Map Tile Server', '🟢 Operational',
                  '32ms', true),
              const Divider(height: 18, color: Color(0xFFF1F5F9)),
              _buildServiceRow('Satellite Ortho Pipeline', '🟢 Operational',
                  '310ms', true),
              const Divider(height: 18, color: Color(0xFFF1F5F9)),
              _buildServiceRow('AI Flood Prediction Worker', '🟢 Operational',
                  '140ms', true),
              const Divider(height: 18, color: Color(0xFFF1F5F9)),
              _buildServiceRow('CAP Multi-channel SMS/Push Gateway',
                  '🟢 Operational', '85ms', true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHealthItem(String label, String value, String status) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(
      String title, String desc, Color bgColor, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            desc,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.85),
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceRow(
      String name, String status, String latency, bool isGood) {
    return Row(
      children: [
        Text(
          name,
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F7F0),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            latency,
            style: const TextStyle(
              color: Color(0xFF0E5C38),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          status,
          style: const TextStyle(
            color: Color(0xFF10B981),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // TAB 1: SENSOR & HARDWARE MONITORING
  // ==========================================================================
  Widget _buildSensorHardwareTab() {
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
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
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
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildHardwareStat(
                      '🟢 Online', '248 Nodes', const Color(0xFF10B981)),
                  _buildHardwareStat(
                      '🟠 Warning', '3 Nodes', const Color(0xFFF59E0B)),
                  _buildHardwareStat(
                      '🔴 Offline', '1 Node', const Color(0xFFEF4444)),
                  _buildHardwareStat(
                      '📡 LoRa Packets', '99.2%', const Color(0xFF007AEB)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Deep-dive Selected Node Inspection Card
        Row(
          children: [
            const Icon(Icons.developer_board_rounded,
                color: Color(0xFF7351D8), size: 18),
            const SizedBox(width: 8),
            Text(
              'Node Telemetry Inspector: ${activeNode['id']}',
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 14.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F0F172A),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: (activeNode['color'] as Color).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.router_rounded,
                      color: activeNode['color'] as Color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeNode['name'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '${activeNode['id']} • ${activeNode['location']}',
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          (activeNode['color'] as Color).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: activeNode['color'] as Color),
                    ),
                    child: Text(
                      activeNode['status'] as String,
                      style: TextStyle(
                        color: activeNode['color'] as Color,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: Color(0xFF334155)),

              // Sensor Sub-modules telemetry
              _buildSensorSubRow(
                  '🌊 Ultrasonic Water Level', activeNode['waterLevel'] as String),
              _buildSensorSubRow(
                  '🌧️ Tipping Bucket Rain Gauge', activeNode['rainGauge'] as String),
              _buildSensorSubRow(
                  '💨 Flow Velocity Sensor', activeNode['flowSensor'] as String),
              _buildSensorSubRow(
                  '📐 MEMS Tilt Inclinometer', activeNode['tiltSensor'] as String),
              _buildSensorSubRow('🌱 Volumetric Soil Moisture',
                  activeNode['soilMoisture'] as String),
              const Divider(height: 20, color: Color(0xFF334155)),

              // Telemetry status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '🔋 Battery: ${activeNode['battery']}%',
                      style: const TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '📻 LoRa: ${activeNode['loraRssi']}',
                      style: const TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '⏱️ ${activeNode['lastData']}',
                    style: const TextStyle(
                      color: Color(0xFF4ADE80),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Node Selector List
        Row(
          children: const [
            Icon(Icons.list_alt_rounded, color: Color(0xFF0F172A), size: 18),
            SizedBox(width: 8),
            Text(
              'Select Node for Telemetry Audit',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

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
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            val,
            style: TextStyle(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorSubRow(String sensor, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            sensor,
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            status,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
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

    return GestureDetector(
      onTap: () => setState(() => _selectedNodeId = n['id'] as String),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF3F0FC) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF7351D8) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${n['id']} • ${n['name']}',
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    n['location'] as String,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Batt: ${n['battery']}%',
              style: TextStyle(
                color: n['battery'] < 20
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // TAB 2: SATELLITE & AI ENGINE PIPELINE
  // ==========================================================================
  Widget _buildSatelliteAndAiTab() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(14),
      children: [
        // 1. Satellite Ingest Telemetry Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A0F172A),
                blurRadius: 8,
                offset: Offset(0, 2),
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
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.satellite_alt_rounded,
                      color: Color(0xFF0284C7),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SATELLITE DATA PIPELINE',
                          style: TextStyle(
                            color: Color(0xFF0284C7),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          'Sentinel-1 / Sentinel-2 Feed',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F7F0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'ONLINE 🟢',
                      style: TextStyle(
                        color: Color(0xFF0E5C38),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 22, color: Color(0xFFF1F5F9)),

              _buildPipelineStatusItem(
                  'Data Connection', '🟢 Connected (NRSC / ESA Hub)'),
              _buildPipelineStatusItem(
                  'Latest Imagery', '🟢 SAR Cloud-Penetrating Ingested'),
              _buildPipelineStatusItem(
                  'Ortho Processing', '🟢 Sub-meter Gridding Complete'),
              _buildPipelineStatusItem(
                  'Flood Extent Detection', '🟢 Water Surface Mask Active'),
              _buildPipelineStatusItem(
                  'Change Detection', '🟢 Damodar Basin Masked (+18% Δ)'),
              const Divider(height: 20, color: Color(0xFFF1F5F9)),

              Row(
                children: const [
                  Icon(Icons.schedule_rounded,
                      size: 14, color: Color(0xFF64748B)),
                  SizedBox(width: 6),
                  Text(
                    'Last Update: 10 Sept 2026 • 12:20 PM',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. AI Engine Status Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A0F172A),
                blurRadius: 8,
                offset: Offset(0, 2),
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
                      color: const Color(0xFFF3F0FC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.psychology_rounded,
                      color: Color(0xFF7351D8),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI PREDICTION ENGINE',
                          style: TextStyle(
                            color: Color(0xFF7351D8),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          'JalGuard-Flood-v2.1',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F7F0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'INFERENCE 🟢',
                      style: TextStyle(
                        color: Color(0xFF0E5C38),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 22, color: Color(0xFFF1F5F9)),

              _buildPipelineStatusItem(
                  'Flood Depth Prediction', '🟢 Running (3-hr ahead forecast)'),
              _buildPipelineStatusItem(
                  'GLOF Analysis', '🟢 Running (Upper glacial lakes normal)'),
              _buildPipelineStatusItem(
                  'Landslide Detection', '🟢 Running (Slope instability scan)'),
              _buildPipelineStatusItem(
                  'Risk Classification', '🟢 Running (Triage category matrix)'),
              const Divider(height: 20, color: Color(0xFFF1F5F9)),

              Row(
                children: const [
                  Icon(Icons.bolt_rounded, size: 16, color: Color(0xFF7351D8)),
                  SizedBox(width: 4),
                  Text(
                    'Last Prediction Run: 32 sec ago (0 pipeline errors)',
                    style: TextStyle(
                      color: Color(0xFF7351D8),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPipelineStatusItem(String label, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            status,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 3: ALERTS DELIVERY & SYSTEM LOGS
  // ==========================================================================
  Widget _buildAlertsAndLogsTab() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(14),
      children: [
        // Notification System Delivery Stats
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.send_and_archive_rounded,
                      color: Color(0xFF7351D8), size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Multi-Channel Alert Delivery Telemetry',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$_alertBroadcastCount Sent',
                    style: const TextStyle(
                      color: Color(0xFF7351D8),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const Divider(height: 20, color: Color(0xFFF1F5F9)),

              Row(
                children: [
                  _buildChannelItem('📱 Push', '🟢 OK'),
                  _buildChannelItem('💬 SMS', '🟢 OK'),
                  _buildChannelItem('✉️ Email', '🟢 OK'),
                  _buildChannelItem('🚨 Sirens', '🟢 OK'),
                  _buildChannelItem('🔊 Audio', '🟢 OK'),
                ],
              ),
              const SizedBox(height: 14),

              Row(
                children: const [
                  Text(
                    'Last Flood Warning: Delivered 98.4%',
                    style: TextStyle(
                      color: Color(0xFF0E5C38),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Spacer(),
                  Text(
                    'Failed: 1.6%',
                    style: TextStyle(
                      color: Color(0xFFDC2626),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // System Terminal Logs
        Row(
          children: const [
            Icon(Icons.terminal_rounded, color: Color(0xFF0F172A), size: 18),
            SizedBox(width: 8),
            Text(
              'Live System Audit Logs',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 14.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: _systemLogs.map((log) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log['time'] as String,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color:
                            (log['color'] as Color).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        log['level'] as String,
                        style: TextStyle(
                          color: log['color'] as Color,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        log['message'] as String,
                        style: const TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontSize: 11.5,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildChannelItem(String channel, String status) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Text(
              channel,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              status,
              style: const TextStyle(
                color: Color(0xFF10B981),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // BOTTOM NAVIGATION BAR
  // ==========================================================================
  Widget _buildBottomNavigation() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 0.8)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            _buildNavTab(0, Icons.speed_rounded, 'Overview'),
            _buildNavTab(1, Icons.sensors_rounded, 'Sensors (248)'),
            _buildNavTab(2, Icons.satellite_alt_rounded, 'Satellite & AI'),
            _buildNavTab(3, Icons.list_alt_rounded, 'Alerts & Logs'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTab(int index, IconData icon, String label) {
    final bool isSelected = _selectedTabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected
                    ? const Color(0xFF7351D8)
                    : const Color(0xFF94A3B8),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF7351D8)
                      : const Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
