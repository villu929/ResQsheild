import 'package:flutter/material.dart';

class RescueTeamsDetailScreen extends StatelessWidget {
  const RescueTeamsDetailScreen({super.key});

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
          'Rescue Teams & Boats',
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
              color: const Color(0xFFA855F7).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFA855F7), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.shield_outlined, color: Color(0xFFA855F7), size: 14),
                SizedBox(width: 4),
                Text(
                  '24 ACTIVE',
                  style: TextStyle(
                    color: Color(0xFFA855F7),
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
                    'assets/images/screen_bg_2.png',
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
                              'Deployed Task Forces',
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
                                  '24',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 38,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'teams on field',
                                  style: TextStyle(
                                    color: Color(0xFFA855F7),
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
                                color: const Color(0xFFA855F7).withOpacity(0.25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'NDRF, Indian Navy & SDRF Units',
                                style: TextStyle(
                                  color: Color(0xFFD8B4FE),
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
                _buildStatTile('Rescue Boats', '18 Motorized', Icons.sailing_rounded, const Color(0xFF38BDF8)),
                const SizedBox(width: 12),
                _buildStatTile('Rescued Today', '384 Persons', Icons.health_and_safety_rounded, const Color(0xFF10B981)),
                const SizedBox(width: 12),
                _buildStatTile('Helicopters', '3 Air Sorties', Icons.airplanemode_active_rounded, const Color(0xFFA855F7)),
              ],
            ),

            const SizedBox(height: 24),

            // Active Units List
            const Text(
              'Active Rescue Battalions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),

            _buildTeamItem('NDRF 4th Battalion Team Alpha', 'Aluva Riverside', '8 Boats • 32 Personnel', const Color(0xFF10B981)),
            _buildTeamItem('Indian Navy Diving Team', 'Periyar Basin', '4 Gemini Boats • 16 Divers', const Color(0xFF38BDF8)),
            _buildTeamItem('SDRF Emergency Response Unit', 'Paravur Sector', '3 Rescue Craft • 12 Staff', const Color(0xFFA855F7)),
            _buildTeamItem('Civil Defense Quick Action', 'Kalamassery', 'Food & Meds Delivery', const Color(0xFFF59E0B)),
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

  Widget _buildTeamItem(String name, String sector, String detail, Color badgeColor) {
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
          Expanded(
            child: Column(
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
                  detail,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: badgeColor.withOpacity(0.4)),
            ),
            child: Text(
              sector,
              style: TextStyle(
                color: badgeColor,
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
