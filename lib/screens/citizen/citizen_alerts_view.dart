import 'package:flutter/material.dart';

class CitizenAlertsView extends StatefulWidget {
  final bool isHindi;

  const CitizenAlertsView({super.key, this.isHindi = false});

  @override
  State<CitizenAlertsView> createState() => _CitizenAlertsViewState();
}

class _CitizenAlertsViewState extends State<CitizenAlertsView> {
  String _activeFilter = 'All';

  final List<Map<String, dynamic>> _alerts = [
    {
      'id': 'ALT-104',
      'level': 'EVACUATION ORDER',
      'levelHi': 'तत्काल निकासी आदेश',
      'time': '18 mins ago',
      'source': 'NDMA & District Administration',
      'title': 'Mandatory Evacuation for Riverbank Wards',
      'titleHi': 'नदी तटवर्ती वार्डों के लिए अनिवार्य निकासी',
      'message':
          'Tenughat Dam floodgates 4 and 5 have been opened. Residents in low-lying riverside sectors must proceed along designated Safe Routes to designated schools immediately.',
      'messageHi':
          'तेनुघाट बांध के फाटक 4 और 5 खोल दिए गए हैं। निचले इलाकों के निवासी तुरंत सुरक्षित मार्ग का उपयोग कर राहत शिविरों में पहुंचे।',
      'color': Color(0xFFE92828),
      'icon': Icons.campaign_rounded,
    },
    {
      'id': 'ALT-103',
      'level': 'WARNING',
      'levelHi': 'बाढ़ चेतावनी (ऑरेंज अलर्ट)',
      'time': '1 hr ago',
      'source': 'Central Water Commission (CWC)',
      'title': 'River Damodar Gauge Approaching Danger Level',
      'titleHi': 'दामोदर नदी का जलस्तर खतरे के निशान के करीब',
      'message':
          'Water level at Bokaro gauge is currently 214.6m (Danger Level: 215.2m). Rate of rise is approximately 14 cm per hour. Avoid river crossings.',
      'messageHi':
          'बोकारो गेज पर जलस्तर 214.6 मीटर दर्ज किया गया है (खतरे का निशान: 215.2 मीटर)। नदी तट और पुलों से दूर रहें।',
      'color': Color(0xFFF39A20),
      'icon': Icons.warning_amber_rounded,
    },
    {
      'id': 'ALT-102',
      'level': 'WATCH',
      'levelHi': 'मौसम निगरानी (येलो अलर्ट)',
      'time': '3 hrs ago',
      'source': 'India Meteorological Department (IMD)',
      'title': 'Heavy Rainfall Influx Forecast',
      'titleHi': 'अगले 6 घंटों में भारी वर्षा का पूर्वानुमान',
      'message':
          'Doppler Radar indicates widespread convective rainfall clouds over Bokaro & Dhanbad. Expected rainfall: 85mm to 110mm.',
      'messageHi':
          'राडार रिपोर्ट के अनुसार अगले कुछ घंटों में 85 से 110 मिमी भारी वर्षा होने की संभावना है।',
      'color': Color(0xFF007AEB),
      'icon': Icons.cloud_sync_rounded,
    },
    {
      'id': 'ALT-101',
      'level': 'ADVISORY',
      'levelHi': 'सामान्य सुरक्षा परामर्श',
      'time': 'Yesterday',
      'source': 'State Disaster Management Authority (SDMA)',
      'title': 'Monsoon Preparedness Protocol Active',
      'titleHi': 'मानसूनी आपदा प्रबंधन प्रोटोकॉल सक्रिय',
      'message':
          'All district relief shelters and boat rescue squads have been placed on 24-hour tactical standby.',
      'messageHi':
          'सभी राहत शिविर और नौका बचाव दल 24 घंटे की सतर्कता पर तैनात किए गए हैं।',
      'color': Color(0xFF15945C),
      'icon': Icons.check_circle_outline_rounded,
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
          widget.isHindi ? 'आपातकालीन अलर्ट्स इनबॉक्स' : 'Emergency Alert Inbox',
          style: const TextStyle(
            color: Color(0xFF013973),
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('All'),
                  const SizedBox(width: 8),
                  _filterChip('Evacuation'),
                  const SizedBox(width: 8),
                  _filterChip('Warning'),
                  const SizedBox(width: 8),
                  _filterChip('Watch'),
                ],
              ),
            ),
          ),

          // Alerts List
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: _alerts.length,
              itemBuilder: (context, index) {
                final a = _alerts[index];
                return _buildAlertCard(a);
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

  Widget _buildAlertCard(Map<String, dynamic> a) {
    final Color color = a['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF013973).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Severity Badge & Time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(a['icon'] as IconData, size: 14, color: color),
                    const SizedBox(width: 6),
                    Text(
                      widget.isHindi ? (a['levelHi'] as String) : (a['level'] as String),
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                a['time'],
                style: const TextStyle(color: Color(0xFF537392), fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Title
          Text(
            widget.isHindi ? (a['titleHi'] as String) : (a['title'] as String),
            style: const TextStyle(
              color: Color(0xFF013973),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 2),

          // Source
          Text(
            'Source: ${a['source']}',
            style: const TextStyle(
              color: Color(0xFF007AEB),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          // Message
          Text(
            widget.isHindi ? (a['messageHi'] as String) : (a['message'] as String),
            style: const TextStyle(
              color: Color(0xFF0F2642),
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 12),

          // Action: Audio siren / speech simulation
          InkWell(
            onTap: () => _showMessage('Playing official voice alert in Hindi / English...'),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F8FD),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.volume_up_rounded, size: 16, color: Color(0xFF007AEB)),
                  SizedBox(width: 6),
                  Text(
                    'Play Audio Siren & Voice Broadcast',
                    style: TextStyle(color: Color(0xFF007AEB), fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
