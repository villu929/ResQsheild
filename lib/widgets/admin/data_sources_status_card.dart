import 'package:flutter/material.dart';

class DataSourcesStatusCard extends StatelessWidget {
  const DataSourcesStatusCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x050F172A), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.hub, color: Color(0xFF6366F1), size: 22),
              SizedBox(width: 8),
              Text('Data Sources Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 16),
          _buildSourceRow('IMD (Meteorological)', 'ONLINE', const Color(0xFF10B981), '42ms', '2 mins ago'),
          _buildSourceRow('GPM (Rainfall)', 'ONLINE', const Color(0xFF10B981), '120ms', '15 mins ago'),
          _buildSourceRow('CWC (River Gauges)', 'WARNING', const Color(0xFFF59E0B), '800ms', '2 hrs ago (Delayed)'),
          _buildSourceRow('Sentinel-1 SAR', 'ONLINE', const Color(0xFF10B981), '85ms', '1 day ago'),
          _buildSourceRow('Radar (Doppler)', 'OFFLINE', const Color(0xFFEF4444), 'Timeout', 'Yesterday'),
        ],
      ),
    );
  }

  Widget _buildSourceRow(String name, String status, Color statusColor, String latency, String lastSync) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(flex: 3, child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF334155)))),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(Icons.circle, size: 10, color: statusColor),
                const SizedBox(width: 4),
                Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor)),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(latency, style: const TextStyle(color: Color(0xFF64748B)))),
          Expanded(flex: 3, child: Text(lastSync, textAlign: TextAlign.right, style: const TextStyle(color: Color(0xFF64748B)))),
        ],
      ),
    );
  }
}
