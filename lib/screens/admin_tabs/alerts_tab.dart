import 'package:flutter/material.dart';
import '../../widgets/admin/shared_admin_widgets.dart';

class AlertsTab extends StatelessWidget {
  final int broadcastCount;
  
  const AlertsTab({Key? key, required this.broadcastCount}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(14),
      children: [
        // Notification System Delivery Stats
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F0FC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.send_and_archive_rounded,
                      color: Color(0xFF7351D8),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Multi-Channel Alert Delivery Telemetry',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F0FC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$broadcastCount Sent',
                      style: const TextStyle(
                        color: Color(0xFF7351D8),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 28, color: Color(0xFFF1F5F9)),

              Row(
                children: [
                  _buildChannelItem('📱 Push', '99.8%', const Color(0xFF10B981)),
                  _buildChannelItem('💬 SMS', '97.2%', const Color(0xFF10B981)),
                  _buildChannelItem('✉️ Email', '99.9%', const Color(0xFF10B981)),
                  _buildChannelItem('🚨 Sirens', '100%', const Color(0xFF10B981)),
                  _buildChannelItem('🔊 Audio', '95.5%', const Color(0xFFF59E0B)),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F7F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.check_circle_rounded, color: Color(0xFF0E5C38), size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Overall Success: 98.4%',
                            style: TextStyle(
                              color: Color(0xFF0E5C38),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Failed: 1.6%',
                          style: TextStyle(
                            color: Color(0xFFDC2626),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // System Terminal Logs
        const SectionHeader(
          icon: Icons.terminal_rounded,
          title: 'Live System Audit Logs',
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
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
            children: _systemLogs.map((log) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log['time'] as String,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11.5,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 50,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: (log['color'] as Color).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: (log['color'] as Color).withValues(alpha: 0.3)),
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        log['message'] as String,
                        style: const TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontSize: 12.5,
                          height: 1.4,
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

  Widget _buildChannelItem(String channel, String stat, Color statColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Text(
              channel,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              stat,
              style: TextStyle(
                color: statColor,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const List<Map<String, dynamic>> _systemLogs = [
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
}
