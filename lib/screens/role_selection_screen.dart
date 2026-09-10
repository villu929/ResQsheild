import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'authority_verification_screen.dart';
import 'field_responder_verification_screen.dart';
import 'technical_admin_verification_screen.dart';
import 'login_screen.dart';

enum UserRole {
  authority,
  fieldResponder,
  citizen,
  adminConsole,
}

class _RoleModel {
  final UserRole role;
  final String title;
  final String subtitle;
  final String shortDescription;
  final IconData icon;
  final Color accentColor;
  final String badgeText;

  const _RoleModel({
    required this.role,
    required this.title,
    required this.subtitle,
    required this.shortDescription,
    required this.icon,
    required this.accentColor,
    required this.badgeText,
  });
}

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  // Default selected role is Citizen (or user can choose any of the 4)
  UserRole _selectedRole = UserRole.citizen;

  static const List<_RoleModel> _roles = [
    _RoleModel(
      role: UserRole.authority,
      title: 'Authority Command Center',
      subtitle: 'NDRF / SDMA / District Administration',
      shortDescription:
          'Live river gauges, dam discharge telemetry & rescue deployments.',
      icon: Icons.admin_panel_settings_rounded,
      accentColor: Color(0xFF013973),
      badgeText: 'COMMAND & CONTROL',
    ),
    _RoleModel(
      role: UserRole.fieldResponder,
      title: 'Field Responder',
      subtitle: 'NDRF Teams, Police, PWD & Local Responders',
      shortDescription:
          'Tactical dispatch, casualty triage, route status & LoRa sync.',
      icon: Icons.health_and_safety_rounded,
      accentColor: Color(0xFF15945C),
      badgeText: 'TACTICAL UNITS',
    ),
    _RoleModel(
      role: UserRole.citizen,
      title: 'Citizen / General Public',
      subtitle: 'Villagers & Local Citizens',
      shortDescription:
          'Evacuation routes, nearest relief camps & instant SOS broadcast.',
      icon: Icons.people_alt_rounded,
      accentColor: Color(0xFF007AEB),
      badgeText: 'PUBLIC ACCESS & SOS',
    ),
    _RoleModel(
      role: UserRole.adminConsole,
      title: 'Technical / Admin Console',
      subtitle: 'System Administrators & Engineers',
      shortDescription:
          'Telemetry pipeline health, CAP overrides & audit telemetry.',
      icon: Icons.terminal_rounded,
      accentColor: Color(0xFF7351D8),
      badgeText: 'SYSADMIN & INFRA',
    ),
  ];

  void _proceedWithRole(UserRole role) {
    switch (role) {
      case UserRole.citizen:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        break;

      case UserRole.authority:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AuthorityVerificationScreen(),
          ),
        );
        break;

      case UserRole.fieldResponder:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const FieldResponderVerificationScreen(),
          ),
        );
        break;

      case UserRole.adminConsole:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TechnicalAdminVerificationScreen(),
          ),
        );
        break;
    }
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

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;

    // Clamp text scale to prevent OS accessibility settings from breaking the 1-screen layout
    final clampedTextScaler = mediaQuery.textScaler.clamp(
      minScaleFactor: 0.85,
      maxScaleFactor: 1.15,
    );

    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: clampedTextScaler),
      child: Scaffold(
        backgroundColor: const Color(0xFFE9F4FB),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Scenic background image with graceful fallback
            Positioned.fill(
              child: Image.asset(
                'assets/images/screen_bg_1.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, _, _) => const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFD6EAF8), Color(0xFFE9F4FB)],
                    ),
                  ),
                ),
              ),
            ),

            // 2. High-readability soft tint overlay
            Positioned.fill(
              child: Container(
                color: const Color(0xFFE9F4FB).withValues(alpha: 0.45),
              ),
            ),

            // 3. Main Single-Screen Responsive Layout using LayoutBuilder & MediaQuery
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double maxH = constraints.maxHeight;
                  final double maxW = constraints.maxWidth;

                  // Adaptive breakpoints
                  final bool isWide =
                      maxW >= 600 || (isLandscape && maxW > maxH);
                  final bool isCompact = maxH < 700;
                  final bool isVeryCompact = maxH < 600;

                  // Responsive horizontal padding based on screen width
                  final double horizPadding =
                      maxW > 700 ? (maxW - 620) / 2 : 16.0;

                  // Tightly budgeted vertical metrics to guarantee zero overflow & no scrolling
                  final double topBarH = isVeryCompact ? 36.0 : 40.0;
                  final double headerSpacing =
                      isVeryCompact ? 3.0 : (isCompact ? 6.0 : 8.0);
                  final double cardSpacing =
                      isVeryCompact ? 6.0 : (isCompact ? 7.0 : 10.0);
                  final double bottomSpacing =
                      isVeryCompact ? 6.0 : (isCompact ? 8.0 : 10.0);
                  final double btnPaddingV =
                      isVeryCompact ? 10.0 : (isCompact ? 12.0 : 14.0);
                  final double helplineH = isVeryCompact ? 26.0 : 30.0;

                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top Navigation / Brand Header
                        SizedBox(
                          height: topBarH,
                          child: _buildTopBar(context, isCompact),
                        ),

                        SizedBox(height: headerSpacing),

                        // Section Title & Subtitle (Adaptive font sizes)
                        _buildHeader(isVeryCompact, isCompact),

                        SizedBox(height: headerSpacing),

                        // Expanded container for the 4 roles:
                        // Children use Expanded so they mathematically fit 100% of the remaining height
                        // Without any scrolling and without any RenderFlex overflow!
                        Expanded(
                          child: isWide
                              ? _build2x2Grid(context, cardSpacing, maxH)
                              : _buildVerticalList(
                                  context,
                                  cardSpacing,
                                  isCompact,
                                  isVeryCompact,
                                ),
                        ),

                        SizedBox(height: bottomSpacing),

                        // Primary Action Button
                        _buildActionButton(btnPaddingV, isCompact),

                        SizedBox(height: isVeryCompact ? 4.0 : 6.0),

                        // Emergency Helpline Badge
                        SizedBox(
                          height: helplineH,
                          child: _buildHelplineBadge(isVeryCompact),
                        ),

                        SizedBox(height: isVeryCompact ? 4.0 : 8.0),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TOP BAR
  // --------------------------------------------------------------------------
  Widget _buildTopBar(BuildContext context, bool isCompact) {
    final bool canPop = Navigator.canPop(context);

    return Row(
      children: [
        if (canPop)
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF013973),
              size: 18,
            ),
            onPressed: () => Navigator.maybePop(context),
            tooltip: 'Back',
          )
        else
          const SizedBox(width: 36),

        const Spacer(),

        // Brand Logo + Title
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/app_logo.png',
              width: isCompact ? 26 : 30,
              height: isCompact ? 26 : 30,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Icon(
                Icons.shield_rounded,
                size: isCompact ? 24 : 28,
                color: const Color(0xFF013973),
              ),
            ),
            const SizedBox(width: 8),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Res',
                    style: TextStyle(
                      color: const Color(0xFF013973),
                      fontSize: isCompact ? 17 : 19,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                  TextSpan(
                    text: 'Q',
                    style: TextStyle(
                      color: const Color(0xFF00FF00),
                      fontSize: isCompact ? 18 : 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                      shadows: const [
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
                      color: const Color(0xFF013973),
                      fontSize: isCompact ? 17 : 19,
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
        const SizedBox(width: 36), // Balance leading widget
      ],
    );
  }

  // --------------------------------------------------------------------------
  // HEADER
  // --------------------------------------------------------------------------
  Widget _buildHeader(bool isVeryCompact, bool isCompact) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Select Your Role',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF013973),
            fontSize: isVeryCompact ? 18 : (isCompact ? 20 : 22),
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
        SizedBox(height: isVeryCompact ? 2 : 4),
        Text(
          'Choose your operational profile for tailored disaster response tools.',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: const Color(0xFF537392),
            fontSize: isVeryCompact ? 10.5 : (isCompact ? 11.5 : 12.0),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // VERTICAL 4-CARD LIST (Standard Mobile Portrait)
  // --------------------------------------------------------------------------
  Widget _buildVerticalList(
    BuildContext context,
    double cardSpacing,
    bool isCompact,
    bool isVeryCompact,
  ) {
    return Column(
      children: [
        for (int i = 0; i < _roles.length; i++) ...[
          if (i > 0) SizedBox(height: cardSpacing),
          Expanded(
            child: _buildRoleCard(
              item: _roles[i],
              isCompact: isCompact,
              isVeryCompact: isVeryCompact,
              isGrid: false,
            ),
          ),
        ],
      ],
    );
  }

  // --------------------------------------------------------------------------
  // 2x2 GRID (Wide Screens / Tablets / Landscape)
  // --------------------------------------------------------------------------
  Widget _build2x2Grid(BuildContext context, double cardSpacing, double totalH) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _buildRoleCard(
                  item: _roles[0],
                  isCompact: false,
                  isVeryCompact: false,
                  isGrid: true,
                ),
              ),
              SizedBox(width: cardSpacing),
              Expanded(
                child: _buildRoleCard(
                  item: _roles[1],
                  isCompact: false,
                  isVeryCompact: false,
                  isGrid: true,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: cardSpacing),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _buildRoleCard(
                  item: _roles[2],
                  isCompact: false,
                  isVeryCompact: false,
                  isGrid: true,
                ),
              ),
              SizedBox(width: cardSpacing),
              Expanded(
                child: _buildRoleCard(
                  item: _roles[3],
                  isCompact: false,
                  isVeryCompact: false,
                  isGrid: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // INDIVIDUAL ROLE CARD
  // --------------------------------------------------------------------------
  Widget _buildRoleCard({
    required _RoleModel item,
    required bool isCompact,
    required bool isVeryCompact,
    required bool isGrid,
  }) {
    return _RoleKeycapCard(
      item: item,
      isSelected: _selectedRole == item.role,
      isCompact: isCompact,
      isVeryCompact: isVeryCompact,
      isGrid: isGrid,
      onTap: () {
        setState(() {
          _selectedRole = item.role;
        });
      },
    );
  }

  // --------------------------------------------------------------------------
  // PRIMARY ACTION BUTTON
  // --------------------------------------------------------------------------
  Widget _buildActionButton(double verticalPadding, bool isCompact) {
    return ElevatedButton(
      onPressed: () => _proceedWithRole(_selectedRole),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF007AEB),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        elevation: 3,
        shadowColor: const Color(0xFF007AEB).withValues(alpha: 0.35),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              _getButtonLabel(_selectedRole),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isCompact ? 14.5 : 15.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_rounded, size: 18),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // EMERGENCY HELPLINE BADGE
  // --------------------------------------------------------------------------
  Widget _buildHelplineBadge(bool isVeryCompact) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10,
        vertical: isVeryCompact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD6E8F7)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.call_rounded, size: 13, color: Color(0xFFE92828)),
            SizedBox(width: 5),
            Text(
              'National Disaster Helpline: ',
              style: TextStyle(
                color: Color(0xFF537392),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '1070 / 112',
              style: TextStyle(
                color: Color(0xFFE92828),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 3D KEYBOARD KEYCAP ROLE CARD WIDGET
// ============================================================================
class _RoleKeycapCard extends StatefulWidget {
  final _RoleModel item;
  final bool isSelected;
  final bool isCompact;
  final bool isVeryCompact;
  final bool isGrid;
  final VoidCallback onTap;

  const _RoleKeycapCard({
    required this.item,
    required this.isSelected,
    required this.isCompact,
    required this.isVeryCompact,
    required this.isGrid,
    required this.onTap,
  });

  @override
  State<_RoleKeycapCard> createState() => _RoleKeycapCardState();
}

class _RoleKeycapCardState extends State<_RoleKeycapCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isDepressed = widget.isSelected || _isPressed;
    final item = widget.item;

    return LayoutBuilder(
      builder: (context, cardConstraints) {
        final double cardH = cardConstraints.maxHeight;

        // Content density switches based on exact card height
        final bool showDescription = cardH >= 86;
        final bool showBadge = cardH >= 68;
        final double iconBoxSize = (cardH * 0.42).clamp(28.0, 38.0);
        final double iconSize = (iconBoxSize * 0.54).clamp(15.0, 21.0);

        final double titleSize =
            widget.isVeryCompact ? 13.0 : (widget.isCompact ? 14.0 : 15.0);
        final double subtitleSize =
            widget.isVeryCompact ? 9.5 : (widget.isCompact ? 10.5 : 11.0);

        return Padding(
          padding: const EdgeInsets.only(
            top: 1.0,
            bottom: 6.0,
            left: 1.0,
            right: 1.0,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(
              0.0,
              isDepressed ? 5.5 : 0.0,
              0.0,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDepressed
                    ? item.accentColor
                    : const Color(0xFFBED7EC),
                width: isDepressed ? 2.5 : 1.4,
              ),
              boxShadow: isDepressed
                  ? [
                      // 1. Vivid neon rim light along the outline
                      BoxShadow(
                        color: item.accentColor.withValues(alpha: 0.65),
                        blurRadius: 10,
                        spreadRadius: 1.0,
                        offset: Offset.zero,
                      ),
                      // 2. Wide atmospheric ambient underglow halo radiating outward
                      BoxShadow(
                        color: item.accentColor.withValues(alpha: 0.35),
                        blurRadius: 22,
                        spreadRadius: 2.5,
                        offset: const Offset(0, 1.5),
                      ),
                      // 3. Top boundary rim reflection
                      BoxShadow(
                        color: item.accentColor.withValues(alpha: 0.20),
                        blurRadius: 5,
                        spreadRadius: 0,
                        offset: const Offset(0, -1),
                      ),
                      // 4. Flat contact shadow
                      BoxShadow(
                        color: const Color(0xFF013973).withValues(alpha: 0.08),
                        offset: const Offset(0, 1.0),
                        blurRadius: 2.0,
                      ),
                    ]
                  : [
                      // Physical 3D bottom bevel / keycap extrusion ledge (Prominent 5.5px depth)
                      const BoxShadow(
                        color: Color(0xFFA8CBE4),
                        offset: Offset(0, 5.5),
                        blurRadius: 0,
                        spreadRadius: 0,
                      ),
                      // Ambient soft 3D elevation contact shadow
                      BoxShadow(
                        color: const Color(0xFF013973).withValues(alpha: 0.16),
                        offset: const Offset(0, 9.0),
                        blurRadius: 13,
                        spreadRadius: 0,
                      ),
                      // Top edge specular highlight reflection
                      const BoxShadow(
                        color: Colors.white,
                        offset: Offset(0, -1.5),
                        blurRadius: 0,
                        spreadRadius: 0,
                      ),
                    ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onHighlightChanged: (value) {
                  if (_isPressed != value) {
                    setState(() => _isPressed = value);
                  }
                },
                onTap: () {
                  HapticFeedback.mediumImpact();
                  widget.onTap();
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.isVeryCompact ? 10 : 12,
                    vertical: widget.isVeryCompact ? 4 : 6,
                  ),
                  child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Accent Icon Box (with dynamic illumination)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      width: iconBoxSize,
                      height: iconBoxSize,
                      decoration: BoxDecoration(
                        color: item.accentColor.withValues(
                          alpha: isDepressed ? 0.16 : 0.08,
                        ),
                        borderRadius:
                            BorderRadius.circular(iconBoxSize * 0.28),
                        border: Border.all(
                          color: item.accentColor.withValues(
                            alpha: isDepressed ? 0.45 : 0.14,
                          ),
                          width: isDepressed ? 1.2 : 1.0,
                        ),
                        boxShadow: isDepressed
                            ? [
                                BoxShadow(
                                  color: item.accentColor.withValues(alpha: 0.22),
                                  blurRadius: 6,
                                  spreadRadius: 0,
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        item.icon,
                        color: item.accentColor,
                        size: iconSize,
                      ),
                    ),

                    SizedBox(width: widget.isVeryCompact ? 8 : 10),

                    // Titles & Details
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showBadge) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: item.accentColor.withValues(
                                  alpha: isDepressed ? 0.14 : 0.09,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.badgeText,
                                style: TextStyle(
                                  color: item.accentColor,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                          ],
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color(0xFF013973),
                              fontSize: titleSize,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          Text(
                            item.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color(0xFF537392),
                              fontSize: subtitleSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (showDescription) ...[
                            const SizedBox(height: 2),
                            Text(
                              item.shortDescription,
                              maxLines: cardH > 100 ? 2 : 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF6887A4),
                                fontSize: 10.0,
                                height: 1.2,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Radio Check Indicator (3D Socket vs Illuminated LED)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      width: widget.isVeryCompact ? 19 : 22,
                      height: widget.isVeryCompact ? 19 : 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDepressed
                            ? item.accentColor
                            : const Color(0xFFF1F6FB),
                        border: Border.all(
                          color: isDepressed
                              ? Colors.white
                              : const Color(0xFFBDD8EE),
                          width: isDepressed ? 1.8 : 1.5,
                        ),
                        boxShadow: isDepressed
                            ? [
                                BoxShadow(
                                  color: item.accentColor.withValues(alpha: 0.60),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : const [
                                BoxShadow(
                                  color: Color(0x12013973),
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                ),
                              ],
                      ),
                      child: isDepressed
                          ? Icon(
                              Icons.check_rounded,
                              size: widget.isVeryCompact ? 12 : 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
}

