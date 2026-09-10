import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'permission_screen.dart';

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
// High-performance continuous animation architecture:
// Driven by a single master Ticker via ValueNotifier so that the UI widget tree
// (Logo, Title, Tagline, Scaffold) is built ONCE without unnecessary rebuilds,
// while the ocean and floating button repaint at a silky smooth 60/120 FPS.
// ============================================================================

class _GetStartedScreenState extends State<GetStartedScreen>
    with TickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _clock = ValueNotifier<double>(0.0);

  bool _loginPressed = false;

  // Login button press & spring release animation
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

  void _validateLogin() {
    // Navigate to Permission Screen right after Get Started
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PermissionScreen()),
    );
  }

  @override
  void initState() {
    super.initState();
    // Continuous time accumulator that never snaps or loops abruptly
    _ticker = createTicker((elapsed) {
      _clock.value = elapsed.inMicroseconds / 1000000.0;
    })..start();

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
    _clock.dispose();
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final sw = media.size.width;
    final sh = media.size.height;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xff000208),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ============================================================
          // CONTINUOUS OCEAN BACKGROUND — repaints via CustomPainter repaint listener
          // ============================================================
          CustomPaint(
            painter: RealisticOceanPainter(_clock),
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

                final double scaleW = (w / 390.0).clamp(0.65, 1.45);
                final double scaleH = (h / 844.0).clamp(0.65, 1.35);
                final double textScale = (w / 390.0).clamp(0.70, 1.35);

                final double logoSize = (46.0 * scaleW).clamp(32.0, 64.0);
                final double titleFontSize = (24.0 * textScale).clamp(17.0, 32.0);
                final double qFontSize = (27.0 * textScale).clamp(19.0, 36.0);
                final double taglineFontSize = (11.0 * textScale).clamp(8.5, 14.5);

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
                              color: const Color(0xFF013973),
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1.5),
                                ),
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                          TextSpan(
                            text: 'Q',
                            style: TextStyle(
                              color: const Color(0xFF00FF00),
                              fontSize: qFontSize,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(
                                  color: const Color(0xFF00FF00).withValues(alpha: 0.6),
                                  blurRadius: 8,
                                  offset: const Offset(0, 0),
                                ),
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1.5),
                                ),
                              ],
                            ),
                          ),
                          TextSpan(
                            text: 'Shield',
                            style: TextStyle(
                              color: const Color(0xFF013973),
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1.5),
                                ),
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.12),
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

                    // ── TAGLINE ──
                    Text(
                      'SAFER ROUTES. STRONGER COMMUNITIES.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF013973),
                        fontSize: taglineFontSize,
                        fontWeight: FontWeight.w800,
                        letterSpacing: (0.9 * textScale).clamp(0.4, 1.5),
                        shadows: [
                          Shadow(
                            color: Colors.white.withValues(alpha: 0.9),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // ── SMOOTH CONTINUOUS FLOATING GET STARTED BUTTON ──
                    AnimatedBuilder(
                      animation: Listenable.merge([_clock, _pressAnimation]),
                      builder: (context, child) {
                        final double elapsed = _clock.value;

                        // Fluid continuous floating harmonic motion (~2.8s cadence)
                        // Uses phased sine waves that never zero out or cancel each other
                        final double t = elapsed * 2.24;
                        final double floatY = math.sin(t) * 5.4 + math.sin(t * 0.5 + 0.6) * 1.8;
                        final double floatX = math.cos(t * 0.65 + 0.8) * 2.4;

                        // Realistic organic 3D rocking
                        final double tiltX = -(math.pi * 52.5 / 180) +
                            math.sin(t * 0.85 + 0.6) * (math.pi * 7.5 / 180);
                        final double tiltZ = math.sin(t * 0.75 + 0.35) * (math.pi * 3.4 / 180);
                        final double rockBias = math.sin(tiltZ) * 4.6;

                        final double pressT = _pressAnimation.value;
                        final double pressSink = pressT * 3.0;

                        // Smooth continuous ripple expansion (~2.6s expansion cadence)
                        final double rippleClock = elapsed * 0.38;

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
                                    painter: LoginWaterReflectionPainter(rippleClock),
                                  ),
                                ),
                                // Smooth continuous ripple rings
                                Positioned(
                                  top: -26,
                                  child: CustomPaint(
                                    size: Size(btnW * 1.45, 92),
                                    painter: LoginWaterRipplePainter(rippleClock, rockBias),
                                  ),
                                ),
                                // 3D floating button platform
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
                                          color: const Color(0xff063F52).withValues(alpha: .50),
                                          blurRadius: 16,
                                          spreadRadius: -2,
                                          offset: const Offset(0, 16),
                                        ),
                                        BoxShadow(
                                          color: const Color(0xff54C9F4).withValues(alpha: .25),
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
                                          left: 1,
                                          right: 1,
                                          top: 7,
                                          bottom: 0,
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
                                          left: 0,
                                          right: 0,
                                          top: 0,
                                          bottom: 7,
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
                                                    color: Colors.white.withValues(alpha: .75 * (1 - pressT * .6)),
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
                                          left: 10,
                                          right: 10,
                                          bottom: 4,
                                          child: IgnorePointer(
                                            child: CustomPaint(
                                              size: Size(btnW - 20, 6),
                                              painter: LoginWaterlinePainter(rippleClock),
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
                                      painter: LoginContactFoamPainter(rippleClock, rockBias),
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
            const Color(0xff9FE9E5).withValues(alpha: .22),
            const Color(0xff63C6CC).withValues(alpha: .12),
            const Color(0xff247B8A).withValues(alpha: .04),
            Colors.transparent,
          ],
          stops: const [0, .35, .68, 1],
        ).createShader(reflectionRect),
    );

    for (int i = 0; i < 12; i++) {
      final p = i / 11;
      final y = center.dy - (size.height * 0.28) + p * (size.height * 0.56);
      final width = (size.width * 0.25) + math.sin(p * math.pi) * (size.width * 0.45);
      final drift = math.sin(t * 1.4 + i * .75) * (2 + p * 4);
      final opacity = (.045 + math.sin(t * 1.8 + i) * .018).clamp(.015, .08).toDouble();

      canvas.drawLine(
        Offset(center.dx - width / 2 + drift, y),
        Offset(center.dx + width / 2 + drift, y + math.sin(t * 2 + i) * 1.3),
        Paint()
          ..color = Colors.white.withValues(alpha: opacity)
          ..strokeWidth = .7 + p * .7
          ..strokeCap = StrokeCap.round,
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
// ============================================================================

class LoginWaterRipplePainter extends CustomPainter {
  final double animationValue;
  final double rockBias;

  LoginWaterRipplePainter(this.animationValue, this.rockBias);

  static const double _aspect = .235;
  static const int _ringCount = 5;
  static const int _segmentsPerRing = 16;

  double _hash(double x) {
    final v = math.sin(x * 12.9898 + 78.233) * 43758.5453;
    return v - v.floorToDouble();
  }

  double _hashSigned(double x) => _hash(x) * 2 - 1;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animationValue * math.pi * 2;
    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < _ringCount; i++) {
      final spawnJitter = _hash(i * 7.13) * .16;
      // Smooth continuous outward ripple progression
      final phase = (animationValue + i / _ringCount + spawnJitter) % 1.0;

      final p = Curves.easeOut.transform(phase);
      final fade = math.sin(phase * math.pi);
      final ringStrength = .55 + _hash(i * 3.31 + 2) * .8;

      final baseOpacity = (.22 * fade * ringStrength * (1 - p * .25))
          .clamp(0.0, .28)
          .toDouble();

      if (baseOpacity < .006) continue;

      final rx = (size.width * 0.12) + p * (size.width * 0.44);
      final ry = rx * _aspect;
      final baseStrokeWidth = 1.45 + (1 - p) * 1.2;

      for (int seg = 0; seg < _segmentsPerRing; seg++) {
        final a0 = (seg / _segmentsPerRing) * math.pi * 2;
        final a1 = ((seg + 1) / _segmentsPerRing) * math.pi * 2;

        final segSeed = i * 91.7 + seg * 13.37;
        final segNoise = _hash(segSeed);
        final drift = math.sin(t * .5 + i * 1.4 + seg * .8) * .5 + .5;

        final midAngle = (a0 + a1) / 2;
        final leanDot = math.cos(midAngle);
        final leanBoost = 1 + (leanDot * rockBias / 6) * .45;

        var segStrength = (segNoise * .6 + drift * .4) * leanBoost;
        segStrength = segStrength.clamp(0.0, 1.4);

        if (segStrength < .28) continue;

        final opacity = (baseOpacity * segStrength).clamp(0.0, .32).toDouble();
        final strokeWidth = (baseStrokeWidth * (.5 + segStrength * .8))
            .clamp(.9, 3.8)
            .toDouble();

        final path = Path();
        const steps = 5;

        for (int k = 0; k <= steps; k++) {
          final a = a0 + (a1 - a0) * (k / steps);
          final distortion = 1 +
              math.sin(a * 2.7 + t * 1.2 + i * 1.7) * .055 +
              math.sin(a * 5.3 - t * .8 + i) * .028 +
              _hashSigned(segSeed + k) * .035;

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
            ..color = Colors.white.withValues(alpha: opacity)
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
// WATERLINE SHIMMER
// ============================================================================

class LoginWaterlinePainter extends CustomPainter {
  final double animationValue;

  LoginWaterlinePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final t = animationValue * math.pi * 2;
    final path = Path();

    for (int i = 0; i <= 60; i++) {
      final p = i / 60;
      final x = p * size.width;
      final y = size.height / 2 +
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
        ..color = const Color(0xffE9FFFF).withValues(alpha: .38)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.05
        ..strokeCap = StrokeCap.round,
    );

    final lowerPath = Path();
    for (int i = 0; i <= 60; i++) {
      final p = i / 60;
      final x = p * size.width;
      final y = size.height / 2 + 2.0 + math.sin(p * math.pi * 4 + t * 1.3) * .8;

      if (i == 0) {
        lowerPath.moveTo(x, y);
      } else {
        lowerPath.lineTo(x, y);
      }
    }

    canvas.drawPath(
      lowerPath,
      Paint()
        ..color = const Color(0xff4FC5D9).withValues(alpha: .22)
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

    // Matches the button's smooth harmonic bobbing
    final floatBob = math.sin(t) * 5.4 + math.sin(t * 0.5 + 0.6) * 1.8;
    final bobVelocity = math.cos(t) * 5.4 + math.cos(t * 0.5 + 0.6) * 0.9;
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
            const Color(0xff0A7180).withValues(alpha: .24),
            const Color(0xff4DBBC6).withValues(alpha: .12),
            Colors.transparent,
          ],
          stops: const [0, .48, 1],
        ).createShader(pressureRect),
    );

    // ------------------------------------------------------------
    // OVERLAPPING FRONT WATER WAVES
    // ------------------------------------------------------------
    for (int wave = 0; wave < 3; wave++) {
      final phase = t * (1.05 + wave * .12) + wave * 1.7;
      final path = Path();

      for (int i = 0; i <= 60; i++) {
        final p = i / 60;
        final x = 22 + p * (size.width - 44);
        final envelope = math.sin(p * math.pi);
        final largeWave =
            math.sin(p * math.pi * (3.0 + wave * .7) + phase) * (1.1 + wave * .45);
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
          ..color = Colors.white.withValues(alpha: .048 + (2 - wave) * .028)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .65 + (2 - wave) * .20
          ..strokeCap = StrokeCap.round,
      );
    }

    // ------------------------------------------------------------
    // LEFT + RIGHT WAVES TRAVELLING INTO THE BUTTON
    // ------------------------------------------------------------
    const buttonHalf = 130.0;
    for (final side in [-1.0, 1.0]) {
      for (int wave = 0; wave < 3; wave++) {
        final raw = (animationValue * 1.18 + wave * .19 + (side > 0 ? .47 : 0.0)) % 1.0;
        final approach = Curves.easeInOut.transform(raw);
        final startDistance = 175.0 + wave * 8.0;
        final contactDistance = buttonHalf - 3.0;
        final distance = startDistance + (contactDistance - startDistance) * approach;

        final x = cx + side * distance;
        final impact = math.sin(approach * math.pi);
        final waveHeight = 1.2 + impact * 4.5 + downwardImpact * 2.0;

        final path = Path();
        const spread = 34.0;

        for (int i = -8; i <= 8; i++) {
          final p = i / 8;
          final localX = x + p * spread;
          final envelope = math.exp(-p * p * 2.2);
          final ripple =
              math.sin(p * math.pi * 2.7 + t * 2.2 + wave * 1.5) * (.45 + impact * .9);
          final y = waterY - waveHeight * envelope + ripple;

          if (i == -8) {
            path.moveTo(localX, y);
          } else {
            path.lineTo(localX, y);
          }
        }

        final opacity = (.025 + impact * .11) * (1 - raw * .35);

        canvas.drawPath(
          path,
          Paint()
            ..color = Colors.white.withValues(alpha: opacity.clamp(0.0, .16).toDouble())
            ..style = PaintingStyle.stroke
            ..strokeWidth = .65 + impact * .75
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    // ------------------------------------------------------------
    // FOAM / AIR PARTICLES AROUND THE IMPACT ZONE
    // ------------------------------------------------------------
    const particleCount = 28;
    for (int i = 0; i < particleCount; i++) {
      final seed = i * 17.31;
      final angle = (i / particleCount) * math.pi * 2 + (_hash(seed) - .5) * .20;
      final radius = 118 + _hash(seed + 3) * 36;
      final bob = math.sin(
        t * (1.0 + _hash(seed + 6) * .8) + _hash(seed + 9) * math.pi * 2,
      );

      final x = cx + math.cos(angle) * radius + bob * 1.2;
      final y = waterY + math.sin(angle) * radius * .12 + bob * .8;
      final proximity = (1 - ((radius - 118) / 36)).clamp(0.0, 1.0).toDouble();
      final opacity = (.020 + _hash(seed + 11) * .05) * proximity;

      canvas.drawCircle(
        Offset(x, y),
        .35 + _hash(seed + 14) * .8,
        Paint()
          ..color = Colors.white.withValues(alpha: opacity.clamp(0.0, .08).toDouble()),
      );
    }
  }

  @override
  bool shouldRepaint(covariant LoginContactFoamPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.rockBias != rockBias;
  }
}

// ============================================================================
// REALISTIC OCEAN — CONTINUOUS, HIGH-PERFORMANCE FLUID MOTION
// ============================================================================

class RealisticOceanPainter extends CustomPainter {
  final ValueNotifier<double> clock;

  RealisticOceanPainter(this.clock) : super(repaint: clock);

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
    // Flowing water clock: smooth continuous progression (~9s full wave period)
    final t = clock.value * 0.12;
    final horizon = size.height * .48;

    _sky(canvas, size, horizon);
    _waterBase(canvas, size, horizon, t);
    _farWaves(canvas, size, horizon, t);
    _middleWaves(canvas, size, horizon, t);
    _deepWaves(canvas, size, horizon, t);
    _reflection(canvas, size, horizon, t);
    _highlights(canvas, size, horizon, t);
    _specularSparkle(canvas, size, horizon, t);
    _foreground(canvas, size, t);
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
            Colors.white.withValues(alpha: .45),
            Colors.white.withValues(alpha: .15),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: sun, radius: size.width * .32)),
    );

    canvas.drawCircle(
      sun,
      16,
      Paint()..color = Colors.white.withValues(alpha: .75),
    );
  }

  void _waterBase(Canvas canvas, Size size, double horizon, double t) {
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

    // Ambient ocean illumination spots
    for (int i = 0; i < 14; i++) {
      final d = noise(i * 13);
      final x = noise(i * 31) * size.width;
      final y = horizon + noise(i * 47) * (size.height - horizon);
      final radius = 70 + d * 220;
      final drift = math.sin(t * (.35 + d * .55) + i * 2.1) * (8 + d * 20);
      final center = Offset(x + drift, y);

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xff55A5A8).withValues(alpha: .045),
              const Color(0xff176E82).withValues(alpha: .018),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }
  }

  void _farWaves(Canvas canvas, Size size, double horizon, double t) {
    for (int row = 0; row < 22; row++) {
      final d = row / 21;
      final y = horizon + 4 + math.pow(d, 2.2).toDouble() * size.height * .30;
      final amp = .6 + d * 3.0;

      final path = Path()..moveTo(-30, y);

      for (double x = -30; x <= size.width + 30; x += 10) {
        final p1 = x * .031 + row * .74 + t * (1.8 + noise(row) * 2.2);
        final p2 = x * .071 - row * 1.1 - t * 1.2;
        final irregular = smoothNoise(x * .025, row * .22 + t * .15);

        path.lineTo(
          x,
          y + wave(p1) * amp + math.sin(p2) * amp * .25 + irregular * amp * .12,
        );
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xffD8F1EB).withValues(alpha: .018 + d * .028)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .5 + d * .8,
      );
    }
  }

  void _middleWaves(Canvas canvas, Size size, double horizon, double t) {
    for (int row = 0; row < 16; row++) {
      final d = row / 15;
      final baseY = horizon + 10 + math.pow(d, 1.15).toDouble() * (size.height - horizon) * .72;
      final amp = 2.2 + math.pow(d, 1.35).toDouble() * 24;
      final direction = noise(row * 91) > .5 ? 1.0 : -1.0;
      final speed = 2.4 + noise(row * 17) * 3.4;

      final path = Path()..moveTo(-60, baseY);

      for (double x = -60; x <= size.width + 60; x += 8) {
        final p1 = x * .010 + row * .73 + direction * t * speed;
        final p2 = x * .022 - row * .87 - t * 1.4;
        final p3 = x * .049 + row * 1.7 + direction * t * 3.2;
        final distortion = smoothNoise(x * .018, row * .48 - t * .15) * amp * .16;
        final vertical = math.sin(t * (.7 + noise(row) * 1.2) + row * 2.2) * amp * .12;

        path.lineTo(
          x,
          baseY + wave(p1) * amp + math.sin(p2) * amp * .27 + math.sin(p3) * amp * .08 + vertical + distortion,
        );
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = Color.lerp(
            const Color(0xffD2EEE8),
            const Color(0xff347F8C),
            d,
          )!.withValues(alpha: .03 + (1 - d) * .05)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .6 + d * 1.3,
      );
    }
  }

  void _deepWaves(Canvas canvas, Size size, double horizon, double t) {
    const rows = 12;

    for (int row = 0; row < rows; row++) {
      final d = row / (rows - 1);
      final perspective = math.pow(d, 1.7).toDouble();
      final baseY = horizon + 25 + perspective * (size.height - horizon) * .90;
      final amp = 4 + perspective * 44;
      final thickness = 8 + perspective * 30;
      final direction = noise(row * 71) > .5 ? 1.0 : -1.0;
      final speed = 2.4 + noise(row * 31) * 3.8;

      final path = Path()..moveTo(-100, baseY);

      for (double x = -100; x <= size.width + 100; x += 7) {
        final p1 = x * (.012 - d * .004) + row * .83 + direction * t * speed;
        final p2 = x * .029 + row * 1.7 - t * 1.5;
        final p3 = x * .071 - row * 1.1 + direction * t * 2.8;
        final chaotic = smoothNoise(x * .025 + direction * t * .08, row * .55 - t * .12) * amp * .10;

        final y = baseY +
            wave(p1) * amp +
            math.sin(p2) * amp * .20 +
            math.sin(p3) * amp * .05 +
            math.sin(t * (.65 + noise(row * 19) * 1.5) + row * 2.31) * amp * .13 +
            chaotic;

        path.lineTo(x, y);
      }

      path
        ..lineTo(size.width + 100, baseY + amp + thickness)
        ..lineTo(-100, baseY + amp + thickness)
        ..close();

      final rect = Rect.fromLTWH(0, baseY - amp, size.width, amp * 2 + thickness);

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
              )!.withValues(alpha: .10 + (1 - d) * .10),
              Color.lerp(
                const Color(0xff1D7485),
                const Color(0xff063C54),
                d,
              )!.withValues(alpha: .14 + d * .09),
              Color.lerp(
                const Color(0xff063E55),
                const Color(0xff000D18),
                d,
              )!.withValues(alpha: .15 + d * .15),
            ],
            stops: const [0, .46, 1],
          ).createShader(rect),
      );

      // Crest highlight
      final crest = Path()..moveTo(-100, baseY);
      for (double x = -100; x <= size.width + 100; x += 8) {
        final p = x * (.012 - d * .004) + row * .83 + direction * t * speed;
        crest.lineTo(x, baseY + wave(p) * amp);
      }

      canvas.drawPath(
        crest,
        Paint()
          ..color = Color.lerp(
            const Color(0xffEFFFFF),
            const Color(0xff438D97),
            d,
          )!.withValues(alpha: .06 + (1 - d) * .12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .7 + d * 2.2
          ..strokeCap = StrokeCap.round,
      );

      // Dynamic surface foam
      if (d > .55) {
        final foamDensity = (d - .55) / .45;
        final dashCount = (foamDensity * 12).round();

        for (int f = 0; f < dashCount; f++) {
          final fx = noise(row * 211 + f * 13) * (size.width + 200) - 100;
          final p = fx * (.012 - d * .004) + row * .83 + direction * t * speed;
          final fy = baseY + wave(p) * amp;
          final flen = 2.5 + noise(f * 7 + row) * (2.5 + d * 5);

          canvas.drawLine(
            Offset(fx - flen, fy - 1),
            Offset(fx + flen, fy + math.sin(f * 1.7 + t * 3.4 + row) * 1.1),
            Paint()
              ..color = Colors.white.withValues(
                alpha: .10 * foamDensity + noise(f * 3 + row) * .05,
              )
              ..strokeWidth = .8 + d * 1.3
              ..strokeCap = StrokeCap.round,
          );
        }
      }
    }
  }

  void _reflection(Canvas canvas, Size size, double horizon, double t) {
    final x0 = size.width * .78;

    for (int i = 0; i < 48; i++) {
      final p = i / 47;
      final y = horizon + 8 + math.pow(p, 1.38).toDouble() * size.height * .73;
      final spread = 3 + math.pow(p, 1.5).toDouble() * size.width * .15;
      final movement = math.sin(t * (1.2 + noise(i * 17) * 2.4) + i * 1.8);
      final x = x0 + movement * spread * .75;

      if (math.sin(i * 2.71 + t * 2.2) * .5 + noise(i * 71) < .45) {
        continue;
      }

      final length = 2 + noise(i * 29) * (7 + p * 15);

      canvas.drawLine(
        Offset(x - length, y),
        Offset(x + length, y + math.sin(i * .8 + t * 4.5) * (1 + p * 2)),
        Paint()
          ..color = Colors.white.withValues(alpha: .13 - p * .055)
          ..strokeWidth = .5 + p * 1.2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _highlights(Canvas canvas, Size size, double horizon, double t) {
    for (int i = 0; i < 64; i++) {
      final d = .20 + noise(i * 19) * .76;
      final y = horizon + math.pow(d, 1.48).toDouble() * (size.height - horizon);
      final x = noise(i * 61) * size.width;
      final movement = math.sin(t * (1.2 + noise(i * 17) * 3) + i * 1.43);
      final xx = x + movement * (4 + d * 20);
      final length = 4 + noise(i * 53) * (8 + d * 45);

      canvas.drawLine(
        Offset(xx - length, y),
        Offset(xx + length, y + math.sin(i + t * 4) * (1 + d * 2)),
        Paint()
          ..color = Color.lerp(
            const Color(0xffDDF7F2),
            const Color(0xff459EA8),
            d,
          )!.withValues(alpha: .018 + (1 - d) * .04)
          ..strokeWidth = .5 + d * 1.2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _specularSparkle(Canvas canvas, Size size, double horizon, double t) {
    for (int i = 0; i < 28; i++) {
      final d = .12 + noise(i * 37) * .82;
      final y = horizon + math.pow(d, 1.5).toDouble() * (size.height - horizon);
      final x = noise(i * 83) * size.width;
      final flicker = math.sin(t * (2.4 + noise(i * 5) * 3.8) + i * 3.7);

      if (flicker < .55) continue;

      final strength = (flicker - .55) / .45;
      final glintSize = (1.2 + noise(i * 91) * 2.4) * (1 - d * .35);

      canvas.drawCircle(
        Offset(x, y),
        glintSize,
        Paint()
          ..color = Colors.white.withValues(alpha: strength * (.22 + (1 - d) * .35)),
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
            ..color = Colors.white.withValues(alpha: strength * .20 * (1 - d))
            ..strokeWidth = .7
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  void _foreground(Canvas canvas, Size size, double t) {
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

    for (int i = 0; i < 6; i++) {
      final d = i / 5;
      final base = size.height * .70 + d * size.height * .29;
      final amp = 14 + d * 38;
      final direction = noise(i * 121) > .5 ? 1.0 : -1.0;
      final speed = 1.6 + noise(i * 41) * 2.8;

      final path = Path()..moveTo(-150, base);

      for (double x = -150; x <= size.width + 150; x += 10) {
        final p1 = x * .006 + i * 1.8 + direction * t * speed;
        final p2 = x * .017 - t * 1.5 + i;
        path.lineTo(x, base + wave(p1) * amp + math.sin(p2) * amp * .22);
      }

      path
        ..lineTo(size.width + 150, size.height)
        ..lineTo(-150, size.height)
        ..close();

      canvas.drawPath(
        path,
        Paint()
          ..color = Color.lerp(
            const Color(0xff075169),
            const Color(0xff000914),
            d,
          )!.withValues(alpha: .12 + d * .24),
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
          colors: [Colors.transparent, Colors.black.withValues(alpha: .20)],
          stops: const [.58, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant RealisticOceanPainter oldDelegate) => false;
}
