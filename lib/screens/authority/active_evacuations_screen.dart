import 'package:flutter/material.dart';

class ActiveEvacuationsScreen extends StatelessWidget {
  const ActiveEvacuationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dummy Data for active evacuations
    final List<Map<String, dynamic>> activeEvacuations = [
      {
        'area': 'Sector A',
        'team': 'Team Alpha',
        'evacuated': 1903,
        'target': 2840,
        'status': 'Critical - Low Progress',
        'statusColor': Colors.red,
        'upTrend': '+12%',
        'downTrend': '-8%',
        'sectors': '3 / 5',
      },
      {
        'area': 'Sector B, Delhi',
        'team': 'Team Bravo',
        'evacuated': 850,
        'target': 1000,
        'status': 'Near Completion',
        'statusColor': Colors.orange,
        'upTrend': '+5%',
        'downTrend': '-12%',
        'sectors': '4 / 5',
      },
      {
        'area': 'Bandra West, Coastal Line',
        'team': 'Team Charlie',
        'evacuated': 1200,
        'target': 1200,
        'status': 'Completed',
        'statusColor': Colors.green,
        'upTrend': '+0%',
        'downTrend': '-100%',
        'sectors': '5 / 5',
      },
      {
        'area': 'Narela Sector 5',
        'team': 'Team Delta',
        'evacuated': 320,
        'target': 1500,
        'status': 'Critical - Low Progress',
        'statusColor': Colors.red,
        'upTrend': '+2%',
        'downTrend': '-1%',
        'sectors': '1 / 6',
      },
      {
        'area': 'Rohini Sector 7',
        'team': 'Team Echo',
        'evacuated': 950,
        'target': 1500,
        'status': 'In Progress',
        'statusColor': Colors.blue,
        'upTrend': '+8%',
        'downTrend': '-4%',
        'sectors': '2 / 4',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: const Text(
          'Active Evacuations',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                'Total: ${activeEvacuations.fold(0, (sum, item) => sum + (item['target'] as int))}',
                style: const TextStyle(
                  color: Color(0xFF1E3A8A),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          )
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: activeEvacuations.length,
        itemBuilder: (context, index) {
          final data = activeEvacuations[index];
          final int evacuated = data['evacuated'];
          final int target = data['target'];
          final int remaining = target - evacuated;
          final double progress = target > 0 ? evacuated / target : 0.0;
          final int progressPct = (progress * 100).toInt();

          bool isHighPriority = data['status'] == 'Critical - Low Progress';

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE0F2FE), // Light blue background
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.groups_rounded, color: Color(0xFF0284C7), size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EVACUATION MANAGEMENT (${data['area'].toUpperCase()})',
                            style: const TextStyle(
                              color: Color(0xFF1E293B),
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Overall progress of evacuation and relief operations',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isHighPriority)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2), // Light red
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.notifications_active, color: Color(0xFFDC2626), size: 12),
                            SizedBox(width: 4),
                            Text(
                              'HIGH PRIORITY',
                              style: TextStyle(
                                color: Color(0xFFDC2626),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: data['statusColor'].withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: data['statusColor'].withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(progress == 1.0 ? Icons.check_circle : Icons.loop, color: data['statusColor'], size: 12),
                            const SizedBox(width: 4),
                            Text(
                              data['status'].toUpperCase(),
                              style: TextStyle(
                                color: data['statusColor'],
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // 2. Progress Text Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$progressPct% Evacuated',
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_formatNumber(evacuated)} / ${_formatNumber(target)}',
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Remaining: ${_formatNumber(remaining)}',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 3. Progress Bar
                Container(
                  height: 8,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9), // Light grey
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7), // Bright blue
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Grid of 4 Metric Cards
                Row(
                  children: [
                    // Card 1: People Evacuated
                    Expanded(
                      child: _buildMetricCard(
                        title: 'People Evacuated',
                        value: _formatNumber(evacuated),
                        icon: Icons.group_add_rounded,
                        iconColor: const Color(0xFF16A34A),
                        bgIconColor: const Color(0xFFDCFCE7),
                        bottomWidget: Row(
                          children: [
                            const Icon(Icons.arrow_upward, size: 10, color: Color(0xFF16A34A)),
                            const SizedBox(width: 2),
                            Text('${data['upTrend']} from last hour', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF16A34A))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // Card 2: People Remaining
                    Expanded(
                      child: _buildMetricCard(
                        title: 'People Remaining',
                        value: _formatNumber(remaining),
                        icon: Icons.person_remove_alt_1_rounded,
                        iconColor: const Color(0xFFEA580C), // Orange
                        bgIconColor: const Color(0xFFFFEDD5),
                        bottomWidget: Row(
                          children: [
                            const Icon(Icons.arrow_downward, size: 10, color: Color(0xFFEA580C)),
                            const SizedBox(width: 2),
                            Text('${data['downTrend']} from last hour', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFFEA580C))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // Card 3: Total Capacity
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Total Capacity',
                        value: _formatNumber(target),
                        icon: Icons.flag_rounded,
                        iconColor: const Color(0xFF7E22CE), // Purple
                        bgIconColor: const Color(0xFFF3E8FF),
                        bottomWidget: null, // Empty for this one based on image
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // Card 4: Sectors Covered
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Sectors Covered',
                        value: data['sectors'],
                        icon: Icons.domain_rounded,
                        iconColor: const Color(0xFF2563EB), // Blue
                        bgIconColor: const Color(0xFFDBEAFE),
                        bottomWidget: Text(
                          '${data['area']} - ${data['status'] == 'Completed' ? 'Completed' : 'In Progress'}',
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color bgIconColor,
    Widget? bottomWidget,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: bgIconColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 12, color: iconColor),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B), // Grey text
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Value
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          if (bottomWidget != null) ...[
            const SizedBox(height: 4),
            bottomWidget,
          ]
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    // Basic comma formatting for thousands
    return number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }
}
