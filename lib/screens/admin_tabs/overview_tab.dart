import 'package:flutter/material.dart';
import '../../widgets/admin/shared_admin_widgets.dart';

class OverviewTab extends StatelessWidget {
  const OverviewTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(14),
      children: [
        // 1. System Health Master Banner
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x330F172A),
                  blurRadius: 16,
                  offset: Offset(0, 6),
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
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.hub_rounded,
                        color: Color(0xFF4ADE80),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
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
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const AnimatedStatusChip(
                      label: 'NORMAL',
                      color: Color(0xFF4ADE80),
                      icon: Icons.circle,
                    ),
                  ],
                ),
                const Divider(height: 28, color: Color(0xFF334155)),
                Row(
                  children: const [
                    AnimatedKPIBox(
                      label: '📡 Sensors',
                      value: '248 / 252',
                      status: 'OK',
                      statusColor: Color(0xFF10B981),
                    ),
                    AnimatedKPIBox(
                      label: '🛰️ Satellite',
                      value: 'Sync Active',
                      status: 'OK',
                      statusColor: Color(0xFF10B981),
                    ),
                    AnimatedKPIBox(
                      label: '☁️ Backend',
                      value: '42ms Latency',
                      status: 'OK',
                      statusColor: Color(0xFF10B981),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    AnimatedKPIBox(
                      label: '🤖 AI Engine',
                      value: 'v2.1 Running',
                      status: 'OK',
                      statusColor: Color(0xFF10B981),
                    ),
                    AnimatedKPIBox(
                      label: '📱 Alerts',
                      value: '98.4% Delivered',
                      status: 'OK',
                      statusColor: Color(0xFF10B981),
                    ),
                    AnimatedKPIBox(
                      label: '🗄️ Database',
                      value: 'Replica Synced',
                      status: 'OK',
                      statusColor: Color(0xFF10B981),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Last Sync: Just now',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // 2. Alerts Box
        const SectionHeader(
          icon: Icons.notifications_active_rounded,
          title: 'Active System Alerts & Diagnostics',
          iconColor: Color(0xFFF59E0B),
        ),
        const SizedBox(height: 12),

        const AlertCard(
          title: 'Hardware Node JG-003 Offline',
          description: '3 consecutive packets dropped • Solar battery empty • Field tech dispatched',
          baseColor: Color(0xFFDC2626),
          icon: Icons.error_rounded,
        ),
        const AlertCard(
          title: 'Sensor Node JG-021 Low Voltage',
          description: 'Battery at 18% • River gauge operating on backup capacitor',
          baseColor: Color(0xFFD97706),
          icon: Icons.warning_rounded,
        ),
        const AlertCard(
          title: 'Satellite Processing Queue Delayed',
          description: 'Sentinel-2 multispectral tile ingest delayed by 4 minutes (Cloud API queue)',
          baseColor: Color(0xFFD97706),
          icon: Icons.warning_rounded,
        ),
        const AlertCard(
          title: 'Automated Database Snapshot Completed',
          description: 'Hourly hot backup synced to encrypted offsite disaster vault',
          baseColor: Color(0xFF0E5C38),
          icon: Icons.check_circle_rounded,
        ),
        const SizedBox(height: 20),

        // 3. Microservices Grid
        const SectionHeader(
          icon: Icons.dns_rounded,
          title: 'Microservices & Pipeline Health',
          iconColor: Color(0xFF7351D8),
        ),
        const SizedBox(height: 12),

        Container(
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
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _services.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
            itemBuilder: (context, index) {
              final service = _services[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: Text(
                  service['name']!,
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F7F0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        service['latency']!,
                        style: const TextStyle(
                          color: Color(0xFF0E5C38),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Operational',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  static const _services = [
    {'name': 'REST & GraphQL API Gateway', 'latency': '18ms'},
    {'name': 'TimescaleDB Telemetry Store', 'latency': '12ms'},
    {'name': 'MFA & Role Auth Cluster', 'latency': '24ms'},
    {'name': 'GIS Vector Map Tile Server', 'latency': '32ms'},
    {'name': 'Satellite Ortho Pipeline', 'latency': '310ms'},
    {'name': 'AI Flood Prediction Worker', 'latency': '140ms'},
    {'name': 'CAP Multi-channel SMS/Push Gateway', 'latency': '85ms'},
  ];
}
