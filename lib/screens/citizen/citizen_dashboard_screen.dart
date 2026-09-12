import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

import 'citizen_safe_route_view.dart';
import 'citizen_shelters_view.dart';
import 'citizen_hazard_report_view.dart';
import 'citizen_alerts_view.dart';
import '../role_selection_screen.dart';

enum CitizenThreatLevel {
  safe,
  watch,
  warning,
  evacuation,
}

class _DosPhaseInfo {
  final String badgeEn;
  final String badgeHi;
  final String titleEn;
  final String titleHi;
  final List<String> tipsEn;
  final List<String> tipsHi;

  const _DosPhaseInfo({
    required this.badgeEn,
    required this.badgeHi,
    required this.titleEn,
    required this.titleHi,
    required this.tipsEn,
    required this.tipsHi,
  });
}

class _DosDisasterInfo {
  final String id;
  final String titleEn;
  final String titleHi;
  final String bannerTitleEn;
  final String bannerTitleHi;
  final String bannerSubtitleEn;
  final String bannerSubtitleHi;
  final IconData icon;
  final List<Color> gradient;
  final Color primaryColor;
  final String imagePath;
  final List<_DosPhaseInfo> phases;

  const _DosDisasterInfo({
    required this.id,
    required this.titleEn,
    required this.titleHi,
    required this.bannerTitleEn,
    required this.bannerTitleHi,
    required this.bannerSubtitleEn,
    required this.bannerSubtitleHi,
    required this.icon,
    required this.gradient,
    required this.primaryColor,
    required this.imagePath,
    required this.phases,
  });
}

class _ScenicWatermarkPainter extends CustomPainter {
  final Color baseColor;

  const _ScenicWatermarkPainter({required this.baseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final hillPaint1 = Paint()
      ..color = baseColor.withValues(alpha: 0.035)
      ..style = PaintingStyle.fill;

    final hillPaint2 = Paint()
      ..color = baseColor.withValues(alpha: 0.055)
      ..style = PaintingStyle.fill;

    final treePaint = Paint()
      ..color = baseColor.withValues(alpha: 0.09)
      ..style = PaintingStyle.fill;

    // Distant hill curve
    final path1 = Path();
    path1.moveTo(0, size.height * 0.40);
    path1.quadraticBezierTo(size.width * 0.20, size.height * 0.22, size.width * 0.45, size.height * 0.50);
    path1.quadraticBezierTo(size.width * 0.70, size.height * 0.75, size.width, size.height * 0.65);
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(path1, hillPaint1);

    // Midground hill curve
    final path2 = Path();
    path2.moveTo(0, size.height * 0.62);
    path2.quadraticBezierTo(size.width * 0.16, size.height * 0.42, size.width * 0.38, size.height * 0.68);
    path2.quadraticBezierTo(size.width * 0.60, size.height * 0.88, size.width * 0.82, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, hillPaint2);

    // Stylized conifer pine trees on bottom left
    void drawPineTree(double x, double baseY, double treeWidth, double treeHeight) {
      final p = Path();
      p.moveTo(x, baseY - treeHeight);
      p.lineTo(x + treeWidth * 0.32, baseY - treeHeight * 0.58);
      p.lineTo(x + treeWidth * 0.18, baseY - treeHeight * 0.58);
      p.lineTo(x + treeWidth * 0.40, baseY - treeHeight * 0.28);
      p.lineTo(x + treeWidth * 0.25, baseY - treeHeight * 0.28);
      p.lineTo(x + treeWidth * 0.50, baseY);
      p.lineTo(x - treeWidth * 0.50, baseY);
      p.lineTo(x - treeWidth * 0.25, baseY - treeHeight * 0.28);
      p.lineTo(x - treeWidth * 0.40, baseY - treeHeight * 0.28);
      p.lineTo(x - treeWidth * 0.18, baseY - treeHeight * 0.58);
      p.lineTo(x - treeWidth * 0.32, baseY - treeHeight * 0.58);
      p.close();
      canvas.drawPath(p, treePaint);
    }

    drawPineTree(size.width * 0.02, size.height * 0.98, 20, 38);
    drawPineTree(size.width * 0.055, size.height * 0.95, 16, 30);
    drawPineTree(size.width * 0.09, size.height * 0.99, 22, 44);
    drawPineTree(size.width * 0.13, size.height * 0.94, 15, 28);
    drawPineTree(size.width * 0.17, size.height * 0.97, 19, 36);
    drawPineTree(size.width * 0.22, size.height * 0.99, 14, 26);
    drawPineTree(size.width * 0.27, size.height * 0.96, 13, 24);
    drawPineTree(size.width * 0.33, size.height * 0.98, 12, 20);
  }

  @override
  bool shouldRepaint(covariant _ScenicWatermarkPainter oldDelegate) => oldDelegate.baseColor != baseColor;
}

final List<_DosDisasterInfo> _dosDisasterList = [
  // 1. URBAN FLOOD
  _DosDisasterInfo(
    id: 'flood',
    titleEn: 'Urban Flood',
    titleHi: 'शहरी बाढ़',
    bannerTitleEn: "Do's and Don'ts during Urban Flood",
    bannerTitleHi: 'शहरी बाढ़: क्या करें और क्या न करें',
    bannerSubtitleEn: 'Fast rising stormwater. Seek high ground immediately.',
    bannerSubtitleHi: 'तेजी से बढ़ता जलस्तर। तुरंत ऊंचे स्थानों पर जाएं।',
    icon: Icons.water_drop_rounded,
    gradient: const [Color(0xFF1D4ED8), Color(0xFF0284C7)],
    primaryColor: const Color(0xFF1D4ED8),
    imagePath: 'assets/images/flood_guide.jpg',
    phases: const [
      _DosPhaseInfo(
        badgeEn: 'Before Floods & Warning Signs',
        badgeHi: 'बाढ़ से पहले तैयारी व संकेत',
        titleEn: 'Before Floods',
        titleHi: 'बाढ़ से पहले',
        tipsEn: [
          'Make sure each person has lantern, torch, edibles, drinking water and necessary documents.',
          'Keep identity cards, insurance and medical prescriptions handy in waterproof pouches.',
          'Put all electrical appliances, food rations and valuables at a higher place in the house.',
          'Check local drainage outlets, secure outdoor items and monitor weather broadcasts.',
        ],
        tipsHi: [
          'प्रत्येक व्यक्ति के लिए टॉर्च, पीने का पानी, सूखा भोजन व जरूरी दस्तावेज तैयार रखें।',
          'पहचान पत्र, बीमा और मेडिकल पर्चे वाटरप्रूफ पाउच में संभाल कर रखें।',
          'सभी कीमती सामान, राशन और बिजली के उपकरण घर के ऊपरी तल पर रखें।',
          'घर के आसपास नालियों की जांच करें और आधिकारिक बाढ़ अलर्ट पर नजर रखें।',
        ],
      ),
      _DosPhaseInfo(
        badgeEn: 'During Floods & Evacuation',
        badgeHi: 'बाढ़ के दौरान सुरक्षा व बचाव',
        titleEn: 'During Floods',
        titleHi: 'बाढ़ के दौरान',
        tipsEn: [
          'Never walk, swim or drive through moving floodwaters (15 cm can knock you down).',
          'Switch off main electrical circuit breakers and gas connections before water enters.',
          'Stay away from damaged bridges, fallen poles and submerged electrical wires.',
          'If trapped in house, move to highest floor or roof and wave a bright cloth for rescue.',
        ],
        tipsHi: [
          'बहते बाढ़ के पानी में बिल्कुल न चलें, तैरें या गाड़ी न ले जाएं।',
          'पानी घर में घुसने से पहले मुख्य बिजली ब्रेकर और गैस कनेक्शन बंद करें।',
          'क्षतिग्रस्त पुलों, गिरे खंभों और डूबे बिजली तारों से कम से कम 10 मीटर दूर रहें।',
          'घर में फंसने पर छत पर जाएं और बचाव दल को संकेत देने के लिए चमकीला कपड़ा लहराएं।',
        ],
      ),
      _DosPhaseInfo(
        badgeEn: 'After Floods & Recovery',
        badgeHi: 'बाढ़ के बाद सुरक्षित वापसी',
        titleEn: 'After Floods',
        titleHi: 'बाढ़ के बाद',
        tipsEn: [
          'Do not drink tap or well water until verified safe; boil or filter all drinking water.',
          'Watch out for venomous snakes and reptiles taking shelter in dry rooms or furniture.',
          'Have an electrician inspect wiring before turning electrical power back on.',
          'Disinfect all submerged rooms and throw away contaminated perishable food items.',
        ],
        tipsHi: [
          'नल या कुएं का पानी बिना उबाले न पिएं; केवल उबला या शुद्ध पानी ही प्रयोग करें।',
          'सूखे कमरों और अलमारियों में छिपे सांपों और जहरीले कीटों से विशेष सावधान रहें।',
          'बिजली आपूर्ति बहाल करने से पहले प्रमाणित इलेक्ट्रीशियन से वायरिंग की जांच कराएं।',
          'बाढ़ के पानी से भीगे कमरों को कीटाणुरहित करें और दूषित भोजन नष्ट कर दें।',
        ],
      ),
    ],
  ),

  // 2. CYCLONE
  _DosDisasterInfo(
    id: 'cyclone',
    titleEn: 'Cyclone',
    titleHi: 'चक्रवात',
    bannerTitleEn: "Do's & Don'ts Before, During & After Cyclone",
    bannerTitleHi: 'चक्रवात: क्या करें और क्या न करें',
    bannerSubtitleEn: 'High-speed destructive winds. Stay indoors in secure rooms.',
    bannerSubtitleHi: 'अत्यंत तेज विनाशकारी हवाएं। सुरक्षित पक्के कमरों में रहें।',
    icon: Icons.cyclone_rounded,
    gradient: const [Color(0xFF047857), Color(0xFF10B981)],
    primaryColor: const Color(0xFF047857),
    imagePath: 'assets/images/cyclone_guide.jpg',
    phases: const [
      _DosPhaseInfo(
        badgeEn: 'Before Cyclone & Early Alert',
        badgeHi: 'चक्रवात से पहले तैयारी',
        titleEn: 'Before Cyclone',
        titleHi: 'चक्रवात से पहले',
        tipsEn: [
          'Ignore rumours, stay calm and listen to radio or TV for official IMD warnings.',
          'Keep mobile phones, emergency lamps and power banks fully charged.',
          'Trim dead overhanging tree branches near your house and secure loose roof sheets.',
          'Prepare an emergency survival kit with non-perishable food, water and first-aid.',
        ],
        tipsHi: [
          'अफवाहों पर ध्यान न दें, शांत रहें और मौसम विभाग (IMD) के बुलेटिन सुनें।',
          'मोबाइल फोन, इमरजेंसी लाइट और पावर बैंक को 100% चार्ज रखें।',
          'घर के पास सूखे पेड़ों की डालियां छांटें और टीन की छत को कसकर बांधें।',
          'सूखे खाद्य पदार्थ, पीने का पानी और प्राथमिक चिकित्सा किट पहले से तैयार रखें।',
        ],
      ),
      _DosPhaseInfo(
        badgeEn: 'During Cyclone & Landfall',
        badgeHi: 'चक्रवात के दौरान सुरक्षा',
        titleEn: 'During Cyclone',
        titleHi: 'चक्रवात के दौरान',
        tipsEn: [
          'Stay indoors away from glass windows; seek shelter in the strongest interior room.',
          'Disconnect all electrical and electronic appliances to avoid surge damage.',
          'Beware of the calm "eye" of the cyclone; ferocious winds will return abruptly.',
          'If outside, do not take shelter under trees, tin sheds or electrical lines.',
        ],
        tipsHi: [
          'खिड़कियों और कांच से दूर रहें; घर के सबसे मजबूत अंदरूनी कमरे में शरण लें।',
          'बिजली के सभी उपकरण सॉकेट से निकाल दें ताकि शॉर्ट सर्किट न हो।',
          'चक्रवात के शांत केंद्र (Eye) के दौरान बाहर न निकलें, तेज हवाएं फिर लौटेंगी।',
          'यदि बाहर हैं तो पेड़ों, टीन शेड या बिजली के खंभों के नीचे कभी आश्रय न लें।',
        ],
      ),
      _DosPhaseInfo(
        badgeEn: 'After Cyclone & Restoration',
        badgeHi: 'चक्रवात के बाद पुनर्बहाली',
        titleEn: 'After Cyclone',
        titleHi: 'चक्रवात के बाद',
        tipsEn: [
          'Remain in safe shelters until local authorities issue official "All Clear" notice.',
          'Beware of dangling power cables, broken glass and structurally loosened walls.',
          'Boil drinking water and thoroughly inspect stored food supplies before consuming.',
          'Report uprooted trees and road blockages immediately to emergency authorities.',
        ],
        tipsHi: [
          'जब तक प्रशासन आधिकारिक तौर पर सुरक्षित न कहे, आश्रय स्थल में ही रहें।',
          'लटकते बिजली तारों, टूटे कांच और कमजोर दीवारों से विशेष दूरी बनाए रखें।',
          'पीने के पानी को उबालें और खराब या गीले भोजन का सेवन न करें।',
          'गिरे पेड़ों और अवरुद्ध मार्गों की जानकारी तुरंत आपदा नियंत्रण कक्ष को दें।',
        ],
      ),
    ],
  ),

  // 3. LANDSLIDE
  _DosDisasterInfo(
    id: 'landslide',
    titleEn: 'Landslide',
    titleHi: 'भूस्खलन',
    bannerTitleEn: "Do's and Don'ts during Landslide",
    bannerTitleHi: 'भूस्खलन: क्या करें और क्या न करें',
    bannerSubtitleEn: 'Unstable hill slopes and mudslides. Move away from steep paths.',
    bannerSubtitleHi: 'पहाड़ी ढलानों पर मिट्टी का खिसकना। ढलान वाले रास्तों से दूर रहें।',
    icon: Icons.landscape_rounded,
    gradient: const [Color(0xFFC2410C), Color(0xFFEA580C)],
    primaryColor: const Color(0xFFC2410C),
    imagePath: 'assets/images/landslide_guide.jpg',
    phases: const [
      _DosPhaseInfo(
        badgeEn: 'Before Landslide & Early Warning',
        badgeHi: 'भूस्खलन से पहले चेतावनी संकेत',
        titleEn: 'Before Landslide',
        titleHi: 'भूस्खलन से पहले',
        tipsEn: [
          'Watch for warning signs: cracks in soil or pavement, tilting poles and leaning trees.',
          'Stay alert during intense continuous rainfall in hilly slopes and valleys.',
          'Know designated evacuation corridors leading to flat, stable high ground.',
          'Keep an emergency go-bag ready near your door with whistle, light and cash.',
        ],
        tipsHi: [
          'चेतावनी संकेतों पर नजर रखें: जमीन या दीवारों में दरारें, खंभों और पेड़ों का झुकना।',
          'पहाड़ी क्षेत्रों में लगातार मूसलाधार बारिश के समय अत्यंत सतर्क रहें।',
          'सुरक्षित समतल और मजबूत पठारी क्षेत्रों के आपातकालीन रास्तों की जानकारी रखें।',
          'सीटी, टॉर्च और नकदी के साथ जरूरी सामान का बैग दरवाजे के पास तैयार रखें।',
        ],
      ),
      _DosPhaseInfo(
        badgeEn: 'During Landslide & Mudflow',
        badgeHi: 'भूस्खलन के दौरान त्वरित बचाव',
        titleEn: 'During Landslide',
        titleHi: 'भूस्खलन के दौरान',
        tipsEn: [
          'Evacuate immediately upon hearing unusual rumbling sounds or crackling trees.',
          'Move perpendicular away from the debris flow path to higher stable ground.',
          'If escape is impossible, curl into a tight ball and protect your head with hands.',
          'Never cross bridges or narrow mountain bends that show visible cracks.',
        ],
        tipsHi: [
          'पत्थरों के गिरने या असामान्य गड़गड़ाहट की आवाज सुनते ही तुरंत सुरक्षित भागें।',
          'मलबे के बहाव की दिशा से दूर समकोण (perpendicular) पर ऊंचे स्थान की ओर जाएं।',
          'यदि भागना असंभव हो तो दोनों हाथों से सिर ढककर गेंद की तरह मुड़ जाएं।',
          'दरार वाले पहाड़ी पुलों या धंसी हुई सड़कों को पार करने की कोशिश न करें।',
        ],
      ),
      _DosPhaseInfo(
        badgeEn: 'After Landslide & Safety Check',
        badgeHi: 'भूस्खलन के बाद सुरक्षा जांच',
        titleEn: 'After Landslide',
        titleHi: 'भूस्खलन के बाद',
        tipsEn: [
          'Stay clear of the slide zone; secondary landslides and collapses frequently follow.',
          'Check for trapped or injured neighbours without stepping into unstable hazard zones.',
          'Inspect home utility connections for ruptured gas lines and exposed wiring.',
          'Listen to official disaster updates for road clearance before travelling.',
        ],
        tipsHi: [
          'भूस्खलन क्षेत्र से दूर रहें; पहले भूस्खलन के बाद दोबारा मलबा गिर सकता है।',
          'खतरे में पड़े बिना फंसे लोगों की मदद करें और बचाव दल को सूचित करें।',
          'गैस पाइपलाइनों, पानी के नलों और बिजली के तारों की क्षति की जांच करें।',
          'मार्ग साफ होने की आधिकारिक पुष्टि के बाद ही पहाड़ी रास्तों पर यात्रा करें।',
        ],
      ),
    ],
  ),

  // 4. LIGHTNING
  _DosDisasterInfo(
    id: 'lightning',
    titleEn: 'Lightning',
    titleHi: 'वज्रपात',
    bannerTitleEn: "Do's and Don'ts during Lightning",
    bannerTitleHi: 'आकाशीय बिजली: क्या करें और क्या न करें',
    bannerSubtitleEn: 'When thunder roars, go indoors. Seek safe shelter immediately.',
    bannerSubtitleHi: 'जब बिजली चमके और बादल गरजे, तुरंत पक्के मकान में जाएं।',
    icon: Icons.flash_on_rounded,
    gradient: const [Color(0xFF6D28D9), Color(0xFF9333EA)],
    primaryColor: const Color(0xFF6D28D9),
    imagePath: 'assets/images/lightning_guide.jpg',
    phases: const [
      _DosPhaseInfo(
        badgeEn: 'Before & Warning Signs',
        badgeHi: 'वज्रपात से पहले चेतावनी',
        titleEn: 'Before Lightning',
        titleHi: 'वज्रपात से पहले',
        tipsEn: [
          'Follow the 30-30 rule: seek shelter if thunder follows flash within 30s.',
          'Unplug computers, TVs, routers and non-essential electronic appliances.',
          'Bring outdoor pets and livestock into grounded, enclosed shelters.',
          'Avoid scheduling outdoor sports, farming or water activities during storm alerts.',
        ],
        tipsHi: [
          '30-30 नियम अपनाएं: बिजली चमकने के 30 सेकंड में गड़गड़ाहट हो तो सुरक्षित शरण लें।',
          'कंप्यूटर, टीवी और सभी इलेक्ट्रॉनिक उपकरणों के प्लग बिजली बोर्ड से निकालें।',
          'पालतू जानवरों और मवेशियों को खुले मैदान से सुरक्षित पक्के बाड़े में ले जाएं।',
          'आंधी-तूफान के अलर्ट के समय खुले खेतों, खेल मैदानों या जलाशयों में न जाएं।',
        ],
      ),
      _DosPhaseInfo(
        badgeEn: 'During Lightning & Storm',
        badgeHi: 'वज्रपात के दौरान सावधानी',
        titleEn: 'During Lightning',
        titleHi: 'वज्रपात के दौरान',
        tipsEn: [
          'Do not stand in a crowd or open fields; seek shelter in a concrete building.',
          "Don't take shelter under isolated trees, tin roofs or metal sheds.",
          "Don't touch indoor plumbing, metallic pipes, faucets or corded equipment.",
          'Stay away from power lines, wire fences, open hilltops and water bodies.',
        ],
        tipsHi: [
          'भीड़ में या खुले मैदान में खड़े न हों; पक्के कंक्रीट के मकान में आश्रय लें।',
          'ऊंचे पेड़ों, बिजली के खंभों, टीन शेड या टावरों के नीचे कभी शरण न लें।',
          'घर के अंदर नल, धातु के पाइप, धातु की खिड़कियां या वायर्ड फोन न छुएं।',
          'बिजली के तारों, लोहे की बाड़, खुले टीलों और पानी के स्रोतों से दूर रहें।',
        ],
      ),
      _DosPhaseInfo(
        badgeEn: 'After Lightning & First Aid',
        badgeHi: 'वज्रपात के बाद प्राथमिक उपचार',
        titleEn: 'After Lightning',
        titleHi: 'वज्रपात के बाद',
        tipsEn: [
          'Wait at least 30 minutes after hearing the last thunderclap before going outdoors.',
          'Check on affected companions; lightning strike victims carry NO electric charge.',
          'Perform immediate CPR if someone is unconscious and call 112 / 108 emergency.',
          'Report fallen electrical wires or spark fires immediately to authorities.',
        ],
        tipsHi: [
          'अंतिम गड़गड़ाहट के कम से कम 30 मिनट बाद ही घर से बाहर निकलें।',
          'बिजली गिरे व्यक्ति की जांच करें; उनके शरीर में करंट नहीं होता, तुरंत CPR दें।',
          'बेहोश व्यक्ति के लिए तुरंत सीपीआर शुरू करें और 112 / 108 पर कॉल करें।',
          'गिरे तारों, टूटे खंभों या आग की सूचना तुरंत आपातकालीन सेवा को दें।',
        ],
      ),
    ],
  ),
];

class CitizenDashboardScreen extends StatefulWidget {
  const CitizenDashboardScreen({super.key});

  @override
  State<CitizenDashboardScreen> createState() => _CitizenDashboardScreenState();
}

class _CitizenDashboardScreenState extends State<CitizenDashboardScreen> {
  // Navigation & Localization
  int _currentTab = 0;
  bool _isHindi = false;
  String _currentLocation = 'Shillong, Meghalaya';

  // Dynamic Safety State (Safe / Watch / Warning / Critical)
  CitizenThreatLevel _threatLevel = CitizenThreatLevel.safe;
  bool _isSosActive = false;
  int _activeAlertIndex = 0;
  double _alertMapZoom = 1.0;
  bool _alertMapSatellite = false;

  // Do's and Don'ts Carousel State (Auto-slides every 3.5s)
  int _dosDisasterIdx = 0; // 0: Flood, 1: Cyclone, 2: Landslide, 3: Lightning
  int _dosPhaseIdx = 0;    // 0: Before, 1: During, 2: After
  Timer? _dosAutoSlideTimer;

  // Map Controllers
  late final MapController _mapController;
  late final MapController _fullMapController;
  late final MapController _rainMapController;
  bool _showRainRadar = true;
  String _fullMapFilter = 'All';

  // Key Coordinates (Local Basin)
  final LatLng _userPos = const LatLng(23.7957, 86.4304);
  final LatLng _waypointPos = const LatLng(23.7990, 86.4340);
  final LatLng _shelterPos1 = const LatLng(23.8030, 86.4380);
  final LatLng _shelterPos2 = const LatLng(23.7920, 86.4250);
  final LatLng _hospitalPos = const LatLng(23.8060, 86.4220);
  final LatLng _roadBlockPos = const LatLng(23.7975, 86.4390);
  final LatLng _rescueTeamPos = const LatLng(23.8010, 86.4290);

  // Family Safety Data
  final List<Map<String, dynamic>> _familyMembers = [
    {'name': 'Father', 'nameHi': 'पिताजी', 'status': 'Safe', 'statusHi': 'सुरक्षित', 'icon': Icons.elderly_rounded, 'isSafe': true, 'time': 'Updated 5m ago'},
    {'name': 'Mother', 'nameHi': 'माताजी', 'status': 'Safe', 'statusHi': 'सुरक्षित', 'icon': Icons.face_3_rounded, 'isSafe': true, 'time': 'Updated 10m ago'},
    {'name': 'Brother', 'nameHi': 'भाई', 'status': 'Last seen 15 min ago', 'statusHi': '15 मिनट पहले देखा गया', 'icon': Icons.boy_rounded, 'isSafe': false, 'time': 'Last seen 15m ago'},
    {'name': 'Sister', 'nameHi': 'बहन', 'status': 'Safe', 'statusHi': 'सुरक्षित', 'icon': Icons.girl_rounded, 'isSafe': true, 'time': 'Updated 2m ago'},
  ];

  // Active Alerts List
  final List<Map<String, dynamic>> _activeAlerts = [
    {
      'title': 'Heavy Rainfall + Rising River Alert',
      'titleHi': 'भारी बारिश + नदी जलस्तर वृद्धि चेतावनी',
      'distance': '2.4 km from you',
      'distanceHi': 'आपसे 2.4 किमी दूर',
      'time': 'Updated 5 min ago',
      'timeHi': '5 मिनट पहले अपडेट',
      'impact': 'Low-lying areas may face flooding in the next 5–8 hours.',
      'impactHi': 'निचले क्षेत्रों में अगले 5–8 घंटों में बाढ़ की संभावना है।',
      'badge': 'FLOOD WARNING',
      'badgeHi': 'बाढ़ चेतावनी',
      'issued': 'Issued 2h ago',
      'issuedHi': '2 घंटे पहले जारी',
      'district': 'District: River Basin',
      'districtHi': 'जिला: नदी बेसिन',
      'riskLevel': 'Risk Level: High',
      'riskLevelHi': 'जोखिम: उच्च',
      'riskStep': 2,
      'color': const Color(0xFFDC2626),
    },
    {
      'title': 'High Water Discharge from Upstream Dam',
      'titleHi': 'बांध से अतिरिक्त पानी छोड़ा गया',
      'distance': '6.1 km upstream',
      'distanceHi': '6.1 किमी ऊपर की ओर',
      'time': 'Updated 18 min ago',
      'timeHi': '18 मिनट पहले अपडेट',
      'impact': 'River velocity elevated. Avoid low-ground causeways and riverbanks.',
      'impactHi': 'नदी की गति तेज है। पुल और नदी तट से दूर रहें।',
      'badge': 'DAM SURGE',
      'badgeHi': 'डैम सर्ज',
      'issued': 'Issued 45m ago',
      'issuedHi': '45 मिनट पहले जारी',
      'district': 'District: Upstream Valley',
      'districtHi': 'जिला: ऊपरी घाटी',
      'riskLevel': 'Risk Level: Moderate',
      'riskLevelHi': 'जोखिम: मध्यम',
      'riskStep': 1,
      'color': const Color(0xFFF39A20),
    },
    {
      'title': 'Severe Lightning & Thunderstorm Alert',
      'titleHi': 'भीषण आंधी-तूफान एवं वज्रपात चेतावनी',
      'distance': '1.2 km away • Basin Zone',
      'distanceHi': '1.2 किमी दूर • बेसिन क्षेत्र',
      'time': 'Updated 2 min ago',
      'timeHi': '2 मिनट पहले अपडेट',
      'impact': 'Stay indoors. Avoid open fields, tall trees and electrical poles.',
      'impactHi': 'घर के अंदर रहें। खुले मैदान, ऊंचे पेड़ और खंभों से दूर रहें।',
      'badge': 'THUNDERSTORM',
      'badgeHi': 'वज्रपात चेतावनी',
      'issued': 'Issued 30m ago',
      'issuedHi': '30 मिनट पहले जारी',
      'district': 'District: North Ridge',
      'districtHi': 'जिला: उत्तरी कटक',
      'riskLevel': 'Risk Level: High',
      'riskLevelHi': 'जोखिम: उच्च',
      'riskStep': 2,
      'color': const Color(0xFFD97706),
    },
    {
      'title': 'Bridge & Underpass Inundation Warning',
      'titleHi': 'पुलिया व अंडरपास जलभराव सूचना',
      'distance': '3.5 km away • Old Highway',
      'distanceHi': '3.5 किमी दूर • पुराना हाईवे',
      'time': 'Updated 12 min ago',
      'timeHi': '12 मिनट पहले अपडेट',
      'impact': 'Water height 2.5ft over causeway. Route blocked for light vehicles.',
      'impactHi': 'पुलिया पर 2.5 फीट पानी। हल्के वाहनों का आवागमन बंद।',
      'badge': 'ROAD BLOCKED',
      'badgeHi': 'मार्ग अवरुद्ध',
      'issued': 'Issued 1h ago',
      'issuedHi': '1 घंटा पहले जारी',
      'district': 'District: Highway Sector 4',
      'districtHi': 'जिला: हाईवे सेक्टर 4',
      'riskLevel': 'Risk Level: Critical',
      'riskLevelHi': 'जोखिम: गंभीर',
      'riskStep': 3,
      'color': const Color(0xFFDC2626),
    },
  ];

  // Notifications List
  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'Flood Warning for Sector 4 & 5',
      'body': 'Water level Damodar river reached 214.6m. Stay alert.',
      'type': 'Emergency',
      'time': '10 mins ago',
      'isRead': false,
    },
    {
      'title': 'Relief Shelter Open: Govt Senior Secondary',
      'body': 'Capacity 72% full. Clean food, drinking water & doctors available.',
      'type': 'Shelter',
      'time': '25 mins ago',
      'isRead': false,
    },
    {
      'title': 'Damodar River Bridge Closed',
      'body': 'Structural safety precaution. Use High Ridge bypass.',
      'type': 'Road',
      'time': '1 hour ago',
      'isRead': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _fullMapController = MapController();
    _rainMapController = MapController();
    if (!_isTestEnvironment()) {
      _startDosTimer();
    }
  }

  @override
  void dispose() {
    _dosAutoSlideTimer?.cancel();
    super.dispose();
  }

  bool _isTestEnvironment() {
    return WidgetsBinding.instance.runtimeType.toString().contains('Test');
  }

  void _startDosTimer() {
    _dosAutoSlideTimer?.cancel();
    if (_isTestEnvironment()) return;
    _dosAutoSlideTimer = Timer.periodic(const Duration(milliseconds: 4500), (_) {
      if (!mounted) return;
      _advanceDosSlide();
    });
  }

  void _advanceDosSlide() {
    setState(() {
      if (_dosPhaseIdx < 2) {
        _dosPhaseIdx++;
      } else {
        _dosPhaseIdx = 0;
        _dosDisasterIdx = (_dosDisasterIdx + 1) % _dosDisasterList.length;
      }
    });
  }

  void _prevDosSlide() {
    setState(() {
      if (_dosPhaseIdx > 0) {
        _dosPhaseIdx--;
      } else {
        _dosPhaseIdx = 2;
        _dosDisasterIdx = (_dosDisasterIdx - 1 + _dosDisasterList.length) % _dosDisasterList.length;
      }
    });
    _startDosTimer();
  }

  void _nextDosSlide() {
    _advanceDosSlide();
    _startDosTimer();
  }

  void _selectDosDisaster(int index) {
    setState(() {
      _dosDisasterIdx = index;
      _dosPhaseIdx = 0;
    });
    _startDosTimer();
  }

  void _selectDosPhase(int index) {
    setState(() {
      _dosPhaseIdx = index;
    });
    _startDosTimer();
  }

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

  // ==========================================================================
  // MAIN BUILD
  // ==========================================================================
  void _navigateToRoles() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _navigateToRoles();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFE9F4FB),
        appBar: _buildTopAppBar(),
        body: _buildCurrentTabBody(),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildCurrentTabBody() {
    switch (_currentTab) {
      case 0:
        return _buildHomeDashboardTab();
      case 1:
        return _buildFullMapTab();
      case 2:
        return CitizenAlertsView(isHindi: _isHindi);
      case 3:
        return _buildHelpHubTab();
      case 4:
        return _buildProfileTab();
      default:
        return _buildHomeDashboardTab();
    }
  }

  // ==========================================================================
  // 1. TOP APP BAR (Location + Notifications + Language + Profile)
  // ==========================================================================
  PreferredSizeWidget _buildTopAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      titleSpacing: 8,
      leadingWidth: 44,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A), size: 22),
        tooltip: _isHindi ? 'भूमिका चयन' : 'Back to Roles',
        onPressed: _navigateToRoles,
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ResQShield Logo with Pulse
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.shield_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'ResQShield',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _isHindi ? 'सतर्क रहें • सुरक्षित रहें • तैयार रहें' : 'Be Aware • Be Safe • Be Prepared',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Location Pill (Opens picker)
        InkWell(
          onTap: _showLocationPickerModal,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF2563EB)),
                const SizedBox(width: 3),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 95),
                  child: Text(
                    _currentLocation,
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 3),

        // Language Toggle
        GestureDetector(
          onTap: () {
            setState(() => _isHindi = !_isHindi);
            _showMessage(_isHindi ? 'भाषा बदली गई: हिंदी' : 'Language switched to English');
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Text(
              _isHindi ? 'EN' : 'हिं',
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 2),

        // Notifications Bell with Badge
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF1E293B), size: 21),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: _showNotificationsSheet,
              tooltip: _isHindi ? 'सूचनाएं' : 'Notifications',
            ),
            Positioned(
              right: 1,
              top: 5,
              child: Container(
                padding: const EdgeInsets.all(3.5),
                decoration: const BoxDecoration(
                  color: Color(0xFFDC2626),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${_notifications.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 4),

        // Profile Avatar Icon
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: GestureDetector(
            onTap: () => setState(() => _currentTab = 4),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Icon(Icons.person_rounded, size: 18, color: Color(0xFF2563EB)),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // TAB 0: HOME DASHBOARD (SCROLLABLE MAP + COMPLETE ACTION ORDER)
  // ==========================================================================
  Widget _buildHomeDashboardTab() {
    return Column(
      children: [
        // Offline Mesh Banner
        _buildOfflineBanner(),

        // Active SOS Banner (if SOS sent)
        if (_isSosActive) _buildActiveSosBanner(),

        // Scrollable Dashboard Content
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. TOP UNIFIED SAFETY STATUS & LIVE MAP CARD (Matches screenshot)
                _buildUnifiedSafetyMapCard(),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 2. QUICK ACTIONS (Exact screenshot design with SOS, Safe Route, Shelter, Medical + More services)
                      _buildQuickActionGrid(),

                      const SizedBox(height: 16),

                      // Simulation Chips (Allows testing all 4 states on demand)
                      _buildThreatLevelSimulatorChips(),

                      const SizedBox(height: 14),

                      // 3. ACTIVE EMERGENCY ALERT CARD
                      _buildActiveAlertCard(),

                      const SizedBox(height: 18),

                      // 5. NEAREST SAFE SHELTER CARD
                      _buildNearestSafeShelterCard(),

                      const SizedBox(height: 16),

                      // 6. FAMILY SAFETY CARD
                      _buildFamilySafetyCard(),

                      const SizedBox(height: 16),

                      // 7. LOCAL CONDITIONS (Clean & Non-Technical)
                      _buildLocalConditionsCard(),

                      const SizedBox(height: 16),

                      // 8. WEATHER & RAINFALL FORECAST
                      _buildWeatherForecastCard(),

                      const SizedBox(height: 16),

                      // 9. LOCAL ROAD CONDITIONS
                      _buildRoadStatusCard(),

                      const SizedBox(height: 16),

                      // 10. NEARBY MEDICAL / HOSPITAL HELP
                      _buildMedicalHelpCard(),

                      const SizedBox(height: 16),

                      // 11. DYNAMIC SAFETY INSTRUCTIONS ("What You Should Do")
                      _buildSafetyInstructionsCard(),

                      const SizedBox(height: 16),

                      // 12. EMERGENCY CONTACTS ROW
                      _buildEmergencyContactsRow(),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // OFFLINE BANNER
  // --------------------------------------------------------------------------
  Widget _buildOfflineBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF1B4D89),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4D89).withValues(alpha: 0.22),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.sensors_rounded, color: Color(0xFF38BDF8), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isHindi
                  ? 'ऑफलाइन सेफ्टी मोड • कैश्ड मैप, शेल्टर निर्देशांक व रेडियो सिंक'
                  : 'Offline Safety Mode • Cached map, shelter coordinates & radio sync',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded, color: Color(0xFFF87171), size: 15),
                const SizedBox(width: 5),
                Text(
                  _isHindi ? 'ऑफलाइन कार्यशील' : 'Works offline',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // ACTIVE SOS STATE BANNER
  // --------------------------------------------------------------------------
  Widget _buildActiveSosBanner() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFE92828),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.emergency_rounded, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isHindi ? '🚨 आपातकालीन SOS सक्रिय' : '🚨 EMERGENCY SOS ACTIVE',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                ),
                Text(
                  _isHindi
                      ? 'स्थान राहत दल से साझा किया गया • स्थिति: बचाव दल रवाना'
                      : 'GPS shared with Response Unit • Status: Rescue team dispatched',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() => _isSosActive = false);
              _showMessage(_isHindi ? 'SOS समाप्त किया गया' : 'SOS Cancelled');
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
            child: Text(
              _isHindi ? 'रद्द करें' : 'Resolve',
              style: const TextStyle(color: Color(0xFFE92828), fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }


  // --------------------------------------------------------------------------
  // 2. TOP UNIFIED SAFETY STATUS & LIVE MAP CARD (EXACT SCREENSHOT DESIGN)
  // --------------------------------------------------------------------------
  Widget _buildUnifiedSafetyMapCard() {
    Color cardBgColor;
    Color borderColor;
    Color badgeColor;
    Color badgeTextColor;
    String statusTitle;
    String statusDesc;
    IconData shieldIcon;

    switch (_threatLevel) {
      case CitizenThreatLevel.safe:
        cardBgColor = Colors.white;
        borderColor = const Color(0xFFD4EFE0);
        badgeColor = const Color(0xFFDCFCE7);
        badgeTextColor = const Color(0xFF065F46);
        statusTitle = _isHindi ? 'आप सुरक्षित हैं' : 'You are currently safe';
        statusDesc = _isHindi
            ? 'आपके क्षेत्र में कोई तात्कालिक खतरा नहीं'
            : 'No immediate threats in your area';
        shieldIcon = Icons.shield_rounded;
        break;

      case CitizenThreatLevel.watch:
        cardBgColor = Colors.white;
        borderColor = const Color(0xFFFDE047);
        badgeColor = const Color(0xFFFEF08A);
        badgeTextColor = const Color(0xFFB45309);
        statusTitle = _isHindi ? 'सतर्क रहें' : 'Stay alert & monitor';
        statusDesc = _isHindi
            ? 'जलस्तर बढ़ रहा है। तैयार रहें।'
            : 'Water levels rising. Keep essentials ready.';
        shieldIcon = Icons.visibility_rounded;
        break;

      case CitizenThreatLevel.warning:
        cardBgColor = Colors.white;
        borderColor = const Color(0xFFFDBA74);
        badgeColor = const Color(0xFFFFEDD5);
        badgeTextColor = const Color(0xFFC2410C);
        statusTitle = _isHindi ? 'निकासी की तैयारी' : 'Prepare to evacuate';
        statusDesc = _isHindi
            ? 'बाढ़ का खतरा बढ़ रहा है। मार्ग पहचानें।'
            : 'Flood risk increasing. Check safe route.';
        shieldIcon = Icons.warning_amber_rounded;
        break;

      case CitizenThreatLevel.evacuation:
        cardBgColor = Colors.white;
        borderColor = const Color(0xFFFCA5A5);
        badgeColor = const Color(0xFFFEE2E2);
        badgeTextColor = const Color(0xFFDC2626);
        statusTitle = _isHindi ? 'तुरंत सुरक्षित स्थान जाएं' : 'Evacuate immediately';
        statusDesc = _isHindi
            ? 'तत्काल राहत शिविर की ओर बढ़ें।'
            : 'Move to nearest shelter immediately.';
        shieldIcon = Icons.crisis_alert_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: badgeTextColor.withValues(alpha: 0.08),
            blurRadius: 18,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Stack(
          children: [
            // Background Watermark: Scenic Rolling Hills & Pine Trees (Matches Screenshot)
            Positioned.fill(
              child: CustomPaint(
                painter: _ScenicWatermarkPainter(
                  baseColor: badgeTextColor,
                ),
              ),
            ),

            // Card Foreground Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 600;

                  final leftContent = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top Row: Squircle / Circular Badge + STAY INFORMED + Main Title
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: badgeTextColor.withValues(alpha: 0.16),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(shieldIcon, color: badgeTextColor, size: 32),
                                if (_threatLevel == CitizenThreatLevel.safe)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: Icon(Icons.check_rounded, color: Colors.white, size: 16),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isHindi ? 'सतर्क रहें। सुरक्षित रहें।' : 'STAY INFORMED. STAY SAFE.',
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  statusTitle,
                                  style: TextStyle(
                                    color: badgeTextColor,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Location Pin + No Immediate Threat / Subtitle Block
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 1),
                            child: Icon(
                              Icons.location_on_rounded,
                              color: Color(0xFF1E3A8A),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  statusDesc,
                                  style: const TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _isHindi
                                      ? 'अपडेट रहें और आधिकारिक अलर्ट का पालन करें।'
                                      : 'Stay updated and follow official alerts.',
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Last Updated Pill Badge (FittedBox ensures zero overflow on any device or in tests)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF6EE7B7), width: 1.2),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                color: Color(0xFF059669),
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isHindi ? 'अंतिम अपडेट: 12 सितं 2026, 12:05 पूर्वाह्न' : 'Last updated: 12 Sep 2026, 12:05 AM',
                                style: const TextStyle(
                                  color: Color(0xFF065F46),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // "View live map →" Button
                      Container(
                        width: double.infinity,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0052CC),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0052CC).withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => setState(() => _currentTab = 1),
                            borderRadius: BorderRadius.circular(22),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.map_rounded, size: 18, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isHindi ? 'लाइव मैप देखें' : 'View live map',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );

                  final mapBox = GestureDetector(
                    onTap: () => setState(() => _currentTab = 1),
                    child: Container(
                      height: isWide ? 210 : 190,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: _buildSafetyLiveMiniMap(),
                      ),
                    ),
                  );

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(flex: 55, child: leftContent),
                        const SizedBox(width: 16),
                        Expanded(flex: 45, child: mapBox),
                      ],
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        leftContent,
                        const SizedBox(height: 14),
                        mapBox,
                      ],
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // LIVE MINI MAP (REAL FLUTTER_MAP FOR THE SAFETY CARD)
  // --------------------------------------------------------------------------
  Widget _buildSafetyLiveMiniMap() {
    return Stack(
      children: [
        // 1. Live FlutterMap with real OpenStreetMap tiles
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _userPos,
            initialZoom: 14.3,
            minZoom: 10.0,
            maxZoom: 18.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.resqshield.app',
              maxZoom: 19,
            ),
            // Concentric pulsing location circles
            CircleLayer(
              circles: [
                CircleMarker(
                  point: _userPos,
                  radius: 46,
                  useRadiusInMeter: false,
                  color: const Color(0xFF0066FF).withValues(alpha: 0.12),
                  borderColor: const Color(0xFF0066FF).withValues(alpha: 0.35),
                  borderStrokeWidth: 1.5,
                ),
                CircleMarker(
                  point: _userPos,
                  radius: 26,
                  useRadiusInMeter: false,
                  color: const Color(0xFF0066FF).withValues(alpha: 0.22),
                  borderColor: const Color(0xFF0066FF).withValues(alpha: 0.60),
                  borderStrokeWidth: 1.5,
                ),
              ],
            ),
            // Highlighted Route / Corridor Line
            PolylineLayer(
              polylines: [
                Polyline(
                  points: [_userPos, _waypointPos, _shelterPos1],
                  color: const Color(0xFFFDBA74).withValues(alpha: 0.85),
                  strokeWidth: 6.0,
                  borderColor: const Color(0xFFEA580C),
                  borderStrokeWidth: 1.2,
                ),
              ],
            ),
            // Markers
            MarkerLayer(
              markers: [
                // Red emergency checkpoint markers along roads (as seen in screenshot)
                Marker(
                  point: const LatLng(25.5825, 91.8890),
                  width: 20,
                  height: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.8),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 1)),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.add, color: Colors.white, size: 12),
                    ),
                  ),
                ),
                Marker(
                  point: const LatLng(25.5780, 91.8990),
                  width: 20,
                  height: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.8),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 1)),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.add, color: Colors.white, size: 12),
                    ),
                  ),
                ),
                Marker(
                  point: const LatLng(25.5745, 91.9045),
                  width: 20,
                  height: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.8),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 1)),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.add, color: Colors.white, size: 12),
                    ),
                  ),
                ),
                // Secondary Shelter Marker
                Marker(
                  point: _shelterPos2,
                  width: 20,
                  height: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.8),
                    ),
                    child: const Icon(
                      Icons.night_shelter_rounded,
                      color: Colors.white,
                      size: 11,
                    ),
                  ),
                ),
                // Rescue Team Pin
                Marker(
                  point: _rescueTeamPos,
                  width: 20,
                  height: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.8),
                    ),
                    child: const Icon(
                      Icons.support_rounded,
                      color: Colors.white,
                      size: 11,
                    ),
                  ),
                ),
                // Citizen Current Location Pin (Pulsing center blue dot with white ring)
                Marker(
                  point: _userPos,
                  width: 24,
                  height: 24,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0066FF),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        // 2. Top-Left Floating Badge: "• Live Map (Offline)"
        Positioned(
          top: 10,
          left: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF16A34A),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _isHindi ? 'लाइव मैप (ऑफलाइन)' : 'Live Map (Offline)',
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 3. Bottom-Left Floating Badge: "• Your location"
        Positioned(
          bottom: 10,
          left: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0066FF),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _isHindi ? 'आपकी स्थिति' : 'Your location',
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 4. Right-Side Floating Map Controls (Layers, Zoom In/Out, Locate)
        Positioned(
          top: 10,
          right: 8,
          bottom: 10,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Layers Button
              Material(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(8),
                elevation: 2,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    _showMessage(_isHindi ? 'मैप लेयर स्विच की गई' : 'Map layers toggled');
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.layers_rounded, size: 18, color: Color(0xFF334155)),
                        SizedBox(height: 1),
                        Text(
                          'Layers',
                          style: TextStyle(
                            fontSize: 7.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Zoom In / Out Pill
              Material(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(8),
                elevation: 2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      onTap: () {
                        final currentZoom = _mapController.camera.zoom;
                        _mapController.move(_mapController.camera.center, (currentZoom + 1).clamp(10.0, 18.0));
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                        child: Icon(Icons.add, size: 16, color: Color(0xFF334155)),
                      ),
                    ),
                    Container(width: 20, height: 1, color: Colors.black12),
                    InkWell(
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                      onTap: () {
                        final currentZoom = _mapController.camera.zoom;
                        _mapController.move(_mapController.camera.center, (currentZoom - 1).clamp(10.0, 18.0));
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                        child: Icon(Icons.remove, size: 16, color: Color(0xFF334155)),
                      ),
                    ),
                  ],
                ),
              ),

              // Re-center / Locate Arrow Button
              Material(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(8),
                elevation: 2,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    _mapController.move(_userPos, 14.5);
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(7),
                    child: Icon(Icons.near_me_rounded, size: 16, color: Color(0xFF334155)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showMoreServicesModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _isHindi ? 'सभी सेवाएं' : 'All Citizen Services',
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFF5F3FF),
                    child: Icon(Icons.groups_rounded, color: Color(0xFF7C3AED)),
                  ),
                  title: Text(_isHindi ? 'परिवार सुरक्षा' : 'Family Safety'),
                  subtitle: Text(_isHindi ? 'परिवार को ट्रैक करें' : 'Track and connect with family members'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {
                    Navigator.pop(context);
                    _showFamilySafetyModal();
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFF7ED),
                    child: Icon(Icons.camera_alt_rounded, color: Color(0xFFEA580C)),
                  ),
                  title: Text(_isHindi ? 'आपदा रिपोर्ट' : 'Hazard Report'),
                  subtitle: Text(_isHindi ? 'घटनाओं या खतरों की रिपोर्ट करें' : 'Submit photo and report hazards'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CitizenHazardReportView(isHindi: _isHindi)),
                    );
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEFF6FF),
                    child: Icon(Icons.map_rounded, color: Color(0xFF2563EB)),
                  ),
                  title: Text(_isHindi ? 'पूर्ण लाइव मैप' : 'Full Interactive Map'),
                  subtitle: Text(_isHindi ? 'सभी शेल्टर और रिलीफ कैंप देखें' : 'View full evacuation corridors & relief zones'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _currentTab = 1);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Simulator chips so user/evaluator can easily test all 4 states
  Widget _buildThreatLevelSimulatorChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD6E8F7)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Text(
              _isHindi ? 'स्थिति सिमुलेशन:' : 'Simulate:',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF537392)),
            ),
            const SizedBox(width: 8),
            _buildSimChip('🟢 Safe', CitizenThreatLevel.safe),
            const SizedBox(width: 6),
            _buildSimChip('🟡 Watch', CitizenThreatLevel.watch),
            const SizedBox(width: 6),
            _buildSimChip('🟠 Warning', CitizenThreatLevel.warning),
            const SizedBox(width: 6),
            _buildSimChip('🔴 Evac', CitizenThreatLevel.evacuation),
          ],
        ),
      ),
    );
  }

  Widget _buildSimChip(String label, CitizenThreatLevel level) {
    final isSelected = _threatLevel == level;
    return GestureDetector(
      onTap: () => setState(() => _threatLevel = level),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF013973) : const Color(0xFFF3F8FD),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.white : const Color(0xFF013973),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 3. ACTIVE EMERGENCY ALERT CARD (EXACT SCREENSHOT REDESIGN)
  // --------------------------------------------------------------------------
  Widget _buildActiveAlertCard() {
    final alert = _activeAlerts[_activeAlertIndex];
    final Color alertColor = alert['color'] as Color? ?? const Color(0xFFDC2626);
    final int activeRiskStep = alert['riskStep'] as int? ?? 2;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFFFD1D5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: alertColor.withValues(alpha: 0.05),
            blurRadius: 18,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 760;

          // Red Alert Circular Badge with glowing halo + small red indicator dot
          Widget alertBadge = Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.20),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x33DC2626),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 22),
                ),
              ),
              Positioned(
                top: 1,
                right: 1,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          );

          // Middle Alert Information: Badge, Title, Subtitle, Chips
          Widget middleInfo = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Red Pill Badge (FLOOD WARNING)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.waves_rounded, color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      _isHindi ? (alert['badgeHi'] ?? 'बाढ़ चेतावनी') : (alert['badge'] ?? 'FLOOD WARNING'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // Title
              Text(
                _isHindi ? alert['titleHi'] : (alert['title'] ?? 'Heavy Rainfall + Rising River Alert'),
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // Subtitle / Impact description
              Text(
                _isHindi ? alert['impactHi'] : (alert['impact'] ?? 'Low-lying areas may face flooding in the next 5–8 hours.'),
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Metadata tags: Issued, District, Risk Level
              Wrap(
                spacing: 6,
                runSpacing: 5,
                children: [
                  _buildAlertTag(
                    icon: Icons.access_time_rounded,
                    text: _isHindi ? (alert['issuedHi'] ?? '2 घंटे पहले जारी') : (alert['issued'] ?? 'Issued 2h ago'),
                    bgColor: const Color(0xFFEFF6FF),
                    borderColor: const Color(0xFFDBEAFE),
                    textColor: const Color(0xFF1D4ED8),
                  ),
                  _buildAlertTag(
                    icon: Icons.location_on_rounded,
                    text: _isHindi ? (alert['districtHi'] ?? 'जिला: नदी बेसिन') : (alert['district'] ?? 'District: River Basin'),
                    bgColor: const Color(0xFFEFF6FF),
                    borderColor: const Color(0xFFDBEAFE),
                    textColor: const Color(0xFF1D4ED8),
                  ),
                  _buildAlertTag(
                    icon: Icons.tune_rounded,
                    text: _isHindi ? (alert['riskLevelHi'] ?? 'जोखिम: उच्च') : (alert['riskLevel'] ?? 'Risk Level: High'),
                    bgColor: const Color(0xFFFEF2F2),
                    borderColor: const Color(0xFFFEE2E2),
                    textColor: const Color(0xFFDC2626),
                  ),
                ],
              ),
            ],
          );

          // Switcher Capsule < 1 of 4 >
          Widget switcherCapsule = Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      _activeAlertIndex = (_activeAlertIndex - 1 + _activeAlerts.length) % _activeAlerts.length;
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.chevron_left_rounded, size: 16, color: Color(0xFF475569)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '${_activeAlertIndex + 1} of ${_activeAlerts.length}',
                    style: const TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      _activeAlertIndex = (_activeAlertIndex + 1) % _activeAlerts.length;
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF475569)),
                  ),
                ),
              ],
            ),
          );

          // Risk Level Gauge (Safe, Low Risk, High Risk, Danger)
          Widget riskMeter = _buildAlertRiskMeter(activeRiskStep);

          // Action Buttons: View Alert → (Solid Blue) and Safety Instructions > (Outlined Blue)
          Widget actionButtons = Row(
            children: [
              // View Alert Button (Expanded Width)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _currentTab = 2),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066EE),
                    foregroundColor: Colors.white,
                    elevation: 1.5,
                    minimumSize: const Size.fromHeight(48),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  icon: const Icon(Icons.visibility_rounded, size: 16, color: Colors.white),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _isHindi ? 'अलर्ट देखें →' : 'View Alert →',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Safety Instructions Button (Expanded Width)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showSafetyInstructionsModal,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0066EE),
                    side: const BorderSide(color: Color(0xFF0066EE), width: 1.5),
                    minimumSize: const Size.fromHeight(48),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  icon: const Icon(Icons.shield_outlined, size: 16, color: Color(0xFF0066EE)),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _isHindi ? 'सुरक्षा निर्देश >' : 'Safety Instructions >',
                      style: const TextStyle(
                        color: Color(0xFF0066EE),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );

          // Full right-side Map widget
          Widget fullMap = _buildFullAlertMap(context, height: isWide ? 235 : 210);

          return Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: isWide
                ? IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left Section: Aligned to stretch so actionButtons sit right at the bottom
                        Expanded(
                          flex: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      alertBadge,
                                      const SizedBox(width: 14),
                                      Expanded(child: middleInfo),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  riskMeter,
                                ],
                              ),
                              const SizedBox(height: 24),
                              actionButtons,
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Right Section: Switcher on top, Map below filling remaining space
                        Expanded(
                          flex: 11,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              switcherCapsule,
                              const SizedBox(height: 10),
                              fullMap,
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          alertBadge,
                          switcherCapsule,
                        ],
                      ),
                      const SizedBox(height: 12),
                      middleInfo,
                      const SizedBox(height: 16),
                      riskMeter,
                      const SizedBox(height: 18),
                      fullMap,
                      const SizedBox(height: 20),
                      actionButtons,
                    ],
                  ),
          );
        },
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 4-STEP RISK LEVEL GAUGE (Safe, Low Risk, High Risk, Danger)
  // --------------------------------------------------------------------------
  Widget _buildAlertRiskMeter(int activeStep) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Segmented Track Line running horizontally through circle centers
          Positioned(
            top: 12,
            left: 20,
            right: 20,
            child: Row(
              children: [
                // Segment 1: Safe -> Low Risk (Green to Amber)
                Expanded(
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: const Color(0xFFA7F3D0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Segment 2: Low Risk -> High Risk (Amber to Light Red)
                Expanded(
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDE68A),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Segment 3: High Risk -> Danger (Light Red)
                Expanded(
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFECACA),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 4 Interactive / Informational Nodes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildRiskNode(
                index: 0,
                label: _isHindi ? 'सुरक्षित' : 'Safe',
                color: const Color(0xFF16A34A),
                isActive: activeStep == 0,
              ),
              _buildRiskNode(
                index: 1,
                label: _isHindi ? 'कम जोखिम' : 'Low Risk',
                color: const Color(0xFFEAB308),
                isActive: activeStep == 1,
              ),
              _buildRiskNode(
                index: 2,
                label: _isHindi ? 'उच्च जोखिम' : 'High Risk',
                color: const Color(0xFFEF4444),
                isActive: activeStep == 2,
              ),
              _buildRiskNode(
                index: 3,
                label: _isHindi ? 'खतरा' : 'Danger',
                color: const Color(0xFF991B1B),
                isActive: activeStep == 3,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiskNode({
    required int index,
    required String label,
    required Color color,
    required bool isActive,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          child: isActive
              ? Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.22),
                    border: Border.all(
                      color: color.withValues(alpha: 0.50),
                      width: 1.2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                  ),
                )
              : Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            color: isActive
                ? (color == const Color(0xFFEF4444) ? const Color(0xFFDC2626) : color)
                : const Color(0xFF334155),
            fontSize: 11.5,
            fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // FULL RIGHT-SIDE ALERT MAP (WITH TERRAIN, RIVER, RADAR, CONTROLS)
  // --------------------------------------------------------------------------
  Widget _buildFullAlertMap(BuildContext context, {required double height}) {
    String scaleText;
    if (_alertMapZoom >= 2.0) {
      scaleText = '500 m';
    } else if (_alertMapZoom >= 1.5) {
      scaleText = '1 km';
    } else if (_alertMapZoom >= 1.2) {
      scaleText = '1.5 km';
    } else if (_alertMapZoom >= 0.9) {
      scaleText = '2 km';
    } else {
      scaleText = '3 km';
    }

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBAE6FD), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            // 1. Real Detailed FlutterMap with OpenStreetMap Tiles & Doppler Radar
            Positioned.fill(
              child: FlutterMap(
                mapController: _rainMapController,
                options: const MapOptions(
                  initialCenter: LatLng(25.5788, 91.8933),
                  initialZoom: 12.2,
                  interactionOptions: InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: _alertMapSatellite
                        ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.resqshield.app',
                  ),

                  // Doppler Rain & River Flood Radar Circles
                  if (_showRainRadar)
                    CircleLayer(
                      circles: [
                        // Broad precipitation cloud
                        CircleMarker(
                          point: const LatLng(25.5850, 91.8900),
                          radius: 4500,
                          useRadiusInMeter: true,
                          color: const Color(0xFF0284C7).withValues(alpha: 0.22),
                          borderColor: const Color(0xFF0284C7).withValues(alpha: 0.55),
                          borderStrokeWidth: 1.5,
                        ),
                        // Intense river basin flood cell
                        CircleMarker(
                          point: const LatLng(25.5720, 91.9050),
                          radius: 2600,
                          useRadiusInMeter: true,
                          color: const Color(0xFFDC2626).withValues(alpha: 0.28),
                          borderColor: const Color(0xFFDC2626).withValues(alpha: 0.65),
                          borderStrokeWidth: 2.0,
                        ),
                        // Moderate rain area
                        CircleMarker(
                          point: const LatLng(25.5600, 91.8700),
                          radius: 3500,
                          useRadiusInMeter: true,
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
                          borderColor: const Color(0xFF0284C7).withValues(alpha: 0.45),
                          borderStrokeWidth: 1.5,
                        ),
                      ],
                    ),

                  // Telemetry & Alert Location Markers
                  MarkerLayer(
                    markers: [
                      // Damodar River Alert Marker
                      Marker(
                        point: const LatLng(25.5720, 91.9050),
                        width: 146,
                        height: 34,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white, width: 1.5),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                            ],
                          ),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.waves_rounded, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Damodar: 214.6m [High]',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Cloudburst 68 mm/h Pin
                      Marker(
                        point: const LatLng(25.5620, 91.8820),
                        width: 96,
                        height: 28,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F2D59),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF38BDF8), width: 1.2),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                          ),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.thunderstorm_rounded, color: Color(0xFF38BDF8), size: 13),
                                SizedBox(width: 3),
                                Text(
                                  '68 mm/h',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // User Location Marker
                      Marker(
                        point: const LatLng(25.5788, 91.8933),
                        width: 22,
                        height: 22,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF2563EB),
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. Top-Left: Live Doppler Radar Badge
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.7), width: 1),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isHindi ? 'लाइव डॉपलर रडार' : 'LIVE DOPPLER RADAR',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Floating Bottom-Left: • Your location
            Positioned(
              left: 10,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
                  boxShadow: const [
                    BoxShadow(color: Color(0x12000000), blurRadius: 5, offset: Offset(0, 1)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF2563EB)),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _isHindi ? 'आपकी स्थिति' : 'Your location',
                      style: const TextStyle(color: Color(0xFF1E293B), fontSize: 10.5, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),

            // 4. Floating Top-Right Control Toolbar: Layers, Zoom In (+), Zoom Out (-), Radar Toggle, Recenter
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
                  boxShadow: const [
                    BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Layers toggle
                    InkWell(
                      onTap: () => setState(() => _alertMapSatellite = !_alertMapSatellite),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                        child: Column(
                          children: [
                            Icon(
                              _alertMapSatellite ? Icons.layers : Icons.layers_outlined,
                              size: 15,
                              color: _alertMapSatellite ? const Color(0xFF2563EB) : const Color(0xFF475569),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              _isHindi ? 'परतें' : 'Layers',
                              style: TextStyle(
                                fontSize: 8.0,
                                color: _alertMapSatellite ? const Color(0xFF2563EB) : const Color(0xFF475569),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(height: 1, width: 28, color: const Color(0xFFF1F5F9)),

                    // Zoom In (+)
                    InkWell(
                      key: const Key('alert_map_zoom_in'),
                      onTap: () {
                        setState(() {
                          _alertMapZoom = (_alertMapZoom + 0.25).clamp(0.75, 2.5);
                        });
                        try {
                          final currentZoom = _rainMapController.camera.zoom;
                          _rainMapController.move(_rainMapController.camera.center, currentZoom + 1.0);
                        } catch (_) {}
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.add, size: 16, color: Color(0xFF0F2D59)),
                      ),
                    ),
                    Container(height: 1, width: 28, color: const Color(0xFFF1F5F9)),

                    // Zoom Out (-)
                    InkWell(
                      key: const Key('alert_map_zoom_out'),
                      onTap: () {
                        setState(() {
                          _alertMapZoom = (_alertMapZoom - 0.25).clamp(0.75, 2.5);
                        });
                        try {
                          final currentZoom = _rainMapController.camera.zoom;
                          _rainMapController.move(_rainMapController.camera.center, currentZoom - 1.0);
                        } catch (_) {}
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.remove, size: 16, color: Color(0xFF0F2D59)),
                      ),
                    ),
                    Container(height: 1, width: 28, color: const Color(0xFFF1F5F9)),

                    // Radar Toggle
                    InkWell(
                      key: const Key('rain_map_radar_toggle'),
                      onTap: () => setState(() => _showRainRadar = !_showRainRadar),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.radar_rounded,
                          size: 16,
                          color: _showRainRadar ? const Color(0xFF0284C7) : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                    Container(height: 1, width: 28, color: const Color(0xFFF1F5F9)),

                    // Recenter / Navigation
                    InkWell(
                      key: const Key('rain_map_recenter'),
                      onTap: () {
                        setState(() {
                          _alertMapZoom = 1.0;
                        });
                        try {
                          _rainMapController.move(const LatLng(25.5788, 91.8933), 12.2);
                        } catch (_) {}
                      },
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.my_location_rounded, size: 15, color: Color(0xFF0F2D59)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 5. Floating Bottom-Right Scale Indicator: |____| scaleText
            Positioned(
              right: 10,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.90),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 4,
                      decoration: const BoxDecoration(
                        border: Border(
                          left: BorderSide(color: Color(0xFF334155), width: 1.5),
                          bottom: BorderSide(color: Color(0xFF334155), width: 1.5),
                          right: BorderSide(color: Color(0xFF334155), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      scaleText,
                      style: const TextStyle(
                        color: Color(0xFF334155),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertTag({
    required IconData icon,
    required String text,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: textColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 4. QUICK ACTIONS (EXACT SCREENSHOT DESIGN)
  // --------------------------------------------------------------------------
  Widget _buildQuickActionGrid() {
    final List<_QuickActionItem> items = [
      _QuickActionItem(
        title: _isHindi ? 'एसओएस' : 'SOS',
        subtitle: _isHindi
            ? 'स्थान के साथ आपातकालीन अलर्ट भेजें'
            : 'Send emergency alert with your location',
        icon: Icons.emergency_rounded,
        accentColor: const Color(0xFFEF4444),
        cardBgColor: const Color(0xFFFFF7F7),
        borderColor: const Color(0xFFFFE0E0),
        iconCircleColor: const Color(0xFFFFE5E5),
        watermarkIcon: Icons.crisis_alert_rounded,
        onTap: _showSosConfirmationDialog,
      ),
      _QuickActionItem(
        title: _isHindi ? 'सुरक्षित मार्ग' : 'Safe Route',
        subtitle: _isHindi
            ? 'गंतव्य हेतु सबसे सुरक्षित मार्ग खोजें'
            : 'Find safest route to your destination',
        icon: Icons.near_me_rounded,
        accentColor: const Color(0xFF2563EB),
        cardBgColor: const Color(0xFFF3F8FE),
        borderColor: const Color(0xFFD6E8FC),
        iconCircleColor: const Color(0xFFDFEFFF),
        watermarkIcon: Icons.alt_route_rounded,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CitizenSafeRouteView(isHindi: _isHindi)),
          );
        },
      ),
      _QuickActionItem(
        title: _isHindi ? 'आश्रय स्थल' : 'Shelter',
        subtitle: _isHindi
            ? 'पास के सुरक्षित राहत शिविर खोजें'
            : 'Find nearby safe shelters & relief centers',
        icon: Icons.home_rounded,
        accentColor: const Color(0xFF10B981),
        cardBgColor: const Color(0xFFF2FAF5),
        borderColor: const Color(0xFFD3F2E2),
        iconCircleColor: const Color(0xFFDCF6E7),
        watermarkIcon: Icons.holiday_village_rounded,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CitizenSheltersView(isHindi: _isHindi)),
          );
        },
      ),
      _QuickActionItem(
        title: _isHindi ? 'चिकित्सा' : 'Medical',
        subtitle: _isHindi
            ? 'अस्पताल, क्लीनिक व चिकित्सा सहायता खोजें'
            : 'Locate hospitals, clinics & medical help',
        icon: Icons.add_box_rounded,
        accentColor: const Color(0xFF8B5CF6),
        cardBgColor: const Color(0xFFF8F5FE),
        borderColor: const Color(0xFFE9E0FD),
        iconCircleColor: const Color(0xFFEDE4FD),
        watermarkIcon: Icons.favorite_rounded,
        onTap: _showMedicalDetailsModal,
      ),
      _QuickActionItem(
        title: _isHindi ? 'परिवार' : 'Family',
        subtitle: _isHindi
            ? 'परिवार की सुरक्षा ट्रैक करें और जुड़े रहें'
            : 'Track and stay connected with family',
        icon: Icons.groups_rounded,
        accentColor: const Color(0xFF7C3AED),
        cardBgColor: const Color(0xFFF5F3FF),
        borderColor: const Color(0xFFEDE9FE),
        iconCircleColor: const Color(0xFFEDE4FD),
        watermarkIcon: Icons.people_outline_rounded,
        onTap: _showFamilySafetyModal,
      ),
      _QuickActionItem(
        title: _isHindi ? 'रिपोर्ट' : 'Report',
        subtitle: _isHindi
            ? 'घटनाओं या खतरों की तुरंत रिपोर्ट करें'
            : 'Report incidents, hazards or emergencies',
        icon: Icons.camera_alt_rounded,
        accentColor: const Color(0xFFEA580C),
        cardBgColor: const Color(0xFFFFF7ED),
        borderColor: const Color(0xFFFFEDD5),
        iconCircleColor: const Color(0xFFFFEDD5),
        watermarkIcon: Icons.warning_amber_rounded,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CitizenHazardReportView(isHindi: _isHindi)),
          );
        },
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row with lightning icon + title + subtitle + More services
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lightning bolt icon
            Container(
              margin: const EdgeInsets.only(top: 2),
              child: const Icon(
                Icons.bolt_rounded,
                color: Color(0xFF1565C0),
                size: 22,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isHindi ? 'त्वरित कार्य' : 'Quick Actions',
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isHindi
                        ? 'सहायता प्राप्त करें, सुरक्षा पाएं और तुरंत जानकारी पाएं।'
                        : 'Get help, find safety and stay informed — fast.',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: _showMoreServicesModal,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isHindi ? 'अधिक सेवाएं' : 'More services',
                      style: const TextStyle(
                        color: Color(0xFF1565C0),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Color(0xFF1565C0),
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            // Full width expansion across all 6 cards
            if (constraints.maxWidth >= 720) {
              // 6 cards in a single row spanning full screen width equally
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int i = 0; i < items.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(child: _buildQuickActionCard(items[i])),
                    ],
                  ],
                ),
              );
            } else if (constraints.maxWidth >= 420) {
              // 3 columns x 2 rows spanning full screen width equally
              return Column(
                children: [
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (int i = 0; i < 3; i++) ...[
                          if (i > 0) const SizedBox(width: 10),
                          Expanded(child: _buildQuickActionCard(items[i])),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (int i = 3; i < 6; i++) ...[
                          if (i > 3) const SizedBox(width: 10),
                          Expanded(child: _buildQuickActionCard(items[i])),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            } else {
              // 2 columns x 3 rows spanning full screen width equally
              return Column(
                children: [
                  for (int row = 0; row < 3; row++) ...[
                    if (row > 0) const SizedBox(height: 10),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _buildQuickActionCard(items[row * 2])),
                          const SizedBox(width: 10),
                          Expanded(child: _buildQuickActionCard(items[row * 2 + 1])),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(_QuickActionItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: item.onTap,
            borderRadius: BorderRadius.circular(20),
            splashColor: item.accentColor.withValues(alpha: 0.08),
            highlightColor: item.accentColor.withValues(alpha: 0.04),
            child: Stack(
              children: [
                // Organic curved background shape in top-right corner
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CardCornerWavePainter(
                      color: item.accentColor.withValues(alpha: 0.08),
                    ),
                  ),
                ),

                // Thick solid accent vertical line along the left border
                Positioned(
                  left: 0,
                  top: 14,
                  bottom: 14,
                  child: Container(
                    width: 4.0,
                    decoration: BoxDecoration(
                      color: item.accentColor,
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(3)),
                    ),
                  ),
                ),

                // Card Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top-left circular icon with soft accent tint
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: item.iconCircleColor,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          item.icon,
                          color: item.accentColor,
                          size: 23,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            item.title,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // Subtitle
                          Text(
                            item.subtitle,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11.5,
                              height: 1.3,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          // Bottom row: "✱ Quick Access" pill on left + circular arrow button on right
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: item.accentColor.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '✱',
                                        style: TextStyle(
                                          color: item.accentColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          _isHindi ? 'त्वरित पहुंच' : 'Quick Access',
                                          style: TextStyle(
                                            color: item.accentColor,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.1,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Circular arrow button on right
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: item.accentColor.withValues(alpha: 0.10),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.arrow_forward_rounded,
                                  color: item.accentColor,
                                  size: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // --------------------------------------------------------------------------
  // 5. NEAREST SAFE SHELTER & GOVT RELIEF CENTER CARD
  // --------------------------------------------------------------------------
  Widget _buildNearestSafeShelterCard() {
    const accentColor = Color(0xFF10B981); // Emerald green for safe shelter

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Icon + Badge & Titles + Live Open Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shelter Home Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F4EA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.home_rounded,
                  color: Color(0xFF15945C),
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // NEAREST SAFE SHELTER Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _isHindi ? 'नजदीकी सुरक्षित शिविर' : 'NEAREST SAFE SHELTER',
                        style: const TextStyle(
                          color: Color(0xFF15803D),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isHindi ? 'सरकारी राहत केंद्र' : 'Government Relief Centre',
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isHindi
                          ? 'सुरक्षित, स्वच्छ और आवश्यक सेवाओं से युक्त राहत केंद्र।'
                          : 'Safe, clean and fully equipped shelter with essential services.',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Live Open Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _isHindi ? 'खुला है' : 'OPEN',
                      style: const TextStyle(
                        color: Color(0xFF065F46),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Distance, Location & Occupancy Row
          Wrap(
            spacing: 12,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_rounded, size: 15, color: Color(0xFF007AEB)),
                  const SizedBox(width: 4),
                  Text(
                    _isHindi ? '3.4 किमी दूर • सेक्टर 5' : '3.4 km away • Sector 5',
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people_alt_rounded, size: 15, color: Color(0xFF007AEB)),
                  const SizedBox(width: 4),
                  Text(
                    _isHindi ? '312 / 500 व्यक्ति (62%)' : '312 / 500 people (62%)',
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Capacity (60% width) + Food, Water, Medical, Power in 4 equal widths (40% width)
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = constraints.maxWidth;
              final isWide = cardWidth >= 700;

              final capacityWidget = Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.groups_rounded, size: 18, color: Color(0xFF007AEB)),
                    const SizedBox(width: 6),
                    Text(
                      _isHindi ? 'क्षमता' : 'Capacity',
                      style: const TextStyle(
                        color: Color(0xFF0F2642),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: const LinearProgressIndicator(
                          value: 0.62,
                          minHeight: 14,
                          backgroundColor: Color(0xFFE2E8F0),
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '62%',
                      style: TextStyle(
                        color: Color(0xFF0F2642),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              );

              final supplyChips = [
                _buildShelterSupplyChip(
                  icon: Icons.restaurant_rounded,
                  iconBgColor: const Color(0xFFFEF3C7),
                  iconColor: const Color(0xFFD97706),
                  title: _isHindi ? 'भोजन' : 'Food',
                  status: _isHindi ? 'उपलब्ध' : 'Available',
                  onTap: _showShelterDetailsModal,
                ),
                _buildShelterSupplyChip(
                  icon: Icons.water_drop_rounded,
                  iconBgColor: const Color(0xFFE0F2FE),
                  iconColor: const Color(0xFF0284C7),
                  title: _isHindi ? 'जल' : 'Water',
                  status: _isHindi ? 'उपलब्ध' : 'Available',
                  onTap: _showShelterDetailsModal,
                ),
                _buildShelterSupplyChip(
                  icon: Icons.add_circle_rounded,
                  iconBgColor: const Color(0xFFFEE2E2),
                  iconColor: const Color(0xFFEF4444),
                  title: _isHindi ? 'चिकित्सा' : 'Medical',
                  status: _isHindi ? 'उपलब्ध' : 'Available',
                  onTap: _showShelterDetailsModal,
                ),
                _buildShelterSupplyChip(
                  icon: Icons.bolt_rounded,
                  iconBgColor: const Color(0xFFF3E8FF),
                  iconColor: const Color(0xFF9333EA),
                  title: _isHindi ? 'बिजली' : 'Power',
                  status: _isHindi ? 'उपलब्ध' : 'Available',
                  onTap: _showShelterDetailsModal,
                ),
              ];

              if (isWide) {
                return Row(
                  children: [
                    Expanded(
                      flex: 60,
                      child: capacityWidget,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 40,
                      child: Row(
                        children: [
                          for (int i = 0; i < supplyChips.length; i++) ...[
                            if (i > 0) const SizedBox(width: 6),
                            Expanded(child: supplyChips[i]),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    capacityWidget,
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        for (int i = 0; i < supplyChips.length; i++) ...[
                          if (i > 0) const SizedBox(width: 6),
                          Expanded(child: supplyChips[i]),
                        ],
                      ],
                    ),
                  ],
                );
              }
            },
          ),

          const SizedBox(height: 14),

          // Action Buttons: View Details & Get Directions
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: _showShelterDetailsModal,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  side: const BorderSide(color: Color(0xFF10B981), width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  backgroundColor: const Color(0xFFF0FDF4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.map_outlined, size: 16, color: Color(0xFF059669)),
                    const SizedBox(width: 6),
                    Text(
                      _isHindi ? 'विवरण देखें' : 'View Details',
                      style: const TextStyle(
                        color: Color(0xFF059669),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF059669)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CitizenSafeRouteView(isHindi: _isHindi)),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  backgroundColor: const Color(0xFFF8FAFC),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.near_me_outlined, size: 15, color: Color(0xFF007AEB)),
                    const SizedBox(width: 6),
                    Text(
                      _isHindi ? 'दिशा-निर्देश' : 'Get Directions',
                      style: const TextStyle(
                        color: Color(0xFF007AEB),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShelterSupplyChip({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String status,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: iconColor),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    status,
                    style: const TextStyle(
                      color: Color(0xFF16A34A),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 3),
              const Icon(Icons.chevron_right_rounded, size: 13, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 6. FAMILY SAFETY CARD
  // --------------------------------------------------------------------------
  Widget _buildFamilySafetyCard() {
    final safeCount = _familyMembers.where((m) => m['isSafe'] == true).length;
    final totalCount = _familyMembers.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD6E8F7)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7351D8).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.family_restroom_rounded, color: Color(0xFF7351D8), size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isHindi ? 'परिवार सुरक्षा स्थिति' : 'FAMILY SAFETY',
                      style: const TextStyle(color: Color(0xFF537392), fontSize: 10.5, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      _isHindi ? '$safeCount / $totalCount सदस्य सुरक्षित हैं' : '$safeCount / $totalCount members safe',
                      style: const TextStyle(color: Color(0xFF013973), fontSize: 14, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _showFamilySafetyModal,
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: Text(
                  _isHindi ? 'पूरा देखें' : 'View Family',
                  style: const TextStyle(color: Color(0xFF007AEB), fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Column(
            children: _familyMembers.map((member) {
              final isSafe = member['isSafe'] as bool;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: const Color(0xFFF3F8FD),
                      child: Icon(member['icon'], size: 16, color: const Color(0xFF013973)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _isHindi ? member['nameHi'] : member['name'],
                        style: const TextStyle(color: Color(0xFF013973), fontWeight: FontWeight.w800, fontSize: 12.5),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isSafe ? const Color(0xFFEAF8F0) : const Color(0xFFFFF5E7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSafe ? Icons.check_circle_rounded : Icons.access_time_rounded,
                            size: 12,
                            color: isSafe ? const Color(0xFF15945C) : const Color(0xFFF39A20),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isHindi ? member['statusHi'] : member['status'],
                            style: TextStyle(
                              color: isSafe ? const Color(0xFF15945C) : const Color(0xFFF39A20),
                              fontWeight: FontWeight.w800,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 7. LOCAL CONDITIONS (NON-TECHNICAL INDICATORS)
  // --------------------------------------------------------------------------
  Widget _buildLocalConditionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD6E8F7), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A013973),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── HEADER: CIRCULAR PIN + TITLE + LIVE REPORT BADGE ──
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFE0F2FE),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFF007AEB),
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _isHindi ? 'आपके क्षेत्र की स्थिति' : 'LOCAL CONDITIONS (YOUR AREA)',
                  style: const TextStyle(
                    color: Color(0xFF013973),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFA7F3D0), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF16A34A),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x6616A34A),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _isHindi ? 'लाइव रिपोर्ट' : 'Live Report',
                      style: const TextStyle(
                        color: Color(0xFF15803D),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── 4 CONDITION TILES (2x2 GRID MATCHING SCREENSHOT) ──
          Column(
            children: [
              Row(
                children: [
                  // Tile 1: Rainfall
                  Expanded(
                    child: _buildConditionTile(
                      icon: Icons.cloudy_snowing,
                      iconColor: const Color(0xFF0284C7),
                      iconBgColor: const Color(0xFFE0F2FE),
                      title: _isHindi ? 'बारिश' : 'Rainfall',
                      value: _isHindi ? 'भारी (Heavy)' : 'Heavy',
                      subtitle: _isHindi ? 'निरंतर जारी' : 'Continuous',
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Tile 2: River Level
                  Expanded(
                    child: _buildConditionTile(
                      icon: Icons.waves_rounded,
                      iconColor: const Color(0xFFE11D48),
                      iconBgColor: const Color(0xFFFFE4E6),
                      title: _isHindi ? 'नदी जलस्तर' : 'River Level',
                      value: _isHindi ? 'तेजी से बढ़ रहा' : 'Rising rapidly',
                      subtitle: _isHindi ? 'दामोदर नदी' : 'Damodar River',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Tile 3: Temperature
                  Expanded(
                    child: _buildConditionTile(
                      icon: Icons.thermostat_rounded,
                      iconColor: const Color(0xFFD97706),
                      iconBgColor: const Color(0xFFFEF3C7),
                      title: _isHindi ? 'तापमान' : 'Temperature',
                      value: '24°C',
                      subtitle: _isHindi ? 'नमी: 94%' : 'Humidity: 94%',
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Tile 4: Wind Speed
                  Expanded(
                    child: _buildConditionTile(
                      icon: Icons.air_rounded,
                      iconColor: const Color(0xFF0284C7),
                      iconBgColor: const Color(0xFFE0F2FE),
                      title: _isHindi ? 'हवा की गति' : 'Wind Speed',
                      value: '18 km/h',
                      subtitle: _isHindi ? 'हवा का रुख: पूर्व' : 'Heading East',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConditionTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circular Avatar Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(icon, color: iconColor, size: 24),
            ),
          ),
          const SizedBox(width: 12),

          // Content Column (Category Title, Primary Value, Subtext)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 8. WEATHER & RAIN FORECAST CARD
  // --------------------------------------------------------------------------
  Widget _buildWeatherForecastCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Stack(
          children: [
            // Faint background cloud watermark matching screenshot
            Positioned(
              right: 12,
              top: 8,
              child: Opacity(
                opacity: 0.06,
                child: Icon(
                  Icons.cloud_rounded,
                  size: 110,
                  color: const Color(0xFF0284C7),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Large Circular Rain Icon + Weather Details Column
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Large Circular Weather Icon Badge (light blue with dark blue cloud and rain)
                      Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE0F2FE),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.cloud_rounded,
                              color: Color(0xFF0284C7),
                              size: 32,
                            ),
                            const SizedBox(height: 1),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Transform.rotate(
                                  angle: -0.2,
                                  child: Container(
                                    width: 3,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF38BDF8),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Transform.rotate(
                                  angle: -0.2,
                                  child: Container(
                                    width: 3,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF38BDF8),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Transform.rotate(
                                  angle: -0.2,
                                  child: Container(
                                    width: 3,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF38BDF8),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 14),

                      // Text and Action Header
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header row: WEATHER & RAIN FORECAST + Today Chip + View Forecast > Button
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isCompact = constraints.maxWidth < 360;

                                final headerChips = Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      _isHindi ? 'मौसम और वर्षा पूर्वानुमान' : 'WEATHER & RAIN FORECAST',
                                      style: const TextStyle(
                                        color: Color(0xFF0F2D59),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE0F2FE),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.cloud_rounded,
                                            size: 12,
                                            color: Color(0xFF0284C7),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _isHindi ? 'आज' : 'Today',
                                            style: const TextStyle(
                                              color: Color(0xFF0284C7),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );

                                final viewForecastBtn = InkWell(
                                  onTap: _showWeatherForecastModal,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: const Color(0xFF93C5FD), width: 1.2),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _isHindi ? 'पूर्वानुमान देखें' : 'View Forecast',
                                          style: const TextStyle(
                                            color: Color(0xFF1D4ED8),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        const Icon(
                                          Icons.chevron_right_rounded,
                                          color: Color(0xFF1D4ED8),
                                          size: 15,
                                        ),
                                      ],
                                    ),
                                  ),
                                );

                                if (isCompact) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      headerChips,
                                      const SizedBox(height: 6),
                                      viewForecastBtn,
                                    ],
                                  );
                                }

                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: headerChips),
                                    const SizedBox(width: 8),
                                    viewForecastBtn,
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: 2),

                            // Subtitle: Short-term outlook
                            Text(
                              _isHindi ? 'अल्पकालिक दृष्टिकोण' : 'Short-term outlook',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            const SizedBox(height: 6),

                            // Bold Main Heading: Heavy rainfall expected today
                            Text(
                              _isHindi ? 'आज भारी वर्षा की संभावना' : 'Heavy rainfall expected today',
                              style: const TextStyle(
                                color: Color(0xFF0F2D59),
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Warning Banner: Next 3 hrs: Flood risk may rise
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFED7AA), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_rounded,
                          color: Color(0xFFEA580C),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _isHindi
                                ? 'अगले 3 घंटे: बाढ़ का खतरा बढ़ सकता है'
                                : 'Next 3 hrs: Flood risk may rise',
                            style: const TextStyle(
                              color: Color(0xFFC2410C),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 4-Hour Rainfall Forecast Outlook
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: _buildHourlyRain('Now', '🌧️🌧️', '35 mm/h', 'High')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildHourlyRain('+1 hr', '🌧️🌧️🌧️', '48 mm/h', 'Peak')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildHourlyRain('+2 hr', '🌧️🌧️', '30 mm/h', 'High')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildHourlyRain('+3 hr', '🌧️', '14 mm/h', 'Moderate')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 9. LOCAL ROAD STATUS CARD
  // --------------------------------------------------------------------------
  Widget _buildRoadStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          // Header: Signal pill + Title + Live traffic & weather impact + View All Roads >
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFE0F2FE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Color(0xFF0284C7),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isHindi ? 'आस-पास के सड़कों की स्थिति' : 'Nearby Road Conditions',
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isHindi ? 'लाइव ट्रैफ़िक व मौसम प्रभाव' : 'Live traffic & weather impact',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: _showRoadConditionsModal,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isHindi ? 'सभी सड़कें' : 'View All Roads',
                        style: const TextStyle(
                          color: Color(0xFF2563EB),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF2563EB),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 1. Main Bypass Highway (Open)
          _buildRoadConditionItem(
            name: _isHindi ? 'मुख्य बायपास रोड' : 'Main Bypass Highway',
            subtitle: _isHindi ? 'साफ • सामान्य यातायात' : 'Clear • Normal traffic',
            statusLabel: _isHindi ? 'खुला है' : 'Open',
            dotColor: const Color(0xFF16A34A),
            iconBgColor: const Color(0xFFDCFCE7),
            iconColor: const Color(0xFF16A34A),
            badgeBgColor: const Color(0xFFDCFCE7),
            badgeTextColor: const Color(0xFF16A34A),
            icon: Icons.tune_rounded,
          ),

          const SizedBox(height: 14),

          // 2. Hill Ridge Road (Slow)
          _buildRoadConditionItem(
            name: _isHindi ? 'हिल रिज रोड' : 'Hill Ridge Road',
            subtitle: _isHindi ? 'जलभराव (हल्का)' : 'Water logging (low)',
            statusLabel: _isHindi ? 'धीमा' : 'Slow',
            dotColor: const Color(0xFFD97706),
            iconBgColor: const Color(0xFFFEF3C7),
            iconColor: const Color(0xFFD97706),
            badgeBgColor: const Color(0xFFFEF3C7),
            badgeTextColor: const Color(0xFFD97706),
            icon: Icons.warning_amber_rounded,
          ),

          const SizedBox(height: 14),

          // 3. Damodar River Bridge (Closed)
          _buildRoadConditionItem(
            name: _isHindi ? 'दामोदर नदी पुल' : 'Damodar River Bridge',
            subtitle: _isHindi ? 'अतिप्रवाह के कारण बंद' : 'Closed due to overflow',
            statusLabel: _isHindi ? 'बंद' : 'Closed',
            dotColor: const Color(0xFFDC2626),
            iconBgColor: const Color(0xFFFEE2E2),
            iconColor: const Color(0xFFDC2626),
            badgeBgColor: const Color(0xFFFEE2E2),
            badgeTextColor: const Color(0xFFDC2626),
            icon: Icons.block_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildRoadConditionItem({
    required String name,
    required String subtitle,
    required String statusLabel,
    required Color dotColor,
    required Color iconBgColor,
    required Color iconColor,
    required Color badgeBgColor,
    required Color badgeTextColor,
    required IconData icon,
  }) {
    return InkWell(
      onTap: _showRoadConditionsModal,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            // Status dot
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),

            // Circle Icon
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),

            // Road Name & Live traffic condition
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Right Status Badge Pill + chevron
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: badgeBgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    statusLabel,
                    style: TextStyle(
                      color: badgeTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 14,
                    color: badgeTextColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoadItem({
    required String name,
    required String status,
    required Color statusColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: statusColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 10. NEARBY MEDICAL / HOSPITAL HELP CARD
  // --------------------------------------------------------------------------
  Widget _buildMedicalHelpCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Header Row: Hospital Icon + Info + Operational Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Medical Bag / First Aid Icon in light blue rounded container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.medical_services_rounded, color: Color(0xFF0284C7), size: 22),
              ),

              const SizedBox(width: 12),

              // Title & Location / Beds Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isHindi ? 'झारखंड' : 'JHARKHAND',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isHindi ? 'जिला सामान्य अस्पताल' : 'District General Hospital',
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 13, color: Color(0xFF0284C7)),
                          const SizedBox(width: 3),
                          Text(
                            _isHindi ? '3.2 किमी दूर' : '3.2 km away',
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Text('  |  ', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11)),
                          const Icon(Icons.bed_rounded, size: 14, color: Color(0xFF64748B)),
                          const SizedBox(width: 3),
                          Text(
                            _isHindi ? '120+ बेड' : '120+ beds',
                            style: const TextStyle(
                              color: Color(0xFF475569),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Text('  •  ', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11)),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF16A34A),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isHindi ? 'खुला 24 × 7' : 'Open 24 × 7',
                            style: const TextStyle(
                              color: Color(0xFF16A34A),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // Operational Pill Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFBBF7D0), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      _isHindi ? 'सक्रिय' : 'Operational',
                      style: const TextStyle(
                        color: Color(0xFF15803D),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 2. The 4 Metric Cards in Equal Parts
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 640;

              // Card 1: Available Beds (with bar indicator)
              Widget bedCard = _buildHospitalMetricBox(
                icon: Icons.bed_rounded,
                iconBg: const Color(0xFFE0F2FE),
                iconColor: const Color(0xFF0284C7),
                label: _isHindi ? 'उपलब्ध बेड' : 'Available Beds',
                value: '78 / 120',
                bottomWidget: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    value: 78 / 120,
                    minHeight: 5,
                    backgroundColor: Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF007AEB)),
                  ),
                ),
              );

              // Card 2: Doctors On Duty
              Widget doctorCard = _buildHospitalMetricBox(
                icon: Icons.medical_services_outlined,
                iconBg: const Color(0xFFDCFCE7),
                iconColor: const Color(0xFF16A34A),
                label: _isHindi ? 'ड्यूटी पर डॉक्टर' : 'Doctors On Duty',
                value: '18',
                bottomWidget: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF16A34A),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isHindi ? 'सक्रिय' : 'Active',
                      style: const TextStyle(
                        color: Color(0xFF16A34A),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );

              // Card 3: Ambulances
              Widget ambulanceCard = _buildHospitalMetricBox(
                icon: Icons.emergency_outlined,
                iconBg: const Color(0xFFFEE2E2),
                iconColor: const Color(0xFFEF4444),
                label: _isHindi ? 'एम्बुलेंस' : 'Ambulances',
                value: '5',
                bottomWidget: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF16A34A),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isHindi ? 'उपलब्ध' : 'Available',
                      style: const TextStyle(
                        color: Color(0xFF16A34A),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );

              // Card 4: Emergency Helpline
              Widget helplineCard = _buildHospitalMetricBox(
                icon: Icons.phone_rounded,
                iconBg: const Color(0xFFF3E8FF),
                iconColor: const Color(0xFF9333EA),
                label: _isHindi ? 'इमरजेंसी हेल्पलाइन' : 'Emergency Helpline',
                value: '108',
                bottomWidget: const Text(
                  '(24 × 7)',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );

              if (isWide) {
                return Row(
                  children: [
                    Expanded(child: bedCard),
                    const SizedBox(width: 10),
                    Expanded(child: doctorCard),
                    const SizedBox(width: 10),
                    Expanded(child: ambulanceCard),
                    const SizedBox(width: 10),
                    Expanded(child: helplineCard),
                  ],
                );
              } else {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: bedCard),
                        const SizedBox(width: 8),
                        Expanded(child: doctorCard),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: ambulanceCard),
                        const SizedBox(width: 8),
                        Expanded(child: helplineCard),
                      ],
                    ),
                  ],
                );
              }
            },
          ),

          const SizedBox(height: 16),

          // 3. Action Buttons: Call Hospital & Get Directions
          Row(
            children: [
              // Call Hospital Button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showMessage(
                    _isHindi
                        ? 'अस्पताल को कॉल किया जा रहा है: 06542-230001'
                        : 'Dialing District General Hospital (108 / 06542-230001)...',
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    side: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
                    backgroundColor: const Color(0xFFF0F9FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.phone_in_talk_rounded, size: 16, color: Color(0xFF0284C7)),
                  label: Text(
                    _isHindi ? 'अस्पताल को कॉल करें' : 'Call Hospital',
                    style: const TextStyle(
                      color: Color(0xFF0284C7),
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Get Directions Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CitizenSafeRouteView(isHindi: _isHindi)),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    backgroundColor: const Color(0xFF007AEB),
                    elevation: 1.5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.near_me_rounded, size: 16, color: Colors.white),
                  label: Text(
                    _isHindi ? 'दिशा-निर्देश प्राप्त करें' : 'Get Directions',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHospitalMetricBox({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
    required Widget bottomWidget,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon in tinted circular pill
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          bottomWidget,
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 11. DYNAMIC SAFETY INSTRUCTIONS ("DO'S AND DON'TS" SLIDING CAROUSEL)
  // --------------------------------------------------------------------------
  Widget _buildSafetyInstructionsCard() {
    final currentDisaster = _dosDisasterList[_dosDisasterIdx.clamp(0, _dosDisasterList.length - 1)];
    final currentPhase = currentDisaster.phases[_dosPhaseIdx.clamp(0, currentDisaster.phases.length - 1)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. SECTION HEADER: "Do's and Don'ts" + Subtitle + "View All >"
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isHindi ? "क्या करें और क्या न करें" : "Do's and Don'ts",
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isHindi
                        ? 'सूचित रहें। सुरक्षित रहें। आपदा के समय सही कदम उठाएं।'
                        : 'Stay informed. Stay safe. Follow the right steps during disasters.',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: _showSafetyInstructionsModal,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isHindi ? 'सभी देखें' : 'View All',
                      style: const TextStyle(
                        color: Color(0xFF1D4ED8),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF1D4ED8),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // 2. 4 CATEGORY CONTAINERS (Urban Flood, Cyclone, Landslide, Lightning)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: List.generate(_dosDisasterList.length, (index) {
              final item = _dosDisasterList[index];
              final isSelected = index == _dosDisasterIdx;

              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0B46A2) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF0B46A2) : const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF0B46A2).withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => _selectDosDisaster(index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.icon,
                              size: 16,
                              color: isSelected ? Colors.white : const Color(0xFF334155),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isHindi ? item.titleHi : item.titleEn,
                              style: TextStyle(
                                color: isSelected ? Colors.white : const Color(0xFF334155),
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 14),

        // 3. MAIN ANIMATED CARD WITH FLOATING ARROWS
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 3A. HEADER GRADIENT BANNER
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: currentDisaster.gradient,
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(currentDisaster.icon, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isHindi ? currentDisaster.bannerTitleHi : currentDisaster.bannerTitleEn,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isHindi ? currentDisaster.bannerSubtitleHi : currentDisaster.bannerSubtitleEn,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.waves_rounded,
                          color: Colors.white.withValues(alpha: 0.25),
                          size: 30,
                        ),
                      ],
                    ),
                  ),

                  // 3B. CARD BODY (TIPS TEXT SLIDES ON PHASE; IMAGE ONLY SLIDES ON DISASTER CHANGE)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 600;
                      final tips = _isHindi ? currentPhase.tipsHi : currentPhase.tipsEn;

                      // 1. Tips content: AnimatedSwitcher keyed by Phase + Disaster
                      // Slow, silky-smooth horizontal conveyor slide animation (950ms, full 1.0 travel, Curves.easeInOutCubic)
                      // No abrupt fade-out so text remains visible while physically sliding across
                      final tipsContent = AnimatedSwitcher(
                        duration: const Duration(milliseconds: 950),
                        switchInCurve: Curves.easeInOutCubic,
                        switchOutCurve: Curves.easeInOutCubic,
                        layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                          return Stack(
                            alignment: Alignment.topLeft,
                            children: <Widget>[
                              ...previousChildren,
                              ?currentChild,
                            ],
                          );
                        },
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          final isEntering = (child.key == ValueKey('tips-${currentDisaster.id}-$_dosPhaseIdx'));
                          final slideTween = isEntering
                              ? Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
                              : Tween<Offset>(begin: const Offset(-1.0, 0.0), end: Offset.zero);

                          return ClipRect(
                            child: SlideTransition(
                              position: slideTween.animate(CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeInOutCubic,
                              )),
                              child: child,
                            ),
                          );
                        },
                        child: SizedBox(
                          key: ValueKey('tips-${currentDisaster.id}-$_dosPhaseIdx'),
                          width: double.infinity,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: isWide ? 230 : 205),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Phase Badge Pill (clean without any dot)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE0F2FE),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFFBAE6FD)),
                                  ),
                                  child: Text(
                                    _isHindi ? currentPhase.badgeHi : currentPhase.badgeEn,
                                    style: const TextStyle(
                                      color: Color(0xFF0284C7),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Bullet Checkmarks
                                ...tips.map(
                                  (tip) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.only(top: 2),
                                          child: Icon(
                                            Icons.check_circle_rounded,
                                            color: Color(0xFF0284C7),
                                            size: 17,
                                          ),
                                        ),
                                        const SizedBox(width: 9),
                                        Expanded(
                                          child: Text(
                                            tip,
                                            style: const TextStyle(
                                              color: Color(0xFF1E293B),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              height: 1.35,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // View Full Guide Button
                                ElevatedButton(
                                  onPressed: _showSafetyInstructionsModal,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0F172A),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _isHindi ? 'पूरी गाइड देखें' : 'View Full Guide',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward_rounded, size: 15),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );

                      // 2. Image widget: AnimatedSwitcher keyed ONLY by Disaster ID
                      // Stays completely still when changing phases (Before/During/After);
                      // Slides & updates with smooth 950ms duration ONLY when the disaster type changes!
                      final imageWidget = AnimatedSwitcher(
                        duration: const Duration(milliseconds: 950),
                        switchInCurve: Curves.easeInOutCubic,
                        switchOutCurve: Curves.easeInOutCubic,
                        layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                          return Stack(
                            alignment: Alignment.center,
                            children: <Widget>[
                              ...previousChildren,
                              ?currentChild,
                            ],
                          );
                        },
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          final isEntering = (child.key == ValueKey('img-${currentDisaster.id}'));
                          final slideTween = isEntering
                              ? Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
                              : Tween<Offset>(begin: const Offset(-1.0, 0.0), end: Offset.zero);

                          return ClipRect(
                            child: SlideTransition(
                              position: slideTween.animate(CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeInOutCubic,
                              )),
                              child: child,
                            ),
                          );
                        },
                        child: ClipRRect(
                          key: ValueKey('img-${currentDisaster.id}'),
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            currentDisaster.imagePath,
                            height: isWide ? 230 : 175,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: isWide ? 230 : 175,
                              color: const Color(0xFFE2E8F0),
                              child: Icon(currentDisaster.icon, size: 48, color: const Color(0xFF94A3B8)),
                            ),
                          ),
                        ),
                      );

                      return Padding(
                        padding: const EdgeInsets.all(18),
                        child: isWide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 6, child: tipsContent),
                                  const SizedBox(width: 18),
                                  Expanded(flex: 5, child: imageWidget),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  tipsContent,
                                  const SizedBox(height: 16),
                                  imageWidget,
                                ],
                              ),
                      );
                    },
                  ),

                  const Divider(height: 1, color: Color(0xFFF1F5F9)),

                  // 3C. BOTTOM INDICATORS: 3 PHASE CHIPS + 4 DISASTER DOTS
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 10,
                      children: [
                        // Phase Indicators (Before, During, After)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildDosPhaseButton(0, _isHindi ? 'पूर्व' : 'Before'),
                            const SizedBox(width: 6),
                            _buildDosPhaseButton(1, _isHindi ? 'दौरान' : 'During'),
                            const SizedBox(width: 6),
                            _buildDosPhaseButton(2, _isHindi ? 'पश्चात' : 'After'),
                          ],
                        ),

                        // 4 Disaster Pagination Dots (Flood, Cyclone, Landslide, Lightning)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(_dosDisasterList.length, (dIdx) {
                            final isCurr = dIdx == _dosDisasterIdx;
                            return InkWell(
                              onTap: () => _selectDosDisaster(dIdx),
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: isCurr ? 24 : 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: isCurr ? currentDisaster.primaryColor : const Color(0xFFCBD5E1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Left Floating Arrow Button
            Positioned(
              left: 6,
              top: 135,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _prevDosSlide,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                      ],
                    ),
                    child: const Icon(Icons.chevron_left_rounded, color: Color(0xFF0F172A), size: 22),
                  ),
                ),
              ),
            ),

            // Right Floating Arrow Button
            Positioned(
              right: 6,
              top: 135,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _nextDosSlide,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                      ],
                    ),
                    child: const Icon(Icons.chevron_right_rounded, color: Color(0xFF0F172A), size: 22),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDosPhaseButton(int phaseIndex, String label) {
    final isSelected = phaseIndex == _dosPhaseIdx;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectDosPhase(phaseIndex),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE0F2FE) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFFBAE6FD) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF64748B),
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 12. EMERGENCY CONTACTS ROW (FULL WIDTH WITH EQUAL PARTS)
  // --------------------------------------------------------------------------
  Widget _buildEmergencyContactsRow() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Circular Phone Badge + Title & Subtitle
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.phone_in_talk_rounded,
                  color: Color(0xFFDC2626),
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isHindi ? 'आपातकालीन संपर्क (1-टैप कॉल)' : 'EMERGENCY HELPLINES (1-TAP CALL)',
                      style: const TextStyle(
                        color: Color(0xFF0F2642),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isHindi
                          ? 'तत्काल सहायता प्राप्त करें। कॉल करने के लिए किसी भी नंबर पर टैप करें।'
                          : 'Get immediate help. Tap any number below to call.',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 5 Equal Helpline Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;
              final isMedium = constraints.maxWidth >= 480;

              final card1 = _buildHelplineCard(
                label: _isHindi ? 'इमरजेंसी' : 'Emergency',
                number: '112',
                cardBg: const Color(0xFFFFF1F2),
                borderColor: const Color(0xFFFECDD3),
                iconBg: const Color(0xFFFFE4E6),
                iconColor: const Color(0xFFDC2626),
                icon: Icons.crisis_alert_rounded,
                pillColor: const Color(0xFFDC2626),
                chevronColor: const Color(0xFFFB7185),
                onTap: () => _showMessage(
                  _isHindi ? '112 (इमरजेंसी) पर कॉल किया जा रहा है...' : 'Dialing 112 (Emergency)...',
                ),
              );

              final card2 = _buildHelplineCard(
                label: _isHindi ? 'पुलिस' : 'Police',
                number: '100',
                cardBg: const Color(0xFFEFF6FF),
                borderColor: const Color(0xFFBFDBFE),
                iconBg: const Color(0xFFDBEAFE),
                iconColor: const Color(0xFF2563EB),
                icon: Icons.local_police_rounded,
                pillColor: const Color(0xFF2563EB),
                chevronColor: const Color(0xFF60A5FA),
                onTap: () => _showMessage(
                  _isHindi ? '100 (पुलिस) पर कॉल किया जा रहा है...' : 'Dialing 100 (Police)...',
                ),
              );

              final card3 = _buildHelplineCard(
                label: _isHindi ? 'फायर' : 'Fire',
                number: '101',
                cardBg: const Color(0xFFFFF7ED),
                borderColor: const Color(0xFFFED7AA),
                iconBg: const Color(0xFFFFEDD5),
                iconColor: const Color(0xFFEA580C),
                icon: Icons.local_fire_department_rounded,
                pillColor: const Color(0xFFEA580C),
                chevronColor: const Color(0xFFFB923C),
                onTap: () => _showMessage(
                  _isHindi ? '101 (फायर) पर कॉल किया जा रहा है...' : 'Dialing 101 (Fire)...',
                ),
              );

              final card4 = _buildHelplineCard(
                label: _isHindi ? 'एम्बुलेंस' : 'Ambulance',
                number: '108',
                cardBg: const Color(0xFFF0FDF4),
                borderColor: const Color(0xFFBBF7D0),
                iconBg: const Color(0xFFDCFCE7),
                iconColor: const Color(0xFF16A34A),
                icon: Icons.medical_services_rounded,
                pillColor: const Color(0xFF16A34A),
                chevronColor: const Color(0xFF4ADE80),
                onTap: () => _showMessage(
                  _isHindi ? '108 (एम्बुलेंस) पर कॉल किया जा रहा है...' : 'Dialing 108 (Ambulance)...',
                ),
              );

              final card5 = _buildHelplineCard(
                label: _isHindi ? 'आपदा नियंत्रण' : 'Disaster Control',
                number: '1077',
                cardBg: const Color(0xFFFAF5FF),
                borderColor: const Color(0xFFE9D5FF),
                iconBg: const Color(0xFFF3E8FF),
                iconColor: const Color(0xFF9333EA),
                icon: Icons.account_balance_rounded,
                pillColor: const Color(0xFF9333EA),
                chevronColor: const Color(0xFFC084FC),
                onTap: () => _showMessage(
                  _isHindi ? '1077 (आपदा नियंत्रण) पर कॉल किया जा रहा है...' : 'Dialing 1077 (Disaster Control)...',
                ),
              );

              if (isWide) {
                // Wide / Desktop / Tablet: exactly 5 equal columns
                return Row(
                  children: [
                    Expanded(child: card1),
                    const SizedBox(width: 8),
                    Expanded(child: card2),
                    const SizedBox(width: 8),
                    Expanded(child: card3),
                    const SizedBox(width: 8),
                    Expanded(child: card4),
                    const SizedBox(width: 8),
                    Expanded(child: card5),
                  ],
                );
              } else if (isMedium) {
                // Medium viewports: 3 on top, 2 on bottom (all expanded equally)
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: card1),
                        const SizedBox(width: 8),
                        Expanded(child: card2),
                        const SizedBox(width: 8),
                        Expanded(child: card3),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: card4),
                        const SizedBox(width: 8),
                        Expanded(child: card5),
                      ],
                    ),
                  ],
                );
              } else {
                // Mobile viewports: clean 2-column equal layout with 5th spanning nicely
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: card1),
                        const SizedBox(width: 8),
                        Expanded(child: card2),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: card3),
                        const SizedBox(width: 8),
                        Expanded(child: card4),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: card5),
                      ],
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHelplineCard({
    required String label,
    required String number,
    required Color cardBg,
    required Color borderColor,
    required Color iconBg,
    required Color iconColor,
    required IconData icon,
    required Color pillColor,
    required Color chevronColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.1),
          ),
          child: Row(
            children: [
              // Icon Circle
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),

              const SizedBox(width: 8),

              // Title and Number Pill
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: pillColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        number,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 4),

              // Chevron Right in soft circular background
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: chevronColor,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // TAB 1: FULL DISASTER MAP TAB (FILTERS & CONTROLS)
  // ==========================================================================
  Widget _buildFullMapTab() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _fullMapController,
          options: MapOptions(
            initialCenter: const LatLng(23.7990, 86.4340),
            initialZoom: 13.5,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.resqshield.app',
            ),
            // Safe Corridor Polyline
            PolylineLayer(
              polylines: [
                Polyline(
                  points: [_userPos, _waypointPos, _shelterPos1],
                  color: const Color(0xFF15945C),
                  strokeWidth: 5.0,
                ),
              ],
            ),
            // Filterable Markers
            MarkerLayer(
              markers: [
                // User Marker
                Marker(
                  point: _userPos,
                  width: 44,
                  height: 44,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AEB),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                    ),
                    child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 24),
                  ),
                ),
                // Shelter 1
                if (_fullMapFilter == 'All' || _fullMapFilter == 'Shelters')
                  Marker(
                    point: _shelterPos1,
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: _showShelterDetailsModal,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFE92828),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                        child: const Icon(Icons.night_shelter_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                // Hospital
                if (_fullMapFilter == 'All' || _fullMapFilter == 'Hospitals')
                  Marker(
                    point: _hospitalPos,
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: _showMedicalDetailsModal,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                        child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                // Road Block
                if (_fullMapFilter == 'All' || _fullMapFilter == 'Roads')
                  Marker(
                    point: _roadBlockPos,
                    width: 38,
                    height: 38,
                    child: GestureDetector(
                      onTap: _showRoadConditionsModal,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF39A20),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.block_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),

        // Filter Chips on Top of Map
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Flood Zone', 'Roads', 'Shelters', 'Hospitals'].map((filter) {
                final isSelected = _fullMapFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(
                      filter,
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF013973),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    selectedColor: const Color(0xFF013973),
                    backgroundColor: Colors.white.withValues(alpha: 0.95),
                    onSelected: (_) => setState(() => _fullMapFilter = filter),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Floating Action Button to launch Full Safe Route
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CitizenSafeRouteView(isHindi: _isHindi)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF15945C),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 6,
            ),
            icon: const Icon(Icons.directions_run_rounded, color: Colors.white, size: 22),
            label: Text(
              _isHindi ? 'सुरक्षित मार्ग नेविगेशन शुरू करें' : 'START SAFE ROUTE NAVIGATION',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // TAB 3: HELP HUB TAB (EMERGENCY-FOCUSED)
  // ==========================================================================
  Widget _buildHelpHubTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Need Help Header
          Text(
            _isHindi ? '🚨 आपातकालीन मदद की आवश्यकता है?' : '🚨 Need Immediate Help?',
            style: const TextStyle(color: Color(0xFF013973), fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            _isHindi
                ? 'यदि आप या आपका परिवार खतरे में है, तो नीचे दिए गए लाल SOS बटन को दबाएं।'
                : 'If you or someone around you is in immediate peril, trigger the Emergency SOS below.',
            style: const TextStyle(color: Color(0xFF537392), fontSize: 13),
          ),
          const SizedBox(height: 18),

          // Big Emergency SOS Button
          SizedBox(
            height: 100,
            child: ElevatedButton(
              onPressed: _showSosConfirmationDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE92828),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 6,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emergency_share_rounded, color: Colors.white, size: 40),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isHindi ? 'आपातकालीन SOS भेजें' : 'TRANSMIT SOS NOW',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                      Text(
                        _isHindi ? 'लाइव जीपीएस सीधे राहत दल को जाएगा' : 'Shares exact GPS with nearby NDRF / Police',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Quick Action Cards
          _buildHelpTile(
            icon: Icons.alt_route_rounded,
            color: const Color(0xFF15945C),
            title: _isHindi ? 'सुरक्षित मार्ग खोजें' : 'Find Safe Evacuation Route',
            subtitle: _isHindi ? 'बाढ़ से मुक्त ऊंचे मार्गों की नेविगेशन' : 'GPS route avoiding submerged roads & bridges',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CitizenSafeRouteView(isHindi: _isHindi)),
              );
            },
          ),
          const SizedBox(height: 10),
          _buildHelpTile(
            icon: Icons.night_shelter_rounded,
            color: const Color(0xFF007AEB),
            title: _isHindi ? 'निकटतम राहत शिविर खोजें' : 'Locate Nearest Relief Shelter',
            subtitle: _isHindi ? 'भोजन, पानी और बिस्तर की उपलब्धता' : 'Food, clean water, medical aid & bed capacity',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CitizenSheltersView(isHindi: _isHindi)),
              );
            },
          ),
          const SizedBox(height: 10),
          _buildHelpTile(
            icon: Icons.local_hospital_rounded,
            color: const Color(0xFF0284C7),
            title: _isHindi ? 'अस्पताल व प्राथमिक चिकित्सा' : 'Hospitals & Medical Care',
            subtitle: _isHindi ? 'सक्रिय स्वास्थ्य केंद्र एवं एम्बुलेंस' : 'Emergency clinics & on-call trauma units',
            onTap: _showMedicalDetailsModal,
          ),
          const SizedBox(height: 10),
          _buildHelpTile(
            icon: Icons.shield_rounded,
            color: const Color(0xFF7351D8),
            title: _isHindi ? 'सुरक्षा गाइड और निर्देश' : 'Disaster Survival Guide',
            subtitle: _isHindi ? 'बाढ़ के दौरान क्या करें और क्या न करें' : 'Step-by-step checklist during flash floods',
            onTap: _showSafetyInstructionsModal,
          ),
          const SizedBox(height: 10),
          _buildHelpTile(
            icon: Icons.add_a_photo_rounded,
            color: const Color(0xFFF39A20),
            title: _isHindi ? 'आपदा या खतरा दर्ज करें' : 'Report Incident or Hazard',
            subtitle: _isHindi ? 'टूटे पुल, जलभराव या मलबे की फोटो भेजें' : 'Report blocked roads or stranded persons',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CitizenHazardReportView(isHindi: _isHindi)),
              );
            },
          ),
          const SizedBox(height: 20),

          // Helplines
          _buildEmergencyContactsRow(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHelpTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD6E8F7)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Color(0xFF013973), fontSize: 13.5, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Color(0xFF537392), fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF537392), size: 16),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // TAB 4: PROFILE & SETTINGS TAB
  // ==========================================================================
  Widget _buildProfileTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD6E8F7)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFF013973),
                  child: Icon(Icons.person, size: 36, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rohit Kumar',
                        style: TextStyle(color: Color(0xFF013973), fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '+91 98765 43210 • Citizen',
                        style: TextStyle(color: Color(0xFF537392), fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF8F0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _isHindi ? '🟢 जीपीएस सत्यापित' : '🟢 GPS Location Verified',
                          style: const TextStyle(color: Color(0xFF15945C), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Menu Section 1: Family & SOS
          _buildProfileMenuSection(
            title: _isHindi ? 'परिवार एवं आपातकालीन' : 'FAMILY & EMERGENCY',
            items: [
              _buildProfileMenuItem(
                icon: Icons.family_restroom_rounded,
                title: _isHindi ? 'परिवार सदस्य सूची एवं चेक-इन' : 'Family Safety & Check-in',
                subtitle: _isHindi ? '3/4 सदस्य सुरक्षित' : '3 / 4 members marked safe',
                onTap: _showFamilySafetyModal,
              ),
              _buildProfileMenuItem(
                icon: Icons.contact_phone_rounded,
                title: _isHindi ? 'आपातकालीन संपर्क सूची' : 'Emergency Contacts',
                subtitle: _isHindi ? '112, पुलिस, एम्बुलेंस' : '112, Police, NDRF',
                onTap: () => _showMessage('Emergency contacts up to date'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Menu Section 2: Data & Connectivity
          _buildProfileMenuSection(
            title: _isHindi ? 'डेटा एवं ऑफ़लाइन' : 'OFFLINE DATA & ACCESS',
            items: [
              _buildProfileMenuItem(
                icon: Icons.download_done_rounded,
                title: _isHindi ? 'डाउनलोड किए गए मैप और डेटा' : 'Downloaded Offline Data',
                subtitle: _isHindi ? 'बोकारो व शिलांग बेसिन (14 MB)' : 'Bokaro & Shillong Basins (14 MB cached)',
                onTap: () => _showMessage('Offline maps are cached and ready'),
              ),
              _buildProfileMenuItem(
                icon: Icons.wifi_tethering_rounded,
                title: _isHindi ? 'लोरा रेडियो मेश सेटिंग्स' : 'LoRa Mesh Sync Settings',
                subtitle: _isHindi ? 'ऑटोमैटिक पियर-टू-पियर चालू' : 'P2P background synchronization active',
                onTap: () => _showMessage('LoRa Mesh is active in background'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Menu Section 3: Preferences
          _buildProfileMenuSection(
            title: _isHindi ? 'प्राथमिकताएं' : 'PREFERENCES',
            items: [
              _buildProfileMenuItem(
                icon: Icons.language_rounded,
                title: _isHindi ? 'भाषा (Language)' : 'App Language',
                subtitle: _isHindi ? 'वर्तमान: हिन्दी (टैप करें बदलने के लिए)' : 'Current: English (tap to switch)',
                onTap: () {
                  setState(() => _isHindi = !_isHindi);
                  _showMessage(_isHindi ? 'भाषा: हिन्दी' : 'Language: English');
                },
              ),
              _buildProfileMenuItem(
                icon: Icons.notifications_active_rounded,
                title: _isHindi ? 'आपातकालीन अलर्ट सायरन' : 'Emergency Alert Sound',
                subtitle: _isHindi ? 'उच्च प्राथमिकता सायरन चालू' : 'Loud siren on Critical Evacuation: ON',
                onTap: () => _showMessage('Siren test completed'),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProfileMenuSection({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Color(0xFF537392), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.6),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFD6E8F7)),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF013973)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Color(0xFF013973), fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Color(0xFF537392), fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF537392), size: 14),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // BOTTOM NAVIGATION BAR (5 TABS)
  // ==========================================================================
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFD6E8F7), width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (idx) => setState(() => _currentTab = idx),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF013973),
        unselectedItemColor: const Color(0xFF64748B),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10.5),
        elevation: 0,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_rounded),
            label: _isHindi ? 'होम' : 'Home',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.map_rounded),
            label: _isHindi ? 'मानचित्र' : 'Map',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.campaign_rounded),
            label: _isHindi ? 'अलर्ट्स' : 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.emergency_rounded),
            label: _isHindi ? 'मदद' : 'Help',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_rounded),
            label: _isHindi ? 'प्रोफ़ाइल' : 'Profile',
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // INTERACTIVE MODALS & SHEETS
  // ==========================================================================

  // 1. SOS CONFIRMATION & ACTIVE TRANSMIT MODAL
  void _showSosConfirmationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_rounded, color: Color(0xFFE92828), size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _isHindi ? 'आपातकालीन SOS' : 'Emergency SOS',
                style: const TextStyle(color: Color(0xFF013973), fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isHindi
                  ? 'क्या आप या आपके साथ के लोग तात्कालिक खतरे में हैं?'
                  : 'Are you in immediate danger? Triggering SOS will dispatch your exact GPS coordinates to the nearest NDRF & police rescue team.',
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEEEE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.group_rounded, color: Color(0xFFE92828), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isHindi ? 'साथ में लोग: 3 सदस्य' : 'People with you: 3 members',
                      style: const TextStyle(color: Color(0xFFE92828), fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              _isHindi ? 'रद्द करें' : 'CANCEL',
              style: const TextStyle(color: Color(0xFF537392), fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _isSosActive = true;
                _threatLevel = CitizenThreatLevel.evacuation;
              });
              _showMessage(_isHindi ? '🚨 SOS भेजा गया! राहत दल को सूचित किया गया है।' : '🚨 SOS Transmitted! Relief team assigned.');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE92828),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              _isHindi ? 'SOS भेजें' : 'SEND SOS',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  // 2. LOCATION PICKER MODAL
  void _showLocationPickerModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.my_location_rounded, color: Color(0xFF007AEB)),
                const SizedBox(width: 8),
                Text(
                  _isHindi ? 'स्थान चुनें' : 'Select Location',
                  style: const TextStyle(color: Color(0xFF013973), fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...['Shillong, Meghalaya', 'Bokaro Basin, Jharkhand', 'Ranchi, Jharkhand', 'Guwahati, Assam'].map((loc) {
              final isSel = _currentLocation == loc;
              return ListTile(
                leading: Icon(
                  isSel ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isSel ? const Color(0xFF007AEB) : const Color(0xFF537392),
                ),
                title: Text(loc, style: TextStyle(fontWeight: isSel ? FontWeight.w900 : FontWeight.w600)),
                onTap: () {
                  setState(() => _currentLocation = loc);
                  Navigator.pop(ctx);
                  _showMessage(_isHindi ? 'स्थान बदला गया: $loc' : 'Location updated: $loc');
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  // 3. NOTIFICATIONS SHEET
  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.65,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active_rounded, color: Color(0xFF013973)),
                const SizedBox(width: 8),
                Text(
                  _isHindi ? 'सूचनाएं (नोटिफिकेशन्स)' : 'Notifications (${_notifications.length})',
                  style: const TextStyle(color: Color(0xFF013973), fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showMessage(_isHindi ? 'सभी सूचनाएं पढ़ी गईं' : 'All marked as read');
                  },
                  child: Text(_isHindi ? 'पढ़ा हुआ मार्क करें' : 'Mark all read'),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView.separated(
                itemCount: _notifications.length,
                separatorBuilder: (_, _) => const Divider(height: 12),
                itemBuilder: (_, idx) {
                  final notif = _notifications[idx];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: notif['type'] == 'Emergency' ? const Color(0xFFFFEEEE) : const Color(0xFFE9F4FB),
                      child: Icon(
                        notif['type'] == 'Emergency' ? Icons.warning_rounded : Icons.info_rounded,
                        color: notif['type'] == 'Emergency' ? const Color(0xFFE92828) : const Color(0xFF007AEB),
                      ),
                    ),
                    title: Text(notif['title'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    subtitle: Text(notif['body'], style: const TextStyle(fontSize: 11)),
                    trailing: Text(notif['time'], style: const TextStyle(fontSize: 10, color: Color(0xFF537392))),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 4. FAMILY SAFETY & CHECK-IN MODAL
  void _showFamilySafetyModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            padding: const EdgeInsets.all(20),
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.family_restroom_rounded, color: Color(0xFF7351D8), size: 24),
                    const SizedBox(width: 8),
                    Text(
                      _isHindi ? 'परिवार सुरक्षा चेक-इन' : 'Family Safety & Check-in',
                      style: const TextStyle(color: Color(0xFF013973), fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _isHindi
                      ? 'आपदा के समय अपने परिवार के सदस्यों की सुरक्षा स्थिति ट्रैक करें या स्वयं को सुरक्षित मार्क करें।'
                      : 'Real-time sync of family member check-ins. Works offline via LoRa broadcast.',
                  style: const TextStyle(color: Color(0xFF537392), fontSize: 12),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showMessage(_isHindi ? 'आपने खुद को सुरक्षित मार्क किया!' : 'You marked yourself SAFE!');
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF15945C),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                    label: Text(
                      _isHindi ? 'मैं सुरक्षित हूँ (चेक-इन करें)' : 'I AM SAFE (BROADCAST CHECK-IN)',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const Divider(height: 24),
                Expanded(
                  child: ListView.builder(
                    itemCount: _familyMembers.length,
                    itemBuilder: (_, i) {
                      final m = _familyMembers[i];
                      final isSafe = m['isSafe'] as bool;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xFFE9F4FB),
                              child: Icon(m['icon'], color: const Color(0xFF013973)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isHindi ? m['nameHi'] : m['name'],
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                  ),
                                  Text(
                                    _isHindi ? m['statusHi'] : m['status'],
                                    style: TextStyle(
                                      color: isSafe ? const Color(0xFF15945C) : const Color(0xFFF39A20),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.phone_rounded, color: Color(0xFF007AEB)),
                              onPressed: () => _showMessage('Calling ${m['name']}...'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 5. SHELTER DETAILS MODAL
  void _showShelterDetailsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.night_shelter_rounded, color: Color(0xFF15945C), size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isHindi ? 'सरकारी राहत केंद्र' : 'Government Relief Centre',
                        style: const TextStyle(color: Color(0xFF013973), fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                      const Text('Sector 4 High Ground, Bokaro • 1.8 km', style: TextStyle(color: Color(0xFF537392), fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Text(
              _isHindi ? 'शिविर सुविधाएं एवं स्थिति' : 'Shelter Amenities & Readiness',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF013973)),
            ),
            const SizedBox(height: 10),
            _buildShelterRow(Icons.groups_rounded, _isHindi ? 'क्षमता' : 'Occupancy', '72 / 100 Beds Occupied (28 Remaining)'),
            _buildShelterRow(Icons.rice_bowl_rounded, _isHindi ? 'भोजन' : 'Clean Food', 'Hot Meals & Drinking Water Stocked'),
            _buildShelterRow(Icons.medical_services_rounded, _isHindi ? 'चिकित्सा' : 'Medical Staff', '1 Doctor & 2 Registered Nurses On-Duty'),
            _buildShelterRow(Icons.bolt_rounded, _isHindi ? 'पावर' : 'Generator', 'Emergency Diesel Generator Active'),
            _buildShelterRow(Icons.wifi_rounded, _isHindi ? 'संचार' : 'Radio Mesh', 'LoRa Relay + Satellite Phone Hub'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CitizenSafeRouteView(isHindi: _isHindi)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF15945C),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.directions_run_rounded, color: Colors.white),
                label: Text(
                  _isHindi ? 'इस शिविर का सुरक्षित मार्ग शुरू करें' : 'NAVIGATE SAFE CORRIDOR TO SHELTER',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShelterRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF007AEB)),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5, color: Color(0xFF013973))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 11.5, color: Color(0xFF0F2642)))),
        ],
      ),
    );
  }

  // 6. MEDICAL / HOSPITAL MODAL
  void _showMedicalDetailsModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_hospital_rounded, color: Color(0xFF0284C7), size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isHindi ? 'जिला सामान्य अस्पताल' : 'District General Hospital',
                        style: const TextStyle(color: Color(0xFF013973), fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                      const Text('Sector 1 Civic Center • 3.2 km away', style: TextStyle(color: Color(0xFF537392), fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            _buildShelterRow(Icons.bed_rounded, _isHindi ? 'इमरजेंसी बेड' : 'Emergency Beds', '18 Trauma Beds Available'),
            _buildShelterRow(Icons.local_shipping_rounded, _isHindi ? 'एम्बुलेंस' : 'Ambulance Units', '3 High-Water Ambulances On Standby'),
            _buildShelterRow(Icons.bloodtype_rounded, _isHindi ? 'ब्लड बैंक' : 'Blood Bank', 'All Types Available in Emergency Reserve'),
            _buildShelterRow(Icons.phone_in_talk_rounded, _isHindi ? 'हेल्पलाइन' : 'Direct Helpline', '06542-230001 / 108'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showMessage('Calling 06542-230001...');
                    },
                    icon: const Icon(Icons.phone, size: 16),
                    label: Text(_isHindi ? 'कॉल करें' : 'Call Hospital'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showMessage('Routing to District Hospital');
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                    icon: const Icon(Icons.directions, color: Colors.white, size: 16),
                    label: Text(_isHindi ? 'नेविगेट' : 'Directions', style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 7. ROAD CONDITIONS MODAL
  void _showRoadConditionsModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.traffic_rounded, color: Color(0xFF013973), size: 24),
                const SizedBox(width: 8),
                Text(
                  _isHindi ? 'सड़क एवं पुल स्थिति रिपोर्ट' : 'Local Road & Bridge Report',
                  style: const TextStyle(color: Color(0xFF013973), fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const Divider(height: 20),
            _buildRoadItem(
              name: 'Main Bypass Highway (Sector 1 to 4)',
              status: 'OPEN & CLEAR',
              statusColor: const Color(0xFF15945C),
              icon: Icons.check_circle_rounded,
            ),
            const SizedBox(height: 8),
            _buildRoadItem(
              name: 'Hill Ridge Elevation Road',
              status: 'SLOW / WATER POOLING',
              statusColor: const Color(0xFFF39A20),
              icon: Icons.warning_rounded,
            ),
            const SizedBox(height: 8),
            _buildRoadItem(
              name: 'Damodar River Causeway Bridge',
              status: 'SUBMERGED - STRICTLY CLOSED',
              statusColor: const Color(0xFFE92828),
              icon: Icons.cancel_rounded,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF8F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _isHindi
                    ? '💡 सलाह: राहत केंद्र पहुंचने के लिए केवल ग्रीन सुरक्षित मार्ग (हाईवे बायपास) का ही उपयोग करें।'
                    : '💡 Safe Corridor Recommendation: Stick strictly to the green Safe Route along high ground.',
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF15945C), fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 8. WEATHER FORECAST MODAL
  void _showWeatherForecastModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_sync_rounded, color: Color(0xFF007AEB), size: 24),
                const SizedBox(width: 8),
                Text(
                  _isHindi ? 'मौसम एवं वर्षा पूर्वानुमान' : 'Weather & Radar Forecast',
                  style: const TextStyle(color: Color(0xFF013973), fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const Divider(height: 20),
            Text(
              _isHindi ? 'अगले 6 घंटे का अनुमान (IMD डॉप्लर रडार)' : 'Next 6 Hours Outlook (Doppler Radar)',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF013973)),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildHourlyRain('Now', '🌧️🌧️', '35 mm/h', 'High'),
                _buildHourlyRain('+1 hr', '🌧️🌧️🌧️', '48 mm/h', 'Peak'),
                _buildHourlyRain('+2 hr', '🌧️🌧️', '30 mm/h', 'High'),
                _buildHourlyRain('+3 hr', '🌧️', '14 mm/h', 'Moderate'),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _isHindi
                  ? 'चेतावनी: पिक ऑवर (+1 घंटा) के दौरान नदी तट के निचले वार्डों में पानी 15-25 सेमी बढ़ सकता है।'
                  : 'Notice: Peak rain influx will hit at +1 hr. Low-lying riverside wards should expect 15-25cm rise.',
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF537392)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyRain(String time, String icon, String rain, String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F8FD),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(time, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF013973))),
          const SizedBox(height: 4),
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(rain, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
          Text(tag, style: const TextStyle(color: Color(0xFFE92828), fontSize: 9.5, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // 9. FULL SAFETY INSTRUCTIONS MODAL
  void _showSafetyInstructionsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shield_rounded, color: Color(0xFF15945C), size: 26),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isHindi ? 'आपदा सुरक्षा गाइड (NDMA)' : 'Citizen Safety Guide (NDMA)',
                    style: const TextStyle(color: Color(0xFF013973), fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.of(ctx).pop(),
                  tooltip: 'Close',
                ),
              ],
            ),
            const Divider(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildSafetySection(
                    _isHindi ? '1. बाढ़ से पहले क्या करें (तैयारी)' : '1. Before Flood Waters Rise (Preparation)',
                    [
                      'Keep emergency documents, IDs & prescription medicines in water-sealed bags.',
                      'Store at least 3 days of potable water and non-perishable rations.',
                      'Charge power banks and cellphones fully; memorize helpline 112.',
                      'Know your designated high-ground shelter & evacuation corridor.',
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildSafetySection(
                    _isHindi ? '2. बाढ़ के दौरान क्या करें (निकासी)' : '2. During Flooding (Evacuation & Survival)',
                    [
                      'Never drive or wade through floodwaters — 15 cm of moving water can knock you down.',
                      'Disconnect main power switches before water enters your house.',
                      'Do not touch electric wires, fallen transformers, or submerged poles.',
                      'Move immediately to first floor or roof if evacuation route is compromised, and broadcast SOS.',
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildSafetySection(
                    _isHindi ? '3. बाढ़ के बाद क्या करें (सुरक्षित वापसी)' : '3. After Flood Waters Recede',
                    [
                      'Do not drink tap or well water until officially verified as potable.',
                      'Beware of venomous snakes and reptiles that seek shelter in dry buildings.',
                      'Report damaged structures and broken electrical cables to authorities.',
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetySection(String title, List<String> points) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Color(0xFF013973), fontWeight: FontWeight.w900, fontSize: 13.5)),
        const SizedBox(height: 6),
        ...points.map((p) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: Color(0xFF007AEB), fontWeight: FontWeight.bold, fontSize: 14)),
                  Expanded(child: Text(p, style: const TextStyle(fontSize: 12, color: Color(0xFF0F2642), height: 1.3))),
                ],
              ),
            )),
      ],
    );
  }
}

class _QuickActionItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Color cardBgColor;
  final Color borderColor;
  final Color iconCircleColor;
  final IconData? watermarkIcon;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.cardBgColor,
    required this.borderColor,
    required this.iconCircleColor,
    this.watermarkIcon,
    required this.onTap,
  });
}

// ---------------------------------------------------------------------------
// Quick Action Card Top-Right Corner Wave Painter (matches exact screenshot design)
// ---------------------------------------------------------------------------
class _CardCornerWavePainter extends CustomPainter {
  final Color color;
  const _CardCornerWavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width * 0.46, 0);
    path.cubicTo(
      size.width * 0.52, size.height * 0.16,
      size.width * 0.70, size.height * 0.34,
      size.width, size.height * 0.58,
    );
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CardCornerWavePainter oldDelegate) =>
      oldDelegate.color != color;
}

