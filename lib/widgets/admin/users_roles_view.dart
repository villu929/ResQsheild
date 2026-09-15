import 'package:flutter/material.dart';

class UsersRolesView extends StatelessWidget {
  const UsersRolesView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(14),
      children: [
        const Text(
          'Users & Roles Management',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 16),
        _buildRoleCard('System Admin', 'Full Access', '3 Users', const Color(0xFF6366F1), ['All Permissions']),
        _buildRoleCard('Authority', 'Command & Control', '12 Users', const Color(0xFF0284C7), ['Escalation', 'Evacuation', 'CAP']),
        _buildRoleCard('Technical Admin', 'Hardware & Sensors', '5 Users', const Color(0xFFD97706), ['Calibration', 'Diagnostics']),
        _buildRoleCard('Field Responder', 'Ground Operations', '48 Users', const Color(0xFF059669), ['Reporting', 'Shelters']),
      ],
    );
  }

  Widget _buildRoleCard(String title, String subtitle, String userCount, Color color, List<String> permissions) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x050F172A), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.shield, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(userCount, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155))),
              const SizedBox(height: 4),
              Row(
                children: permissions.map((p) => Container(
                  margin: const EdgeInsets.only(left: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                  child: Text(p, style: const TextStyle(fontSize: 10, color: Color(0xFF475569))),
                )).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
