import 'package:flutter/material.dart';

class ModelRegistryCard extends StatelessWidget {
  const ModelRegistryCard({Key? key}) : super(key: key);

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
              Icon(Icons.psychology, color: Color(0xFF6366F1), size: 22),
              SizedBox(width: 8),
              Text('Model Registry & Monitoring', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 16),
          _buildModelRow('SAR Change Detection', 'v2.1', 'DEPLOYED', const Color(0xFF10B981), '140ms', 'Nominal'),
          _buildModelRow('Hydrological Routing', 'v1.4', 'DEPLOYED', const Color(0xFF10B981), '350ms', 'Nominal'),
          _buildModelRow('Precipitation Nowcast', 'v3.0-rc1', 'SHADOW', const Color(0xFFF59E0B), '80ms', 'Drift Watch (12%)'),
          _buildModelRow('Damage Assessment', 'v1.0', 'DEPLOYED', const Color(0xFF10B981), '890ms', 'Nominal'),
        ],
      ),
    );
  }

  Widget _buildModelRow(String name, String version, String status, Color statusColor, String latency, String drift) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                Text(version, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
              child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
            ),
          ),
          Expanded(flex: 2, child: Text(latency, style: const TextStyle(color: Color(0xFF64748B)))),
          Expanded(
            flex: 2,
            child: Text(drift, textAlign: TextAlign.right, style: TextStyle(color: drift.contains('Drift') ? const Color(0xFFF59E0B) : const Color(0xFF64748B))),
          ),
        ],
      ),
    );
  }
}
