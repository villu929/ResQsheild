import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../models/incident_models.dart';
import '../../../../services/river_api_service.dart';
import '../../../../services/rainfall_api_service.dart';

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

class _RiverTelemetryCardState extends State<RiverTelemetryCard> {
  List<RiverModel> _rivers = [];
  RiverModel? _selectedRiver;
  bool _is12H = true;

  @override
  void initState() {
    super.initState();
    _loadRivers();
  }

  Future<void> _loadRivers() async {
    final data = await RiverApiService.fetchRivers();
    if (mounted) {
      setState(() {
        _rivers = data;
        if (_rivers.isNotEmpty) _selectedRiver = _rivers.first;
      });
    }
  }

  void _showRiverSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select River Station', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: _rivers.length,
                  itemBuilder: (context, index) {
                    final r = _rivers[index];
                    Color statusColor = _getStatusColor(r.status);
                    return ListTile(
                      leading: Icon(Icons.waves, color: statusColor),
                      title: Text('${r.name} — ${r.stationName}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('Cur: ${r.currentLevel.toStringAsFixed(1)}m • Dngr: ${r.dangerLevelM}m'),
                      trailing: Text(r.status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w800)),
                      onTap: () {
                        setState(() {
                          _selectedRiver = r;
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'DANGER': return const Color(0xFFDC2626);
      case 'WARNING': return const Color(0xFFEA580C);
      case 'WATCH': return const Color(0xFFD97706);
      case 'NORMAL':
      default: return const Color(0xFF16A34A);
    }
  }

  List<FlSpot> _getSpots() {
    if (_selectedRiver == null || _selectedRiver!.observations.isEmpty) return [];
    final obs = _selectedRiver!.observations;
    
    List<FlSpot> hourlySpots = [];

    for (int i = 0; i < obs.length; i++) {
      final o = obs[i];
      int hoursAgo = obs.length - 1 - i; 
      
      if (_is12H) {
        hourlySpots.add(FlSpot((12 - hoursAgo).toDouble(), o.waterLevelM));
      } else {
        if (hoursAgo <= 6) {
          hourlySpots.add(FlSpot((6 - hoursAgo).toDouble(), o.waterLevelM));
        }
      }
    }
    
    // Generate dense spots for continuous hover
    hourlySpots.sort((a, b) => a.x.compareTo(b.x));
    List<double> values = hourlySpots.map((s) => s.y).toList();
    List<FlSpot> denseSpots = [];
    int totalMinutes = _is12H ? 12 * 60 : 6 * 60;
    for (int m = 0; m <= totalMinutes; m++) {
      double t = m / 60.0;
      double y = _interpolateSpline(values, t);
      denseSpots.add(FlSpot(t, y));
    }
    return denseSpots;
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedRiver == null) {
      return Container(
        height: 300,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final spots = _getSpots();
    
    // Dynamic Y-axis logic
    double minY = 0.0;
    double maxY = 10.0;
    
    if (spots.isNotEmpty) {
      double minSpotY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
      double maxSpotY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
      
      // Determine minY
      if (_selectedRiver!.normalMinM > 50) {
        minY = ((minSpotY - 10) / 10).floor() * 10.0;
        if (minY < 0) minY = 0;
      } else if (_selectedRiver!.normalMinM > 20) {
        minY = ((minSpotY - 5) / 5).floor() * 5.0;
        if (minY < 0) minY = 0;
      } else {
        minY = 0;
      }

      // Determine maxY
      double requiredMax = maxSpotY > _selectedRiver!.dangerLevelM ? maxSpotY : _selectedRiver!.dangerLevelM;
      double range = requiredMax - minY;
      
      if (range > 100) {
        maxY = (requiredMax / 25).ceil() * 25.0;
      } else if (range > 50) {
        maxY = (requiredMax / 10).ceil() * 10.0;
      } else if (range > 20) {
        maxY = (requiredMax / 5).ceil() * 5.0;
      } else {
        maxY = (requiredMax / 2).ceil() * 2.0;
        if (maxY <= requiredMax) maxY += 2.0;
      }
    }
    
    // Determine interval for grid
    double interval = (maxY - minY) / 5;
    if (interval < 1) interval = 1;
    
    final statusColor = _getStatusColor(_selectedRiver!.status);
    final rate = _selectedRiver!.rateOfRise;
    final rateStr = '${rate > 0 ? '+' : ''}${(rate * 100).toInt()} cm/hr ${rate > 0.02 ? '↑' : (rate < -0.02 ? '↓' : '')}';

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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.waves_rounded, color: Color(0xFF0284C7), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RIVER TELEMETRY',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    InkWell(
                      onTap: _showRiverSelector,
                      borderRadius: BorderRadius.circular(4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              '${_selectedRiver!.name} — ${_selectedRiver!.stationName}',
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0284C7), size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Live Indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDCFCE7)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: Color(0xFF16A34A), size: 8),
                    SizedBox(width: 4),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: Color(0xFF16A34A),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // KPIs Row
          Row(
            children: [
              _kpiBlock('CURRENT', '${_selectedRiver!.currentLevel.toStringAsFixed(1)} m'),
              _vDivider(),
              _kpiBlock('NORMAL', '${_selectedRiver!.normalMinM.toInt()}–${_selectedRiver!.normalMaxM.toInt()} m'),
              _vDivider(),
              _kpiBlock('DANGER', '${_selectedRiver!.dangerLevelM} m'),
              _vDivider(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('RATE', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(rateStr, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: -0.3)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Range Selector & Chart Area
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _is12H ? 'Last 12 Hours' : 'Last 6 Hours',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text(_selectedRiver!.status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        _rangeToggle('6H', !_is12H, () => setState(() => _is12H = false)),
                        _rangeToggle('12H', _is12H, () => setState(() => _is12H = true)),
                      ],
                    ),
                  )
                ],
              )
            ],
          ),
          const SizedBox(height: 12),

          SizedBox(
            height: 170,
            child: LineChart(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              LineChartData(
                minX: 0,
                maxX: _is12H ? 12 : 6,
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (val) => const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: interval,
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
                      interval: 2.0,
                      getTitlesWidget: (val, meta) {
                        int hoursAgo = _is12H ? (12 - val.toInt()) : (6 - val.toInt());
                        if (hoursAgo == 0) return const Text('Now', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5));
                        return Text('${hoursAgo}h', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(y: _selectedRiver!.watchLevelM, color: const Color(0xFFD97706).withValues(alpha: 0.5), strokeWidth: 1, dashArray: [4, 4], label: HorizontalLineLabel(show: true, alignment: Alignment.bottomRight, style: const TextStyle(color: Color(0xFFD97706), fontSize: 8), labelResolver: (_) => 'Watch')),
                    HorizontalLine(y: _selectedRiver!.warningLevelM, color: const Color(0xFFEA580C).withValues(alpha: 0.6), strokeWidth: 1, dashArray: [4, 4], label: HorizontalLineLabel(show: true, alignment: Alignment.bottomRight, style: const TextStyle(color: Color(0xFFEA580C), fontSize: 8), labelResolver: (_) => 'Warning')),
                    HorizontalLine(y: _selectedRiver!.dangerLevelM, color: const Color(0xFFDC2626).withValues(alpha: 0.8), strokeWidth: 1.5, dashArray: [4, 4], label: HorizontalLineLabel(show: true, alignment: Alignment.bottomRight, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 8, fontWeight: FontWeight.w700), labelResolver: (_) => 'Danger')),
                  ],
                ),
                lineTouchData: LineTouchData(
                  enabled: true,
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF172033),
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipBorderRadius: BorderRadius.circular(6),
                  getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        double hoursAgo = _is12H ? (12 - spot.x) : (6 - spot.x);
                        String timeStr = hoursAgo <= 0 ? 'Now' : _formatTimeFromHour(hoursAgo) + ' ago';
                        return LineTooltipItem(
                          '$timeStr\nLvl: ${spot.y.toStringAsFixed(2)} m',
                          const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        );
                      }).toList();
                    },
                  ),
                  getTouchedSpotIndicator: (barData, spotIndexes) {
                    return spotIndexes.map((i) {
                      return TouchedSpotIndicatorData(
                        const FlLine(color: Color(0xFF0284C7), strokeWidth: 1.5, dashArray: [3, 3]),
                        FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 5, color: const Color(0xFF0284C7), strokeWidth: 2, strokeColor: Colors.white)),
                      );
                    }).toList();
                  },
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.2,
                    color: const Color(0xFF0284C7), // Keep line government blue
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF0284C7).withValues(alpha: 0.15),
                          const Color(0xFF0284C7).withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiBlock(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: -0.3)),
        ],
      ),
    );
  }

  Widget _rangeToggle(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1))] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _vDivider() {
    return Container(
      height: 24,
      width: 1,
      color: const Color(0xFFE2E8F0),
      margin: const EdgeInsets.symmetric(horizontal: 12),
    );
  }
}

// ============================================================================
class RainfallTelemetryCard extends StatefulWidget {
  const RainfallTelemetryCard({super.key});

  @override
  State<RainfallTelemetryCard> createState() => _RainfallTelemetryCardState();
}

class _RainfallTelemetryCardState extends State<RainfallTelemetryCard> {
  List<RainfallModel> _areas = [];
  RainfallModel? _selectedArea;
  bool _is12H = true;
  int? _hoverIndex;

  @override
  void initState() {
    super.initState();
    _loadAreas();
  }

  Future<void> _loadAreas() async {
    final data = await RainfallApiService.fetchRainfallData();
    if (mounted) {
      setState(() {
        _areas = data;
        if (_areas.isNotEmpty) _selectedArea = _areas.first;
      });
    }
  }

  void _showAreaSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select Rainfall Area', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: _areas.length,
                  itemBuilder: (context, index) {
                    final r = _areas[index];
                    Color statusColor = _getStatusColor(r.alertLevel);
                    return ListTile(
                      leading: Icon(Icons.water_drop, color: statusColor),
                      title: Text('${r.areaName}, ${r.state}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('12h: ${r.total12H}mm • Fcst: ${r.forecastMm}mm'),
                      trailing: Text(r.status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w800)),
                      onTap: () {
                        setState(() {
                          _selectedArea = r;
                          _hoverIndex = null;
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(String alertLevel) {
    switch (alertLevel) {
      case 'Red': return const Color(0xFFDC2626);
      case 'Orange': return const Color(0xFFEA580C);
      case 'Yellow': return const Color(0xFFD97706);
      case 'Green':
      default: return const Color(0xFF16A34A);
    }
  }

  List<FlSpot> _getSpots() {
    if (_selectedArea == null || _selectedArea!.observations.isEmpty) return [];
    final obs = _selectedArea!.observations;
    
    List<FlSpot> hourlySpots = [];
    double baseMm = 0;

    if (!_is12H && obs.length >= 7) {
      baseMm = obs[obs.length - 7].cumulativeMm;
    }

    for (int i = 0; i < obs.length; i++) {
      final o = obs[i];
      int hoursAgo = obs.length - 1 - i; // Assumes 1 per hour, last is 0
      
      if (_is12H) {
        hourlySpots.add(FlSpot((12 - hoursAgo).toDouble(), o.cumulativeMm));
      } else {
        if (hoursAgo <= 6) {
          hourlySpots.add(FlSpot((6 - hoursAgo).toDouble(), o.cumulativeMm - baseMm));
        }
      }
    }
    
    // Generate dense spots for continuous hover
    hourlySpots.sort((a, b) => a.x.compareTo(b.x));
    List<double> values = hourlySpots.map((s) => s.y).toList();
    List<FlSpot> denseSpots = [];
    int totalMinutes = _is12H ? 12 * 60 : 6 * 60;
    for (int m = 0; m <= totalMinutes; m++) {
      double t = m / 60.0;
      double y = _interpolateSpline(values, t);
      denseSpots.add(FlSpot(t, y));
    }
    return denseSpots;
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedArea == null) {
      return Container(
        height: 300,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final spots = _getSpots();
    double maxY = 36.0;
    if (spots.isNotEmpty) {
      double maxSpotY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
      if (maxSpotY > 36.0) {
        maxY = ((maxSpotY / 10).ceil() * 10).toDouble() + 5.0; 
      }
    }
    
    final statusColor = _getStatusColor(_selectedArea!.alertLevel);

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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.water_drop_rounded, color: Color(0xFF0284C7), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RAINFALL TELEMETRY',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    InkWell(
                      onTap: _showAreaSelector,
                      borderRadius: BorderRadius.circular(4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedArea!.areaName,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0284C7), size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Live Indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDCFCE7)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: Color(0xFF16A34A), size: 8),
                    SizedBox(width: 4),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: Color(0xFF16A34A),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // KPIs Row
          Row(
            children: [
              _kpiBlock('1H', '${_selectedArea!.total1H.toStringAsFixed(1)} mm'),
              _vDivider(),
              _kpiBlock('6H', '${_selectedArea!.total6H.toStringAsFixed(1)} mm'),
              _vDivider(),
              _kpiBlock('12H', '${_selectedArea!.total12H.toStringAsFixed(1)} mm'),
              _vDivider(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Intensity', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _selectedArea!.status,
                        style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Range Selector & Chart Area
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _is12H ? 'Last 12 Hours Cumulative' : 'Last 6 Hours Cumulative',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    _rangeToggle('6H', !_is12H, () => setState(() => _is12H = false)),
                    _rangeToggle('12H', _is12H, () => setState(() => _is12H = true)),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 12),

          SizedBox(
            height: 170,
            child: LineChart(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              LineChartData(
                minX: 0,
                maxX: _is12H ? 12 : 6,
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 9.0,
                  getDrawingHorizontalLine: (val) => const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: 9.0,
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
                      interval: 2.0,
                      getTitlesWidget: (val, meta) {
                        int hoursAgo = _is12H ? (12 - val.toInt()) : (6 - val.toInt());
                        if (hoursAgo == 0) return const Text('Now', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5));
                        return Text('${hoursAgo}h', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(y: 18.0, color: const Color(0xFFD97706).withValues(alpha: 0.3), strokeWidth: 1, dashArray: [4, 4], label: HorizontalLineLabel(show: true, alignment: Alignment.topRight, style: const TextStyle(color: Color(0xFFD97706), fontSize: 8), labelResolver: (_) => '18mm (Mod)')),
                    HorizontalLine(y: 27.0, color: const Color(0xFFEA580C).withValues(alpha: 0.4), strokeWidth: 1, dashArray: [4, 4], label: HorizontalLineLabel(show: true, alignment: Alignment.topRight, style: const TextStyle(color: Color(0xFFEA580C), fontSize: 8), labelResolver: (_) => '27mm (Hvy)')),
                    HorizontalLine(y: 36.0, color: const Color(0xFFDC2626).withValues(alpha: 0.5), strokeWidth: 1, dashArray: [4, 4], label: HorizontalLineLabel(show: true, alignment: Alignment.topRight, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 8), labelResolver: (_) => '36mm (Dngr)')),
                  ],
                ),
                lineTouchData: LineTouchData(
                  enabled: true,
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF172033),
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipBorderRadius: BorderRadius.circular(6),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        double hoursAgo = _is12H ? (12 - spot.x) : (6 - spot.x);
                        String timeStr = hoursAgo <= 0 ? 'Now' : _formatTimeFromHour(hoursAgo) + ' ago';
                        return LineTooltipItem(
                          '$timeStr\nCumulative: ${spot.y.toStringAsFixed(1)} mm',
                          const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        );
                      }).toList();
                    },
                  ),
                  getTouchedSpotIndicator: (barData, spotIndexes) {
                    return spotIndexes.map((i) {
                      return TouchedSpotIndicatorData(
                        const FlLine(color: Color(0xFF0284C7), strokeWidth: 1.5, dashArray: [3, 3]),
                        FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 5, color: const Color(0xFF0284C7), strokeWidth: 2, strokeColor: Colors.white)),
                      );
                    }).toList();
                  },
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.2,
                    color: statusColor,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          statusColor.withValues(alpha: 0.2),
                          statusColor.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiBlock(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: -0.3)),
        ],
      ),
    );
  }

  Widget _rangeToggle(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1))] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _vDivider() {
    return Container(
      height: 24,
      width: 1,
      color: const Color(0xFFE2E8F0),
      margin: const EdgeInsets.symmetric(horizontal: 12),
    );
  }
}

