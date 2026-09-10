import 'package:flutter/material.dart';

class RainfallDetailScreen extends StatelessWidget {
  const RainfallDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF061A2B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF092238),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Rainfall & Weather',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF38BDF8), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.cloud_queue_rounded, color: Color(0xFF38BDF8), size: 14),
                SizedBox(width: 4),
                Text(
                  'HEAVY RAIN',
                  style: TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Card with Rainfall Graphic
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  Image.asset(
                    'assets/images/screen_bg_1.png',
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.2),
                          const Color(0xFF061A2B).withOpacity(0.85),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Accumulated Rainfall',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: const [
                                Text(
                                  '128',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 42,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'mm',
                                  style: TextStyle(
                                    color: Color(0xFF38BDF8),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF38BDF8).withOpacity(0.25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Past 6 Hours (Torrential)',
                                style: TextStyle(
                                  color: Color(0xFF7DD3FC),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Column(
                            children: const [
                              Text(
                                'Rain Intensity',
                                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '24 mm/h',
                                style: TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Rainfall Metrics Row
            Row(
              children: [
                _buildMetricTile('Last 1 Hr', '28 mm', Icons.timer_outlined, const Color(0xFF38BDF8)),
                const SizedBox(width: 12),
                _buildMetricTile('Expected 24h', '190 mm', Icons.umbrella_rounded, const Color(0xFF818CF8)),
                const SizedBox(width: 12),
                _buildMetricTile('Flood Risk', 'Very High', Icons.warning_amber_rounded, const Color(0xFFEF4444)),
              ],
            ),

            const SizedBox(height: 24),

            // Hourly Rain Forecast
            const Text(
              'Hourly Rainfall Forecast',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0B243B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1B3D60)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildHourlyBar('1 PM', '24 mm', 0.8, const Color(0xFFEF4444)),
                  _buildHourlyBar('2 PM', '30 mm', 1.0, const Color(0xFFEF4444)),
                  _buildHourlyBar('3 PM', '22 mm', 0.72, const Color(0xFFF59E0B)),
                  _buildHourlyBar('4 PM', '18 mm', 0.58, const Color(0xFFF59E0B)),
                  _buildHourlyBar('5 PM', '12 mm', 0.4, const Color(0xFF38BDF8)),
                  _buildHourlyBar('6 PM', '6 mm', 0.22, const Color(0xFF10B981)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Precaution Alert
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.report_problem_rounded, color: Color(0xFFEF4444), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Flash Flood & Waterlogging Warning',
                          style: TextStyle(
                            color: Color(0xFFF87171),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Low-lying areas are prone to sudden water rise within the next 2-4 hours. Keep emergency kits ready and avoid underpasses.',
                          style: TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0B243B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyBar(String time, String mm, double fraction, Color barColor) {
    return Column(
      children: [
        Text(mm, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          height: 60,
          width: 16,
          alignment: Alignment.bottomCenter,
          decoration: BoxDecoration(
            color: const Color(0xFF092033),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Container(
            height: 60 * fraction,
            width: 16,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(time, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
      ],
    );
  }
}
