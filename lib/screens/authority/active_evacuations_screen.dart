import 'package:flutter/material.dart';

class ActiveEvacuationsScreen extends StatelessWidget {
  const ActiveEvacuationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dummy Data for active evacuations
    final List<Map<String, dynamic>> activeEvacuations = [
      {
        'area': 'Sector A, Andheri East',
        'team': 'Team Alpha',
        'evacuated': 500,
        'target': 800,
        'status': 'In Progress',
        'statusColor': Colors.blue,
      },
      {
        'area': 'Karala Main Road, Delhi',
        'team': 'Team Bravo',
        'evacuated': 850,
        'target': 1000,
        'status': 'Near Completion',
        'statusColor': Colors.orange,
      },
      {
        'area': 'Bandra West, Coastal Line',
        'team': 'Team Charlie',
        'evacuated': 1200,
        'target': 1200,
        'status': 'Completed',
        'statusColor': Colors.green,
      },
      {
        'area': 'Narela Sector 5',
        'team': 'Team Delta',
        'evacuated': 320,
        'target': 1500,
        'status': 'Critical - Low Progress',
        'statusColor': Colors.red,
      },
      {
        'area': 'Rohini Sector 7',
        'team': 'Team Echo',
        'evacuated': 950,
        'target': 1500,
        'status': 'In Progress',
        'statusColor': Colors.blue,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Light background like other authority screens
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
            child: const Center(
              child: Text(
                'Total: 3,820',
                style: TextStyle(
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
          final double progress = data['evacuated'] / data['target'];
          
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['area'],
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.group_work_rounded, size: 16, color: Color(0xFF64748B)),
                                const SizedBox(width: 6),
                                Text(
                                  data['team'],
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: data['statusColor'].withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: data['statusColor'].withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          data['status'],
                          style: TextStyle(
                            color: data['statusColor'],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: TextStyle(
                          color: const Color(0xFF475569),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${data['evacuated']} / ${data['target']} Evacuated',
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress == 1.0 ? Colors.green : const Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
