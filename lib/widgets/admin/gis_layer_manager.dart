import 'package:flutter/material.dart';

class GisLayerManager extends StatelessWidget {
  const GisLayerManager({Key? key}) : super(key: key);

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
              Icon(Icons.layers, color: Color(0xFF6366F1), size: 22),
              SizedBox(width: 8),
              Text('GIS Layer Manager', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 16),
          _buildLayerSwitch('DEM (Digital Elevation Model)', true),
          _buildLayerSwitch('Flood Extent (SAR)', true),
          _buildLayerSwitch('Susceptibility Map', false),
          _buildLayerSwitch('Road Networks', true),
          _buildLayerSwitch('Relief Shelters', true),
          _buildLayerSwitch('Critical Infrastructure', false),
        ],
      ),
    );
  }

  Widget _buildLayerSwitch(String label, bool value) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF334155))),
      value: value,
      onChanged: (bool newValue) {},
      activeColor: const Color(0xFF6366F1),
      contentPadding: EdgeInsets.zero,
    );
  }
}
