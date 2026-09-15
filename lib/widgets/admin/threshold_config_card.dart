import 'package:flutter/material.dart';

class ThresholdConfigCard extends StatelessWidget {
  const ThresholdConfigCard({Key? key}) : super(key: key);

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
              Icon(Icons.tune, color: Color(0xFF6366F1), size: 22),
              SizedBox(width: 8),
              Text('Threshold Configuration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 16),
          _buildThresholdInput('River Gauge (Warning)', '3.5m', 'Hysteresis: 0.1m'),
          _buildThresholdInput('River Gauge (Critical)', '4.8m', 'Hysteresis: 0.2m'),
          _buildThresholdInput('Rainfall Intensity (1hr)', '50mm', 'Trigger CAP Alert'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () {}, child: const Text('Reset', style: TextStyle(color: Color(0xFF64748B)))),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white, elevation: 0),
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdInput(String label, String value, String hint) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF334155)))),
          Expanded(
            flex: 1,
            child: TextField(
              decoration: InputDecoration(
                isDense: true,
                hintText: value,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(flex: 2, child: Padding(padding: const EdgeInsets.only(left: 12), child: Text(hint, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)))),
        ],
      ),
    );
  }
}
