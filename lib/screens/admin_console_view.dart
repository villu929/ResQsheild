import 'package:flutter/material.dart';

class AdminConsoleView extends StatefulWidget {
  const AdminConsoleView({super.key});

  @override
  State<AdminConsoleView> createState() => _AdminConsoleViewState();
}

class _AdminConsoleViewState extends State<AdminConsoleView> {
  bool _maintenanceMode = false;
  bool _meshRelayActive = true;
  int _alertBroadcastCount = 6;

  final List<Map<String, dynamic>> _systemLogs = [
    {
      'time': '14:04:12',
      'level': 'INFO',
      'source': 'CWC Gauge Feed',
      'message': 'River Damodar at Tenughat Dam: Inflow 14,200 cusecs (Normal)',
      'color': Color(0xFF15945C),
    },
    {
      'time': '13:58:05',
      'level': 'WARN',
      'source': 'IMD Doppler Radar',
      'message': 'Heavy rainfall cell detected over Bokaro Sector 4 (+45mm/hr)',
      'color': Color(0xFFF39A20),
    },
    {
      'time': '13:42:30',
      'level': 'SUCCESS',
      'source': 'CAP SMS Gateway',
      'message': '12,850 SMS alerts successfully routed through NIC gateway',
      'color': Color(0xFF007AEB),
    },
    {
      'time': '13:30:19',
      'level': 'SYS',
      'source': 'Mesh Node #03',
      'message': 'LoRa Tactical Relay synchronized with Field Unit 09',
      'color': Color(0xFF7351D8),
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

  void _showBroadcastDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: const [
            Icon(Icons.warning_rounded, color: Color(0xFFE92828)),
            SizedBox(width: 8),
            Text(
              'CAP Emergency Broadcast',
              style: TextStyle(
                color: Color(0xFF013973),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: const Text(
          'This triggers a priority Common Alerting Protocol (CAP) warning across all active Citizen and Field Responder devices in the selected basin.',
          style: TextStyle(color: Color(0xFF537392), fontSize: 13),
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
              _showMessage('CAP Priority Broadcast dispatched to 42,000 citizens');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE92828),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Confirm Broadcast'),
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
              'Technical & Admin Console',
              style: TextStyle(
                color: Color(0xFF013973),
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              'System Administration • Telemetry & Core Infrastructure',
              style: TextStyle(
                color: Color(0xFF537392),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          // System Health Indicator
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF8F0),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF15945C)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF15945C),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'ALL NOMINAL',
                    style: TextStyle(
                      color: Color(0xFF15945C),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
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
            // 1. Telemetry Services Health Grid
            const Text(
              'INGESTION & SENSOR TELEMETRY',
              style: TextStyle(
                color: Color(0xFF013973),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            _buildTelemetryGrid(),

            const SizedBox(height: 20),

            // 2. Administrator Quick Actions
            const Text(
              'ADMIN CONTROLS & OVERRIDES',
              style: TextStyle(
                color: Color(0xFF013973),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            _buildAdminControls(),

            const SizedBox(height: 20),

            // 3. Server Nodes Status
            const Text(
              'DISASTER CLUSTER NODES',
              style: TextStyle(
                color: Color(0xFF013973),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            _buildClusterNodes(),

            const SizedBox(height: 20),

            // 4. Live Audit Log Stream
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'REAL-TIME AUDIT LOGS',
                  style: TextStyle(
                    color: Color(0xFF013973),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                TextButton(
                  onPressed: () => _showMessage('Exporting CSV audit trail...'),
                  child: const Text(
                    'Export Logs',
                    style: TextStyle(
                      color: Color(0xFF007AEB),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            _buildAuditLogs(),

            const SizedBox(height: 24),

            // 5. Return / Switch Role Button
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
  // TELEMETRY SERVICES GRID
  // --------------------------------------------------------------------------
  Widget _buildTelemetryGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _telemetryServiceCard(
                name: 'CWC River Gauges',
                metric: '48 / 48 Active',
                status: '99.9% Sync',
                icon: Icons.water_rounded,
                color: const Color(0xFF007AEB),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _telemetryServiceCard(
                name: 'IMD Doppler Radar',
                metric: 'Latency: 38ms',
                status: 'Live Raster Feed',
                icon: Icons.radar_rounded,
                color: const Color(0xFF15945C),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _telemetryServiceCard(
                name: 'CAP Broadcast Gateway',
                metric: '$_alertBroadcastCount Alerts Sent',
                status: 'NIC Tier-1 Ready',
                icon: Icons.cell_tower_rounded,
                color: const Color(0xFF7351D8),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _telemetryServiceCard(
                name: 'GIS Offline Map Tiles',
                metric: '2.4 GB Cached',
                status: 'Local Vector Mirror',
                icon: Icons.map_rounded,
                color: const Color(0xFFF39A20),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _telemetryServiceCard({
    required String name,
    required String metric,
    required String status,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
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
              Icon(icon, color: color, size: 22),
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF15945C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              color: Color(0xFF013973),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            metric,
            style: const TextStyle(
              color: Color(0xFF0F2642),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            status,
            style: const TextStyle(
              color: Color(0xFF537392),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // ADMIN CONTROLS
  // --------------------------------------------------------------------------
  Widget _buildAdminControls() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD6E8F7)),
      ),
      child: Column(
        children: [
          _controlTile(
            title: 'Trigger Emergency CAP Broadcast',
            subtitle: 'Dispatch sirens & high-priority push notifications',
            icon: Icons.campaign_rounded,
            iconColor: const Color(0xFFE92828),
            trailing: ElevatedButton(
              onPressed: _showBroadcastDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE92828),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Broadcast', style: TextStyle(fontSize: 11)),
            ),
          ),
          const Divider(height: 20, color: Color(0xFFE5E9EE)),
          _controlTile(
            title: 'LoRa Mesh Relay Routing',
            subtitle: 'Enable zero-internet peer hopping for field tablets',
            icon: Icons.router_rounded,
            iconColor: const Color(0xFF007AEB),
            trailing: Switch(
              value: _meshRelayActive,
              activeThumbColor: const Color(0xFF007AEB),
              activeTrackColor: const Color(0xFFBEDCF5),
              onChanged: (val) {
                setState(() => _meshRelayActive = val);
                _showMessage(_meshRelayActive ? 'LoRa mesh repeater enabled' : 'LoRa mesh repeater disabled');
              },
            ),
          ),
          const Divider(height: 20, color: Color(0xFFE5E9EE)),
          _controlTile(
            title: 'Public Portal Maintenance Mode',
            subtitle: 'Temporarily pause non-critical public submissions',
            icon: Icons.lock_clock_rounded,
            iconColor: const Color(0xFF7351D8),
            trailing: Switch(
              value: _maintenanceMode,
              activeThumbColor: const Color(0xFF7351D8),
              activeTrackColor: const Color(0xFFE3D9F8),
              onChanged: (val) {
                setState(() => _maintenanceMode = val);
                _showMessage(_maintenanceMode ? 'Maintenance mode enabled for public users' : 'Maintenance mode disabled');
              },
            ),
          ),
          const Divider(height: 20, color: Color(0xFFE5E9EE)),
          _controlTile(
            title: 'Purge GIS Map Cache',
            subtitle: 'Re-fetch latest bathymetry & flood inundation contours',
            icon: Icons.cleaning_services_rounded,
            iconColor: const Color(0xFFF39A20),
            trailing: OutlinedButton(
              onPressed: () => _showMessage('GIS Cache purged & shapefiles reloaded'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF013973),
                side: const BorderSide(color: Color(0xFFD6E8F7)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              child: const Text('Flush Cache', style: TextStyle(fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Widget trailing,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: iconColor.withValues(alpha: 0.12),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF013973),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF537392), fontSize: 11),
              ),
            ],
          ),
        ),
        trailing,
      ],
    );
  }

  // --------------------------------------------------------------------------
  // CLUSTER NODES
  // --------------------------------------------------------------------------
  Widget _buildClusterNodes() {
    return Column(
      children: [
        _nodeCard('Primary Node: resq-cluster-delhi.gov.in', 'CPU: 22% • RAM: 5.1 GB', 'HEALTHY', const Color(0xFF15945C)),
        const SizedBox(height: 8),
        _nodeCard('Edge Relay: resq-edge-jharkhand.nic.in', 'CPU: 14% • LoRa Hub: Active', 'ONLINE', const Color(0xFF007AEB)),
      ],
    );
  }

  Widget _nodeCard(String node, String metrics, String status, Color statusColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD6E8F7)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                node,
                style: const TextStyle(
                  color: Color(0xFF013973),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                metrics,
                style: const TextStyle(color: Color(0xFF537392), fontSize: 10),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // AUDIT LOGS
  // --------------------------------------------------------------------------
  Widget _buildAuditLogs() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD6E8F7)),
      ),
      child: Column(
        children: _systemLogs.map((log) {
          final Color col = log['color'] as Color;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log['time'],
                  style: const TextStyle(
                    color: Color(0xFF537392),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: col.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    log['level'],
                    style: TextStyle(color: col, fontSize: 9, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    log['message'],
                    style: const TextStyle(
                      color: Color(0xFF0F2642),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
