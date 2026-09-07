import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/custom_painters.dart';
import '../widgets/dos_donts_section.dart';
import '../widgets/live_flood_map_widget.dart';
import 'river_level_detail_screen.dart';
import 'rainfall_detail_screen.dart';
import 'affected_people_detail_screen.dart';
import 'rescue_teams_detail_screen.dart';

// ============================================================
// COLORS
// ============================================================

class AppColors {
  // Soft blue-grey background gradient palette
  static const bgPrimary = Color(0xFF8FA9BC); // Primary: #8FA9BC (RGB: 143, 169, 188)
  static const bgTop = Color(0xFF7E98AE);     // Top/primary: #7E98AE
  static const bgMain = Color(0xFF8FA9BC);    // Main: #8FA9BC
  static const bgLight = Color(0xFFB4C9D8);   // Lighter areas: #B4C9D8
  static const bgBottom = Color(0xFF99ADBF);  // Bottom: #99ADBF

  static const navy = Color(0xFF7E98AE);
  static const darkBlue = Color(0xFF5A758B);
  static const blue = Color(0xFF0877C9);
  static const lightBlue = Color(0xFF35A9E8);

  static const white = Color(0xFFFDFEFF);
  static const text = Color(0xFF10233D);
  static const muted = Color(0xFF607086);

  static const red = Color(0xFFE92828);
  static const orange = Color(0xFFF39A20);
  static const green = Color(0xFF15945C);
  static const purple = Color(0xFF7351D8);

  static const paleRed = Color(0xFFFFEEEE);
  static const paleOrange = Color(0xFFFFF5E7);
  static const paleGreen = Color(0xFFEAF8F0);
}

// ============================================================
// HOME SCREEN
// ============================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedBottomIndex = 0;

  // ------------------------------------------------------------------
  // LOCATION STATE
  // ------------------------------------------------------------------
  String _locationText = 'Locating...';
  double? _latitude;
  double? _longitude;
  bool _locationLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    try {
      // Check if location service is on — 3s timeout
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled().timeout(
        const Duration(seconds: 3),
        onTimeout: () => false,
      );

      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _locationText = 'Location Service Off';
            _locationLoading = false;
          });
        }
        return;
      }

      // Check existing permission (no dialog, just reads current status)
      LocationPermission permission = await Geolocator.checkPermission()
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () => LocationPermission.denied,
          );

      // Only request if not already granted — 5s timeout
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission().timeout(
          const Duration(seconds: 5),
          onTimeout: () => LocationPermission.denied,
        );
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _locationText = 'Location Permission Denied';
            _locationLoading = false;
          });
        }
        return;
      }

      // Fetch actual GPS position — low accuracy is faster, 12s outer timeout
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 12),
      );

      if (mounted) {
        setState(() {
          _latitude = pos.latitude;
          _longitude = pos.longitude;
          _locationText =
              '${pos.latitude.toStringAsFixed(4)}°N, ${pos.longitude.toStringAsFixed(4)}°E';
          _locationLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationText = 'Unable to fetch location';
          _locationLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showEmergencyDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.paleRed,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.sos_rounded,
                color: AppColors.red,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Emergency Rescue',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Immediate Assistance Helplines:',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _emergencyCallTile('National Disaster Helpline', '1070'),
            _emergencyCallTile('State Control Room (Kerala)', '1077'),
            _emergencyCallTile('Medical Emergency & Ambulance', '108'),
            _emergencyCallTile('Police & Integrated Emergency', '112'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _showMessage('Broadcasting live GPS coordinates to NDRF team...');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.my_location_rounded, size: 18),
            label: const Text('Send SOS Alert'),
          ),
        ],
      ),
    );
  }

  Widget _emergencyCallTile(String title, String number) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E9EE)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  Text(
                    number,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.red,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.phone_in_talk_rounded,
                color: AppColors.green,
              ),
              onPressed: () => _showMessage('Dialing $number...'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,

      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            const Positioned.fill(child: BackgroundWater()),

            Column(children: [Expanded(child: _buildScrollableHome())]),
          ],
        ),
      ),

      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildScrollableHome() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 8),

          _buildHeader(),

          const SizedBox(height: 12),

          _buildLocationCard(),

          const SizedBox(height: 12),

          _buildMainAlert(),

          const SizedBox(height: 16),

          _buildLiveSituation(),

          const SizedBox(height: 16),

          _buildQuickSituation(),

          const SizedBox(height: 16),

          _buildFloodMap(),

          const SizedBox(height: 24),

          _buildSectionCaption(
            icon: Icons.notifications_active_rounded,
            title: 'LATEST ALERTS & WARNINGS',
            subtitle: 'Real-time flood alerts and critical updates',
          ),

          const SizedBox(height: 14),

          _buildLatestAlerts(),

          const SizedBox(height: 24),

          _buildSectionCaption(
            icon: Icons.home_rounded,
            title: 'SHELTERS + RELIEF POINTS',
            subtitle: 'Shelter availability & relief distribution status',
          ),

          const SizedBox(height: 14),

          _buildNearbyShelters(),

          const SizedBox(height: 16),

          _buildReliefPoints(),

          const SizedBox(height: 24),

          _buildSectionCaption(
            icon: Icons.local_hospital_rounded,
            title: 'MEDICAL + AMBULANCE',
            subtitle: 'Hospitals, beds, ICU & ambulance availability',
          ),

          const SizedBox(height: 14),

          _buildMedicalFacilities(),

          const SizedBox(height: 16),

          _buildAmbulances(),

          const SizedBox(height: 24),

          _buildSectionCaption(
            icon: Icons.alt_route_rounded,
            title: 'ROUTES + INFRASTRUCTURE',
            subtitle: 'Safe evacuation routes & infrastructure status',
          ),

          const SizedBox(height: 14),

          _buildSafeRoutes(),

          const SizedBox(height: 24),

          _buildSectionCaption(
            icon: Icons.camera_alt_rounded,
            title: 'REPORTS + MORE TOOLS',
            subtitle: 'Citizen reports, water quality, weather & more',
          ),

          const SizedBox(height: 14),

          _buildReportSituation(),

          const SizedBox(height: 16),

          _buildCommunityReports(),

          const SizedBox(height: 16),

          _buildMoreTools(),

          const SizedBox(height: 24),

          _buildSectionCaption(
            icon: Icons.rule_rounded,
            title: 'DO\'S & DON\'TS (SAFETY GUIDELINES)',
            subtitle: 'Critical precautions and safety measures during floods',
          ),

          const SizedBox(height: 14),

          _buildDosDonts(),

          const SizedBox(height: 35),

          _buildBottomMessage(),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ==========================================================
  // HEADER
  // ==========================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          _roundIconButton(
            icon: Icons.menu_rounded,
            onTap: () {
              _showMessage('Menu opened');
            },
          ),

          const Spacer(),

          Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    padding: const EdgeInsets.all(2),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Res',
                          style: TextStyle(
                            color: Color(0xFF38BDF8),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        TextSpan(
                          text: 'Q',
                          style: TextStyle(
                            color: Color(0xFF22C55E),
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        TextSpan(
                          text: 'Shield',
                          style: TextStyle(
                            color: Color(0xFF38BDF8),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                'Safer Routes. Stronger Communities.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.86),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),

          const Spacer(),

          Stack(
            clipBehavior: Clip.none,
            children: [
              _roundIconButton(
                icon: Icons.notifications_none_rounded,
                onTap: () {
                  _showMessage('3 new alerts');
                },
              ),

              Positioned(
                right: -1,
                top: -4,
                child: Container(
                  width: 19,
                  height: 19,
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.bgTop, width: 2),
                  ),
                  child: const Center(
                    child: Text(
                      '3',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
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

  Widget _roundIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            icon,
            color: Colors.white,
            size: 27,
            shadows: const [
              Shadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 1)),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // LOCATION CARD
  // ==========================================================

  Widget _buildLocationCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A4F7A), Color(0xFF063A5B)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF0877C9).withOpacity(0.45),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.22),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF0877C9).withOpacity(0.18),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: const Color(0xFF0877C9).withOpacity(0.4),
                ),
              ),
              child: const Icon(
                Icons.my_location_rounded,
                color: Color(0xFF35A9E8),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Aapki Current Location',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  _locationLoading
                      ? Row(
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.8,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              'Locating...',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          _locationText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                ],
              ),
            ),
            // Refresh button
            GestureDetector(
              onTap: () {
                setState(() {
                  _locationLoading = true;
                  _locationText = 'Locating...';
                });
                _fetchLocation();
              },
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.refresh_rounded,
                  color: Colors.white.withOpacity(0.65),
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // MAIN FLOOD ALERT
  // ==========================================================

  Widget _buildMainAlert() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF0284C7).withValues(alpha: 0.5),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0284C7).withValues(alpha: 0.22),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 960 / 316,
                child: Image.asset(
                  'assets/images/flood_risk_high_banner.png',
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(19),
                    onTap: () {
                      _showMessage('Flood details opened');
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // LIVE SITUATION
  // ==========================================================

  Widget _buildLiveSituation() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 15),
      decoration: BoxDecoration(
        color: const Color(0xFF091E33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1E3A5F).withOpacity(0.8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF38BDF8),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              const Text(
                'Live Situation',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  _showMessage('Map opened');
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'View Map',
                      style: TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 3),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Color(0xFF38BDF8),
                      size: 12,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              _imageSituationCard(
                imagePath: 'assets/images/river_level_card.png',
                fallbackTitle: 'River Level',
                fallbackValue: '8.2 m',
                fallbackSub: 'Rising Fast ↑',
                fallbackAccent: const Color(0xFFEF4444),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RiverLevelDetailScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(width: 10),

              _imageSituationCard(
                imagePath: 'assets/images/rainfall_card.png',
                fallbackTitle: 'Rainfall',
                fallbackValue: '128 mm',
                fallbackSub: 'Last 6 hrs',
                fallbackAccent: const Color(0xFF3B82F6),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RainfallDetailScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              _imageSituationCard(
                imagePath: 'assets/images/affected_people_card.png',
                fallbackTitle: 'Affected People',
                fallbackValue: '12,450',
                fallbackSub: 'In 18 Areas',
                fallbackAccent: const Color(0xFFF59E0B),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AffectedPeopleDetailScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(width: 10),

              _imageSituationCard(
                imagePath: 'assets/images/rescue_teams_card.png',
                fallbackTitle: 'Rescue Teams',
                fallbackValue: '24',
                fallbackSub: 'Active',
                fallbackAccent: const Color(0xFFA855F7),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RescueTeamsDetailScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _imageSituationCard({
    required String imagePath,
    required String fallbackTitle,
    required String fallbackValue,
    required String fallbackSub,
    required Color fallbackAccent,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 1.28,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF1E466E).withValues(alpha: 0.8),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Image.asset(
                imagePath,
                fit: BoxFit.fill,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF0F2B44),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fallbackTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fallbackValue,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fallbackSub,
                        style: TextStyle(
                          color: fallbackAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // QUICK SITUATION
  // ==========================================================

  Widget _buildQuickSituation() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF091E33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1E3A5F).withOpacity(0.8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3.5,
                height: 17,
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Quick Situation',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Color(0xFF38BDF8),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _qsCard(
                imagePath: 'assets/images/qs_sos_card.png',
                accentColor: const Color(0xFFEF4444),
                onTap: () {
                  _showEmergencyDialog();
                },
              ),
              const SizedBox(width: 6),
              _qsCard(
                imagePath: 'assets/images/qs_shelter_card.png',
                accentColor: const Color(0xFF34D399),
                onTap: () {
                  _showMessage('Finding nearby shelters...');
                },
              ),
              const SizedBox(width: 6),
              _qsCard(
                imagePath: 'assets/images/qs_medical_card.png',
                accentColor: const Color(0xFF38BDF8),
                onTap: () {
                  _showMessage('Finding medical help...');
                },
              ),
              const SizedBox(width: 6),
              _qsCard(
                imagePath: 'assets/images/qs_safe_route_card.png',
                accentColor: const Color(0xFFA78BFA),
                onTap: () {
                  _showMessage('Safe route finder opened');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qsCard({
    required String imagePath,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.35),
            width: 1,
          ),
          boxShadow: [
            // Ambient elevation drop shadow
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
            // Soft colored glow
            BoxShadow(
              color: accentColor.withValues(alpha: 0.18),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 230 / 294,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFF0F2B44),
                  ),
                ),
              ),
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: onTap,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // FLOOD MAP
  // ==========================================================

  Widget _buildFloodMap() {
    return LiveFloodMapWidget(
      latitude: _latitude,
      longitude: _longitude,
      locationName: _locationText,
    );
  }

  // ==========================================================
  // SECTION CAPTION
  // ==========================================================

  Widget _buildSectionCaption({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 23),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 21,
            shadows: const [
              Shadow(
                color: Color(0x38000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    shadows: [
                      Shadow(
                        color: Color(0x38000000),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 11,
                    height: 1.25,
                    shadows: const [
                      Shadow(
                        color: Color(0x2E000000),
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // LATEST ALERTS
  // ==========================================================

  Widget _buildLatestAlerts() {
    return Column(
      children: [
        _buildAlertImageCard('assets/images/alert_flood_risk_card.png', 'High Flood Risk alert'),
        const SizedBox(height: 14),
        _buildAlertImageCard('assets/images/alert_rainfall_card.png', 'Heavy Rainfall alert'),
        const SizedBox(height: 14),
        _buildAlertImageCard('assets/images/alert_dam_release_card.png', 'Dam Water Release alert'),
      ],
    );
  }

  Widget _buildAlertImageCard(String imagePath, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: GestureDetector(
        onTap: () {
          _showMessage(message);
        },
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // DOS AND DON'TS
  // ==========================================================

  Widget _buildDosDonts() {
    return DosDontsSection(
      onViewAll: () {
        _showMessage('Safety guidelines opened');
      },
      onShowMessage: (msg) => _showMessage(msg),
    );
  }

  // ==========================================================
  // ==========================================================
  // SHELTERS (MODERN CARD UI MATCHING SCREENSHOT)
  // ==========================================================

  Widget _buildNearbyShelters() {
    final shelters = [
      const _ShelterData(
        imagePath: 'assets/images/shelter_school.jpg',
        category: 'Government',
        categoryIcon: Icons.account_balance_outlined,
        categoryBg: Color(0xFFEBF5FF),
        categoryColor: Color(0xFF1D70B8),
        status: 'Open',
        isOpen: true,
        name: 'Govt. Higher Secondary School',
        location: 'Bokaro, Jharkhand',
        capacity: '500',
        available: '320',
        foodAvailable: true,
        foodWarning: false,
        waterAvailable: true,
        filterCategory: 'Govt.',
      ),
      const _ShelterData(
        imagePath: 'assets/images/shelter_community.jpg',
        category: 'Community',
        categoryIcon: Icons.groups_outlined,
        categoryBg: Color(0xFFE8F5E9),
        categoryColor: Color(0xFF2E7D32),
        status: 'Limited',
        isOpen: false,
        name: 'Community Hall, Kurma',
        location: 'Giridih, Jharkhand',
        capacity: '300',
        available: '120',
        foodAvailable: true,
        foodWarning: true,
        waterAvailable: true,
        filterCategory: 'Community',
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5F8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFCEE8EF), width: 1.2),
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
          // Header Banner matching the relief header
          _buildSheltersHeader(),

          const SizedBox(height: 12),

          // 2 Shelter Cards
          ...shelters.map((shelter) => Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: _shelterCard(shelter),
              )),

          const SizedBox(height: 2),

          // View All Shelters Button
          _outlineButton(
            text: 'View All Shelters (28)',
            icon: Icons.home_work_rounded,
            onTap: () {
              _showMessage('All 28 relief shelters opened');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSheltersHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF072B4E), Color(0xFF0E4574), Color(0xFF135A94)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF072B4E).withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: Color(0xFF7DD3FC),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Nearby Shelters',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Find safe places near you',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              _showMessage('Opening live shelter map...');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.map_outlined,
                    color: Colors.white,
                    size: 12,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'View Map →',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
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

  Widget _shelterCard(_ShelterData data) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEF5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Real Photo
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 105,
              height: 112,
              child: Image.asset(
                data.imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFE2E8F0),
                  child: const Center(
                    child: Icon(
                      Icons.apartment_rounded,
                      color: Color(0xFF94A3B8),
                      size: 36,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Right Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Category + Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: data.categoryBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            data.categoryIcon,
                            size: 11,
                            color: data.categoryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            data.category,
                            style: TextStyle(
                              color: data.categoryColor,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: data.isOpen
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                        border: data.isOpen
                            ? null
                            : Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            data.isOpen
                                ? Icons.check_circle_rounded
                                : Icons.warning_amber_rounded,
                            size: 11,
                            color: data.isOpen
                                ? Colors.white
                                : const Color(0xFFD97706),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            data.status,
                            style: TextStyle(
                              color: data.isOpen
                                  ? Colors.white
                                  : const Color(0xFFD97706),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                // Name
                Text(
                  data.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 2),

                // Location
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 11,
                      color: Color(0xFF1D70B8),
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        data.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                // Stats: Capacity & Available + Arrow
                Row(
                  children: [
                    const Icon(
                      Icons.groups_rounded,
                      size: 13,
                      color: Color(0xFF1E3A5F),
                    ),
                    const SizedBox(width: 4),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Capacity',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 7.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          data.capacity,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.person_add_alt_1_rounded,
                      size: 13,
                      color: Color(0xFF16A34A),
                    ),
                    const SizedBox(width: 4),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Available',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 7.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          data.available,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFF1F5F9),
                      ),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Color(0xFF1E3A5F),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                // Amenities Capsule
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F7FD),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.restaurant_rounded,
                        size: 11,
                        color: Color(0xFF1E3A5F),
                      ),
                      const SizedBox(width: 3),
                      const Text(
                        'Food',
                        style: TextStyle(
                          fontSize: 9,
                          color: Color(0xFF334155),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        data.foodWarning
                            ? Icons.warning_rounded
                            : Icons.check_circle_rounded,
                        size: 11,
                        color: data.foodWarning
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF16A34A),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.water_drop_rounded,
                        size: 11,
                        color: Color(0xFF0284C7),
                      ),
                      const SizedBox(width: 3),
                      const Text(
                        'Water',
                        style: TextStyle(
                          fontSize: 9,
                          color: Color(0xFF334155),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 11,
                        color: Color(0xFF16A34A),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // ==========================================================
  // RELIEF CAMPS & DISTRIBUTION POINTS (MATCHING SCREENSHOT)
  // ==========================================================

  Widget _buildReliefPoints() {
    final reliefCamps = [
      const _ReliefCampData(
        imagePath: 'assets/images/relief_bokaro.jpg',
        name: 'Bokaro Relief Camp',
        location: 'Bokaro, Jharkhand',
        food: '1200 packets',
        water: '1800 bottles',
        distance: '2.8 km away',
        status: 'Active',
        isActive: true,
      ),
      const _ReliefCampData(
        imagePath: 'assets/images/relief_dhanbad.jpg',
        name: 'Dhanbad Relief Camp',
        location: 'Dhanbad, Jharkhand',
        food: '950 packets',
        water: '1500 bottles',
        distance: '3.6 km away',
        status: 'Low Stock',
        isActive: false,
      ),
      const _ReliefCampData(
        imagePath: 'assets/images/relief_giridih.jpg',
        name: 'Giridih Relief Camp',
        location: 'Giridih, Jharkhand',
        food: '700 packets',
        water: '1200 bottles',
        distance: '5.1 km away',
        status: 'Active',
        isActive: true,
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5F8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFCEE8EF), width: 1.2),
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
          // Header Banner matching the screenshot
          _buildReliefHeader(),

          const SizedBox(height: 12),

          // 3 Relief Camp Cards
          ...reliefCamps.map((camp) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _reliefCampCard(camp),
              )),

          const SizedBox(height: 2),

          // View All Relief Camps Button
          _outlineButton(
            text: 'View All Relief Camps (36)',
            icon: Icons.holiday_village_rounded,
            onTap: () {
              _showMessage('All 36 relief distribution camps opened');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReliefHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF072B4E), Color(0xFF0E4574), Color(0xFF135A94)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF072B4E).withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: const Icon(
              Icons.holiday_village_rounded,
              color: Color(0xFF7DD3FC),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Relief Camps',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Find nearby relief camps with food, water and essential supplies.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              _showMessage('Showing camps for Jharkhand');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5.5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.location_on_rounded, color: Colors.white, size: 11),
                  SizedBox(width: 3),
                  Text(
                    'Jharkhand',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 13),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reliefCampCard(_ReliefCampData data) {
    return InkWell(
      onTap: () {
        _showMessage('Opening ${data.name} details...');
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(8.5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFCCE4EC), width: 1.1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                data.imagePath,
                width: 108,
                height: 82,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 108,
                    height: 82,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F2642).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.image_not_supported_rounded,
                      color: Color(0xFF64748B),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(width: 10),

            // Middle Details Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Status Badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF0B2238),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: data.isActive
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: data.isActive
                                ? const Color(0xFF86EFAC)
                                : const Color(0xFFFDE68A),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5.5,
                              height: 5.5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: data.isActive
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFD97706),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              data.status,
                              style: TextStyle(
                                color: data.isActive
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFD97706),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 3),

                  // Location
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 11.5,
                        color: Color(0xFF0284C7),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          data.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Food
                  Row(
                    children: [
                      const Icon(
                        Icons.roofing_rounded,
                        size: 12,
                        color: Color(0xFF0F2642),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Food:  ',
                        style: TextStyle(
                          fontSize: 9.5,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        data.food,
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 2.5),

                  // Water
                  Row(
                    children: [
                      const Icon(
                        Icons.water_drop_rounded,
                        size: 11.5,
                        color: Color(0xFF0284C7),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Water: ',
                        style: TextStyle(
                          fontSize: 9.5,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        data.water,
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 2.5),

                  // Distance
                  Row(
                    children: [
                      const Icon(
                        Icons.alt_route_rounded,
                        size: 11.5,
                        color: Color(0xFF0F2642),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        data.distance,
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 4),

            // Chevron Right Arrow
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF0284C7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // MEDICAL FACILITIES (MATCHING SCREENSHOT)
  // ==========================================================

  Widget _buildMedicalFacilities() {
    final hospitals = [
      const _HospitalData(
        imagePath: 'assets/images/hospital_ranchi.jpg',
        name: 'Ranchi Sadar Hospital',
        location: 'Kanke, Ranchi, Jharkhand',
        beds: '450 / 650',
        icuAvailable: '40 / 60',
        distance: '2.8 km away',
        status: 'Open',
        isOpen: true,
      ),
      const _HospitalData(
        imagePath: 'assets/images/hospital_dhanbad.jpg',
        name: 'Dhanbad Medical College & Hospital',
        location: 'Sindri Road, Dhanbad, Jharkhand',
        beds: '320 / 500',
        icuAvailable: '25 / 40',
        distance: '3.6 km away',
        status: 'Open',
        isOpen: true,
      ),
      const _HospitalData(
        imagePath: 'assets/images/hospital_giridih.jpg',
        name: 'Giridih Sadar Hospital',
        location: 'Giridih, Jharkhand',
        beds: '210 / 350',
        icuAvailable: '18 / 30',
        distance: '5.2 km away',
        status: 'Open',
        isOpen: true,
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5F8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFCEE8EF), width: 1.2),
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
          // Header Banner matching the screenshot
          _buildMedicalHeader(),

          const SizedBox(height: 12),

          // 3 Hospital Cards
          ...hospitals.map((hospital) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _hospitalCard(hospital),
              )),

          const SizedBox(height: 2),

          // View All Hospitals Button
          _outlineButton(
            text: 'View All Hospitals (48)',
            icon: Icons.local_hospital_rounded,
            onTap: () {
              _showMessage('All 48 hospitals and healthcare centers opened');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF072B4E), Color(0xFF0E4574), Color(0xFF135A94)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF072B4E).withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: const Icon(
              Icons.local_hospital_rounded,
              color: Color(0xFF7DD3FC),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Medical Facilities',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Nearby hospitals and healthcare centers in flood-affected areas of Jharkhand.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              _showMessage('Showing medical facilities for Jharkhand');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5.5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.location_on_rounded, color: Colors.white, size: 11),
                  SizedBox(width: 3),
                  Text(
                    'Jharkhand',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 13),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hospitalCard(_HospitalData data) {
    return InkWell(
      onTap: () {
        _showMessage('Opening ${data.name} details & bed availability...');
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(8.5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFCCE4EC), width: 1.1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Hospital Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                data.imagePath,
                width: 108,
                height: 82,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 108,
                    height: 82,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F2642).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.local_hospital_rounded,
                      color: Color(0xFF64748B),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(width: 10),

            // Middle Details Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Status Badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF0B2238),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: data.isOpen
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: data.isOpen
                                ? const Color(0xFF86EFAC)
                                : const Color(0xFFFDE68A),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5.5,
                              height: 5.5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: data.isOpen
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFD97706),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              data.status,
                              style: TextStyle(
                                color: data.isOpen
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFD97706),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 3),

                  // Location
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 11.5,
                        color: Color(0xFF0284C7),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          data.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Beds
                  Row(
                    children: [
                      const Icon(
                        Icons.hotel_rounded,
                        size: 12,
                        color: Color(0xFF0F2642),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Beds:  ',
                        style: TextStyle(
                          fontSize: 9.5,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        data.beds,
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 2.5),

                  // ICU Available
                  Row(
                    children: [
                      const Icon(
                        Icons.personal_video_rounded,
                        size: 11.5,
                        color: Color(0xFF0284C7),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'ICU Available: ',
                        style: TextStyle(
                          fontSize: 9.5,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        data.icuAvailable,
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 2.5),

                  // Distance
                  Row(
                    children: [
                      const Icon(
                        Icons.alt_route_rounded,
                        size: 11.5,
                        color: Color(0xFF0F2642),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        data.distance,
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 4),

            // Chevron Right Arrow
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF0284C7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // AMBULANCES
  // ==========================================================

  Widget _buildAmbulances() {
    return _whiteCard(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.fromLTRB(13, 14, 13, 14),
      child: Column(
        children: [
          _cardHeader(
            title: 'Ambulance & Emergency Dispatch',
            action: 'Request Ambulance',
            onAction: () {
              _showMessage('Dispatching ambulance to your location...');
            },
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              const AmbulanceIllustration(width: 64, height: 54),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'NDRF Marine Rescue Unit #4',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Boat + ICU Ambulance Ready',
                      style: TextStyle(
                        color: AppColors.green,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'ETA: 8 minutes to Aluva Junction',
                      style: TextStyle(color: AppColors.muted, fontSize: 8),
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

  // ==========================================================
  // SAFE ROUTES & INFRASTRUCTURE
  // ==========================================================

  Widget _buildSafeRoutes() {
    return _whiteCard(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.fromLTRB(13, 14, 13, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
            title: 'Safe Evacuation Routes',
            action: 'Navigation →',
            onAction: () {
              _showMessage('Evacuation navigation started');
            },
          ),

          const SizedBox(height: 10),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 140,
              width: double.infinity,
              child: CustomPaint(painter: SafeRoutesPainter()),
            ),
          ),

          const SizedBox(height: 10),

          _routeStatusRow(
            icon: Icons.check_circle_rounded,
            color: AppColors.green,
            route: 'NH 544 via Kalamassery',
            status: 'CLEAR (Recommended)',
          ),
          const SizedBox(height: 6),
          _routeStatusRow(
            icon: Icons.cancel_rounded,
            color: AppColors.red,
            route: 'Low Level Periyar Bridge',
            status: 'BLOCKED (Submerged 1.2m)',
          ),
        ],
      ),
    );
  }

  Widget _routeStatusRow({
    required IconData icon,
    required Color color,
    required String route,
    required String status,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(
          route,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Text(
          status,
          style: TextStyle(
            color: color,
            fontSize: 8.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // CITIZEN REPORTS & TOOLS
  // ==========================================================

  Widget _buildReportSituation() {
    return _whiteCard(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.blue.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              color: AppColors.blue,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Report Flood or Water Logging',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Submit photo, water level & geotag to alert rescue',
                  style: TextStyle(color: AppColors.muted, fontSize: 9),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _showMessage('Report flood feature opened'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text(
              'Report',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityReports() {
    return _whiteCard(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
            title: 'Citizen Field Feed',
            action: 'Submit +',
            onAction: () => _showMessage('Citizen report camera activated'),
          ),
          const SizedBox(height: 10),
          _feedItem(
            'Water logging near Aluva KSRTC stand',
            '2m ago • Verified by 14 users',
          ),
          const Divider(height: 12),
          _feedItem(
            'Power grid shut down at Desom area for safety',
            '18m ago • Official Notice',
          ),
        ],
      ),
    );
  }

  Widget _feedItem(String title, String sub) {
    return Row(
      children: [
        const Icon(Icons.shield_outlined, size: 16, color: AppColors.blue),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              Text(
                sub,
                style: const TextStyle(fontSize: 8, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMoreTools() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          _toolTile(
            Icons.opacity_rounded,
            'Water Quality',
            AppColors.lightBlue,
          ),
          const SizedBox(width: 8),
          _toolTile(
            Icons.cloud_sync_rounded,
            'Radar Weather',
            AppColors.purple,
          ),
          const SizedBox(width: 8),
          _toolTile(Icons.contact_phone_rounded, 'Helplines', AppColors.orange),
        ],
      ),
    );
  }

  Widget _toolTile(IconData icon, String label, Color color) {
    return Expanded(
      child: InkWell(
        onTap: () => _showMessage('$label opened'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomMessage() {
    return Center(
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/app_logo.png',
                width: 20,
                height: 20,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 6),
              const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Res',
                      style: TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(
                      text: 'Q',
                      style: TextStyle(
                        color: Color(0xFF22C55E),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    TextSpan(
                      text: 'Shield Emergency Network',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        shadows: const [
                          Shadow(
                            color: Color(0x38000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Government of Kerala • Disaster Mitigation Cell',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
              shadows: const [
                Shadow(
                  color: Color(0x2E000000),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // BOTTOM NAVIGATION BAR
  // ==========================================================

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkBlue,
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.18), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: selectedBottomIndex,
        onTap: (index) {
          setState(() {
            selectedBottomIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.darkBlue,
        selectedItemColor: Colors.white,
        unselectedItemColor: const Color(0xFFB4C9D8),
        selectedFontSize: 9,
        unselectedFontSize: 9,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_rounded),
            label: 'Flood Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning_amber_rounded),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.night_shelter_rounded),
            label: 'Shelters',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Tools',
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // HELPER COMPONENTS
  // ==========================================================

  Widget _whiteCard({
    required EdgeInsets margin,
    required EdgeInsets padding,
    required Widget child,
  }) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _cardHeader({
    required String title,
    required String action,
    required VoidCallback onAction,
  }) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onAction,
          child: Text(
            action,
            style: const TextStyle(
              color: AppColors.blue,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _outlineButton({
    required String text,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.blue,
        side: const BorderSide(color: AppColors.blue),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon, size: 16), const SizedBox(width: 6)],
          Text(
            text,
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ==========================================================
// ANIMATED RAINFALL WIDGET
// ==========================================================

class AnimatedRainfallWidget extends StatefulWidget {
  const AnimatedRainfallWidget({super.key});

  @override
  State<AnimatedRainfallWidget> createState() => _AnimatedRainfallWidgetState();
}

class _AnimatedRainfallWidgetState extends State<AnimatedRainfallWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 25,
      width: 32,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Cloud icon shifted slightly to the right
              const Positioned(
                top: 0,
                right: 2,
                child: Icon(
                  Icons.cloud_rounded,
                  color: Color(0xFF38BDF8),
                  size: 19,
                ),
              ),
              // Falling Rain Drops underneath
              Positioned(
                top: 13,
                right: 3,
                width: 18,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildDrop((progress) % 1.0),
                    _buildDrop((progress + 0.33) % 1.0),
                    _buildDrop((progress + 0.66) % 1.0),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDrop(double animVal) {
    final currentY = animVal * 9.0;
    final opacity = (1.0 - animVal).clamp(0.1, 1.0);

    return Transform.translate(
      offset: Offset(0, currentY),
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: 1.5,
          height: 5.5,
          decoration: BoxDecoration(
            color: const Color(0xFF60A5FA),
            borderRadius: BorderRadius.circular(1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF38BDF8).withOpacity(0.8),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShelterData {
  final String imagePath;
  final String category;
  final IconData categoryIcon;
  final Color categoryBg;
  final Color categoryColor;
  final String status;
  final bool isOpen;
  final String name;
  final String location;
  final String capacity;
  final String available;
  final bool foodAvailable;
  final bool foodWarning;
  final bool waterAvailable;
  final String filterCategory;

  const _ShelterData({
    required this.imagePath,
    required this.category,
    required this.categoryIcon,
    required this.categoryBg,
    required this.categoryColor,
    required this.status,
    required this.isOpen,
    required this.name,
    required this.location,
    required this.capacity,
    required this.available,
    required this.foodAvailable,
    required this.foodWarning,
    required this.waterAvailable,
    required this.filterCategory,
  });
}

class _ReliefCampData {
  final String imagePath;
  final String name;
  final String location;
  final String food;
  final String water;
  final String distance;
  final String status;
  final bool isActive;

  const _ReliefCampData({
    required this.imagePath,
    required this.name,
    required this.location,
    required this.food,
    required this.water,
    required this.distance,
    required this.status,
    required this.isActive,
  });
}

class _HospitalData {
  final String imagePath;
  final String name;
  final String location;
  final String beds;
  final String icuAvailable;
  final String distance;
  final String status;
  final bool isOpen;

  const _HospitalData({
    required this.imagePath,
    required this.name,
    required this.location,
    required this.beds,
    required this.icuAvailable,
    required this.distance,
    required this.status,
    required this.isOpen,
  });
}
