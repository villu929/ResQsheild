import 'package:flutter/material.dart';

class AffectedPeopleDetailScreen extends StatelessWidget {
  const AffectedPeopleDetailScreen({super.key});

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
          'Affected Population',
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
              color: const Color(0xFFF59E0B).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF59E0B), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.people_outline_rounded, color: Color(0xFFF59E0B), size: 14),
                SizedBox(width: 4),
                Text(
                  '18 AREAS',
                  style: TextStyle(
                    color: Color(0xFFF59E0B),
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
            // Hero Card
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
                          const Color(0xFF061A2B).withOpacity(0.9),
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
                              'Total Affected Individuals',
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
                                  '12,450',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 38,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'people',
                                  style: TextStyle(
                                    color: Color(0xFFF59E0B),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withOpacity(0.25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Spread across 18 low-lying zones',
                                style: TextStyle(
                                  color: Color(0xFFFCD34D),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Key Stats Grid
            Row(
              children: [
                _buildStatTile('Relief Camps', '36 Active', Icons.night_shelter_rounded, const Color(0xFF10B981)),
                const SizedBox(width: 12),
                _buildStatTile('In Shelters', '8,920', Icons.volunteer_activism_rounded, const Color(0xFF38BDF8)),
                const SizedBox(width: 12),
                _buildStatTile('Need Rescue', '1,420', Icons.priority_high_rounded, const Color(0xFFEF4444)),
              ],
            ),

            const SizedBox(height: 24),

            // Affected Regions Breakdown
            const Text(
              'Impact by Region',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),

            _buildRegionItem('Aluva Municipality', '4,200 people', 'Severe Flood (Zone A)', const Color(0xFFEF4444)),
            _buildRegionItem('North Paravur', '3,150 people', 'High Alert (Zone B)', const Color(0xFFF59E0B)),
            _buildRegionItem('Kalamassery Riverside', '2,800 people', 'Moderate (Zone C)', const Color(0xFF38BDF8)),
            _buildRegionItem('Varapuzha Panchayat', '2,300 people', 'Waterlogged', const Color(0xFF10B981)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, Color color) {
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

  Widget _buildRegionItem(String name, String count, String tag, Color tagColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF092033),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF193755)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                count,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: tagColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: tagColor.withOpacity(0.4)),
            ),
            child: Text(
              tag,
              style: TextStyle(
                color: tagColor,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
