import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'citizen/citizen_login_screen.dart';
import 'field_responder_view.dart';
import 'admin_console_view.dart';

enum UserRole {
  authority,
  fieldResponder,
  citizen,
  adminConsole,
}

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  // Default selected role is Citizen (or user can choose any of the 4)
  UserRole _selectedRole = UserRole.citizen;

  void _proceedWithRole(UserRole role) {
    switch (role) {
      case UserRole.citizen:
        // Routes to the dedicated Citizen Entrance (Mobile OTP Login & GPS Permissions)
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CitizenLoginScreen()),
        );
        break;

      case UserRole.authority:
        // Routes directly to the existing Authority Dashboard (HomeScreen)
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
        break;

      case UserRole.fieldResponder:
        // Routes to the dedicated Field Responder Tactical View
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FieldResponderView()),
        );
        break;

      case UserRole.adminConsole:
        // Routes to the dedicated Technical / System Admin Console
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AdminConsoleView()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9F4FB),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Scenic background image matching the ResQShield visual system
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_bg.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),

          // 2. High-readability soft tint overlay
          Positioned.fill(
            child: Container(
              color: const Color(0xFFE9F4FB).withValues(alpha: 0.45),
            ),
          ),

          // 3. Scrollable content
          SafeArea(
            child: Column(
              children: [
                // Top Navigation Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Color(0xFF013973),
                          size: 20,
                        ),
                        onPressed: () => Navigator.maybePop(context),
                        tooltip: 'Back',
                      ),
                      const Spacer(),
                      // Brand Logo + Title
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/app_logo.png',
                            width: 32,
                            height: 32,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 8),
                          RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Res',
                                  style: TextStyle(
                                    color: Color(0xFF013973),
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Q',
                                  style: TextStyle(
                                    color: Color(0xFF00FF00),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.2,
                                    shadows: [
                                      Shadow(
                                        color: Color(0x6600FF00),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                                TextSpan(
                                  text: 'Shield',
                                  style: TextStyle(
                                    color: Color(0xFF013973),
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const SizedBox(width: 48), // Balance leading back button
                    ],
                  ),
                ),

                // Main Content List
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 6),

                        // Section Title & Subtitle
                        const Text(
                          'Select Your Role',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF013973),
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Choose your operational profile to access customized disaster mitigation and response interfaces.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF537392),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Role 1: Authority Command Center
                        _buildRoleCard(
                          role: UserRole.authority,
                          title: 'Authority Command Center',
                          subtitle: 'NDRF / SDMA / District Administration',
                          description:
                              'Centralized crisis dashboard, live dam releases, river telemetry gauges, shelter capacity, and strategic rescue team deployments.',
                          icon: Icons.admin_panel_settings_rounded,
                          accentColor: const Color(0xFF013973),
                          badgeText: 'COMMAND & CONTROL',
                        ),

                        const SizedBox(height: 12),

                        // Role 2: Field Responder
                        _buildRoleCard(
                          role: UserRole.fieldResponder,
                          title: 'Field Responder',
                          subtitle: 'NDRF Teams, Police, PWD, Local Responders',
                          description:
                              'Tactical ground dispatch, casualty triage logger, route blockages, telemetry sync over LoRa mesh, and equipment readiness.',
                          icon: Icons.health_and_safety_rounded,
                          accentColor: const Color(0xFF15945C),
                          badgeText: 'TACTICAL FIELD UNITS',
                        ),

                        const SizedBox(height: 12),

                        // Role 3: Citizen / General Public
                        _buildRoleCard(
                          role: UserRole.citizen,
                          title: 'Citizen / General Public',
                          subtitle: 'Villagers / General Citizens',
                          description:
                              'Real-time evacuation routes, nearest relief camps & hospitals, instant emergency SOS broadcast, and community hazard reporting.',
                          icon: Icons.people_alt_rounded,
                          accentColor: const Color(0xFF007AEB),
                          badgeText: 'PUBLIC ACCESS & SOS',
                        ),

                        const SizedBox(height: 12),

                        // Role 4: Technical / Admin Console
                        _buildRoleCard(
                          role: UserRole.adminConsole,
                          title: 'Technical / Admin Console',
                          subtitle: 'System Administrators & Engineers',
                          description:
                              'Telemetry pipeline monitoring, CWC/IMD API health, CAP broadcast overrides, GIS layer caches, and cluster server audit trails.',
                          icon: Icons.terminal_rounded,
                          accentColor: const Color(0xFF7351D8),
                          badgeText: 'INFRASTRUCTURE & SYSADMIN',
                        ),

                        const SizedBox(height: 22),

                        // Primary Action Button
                        ElevatedButton(
                          onPressed: () => _proceedWithRole(_selectedRole),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF007AEB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 4,
                            shadowColor: const Color(0xFF007AEB).withValues(alpha: 0.35),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _getButtonLabel(_selectedRole),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Emergency Helpline Info
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFD6E8F7)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.call_rounded, size: 15, color: Color(0xFFE92828)),
                              SizedBox(width: 6),
                              Text(
                                'National Disaster Helpline: ',
                                style: TextStyle(
                                  color: Color(0xFF537392),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '1070 / 112',
                                style: TextStyle(
                                  color: Color(0xFFE92828),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getButtonLabel(UserRole role) {
    switch (role) {
      case UserRole.citizen:
        return 'Continue to Citizen Login';
      case UserRole.authority:
        return 'Access Command Center';
      case UserRole.fieldResponder:
        return 'Open Tactical Field Portal';
      case UserRole.adminConsole:
        return 'Open Admin Console';
    }
  }

  // --------------------------------------------------------------------------
  // ROLE CARD BUILDER
  // --------------------------------------------------------------------------
  Widget _buildRoleCard({
    required UserRole role,
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required Color accentColor,
    required String badgeText,
  }) {
    final bool isSelected = _selectedRole == role;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? accentColor : const Color(0xFFD6E8F7),
          width: isSelected ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? accentColor.withValues(alpha: 0.15)
                : const Color(0xFF013973).withValues(alpha: 0.04),
            blurRadius: isSelected ? 12 : 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              _selectedRole = role;
            });
          },
          onDoubleTap: () => _proceedWithRole(role),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Role Icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: accentColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    // Titles & Badge
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  badgeText,
                                  style: TextStyle(
                                    color: accentColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            title,
                            style: const TextStyle(
                              color: Color(0xFF013973),
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: Color(0xFF537392),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Radio indicator
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? accentColor : const Color(0xFFBEDCF5),
                          width: 2,
                        ),
                        color: isSelected ? accentColor : Colors.transparent,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF537392),
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
