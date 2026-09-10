import 'package:flutter/material.dart';

class TrendsForecastScreen extends StatefulWidget {
  const TrendsForecastScreen({super.key});

  @override
  State<TrendsForecastScreen> createState() => _TrendsForecastScreenState();
}

class _TrendsForecastScreenState extends State<TrendsForecastScreen> {
  String _timeWindow = '24h'; // '24h', '48h', '72h'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF013973)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'TRENDS & HYDRO FORECAST',
              style: TextStyle(
                color: Color(0xFF013973),
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              'Hydrological Sensors, Inundation Models & Predictions',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: ['24h', '48h', '72h'].map((w) {
                final isSel = _timeWindow == w;
                return GestureDetector(
                  onTap: () => setState(() => _timeWindow = w),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFF007AEB) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      w,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isSel ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. RAINFALL GRAPH SECTION
            _buildChartCard(
              title: 'PRECIPITATION HYETOGRAPH ($timeWindow + FORECAST)',
              subtitle: 'Accumulated: 184 mm • Forecast: +65 mm peak in next 6h',
              icon: Icons.cloud_download_rounded,
              iconColor: const Color(0xFF0284C7),
              child: _buildRainfallGraph(),
            ),

            const SizedBox(height: 16),

            // 2. RIVER & DAM WATER LEVEL GRAPH
            _buildChartCard(
              title: 'RIVER & DAM WATER LEVEL TREND ($timeWindow)',
              subtitle: 'Current: 8.4m • Danger Mark: 7.2m (Rising +14 cm/hr)',
              icon: Icons.water_rounded,
              iconColor: const Color(0xFFDC2626),
              child: _buildRiverLevelGraph(),
            ),

            const SizedBox(height: 16),

            // 3. VILLAGE RISK SCORE TREND (RISING / FALLING)
            _buildChartCard(
              title: 'VILLAGE RISK DYNAMICS & SCORE PROJECTION',
              subtitle: 'Automated 24h AI hydrodynamic risk trajectory',
              icon: Icons.trending_up_rounded,
              iconColor: const Color(0xFFEA580C),
              child: _buildVillageRiskDynamics(),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String get timeWindow => _timeWindow;

  Widget _buildChartCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5, color: Color(0xFF0F172A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  // Simulated Custom Rainfall Chart
  Widget _buildRainfallGraph() {
    final rainPoints = [
      {'time': '-18h', 'mm': 12.0, 'forecast': false},
      {'time': '-12h', 'mm': 28.0, 'forecast': false},
      {'time': '-6h', 'mm': 46.0, 'forecast': false},
      {'time': 'Now', 'mm': 64.0, 'forecast': false},
      {'time': '+6h', 'mm': 52.0, 'forecast': true},
      {'time': '+12h', 'mm': 30.0, 'forecast': true},
      {'time': '+18h', 'mm': 14.0, 'forecast': true},
    ];

    return Column(
      children: [
        SizedBox(
          height: 130,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: rainPoints.map((pt) {
              final val = pt['mm'] as double;
              final isForecast = pt['forecast'] as bool;
              final height = (val / 70.0 * 100).clamp(10.0, 100.0);

              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${val.toInt()}mm',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: isForecast ? const Color(0xFF0284C7) : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 28,
                    height: height,
                    decoration: BoxDecoration(
                      color: isForecast
                          ? const Color(0xFF38BDF8).withValues(alpha: 0.6)
                          : const Color(0xFF0284C7),
                      borderRadius: BorderRadius.circular(6),
                      border: isForecast ? Border.all(color: const Color(0xFF0284C7), style: BorderStyle.solid) : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    pt['time'] as String,
                    style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: const Color(0xFF0284C7), borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 4),
            const Text('Observed Radar Rain', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
            const SizedBox(width: 14),
            Container(width: 10, height: 10, decoration: BoxDecoration(color: const Color(0xFF38BDF8).withValues(alpha: 0.6), borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 4),
            const Text('WRF AI Forecast (+18h)', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
          ],
        ),
      ],
    );
  }

  // Simulated River & Dam Level Trend
  Widget _buildRiverLevelGraph() {
    final levels = [
      {'t': '-18h', 'm': 5.2},
      {'t': '-12h', 'm': 6.0},
      {'t': '-6h', 'm': 7.1},
      {'t': 'Now', 'm': 8.4},
      {'t': '+6h', 'm': 8.9},
      {'t': '+12h', 'm': 8.1},
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(width: 14, height: 2, color: const Color(0xFFDC2626)),
              const SizedBox(width: 6),
              const Text('Danger Threshold: 7.20 m (BREACHED)', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFFDC2626))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: levels.map((l) {
              final m = l['m'] as double;
              final isDanger = m >= 7.2;

              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDanger ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${m}m',
                      style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isDanger ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(l['t'] as String, style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Simulated Village Risk Dynamics
  Widget _buildVillageRiskDynamics() {
    final list = [
      {
        'name': 'Aluva Riverside',
        'score': '94',
        'delta': '+18% last 12h',
        'isRising': true,
        'status': 'HIGH INUNDATION PROJECTION',
        'color': const Color(0xFFDC2626),
      },
      {
        'name': 'Paravur Lowlands',
        'score': '88',
        'delta': '+12% last 12h',
        'isRising': true,
        'status': 'RISING CREST EXPANSION',
        'color': const Color(0xFFEA580C),
      },
      {
        'name': 'Chalakudy West',
        'score': '82',
        'delta': '+8% last 12h',
        'isRising': true,
        'status': 'STABILIZING HIGH',
        'color': const Color(0xFFEA580C),
      },
      {
        'name': 'Thodupuzha Riverbank',
        'score': '52',
        'delta': '-14% last 12h',
        'isRising': false,
        'status': 'RECEDING DRAINAGE OK',
        'color': const Color(0xFF16A34A),
      },
      {
        'name': 'Perumbavoor East',
        'score': '22',
        'delta': '-6% last 12h',
        'isRising': false,
        'status': 'SAFE NORMAL ELEVATION',
        'color': const Color(0xFF16A34A),
      },
    ];

    return Column(
      children: list.map((item) {
        final isRising = item['isRising'] as bool;
        final color = item['color'] as Color;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Icon(
                  isRising ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  color: isRising ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['name'] as String, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF0F172A))),
                      Text(item['status'] as String, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: color)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Index: ${item['score']}/100', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color)),
                    Text(item['delta'] as String, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: isRising ? const Color(0xFFDC2626) : const Color(0xFF16A34A))),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
