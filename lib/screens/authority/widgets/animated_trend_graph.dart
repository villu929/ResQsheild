import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

// ============================================================================
// HELPER FOR SMOOTH MINUTE-BY-MINUTE SPLINE INTERPOLATION
// ============================================================================
double _interpolateSpline(List<double> values, double t) {
  if (t <= 0) return values.first;
  if (t >= values.length - 1) return values.last;
  final i = t.floor();
  final frac = t - i;
  final p0 = i > 0 ? values[i - 1] : values[i];
  final p1 = values[i];
  final p2 = i + 1 < values.length ? values[i + 1] : p1;
  final p3 = i + 2 < values.length ? values[i + 2] : p2;
  // Catmull-Rom cubic interpolation
  final c0 = p1;
  final c1 = 0.5 * (p2 - p0);
  final c2 = p0 - 2.5 * p1 + 2.0 * p2 - 0.5 * p3;
  final c3 = 0.5 * (p3 - p0) + 1.5 * (p1 - p2);
  return c0 + c1 * frac + c2 * frac * frac + c3 * frac * frac * frac;
}

List<FlSpot> _generateMinuteSpots(List<double> values) {
  final spots = <FlSpot>[];
  const totalMinutes = 360; // 6 hours * 60 minutes
  for (int m = 0; m <= totalMinutes; m++) {
    final t = m / 60.0;
    final y = _interpolateSpline(values, t);
    spots.add(FlSpot(t, y));
  }
  return spots;
}

String _formatTimeFromHour(double hourFraction) {
  final totalMinutes = (hourFraction * 60).round().clamp(0, 360);
  final hours = totalMinutes ~/ 60;
  final mins = totalMinutes % 60;
  if (mins == 0) return '${hours}h';
  return '${hours}h ${mins.toString().padLeft(2, '0')}m';
}

// ============================================================================
// RIVER TELEMETRY CARD (Umiam Stn #4)
// ============================================================================
class RiverTelemetryCard extends StatefulWidget {
  const RiverTelemetryCard({super.key});

  @override
  State<RiverTelemetryCard> createState() => _RiverTelemetryCardState();
}

class _RiverTelemetryCardState extends State<RiverTelemetryCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int? _hoverIndex;

  static const List<double> _anchorLevels = [2.70, 3.20, 4.10, 5.00, 5.80, 6.60, 7.42];
  late final List<FlSpot> _allMinuteSpots;

  @override
  void initState() {
    super.initState();
    _allMinuteSpots = _generateMinuteSpots(_anchorLevels);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              const Icon(Icons.waves_rounded, color: Color(0xFF0284C7), size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'RIVER TELEMETRY – Umiam (Stn #4)',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFEE2E2)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_rounded, color: Color(0xFFDC2626), size: 12),
                    SizedBox(width: 4),
                    Text(
                      'Rising rapidly toward danger',
                      style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Synchronized Live Inspection Area
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final animatedSpots = _allMinuteSpots
                  .map((s) => FlSpot(s.x, s.y * _animation.value))
                  .toList();

              final activeIndex = (_hoverIndex ?? (animatedSpots.length - 1)).clamp(0, animatedSpots.length - 1);
              final activeSpot = animatedSpots[activeIndex];
              final isHovering = _hoverIndex != null;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Metrics Bar (syncs with cursor position)
                  Row(
                    children: [
                      _metricColumn(
                        prefixIcon: isHovering
                            ? const Icon(Icons.touch_app_rounded, color: Color(0xFFFF5722), size: 14)
                            : const Icon(Icons.arrow_upward_rounded, color: Color(0xFF16A34A), size: 14),
                        value: '${activeSpot.y.toStringAsFixed(2)} m',
                        label: isHovering ? 'Level @ ${_formatTimeFromHour(activeSpot.x)}' : 'Current Level (6h)',
                        valColor: isHovering ? const Color(0xFFFF5722) : const Color(0xFF0F172A),
                      ),
                      _vDivider(),
                      _metricColumn(
                        value: '8.00 m',
                        label: 'Danger Threshold',
                        valColor: const Color(0xFFDC2626),
                      ),
                      _vDivider(),
                      _metricColumn(
                        value: '+18 cm/hr',
                        label: 'Rate of Rise',
                        valColor: const Color(0xFFDC2626),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Graph with continuous minute-level cursor inspection
                  SizedBox(
                    height: 165,
                    child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: 6.05,
                    minY: 0,
                    maxY: 10.5,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 2.0,
                      getDrawingHorizontalLine: (val) => const FlLine(
                        color: Color(0xFFF1F5F9),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        axisNameWidget: const Text(
                          'Water Level (m)',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5, fontWeight: FontWeight.w600),
                        ),
                        axisNameSize: 18,
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 24,
                          interval: 2.0,
                          getTitlesWidget: (val, meta) => Text(
                            val.toStringAsFixed(1),
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 20,
                          interval: 1.0,
                          getTitlesWidget: (val, meta) {
                            // Only show whole hours on bottom axis
                            if ((val - val.round()).abs() < 0.05) {
                              return Text(
                                '${val.toInt()}h',
                                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    extraLinesData: ExtraLinesData(
                      horizontalLines: [
                        HorizontalLine(
                          y: 8.0,
                          color: const Color(0xFFEF4444),
                          strokeWidth: 1.2,
                          dashArray: [4, 4],
                          label: HorizontalLineLabel(
                            show: true,
                            alignment: Alignment.topLeft,
                            padding: const EdgeInsets.only(left: 4, bottom: 2),
                            style: const TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                            labelResolver: (line) => 'Danger Threshold (8.00 m)',
                          ),
                        ),
                      ],
                    ),
                    showingTooltipIndicators: [
                      ShowingTooltipIndicators([
                        LineBarSpot(
                          LineChartBarData(spots: animatedSpots),
                          0,
                          activeSpot,
                        ),
                      ]),
                    ],
                    lineTouchData: LineTouchData(
                      enabled: true,
                      handleBuiltInTouches: true,
                      touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                        if (touchResponse?.lineBarSpots != null && touchResponse!.lineBarSpots!.isNotEmpty) {
                          final idx = touchResponse.lineBarSpots!.first.spotIndex;
                          if (_hoverIndex != idx) {
                            setState(() {
                              _hoverIndex = idx;
                            });
                          }
                        }
                      },
                      getTouchedSpotIndicator: (barData, spotIndexes) {
                        return spotIndexes.map((i) {
                          return TouchedSpotIndicatorData(
                            const FlLine(
                              color: Color(0xFFFF5722),
                              strokeWidth: 1.5,
                              dashArray: [3, 3],
                            ),
                            FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                                radius: 5.5,
                                color: const Color(0xFFFF5722),
                                strokeWidth: 2.5,
                                strokeColor: Colors.white,
                              ),
                            ),
                          );
                        }).toList();
                      },
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) => const Color(0xFFFF5722),
                        tooltipPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        tooltipBorderRadius: BorderRadius.circular(6),
                        tooltipMargin: 8,
                        fitInsideHorizontally: true,
                        fitInsideVertically: true,
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final timeLabel = _formatTimeFromHour(spot.x);
                            return LineTooltipItem(
                              '$timeLabel: ${spot.y.toStringAsFixed(2)} m',
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: animatedSpots,
                        isCurved: true,
                        curveSmoothness: 0.1,
                        color: const Color(0xFFFF5722),
                        barWidth: 2.5,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          checkToShowDot: (spot, barData) {
                            // Show dots only on whole hours for clean appearance
                            return (spot.x - spot.x.round()).abs() < 0.005;
                          },
                          getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                            radius: 3.5,
                            color: const Color(0xFFFF5722),
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFFFF5722).withValues(alpha: 0.22),
                              const Color(0xFFFF5722).withValues(alpha: 0.01),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ],
  ),
);
}

  Widget _metricColumn({
    Widget? prefixIcon,
    required String value,
    required String label,
    required Color valColor,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (prefixIcon != null) ...[
                prefixIcon,
                const SizedBox(width: 3),
              ],
              Text(
                value,
                style: TextStyle(
                  color: valColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _vDivider() {
    return Container(
      height: 26,
      width: 1,
      color: const Color(0xFFE2E8F0),
      margin: const EdgeInsets.symmetric(horizontal: 10),
    );
  }
}

// ============================================================================
// RAINFALL TELEMETRY CARD (24H)
// ============================================================================
class RainfallTelemetryCard extends StatefulWidget {
  const RainfallTelemetryCard({super.key});

  @override
  State<RainfallTelemetryCard> createState() => _RainfallTelemetryCardState();
}

class _RainfallTelemetryCardState extends State<RainfallTelemetryCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int? _hoverIndex;

  static const List<double> _anchorRainfall = [22, 38, 60, 95, 130, 162, 186];
  late final List<FlSpot> _allMinuteSpots;

  @override
  void initState() {
    super.initState();
    _allMinuteSpots = _generateMinuteSpots(_anchorRainfall);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              const Icon(Icons.water_drop_rounded, color: Color(0xFF0284C7), size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'RAINFALL TELEMETRY (24H)',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline_rounded, color: Color(0xFF0284C7), size: 12),
                    SizedBox(width: 4),
                    Text(
                      'Steady rainfall, high cumulative total',
                      style: TextStyle(
                        color: Color(0xFF0284C7),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Synchronized Live Inspection Area
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final animatedSpots = _allMinuteSpots
                  .map((s) => FlSpot(s.x, s.y * _animation.value))
                  .toList();

              final activeIndex = (_hoverIndex ?? (animatedSpots.length - 1)).clamp(0, animatedSpots.length - 1);
              final activeSpot = animatedSpots[activeIndex];
              final isHovering = _hoverIndex != null;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Metrics Bar (syncs with cursor position)
                  Row(
                    children: [
                      _metricColumn(
                        prefixIcon: isHovering
                            ? const Icon(Icons.touch_app_rounded, color: Color(0xFF0284C7), size: 14)
                            : const Icon(Icons.arrow_upward_rounded, color: Color(0xFF0284C7), size: 14),
                        value: '${activeSpot.y.toInt()} mm',
                        label: isHovering ? 'Rain @ ${_formatTimeFromHour(activeSpot.x)}' : 'Total (24h)',
                        valColor: const Color(0xFF0284C7),
                      ),
                      _vDivider(),
                      _metricColumn(
                        value: '42 mm',
                        label: 'Last 1 Hour',
                        valColor: const Color(0xFF0284C7),
                      ),
                      _vDivider(),
                      _metricColumn(
                        value: '118 mm',
                        label: 'Last 6 Hours',
                        valColor: const Color(0xFF0284C7),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Graph with continuous minute-level cursor inspection
                  SizedBox(
                    height: 165,
                    child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: 6.05,
                    minY: 0,
                    maxY: 250,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 50.0,
                      getDrawingHorizontalLine: (val) => const FlLine(
                        color: Color(0xFFF1F5F9),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        axisNameWidget: const Text(
                          'Rainfall (mm)',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5, fontWeight: FontWeight.w600),
                        ),
                        axisNameSize: 18,
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 26,
                          interval: 50.0,
                          getTitlesWidget: (val, meta) => Text(
                            '${val.toInt()}',
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 20,
                          interval: 1.0,
                          getTitlesWidget: (val, meta) {
                            if ((val - val.round()).abs() < 0.05) {
                              return Text(
                                '${val.toInt()}h',
                                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    showingTooltipIndicators: [
                      ShowingTooltipIndicators([
                        LineBarSpot(
                          LineChartBarData(spots: animatedSpots),
                          0,
                          activeSpot,
                        ),
                      ]),
                    ],
                    lineTouchData: LineTouchData(
                      enabled: true,
                      handleBuiltInTouches: true,
                      touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                        if (touchResponse?.lineBarSpots != null && touchResponse!.lineBarSpots!.isNotEmpty) {
                          final idx = touchResponse.lineBarSpots!.first.spotIndex;
                          if (_hoverIndex != idx) {
                            setState(() {
                              _hoverIndex = idx;
                            });
                          }
                        }
                      },
                      getTouchedSpotIndicator: (barData, spotIndexes) {
                        return spotIndexes.map((i) {
                          return TouchedSpotIndicatorData(
                            const FlLine(
                              color: Color(0xFF0284C7),
                              strokeWidth: 1.5,
                              dashArray: [3, 3],
                            ),
                            FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                                radius: 5.5,
                                color: const Color(0xFF0284C7),
                                strokeWidth: 2.5,
                                strokeColor: Colors.white,
                              ),
                            ),
                          );
                        }).toList();
                      },
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) => const Color(0xFF0284C7),
                        tooltipPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        tooltipBorderRadius: BorderRadius.circular(6),
                        tooltipMargin: 8,
                        fitInsideHorizontally: true,
                        fitInsideVertically: true,
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final timeLabel = _formatTimeFromHour(spot.x);
                            return LineTooltipItem(
                              '$timeLabel: ${spot.y.toInt()} mm',
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: animatedSpots,
                        isCurved: true,
                        curveSmoothness: 0.1,
                        color: const Color(0xFF0284C7),
                        barWidth: 2.5,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          checkToShowDot: (spot, barData) {
                            return (spot.x - spot.x.round()).abs() < 0.005;
                          },
                          getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                            radius: 3.5,
                            color: const Color(0xFF0284C7),
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFF0284C7).withValues(alpha: 0.22),
                              const Color(0xFF0284C7).withValues(alpha: 0.01),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ],
  ),
);
}

  Widget _metricColumn({
    Widget? prefixIcon,
    required String value,
    required String label,
    required Color valColor,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (prefixIcon != null) ...[
                prefixIcon,
                const SizedBox(width: 3),
              ],
              Text(
                value,
                style: TextStyle(
                  color: valColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _vDivider() {
    return Container(
      height: 26,
      width: 1,
      color: const Color(0xFFE2E8F0),
      margin: const EdgeInsets.symmetric(horizontal: 10),
    );
  }
}
