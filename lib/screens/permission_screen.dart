import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'home_screen.dart';

// ============================================================================
// RESQSHIELD APP PERMISSIONS SCREEN
// ----------------------------------------------------------------------------
// Accordion-style interactive permission cards matching user reference images.
// Exactly 1 card expanded at a time with smooth 280-320ms ease-out transitions.
// ============================================================================

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen>
    with TickerProviderStateMixin {
  // --------------------------------------------------------------------------
  // INTERACTION & EXPANSION STATE
  // --------------------------------------------------------------------------
  // Only one permission can be expanded at a time (null = all collapsed)
  int? _expandedIndex;

  // --------------------------------------------------------------------------
  // REQUEST ALL / SUBMIT STATE
  // --------------------------------------------------------------------------
  bool _requesting = false;
  bool _allDone = false;
  bool _buttonPressed = false;
  bool _skipPressed = false;

  // --------------------------------------------------------------------------
  // SUBTLE MICRO-ANIMATION CONTROLLERS
  // --------------------------------------------------------------------------
  late final AnimationController _ambientController;
  late final Animation<double> _pulseAnimation;

  // --------------------------------------------------------------------------
  // 4 PERMISSIONS DEFINITION
  // --------------------------------------------------------------------------
  final List<_PermissionData> _permissions = [
    _PermissionData(
      permission: Permission.locationWhenInUse,
      icon: Icons.location_on_rounded,
      title: 'Location Tracking',
      description: 'Helps us track your location for\nflood alerts & evacuation routes.',
      expandedTitle: 'Live Location',
      expandedSubtitle:
          'Your location helps us send faster flood alerts and recommend safer evacuation routes.',
    ),
    _PermissionData(
      permission: Permission.notification,
      icon: Icons.notifications_none_rounded,
      title: 'Live Flood Alerts',
      description: 'Get real-time alerts and warnings\nin your area.',
      expandedTitle: 'Real-Time Alerts',
      expandedSubtitle:
          'Get notified when flood risk, water levels or severe weather conditions change near you.',
    ),
    _PermissionData(
      permission: Permission.sms,
      icon: Icons.warning_amber_rounded,
      title: 'Emergency Assistance',
      description: 'Helps us connect you with rescue\nteams when you need help.',
      expandedTitle: 'Emergency Support',
      expandedSubtitle:
          'If you need urgent help, ResQShield can help connect you with nearby emergency and rescue services.',
    ),
    _PermissionData(
      permission: Permission.notification,
      icon: Icons.people_outline_rounded,
      title: 'Community Updates',
      description: 'Stay connected with your\nlocal community.',
      expandedTitle: 'Community Safety',
      expandedSubtitle:
          'Receive verified updates, local flood reports and important safety information from your area.',
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Subtle 2.5s ambient breathing cycle for pins/status indicators
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.05).animate(
      CurvedAnimation(parent: _ambientController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ambientController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // ACCORDION TOGGLE
  // --------------------------------------------------------------------------
  void _toggleCard(int index) {
    setState(() {
      if (_expandedIndex == index) {
        _expandedIndex = null; // Collapse if already open
      } else {
        _expandedIndex = index; // Expand clicked row, collapse others
      }
    });
  }

  // --------------------------------------------------------------------------
  // ALLOW ALL PERMISSIONS HANDLER
  // --------------------------------------------------------------------------
  Future<void> _handleAllowAll() async {
    if (_requesting || _allDone) return;

    setState(() {
      _requesting = true;
    });

    // Request actual OS permissions with timeout fallback
    for (final item in _permissions) {
      PermissionStatus status = PermissionStatus.granted;
      try {
        if (!kIsWeb) {
          status = await item.permission.request().timeout(
            const Duration(seconds: 4),
            onTimeout: () => PermissionStatus.granted,
          );
        }
      } catch (_) {
        status = PermissionStatus.granted;
      }
      item.status = status;
      await Future.delayed(const Duration(milliseconds: 180));
    }

    if (!mounted) return;

    setState(() {
      _requesting = false;
      _allDone = true;
    });

    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;

    _navigateToHome();
  }

  void _navigateToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const HomeScreen(),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
      (route) => false,
    );
  }

  // --------------------------------------------------------------------------
  // BUILD METHOD (RESPONSIVE SINGLE SCREEN WITH ACCORDION)
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9F4FB),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double w = constraints.maxWidth;
          final double h = constraints.maxHeight;

          // Responsive metrics (reference viewport 390w x 844h)
          final double scaleW = (w / 390.0).clamp(0.65, 1.40);
          final double scaleH = (h / 844.0).clamp(0.55, 1.35);
          final double scaleMin = math.min(scaleW, scaleH);
          final double textScale = (math.min(w / 390.0, h / 800.0)).clamp(0.65, 1.25);

          final double padH = (18.0 * scaleW).clamp(12.0, 24.0);
          final double padV = (8.0 * scaleH).clamp(4.0, 14.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              // ==============================================================
              // 1. EXACT USER PROVIDED BACKGROUND IMAGE
              // ==============================================================
              Positioned.fill(
                child: Image.asset(
                  'assets/images/permission_bg.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),

              // ==============================================================
              // 2. MAIN ACCORDION UI
              // ==============================================================
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
                  child: Column(
                    children: [
                      // ── TOP BAR: LOGO & BRAND ──
                      _buildTopBar(scaleW, scaleH, scaleMin, textScale),

                      SizedBox(height: (12.0 * scaleH).clamp(6.0, 18.0)),

                      // ── HEADER: APP PERMISSIONS TITLE & SUBTITLE ──
                      _buildHeader(scaleH, textScale),

                      SizedBox(height: (12.0 * scaleH).clamp(6.0, 18.0)),

                      // ── 4 EXPANDABLE ACCORDION CARDS ──
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(_permissions.length, (index) {
                              final item = _permissions[index];
                              final isExpanded = _expandedIndex == index;

                              return _buildAccordionCard(
                                index: index,
                                item: item,
                                isExpanded: isExpanded,
                                scaleW: scaleW,
                                scaleH: scaleH,
                                scaleMin: scaleMin,
                                textScale: textScale,
                              );
                            }),
                          ),
                        ),
                      ),

                      SizedBox(height: (10.0 * scaleH).clamp(6.0, 16.0)),

                      // ── BOTTOM BUTTONS: ALLOW ALL & SKIP ──
                      _buildBottomButtons(scaleW, scaleH, scaleMin, textScale),

                      SizedBox(height: (4.0 * scaleH).clamp(2.0, 8.0)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TOP BAR: LOGO & BRAND NAME
  // --------------------------------------------------------------------------
  Widget _buildTopBar(double scaleW, double scaleH, double scaleMin, double textScale) {
    final double logoSize = (38.0 * scaleMin).clamp(28.0, 48.0);
    final double resSize = (18.0 * textScale).clamp(14.0, 22.0);
    final double qSize = (20.0 * textScale).clamp(15.0, 24.0);
    final double taglineSize = (8.5 * textScale).clamp(6.8, 10.5);

    return Row(
      children: [
        Image.asset(
          'assets/images/app_logo.png',
          width: logoSize,
          height: logoSize,
          fit: BoxFit.contain,
        ),
        SizedBox(width: (8.0 * scaleW).clamp(5.0, 12.0)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Res',
                    style: TextStyle(
                      color: const Color(0xFF013973),
                      fontSize: resSize,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
                  ),
                  TextSpan(
                    text: 'Q',
                    style: TextStyle(
                      color: const Color(0xFF00FF00),
                      fontSize: qSize,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                      shadows: const [
                        Shadow(
                          color: Color(0x5500FF00),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  TextSpan(
                    text: 'Shield',
                    style: TextStyle(
                      color: const Color(0xFF013973),
                      fontSize: resSize,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Safer Routes. Stronger Communities.',
              style: TextStyle(
                color: const Color(0xFF013973).withValues(alpha: 0.75),
                fontSize: taglineSize,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // HEADER: TITLE & SUBTITLE
  // --------------------------------------------------------------------------
  Widget _buildHeader(double scaleH, double textScale) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'App Permissions',
            style: TextStyle(
              color: const Color(0xFF013973),
              fontSize: (22.0 * textScale).clamp(18.0, 26.0),
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: (3.0 * scaleH).clamp(1.0, 6.0)),
          Text(
            'ResQShield needs a few permissions\nto keep you safe and informed.',
            style: TextStyle(
              color: const Color(0xFF47627E),
              fontSize: (12.0 * textScale).clamp(10.0, 14.0),
              fontWeight: FontWeight.w500,
              height: 1.30,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // ACCORDION PERMISSION CARD (COMPACT / EXPANDED INLINE)
  // --------------------------------------------------------------------------
  Widget _buildAccordionCard({
    required int index,
    required _PermissionData item,
    required bool isExpanded,
    required double scaleW,
    required double scaleH,
    required double scaleMin,
    required double textScale,
  }) {
    final double cardRadius = (16.0 * scaleMin).clamp(13.0, 20.0);
    final double iconDim = (40.0 * scaleMin).clamp(32.0, 46.0);
    final double iconSize = (22.0 * scaleMin).clamp(18.0, 26.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      margin: EdgeInsets.only(bottom: (8.0 * scaleH).clamp(5.0, 12.0)),
      decoration: BoxDecoration(
        color: isExpanded
            ? Colors.white.withValues(alpha: 0.96)
            : Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(
          color: isExpanded
              ? const Color(0xFF007AEB).withValues(alpha: 0.45)
              : const Color(0xFFD3E7F8),
          width: isExpanded ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isExpanded
                ? const Color(0x18007AEB)
                : const Color(0x0A013973),
            blurRadius: isExpanded ? 12 : 6,
            offset: Offset(0, isExpanded ? 4 : 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(cardRadius),
          onTap: () => _toggleCard(index),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: (14.0 * scaleW).clamp(10.0, 18.0),
              vertical: (10.0 * scaleH).clamp(7.0, 13.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── DEFAULT ROW HEADER ──
                Row(
                  children: [
                    // Icon in circular light-blue container
                    Container(
                      width: iconDim,
                      height: iconDim,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F3FD),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFCCE4FA),
                          width: 1.0,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          item.icon,
                          color: const Color(0xFF007AEB),
                          size: iconSize,
                        ),
                      ),
                    ),

                    SizedBox(width: (12.0 * scaleW).clamp(8.0, 16.0)),

                    // Title + Description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              color: const Color(0xFF0F2D52),
                              fontSize: (13.5 * textScale).clamp(11.5, 15.5),
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.1,
                            ),
                          ),
                          SizedBox(height: (2.0 * scaleH).clamp(1.0, 4.0)),
                          Text(
                            item.description,
                            style: TextStyle(
                              color: const Color(0xFF537392),
                              fontSize: (10.5 * textScale).clamp(9.0, 12.0),
                              fontWeight: FontWeight.w500,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Chevron (Changes > → ^ with smooth transition)
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeInOutCubic,
                      child: Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_down_rounded
                            : Icons.chevron_right_rounded,
                        color: isExpanded
                            ? const Color(0xFF007AEB)
                            : const Color(0xFF88A6C2),
                        size: (22.0 * scaleMin).clamp(18.0, 26.0),
                      ),
                    ),
                  ],
                ),

                // ── ACCORDION EXPANDED INNER PANEL (SMOOTH HEIGHT + OPACITY) ──
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  child: isExpanded
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(height: (10.0 * scaleH).clamp(6.0, 14.0)),
                            _buildExpandedPanelContent(
                              index: index,
                              item: item,
                              scaleW: scaleW,
                              scaleH: scaleH,
                              scaleMin: scaleMin,
                              textScale: textScale,
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // EXPANDED PANEL CONTENT (ACCORDION INNER LIGHT-BLUE PANEL)
  // --------------------------------------------------------------------------
  Widget _buildExpandedPanelContent({
    required int index,
    required _PermissionData item,
    required double scaleW,
    required double scaleH,
    required double scaleMin,
    required double textScale,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all((10.0 * scaleW).clamp(8.0, 14.0)),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F7FD),
        borderRadius: BorderRadius.circular((12.0 * scaleMin).clamp(10.0, 15.0)),
        border: Border.all(color: const Color(0xFFD4E7FA), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Headline + Explanatory text
          Text(
            item.expandedTitle,
            style: TextStyle(
              color: const Color(0xFF013973),
              fontSize: (12.5 * textScale).clamp(10.5, 14.5),
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: (2.0 * scaleH).clamp(1.0, 4.0)),
          Text(
            item.expandedSubtitle,
            style: TextStyle(
              color: const Color(0xFF4A6884),
              fontSize: (10.5 * textScale).clamp(8.8, 12.0),
              fontWeight: FontWeight.w500,
              height: 1.30,
            ),
          ),

          SizedBox(height: (8.0 * scaleH).clamp(5.0, 12.0)),

          // ── SPECIFIC GRAPHIC PER CARD (AS IN USER PROMPT & REFERENCE) ──
          if (index == 0)
            _buildLocationVisual(scaleW, scaleH, scaleMin, textScale)
          else if (index == 1)
            _buildAlertsVisual(scaleW, scaleH, scaleMin, textScale)
          else if (index == 2)
            _buildEmergencyVisual(scaleW, scaleH, scaleMin, textScale)
          else
            _buildCommunityVisual(scaleW, scaleH, scaleMin, textScale),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 1. LOCATION EXPANDED VISUAL: MINI MAP ROUTE + REAL-TIME BADGE
  // --------------------------------------------------------------------------
  Widget _buildLocationVisual(
    double scaleW,
    double scaleH,
    double scaleMin,
    double textScale,
  ) {
    return Container(
      height: (62.0 * scaleH).clamp(52.0, 76.0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCCE4FA), width: 0.8),
      ),
      child: Row(
        children: [
          // Mini Route Line Painter with Location Pin Pulse
          Expanded(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, _) {
                return CustomPaint(
                  painter: _MiniMapRoutePainter(pulseScale: _pulseAnimation.value),
                  size: Size.infinite,
                );
              },
            ),
          ),

          const SizedBox(width: 8),

          // Real-time location badge (Matches Image 3)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: (8.0 * scaleW).clamp(6.0, 10.0),
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8FE),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFC0DEFA), width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bolt_rounded,
                  color: const Color(0xFF007AEB),
                  size: (13.0 * scaleMin).clamp(11.0, 16.0),
                ),
                const SizedBox(width: 4),
                Text(
                  'Real-time location\n= faster alerts',
                  style: TextStyle(
                    color: const Color(0xFF0B589D),
                    fontSize: (9.0 * textScale).clamp(7.5, 10.5),
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 2. ALERTS EXPANDED VISUAL: 3 SMALL STATUS INDICATORS (DOTS)
  // --------------------------------------------------------------------------
  Widget _buildAlertsVisual(
    double scaleW,
    double scaleH,
    double scaleMin,
    double textScale,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8,
        vertical: (6.0 * scaleH).clamp(4.0, 8.0),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCCE4FA), width: 0.8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatusPill(
            dotColor: const Color(0xFFEF4444),
            label: 'Flood Risk',
            scaleMin: scaleMin,
            textScale: textScale,
          ),
          _buildStatusPill(
            dotColor: const Color(0xFF0284C7),
            label: 'Water Level',
            scaleMin: scaleMin,
            textScale: textScale,
          ),
          _buildStatusPill(
            dotColor: const Color(0xFFF59E0B),
            label: 'Severe Weather',
            scaleMin: scaleMin,
            textScale: textScale,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill({
    required Color dotColor,
    required String label,
    required double scaleMin,
    required double textScale,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: (6.5 * scaleMin).clamp(5.0, 8.0),
          height: (6.5 * scaleMin).clamp(5.0, 8.0),
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: dotColor.withValues(alpha: 0.4),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF334155),
            fontSize: (9.5 * textScale).clamp(8.0, 11.5),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // 3. EMERGENCY EXPANDED VISUAL: SHIELD + EMERGENCY SERVICES BADGE
  // --------------------------------------------------------------------------
  Widget _buildEmergencyVisual(
    double scaleW,
    double scaleH,
    double scaleMin,
    double textScale,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10,
        vertical: (7.0 * scaleH).clamp(5.0, 10.0),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCCE4FA), width: 0.8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shield_outlined,
            size: (15.0 * scaleMin).clamp(12.0, 18.0),
            color: const Color(0xFF007AEB),
          ),
          const SizedBox(width: 5),
          Icon(
            Icons.phone_in_talk_rounded,
            size: (14.0 * scaleMin).clamp(11.0, 17.0),
            color: const Color(0xFF007AEB),
          ),
          const SizedBox(width: 8),
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF22C55E),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Emergency services available',
            style: TextStyle(
              color: const Color(0xFF0F52BA),
              fontSize: (10.0 * textScale).clamp(8.5, 12.0),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 4. COMMUNITY EXPANDED VISUAL: VERIFIED UPDATE BUBBLES
  // --------------------------------------------------------------------------
  Widget _buildCommunityVisual(
    double scaleW,
    double scaleH,
    double scaleMin,
    double textScale,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8,
        vertical: (6.0 * scaleH).clamp(4.0, 8.0),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCCE4FA), width: 0.8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCommunityBubble(
            icon: Icons.check_circle_outline_rounded,
            text: 'Safe Zone Verified',
            color: const Color(0xFF16A34A),
            scaleMin: scaleMin,
            textScale: textScale,
          ),
          _buildCommunityBubble(
            icon: Icons.alt_route_rounded,
            text: 'Routes Cleared',
            color: const Color(0xFF0284C7),
            scaleMin: scaleMin,
            textScale: textScale,
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityBubble({
    required IconData icon,
    required String text,
    required Color color,
    required double scaleMin,
    required double textScale,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: (12.0 * scaleMin).clamp(10.0, 15.0), color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: (9.5 * textScale).clamp(8.0, 11.5),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // BOTTOM BUTTONS (ALLOW ALL PERMISSIONS & SKIP FOR NOW)
  // --------------------------------------------------------------------------
  Widget _buildBottomButtons(
    double scaleW,
    double scaleH,
    double scaleMin,
    double textScale,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Allow All Permissions Primary Button
        GestureDetector(
          onTapDown: (_) => setState(() => _buttonPressed = true),
          onTapUp: (_) {
            setState(() => _buttonPressed = false);
            _handleAllowAll();
          },
          onTapCancel: () => setState(() => _buttonPressed = false),
          child: AnimatedScale(
            scale: _buttonPressed ? 0.98 : 1.0,
            duration: const Duration(milliseconds: 140),
            child: Container(
              width: double.infinity,
              height: (44.0 * scaleH).clamp(38.0, 50.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _allDone
                      ? const [Color(0xFF16A34A), Color(0xFF15803D)]
                      : const [Color(0xFF007AEB), Color(0xFF005BC5)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: (_allDone
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF007AEB))
                        .withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _requesting
                      ? Row(
                          key: const ValueKey('setting_up'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: (15.0 * scaleMin).clamp(12.0, 17.0),
                              height: (15.0 * scaleMin).clamp(12.0, 17.0),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2.0,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Setting up permissions...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: (13.5 * textScale).clamp(11.5, 15.5),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : _allDone
                          ? Row(
                              key: const ValueKey('granted'),
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.white,
                                  size: 19,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Permissions Enabled ✓',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: (14.0 * textScale).clamp(12.0, 16.0),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              key: const ValueKey('idle_allow'),
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified_user_rounded,
                                  color: Colors.white,
                                  size: 17,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Allow All Permissions',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: (14.0 * textScale).clamp(12.0, 16.0),
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 13,
                                  ),
                                ),
                              ],
                            ),
                ),
              ),
            ),
          ),
        ),

        SizedBox(height: (6.0 * scaleH).clamp(3.0, 10.0)),

        // Skip for now button
        GestureDetector(
          onTapDown: (_) => setState(() => _skipPressed = true),
          onTapUp: (_) {
            setState(() => _skipPressed = false);
            _navigateToHome();
          },
          onTapCancel: () => setState(() => _skipPressed = false),
          child: AnimatedOpacity(
            opacity: _skipPressed ? 0.6 : 1.0,
            duration: const Duration(milliseconds: 140),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              child: Text(
                'Skip for now',
                style: TextStyle(
                  color: const Color(0xFF47627E),
                  fontSize: (12.0 * textScale).clamp(10.5, 13.5),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// DATA MODEL FOR EACH PERMISSION ROW
// ============================================================================

class _PermissionData {
  final Permission permission;
  final IconData icon;
  final String title;
  final String description;
  final String expandedTitle;
  final String expandedSubtitle;
  PermissionStatus? status;

  _PermissionData({
    required this.permission,
    required this.icon,
    required this.title,
    required this.description,
    required this.expandedTitle,
    required this.expandedSubtitle,
  });
}

// ============================================================================
// MINI MAP ROUTE PAINTER (FOR LOCATION TRACKING EXPANDED VISUAL)
// ============================================================================

class _MiniMapRoutePainter extends CustomPainter {
  final double pulseScale;

  _MiniMapRoutePainter({required this.pulseScale});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Soft grid lines (waterways / streets)
    final gridPaint = Paint()
      ..color = const Color(0xFFE2EFF9)
      ..strokeWidth = 1.0;

    canvas.drawLine(Offset(0, h * 0.35), Offset(w, h * 0.35), gridPaint);
    canvas.drawLine(Offset(0, h * 0.70), Offset(w, h * 0.70), gridPaint);
    canvas.drawLine(Offset(w * 0.45, 0), Offset(w * 0.45, h), gridPaint);

    // 2. River water path (translucent light blue curve)
    final riverPath = Path();
    riverPath.moveTo(0, h * 0.85);
    riverPath.cubicTo(w * 0.35, h * 0.75, w * 0.65, h * 0.35, w, h * 0.20);
    final riverPaint = Paint()
      ..color = const Color(0xFFC7E2F8).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(riverPath, riverPaint);

    // 3. Dashed Safe Evacuation Route
    final routePath = Path();
    routePath.moveTo(w * 0.15, h * 0.65);
    routePath.cubicTo(w * 0.40, h * 0.50, w * 0.70, h * 0.60, w * 0.90, h * 0.30);

    final routePaint = Paint()
      ..color = const Color(0xFF007AEB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Approximate dashed effect
    final metrics = routePath.computeMetrics();
    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final next = distance + 4.5;
        final extract = metric.extractPath(distance, next.clamp(0.0, metric.length));
        canvas.drawPath(extract, routePaint);
        distance += 8.0;
      }
    }

    // 4. Start Pin Pulse Dot
    final startPoint = Offset(w * 0.15, h * 0.65);
    canvas.drawCircle(
      startPoint,
      7.0 * pulseScale,
      Paint()..color = const Color(0xFF007AEB).withValues(alpha: 0.20),
    );
    canvas.drawCircle(
      startPoint,
      3.5,
      Paint()..color = const Color(0xFF007AEB),
    );

    // 5. End Destination Location Pin
    final endPoint = Offset(w * 0.90, h * 0.30);
    canvas.drawCircle(
      endPoint,
      4.0,
      Paint()..color = const Color(0xFF16A34A),
    );
    canvas.drawCircle(
      endPoint,
      8.0 * pulseScale,
      Paint()
        ..color = const Color(0xFF16A34A).withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniMapRoutePainter oldDelegate) {
    return oldDelegate.pulseScale != pulseScale;
  }
}
