import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'role_selection_screen.dart';

// ============================================================================
// CURTAIN / ROLLER-BLIND PERMISSION TRANSITION SCREEN
// ============================================================================
// Realistic physical roller-blind metaphor:
// 1. Interactive vertical pull cord with weighted acorn handle on the side.
// 2. Dragging the cord downward slides the permission popup upward smoothly.
// 3. Tapping "Allow":
//    - Cord retracts upward smoothly (500-700ms)
//    - Current curtain screen moves downward and disappears below viewport (700-900ms)
//    - Reveals RoleSelectionScreen underneath in place with depth & parallax!
// ============================================================================

class PermissionScreen extends StatefulWidget {
  final Widget? nextScreen;
  const PermissionScreen({super.key, this.nextScreen});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen>
    with TickerProviderStateMixin {
  // --------------------------------------------------------------------------
  // CORD PULL & POPUP ANIMATION
  // --------------------------------------------------------------------------
  late final AnimationController _pullController; // 0.0 (rest) to 1.0 (fully pulled)
  late final Animation<double> _pullCurve;

  // --------------------------------------------------------------------------
  // MAIN CURTAIN TRANSITION ANIMATION (ON ALLOW)
  // --------------------------------------------------------------------------
  late final AnimationController _curtainRetractController; // Cord zips up
  late final Animation<double> _cordRetractAnimation;

  late final AnimationController _curtainDropController; // Screen slides down
  late final Animation<double> _curtainDropAnimation;

  late final AnimationController _underneathRevealController; // Roles screen depth scale
  late final Animation<double> _underneathScaleAnimation;
  late final Animation<double> _underneathOpacityAnimation;

  // Idle breath animation for the handle
  late final AnimationController _idleBobController;
  late final Animation<double> _idleBobAnimation;

  // --------------------------------------------------------------------------
  // STATE FLAGS
  // --------------------------------------------------------------------------
  bool _isTransitioning = false;
  bool _isPopupOpen = false;
  bool _isCordHoveredOrDragged = false;
  bool _allowPressed = false;
  bool _notNowPressed = false;

  // Cord metrics
  static const double _kRestingCordLength = 140.0;
  static const double _kMaxPullExtension = 110.0; // Total pulled length = 250px
  static const double _kPullThreshold = 0.40;

  @override
  void initState() {
    super.initState();

    // 1. Cord pull animation controller
    _pullController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    );
    _pullCurve = CurvedAnimation(
      parent: _pullController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    // 2. Cord retract animation controller (500-700ms)
    _curtainRetractController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _cordRetractAnimation = CurvedAnimation(
      parent: _curtainRetractController,
      curve: Curves.easeInOutCubic,
    );

    // 3. Screen slide downward animation controller (700-900ms)
    _curtainDropController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _curtainDropAnimation = CurvedAnimation(
      parent: _curtainDropController,
      curve: Curves.easeInOutQuart,
    );

    // 4. Underneath Roles screen depth reveal
    _underneathRevealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _underneathScaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _underneathRevealController, curve: Curves.easeOutCubic),
    );
    _underneathOpacityAnimation = Tween<double>(begin: 0.70, end: 1.0).animate(
      CurvedAnimation(parent: _underneathRevealController, curve: Curves.easeInQuad),
    );

    // 5. Idle breathing bobbing for cord handle
    _idleBobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _idleBobAnimation = Tween<double>(begin: 0.0, end: 6.0).animate(
      CurvedAnimation(parent: _idleBobController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _pullController.dispose();
    _curtainRetractController.dispose();
    _curtainDropController.dispose();
    _underneathRevealController.dispose();
    _idleBobController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // INTERACTIVE DRAG HANDLING FOR PULL CORD
  // --------------------------------------------------------------------------
  void _onCordDragStart(DragStartDetails details) {
    if (_isTransitioning) return;
    setState(() => _isCordHoveredOrDragged = true);
    HapticFeedback.selectionClick();
  }

  void _onCordDragUpdate(DragUpdateDetails details) {
    if (_isTransitioning) return;
    final double deltaProgress = details.primaryDelta! / _kMaxPullExtension;
    final double newProgress = (_pullController.value + deltaProgress).clamp(0.0, 1.25);
    _pullController.value = newProgress;

    if (newProgress >= _kPullThreshold && !_isPopupOpen) {
      setState(() => _isPopupOpen = true);
      HapticFeedback.lightImpact();
    }
  }

  void _onCordDragEnd(DragEndDetails details) {
    if (_isTransitioning) return;
    setState(() => _isCordHoveredOrDragged = false);

    final double velocity = details.primaryVelocity ?? 0.0;
    if (velocity > 350 || _pullController.value >= _kPullThreshold) {
      // Snap fully open
      _pullController.animateTo(1.0, curve: Curves.easeOutBack);
      setState(() => _isPopupOpen = true);
      HapticFeedback.mediumImpact();
    } else {
      // Snap back to resting position
      _pullController.animateTo(0.0, curve: Curves.easeOutCubic);
      setState(() => _isPopupOpen = false);
    }
  }

  void _openPopupDirectly() {
    if (_isTransitioning || _isPopupOpen) return;
    HapticFeedback.lightImpact();
    setState(() => _isPopupOpen = true);
    _pullController.animateTo(1.0, curve: Curves.easeOutCubic);
  }

  void _closePopup() {
    if (_isTransitioning) return;
    HapticFeedback.selectionClick();
    _pullController.animateTo(0.0, curve: Curves.easeOutCubic);
    setState(() => _isPopupOpen = false);
  }

  // --------------------------------------------------------------------------
  // MAIN TRANSITION TRIGGER (ON "ALLOW")
  // --------------------------------------------------------------------------
  Future<void> _handleAllow() async {
    if (_isTransitioning) return;
    setState(() => _isTransitioning = true);
    HapticFeedback.mediumImpact();

    // Gracefully request permissions in parallel without blocking UI
    _requestSystemPermissions();

    // Step 1: Cord retracts upward smoothly (500-700ms)
    _curtainRetractController.forward();

    // Slight micro-pause (120ms) for physical inertia before curtain drops
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    // Step 2: Curtain screen moves downward and disappears below viewport (700-900ms)
    _curtainDropController.forward();
    _underneathRevealController.forward();

    // Step 3: Wait for drop animation completion, then seamlessly replace route
    await Future.delayed(const Duration(milliseconds: 850));
    if (!mounted) return;

    final destination = widget.nextScreen ?? const RoleSelectionScreen();
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => destination,
        transitionDuration: Duration.zero,
      ),
    );
  }

  Future<void> _requestSystemPermissions() async {
    try {
      if (!kIsWeb) {
        await [
          Permission.locationWhenInUse,
          Permission.notification,
        ].request().timeout(
          const Duration(seconds: 3),
          onTimeout: () => {},
        );
      }
    } catch (_) {
      // Safe fallback on mock or simulator environments
    }
  }

  // --------------------------------------------------------------------------
  // BUILD METHOD
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final double screenH = media.size.height;
    final double screenW = media.size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFE9F4FB),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ==================================================================
          // LAYER 0: UNDERNEATH ROLES SELECTION SCREEN (REVEALED UNDER CURTAIN)
          // ==================================================================
          AnimatedBuilder(
            animation: _underneathRevealController,
            builder: (context, child) {
              return Transform.scale(
                scale: _underneathScaleAnimation.value,
                child: Opacity(
                  opacity: _underneathOpacityAnimation.value,
                  child: child,
                ),
              );
            },
            child: IgnorePointer(
              ignoring: !_isTransitioning,
              child: widget.nextScreen ?? const RoleSelectionScreen(),
            ),
          ),

          // ==================================================================
          // LAYER 1: CURRENT SCREEN CURTAIN (MOVES DOWNWARD ON ALLOW)
          // ==================================================================
          AnimatedBuilder(
            animation: _curtainDropAnimation,
            builder: (context, child) {
              // Slides downward past the screen height
              final double dropOffset = _curtainDropAnimation.value * (screenH + 120.0);

              return Transform.translate(
                offset: Offset(0, dropOffset),
                child: child,
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF4F9FD),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF013973).withValues(alpha: 0.28),
                    blurRadius: 36,
                    offset: const Offset(0, 20),
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Scenic brand background image
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/screen_bg_1.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      errorBuilder: (_, _, _) => const SizedBox(),
                    ),
                  ),

                  // Soft white/ice protective gradient
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.65),
                            const Color(0xFFEAF4FB).withValues(alpha: 0.88),
                            const Color(0xFFDCEEFB).withValues(alpha: 0.94),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Curtain Header Roller Rod at top
                  _buildRollerBlindRod(screenW),

                  // Main Curtain Body Content
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: _buildCurtainContent(screenW, screenH),
                    ),
                  ),

                  // Dim overlay when permission popup is open
                  AnimatedBuilder(
                    animation: _pullCurve,
                    builder: (context, _) {
                      final double dimT = _pullCurve.value.clamp(0.0, 1.0);
                      if (dimT <= 0.01) return const SizedBox.shrink();

                      return Positioned.fill(
                        child: GestureDetector(
                          onTap: _closePopup,
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            color: const Color(0xFF01274F).withValues(alpha: 0.32 * dimT),
                          ),
                        ),
                      );
                    },
                  ),

                  // ============================================================
                  // LAYER 2: PERMISSION POPUP (SLIDES UPWARD AS CORD IS PULLED)
                  // ============================================================
                  AnimatedBuilder(
                    animation: _pullCurve,
                    builder: (context, child) {
                      final double pullT = _pullCurve.value.clamp(0.0, 1.0);
                      // Popup height is approximately 430px
                      final double hiddenY = 460.0;
                      final double slideY = hiddenY * (1.0 - pullT);

                      return Positioned(
                        left: 0,
                        right: 0,
                        bottom: -slideY,
                        child: child!,
                      );
                    },
                    child: _buildPermissionPopup(screenW),
                  ),

                  // ============================================================
                  // LAYER 3: VERTICAL PULL CORD & REALISTIC ACORN HANDLE
                  // ============================================================
                  _buildVerticalPullCord(screenH),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TOP ROLLER BLIND HEADER ROD
  // --------------------------------------------------------------------------
  Widget _buildRollerBlindRod(double screenW) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 12,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF94A3B8),
              Color(0xFFCBD5E1),
              Color(0xFFE2E8F0),
              Color(0xFF64748B),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // CURTAIN SURFACE CONTENT
  // --------------------------------------------------------------------------
  Widget _buildCurtainContent(double screenW, double screenH) {
    final double scale = (screenW / 390.0).clamp(0.75, 1.30);

    return Column(
      children: [
        SizedBox(height: (28.0 * scale).clamp(18.0, 36.0)),

        // Brand Logo & Shield Header
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/app_logo.png',
              width: (42.0 * scale).clamp(32.0, 50.0),
              height: (42.0 * scale).clamp(32.0, 50.0),
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Icon(
                Icons.shield_rounded,
                size: (36.0 * scale).clamp(28.0, 44.0),
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
                      fontSize: (24.0 * scale).clamp(18.0, 30.0),
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  TextSpan(
                    text: 'Q',
                    style: TextStyle(
                      color: const Color(0xFF00FF00),
                      fontSize: (26.0 * scale).clamp(20.0, 32.0),
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                      shadows: const [
                        Shadow(color: Color(0x6600FF00), blurRadius: 6),
                      ],
                    ),
                  ),
                  TextSpan(
                    text: 'Shield',
                    style: TextStyle(
                      color: const Color(0xFF013973),
                      fontSize: (24.0 * scale).clamp(18.0, 30.0),
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        Text(
          'DISASTER RESPONSE & FLOOD SAFEGUARD',
          style: TextStyle(
            color: const Color(0xFF013973).withValues(alpha: 0.70),
            fontSize: (10.0 * scale).clamp(8.5, 12.0),
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),

        const Spacer(),

        // Central Setup Showcase Card
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: (20.0 * scale).clamp(16.0, 26.0),
            vertical: (24.0 * scale).clamp(18.0, 30.0),
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFD2E6F7), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF013973).withValues(alpha: 0.08),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated pulsing shield badge
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F3FD),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFBCE0FA), width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x18007AEB),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.security_rounded,
                    size: 32,
                    color: Color(0xFF007AEB),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Safety First Setup',
                style: TextStyle(
                  color: const Color(0xFF013973),
                  fontSize: (20.0 * scale).clamp(17.0, 24.0),
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Pull the cord on the right downward to configure essential emergency permissions.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF4A6B8A),
                  fontSize: (13.0 * scale).clamp(11.0, 15.0),
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 20),

              // Interactive Action Clue Button (allows tap-to-open cord as well)
              GestureDetector(
                onTap: _openPopupDirectly,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF007AEB), Color(0xFF005BC5)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF007AEB).withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Pull Cord or Tap to Open',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedBuilder(
                        animation: _idleBobAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _idleBobAnimation.value * 0.4),
                            child: child,
                          );
                        },
                        child: const Icon(
                          Icons.arrow_downward_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Bottom government trust footer
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.verified_rounded,
              color: Color(0xFF16A34A),
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              'NDMA & State Disaster Management Protocols Compliant',
              style: TextStyle(
                color: const Color(0xFF5B7D9D),
                fontSize: (10.5 * scale).clamp(9.0, 12.0),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        SizedBox(height: (16.0 * scale).clamp(10.0, 24.0)),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // VERTICAL PULL CORD & REALISTIC ACORN HANDLE
  // --------------------------------------------------------------------------
  Widget _buildVerticalPullCord(double screenH) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pullController,
        _curtainRetractController,
        _idleBobController,
      ]),
      builder: (context, _) {
        // Base cord length
        double cordLen = _kRestingCordLength;

        // Extension from interactive user drag
        cordLen += _pullController.value * _kMaxPullExtension;

        // Retraction to top on Allow trigger
        if (_isTransitioning) {
          final double retractT = _cordRetractAnimation.value;
          cordLen = cordLen * (1.0 - retractT);
        } else if (!_isCordHoveredOrDragged && !_isPopupOpen) {
          // Idle gentle physical bobbing
          cordLen += _idleBobAnimation.value;
        }

        const double cordX = 26.0; // Margin from right screen edge

        return Positioned(
          top: 0,
          right: cordX,
          child: GestureDetector(
            onVerticalDragStart: _onCordDragStart,
            onVerticalDragUpdate: _onCordDragUpdate,
            onVerticalDragEnd: _onCordDragEnd,
            onTap: () {
              if (_isPopupOpen) {
                _closePopup();
              } else {
                _openPopupDirectly();
              }
            },
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 54,
              height: cordLen + 64, // Cord + handle height
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  // 1. Physical Cord / Beaded Ball-Chain
                  CustomPaint(
                    size: Size(18, cordLen),
                    painter: _RollerBlindCordPainter(
                      cordLength: cordLen,
                      isPulled: _pullController.value > 0.1,
                    ),
                  ),

                  // 2. Realistic Weighted Acorn Handle at bottom
                  Positioned(
                    top: cordLen,
                    child: _buildHandlePendant(
                      isDragged: _isCordHoveredOrDragged,
                      isPulled: _pullController.value > 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Realistic Acorn / Drop Pendant Handle
  Widget _buildHandlePendant({required bool isDragged, required bool isPulled}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      width: isDragged ? 24 : 22,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFE2E8F0),
            Color(0xFF94A3B8),
            Color(0xFF475569),
          ],
          stops: [0.0, 0.35, 0.75, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDragged ? 0.40 : 0.25),
            blurRadius: isDragged ? 12 : 8,
            offset: const Offset(3, 6),
            spreadRadius: isDragged ? 1 : 0,
          ),
          BoxShadow(
            color: const Color(0xFF007AEB).withValues(alpha: isPulled ? 0.35 : 0.0),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.9),
          width: 1.0,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Top mounting chrome ring
          Container(
            width: 10,
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFF013973),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),
          // Grip ridges
          Container(
            width: 12,
            height: 1.5,
            color: const Color(0xFF64748B).withValues(alpha: 0.6),
          ),
          const SizedBox(height: 2.5),
          Container(
            width: 12,
            height: 1.5,
            color: const Color(0xFF64748B).withValues(alpha: 0.6),
          ),
          const SizedBox(height: 2.5),
          Container(
            width: 12,
            height: 1.5,
            color: const Color(0xFF64748B).withValues(alpha: 0.6),
          ),
          const SizedBox(height: 4),
          // Downward arrow icon
          Icon(
            isPulled ? Icons.expand_less_rounded : Icons.expand_more_rounded,
            size: 13,
            color: const Color(0xFF013973),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // PERMISSION POPUP (INTEGRATED INTO CURTAIN MECHANISM)
  // --------------------------------------------------------------------------
  Widget _buildPermissionPopup(double screenW) {
    return Container(
      width: screenW,
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(color: const Color(0xFFD0E4F5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF01274F).withValues(alpha: 0.22),
            blurRadius: 32,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top pill handle
          Center(
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Header Title & Subtitle
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F3FD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBCE0FA)),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: Color(0xFF007AEB),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Emergency Permissions',
                      style: TextStyle(
                        color: Color(0xFF013973),
                        fontSize: 18.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Required for live flood radar & evacuation',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 3 Permission Feature Items
          _buildPermissionItem(
            icon: Icons.location_on_rounded,
            iconBg: const Color(0xFFEAF5FF),
            iconColor: const Color(0xFF007AEB),
            title: 'Precision Location',
            desc: 'Detects high-risk inundation zones & nearest shelters.',
          ),
          const SizedBox(height: 10),
          _buildPermissionItem(
            icon: Icons.notifications_active_rounded,
            iconBg: const Color(0xFFFEF3C7),
            iconColor: const Color(0xFFD97706),
            title: 'Critical Emergency Broadcasts',
            desc: 'Instant siren push alerts & dam release warnings.',
          ),
          const SizedBox(height: 10),
          _buildPermissionItem(
            icon: Icons.emergency_share_rounded,
            iconBg: const Color(0xFFDCFCE7),
            iconColor: const Color(0xFF16A34A),
            title: 'Tactical SOS Beacon Relay',
            desc: 'Direct priority beacon to NDRF & medical rescue teams.',
          ),

          const SizedBox(height: 22),

          // Actions: [ Not Now ]  [ Allow ]
          Row(
            children: [
              // "Not Now" Ghost Button
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTapDown: (_) => setState(() => _notNowPressed = true),
                  onTapUp: (_) {
                    setState(() => _notNowPressed = false);
                    _closePopup();
                  },
                  onTapCancel: () => setState(() => _notNowPressed = false),
                  child: AnimatedScale(
                    scale: _notNowPressed ? 0.96 : 1.0,
                    duration: const Duration(milliseconds: 120),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Not Now',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // "Allow" Primary Button
              Expanded(
                flex: 3,
                child: GestureDetector(
                  onTapDown: (_) => setState(() => _allowPressed = true),
                  onTapUp: (_) {
                    setState(() => _allowPressed = false);
                    _handleAllow();
                  },
                  onTapCancel: () => setState(() => _allowPressed = false),
                  child: AnimatedScale(
                    scale: _allowPressed ? 0.96 : 1.0,
                    duration: const Duration(milliseconds: 120),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF007AEB), Color(0xFF005BC5)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF007AEB).withValues(alpha: 0.38),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Allow & Continue',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
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

  Widget _buildPermissionItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9EFF5)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(icon, color: iconColor, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1.5),
                Text(
                  desc,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CUSTOM PAINTER: PHYSICAL ROLLER-BLIND BALL-CHAIN / BRAIDED CORD
// ============================================================================

class _RollerBlindCordPainter extends CustomPainter {
  final double cordLength;
  final bool isPulled;

  _RollerBlindCordPainter({
    required this.cordLength,
    required this.isPulled,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double midX = size.width / 2;

    // 1. Top metallic bracket eyelet
    final bracketPaint = Paint()
      ..color = const Color(0xFF64748B)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(midX, 4), width: 12, height: 8),
        const Radius.circular(3),
      ),
      bracketPaint,
    );

    // 2. Central woven/metal cord line
    final cordCorePaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(midX, 6), Offset(midX, cordLength), cordCorePaint);

    // 3. Beaded roller ball chain highlights
    final beadLightPaint = Paint()
      ..color = isPulled ? const Color(0xFFBAE6FD) : Colors.white
      ..style = PaintingStyle.fill;

    final beadShadowPaint = Paint()
      ..color = const Color(0xFF475569)
      ..style = PaintingStyle.fill;

    const double beadSpacing = 7.5;
    const double beadRadius = 2.2;

    for (double y = 8; y < cordLength; y += beadSpacing) {
      // Small shadow
      canvas.drawCircle(Offset(midX + 0.4, y + 0.5), beadRadius, beadShadowPaint);
      // Main bead
      canvas.drawCircle(Offset(midX, y), beadRadius, beadLightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RollerBlindCordPainter oldDelegate) {
    return oldDelegate.cordLength != cordLength || oldDelegate.isPulled != isPulled;
  }
}
