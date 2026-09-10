import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'citizen_dashboard_screen.dart';

class CitizenPermissionScreen extends StatefulWidget {
  const CitizenPermissionScreen({super.key});

  @override
  State<CitizenPermissionScreen> createState() => _CitizenPermissionScreenState();
}

class _CitizenPermissionScreenState extends State<CitizenPermissionScreen> {
  bool _isRequesting = false;
  String? _statusMessage;

  Future<void> _requestLocationPermission() async {
    setState(() {
      _isRequesting = true;
      _statusMessage = 'Checking device location sensors...';
    });

    try {
      await Geolocator.isLocationServiceEnabled().timeout(
        const Duration(seconds: 4),
        onTimeout: () => false,
      );

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _statusMessage = 'Requesting GPS access...');
        permission = await Geolocator.requestPermission();
      }

      // If granted or if in testing/emulator environment, smoothly proceed
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      _navigateToDashboard();
    } catch (e) {
      if (!mounted) return;
      // Fail-soft: allow citizen to proceed even in emulator/demo mode
      _navigateToDashboard();
    } finally {
      if (mounted) {
        setState(() => _isRequesting = false);
      }
    }
  }

  void _navigateToDashboard() {
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const CitizenDashboardScreen(),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9F4FB),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/permission_bg.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: const Color(0xFFE9F4FB).withValues(alpha: 0.55),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),

                  // Top Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF013973).withValues(alpha: 0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Image.asset('assets/images/app_logo.png', fit: BoxFit.contain),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'ResQShield Citizen',
                        style: TextStyle(
                          color: Color(0xFF013973),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(flex: 1),

                  // Big Center Icon
                  Center(
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF007AEB).withValues(alpha: 0.12),
                        border: Border.all(color: const Color(0xFF007AEB).withValues(alpha: 0.3), width: 2),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.location_on_rounded,
                          size: 54,
                          color: Color(0xFF007AEB),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'GPS Location Permission\nis Essential for Your Safety',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF013973),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                      height: 1.25,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'During flood emergencies, seconds matter. Enabling location allows ResQShield to calculate life-saving escape routes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF537392),
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 3 Key Value Props Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFD6E8F7)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF013973).withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _benefitRow(
                          icon: Icons.alt_route_rounded,
                          color: const Color(0xFF007AEB),
                          title: 'Live Safe Route Navigation',
                          desc: 'Finds dry, elevated paths avoiding submerged culverts.',
                        ),
                        const Divider(height: 20, color: Color(0xFFE5E9EE)),
                        _benefitRow(
                          icon: Icons.night_shelter_rounded,
                          color: const Color(0xFF15945C),
                          title: 'Nearest Verified Shelters',
                          desc: 'Points to closest relief camps with food & doctors.',
                        ),
                        const Divider(height: 20, color: Color(0xFFE5E9EE)),
                        _benefitRow(
                          icon: Icons.sos_rounded,
                          color: const Color(0xFFE92828),
                          title: 'Accurate SOS Dispatch',
                          desc: 'Transmits GPS fix directly to NDRF rescue boats.',
                        ),
                      ],
                    ),
                  ),

                  if (_statusMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _statusMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF007AEB),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],

                  const Spacer(flex: 2),

                  // Primary Button
                  ElevatedButton(
                    onPressed: _isRequesting ? null : _requestLocationPermission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AEB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 3,
                    ),
                    child: _isRequesting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.near_me_rounded, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Grant GPS Location Access',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                  ),

                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: _navigateToDashboard,
                    child: const Text(
                      'Continue with Default Village Location (Bokaro Basin)',
                      style: TextStyle(
                        color: Color(0xFF537392),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _benefitRow({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF013973),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(
                  color: Color(0xFF537392),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
