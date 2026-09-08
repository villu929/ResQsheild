import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'login_screen.dart';
import 'role_selection_screen.dart';

void main() {
  runApp(const ResQShieldApp());
}

class ResQShieldApp extends StatelessWidget {
  const ResQShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GetStartedScreen(),
    );
  }
}

class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({super.key});

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

// ============================================================================
// GET STARTED SCREEN STATE
// ----------------------------------------------------------------------------
// Single continuous Ticker drives all smooth ocean and floating animations
// ============================================================================

class _GetStartedScreenState extends State<GetStartedScreen>
    with TickerProviderStateMixin {
  late final Ticker _ticker;

  // Keeps counting upward forever — never resets, so nothing ever
  // "snaps" back to a starting value.
  double _elapsedSeconds = 0;

  bool passwordVisible = false;
  bool _loginPressed = false;

  // --------------------------------------------------------------------
  // LOGIN BUTTON PRESS ANIMATION
  // --------------------------------------------------------------------
  late final AnimationController _pressController;
  late final Animation<double> _pressAnimation;

  void _setLoginPressed(bool pressed) {
    if (_loginPressed == pressed) return;
    _loginPressed = pressed;
    if (pressed) {
      _pressController.forward();
    } else {
      _pressController.reverse();
    }
  }

  final TextEditingController _identityController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _validateLogin() {
    // Navigate to Role Selection Screen (Primary Gateway)
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
    );
  }

  // Same "speeds" as the old controller durations, just used as
  // divisors on a continuous clock instead of as repeat durations.
  static const double _waterCycle = 26;
  static const double _boatCycle = 8;
  static const double _loginCycle = 7;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      setState(() {
        _elapsedSeconds = elapsed.inMicroseconds / 1000000.0;
      });
    })..start();

    // Quick sink (90ms) so it feels instant/responsive under the finger,
    // slower springy return (320ms with overshoot) so it feels alive
    // when released — the classic "physical button" timing asymmetry.
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 320),
    );
    _pressAnimation = CurvedAnimation(
      parent: _pressController,
      curve: Curves.easeOut,
      reverseCurve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    _pressController.dispose();
    _identityController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double waterValue = _elapsedSeconds / _waterCycle;
    final double loginValue = _elapsedSeconds / _loginCycle;
    final media = MediaQuery.of(context);
    final sw = media.size.width;    // screen width
    final sh = media.size.height;   // screen height

    // Responsive scale factor (base: 375w x 812h iPhone)
    final scale = (sw / 375).clamp(0.75, 1.3);
    final vScale = (sh / 812).clamp(0.70, 1.2);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xff000208),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ============================================================
          // OCEAN BACKGROUND — fills entire screen
          // ============================================================
          CustomPaint(
            painter: RealisticOceanPainter(waterValue),
            size: Size(sw, sh),
          ),

          // ============================================================
          // UI — responsive, single screen, no scroll
          // ============================================================
          SafeArea(
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                final double w = constraints.maxWidth;
                final double h = constraints.maxHeight;

                // Responsive scaling driven directly by LayoutBuilder constraints:
                // Base reference viewport: 390w x 844h (standard mobile display)
                final double scaleW = (w / 390.0).clamp(0.65, 1.45);
                final double scaleH = (h / 844.0).clamp(0.65, 1.35);
                final double textScale = (w / 390.0).clamp(0.70, 1.35);

                // Responsive element dimensions
                final double logoSize = (46.0 * scaleW).clamp(32.0, 64.0);
                final double titleFontSize = (24.0 * textScale).clamp(17.0, 32.0);
                final double qFontSize = (27.0 * textScale).clamp(19.0, 36.0);
                final double taglineFontSize = (11.0 * textScale).clamp(8.5, 14.5);

                // Normal mobile-sized sleek floating login button
                final double btnW = (w * 0.38).clamp(126.0, 165.0);
                final double btnH = (40.0 * scaleW).clamp(35.0, 45.0);
                final double btnFontSize = (14.0 * textScale).clamp(12.0, 16.0);
                final double btnIconSize = (15.5 * textScale).clamp(13.0, 18.0);

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: (h * 0.07).clamp(24.0, 64.0)),

                    // ── LOGO ──
                    Image.asset(
                      'assets/images/app_logo.png',
                      width: logoSize,
                      height: logoSize,
                      fit: BoxFit.contain,
                    ),

                    SizedBox(height: (8.0 * scaleH).clamp(4.0, 14.0)),

                    // ── APP NAME (ResQShield with exact HEX colors) ──
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Res',
                            style: TextStyle(
                              color: const Color(0xFF013973), // Main blue text
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(
                                  color: Colors.white.withOpacity(0.9),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1.5),
                                ),
                                Shadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                          TextSpan(
                            text: 'Q',
                            style: TextStyle(
                              color: const Color(0xFF00FF00), // Green Q
                              fontSize: qFontSize,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(
                                  color: const Color(0xFF00FF00).withOpacity(0.6),
                                  blurRadius: 8,
                                  offset: const Offset(0, 0),
                                ),
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1.5),
                                ),
                              ],
                            ),
                          ),
                          TextSpan(
                            text: 'Shield',
                            style: TextStyle(
                              color: const Color(0xFF013973), // Main blue text
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(
                                  color: Colors.white.withOpacity(0.9),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1.5),
                                ),
                                Shadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: (4.0 * scaleH).clamp(2.0, 8.0)),

                    // ── TAGLINE (SAFER ROUTES... with exact HEX #013973) ──
                    Text(
                      'SAFER ROUTES. STRONGER COMMUNITIES.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF013973), // Tagline blue text
                        fontSize: taglineFontSize,
                        fontWeight: FontWeight.w800,
                        letterSpacing: (0.9 * textScale).clamp(0.4, 1.5),
                        shadows: [
                          Shadow(
                            color: Colors.white.withOpacity(0.9),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // ── FLOATING LOGIN BUTTON (Normal compact mobile size) ──
                    Builder(
                      builder: (_) {
                        final t = loginValue * math.pi * 2;

                        // Gentle float animation
                        final floatY =
                            math.sin(t * .82) * 3.5 +
                            math.sin(t * 1.37 + .8) * 1.4;
                        final floatX = math.sin(t * .43 + 1.2) * 1.6;

                        // Subtle 3D tilt
                        final tiltX =
                            -(math.pi * 52.5 / 180) +
                            math.sin(t * .78 + .6) * (math.pi * 8 / 180);
                        final tiltZ =
                            math.sin(t * .72 + .35) * (math.pi * 3 / 180) +
                            math.sin(t * 1.17 + 1.1) * (math.pi * 1.2 / 180);
                        final rockBias = math.sin(tiltZ) * 4;

                        final pressT = _pressAnimation.value;
                        final pressSink = pressT * 2.8;

                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapDown: (_) => _setLoginPressed(true),
                          onTapUp: (_) {
                            _setLoginPressed(false);
                            _validateLogin();
                          },
                          onTapCancel: () => _setLoginPressed(false),
                          child: Transform.translate(
                            offset: Offset(floatX, floatY),
                            child: Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                // Water reflection glow below button
                                Positioned(
                                  top: btnH * 0.62,
                                  child: CustomPaint(
                                    size: Size(btnW * 1.2, 38),
                                    painter: LoginWaterReflectionPainter(loginValue),
                                  ),
                                ),
                                // Ripple ring
                                Positioned(
                                  top: -26,
                                  child: CustomPaint(
                                    size: Size(btnW * 1.45, 92),
                                    painter: LoginWaterRipplePainter(loginValue, rockBias),
                                  ),
                                ),
                                // 3D button
                                Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()
                                    ..setEntry(3, 2, 0.003)
                                    ..rotateX(tiltX)
                                    ..rotateZ(tiltZ),
                                  child: Container(
                                    width: btnW,
                                    height: btnH,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xff063F52).withOpacity(.50),
                                          blurRadius: 16,
                                          spreadRadius: -2,
                                          offset: const Offset(0, 16),
                                        ),
                                        BoxShadow(
                                          color: const Color(0xff54C9F4).withOpacity(.25),
                                          blurRadius: 16,
                                          spreadRadius: 1,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      clipBehavior: Clip.none,
                                      children: [
                                        // Bottom face (water-side depth)
                                        Positioned(
                                          left: 1, right: 1, top: 7, bottom: 0,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(30),
                                              gradient: const LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Color(0xff8FC4D8),
                                                  Color(0xff3D7E99),
                                                  Color(0xff123444),
                                                ],
                                              ),
                                              border: Border.all(color: const Color(0xff6DC9E7), width: 1.0),
                                            ),
                                          ),
                                        ),
                                        // Top face (the pressable surface)
                                        Positioned(
                                          left: 0, right: 0, top: 0, bottom: 7,
                                          child: Transform.translate(
                                            offset: Offset(0, pressSink),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(30),
                                                gradient: const LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    Color(0xffCFE9F2),
                                                    Color(0xffF5FCFF),
                                                    Color(0xffffffff),
                                                    Color(0xffAEDBEA),
                                                  ],
                                                  stops: [0.0, 0.30, 0.70, 1.0],
                                                ),
                                                border: Border.all(color: Colors.white, width: 1.2),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.white.withOpacity(.75 * (1 - pressT * .6)),
                                                    blurRadius: 4,
                                                    spreadRadius: -1,
                                                    offset: const Offset(0, -1),
                                                  ),
                                                ],
                                              ),
                                              child: Center(
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      'Get Started',
                                                      style: TextStyle(
                                                        color: const Color(0xff1263A2),
                                                        fontSize: btnFontSize,
                                                        fontWeight: FontWeight.bold,
                                                        shadows: const [
                                                          Shadow(
                                                            color: Colors.white,
                                                            blurRadius: 2,
                                                            offset: Offset(0, 1),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(width: (6.0 * scaleW).clamp(4.0, 8.0)),
                                                    Icon(
                                                      Icons.arrow_forward_rounded,
                                                      color: const Color(0xff1263A2),
                                                      size: btnIconSize,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Waterline shimmer at button base
                                        Positioned(
                                          left: 10, right: 10, bottom: 4,
                                          child: IgnorePointer(
                                            child: CustomPaint(
                                              size: Size(btnW - 20, 6),
                                              painter: LoginWaterlinePainter(loginValue),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Foam contact line at waterline
                                Positioned(
                                  top: btnH * 0.72,
                                  child: IgnorePointer(
                                    child: CustomPaint(
                                      size: Size(btnW * 1.2, 28),
                                      painter: LoginContactFoamPainter(loginValue, rockBias),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: (h * 0.12).clamp(30.0, 90.0)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// WATER FLOATING LOGIN - REFLECTION
// ============================================================================

class LoginWaterReflectionPainter extends CustomPainter {
  final double animationValue;

  LoginWaterReflectionPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final t = animationValue * math.pi * 2;

    final center = Offset(size.width / 2, size.height * .52);

    final pulse = .5 + .5 * math.sin(t * 1.15);

    final reflectionRect = Rect.fromCenter(
      center: center,
      width: size.width * 0.95 + pulse * (size.width * 0.05),
      height: size.height * 0.6 + pulse * 4,
    );

    canvas.drawOval(
      reflectionRect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xff9FE9E5).withOpacity(.18),
            const Color(0xff63C6CC).withOpacity(.10),
            const Color(0xff247B8A).withOpacity(.035),
            Colors.transparent,
          ],
          stops: const [0, .35, .68, 1],
        ).createShader(reflectionRect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
    );

    for (int i = 0; i < 15; i++) {
      final p = i / 14;

      final y = center.dy - (size.height * 0.28) + p * (size.height * 0.56);

      final width = (size.width * 0.25) + math.sin(p * math.pi) * (size.width * 0.45);

      final drift = math.sin(t * 1.4 + i * .75) * (2 + p * 4);

      final opacity = (.045 + math.sin(t * 1.8 + i) * .018)
          .clamp(.015, .08)
          .toDouble();

      canvas.drawLine(
        Offset(center.dx - width / 2 + drift, y),
        Offset(center.dx + width / 2 + drift, y + math.sin(t * 2 + i) * 1.3),
        Paint()
          ..color = Colors.white.withOpacity(opacity)
          ..strokeWidth = .7 + p * .7
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, .45),
      );
    }
  }

  @override
  bool shouldRepaint(covariant LoginWaterReflectionPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

// ============================================================================
// WATER RIPPLE RINGS
// ----------------------------------------------------------------------------
// Irregular / non-uniform rings. Each ring is broken into many short arc
// segments, each with its own randomized-but-deterministic strength, so
// some arcs look like a strong push of water and others barely register
// or vanish entirely. `rockBias` — passed in from the platform's own
// Z-axis roll — skews which side's segments get boosted, so the ripples
// visibly favor whichever side the capsule is currently leaning/pressing
// into the water at that instant.
// ============================================================================

class LoginWaterRipplePainter extends CustomPainter {
  final double animationValue;
  final double rockBias;

  LoginWaterRipplePainter(this.animationValue, this.rockBias);

  // The scene views the water from a steep, tilted angle (matching
  // the capsule's own perspective tilt elsewhere in this file). A
  // truly circular ripple on the water's flat surface reads as a
  // flattened ellipse from this camera angle — this ratio keeps every
  // ring's proportions consistent with that same tilt, so they look
  // like one uniform family of circles rather than random ovals.
  static const double _aspect = .235;

  static const int _ringCount = 6;
  static const int _segmentsPerRing = 18;

  // Deterministic pseudo-noise: same input always gives the same
  // output, so shapes don't crawl frame-to-frame — only the animation
  // clock moves them.
  double _hash(double x) {
    final v = math.sin(x * 12.9898 + 78.233) * 43758.5453;
    return v - v.floorToDouble();
  }

  double _hashSigned(double x) => _hash(x) * 2 - 1;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animationValue * math.pi * 2;

    final center = Offset(size.width / 2, size.height / 2);

    // Every ring shares the same origin (the capsule's water-contact
    // center) and the same growth curve, so they expand outward
    // together — the classic concentric "object disturbing still
    // water" look — but each ring's spacing, strength, and per-arc
    // makeup is jittered so the family as a whole reads as irregular,
    // organic disturbance rather than a stamped animation loop.
    for (int i = 0; i < _ringCount; i++) {
      // Irregular spacing: rings don't spawn on a perfectly even
      // schedule, each gets its own small jittered offset.
      final spawnJitter = _hash(i * 7.13) * .16;

      // Growth speed matched to the boats' own water-contact ripples
      // (BoatWaterContactPainter) rather than a fast pulsing loop —
      // each ring takes its time expanding outward.
      final phase = (animationValue * .34 + i / _ringCount + spawnJitter) % 1.0;

      final p = Curves.easeOut.transform(phase);
      final fade = math.sin(phase * math.pi);

      // Some rings are simply born stronger than others.
      final ringStrength = .55 + _hash(i * 3.31 + 2) * .8;

      final baseOpacity = (.20 * fade * ringStrength * (1 - p * .3))
          .clamp(0.0, .26)
          .toDouble();

      if (baseOpacity < .006) continue;

      final rx = (size.width * 0.12) + p * (size.width * 0.40);
      final ry = rx * _aspect;
      final baseStrokeWidth = 1.45 + (1 - p) * 1.2;

      for (int seg = 0; seg < _segmentsPerRing; seg++) {
        final a0 = (seg / _segmentsPerRing) * math.pi * 2;
        final a1 = ((seg + 1) / _segmentsPerRing) * math.pi * 2;

        // Per-segment hashed strength — this is what breaks a ring
        // into uneven strong/weak arcs instead of one uniform stroke.
        // NOTE: this seed is fixed per ring+segment (no animationValue
        // in it) so the base character of each arc doesn't jump around
        // frame to frame — only the smooth sine-based `drift` below
        // moves it over time, same as the boats' ripples.
        final segSeed = i * 91.7 + seg * 13.37;
        final segNoise = _hash(segSeed);

        // Slow drift so a ring's weak spots rotate/change over its
        // lifetime rather than always sitting in the same place.
        final drift = math.sin(t * .5 + i * 1.4 + seg * .8) * .5 + .5;

        // Bias from the capsule's own roll: arcs on the side it's
        // leaning toward get boosted, the far side suppressed.
        final midAngle = (a0 + a1) / 2;
        final leanDot = math.cos(midAngle); // -1 (left) .. 1 (right)
        final leanBoost = 1 + (leanDot * rockBias / 6) * .45;

        var segStrength = (segNoise * .6 + drift * .4) * leanBoost;
        segStrength = segStrength.clamp(0.0, 1.4);

        // Real ripples have gaps, especially in their weaker
        // regions — randomly drop the faintest segments entirely.
        if (segStrength < .3) continue;

        final opacity = (baseOpacity * segStrength).clamp(0.0, .30).toDouble();
        final strokeWidth = (baseStrokeWidth * (.5 + segStrength * .8))
            .clamp(.9, 4.2)
            .toDouble();

        final path = Path();
        const steps = 6;

        for (int k = 0; k <= steps; k++) {
          final a = a0 + (a1 - a0) * (k / steps);

          // Multi-frequency radial distortion (matches the original
          // wobble) plus per-segment jitter, so each arc's edge is
          // organic rather than a clean ellipse slice.
          final distortion =
              1 +
              math.sin(a * 2.7 + t * 1.2 + i * 1.7) * .060 +
              math.sin(a * 5.3 - t * .8 + i) * .030 +
              math.sin(a * 9 + t * .5) * .015 +
              _hashSigned(segSeed + k) * .04 +
              math.sin(a * 3.4 + t * .35 + seg) * .02;

          final directional = 1 + math.cos(a) * p * .11;

          final x = center.dx + math.cos(a) * rx * distortion * directional;

          final y = center.dy + math.sin(a) * ry * distortion;

          if (k == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }

        canvas.drawPath(
          path,
          Paint()
            ..color = Colors.white.withOpacity(opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant LoginWaterRipplePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.rockBias != rockBias;
  }
}

// ============================================================================
// WATERLINE
// ============================================================================

class LoginWaterlinePainter extends CustomPainter {
  final double animationValue;

  LoginWaterlinePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final t = animationValue * math.pi * 2;

    final path = Path();

    for (int i = 0; i <= 90; i++) {
      final p = i / 90;

      final x = p * size.width;

      final y =
          size.height / 2 +
          math.sin(p * math.pi * 3.8 + t * 1.4) * 1.15 +
          math.sin(p * math.pi * 9 + t * 2.1) * .45;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xffE9FFFF).withOpacity(.36)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.05
        ..strokeCap = StrokeCap.round,
    );

    final lowerPath = Path();

    for (int i = 0; i <= 90; i++) {
      final p = i / 90;

      final x = p * size.width;

      final y =
          size.height / 2 + 2.0 + math.sin(p * math.pi * 4 + t * 1.3) * .8;

      if (i == 0) {
        lowerPath.moveTo(x, y);
      } else {
        lowerPath.lineTo(x, y);
      }
    }

    canvas.drawPath(
      lowerPath,
      Paint()
        ..color = const Color(0xff4FC5D9).withOpacity(.20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant LoginWaterlinePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

// ============================================================================
// CONTACT FOAM / FRONT SPLASH
// ----------------------------------------------------------------------------
// Takes `rockBias` so foam density is asymmetric — the side the
// capsule is currently leaning into the water gets noticeably more foam
// than the far side, matching the same physical logic as the ripple
// painter above.
// ============================================================================

class LoginContactFoamPainter extends CustomPainter {
  final double animationValue;
  final double rockBias;

  LoginContactFoamPainter(this.animationValue, this.rockBias);

  double _hash(double x) {
    final v = math.sin(x * 12.9898 + 78.233) * 43758.5453;
    return v - v.floorToDouble();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = animationValue * math.pi * 2;
    final cx = size.width / 2;

    final floatBob = math.sin(t * .82) * 5.6 + math.sin(t * 1.37 + .8) * 2.3;

    final bobVelocity =
        math.cos(t * .82) * .82 * 5.6 + math.cos(t * 1.37 + .8) * 1.37 * 2.3;

    final downwardImpact = (bobVelocity / 6.0).clamp(0.0, 1.0).toDouble();

    final waterY = 12 + floatBob * .65 + math.sin(t * 1.15) * 1.4;

    // ------------------------------------------------------------
    // SOFT PRESSURE UNDER THE BUTTON
    // ------------------------------------------------------------
    final pressureRect = Rect.fromCenter(
      center: Offset(cx, waterY + 5),
      width: 285 + downwardImpact * 22,
      height: 31 + downwardImpact * 9,
    );

    canvas.drawOval(
      pressureRect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xff0A7180).withOpacity(.22),
            const Color(0xff4DBBC6).withOpacity(.11),
            Colors.transparent,
          ],
          stops: const [0, .48, 1],
        ).createShader(pressureRect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // ------------------------------------------------------------
    // OVERLAPPING FRONT WATER WAVES
    // ------------------------------------------------------------
    for (int wave = 0; wave < 4; wave++) {
      final phase = t * (1.05 + wave * .12) + wave * 1.7;
      final path = Path();

      for (int i = 0; i <= 100; i++) {
        final p = i / 100;
        final x = 22 + p * (size.width - 44);
        final envelope = math.sin(p * math.pi);

        final largeWave =
            math.sin(p * math.pi * (3.0 + wave * .7) + phase) *
            (1.1 + wave * .45);

        final smallWave =
            math.sin(p * math.pi * 11.0 + phase * 1.8 + wave) * .35;

        final buttonPressure = envelope * (1.5 + downwardImpact * 3.2);

        final y = waterY - buttonPressure + largeWave + smallWave;

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withOpacity(.045 + (3 - wave) * .025)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .65 + (3 - wave) * .20
          ..strokeCap = StrokeCap.round,
      );
    }

    // ------------------------------------------------------------
    // LEFT + RIGHT WAVES TRAVELLING INTO THE BUTTON
    // ------------------------------------------------------------
    const buttonHalf = 130.0;

    for (final side in [-1.0, 1.0]) {
      for (int wave = 0; wave < 5; wave++) {
        final raw =
            (animationValue * 1.18 + wave * .19 + (side > 0 ? .47 : 0.0)) % 1.0;

        final approach = Curves.easeInOut.transform(raw);
        final startDistance = 175.0 + wave * 8.0;
        final contactDistance = buttonHalf - 3.0;

        final distance =
            startDistance + (contactDistance - startDistance) * approach;

        final x = cx + side * distance;
        final impact = math.sin(approach * math.pi);

        final waveHeight = 1.2 + impact * 4.5 + downwardImpact * 2.0;

        final path = Path();
        const spread = 34.0;

        for (int i = -10; i <= 10; i++) {
          final p = i / 10;
          final localX = x + p * spread;
          final envelope = math.exp(-p * p * 2.2);

          final ripple =
              math.sin(p * math.pi * 2.7 + t * 2.2 + wave * 1.5) *
              (.45 + impact * .9);

          final y = waterY - waveHeight * envelope + ripple;

          if (i == -10) {
            path.moveTo(localX, y);
          } else {
            path.lineTo(localX, y);
          }
        }

        final opacity = (.025 + impact * .11) * (1 - raw * .35);

        canvas.drawPath(
          path,
          Paint()
            ..color = Colors.white.withOpacity(
              opacity.clamp(0.0, .16).toDouble(),
            )
            ..style = PaintingStyle.stroke
            ..strokeWidth = .65 + impact * .75
            ..strokeCap = StrokeCap.round,
        );

        // Impact splash where the side wave meets the button.
        if (approach > .78 && approach < .94) {
          final burst = math.sin(((approach - .78) / .16) * math.pi);

          final contactX = cx + side * buttonHalf;

          canvas.drawArc(
            Rect.fromCenter(
              center: Offset(contactX, waterY - 1),
              width: 13 + burst * 18,
              height: 6 + burst * 7,
            ),
            side > 0 ? math.pi * 1.15 : math.pi * -.15,
            math.pi * .72,
            false,
            Paint()
              ..color = Colors.white.withOpacity(.12 * burst)
              ..style = PaintingStyle.stroke
              ..strokeWidth = .9
              ..strokeCap = StrokeCap.round,
          );
        }
      }
    }

    // ------------------------------------------------------------
    // THIN WATER STREAMS CLIMBING UP BOTH SIDES
    // ------------------------------------------------------------
    for (final side in [-1.0, 1.0]) {
      for (int stream = 0; stream < 7; stream++) {
        final seed = stream * 19.37 + (side > 0 ? 100 : 0);

        final phase =
            t * (.16 + _hash(seed) * .08) + _hash(seed + 2.0) * math.pi * 2;

        final climb = .5 + .5 * math.sin(phase);
        final strength = .35 + _hash(seed + 4.2) * .65;
        final rise = climb * climb * strength;
        final maxRise = 5.0 + _hash(seed + 7.0) * 11.0;
        final streamRise = rise * maxRise;

        final x = cx + side * (buttonHalf - 2 + stream * .65);

        final path = Path();

        for (int i = 0; i <= 18; i++) {
          final p = i / 18;

          final y = waterY - streamRise * p;
          final drift =
              math.sin(p * math.pi * 2 + phase * 1.3 + stream) * (.7 + p * 1.7);

          final xx = x + side * drift;

          if (i == 0) {
            path.moveTo(xx, y);
          } else {
            path.lineTo(xx, y);
          }
        }

        canvas.drawPath(
          path,
          Paint()
            ..color = Colors.white.withOpacity(
              (.018 + rise * .055).clamp(0.0, .075).toDouble(),
            )
            ..style = PaintingStyle.stroke
            ..strokeWidth = .55 + rise * .55
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    // ------------------------------------------------------------
    // VERY SUBTLE WATER LIPS OVER THE SIDE EDGE
    // ------------------------------------------------------------
    for (final side in [-1.0, 1.0]) {
      for (int i = 0; i < 3; i++) {
        final phase =
            (animationValue * (.42 + i * .055) +
                i * .31 +
                (side > 0 ? .47 : 0)) %
            1.0;

        final rise = math.sin(phase * math.pi);
        if (rise < .15) continue;

        final edgeX = cx + side * (buttonHalf - 2);
        final width = 9 + rise * (9 + i * 4);
        final path = Path();

        for (int p = 0; p <= 14; p++) {
          final q = p / 14;

          final x = edgeX + side * (q - .5) * width;

          final y =
              waterY -
              rise * (2.0 + math.sin(q * math.pi) * 4.5) +
              math.sin(q * math.pi * 3 + t * 1.8) * .35;

          if (p == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }

        canvas.drawPath(
          path,
          Paint()
            ..color = Colors.white.withOpacity(.035 * rise)
            ..style = PaintingStyle.stroke
            ..strokeWidth = .8
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    // ------------------------------------------------------------
    // SMALL FOAM / AIR PARTICLES AROUND THE IMPACT ZONE
    // ------------------------------------------------------------
    const particleCount = 42;

    for (int i = 0; i < particleCount; i++) {
      final seed = i * 17.31;
      final angle =
          (i / particleCount) * math.pi * 2 + (_hash(seed) - .5) * .20;

      final radius = 118 + _hash(seed + 3) * 36;

      final bob = math.sin(
        t * (1.0 + _hash(seed + 6) * .8) + _hash(seed + 9) * math.pi * 2,
      );

      final x = cx + math.cos(angle) * radius + bob * 1.2;
      final y = waterY + math.sin(angle) * radius * .12 + bob * .8;

      final proximity = (1 - ((radius - 118) / 36)).clamp(0.0, 1.0).toDouble();

      final opacity = (.018 + _hash(seed + 11) * .045) * proximity;

      canvas.drawCircle(
        Offset(x, y),
        .35 + _hash(seed + 14) * .8,
        Paint()
          ..color = Colors.white.withOpacity(
            opacity.clamp(0.0, .07).toDouble(),
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant LoginContactFoamPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.rockBias != rockBias;
  }
}

class BoatTextField extends StatelessWidget {
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final bool isVisible;
  final VoidCallback? onVisibilityPressed;
  final double animationValue;
  final int boatIndex;
  final TextEditingController? controller;

  const BoatTextField({
    super.key,
    required this.hintText,
    required this.icon,
    required this.animationValue,
    required this.boatIndex,
    this.obscureText = false,
    this.isVisible = false,
    this.onVisibilityPressed,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final t = animationValue * math.pi * 2;

    const swellFreq = .72;
    const swellFreq2 = 1.15;
    const chopFreq = 2.18;

    const swellAmp = 7.2;
    const swell2Amp = 2.6;
    const chopAmp = 1.05;

    final verticalMovement =
        math.sin(t * swellFreq + boatIndex * 1.65) * swellAmp +
        math.sin(t * swellFreq2 + boatIndex * 2.4) * swell2Amp +
        math.sin(t * chopFreq + boatIndex * 4.2) * chopAmp;

    final horizontalMovement =
        math.sin(t * .43 + boatIndex * 2.6) * 2.9 +
        math.sin(t * 1.17 + boatIndex * 1.8) * .85;

    final verticalVelocity =
        math.cos(t * swellFreq + boatIndex * 1.65) * swellFreq * swellAmp +
        math.cos(t * swellFreq2 + boatIndex * 2.4) * swellFreq2 * swell2Amp;

    final rotation =
        verticalVelocity * .0048 + math.sin(t * 1.9 + boatIndex * 3.1) * .008;

    return Transform.translate(
      offset: Offset(horizontalMovement, verticalMovement),
      child: Transform.rotate(
        angle: rotation,
        child: SizedBox(
          width: 345,
          height: 125,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: BoatWaterContactPainter(animationValue, boatIndex),
                ),
              ),
              Positioned(
                left: 42,
                right: 42,
                bottom: 0,
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    gradient: RadialGradient(
                      colors: [
                        Colors.black.withOpacity(.32),
                        Colors.black.withOpacity(.14),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: BoatPainter(animationValue, boatIndex),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: BoatSubmergedTintPainter(
                      animationValue,
                      boatIndex,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: BoatContactFrontPainter(animationValue, boatIndex),
                  ),
                ),
              ),
              Positioned(
                left: 52,
                right: 52,
                top: 34,
                child: Row(
                  children: [
                    Icon(icon, size: 25, color: const Color(0xff1478B9)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        obscureText: obscureText && !isVisible,
                        cursorColor: const Color(0xff1478B9),
                        style: const TextStyle(
                          color: Color(0xff284B59),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: hintText,
                          hintStyle: TextStyle(
                            color: const Color(0xff58717D).withOpacity(.82),
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (onVisibilityPressed != null)
                      GestureDetector(
                        onTap: onVisibilityPressed,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            isVisible ? Icons.visibility : Icons.visibility_off,
                            size: 21,
                            color: const Color(0xff597783),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// BOAT WATER CONTACT
// ============================================================================

class BoatWaterContactPainter extends CustomPainter {
  final double animationValue;
  final int boatIndex;

  BoatWaterContactPainter(this.animationValue, this.boatIndex);

  double noise(double x) {
    return math.sin(x) * .52 +
        math.sin(x * 2.13 + boatIndex) * .24 +
        math.sin(x * 4.71) * .13;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = animationValue * math.pi * 2;

    const cx = 172.5;

    final bob = math.sin(t * .72 + boatIndex * 1.65);

    final fastBob = math.sin(t * 1.43 + boatIndex * 2.4);

    final contactY = 99 + bob * 3.7 + fastBob * .5;

    final pressureRect = Rect.fromCenter(
      center: Offset(cx, contactY + 3),
      width: 315,
      height: 30,
    );

    canvas.drawOval(
      pressureRect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xff012B3A).withOpacity(.38),
            const Color(0xff064C5C).withOpacity(.20),
            const Color(0xff0A6874).withOpacity(.06),
            Colors.transparent,
          ],
          stops: const [0, .3, .64, 1],
        ).createShader(pressureRect),
    );

    final foam = Path()..moveTo(45, contactY);

    for (double x = 45; x <= size.width - 45; x += 2.2) {
      final p = (x - 45) / (size.width - 90);

      final envelope = math.sin(p * math.pi);

      foam.lineTo(x, contactY - envelope * 1.6 + noise(p * 18 + t * 1.4) * .8);
    }

    canvas.drawPath(
      foam,
      Paint()
        ..color = const Color(0xffEFFFFF).withOpacity(.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );

    for (int ring = 0; ring < 8; ring++) {
      final raw = (animationValue * .70 + ring * .14 + boatIndex * .035) % 1.0;

      final p = Curves.easeOut.transform(raw);

      final radiusX = 38 + p * 225;

      final radiusY = 2 + p * 15.5;

      final fade = math.sin(raw * math.pi);

      final alpha = .14 * fade * (1 - p * .58);

      if (alpha < .008) {
        continue;
      }

      final path = Path();

      for (int i = 0; i <= 100; i++) {
        final a = i / 100 * math.pi * 2;

        final distortion =
            1 +
            math.sin(a * 2.7 + t * 1.2 + ring * 1.7) * .060 +
            math.sin(a * 5.3 - t * .8 + ring) * .030 +
            math.sin(a * 9 + t * .5) * .015;

        final directional = 1 + math.cos(a) * p * .11;

        final x = cx + math.cos(a) * radiusX * distortion * directional;

        final y = contactY + math.sin(a) * radiusY * distortion;

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      path.close();

      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withOpacity(alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .9 + (1 - p) * .65
          ..strokeCap = StrokeCap.round,
      );
    }

    for (final side in [-1.0, 1.0]) {
      for (int line = 0; line < 10; line++) {
        final start = 20 + line * 8.0;

        final length = 45 + line * 13.0;

        final path = Path();

        path.moveTo(cx + side * start, contactY);

        for (int i = 0; i <= 40; i++) {
          final p = i / 40;

          final x = cx + side * (start + p * length);

          final y =
              contactY +
              p * 6 +
              math.sin(p * math.pi * 3.5 + t * 2 + line) * (1 + p * 3.5);

          path.lineTo(x, y);
        }

        canvas.drawPath(
          path,
          Paint()
            ..color = Colors.white.withOpacity(.055 * (1 - line / 12))
            ..style = PaintingStyle.stroke
            ..strokeWidth = .65 + (10 - line) * .06
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    for (int i = 0; i < 28; i++) {
      final side = i.isEven ? -1.0 : 1.0;

      final distance = 18 + (i % 14) * 10.0;

      final x = cx + side * (distance + math.sin(t * 1.5 + i) * 2.5);

      final y = contactY + math.sin(t * 2 + i) * 2;

      canvas.drawLine(
        Offset(x - 2.5, y),
        Offset(x + 2.5, y + math.sin(i + t) * .6),
        Paint()
          ..color = Colors.white.withOpacity(.04 + (i % 4) * .01)
          ..strokeWidth = .7
          ..strokeCap = StrokeCap.round,
      );
    }

    _collidingWaves(canvas, contactY, cx);
  }

  void _collidingWaves(Canvas canvas, double contactY, double cx) {
    const hullHalfWidth = 58.0;
    const approachPortion = .58;

    for (final side in [-1.0, 1.0]) {
      for (int i = 0; i < 3; i++) {
        final cyclePhase =
            (animationValue * 1.35 +
                i * .34 +
                boatIndex * .12 +
                (side > 0 ? .5 : 0)) %
            1.0;

        final startX = cx + side * 168;

        final contactX = cx + side * hullHalfWidth;

        double x;
        double opacity;
        double amp;

        if (cyclePhase < approachPortion) {
          final p = cyclePhase / approachPortion;

          final eased = Curves.easeIn.transform(p);

          x = startX + (contactX - startX) * eased;

          opacity = .10 + p * .16;

          amp = 1.2 + p * 2.6;
        } else {
          final p = (cyclePhase - approachPortion) / (1 - approachPortion);

          final eased = Curves.easeOut.transform(p);

          x = contactX + (startX - contactX) * eased;

          opacity = .26 * (1 - p);

          amp = 3.8 * (1 - p * .7);
        }

        final path = Path();

        const spread = 26.0;

        for (int seg = -6; seg <= 6; seg++) {
          final sx = x + seg * (spread / 6);

          final envelope = math.cos(seg / 6 * math.pi / 2);

          final sy = contactY - amp * envelope * envelope;

          if (seg == -6) {
            path.moveTo(sx, sy);
          } else {
            path.lineTo(sx, sy);
          }
        }

        canvas.drawPath(
          path,
          Paint()
            ..color = Colors.white.withOpacity(opacity.clamp(0, 1).toDouble())
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.1
            ..strokeCap = StrokeCap.round,
        );

        final impactCloseness = (cyclePhase - approachPortion).abs();

        if (impactCloseness < .05) {
          final burstP = 1 - impactCloseness / .05;

          final burstRadius = 3 + burstP * 9;

          canvas.drawCircle(
            Offset(contactX, contactY - 2),
            burstRadius,
            Paint()
              ..color = Colors.white.withOpacity(.22 * burstP)
              ..style = PaintingStyle.stroke
              ..strokeWidth = .9,
          );

          for (int d = 0; d < 5; d++) {
            final angle = -math.pi / 2 + (d - 2) * .35;

            final dropLen = 3 + burstP * 6;

            canvas.drawLine(
              Offset(contactX, contactY - 2),
              Offset(
                contactX + math.cos(angle) * dropLen,
                contactY - 2 + math.sin(angle) * dropLen,
              ),
              Paint()
                ..color = Colors.white.withOpacity(.18 * burstP)
                ..strokeWidth = .8
                ..strokeCap = StrokeCap.round,
            );
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant BoatWaterContactPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.boatIndex != boatIndex;
  }
}

// ============================================================================
// BOAT FRONT CONTACT
// ============================================================================

class BoatContactFrontPainter extends CustomPainter {
  final double animationValue;
  final int boatIndex;

  BoatContactFrontPainter(this.animationValue, this.boatIndex);

  @override
  void paint(Canvas canvas, Size size) {
    final t = animationValue * math.pi * 2;

    final bob = math.sin(t * .72 + boatIndex * 1.65) * 3.7;

    final contactY = 98 + bob;

    final path = Path()..moveTo(45, contactY);

    for (double x = 45; x <= size.width - 45; x += 2.2) {
      final p = (x - 45) / (size.width - 90);

      path.lineTo(
        x,
        contactY - math.sin(p * math.pi) * 1.5 + math.sin(p * 21 + t * 2) * .35,
      );
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xffF3FFFF).withOpacity(.24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.45
        ..strokeCap = StrokeCap.round,
    );

    for (int i = 0; i < 7; i++) {
      final p = (animationValue * .72 + i * .14) % 1.0;

      final opacity = .085 * math.sin(p * math.pi);

      if (opacity <= 0) {
        continue;
      }

      final width = 70 + p * 165;

      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(size.width / 2, contactY),
          width: width * 2,
          height: (2.5 + p * 8.5) * 2,
        ),
        math.pi * .08,
        math.pi * .84,
        false,
        Paint()
          ..color = Colors.white.withOpacity(opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .75 + (1 - p) * .75
          ..strokeCap = StrokeCap.round,
      );
    }

    for (int i = 0; i < 12; i++) {
      final p = i / 11;

      final x = 52 + p * (size.width - 104);

      final y = contactY - math.sin(p * math.pi) * 1.4;

      canvas.drawLine(
        Offset(x - 2, y),
        Offset(x + 2, y + math.sin(t * 2 + i) * .5),
        Paint()
          ..color = Colors.white.withOpacity(.09)
          ..strokeWidth = .75
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant BoatContactFrontPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.boatIndex != boatIndex;
  }
}

// ============================================================================
// WOODEN BOAT WIDGET — same oval hull shape as BoatTextField, with 3D depth
// ============================================================================

class WoodenBoat extends StatelessWidget {
  final double animationValue;

  const WoodenBoat({super.key, required this.animationValue});

  @override
  Widget build(BuildContext context) {
    final t = animationValue * math.pi * 2;

    // Gentle ocean swell bobbing
    final verticalMovement =
        math.sin(t * .72) * 6.5 +
        math.sin(t * 1.15 + 0.9) * 2.2 +
        math.sin(t * 2.18 + 2.1) * 0.8;

    final horizontalMovement =
        math.sin(t * .43 + 0.5) * 2.8 +
        math.sin(t * 1.17 + 1.8) * 0.9;

    // Gentle roll from wave action
    final verticalVelocity =
        math.cos(t * .72) * .72 * 6.5 +
        math.cos(t * 1.15 + 0.9) * 1.15 * 2.2;
    final rotation = verticalVelocity * .003 + math.sin(t * 1.9 + 1.0) * .005;

    return Transform.translate(
      offset: Offset(horizontalMovement, verticalMovement),
      child: Transform.rotate(
        angle: rotation,
        child: CustomPaint(
          // 240 wide — compact, same aspect ratio as original BoatTextField
          size: const Size(240, 108),
          painter: WoodenBoatPainter(animationValue),
        ),
      ),
    );
  }
}

// ============================================================================
// WOODEN BOAT PAINTER
// Same oval/pointed-bow hull shape as the original BoatTextField, but drawn
// with 3D wooden depth: bottom "hull side" layer + top "deck" layer.
// Width 240, Height 108 (same proportions as original, just scaled).
// ============================================================================

class WoodenBoatPainter extends CustomPainter {
  final double animationValue;

  WoodenBoatPainter(this.animationValue);

  // Builds the outer hull path for a given canvas size.
  // This exactly mirrors the original BoatTextField hull bezier shape.
  Path _hullPath(double w, double h) {
    return Path()
      ..moveTo(w * 0.075, h * 0.23)             // port bow top
      ..quadraticBezierTo(
        w * 0.033, h * 0.25,
        w * 0.050, h * 0.395,
      )                                          // port bow curve inward
      ..quadraticBezierTo(
        w * 0.088, h * 0.755,
        w * 0.237, h * 0.915,
      )                                          // port stern curve
      ..quadraticBezierTo(
        w * 0.5, h * 1.075,
        w * 0.763, h * 0.915,
      )                                          // stern bottom arc
      ..quadraticBezierTo(
        w * 0.912, h * 0.755,
        w * 0.950, h * 0.395,
      )                                          // starboard stern curve
      ..quadraticBezierTo(
        w * 0.967, h * 0.25,
        w * 0.925, h * 0.23,
      )                                          // starboard bow top
      ..quadraticBezierTo(
        w * 0.5, h * 0.167,
        w * 0.075, h * 0.23,
      )                                          // back to bow
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;   // 240
    final h = size.height;  // 108
    final t = animationValue * math.pi * 2;

    // The 3D effect: the hull body is drawn at FULL height (gives thickness/side),
    // then the top "deck" face is drawn inset upward, creating depth illusion.
    const double sideDepth = 10.0; // vertical thickness of the "hull side" in px

    // ── 1. DROP SHADOW ──
    canvas.drawPath(
      _hullPath(w, h).shift(const Offset(0, 4)),
      Paint()
        ..color = Colors.black.withOpacity(0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // ── 2. HULL SIDE (the visible brown wall / thickness) ──
    // We draw the full hull then clip it to show only the bottom edge band.
    canvas.save();
    canvas.drawPath(
      _hullPath(w, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Color(0xFF4A2409), // very dark — deep shadow inside hull
            Color(0xFF3A1A05),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    canvas.restore();

    // ── 3. TOP DECK FACE (shifted up by sideDepth, same hull shape) ──
    final deckPath = _hullPath(w, h - sideDepth).shift(Offset(0, -sideDepth * 0.4));

    canvas.drawPath(
      deckPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Color(0xFFD4924A), // warm teak highlight at bow
            Color(0xFFBF7B30), // mid mahogany
            Color(0xFF9A5E1E), // darker aft
            Color(0xFF7A3F10), // stern shadow
          ],
          stops: [0.0, 0.32, 0.65, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // ── 4. WOOD PLANK LINES on deck (longitudinal, bow to stern) ──
    // Clip to deck face so lines don't overdraw the hull side
    canvas.save();
    canvas.clipPath(deckPath);
    const int plankCount = 7;
    for (int i = 1; i < plankCount; i++) {
      final xFrac = i / plankCount.toDouble();
      final xLeft = w * xFrac * 0.80 + w * 0.10;  // narrows at bow
      final paint = Paint()
        ..color = (i.isOdd
            ? const Color(0xFF6B3610)
            : const Color(0xFFE0A050))
            .withOpacity(0.38)
        ..strokeWidth = 1.2;
      // Draw a gentle curve from bow end to stern end
      final path = Path()
        ..moveTo(xLeft, h * 0.20)
        ..quadraticBezierTo(xLeft, h * 0.55, xLeft + (xFrac - 0.5) * 20, h * 0.90);
      canvas.drawPath(path, paint..style = PaintingStyle.stroke);
    }
    canvas.restore();

    // ── 5. DECK OUTLINE ──
    canvas.drawPath(
      deckPath,
      Paint()
        ..color = const Color(0xFF2A1205)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // ── 6. GUNWALE RAIL — golden teak strip at top edge of deck ──
    canvas.drawPath(
      deckPath,
      Paint()
        ..color = const Color(0xFFE8B86D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0,
    );
    // Inner highlight on gunwale
    canvas.drawPath(
      deckPath,
      Paint()
        ..color = Colors.white.withOpacity(0.30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    // ── 7. HULL OUTLINE ──
    canvas.drawPath(
      _hullPath(w, h),
      Paint()
        ..color = const Color(0xFF1E0A02)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // ── 8. SUNLIGHT SPECULAR on deck top (animated shimmer) ──
    final shimmer = 0.5 + 0.5 * math.sin(t * 0.9);
    canvas.drawPath(
      deckPath,
      Paint()
        ..shader = LinearGradient(
          begin: const Alignment(-0.6, -1),
          end: const Alignment(0.6, 1),
          colors: [
            Colors.white.withOpacity(0.22 * shimmer),
            Colors.transparent,
            Colors.white.withOpacity(0.06 * shimmer),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // ── 9. WATER RIPPLE around hull base ──
    for (int i = 0; i < 3; i++) {
      final phase = (animationValue * 0.6 + i * 0.33) % 1.0;
      final expand = phase * 14.0;
      final opacity = (1 - phase) * 0.18;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.90),
          width: w * 0.65 + expand * 3,
          height: 10 + expand,
        ),
        const Radius.circular(40),
      );
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = Colors.white.withOpacity(opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WoodenBoatPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

// Keep BoatPainter for BoatSubmergedTintPainter shape reference
class BoatPainter extends CustomPainter {
  final double animationValue;
  final int boatIndex;

  BoatPainter(this.animationValue, this.boatIndex);

  @override
  void paint(Canvas canvas, Size size) {
    // No longer used for drawing — WoodenBoatPainter handles visual rendering.
    // Left here so BoatSubmergedTintPainter hull shape stays consistent.
  }

  @override
  bool shouldRepaint(covariant BoatPainter oldDelegate) => false;
}

// ============================================================================
// BOAT SUBMERGED TINT
// ============================================================================

class BoatSubmergedTintPainter extends CustomPainter {
  final double animationValue;
  final int boatIndex;

  BoatSubmergedTintPainter(this.animationValue, this.boatIndex);

  @override
  void paint(Canvas canvas, Size size) {
    final t = animationValue * math.pi * 2;

    final bob = math.sin(t * .72 + boatIndex * 1.65);

    final fastBob = math.sin(t * 1.43 + boatIndex * 2.4);

    final waterLineY = 99 + bob * 3.7 + fastBob * .5;

    final w = size.width;

    final hullShape = Path()
      ..moveTo(18, 25)
      ..quadraticBezierTo(8, 27, 12, 41)
      ..quadraticBezierTo(21, 79, 57, 99)
      ..quadraticBezierTo(w * .5, 116, w - 57, 99)
      ..quadraticBezierTo(w - 21, 79, w - 12, 41)
      ..quadraticBezierTo(w - 8, 27, w - 18, 25)
      ..quadraticBezierTo(w * .5, 18, 18, 25)
      ..close();

    final waterCover = Path()
      ..moveTo(0, waterLineY)
      ..lineTo(w, waterLineY)
      ..lineTo(w, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.save();

    canvas.clipPath(hullShape);

    canvas.drawPath(
      waterCover,
      Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xff1478B9).withOpacity(.28),
                const Color(0xff083E5E).withOpacity(.48),
              ],
            ).createShader(
              Rect.fromLTWH(0, waterLineY, w, size.height - waterLineY),
            ),
    );

    canvas.drawLine(
      Offset(20, waterLineY),
      Offset(w - 20, waterLineY),
      Paint()
        ..color = Colors.white.withOpacity(.16)
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant BoatSubmergedTintPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.boatIndex != boatIndex;
  }
}

// ============================================================================
// REALISTIC 3D CYLINDRICAL SOCIAL BUTTON
// ----------------------------------------------------------------------------
// Google / Apple floating buttons.
// Same visual language as the main Login platform:
// - elevated top-down perspective
// - elliptical/cylindrical top face
// - visible lower cylindrical rim
// - glossy highlight
// - soft floating shadow
// - slow natural bob + side drift + tiny rocking
// ============================================================================

class SocialButton extends StatelessWidget {
  final Widget child;
  final double animationValue;
  final double phase;

  const SocialButton({
    super.key,
    required this.child,
    required this.animationValue,
    this.phase = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    // Use the SAME continuous animation clock as the Login button.
    // This keeps both social buttons smooth and synchronized with the
    // main floating Login platform.
    final t = (animationValue + phase) * math.pi * 2;

    // Same gentle bobbing character as the Login button.
    final bob = math.sin(t * .82) * 5.6 + math.sin(t * 1.37 + .8) * 2.3;

    // Same subtle horizontal drift as the Login button.
    final drift = math.sin(t * .43 + 1.2) * 2.7;

    // Same top-view rocking/perspective as the Login button.
    final tiltX =
        -(math.pi * 52.5 / 180) + math.sin(t * .78 + .6) * (math.pi * 10 / 180);

    final tiltZ =
        math.sin(t * .72 + .35) * (math.pi * 4.6 / 180) +
        math.sin(t * 1.17 + 1.1) * (math.pi * 1.7 / 180);

    final shadowScale = 1.0 + math.sin(t * .82 + .35) * .07;

    return Transform.translate(
      offset: Offset(drift, bob),
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0028)
          ..rotateX(tiltX)
          ..rotateZ(tiltZ),
        child: SizedBox(
          // WIDTH/BREADTH UNCHANGED.
          width: 92,
          // Keep the same layout footprint; only the visible 3D depth
          // is reduced to match the Login button's ~11px depth.
          height: 78,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // ========================================================
              // FLOATING SHADOW
              // ========================================================
              Positioned(
                bottom: 1,
                left: 7,
                right: 7,
                child: Transform.scale(
                  scaleX: shadowScale,
                  scaleY: .72,
                  child: IgnorePointer(
                    child: Container(
                      height: 19,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        gradient: RadialGradient(
                          colors: [
                            Colors.black.withOpacity(.30),
                            Colors.black.withOpacity(.14),
                            Colors.transparent,
                          ],
                          stops: const [0.0, .52, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ========================================================
              // LOWER 3D BODY
              // 3D depth is ~15px for a slightly fuller, less-thin look.
              // ========================================================
              Positioned(
                left: 2,
                right: 2,
                top: 11,
                bottom: 4,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xff9CBCC8),
                        Color(0xff7596A3),
                        Color(0xff496B79),
                        Color(0xff294955),
                      ],
                      stops: [0.0, .28, .67, 1.0],
                    ),
                    border: Border.all(
                      color: const Color(0xffB8D8E3),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.30),
                        blurRadius: 9,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 9,
                        right: 9,
                        bottom: 3,
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(.30),
                                const Color(0xff587C89).withOpacity(.45),
                                Colors.black.withOpacity(.30),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 8,
                        right: 8,
                        top: 3,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.0),
                                Colors.white.withOpacity(.28),
                                Colors.white.withOpacity(0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ========================================================
              // ELEVATED TOP FACE
              // 3D depth ends at ~15px.
              // ========================================================
              Positioned(
                left: 1,
                right: 1,
                top: 0,
                bottom: 15,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xffD9F1FA),
                        Color(0xffF9FDFF),
                        Color(0xffE7F6FB),
                        Color(0xffC5E3EC),
                        Color(0xffA2CBD8),
                      ],
                      stops: [0.0, .22, .48, .78, 1.0],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(.92),
                      width: 1.45,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(.85),
                        blurRadius: 5,
                        spreadRadius: -1,
                        offset: const Offset(0, -2),
                      ),
                      BoxShadow(
                        color: const Color(0xff34758B).withOpacity(.38),
                        blurRadius: 6,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        left: 13,
                        right: 13,
                        top: 4,
                        child: Container(
                          height: 7,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.white.withOpacity(0.0),
                                Colors.white.withOpacity(.72),
                                Colors.white.withOpacity(.12),
                                Colors.white.withOpacity(0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        right: 10,
                        top: 7,
                        bottom: 7,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            gradient: RadialGradient(
                              center: const Alignment(-.30, -.52),
                              radius: .95,
                              colors: [
                                Colors.white.withOpacity(.43),
                                Colors.white.withOpacity(.10),
                                Colors.transparent,
                              ],
                              stops: const [0.0, .42, 1.0],
                            ),
                          ),
                        ),
                      ),
                      child,
                    ],
                  ),
                ),
              ),

              // ========================================================
              // FRONT RIM
              // ========================================================
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.white.withOpacity(0.0),
                        const Color(0xff5C95A6).withOpacity(.55),
                        Colors.white.withOpacity(.28),
                        const Color(0xff4B8293).withOpacity(.42),
                        Colors.white.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// REALISTIC OCEAN
// ============================================================================

class RealisticOceanPainter extends CustomPainter {
  final double t;

  RealisticOceanPainter(this.t);

  double noise(int n) {
    final v = math.sin(n * 12.9898 + 78.233) * 43758.5453;

    return v - v.floorToDouble();
  }

  double wave(double phase) {
    final s = math.sin(phase);

    return s + .18 * s * s * s;
  }

  double smoothNoise(double x, double y) {
    return math.sin(x * 1.7 + y * 2.3) * .45 +
        math.sin(x * 3.1 - y * 1.4) * .30 +
        math.sin(x * 6.2 + y * 4.8) * .17 +
        math.sin(x * 11.7 - y * 7.1) * .08;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final horizon = size.height * .48;

    _sky(canvas, size, horizon);

    _waterBase(canvas, size, horizon);

    _farWaves(canvas, size, horizon);

    _middleWaves(canvas, size, horizon);

    _deepWaves(canvas, size, horizon);

    _reflection(canvas, size, horizon);

    _highlights(canvas, size, horizon);

    _specularSparkle(canvas, size, horizon);

    _foreground(canvas, size);

    _vignette(canvas, size);
  }

  void _sky(Canvas canvas, Size size, double horizon) {
    final rect = Rect.fromLTWH(0, 0, size.width, horizon);

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xff426F84),
            Color(0xff719BA8),
            Color(0xffB5C4BC),
            Color(0xffE4D2AD),
          ],
          stops: [0, .42, .78, 1],
        ).createShader(rect),
    );

    final sun = Offset(size.width * .78, size.height * .19);

    canvas.drawCircle(
      sun,
      size.width * .32,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withOpacity(.45),
            Colors.white.withOpacity(.15),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: sun, radius: size.width * .32)),
    );

    canvas.drawCircle(sun, 16, Paint()..color = Colors.white.withOpacity(.75));
  }

  void _waterBase(Canvas canvas, Size size, double horizon) {
    final rect = Rect.fromLTWH(0, horizon, size.width, size.height - horizon);

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xff4A8E98),
            Color(0xff276F80),
            Color(0xff15536A),
            Color(0xff0A3C54),
            Color(0xff04263A),
            Color(0xff011622),
            Color(0xff000A12),
          ],
          stops: [0, .13, .30, .50, .70, .86, 1],
        ).createShader(rect),
    );

    for (int i = 0; i < 32; i++) {
      final d = noise(i * 13);

      final x = noise(i * 31) * size.width;

      final y = horizon + noise(i * 47) * (size.height - horizon);

      final radius = 70 + d * 260;

      final drift = math.sin(t * (.35 + d * .55) + i * 2.1) * (8 + d * 24);

      final center = Offset(x + drift, y);

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xff55A5A8).withOpacity(.045),
              const Color(0xff176E82).withOpacity(.018),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    for (int i = 0; i < 22; i++) {
      final d = noise(i * 53 + 7);

      final x = noise(i * 67 + 3) * size.width;

      final y = horizon + noise(i * 89 + 5) * (size.height - horizon);

      final radius = 22 + d * 60;

      final driftX = math.sin(t * (.9 + d * 1.4) + i * 3.3) * (14 + d * 30);

      final driftY = math.cos(t * (.6 + d * 1.1) + i * 2.1) * (6 + d * 12);

      final center = Offset(x + driftX, y + driftY);

      final pulse = math.sin(t * (1.3 + d) + i * 4.1) * .5 + .5;

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xff9FE3E0).withOpacity(.05 * pulse),
              const Color(0xff2E8F97).withOpacity(.02 * pulse),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }
  }

  void _farWaves(Canvas canvas, Size size, double horizon) {
    for (int row = 0; row < 45; row++) {
      final d = row / 44;

      final y = horizon + 4 + math.pow(d, 2.2).toDouble() * size.height * .30;

      final amp = .6 + d * 3.0;

      final path = Path()..moveTo(-40, y);

      for (double x = -40; x <= size.width + 40; x += 6) {
        final p1 = x * .031 + row * .74 + t * (1.5 + noise(row) * 2);

        final p2 = x * .071 - row * 1.1 - t;

        final irregular = smoothNoise(x * .025, row * .22 + t * .1);

        path.lineTo(
          x,
          y + wave(p1) * amp + math.sin(p2) * amp * .25 + irregular * amp * .12,
        );
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xffD8F1EB).withOpacity(.014 + d * .025)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .45 + d * .8
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, .9 - d * .6),
      );
    }
  }

  void _middleWaves(Canvas canvas, Size size, double horizon) {
    for (int row = 0; row < 30; row++) {
      final d = row / 29;

      final baseY =
          horizon +
          10 +
          math.pow(d, 1.15).toDouble() * (size.height - horizon) * .72;

      final amp = 2.2 + math.pow(d, 1.35).toDouble() * 26;

      final direction = noise(row * 91) > .5 ? 1.0 : -1.0;

      final speed = 2.2 + noise(row * 17) * 3.8;

      final path = Path()..moveTo(-100, baseY);

      for (double x = -100; x <= size.width + 100; x += 5) {
        final p1 = x * .010 + row * .73 + direction * t * speed;

        final p2 = x * .022 - row * .87 - t * 1.2;

        final p3 = x * .049 + row * 1.7 + direction * t * 3.5;

        final distortion =
            smoothNoise(x * .018, row * .48 - t * .15) * amp * .17;

        final vertical =
            math.sin(t * (.7 + noise(row) * 1.2) + row * 2.2) * amp * .12;

        path.lineTo(
          x,
          baseY +
              wave(p1) * amp +
              math.sin(p2) * amp * .27 +
              math.sin(p3) * amp * .08 +
              vertical +
              distortion,
        );
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = Color.lerp(
            const Color(0xffD2EEE8),
            const Color(0xff347F8C),
            d,
          )!.withOpacity(.025 + (1 - d) * .045)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .55 + d * 1.25,
      );
    }
  }

  void _deepWaves(Canvas canvas, Size size, double horizon) {
    const rows = 20;

    for (int row = 0; row < rows; row++) {
      final d = row / (rows - 1);

      final perspective = math.pow(d, 1.7).toDouble();

      final baseY = horizon + 25 + perspective * (size.height - horizon) * .90;

      final amp = 4 + perspective * 46;

      final thickness = 8 + perspective * 32;

      final direction = noise(row * 71) > .5 ? 1.0 : -1.0;

      final speed = 2.2 + noise(row * 31) * 4.2;

      final path = Path()..moveTo(-140, baseY);

      for (double x = -140; x <= size.width + 140; x += 4) {
        final p1 = x * (.012 - d * .004) + row * .83 + direction * t * speed;

        final p2 = x * .029 + row * 1.7 - t * 1.4;

        final p3 = x * .071 - row * 1.1 + direction * t * 3;

        final chaotic =
            smoothNoise(x * .025 + direction * t * .08, row * .55 - t * .12) *
            amp *
            .10;

        final y =
            baseY +
            wave(p1) * amp +
            math.sin(p2) * amp * .20 +
            math.sin(p3) * amp * .05 +
            math.sin(t * (.65 + noise(row * 19) * 1.5) + row * 2.31) *
                amp *
                .13 +
            smoothNoise(x * .019 + direction * t * .1, row * .40 + t * .13) *
                amp *
                .11 +
            chaotic;

        path.lineTo(x, y);
      }

      path
        ..lineTo(size.width + 140, baseY + amp + thickness)
        ..lineTo(-140, baseY + amp + thickness)
        ..close();

      final rect = Rect.fromLTWH(
        0,
        baseY - amp,
        size.width,
        amp * 2 + thickness,
      );

      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(
                const Color(0xffB5E1DC),
                const Color(0xff367F8A),
                d,
              )!.withOpacity(.10 + (1 - d) * .10),
              Color.lerp(
                const Color(0xff1D7485),
                const Color(0xff063C54),
                d,
              )!.withOpacity(.14 + d * .09),
              Color.lerp(
                const Color(0xff063E55),
                const Color(0xff000D18),
                d,
              )!.withOpacity(.15 + d * .15),
            ],
            stops: const [0, .46, 1],
          ).createShader(rect),
      );

      final crest = Path()..moveTo(-140, baseY);

      for (double x = -140; x <= size.width + 140; x += 5) {
        final p = x * (.012 - d * .004) + row * .83 + direction * t * speed;

        crest.lineTo(x, baseY + wave(p) * amp);
      }

      final crestShadow = Path()..moveTo(-140, baseY);

      for (double x = -140; x <= size.width + 140; x += 5) {
        final p = x * (.012 - d * .004) + row * .83 + direction * t * speed;

        crestShadow.lineTo(x, baseY + wave(p) * amp + (2 + perspective * 6));
      }

      canvas.drawPath(
        crestShadow,
        Paint()
          ..color = Colors.black.withOpacity(.05 + perspective * .06)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4 + perspective * 3.2
          ..strokeCap = StrokeCap.round
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1 + perspective),
      );

      canvas.drawPath(
        crest,
        Paint()
          ..color = Color.lerp(
            const Color(0xffEFFFFF),
            const Color(0xff438D97),
            d,
          )!.withOpacity(.055 + (1 - d) * .10)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .65 + d * 2.3
          ..strokeCap = StrokeCap.round,
      );

      if (d > .55) {
        final foamDensity = (d - .55) / .45;

        final dashCount = (foamDensity * 16).round();

        for (int f = 0; f < dashCount; f++) {
          final fx = noise(row * 211 + f * 13) * (size.width + 280) - 140;

          final p = fx * (.012 - d * .004) + row * .83 + direction * t * speed;

          final fy = baseY + wave(p) * amp;

          final flen = 2.5 + noise(f * 7 + row) * (2.5 + d * 5);

          canvas.drawLine(
            Offset(fx - flen, fy - 1),
            Offset(fx + flen, fy + math.sin(f * 1.7 + t * 3.4 + row) * 1.1),
            Paint()
              ..color = Colors.white.withOpacity(
                .09 * foamDensity + noise(f * 3 + row) * .05,
              )
              ..strokeWidth = .8 + d * 1.3
              ..strokeCap = StrokeCap.round,
          );
        }
      }
    }
  }

  void _reflection(Canvas canvas, Size size, double horizon) {
    final x0 = size.width * .78;

    for (int i = 0; i < 150; i++) {
      final p = i / 150;

      final y = horizon + 8 + math.pow(p, 1.38).toDouble() * size.height * .73;

      final spread = 3 + math.pow(p, 1.5).toDouble() * size.width * .15;

      final movement = math.sin(t * (1 + noise(i * 17) * 2.4) + i * 1.8);

      final x = x0 + movement * spread * .75;

      if (math.sin(i * 2.71 + t * 2.2) * .5 + noise(i * 71) < .5) {
        continue;
      }

      final length = 2 + noise(i * 29) * (7 + p * 15);

      canvas.drawLine(
        Offset(x - length, y),
        Offset(x + length, y + math.sin(i * .8 + t * 4.5) * (1 + p * 2)),
        Paint()
          ..color = Colors.white.withOpacity(.11 - p * .055)
          ..strokeWidth = .45 + p * 1.2
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, .55),
      );
    }
  }

  void _highlights(Canvas canvas, Size size, double horizon) {
    for (int i = 0; i < 210; i++) {
      final d = .20 + noise(i * 19) * .76;

      final y =
          horizon + math.pow(d, 1.48).toDouble() * (size.height - horizon);

      final x = noise(i * 61) * size.width;

      final movement = math.sin(t * (1 + noise(i * 17) * 3) + i * 1.43);

      final xx = x + movement * (4 + d * 20);

      final length = 4 + noise(i * 53) * (8 + d * 50);

      canvas.drawLine(
        Offset(xx - length, y),
        Offset(xx + length, y + math.sin(i + t * 4) * (1 + d * 2)),
        Paint()
          ..color = Color.lerp(
            const Color(0xffDDF7F2),
            const Color(0xff459EA8),
            d,
          )!.withOpacity(.014 + (1 - d) * .035)
          ..strokeWidth = .5 + d * 1.2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _specularSparkle(Canvas canvas, Size size, double horizon) {
    for (int i = 0; i < 65; i++) {
      final d = .12 + noise(i * 37) * .82;

      final y = horizon + math.pow(d, 1.5).toDouble() * (size.height - horizon);

      final x = noise(i * 83) * size.width;

      final flicker = math.sin(t * (2.2 + noise(i * 5) * 3.8) + i * 3.7);

      if (flicker < .58) {
        continue;
      }

      final strength = (flicker - .58) / .42;

      final glintSize = (1.2 + noise(i * 91) * 2.4) * (1 - d * .35);

      canvas.drawCircle(
        Offset(x, y),
        glintSize,
        Paint()
          ..color = Colors.white.withOpacity(strength * (.20 + (1 - d) * .32))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, .6),
      );

      if (strength > .7) {
        final streakLen = glintSize * (2.4 + noise(i * 61) * 2);

        final angle = noise(i * 29) * math.pi;

        canvas.drawLine(
          Offset(
            x - math.cos(angle) * streakLen,
            y - math.sin(angle) * streakLen * .3,
          ),
          Offset(
            x + math.cos(angle) * streakLen,
            y + math.sin(angle) * streakLen * .3,
          ),
          Paint()
            ..color = Colors.white.withOpacity(strength * .18 * (1 - d))
            ..strokeWidth = .6
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  void _foreground(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      0,
      size.height * .66,
      size.width,
      size.height * .34,
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Color(0x1500050D),
            Color(0x4500030A),
            Color(0xC0000208),
          ],
          stops: [0, .25, .58, 1],
        ).createShader(rect),
    );

    for (int i = 0; i < 8; i++) {
      final d = i / 7;

      final base = size.height * .70 + d * size.height * .29;

      final amp = 14 + d * 40;

      final direction = noise(i * 121) > .5 ? 1.0 : -1.0;

      final speed = 1.5 + noise(i * 41) * 2.8;

      final path = Path()..moveTo(-220, base);

      for (double x = -220; x <= size.width + 220; x += 6) {
        final p1 = x * .006 + i * 1.8 + direction * t * speed;

        final p2 = x * .017 - t * 1.5 + i;

        path.lineTo(x, base + wave(p1) * amp + math.sin(p2) * amp * .22);
      }

      path
        ..lineTo(size.width + 220, size.height)
        ..lineTo(-220, size.height)
        ..close();

      canvas.drawPath(
        path,
        Paint()
          ..color = Color.lerp(
            const Color(0xff075169),
            const Color(0xff000914),
            d,
          )!.withOpacity(.11 + d * .22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
      );
    }
  }

  void _vignette(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: .85,
          colors: [Colors.transparent, Colors.black.withOpacity(.20)],
          stops: const [.58, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant RealisticOceanPainter oldDelegate) {
    return oldDelegate.t != t;
  }
}

// ============================================================================
// TEMPORARY OTP SCREEN
// ----------------------------------------------------------------------------
// This is only a placeholder for navigation testing. Replace this screen's
// UI later with the actual OTP design.
// ============================================================================
class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xff000208),
      body: Center(
        child: Text(
          'OTP Screen',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
