import 'package:flutter/material.dart';

class CitizenRiskView extends StatelessWidget {
  final bool isHindi;

  const CitizenRiskView({super.key, this.isHindi = false});

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
          isHindi ? 'मेरा स्थान जोखिम' : 'My Location Risk',
          style: const TextStyle(
            color: Color(0xFF013973),
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current Location Pin Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD6E8F7)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF013973).withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AEB).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.my_location_rounded, color: Color(0xFF007AEB), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isHindi ? 'वर्तमान स्थिति' : 'Current Village GPS Position',
                          style: const TextStyle(color: Color(0xFF537392), fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Sector 4, Bokaro (Damodar Basin)',
                          style: TextStyle(
                            color: Color(0xFF013973),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          '23.7957° N, 86.4304° E • Elevation: 218m',
                          style: TextStyle(color: Color(0xFF537392), fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Main Risk Assessment Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5E7),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFF39A20), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.warning_amber_rounded, color: Color(0xFFF39A20), size: 24),
                          SizedBox(width: 8),
                          Text(
                            'OVERALL HAZARD: HIGH',
                            style: TextStyle(
                              color: Color(0xFFF39A20),
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF39A20),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'PREPARE TO EVACUATE',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isHindi
                        ? 'सरल भाषा में आपके लिए अर्थ: आपके क्षेत्र के पास नदी का पानी बढ़ रहा है। अगले 2-3 घंटों में मुख्य सड़क पर पानी आ सकता है।'
                        : 'What this means in plain words: River Damodar upstream gates are discharging water. Low-lying roads near your house may become impassable in 2-3 hours.',
                    style: const TextStyle(
                      color: Color(0xFF0F2642),
                      fontSize: 13,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Perils Breakdown
            const Text(
              'SPECIFIC HAZARDS BREAKDOWN',
              style: TextStyle(
                color: Color(0xFF013973),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),

            _hazardTile(
              icon: Icons.flood_rounded,
              color: const Color(0xFFE92828),
              title: isHindi ? 'फ्लैश फ्लड (अचानक बाढ़)' : 'Flash Flood Risk',
              level: 'HIGH 🔴',
              desc: isHindi
                  ? 'जलस्तर 12 सेमी प्रति घंटा की दर से बढ़ रहा है। निचले कमरों से ऊपर जाएं।'
                  : 'Water level is rising 12 cm/hour. Avoid ground-level basements and culverts.',
            ),
            const SizedBox(height: 10),
            _hazardTile(
              icon: Icons.landslide_rounded,
              color: const Color(0xFFF39A20),
              title: isHindi ? 'भूस्खलन / मिट्टी का कटाव' : 'Landslide & Mudflow',
              level: 'MODERATE 🟠',
              desc: isHindi
                  ? 'पहाड़ी किनारों पर मिट्टी गीली है। ढलान वाले रास्तों पर सावधानी बरतें।'
                  : 'Hillslope soil saturation is 78%. Steer clear of steep road embankments.',
            ),
            const SizedBox(height: 10),
            _hazardTile(
              icon: Icons.water_drop_rounded,
              color: const Color(0xFF007AEB),
              title: isHindi ? 'पेयजल संदूषण' : 'Drinking Water Safety',
              level: 'SAFE FOR NOW 🟢',
              desc: isHindi
                  ? 'सरकारी पाइपलाइन अभी सुरक्षित है। कृपया पीने का पानी उबालकर रखें।'
                  : 'Municipal pipeline is currently uncontaminated. Boil water before drinking.',
            ),

            const SizedBox(height: 20),

            // Recommended Citizen Actions Checklist
            const Text(
              'WHAT YOU SHOULD DO RIGHT NOW',
              style: TextStyle(
                color: Color(0xFF013973),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD6E8F7)),
              ),
              child: Column(
                children: [
                  _actionCheckItem('1. Pack important ID cards, property papers & medicines in a waterproof bag.'),
                  const SizedBox(height: 10),
                  _actionCheckItem('2. Keep your mobile phones and emergency torches fully charged.'),
                  const SizedBox(height: 10),
                  _actionCheckItem('3. Locate the nearest high school shelter on the Safe Route screen.'),
                  const SizedBox(height: 10),
                  _actionCheckItem('4. If water enters the courtyard, trigger 🆘 SOS immediately.'),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _hazardTile({
    required IconData icon,
    required Color color,
    required String title,
    required String level,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD6E8F7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF013973),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      level,
                      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(color: Color(0xFF537392), fontSize: 12, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionCheckItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_rounded, color: Color(0xFF15945C), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF0F2642),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
