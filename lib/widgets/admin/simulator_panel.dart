import 'package:flutter/material.dart';
import 'dart:async';

class SimulatorPanel extends StatefulWidget {
  const SimulatorPanel({Key? key}) : super(key: key);

  @override
  State<SimulatorPanel> createState() => _SimulatorPanelState();
}

class _SimulatorPanelState extends State<SimulatorPanel> {
  String? _selectedScenario;
  String _severity = 'MODERATE';
  bool _isSimulating = false;
  double _progress = 0.0;
  String? _resultMessage;

  final List<String> _severities = ['LOW', 'MODERATE', 'SEVERE', 'EXTREME'];

  final List<Map<String, dynamic>> _scenarios = [
    {'id': 'rain_surge', 'title': 'Rain Surge', 'icon': Icons.storm, 'color': Color(0xFF0284C7)},
    {'id': 'sensor_fail', 'title': 'Sensor Failure', 'icon': Icons.sensors_off, 'color': Color(0xFFD97706)},
    {'id': 'road_block', 'title': 'Road Blockage', 'icon': Icons.block, 'color': Color(0xFFEF4444)},
    {'id': 'sat_delay', 'title': 'Satellite Delay', 'icon': Icons.satellite_alt, 'color': Color(0xFF8B5CF6)},
    {'id': 'offline', 'title': 'Offline Mode', 'icon': Icons.wifi_off, 'color': Color(0xFF64748B)},
  ];

  void _runSimulation() {
    if (_selectedScenario == null) return;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Simulation', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Execute simulated scenario "$_selectedScenario" at $_severity severity? This is a local UI demo only.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _startSimulationProgress();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white),
            child: const Text('Run Demo'),
          ),
        ],
      ),
    );
  }

  void _startSimulationProgress() {
    setState(() {
      _isSimulating = true;
      _progress = 0.0;
      _resultMessage = null;
    });

    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _progress += 0.05;
        if (_progress >= 1.0) {
          _progress = 1.0;
          _isSimulating = false;
          _resultMessage = 'Scenario "$_selectedScenario" completed at $_severity severity.\n(Demo Mode - No real changes made)';
          timer.cancel();
        }
      });
    });
  }

  void _resetSimulation() {
    setState(() {
      _selectedScenario = null;
      _isSimulating = false;
      _progress = 0.0;
      _resultMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x080F172A), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.science, color: Color(0xFF334155), size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text('Simulator / Demo Power Tool', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFFECACA))),
                child: const Text('SIMULATION ONLY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFEF4444), letterSpacing: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Scenarios Grid
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _scenarios.map((s) => _buildScenarioCard(s)).toList(),
          ),
          
          const SizedBox(height: 24),
          
          // Controls & Progress
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: _selectedScenario != null ? _buildSimulationControls() : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioCard(Map<String, dynamic> scenario) {
    final bool isSelected = _selectedScenario == scenario['title'];
    final Color baseColor = scenario['color'];
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isSimulating ? null : () => setState(() {
          _selectedScenario = scenario['title'];
          _resultMessage = null;
        }),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 160,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? baseColor.withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? baseColor : const Color(0xFFE2E8F0), width: isSelected ? 2 : 1),
            boxShadow: isSelected ? [BoxShadow(color: baseColor.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))] : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(scenario['icon'], color: isSelected ? baseColor : const Color(0xFF94A3B8), size: 28),
              const SizedBox(height: 12),
              Text(
                scenario['title'],
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF475569),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimulationControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Severity:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155))),
              const SizedBox(width: 12),
              Expanded(
                child: SegmentedButton<String>(
                  segments: _severities.map((s) => ButtonSegment(value: s, label: Text(s, style: const TextStyle(fontSize: 11)))).toList(),
                  selected: {_severity},
                  onSelectionChanged: _isSimulating ? null : (Set<String> newSelection) {
                    setState(() => _severity = newSelection.first);
                  },
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          if (_isSimulating) ...[
            const Text('Executing Simulation...', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: const Color(0xFFE2E8F0),
              color: const Color(0xFF6366F1),
              borderRadius: BorderRadius.circular(4),
              minHeight: 8,
            ),
          ] else if (_resultMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFA7F3D0))),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_resultMessage!, style: const TextStyle(color: Color(0xFF065F46), fontSize: 13, fontWeight: FontWeight.w500))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _resetSimulation,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Reset Simulation'),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF64748B)),
                ),
              ],
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _resetSimulation,
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _runSimulation,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Start Demo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
