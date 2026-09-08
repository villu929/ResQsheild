import 'package:flutter/material.dart';
import 'citizen_safe_route_view.dart';

class CitizenSheltersView extends StatefulWidget {
  final bool isHindi;

  const CitizenSheltersView({super.key, this.isHindi = false});

  @override
  State<CitizenSheltersView> createState() => _CitizenSheltersViewState();
}

class _CitizenSheltersViewState extends State<CitizenSheltersView> {
  String _activeFilter = 'All';

  final List<Map<String, dynamic>> _shelters = [
    {
      'name': 'Govt Senior Secondary School',
      'location': 'Sector 4 High Ground, Bokaro',
      'distance': '0.8 km away',
      'status': 'OPEN',
      'statusColor': Color(0xFF15945C),
      'capacity': '380 / 500 Beds',
      'occupancyPercent': 0.76,
      'hasDoctor': true,
      'doctorText': 'Doctor & 2 Nurses On-Site',
      'phone': '06542-240112',
      'facilities': ['Clean Meals', 'Drinking Water', 'Generators', 'Sanitation'],
    },
    {
      'name': 'Community Welfare Center',
      'location': 'Ward 9 Ridge Road',
      'distance': '1.3 km away',
      'status': 'OPEN',
      'statusColor': Color(0xFF15945C),
      'capacity': '210 / 300 Beds',
      'occupancyPercent': 0.70,
      'hasDoctor': true,
      'doctorText': 'Red Cross First-Aid Team',
      'phone': '06542-240115',
      'facilities': ['Hot Food', 'Dry Blankets', 'Infant Kits'],
    },
    {
      'name': 'St. Xavier Parish Relief Hall',
      'location': 'Bypass Elevation Point 3',
      'distance': '2.1 km away',
      'status': 'NEAR FULL',
      'statusColor': Color(0xFFF39A20),
      'capacity': '190 / 200 Beds',
      'occupancyPercent': 0.95,
      'hasDoctor': false,
      'doctorText': 'Basic First Aid Kit Only',
      'phone': '06542-240120',
      'facilities': ['Emergency Rations', 'Mobile Charging Station'],
    },
    {
      'name': 'District Indoor Stadium Shelter',
      'location': 'Civic Center Hilltop',
      'distance': '3.4 km away',
      'status': 'OPEN',
      'statusColor': Color(0xFF15945C),
      'capacity': '420 / 1200 Beds',
      'occupancyPercent': 0.35,
      'hasDoctor': true,
      'doctorText': 'Full Medical Camp (SDRF Medical Unit)',
      'phone': '1077',
      'facilities': ['1000+ Capacity', 'Field Hospital', 'Dedicated Women & Child Wing'],
    },
  ];

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF013973),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9F4FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF013973)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isHindi ? 'सत्यापित राहत शिविर' : 'Verified Relief Shelters',
          style: const TextStyle(
            color: Color(0xFF013973),
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips Row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('All'),
                  const SizedBox(width: 8),
                  _filterChip('Open Now'),
                  const SizedBox(width: 8),
                  _filterChip('Doctor On-Site'),
                  const SizedBox(width: 8),
                  _filterChip('High Capacity'),
                ],
              ),
            ),
          ),

          // Shelter Cards List
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _shelters.length,
              itemBuilder: (context, index) {
                final s = _shelters[index];
                return _buildShelterCard(s);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String title) {
    final bool isSelected = _activeFilter == title;
    return ChoiceChip(
      label: Text(title),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _activeFilter = title);
      },
      selectedColor: const Color(0xFF007AEB),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF013973),
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
      backgroundColor: const Color(0xFFF3F8FD),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _buildShelterCard(Map<String, dynamic> s) {
    final Color statusColor = s['statusColor'] as Color;
    final List<String> facilities = s['facilities'] as List<String>;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD6E8F7)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF013973).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Status badge and distance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  s['status'],
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.directions_walk_rounded, size: 16, color: Color(0xFF007AEB)),
                  const SizedBox(width: 4),
                  Text(
                    s['distance'],
                    style: const TextStyle(
                      color: Color(0xFF007AEB),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Shelter Name & Address
          Text(
            s['name'],
            style: const TextStyle(
              color: Color(0xFF013973),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF537392)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  s['location'],
                  style: const TextStyle(color: Color(0xFF537392), fontSize: 12),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Capacity Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Shelter Bed Capacity:',
                style: TextStyle(color: Color(0xFF537392), fontSize: 11, fontWeight: FontWeight.w600),
              ),
              Text(
                s['capacity'],
                style: const TextStyle(
                  color: Color(0xFF013973),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: s['occupancyPercent'] as double,
              backgroundColor: const Color(0xFFE5E9EE),
              color: statusColor,
              minHeight: 7,
            ),
          ),

          const SizedBox(height: 12),

          // Medical Doctor status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: s['hasDoctor'] ? const Color(0xFFEAF8F0) : const Color(0xFFFFF5E7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: s['hasDoctor'] ? const Color(0xFF15945C) : const Color(0xFFF39A20),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  s['hasDoctor'] ? Icons.medical_services_rounded : Icons.healing_rounded,
                  size: 15,
                  color: s['hasDoctor'] ? const Color(0xFF15945C) : const Color(0xFFF39A20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s['doctorText'],
                    style: TextStyle(
                      color: s['hasDoctor'] ? const Color(0xFF15945C) : const Color(0xFFF39A20),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Facilities Wrap
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: facilities.map((f) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F8FD),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFD6E8F7)),
                ),
                child: Text(
                  f,
                  style: const TextStyle(color: Color(0xFF013973), fontSize: 10, fontWeight: FontWeight.w600),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),

          // Action Buttons: Safe Route & Call
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CitizenSafeRouteView(isHindi: widget.isHindi),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AEB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.alt_route_rounded, size: 16),
                  label: const Text(
                    'Navigate Safe Route',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: () => _showMessage('Calling Camp Incharge: ${s['phone']}...'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF013973),
                    side: const BorderSide(color: Color(0xFFD6E8F7)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.call_rounded, size: 15, color: Color(0xFF15945C)),
                  label: const Text(
                    'Call Camp',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
