import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

void main() {
  runApp(const WaterWavesApp());
}

// ================================================================
// APP
// ================================================================

class WaterWavesApp extends StatelessWidget {
  const WaterWavesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WaterWavesScreen(),
    );
  }
}

// ================================================================
// SCREEN
// ================================================================

class WaterWavesScreen extends StatefulWidget {
  const WaterWavesScreen({super.key});

  @override
  State<WaterWavesScreen> createState() => _WaterWavesScreenState();
}

class _WaterWavesScreenState extends State<WaterWavesScreen>
    with TickerProviderStateMixin {
  late final AnimationController waterController;
  late final AnimationController platformController;
  late final Ticker loginFloatTicker;
  late final AnimationController loginPressController;

  final ValueNotifier<double> loginElapsedNotifier = ValueNotifier<double>(0.0);

  int loginRippleKey = 0;

  final List<TextEditingController> otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> otpFocusNodes = List.generate(6, (_) => FocusNode());

  @override
  void initState() {
    super.initState();

    waterController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 28),
    )..repeat();

    platformController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat();

    loginPressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      reverseDuration: const Duration(milliseconds: 240),
    );

    loginFloatTicker = createTicker((elapsed) {
      if (!mounted) return;
      loginElapsedNotifier.value = elapsed.inMicroseconds / 1000000.0;
    });
    loginFloatTicker.start();
  }

  @override
  void dispose() {
    waterController.dispose();
    platformController.dispose();
    loginPressController.dispose();
    loginFloatTicker.dispose();
    loginElapsedNotifier.dispose();
    for (final c in otpControllers) {
      c.dispose();
    }
    for (final f in otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final media = MediaQuery.of(context);

          final maxCy = math.max(200.0, h * 0.70);
          final minCy = math.min(260.0, maxCy);
          final baseCy = (h * 0.637).clamp(minCy, maxCy);

          final boxWidth = (w * 0.082).clamp(28.0, 36.0);
          final boxHeight = boxWidth * 1.18;
          final boxGap = (w * 0.02).clamp(6.0, 11.0);
          const boxCount = 6;
          final totalWidth = boxWidth * boxCount + boxGap * (boxCount - 1);
          final startX = cx - totalWidth / 2;
          final startY = baseCy - 30;

          final minBtnTop = baseCy + 35.0;
          final maxBtnTop = math.max(minBtnTop, h * 0.85);
          final buttonTop = (h * 0.705).clamp(minBtnTop, maxBtnTop);

          return Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(
                child: CustomPaint(
                  painter: RealisticOceanPainter(
                    waterController,
                    platformController,
                  ),
                ),
              ),

              AnimatedBuilder(
                animation: Listenable.merge([
                  waterController,
                  platformController,
                ]),
                builder: (_, _) {
                  final phase = waterController.value * math.pi * 2.0;
                  final microPhase =
                      0.5 +
                      0.5 *
                          math.sin(
                            platformController.value * math.pi * 2.0 + 0.42,
                          );

                  final floatY =
                      math.sin(phase) * h * 0.018 +
                      math.sin(phase * 2.0 + 0.9) * h * 0.007 +
                      (microPhase - 0.5) * h * 0.0035;

                  final floatX =
                      math.sin(phase + 1.2) * w * 0.007 +
                      math.sin(phase * 2.0 + 0.4) * w * 0.003 +
                      (microPhase - 0.5) * w * 0.0016;

                  final tiltX =
                      math.sin(phase + 0.6) * (math.pi * 9.0 / 180) +
                      math.sin(phase * 2.0 + 1.4) * (math.pi * 2.0 / 180) +
                      (microPhase - 0.5) * (math.pi * 0.7 / 180);

                  final tiltZ =
                      math.sin(phase + 0.35) * (math.pi * 4.8 / 180) +
                      math.sin(phase * 2.0 + 1.1) * (math.pi * 1.8 / 180) +
                      math.sin(phase * 3.0 + 0.7) * (math.pi * 0.7 / 180) +
                      (microPhase - 0.5) * (math.pi * 0.4 / 180);

                  final perspectiveY = (1.0 - math.sin(tiltX).abs() * 0.16)
                      .clamp(0.84, 1.0)
                      .toDouble();
                  final perspectiveX = (1.0 + math.sin(tiltX) * 0.055)
                      .clamp(0.94, 1.06)
                      .toDouble();
                  final shearX = math.sin(tiltX) * 0.045;

                  final cy = baseCy + floatY - h * 0.015;

                  final matrix = Matrix4.identity()
                    ..translate(cx + floatX, cy)
                    ..rotateZ(tiltZ)
                    ..scale(perspectiveX, perspectiveY)
                    ..setEntry(0, 1, math.tan(shearX))
                    ..translate(-cx, -cy);

                  return Transform(
                    alignment: Alignment.topLeft,
                    transform: matrix,
                    child: Stack(
                      children: [
                        for (int i = 0; i < boxCount; i++)
                          Positioned(
                            left:
                                startX +
                                i * (boxWidth + boxGap) +
                                _otpStoneOffset(i).dx,
                            top: startY + _otpStoneOffset(i).dy,
                            width: boxWidth,
                            height: boxHeight,
                            child: _otpField(i),
                          ),
                      ],
                    ),
                  );
                },
              ),

              Positioned(
                left: 0,
                right: 0,
                top: buttonTop,
                height: 150,
                child: Center(
                  child: RepaintBoundary(
                    child: LoginWaterButton(
                      clock: loginElapsedNotifier,
                      pressController: loginPressController,
                      rippleKey: loginRippleKey,
                      onTapDown: () {
                        loginPressController.forward();
                      },
                      onTapUp: () {
                        loginPressController.reverse();
                        setState(() {
                          loginRippleKey++;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Same subtle rough offset used by _drawOTPBox().
  // This makes each digit sit inside its own stone instead of appearing
  // detached when the larger platform floats and tilts.

  // Local deterministic noise for the OTP stone offsets.
  // RealisticOceanPainter has its own noise() method, but that method
  // cannot be accessed from this State class.
  double _otpNoise(int n) {
    final value = math.sin(n * 12.9898 + 78.233) * 43758.5453;
    return value - value.floorToDouble();
  }

  Offset _otpStoneOffset(int index) {
    final seed = index * 733 + 401;

    double j(int n) => (_otpNoise(seed + n) - 0.5);

    final tl = Offset(j(1) * 1.7, j(2) * 1.35);
    final tr = Offset(j(3) * 1.7, j(4) * 1.35);
    final br = Offset(j(5) * 1.55, j(6) * 1.45);
    final bl = Offset(j(7) * 1.55, j(8) * 1.45);

    // Center of the same four rough corners used by the painted stone.
    return Offset(
      (tl.dx + tr.dx + br.dx + bl.dx) / 4.0,
      (tl.dy + tr.dy + br.dy + bl.dy) / 4.0,
    );
  }

  Widget _otpField(int index) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // A very subtle recessed surface makes the digit feel embedded
          // into the stone rather than floating in front of it.
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black.withOpacity(0.075),
                    Colors.transparent,
                    Colors.black.withOpacity(0.055),
                  ],
                  stops: const [0.0, 0.48, 1.0],
                ),
              ),
            ),
          ),
          Center(
            child: SizedBox(
              width: 28.0,
              height: 33.0,
              child: TextField(
                controller: otpControllers[index],
                focusNode: otpFocusNodes[index],
                autofocus: index == 0,
                maxLength: 1,
                textAlign: TextAlign.center,
                textAlignVertical: TextAlignVertical.center,
                textInputAction: index == 5
                    ? TextInputAction.done
                    : TextInputAction.next,
                keyboardType: TextInputType.number,
                cursorColor: const Color(0xffD8E0DA),
                style: const TextStyle(
                  color: Color(0xffE0E7E2),
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                  shadows: [
                    Shadow(
                      color: Color(0x88000000),
                      blurRadius: 2.2,
                      offset: Offset(0, 1.1),
                    ),
                    Shadow(
                      color: Color(0x44252D28),
                      blurRadius: 0.6,
                      offset: Offset(0, -0.4),
                    ),
                  ],
                ),
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                onChanged: (value) {
                  if (value.isNotEmpty && index < 5) {
                    otpFocusNodes[index + 1].requestFocus();
                  } else if (value.isEmpty && index > 0) {
                    otpFocusNodes[index - 1].requestFocus();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// MAIN PAINTER
// ================================================================

class RealisticOceanPainter extends CustomPainter {
  final ValueListenable<double> waterClock;
  final ValueListenable<double> platformClock;

  double get t => waterClock.value;
  double get platformAnimation => platformClock.value;

  RealisticOceanPainter(this.waterClock, this.platformClock)
    : super(repaint: Listenable.merge([waterClock, platformClock]));

  // ==============================================================
  // DETERMINISTIC NOISE
  // ==============================================================

  double noise(int n) {
    final value = math.sin(n * 12.9898 + 78.233) * 43758.5453;

    return value - value.floorToDouble();
  }

  double noise2(double x, double y) {
    final value = math.sin(x * 127.1 + y * 311.7 + 91.17) * 43758.5453;

    return value - value.floorToDouble();
  }

  double wave(double phase) {
    final s = math.sin(phase);

    return s + 0.18 * s * s * s;
  }

  double smoothNoise(double x, double y) {
    return math.sin(x * 1.7 + y * 2.3) * 0.45 +
        math.sin(x * 3.1 - y * 1.4) * 0.30 +
        math.sin(x * 6.2 + y * 4.8) * 0.17 +
        math.sin(x * 11.7 - y * 7.1) * 0.08;
  }

  double terrainNoise(double x, double y) {
    return math.sin(x * 0.018 + y * 0.021) * 0.42 +
        math.sin(x * 0.041 - y * 0.032) * 0.26 +
        math.sin(x * 0.083 + y * 0.061) * 0.16 +
        math.sin(x * 0.157 - y * 0.119) * 0.09 +
        math.sin(x * 0.31 + y * 0.21) * 0.05;
  }

  // ==============================================================
  // PAINT
  // ==============================================================

  @override
  void paint(Canvas canvas, Size size) {
    final horizon = size.height * 0.38;

    _drawSky(canvas, size, horizon);

    _drawWaterBase(canvas, size, horizon);

    _drawFarWaves(canvas, size, horizon);

    _drawMiddleWaves(canvas, size, horizon);

    _drawDeepWaves(canvas, size, horizon);

    _drawReflection(canvas, size, horizon);

    _drawWaterHighlights(canvas, size, horizon);

    _drawSlantedLand(canvas, size, horizon);

    _drawStonePlatform(canvas, size, horizon);

    // Rain-drop impact ripples are painted BEFORE the floating stone
    // platform so the stone blocks naturally occlude the ripples behind them.
    _drawRainImpacts(canvas, size, horizon);

    _drawOTPBoxes(canvas, size, horizon);

    _drawStoneRipples(canvas, size, horizon);

    _drawRain(canvas, size, horizon);

    _drawForeground(canvas, size);

    _drawVignette(canvas, size);
  }

  // ==============================================================
  // SKY
  // ==============================================================

  void _drawSky(Canvas canvas, Size size, double horizon) {
    final rect = Rect.fromLTWH(0, 0, size.width, horizon);

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xff263941),
            Color(0xff30464F),
            Color(0xff40545B),
            Color(0xff5A696C),
            Color(0xff737F80),
            Color(0xff8A9391),
          ],
          stops: [0.0, 0.20, 0.42, 0.65, 0.84, 1.0],
        ).createShader(rect),
    );

    for (int i = 0; i < 26; i++) {
      final x = noise(i * 31) * size.width;

      final y = size.height * (0.015 + noise(i * 17) * 0.38);

      final radius = 70 + noise(i * 41) * 250;

      final center = Offset(x, y);

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xff14242C).withOpacity(0.12),
              const Color(0xff263A43).withOpacity(0.065),
              const Color(0xff344950).withOpacity(0.025),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    for (int i = 0; i < 13; i++) {
      final d = i / 12;

      final y = size.height * (0.035 + d * 0.33);

      final height = 25 + d * 50;

      final cloudRect = Rect.fromLTWH(-150, y, size.width + 300, height);

      canvas.drawRect(
        cloudRect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.transparent,
              const Color(0xff15262E).withOpacity(0.015 + d * 0.018),
              const Color(0xff182930).withOpacity(0.025 + d * 0.025),
              const Color(0xff24373D).withOpacity(0.015),
              Colors.transparent,
            ],
          ).createShader(cloudRect),
      );
    }

    final hazeRect = Rect.fromLTWH(0, horizon - 80, size.width, 160);

    canvas.drawRect(
      hazeRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xffAEB9B6).withOpacity(0.035),
            const Color(0xffBFC8C5).withOpacity(0.11),
            const Color(0xffA5B0AE).withOpacity(0.06),
            Colors.transparent,
          ],
        ).createShader(hazeRect),
    );

    final mistRect = Rect.fromLTWH(0, horizon - 30, size.width, 90);

    canvas.drawRect(
      mistRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xffD6DEDC).withOpacity(0.04),
            const Color(0xffCDD7D4).withOpacity(0.07),
            Colors.transparent,
          ],
        ).createShader(mistRect),
    );
  }

  // ==============================================================
  // WATER BASE
  // ==============================================================

  void _drawWaterBase(Canvas canvas, Size size, double horizon) {
    final rect = Rect.fromLTWH(0, horizon, size.width, size.height - horizon);

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xff123746),
            Color(0xff0E3040),
            Color(0xff0B2B3B),
            Color(0xff092637),
            Color(0xff082131),
            Color(0xff061A28),
            Color(0xff04141F),
          ],
          stops: [0.0, 0.12, 0.27, 0.44, 0.62, 0.82, 1.0],
        ).createShader(rect),
    );

    for (int i = 0; i < 55; i++) {
      final d = noise(i * 13);

      final x = noise(i * 31) * size.width;

      final y = horizon + noise(i * 47) * (size.height - horizon);

      final radius = 70 + d * 300;

      final drift = math.sin(t * (0.25 + d * 0.65) + i * 2.1) * (8 + d * 35);

      final center = Offset(x + drift, y);

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xff4F91AF).withOpacity(0.018),
              const Color(0xff214B62).withOpacity(0.028),
              const Color(0xff092435).withOpacity(0.015),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    for (int i = 0; i < 14; i++) {
      final d = i / 13;

      final y =
          horizon + math.pow(d, 1.55).toDouble() * (size.height - horizon);

      final bandHeight = 20 + d * 100;

      final bandRect = Rect.fromLTWH(0, y, size.width, bandHeight);

      canvas.drawRect(
        bandRect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(0.003 + (1 - d) * 0.006),
              Colors.transparent,
            ],
          ).createShader(bandRect),
      );
    }
  }

  // ==============================================================
  // FAR WAVES
  // ==============================================================

  void _drawFarWaves(Canvas canvas, Size size, double horizon) {
    for (int row = 0; row < 36; row++) {
      final d = row / 59;

      final perspective = math.pow(d, 2.45).toDouble();

      final y = horizon + 3 + perspective * size.height * 0.28;

      final amp = 0.3 + d * 3.0;

      final path = Path()..moveTo(-60, y);

      for (double x = -60; x <= size.width + 60; x += 7) {
        final p1 = x * 0.034 + row * 0.72 + t * (1.15 + noise(row) * 1.7);

        final p2 = x * 0.076 - row * 1.1 - t;

        final irregular = smoothNoise(x * 0.025, row * 0.22 + t * 0.1);

        path.lineTo(
          x,
          y +
              wave(p1) * amp +
              math.sin(p2) * amp * 0.25 +
              irregular * amp * 0.12,
        );
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xff5095B8).withOpacity(0.012 + d * 0.022)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.35 + d * 0.75,
      );
    }
  }

  // ==============================================================
  // MIDDLE WAVES
  // ==============================================================

  void _drawMiddleWaves(Canvas canvas, Size size, double horizon) {
    for (int row = 0; row < 28; row++) {
      final d = row / 39;

      final perspective = math.pow(d, 1.32).toDouble();

      final baseY = horizon + 8 + perspective * (size.height - horizon) * 0.73;

      final amp = 1.4 + math.pow(d, 1.5).toDouble() * 25;

      final direction = noise(row * 91) > 0.5 ? 1.0 : -1.0;

      final speed = 1.8 + noise(row * 17) * 3.5;

      final path = Path()..moveTo(-120, baseY);

      for (double x = -120; x <= size.width + 120; x += 7) {
        final perspectiveX = x + math.sin(d * 2.5 + t * 0.7) * d * 25;

        final p1 =
            perspectiveX * (0.010 - d * 0.0015) +
            row * 0.73 +
            direction * t * speed;

        final p2 = perspectiveX * 0.022 - row * 0.87 - t * 1.2;

        final p3 = perspectiveX * 0.049 + row * 1.7 + direction * t * 3.5;

        final distortion =
            smoothNoise(x * 0.018, row * 0.48 - t * 0.15) * amp * 0.18;

        final vertical =
            math.sin(t * (0.7 + noise(row) * 1.2) + row * 2.2) * amp * 0.12;

        path.lineTo(
          x,
          baseY +
              wave(p1) * amp +
              math.sin(p2) * amp * 0.27 +
              math.sin(p3) * amp * 0.08 +
              vertical +
              distortion,
        );
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = Color.lerp(
            const Color(0xff5095B8),
            const Color(0xff0B2636),
            d,
          )!.withOpacity(0.016 + (1 - d) * 0.038)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.45 + d * 1.4,
      );
    }
  }

  // ==============================================================
  // DEEP WAVES
  // ==============================================================

  void _drawDeepWaves(Canvas canvas, Size size, double horizon) {
    const rows = 20;

    for (int row = 0; row < rows; row++) {
      final d = row / (rows - 1);

      final perspective = math.pow(d, 1.72).toDouble();

      final baseY = horizon + 20 + perspective * (size.height - horizon) * 0.92;

      final amp = 3.0 + perspective * 58;

      final thickness = 5 + perspective * 38;

      final direction = noise(row * 71) > 0.5 ? 1.0 : -1.0;

      final speed = 1.8 + noise(row * 31) * 4.0;

      final path = Path()..moveTo(-160, baseY);

      for (double x = -160; x <= size.width + 160; x += 6) {
        final xPerspective =
            x + math.sin(row * 0.65 + t * 0.45) * perspective * 28;

        final p1 =
            xPerspective * (0.012 - d * 0.0045) +
            row * 0.83 +
            direction * t * speed;

        final p2 = xPerspective * 0.029 + row * 1.7 - t * 1.4;

        final p3 = xPerspective * 0.071 - row * 1.1 + direction * t * 3;

        final chaotic =
            smoothNoise(
              x * 0.025 + direction * t * 0.08,
              row * 0.55 - t * 0.12,
            ) *
            amp *
            0.12;

        final y =
            baseY +
            wave(p1) * amp +
            math.sin(p2) * amp * 0.20 +
            math.sin(p3) * amp * 0.055 +
            math.sin(t * (0.65 + noise(row * 19) * 1.5) + row * 2.31) *
                amp *
                0.13 +
            smoothNoise(
                  x * 0.019 + direction * t * 0.1,
                  row * 0.40 + t * 0.13,
                ) *
                amp *
                0.11 +
            chaotic;

        path.lineTo(x, y);
      }

      path
        ..lineTo(size.width + 160, baseY + amp + thickness)
        ..lineTo(-160, baseY + amp + thickness)
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
                const Color(0xff75C9F2),
                const Color(0xff2C6885),
                d,
              )!.withOpacity(0.045 + (1 - d) * 0.075),
              Color.lerp(
                const Color(0xff16445B),
                const Color(0xff0B2636),
                d,
              )!.withOpacity(0.11 + d * 0.085),
              Color.lerp(
                const Color(0xff082838),
                const Color(0xff061722),
                d,
              )!.withOpacity(0.15 + d * 0.16),
            ],
            stops: const [0, 0.42, 1],
          ).createShader(rect),
      );

      final crest = Path()..moveTo(-160, baseY);

      for (double x = -160; x <= size.width + 160; x += 9) {
        final xPerspective =
            x + math.sin(row * 0.65 + t * 0.45) * perspective * 28;

        final p =
            xPerspective * (0.012 - d * 0.0045) +
            row * 0.83 +
            direction * t * speed;

        crest.lineTo(x, baseY + wave(p) * amp);
      }

      canvas.drawPath(
        crest,
        Paint()
          ..color = Color.lerp(
            const Color(0xff75C9F2),
            const Color(0xff2C6885),
            d,
          )!.withOpacity(0.030 + (1 - d) * 0.085)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.55 + d * 2.6
          ..strokeCap = StrokeCap.round,
      );

      if (d > 0.25) {
        final shadow = Path()..moveTo(-160, baseY + amp * 0.12);

        for (double x = -160; x <= size.width + 160; x += 7) {
          final p =
              x * (0.012 - d * 0.0045) + row * 0.83 + direction * t * speed;

          shadow.lineTo(x, baseY + wave(p) * amp + 2 + d * 2);
        }

        canvas.drawPath(
          shadow,
          Paint()
            ..color = Colors.black.withOpacity(0.014 + d * 0.030)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8 + d * 2.0,
        );
      }
    }
  }

  // ==============================================================
  // REFLECTION
  // ==============================================================

  void _drawReflection(Canvas canvas, Size size, double horizon) {
    final x0 = size.width * 0.78;

    for (int i = 0; i < 110; i++) {
      final p = i / 200;

      final y = horizon + 7 + math.pow(p, 1.35).toDouble() * size.height * 0.75;

      final spread = 2.5 + math.pow(p, 1.55).toDouble() * size.width * 0.19;

      final movement = math.sin(t * (1 + noise(i * 17) * 2.4) + i * 1.8);

      final x = x0 + movement * spread * 0.75;

      if (math.sin(i * 2.71 + t * 2.2) * 0.5 + noise(i * 71) < 0.5) {
        continue;
      }

      final length = 1.5 + noise(i * 29) * (6 + p * 19);

      canvas.drawLine(
        Offset(x - length, y),
        Offset(x + length, y + math.sin(i * 0.8 + t * 4.5) * (1 + p * 2)),
        Paint()
          ..color = const Color(0xff5095B8).withOpacity(0.032 - p * 0.014)
          ..strokeWidth = 0.4 + p * 1.3
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.55),
      );
    }
  }

  // ==============================================================
  // WATER HIGHLIGHTS
  // ==============================================================

  void _drawWaterHighlights(Canvas canvas, Size size, double horizon) {
    for (int i = 0; i < 170; i++) {
      final d = 0.18 + noise(i * 19) * 0.80;

      final perspective = math.pow(d, 1.42).toDouble();

      final y = horizon + perspective * (size.height - horizon);

      final x = noise(i * 61) * size.width;

      final movement = math.sin(t * (1 + noise(i * 17) * 3) + i * 1.43);

      final xx = x + movement * (4 + d * 25);

      final length = 3 + noise(i * 53) * (7 + d * 65);

      canvas.drawLine(
        Offset(xx - length, y),
        Offset(xx + length, y + math.sin(i + t * 4) * (1 + d * 2.5)),
        Paint()
          ..color = Color.lerp(
            const Color(0xff5095B8),
            const Color(0xff103850),
            d,
          )!.withOpacity(0.009 + (1 - d) * 0.028)
          ..strokeWidth = 0.45 + d * 1.35
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  // ==============================================================
  // LAND
  // ==============================================================

  void _drawSlantedLand(Canvas canvas, Size size, double horizon) {
    final w = size.width;
    final h = size.height;

    final leftShore = Path()
      ..moveTo(0, horizon - 3)
      ..cubicTo(
        w * 0.035,
        horizon - 1,
        w * 0.085,
        horizon + 1,
        w * 0.145,
        horizon + 7,
      )
      ..cubicTo(
        w * 0.205,
        horizon + 16,
        w * 0.235,
        h * 0.485,
        w * 0.195,
        h * 0.515,
      )
      ..cubicTo(
        w * 0.172,
        h * 0.535,
        w * 0.150,
        h * 0.552,
        w * 0.126,
        h * 0.575,
      )
      ..cubicTo(
        w * 0.105,
        h * 0.595,
        w * 0.118,
        h * 0.612,
        w * 0.082,
        h * 0.632,
      )
      ..cubicTo(w * 0.058, h * 0.646, w * 0.032, h * 0.658, 0, h * 0.672)
      ..lineTo(0, h)
      ..close();

    final rightShore = Path()
      ..moveTo(w, horizon - 3)
      ..cubicTo(
        w * 0.958,
        horizon - 1,
        w * 0.910,
        horizon + 2,
        w * 0.858,
        horizon + 8,
      )
      ..cubicTo(
        w * 0.805,
        horizon + 15,
        w * 0.770,
        h * 0.482,
        w * 0.808,
        h * 0.510,
      )
      ..cubicTo(
        w * 0.833,
        h * 0.532,
        w * 0.852,
        h * 0.550,
        w * 0.878,
        h * 0.572,
      )
      ..cubicTo(
        w * 0.900,
        h * 0.591,
        w * 0.887,
        h * 0.610,
        w * 0.922,
        h * 0.630,
      )
      ..cubicTo(w * 0.949, h * 0.646, w * 0.977, h * 0.658, w, h * 0.670)
      ..lineTo(w, h)
      ..close();

    final leftRect = Rect.fromLTWH(0, horizon - 10, w * 0.42, h * 0.78);

    canvas.drawPath(
      leftShore,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xff66736A),
            Color(0xff5B6255),
            Color(0xff4C5045),
            Color(0xff3B4037),
            Color(0xff292F28),
            Color(0xff171D18),
            Color(0xff090F0B),
          ],
          stops: [0.0, 0.12, 0.30, 0.50, 0.68, 0.84, 1.0],
        ).createShader(leftRect),
    );

    final rightRect = Rect.fromLTWH(w * 0.58, horizon - 10, w * 0.42, h * 0.78);

    canvas.drawPath(
      rightShore,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xff66736A),
            Color(0xff5B6255),
            Color(0xff4C5045),
            Color(0xff3B4037),
            Color(0xff292F28),
            Color(0xff171D18),
            Color(0xff090F0B),
          ],
          stops: [0.0, 0.12, 0.30, 0.50, 0.68, 0.84, 1.0],
        ).createShader(rightRect),
    );

    _drawInclinedTerrain(canvas, size, horizon, leftShore, true);
    _drawInclinedTerrain(canvas, size, horizon, rightShore, false);

    final leftContact = Path()
      ..moveTo(w * 0.145, horizon + 7)
      ..cubicTo(
        w * 0.205,
        horizon + 16,
        w * 0.235,
        h * 0.485,
        w * 0.195,
        h * 0.515,
      )
      ..cubicTo(
        w * 0.172,
        h * 0.535,
        w * 0.150,
        h * 0.552,
        w * 0.126,
        h * 0.575,
      )
      ..cubicTo(
        w * 0.105,
        h * 0.595,
        w * 0.118,
        h * 0.612,
        w * 0.082,
        h * 0.632,
      );

    canvas.drawPath(
      leftContact,
      Paint()
        ..color = const Color(0xff020604).withOpacity(0.76)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 19
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );

    final rightContact = Path()
      ..moveTo(w * 0.858, horizon + 8)
      ..cubicTo(
        w * 0.805,
        horizon + 15,
        w * 0.770,
        h * 0.482,
        w * 0.808,
        h * 0.510,
      )
      ..cubicTo(
        w * 0.833,
        h * 0.532,
        w * 0.852,
        h * 0.550,
        w * 0.878,
        h * 0.572,
      )
      ..cubicTo(
        w * 0.900,
        h * 0.591,
        w * 0.887,
        h * 0.610,
        w * 0.922,
        h * 0.630,
      );

    canvas.drawPath(
      rightContact,
      Paint()
        ..color = const Color(0xff020604).withOpacity(0.76)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 19
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );

    final leftWet = Path()
      ..moveTo(w * 0.144, horizon + 6)
      ..cubicTo(
        w * 0.204,
        horizon + 15,
        w * 0.233,
        h * 0.485,
        w * 0.193,
        h * 0.515,
      )
      ..cubicTo(
        w * 0.170,
        h * 0.535,
        w * 0.148,
        h * 0.553,
        w * 0.124,
        h * 0.575,
      )
      ..cubicTo(
        w * 0.103,
        h * 0.595,
        w * 0.116,
        h * 0.612,
        w * 0.080,
        h * 0.632,
      );

    canvas.drawPath(
      leftWet,
      Paint()
        ..color = const Color(0xffB7C7BD).withOpacity(0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.25
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.65),
    );

    final rightWet = Path()
      ..moveTo(w * 0.859, horizon + 7)
      ..cubicTo(
        w * 0.806,
        horizon + 14,
        w * 0.772,
        h * 0.482,
        w * 0.810,
        h * 0.510,
      )
      ..cubicTo(
        w * 0.835,
        h * 0.532,
        w * 0.854,
        h * 0.550,
        w * 0.880,
        h * 0.572,
      )
      ..cubicTo(
        w * 0.902,
        h * 0.591,
        w * 0.889,
        h * 0.610,
        w * 0.924,
        h * 0.630,
      );

    canvas.drawPath(
      rightWet,
      Paint()
        ..color = const Color(0xffB7C7BD).withOpacity(0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.25
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.65),
    );
  }

  // ==============================================================
  // NATURAL 3D SLOPE TERRAIN
  // ==============================================================

  void _drawInclinedTerrain(
    Canvas canvas,
    Size size,
    double horizon,
    Path shorePath,
    bool isLeft,
  ) {
    canvas.save();
    canvas.clipPath(shorePath);

    final w = size.width;
    final h = size.height;

    final terrainRect = Rect.fromLTWH(0, horizon - 15, w, h * 0.82);

    final baseGradient = isLeft
        ? const LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: [
              Color(0xff6D6B59),
              Color(0xff62614F),
              Color(0xff555546),
              Color(0xff45463A),
              Color(0xff34372E),
              Color(0xff20261F),
              Color(0xff101612),
            ],
            stops: [0.0, 0.12, 0.27, 0.43, 0.61, 0.80, 1.0],
          )
        : const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xff6D6B59),
              Color(0xff62614F),
              Color(0xff555546),
              Color(0xff45463A),
              Color(0xff34372E),
              Color(0xff20261F),
              Color(0xff101612),
            ],
            stops: [0.0, 0.12, 0.27, 0.43, 0.61, 0.80, 1.0],
          );

    canvas.drawRect(
      terrainRect,
      Paint()..shader = baseGradient.createShader(terrainRect),
    );

    double bankX(double y) {
      final d = ((y - horizon) / (h * 0.70)).clamp(0.0, 1.0);
      final curved = math.pow(d, 0.78).toDouble();

      if (isLeft) {
        return w * (0.15 + curved * 0.27);
      }
      return w * (0.85 - curved * 0.27);
    }

    double terrainHeight(double x, double y) {
      final d = ((y - horizon) / (h * 0.70)).clamp(0.0, 1.0);

      final broad =
          math.sin(x * 0.010 + (isLeft ? 0.6 : 2.1)) * 0.16 +
          math.sin(x * 0.024 - y * 0.012) * 0.10 +
          math.sin(x * 0.051 + y * 0.019) * 0.055;

      final ridge =
          math.sin(x * 0.086 + y * 0.031) * 0.040 +
          math.sin(x * 0.153 - y * 0.062) * 0.022;

      final slope = d * 0.34;

      return (slope + broad + ridge).clamp(-0.28, 0.62);
    }

    Color earthColor(double variation, double wetness) {
      final colors = <Color>[
        const Color(0xff30372E),
        const Color(0xff3F4337),
        const Color(0xff4D4B3B),
        const Color(0xff595640),
        const Color(0xff69634A),
        const Color(0xff4B5140),
      ];

      final q = ((variation + 1.0) * 0.5).clamp(0.0, 0.999);
      final scaled = q * (colors.length - 1);
      final index = scaled.floor();
      final f = scaled - index;

      var c = Color.lerp(colors[index], colors[index + 1], f)!;

      c = Color.lerp(
        c,
        const Color(0xff242A23),
        wetness.clamp(0.0, 1.0) * 0.58,
      )!;

      return c;
    }

    for (int i = 0; i < 55; i++) {
      final seed = i + (isLeft ? 7200 : 17200);
      final nx = noise(seed * 13);
      final ny = noise(seed * 29);
      final nz = noise(seed * 47);
      final shape = noise(seed * 61);

      final d = math.pow(ny, 0.78).toDouble();
      final edge = bankX(horizon + d * h * 0.66);

      final spread = w * (0.035 + d * 0.16 + shape * 0.06);
      final x = isLeft
          ? math.min(edge - 3, nx * w * 0.95)
          : math.max(edge + 3, w - nx * w * 0.95);

      final y = horizon + d * h * 0.66;
      final rx = 28 + nz * (90 + d * 125);
      final ry = 13 + nz * (30 + d * 82);

      final elev = terrainHeight(x, y) + shape * 0.12;
      final wet = (1.0 - d) * 0.68;

      final shadowCenter = Offset(x + (isLeft ? 7 : -7), y + 8);

      canvas.drawOval(
        Rect.fromCenter(
          center: shadowCenter,
          width: rx * 1.12,
          height: ry * 1.16,
        ),
        Paint()
          ..color = Colors.black.withOpacity(0.025 + (elev + 0.28) * 0.055)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5.0 + d * 8.0),
      );

      final body = Rect.fromCenter(center: Offset(x, y), width: rx, height: ry);

      canvas.drawOval(
        body,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.55, -0.70),
            radius: 1.0,
            colors: [
              earthColor(
                0.36 + elev * 0.35 + shape * 0.12,
                wet,
              ).withOpacity(0.20 + d * 0.11),
              earthColor(0.02 + elev * 0.25, wet).withOpacity(0.13 + d * 0.08),
              const Color(0xff171C16).withOpacity(0.045 + d * 0.06),
              Colors.transparent,
            ],
            stops: const [0.0, 0.42, 0.78, 1.0],
          ).createShader(body),
      );

      if (elev > 0.06) {
        final shoulder = Rect.fromCenter(
          center: Offset(x - (isLeft ? 3 : -3), y - 3),
          width: rx * 0.68,
          height: ry * 0.38,
        );

        canvas.drawOval(
          shoulder,
          Paint()
            ..color = const Color(
              0xffB0AA88,
            ).withOpacity(0.018 + d * 0.026 + elev * 0.035)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.8),
        );
      }
    }

    for (int i = 0; i < 28; i++) {
      final seed = i + (isLeft ? 26000 : 32000);
      final d = i / 42.0;
      final baseY = horizon + math.pow(d, 1.12).toDouble() * h * 0.66;

      final maxWidth = w * (0.075 + d * 0.34);
      final startX = isLeft ? -w * 0.025 : w * 1.025;
      final direction = isLeft ? 1.0 : -1.0;

      final ridge = Path()..moveTo(startX, baseY);

      for (double x = 0; x <= maxWidth; x += 6) {
        final n = terrainNoise(x + seed * 9, baseY * 0.8 + seed * 4);

        final broad = math.sin(x * 0.011 + i * 0.73) * (2.5 + d * 13);
        final medium = math.sin(x * 0.035 - i * 0.41) * (1.2 + d * 7);
        final rough = n * (2.5 + d * 11);

        ridge.lineTo(startX + direction * x, baseY + broad + medium + rough);
      }

      canvas.drawPath(
        ridge.shift(Offset(0, 4.5 + d * 2.5)),
        Paint()
          ..color = Colors.black.withOpacity(0.018 + d * 0.038)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 + d * 4.5
          ..strokeCap = StrokeCap.round
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1.5 + d * 2.2),
      );

      canvas.drawPath(
        ridge.shift(const Offset(0, -2.0)),
        Paint()
          ..color = const Color(
            0xffC0B894,
          ).withOpacity(0.012 + (1 - d) * 0.020 + d * 0.010)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.55 + d * 1.05
          ..strokeCap = StrokeCap.round,
      );
    }

    for (int i = 0; i < 280; i++) {
      final seed = i + (isLeft ? 38000 : 47000);
      final nx = noise(seed * 17);
      final ny = noise(seed * 31);
      final nd = noise(seed * 53);
      final n4 = noise(seed * 71);

      final d = math.pow(ny, 0.84).toDouble();
      final edge = bankX(horizon + d * h * 0.68);

      final maxSide = w * (0.035 + d * 0.35);
      final x = isLeft ? nx * maxSide : w - nx * maxSide;

      final y = horizon + d * h * 0.68;

      final local = isLeft
          ? x / math.max(1.0, edge)
          : (w - x) / math.max(1.0, w - edge);

      if (local > 1.03) continue;

      final r = 2.5 + nd * (8.0 + d * 18.0);
      final texture = terrainNoise(x * 0.8 + seed, y * 0.65 - seed);

      final c = earthColor(texture * 0.75 + (n4 - 0.5) * 0.45, (1 - d) * 0.72);

      final patch = Rect.fromCenter(
        center: Offset(x + (n4 - 0.5) * r * 1.8, y + (nd - 0.5) * r),
        width: r * (1.8 + nd * 2.8),
        height: r * (0.65 + nd * 1.2),
      );

      canvas.drawOval(
        patch,
        Paint()
          ..color = c.withOpacity(0.035 + nd * 0.055 + d * 0.025)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 0.7 + nd * 1.4),
      );

      if (i % 4 == 0) {
        canvas.drawLine(
          Offset(x - r * 0.45, y),
          Offset(x + r * 0.45, y + (n4 - 0.5) * 1.2),
          Paint()
            ..color = const Color(0xffC0B58A).withOpacity(0.018 + d * 0.012)
            ..strokeWidth = 0.45 + nd * 0.45
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    for (int i = 0; i < 18; i++) {
      final seed = i + (isLeft ? 54000 : 61000);
      final n1 = noise(seed * 11);
      final n2 = noise(seed * 23);
      final n3 = noise(seed * 37);

      final startX = isLeft ? n1 * w * 0.28 : w - n1 * w * 0.28;

      final startY = horizon + (0.05 + n2 * 0.28) * h;
      final direction = isLeft ? 1.0 : -1.0;

      final gully = Path()..moveTo(startX, startY);

      for (int j = 1; j <= 13; j++) {
        final q = j / 13.0;
        final jitter = noise(seed + j * 17);

        gully.lineTo(
          startX + direction * q * (22 + n3 * 65 + jitter * 20),
          startY + q * (38 + n2 * 92) + math.sin(j * 1.31 + seed) * (2 + q * 7),
        );
      }

      canvas.drawPath(
        gully,
        Paint()
          ..color = const Color(0xff080C08).withOpacity(0.025 + n3 * 0.035)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0 + n2 * 2.0
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2),
      );

      canvas.drawPath(
        gully.shift(Offset(isLeft ? -1.1 : 1.1, -1.1)),
        Paint()
          ..color = const Color(0xffB3AD8D).withOpacity(0.014)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.65
          ..strokeCap = StrokeCap.round,
      );
    }

    for (int i = 0; i < 34; i++) {
      final seed = i + (isLeft ? 67000 : 72000);
      final n1 = noise(seed * 17);
      final n2 = noise(seed * 43);
      final n3 = noise(seed * 71);

      final x = isLeft ? w * (0.035 + n1 * 0.27) : w * (0.965 - n1 * 0.27);

      final y = horizon + math.pow(n2, 1.25).toDouble() * h * 0.40;

      final rw = 18 + n3 * 80;
      final rh = 4 + n1 * 17;

      final wetPatch = Rect.fromCenter(
        center: Offset(x, y),
        width: rw,
        height: rh,
      );

      canvas.drawOval(
        wetPatch,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xff202B25).withOpacity(0.13),
              const Color(0xff101711).withOpacity(0.075),
              Colors.transparent,
            ],
          ).createShader(wetPatch),
      );
    }

    for (int i = 0; i < 20; i++) {
      final seed = i + (isLeft ? 81000 : 85000);
      final nx = noise(seed * 13);
      final ny = noise(seed * 31);
      final nd = noise(seed * 47);

      final d = math.pow(ny, 0.78).toDouble();
      final edge = bankX(horizon + d * h * 0.65);

      final x = isLeft
          ? math.min(nx * w * 0.35, edge - 6)
          : math.max(w - nx * w * 0.35, edge + 6);

      final y = horizon + d * h * 0.65;
      final r = 2.5 + nd * (6.0 + d * 10.0);

      _drawInclinedRock(canvas, Offset(x, y), r, nd, d);
    }

    for (int i = 0; i < 80; i++) {
      final seed = i + (isLeft ? 91000 : 94000);
      final nx = noise(seed * 19);
      final ny = noise(seed * 41);
      final nd = noise(seed * 67);

      final d = math.pow(ny, 0.82).toDouble();
      final maxSide = w * (0.045 + d * 0.34);

      final x = isLeft ? nx * maxSide : w - nx * maxSide;
      final y = horizon + d * h * 0.67;

      final radius = 0.25 + nd * (0.7 + d * 1.15);

      final pebbleColor = Color.lerp(
        const Color(0xff353A31),
        const Color(0xff817A61),
        nd * 0.55 + d * 0.25,
      )!;

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: radius * (1.5 + nd),
          height: radius * (0.55 + nd * 0.45),
        ),
        Paint()..color = pebbleColor.withOpacity(0.10 + nd * 0.08),
      );
    }

    for (int i = 0; i < 42; i++) {
      final seed = i + (isLeft ? 97000 : 101000);
      final n1 = noise(seed * 13);
      final n2 = noise(seed * 29);
      final n3 = noise(seed * 53);

      final d = math.pow(n2, 0.80).toDouble();
      final x = isLeft ? w * (0.025 + n1 * 0.34) : w * (0.975 - n1 * 0.34);
      final y = horizon + d * h * 0.65;

      final patchW = 7 + n3 * 25;
      final patchH = 1.4 + n2 * 4.0;

      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: patchW, height: patchH),
        Paint()
          ..color = const Color(0xff647154).withOpacity(0.035 + d * 0.035)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.4),
      );

      if (i % 2 == 0) {
        final count = 2 + (n3 * 3).floor();

        for (int b = 0; b < count; b++) {
          final bx = x + (b - count / 2) * (1.3 + n1 * 1.3);
          final lean = (noise(seed + b * 17) - 0.5) * 5.5;

          final blade = Path()
            ..moveTo(bx, y + 2)
            ..quadraticBezierTo(
              bx + lean * 0.45,
              y - 2.8 - n2 * 3.0,
              bx + lean,
              y - 4.5 - n3 * 3.5,
            );

          canvas.drawPath(
            blade,
            Paint()
              ..color = const Color(0xff778465).withOpacity(0.035 + d * 0.028)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.55
              ..strokeCap = StrokeCap.round,
          );
        }
      }
    }

    for (int i = 0; i < 65; i++) {
      final seed = i + (isLeft ? 106000 : 110000);
      final n1 = noise(seed * 17);
      final n2 = noise(seed * 31);
      final n3 = noise(seed * 61);

      final x = isLeft ? w * (0.035 + n1 * 0.34) : w * (0.965 - n1 * 0.34);

      final y = horizon + math.pow(n2, 1.18).toDouble() * h * 0.53;

      final length = 2.5 + n3 * 15;

      canvas.drawLine(
        Offset(x - length * 0.5, y),
        Offset(x + length * 0.5, y + (n3 - 0.5) * 1.5),
        Paint()
          ..color = const Color(
            0xffD0D5C5,
          ).withOpacity(0.012 + (1 - n2) * 0.018)
          ..strokeWidth = 0.45 + n3 * 0.35
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.45),
      );
    }

    for (int i = 0; i < 18; i++) {
      final seed = i + (isLeft ? 116000 : 120000);
      final n1 = noise(seed * 11);
      final n2 = noise(seed * 23);

      final startX = isLeft ? n1 * w * 0.34 : w - n1 * w * 0.34;

      final startY = horizon + (0.14 + n2 * 0.48) * h;

      final direction = isLeft ? 1.0 : -1.0;
      final crack = Path()..moveTo(startX, startY);

      for (int j = 1; j < 7; j++) {
        final d = j / 6.0;

        crack.lineTo(
          startX + direction * d * (9 + noise(seed + j * 7) * 30),
          startY + d * (8 + noise(seed + j * 13) * 25),
        );
      }

      canvas.drawPath(
        crack,
        Paint()
          ..color = const Color(0xff080C08).withOpacity(0.018 + n1 * 0.022)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.4 + n2 * 0.5
          ..strokeCap = StrokeCap.round,
      );
    }

    final lightRect = isLeft
        ? Rect.fromLTWH(0, horizon, w * 0.42, h * 0.72)
        : Rect.fromLTWH(w * 0.58, horizon, w * 0.42, h * 0.72);

    canvas.drawRect(
      lightRect,
      Paint()
        ..shader = LinearGradient(
          begin: isLeft ? Alignment.topRight : Alignment.topLeft,
          end: isLeft ? Alignment.bottomLeft : Alignment.bottomRight,
          colors: [
            const Color(0xffC3B992).withOpacity(0.035),
            const Color(0xff9B9877).withOpacity(0.012),
            Colors.transparent,
          ],
          stops: const [0.0, 0.32, 1.0],
        ).createShader(lightRect),
    );

    canvas.restore();
  }

  void _drawInclinedRock(
    Canvas canvas,
    Offset center,
    double r,
    double nd,
    double depth,
  ) {
    final shadow = Offset(center.dx + r * 0.42, center.dy + r * 0.48);

    canvas.drawOval(
      Rect.fromCenter(center: shadow, width: r * 2.7, height: r * 1.25),
      Paint()
        ..color = Colors.black.withOpacity(0.15 + depth * 0.12)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.42 + 1),
    );

    final body = Rect.fromCenter(
      center: center,
      width: r * 2.15,
      height: r * 1.55,
    );

    canvas.drawOval(
      body,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.55, -0.65),
          radius: 1.15,
          colors: [
            Color.lerp(
              const Color(0xffB7C0B1),
              const Color(0xff707A6D),
              nd,
            )!.withOpacity(0.72),
            Color.lerp(
              const Color(0xff646D61),
              const Color(0xff333C34),
              nd,
            )!.withOpacity(0.80),
            const Color(0xff0C120E).withOpacity(0.92),
          ],
          stops: const [0, 0.53, 1],
        ).createShader(body),
    );

    canvas.drawArc(
      Rect.fromCenter(
        center: center.translate(-r * 0.12, -r * 0.15),
        width: r * 1.55,
        height: r * 1.05,
      ),
      math.pi * 1.05,
      math.pi * 0.58,
      false,
      Paint()
        ..color = const Color(0xffD7DFD1).withOpacity(0.10 + nd * 0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.55, r * 0.10)
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawArc(
      Rect.fromCenter(
        center: center.translate(r * 0.10, r * 0.12),
        width: r * 1.65,
        height: r * 1.05,
      ),
      0.15,
      math.pi * 0.85,
      false,
      Paint()
        ..color = Colors.black.withOpacity(0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.5, r * 0.08)
        ..strokeCap = StrokeCap.round,
    );

    if (r > 8) {
      final facet = Path()
        ..moveTo(center.dx - r * 0.45, center.dy - r * 0.10)
        ..lineTo(center.dx - r * 0.05, center.dy - r * 0.48)
        ..lineTo(center.dx + r * 0.38, center.dy - r * 0.18)
        ..lineTo(center.dx + r * 0.10, center.dy + r * 0.08)
        ..close();

      canvas.drawPath(
        facet,
        Paint()
          ..color = const Color(0xffC0C9BC).withOpacity(0.035 + nd * 0.035),
      );
    }
  }

  void _drawSmallRock(Canvas canvas, Offset center, double r, double nd) {
    final shadow = Offset(center.dx + r * 0.35, center.dy + r * 0.40);

    canvas.drawOval(
      Rect.fromCenter(center: shadow, width: r * 2.2, height: r),
      Paint()
        ..color = Colors.black.withOpacity(0.12)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.45 + 0.5),
    );

    final rect = Rect.fromCenter(
      center: center,
      width: r * 2,
      height: r * 1.35,
    );

    canvas.drawOval(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.45, -0.55),
          colors: [
            const Color(0xffA7B1A4).withOpacity(0.58),
            const Color(0xff4B554A).withOpacity(0.72),
            const Color(0xff111811).withOpacity(0.90),
          ],
          stops: const [0, 0.52, 1],
        ).createShader(rect),
    );

    canvas.drawArc(
      rect,
      math.pi * 1.05,
      math.pi * 0.55,
      false,
      Paint()
        ..color = const Color(0xffD1D9CD).withOpacity(0.07 + nd * 0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.35, r * 0.10),
    );
  }

  // ==============================================================
  // CIRCULAR STONE PLATFORM
  // ==============================================================

  void _drawStonePlatform(Canvas canvas, Size size, double horizon) {
    final w = size.width;
    final h = size.height;

    final cx = w * 0.50;
    final baseCy = h * 0.637;
    final phase = t * math.pi * 2.0;

    final slowPlatformPhase = platformAnimation * math.pi * 2.0;

    final microPhase = 0.5 + 0.5 * math.sin(slowPlatformPhase + 0.42);

    final floatY =
        math.sin(phase) * h * 0.018 +
        math.sin(phase * 2.0 + 0.9) * h * 0.007 +
        (microPhase - 0.5) * h * 0.0035;

    final floatX =
        math.sin(phase + 1.2) * w * 0.007 +
        math.sin(phase * 2.0 + 0.4) * w * 0.003 +
        (microPhase - 0.5) * w * 0.0016;

    final tiltX =
        math.sin(phase + 0.6) * (math.pi * 9.0 / 180) +
        math.sin(phase * 2.0 + 1.4) * (math.pi * 2.0 / 180) +
        (microPhase - 0.5) * (math.pi * 0.7 / 180);

    final tiltZ =
        math.sin(phase + 0.35) * (math.pi * 4.8 / 180) +
        math.sin(phase * 2.0 + 1.1) * (math.pi * 1.8 / 180) +
        math.sin(phase * 3.0 + 0.7) * (math.pi * 0.7 / 180) +
        (microPhase - 0.5) * (math.pi * 0.4 / 180);

    final breathe = 1.0 + math.sin(phase + 0.6) * 0.024;

    final cy = baseCy + floatY - h * 0.015;
    final rx = w * 0.235 * breathe;
    final ry = h * 0.060 * breathe;
    final depth = h * 0.040;

    canvas.save();

    canvas.translate(cx + floatX, cy);
    canvas.rotate(tiltZ);

    final perspectiveY = (1.0 - math.sin(tiltX).abs() * 0.16)
        .clamp(0.84, 1.0)
        .toDouble();
    final perspectiveX = (1.0 + math.sin(tiltX) * 0.055)
        .clamp(0.94, 1.06)
        .toDouble();
    final shearX = math.sin(tiltX) * 0.045;

    canvas.scale(perspectiveX, perspectiveY);
    canvas.skew(shearX, 0.0);
    canvas.translate(-cx, -cy);

    final shadowRect = Rect.fromCenter(
      center: Offset(cx, cy + depth + h * 0.012),
      width: rx * 2.18,
      height: ry * 2.05,
    );

    canvas.drawOval(
      shadowRect,
      Paint()
        ..color = const Color(0xff182028).withOpacity(0.72)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    final reflectionRect = Rect.fromCenter(
      center: Offset(
        cx + math.sin(t * 1.2) * w * 0.012,
        cy + depth + h * 0.018,
      ),
      width: rx * 1.95,
      height: ry * 0.72,
    );

    canvas.drawOval(
      reflectionRect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xff283F48).withOpacity(0.22),
            const Color(0xff283F48).withOpacity(0.11),
            Colors.transparent,
          ],
        ).createShader(reflectionRect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    List<Offset> stonePoints({
      required double centerY,
      required double xRadius,
      required double yRadius,
      required int count,
      required double roughness,
      required double seed,
    }) {
      final points = <Offset>[];

      for (int i = 0; i < count; i++) {
        final a = (i / count) * math.pi * 2.0;

        final broad = math.sin(i * 0.73 + seed) * 0.55;
        final medium = math.sin(i * 1.91 + seed * 1.7) * 0.30;
        final fine = math.sin(i * 4.73 + seed * 0.43) * 0.15;
        final n = 1.0 + roughness * (broad + medium + fine);

        points.add(
          Offset(
            cx + math.cos(a) * xRadius * n,
            centerY + math.sin(a) * yRadius * n,
          ),
        );
      }

      return points;
    }

    Path smoothClosedPath(List<Offset> points) {
      final path = Path();
      final n = points.length;
      final first = Offset(
        (points[n - 1].dx + points[0].dx) * 0.5,
        (points[n - 1].dy + points[0].dy) * 0.5,
      );
      path.moveTo(first.dx, first.dy);

      for (int i = 0; i < n; i++) {
        final current = points[i];
        final next = points[(i + 1) % n];
        final mid = Offset(
          (current.dx + next.dx) * 0.5,
          (current.dy + next.dy) * 0.5,
        );
        path.quadraticBezierTo(current.dx, current.dy, mid.dx, mid.dy);
      }
      path.close();
      return path;
    }

    final topPoints = stonePoints(
      centerY: cy,
      xRadius: rx,
      yRadius: ry,
      count: 88,
      roughness: 0.060,
      seed: 2.4,
    );

    final bottomPoints = stonePoints(
      centerY: cy + depth,
      xRadius: rx * 1.015,
      yRadius: ry * 1.08,
      count: 88,
      roughness: 0.045,
      seed: 4.7,
    );

    final sidePath = Path();

    for (int i = 0; i <= topPoints.length; i++) {
      final p = topPoints[i % topPoints.length];
      if (i == 0) {
        sidePath.moveTo(p.dx, p.dy);
      } else {
        sidePath.lineTo(p.dx, p.dy);
      }
    }

    for (int i = bottomPoints.length; i >= 0; i--) {
      final p = bottomPoints[i % bottomPoints.length];
      sidePath.lineTo(p.dx, p.dy);
    }
    sidePath.close();

    final sideBounds = Rect.fromLTWH(
      cx - rx - 8,
      cy - ry,
      rx * 2 + 16,
      ry + depth + 10,
    );

    canvas.drawPath(
      sidePath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Color(0xff4D5B61),
            Color(0xff3A4950),
            Color(0xff303940),
            Color(0xff182028),
          ],
          stops: const [0.0, 0.28, 0.68, 1.0],
        ).createShader(sideBounds),
    );

    canvas.drawPath(
      smoothClosedPath(bottomPoints),
      Paint()
        ..color = const Color(0xff182028).withOpacity(0.96)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(2.0, h * 0.004),
    );

    final topPath = smoothClosedPath(topPoints);
    final topRect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: rx * 2.0,
      height: ry * 2.0,
    );

    canvas.drawPath(
      topPath,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.28, -0.52),
          radius: 1.0,
          colors: const [
            Color(0xff56646A),
            Color(0xff414F55),
            Color(0xff343F45),
            Color(0xff293238),
            Color(0xff182028),
          ],
          stops: const [0.0, 0.20, 0.44, 0.72, 1.0],
        ).createShader(topRect),
    );

    canvas.save();
    canvas.clipPath(topPath);

    for (int i = 0; i < 20; i++) {
      final sx = noise(i * 17 + 700);
      final sy = noise(i * 31 + 900);
      final sizeSeed = noise(i * 43 + 1100);
      final sign = noise(i * 59 + 1300) > 0.48 ? 1.0 : -1.0;

      final px = cx + (sx - 0.5) * rx * 1.55;
      final py = cy + (sy - 0.5) * ry * 1.55;
      final rw = rx * (0.10 + sizeSeed * 0.24);
      final rh = ry * (0.24 + sizeSeed * 0.60);

      final patch = Rect.fromCenter(
        center: Offset(px, py),
        width: rw * 2.0,
        height: rh * 2.0,
      );

      final strength = 0.018 + sizeSeed * 0.040;

      canvas.drawOval(
        patch,
        Paint()
          ..shader = RadialGradient(
            colors: [
              (sign > 0 ? const Color(0xffA7B0AD) : const Color(0xff10181D))
                  .withOpacity(strength),
              (sign > 0 ? const Color(0xff8A9694) : const Color(0xff202A30))
                  .withOpacity(strength * 0.48),
              Colors.transparent,
            ],
          ).createShader(patch)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.2),
      );
    }

    for (int i = 0; i < 48; i++) {
      final a = noise(i * 19 + 1500) * math.pi * 2.0;
      final radial = 0.12 + noise(i * 23 + 1700) * 0.78;
      final px = cx + math.cos(a) * rx * radial;
      final py = cy + math.sin(a) * ry * radial;
      final width = rx * (0.025 + noise(i * 29 + 1900) * 0.095);
      final height = ry * (0.10 + noise(i * 37 + 2100) * 0.34);
      final raised = noise(i * 41 + 2300) > 0.50;

      final patch = Rect.fromCenter(
        center: Offset(px, py),
        width: width * 2.0,
        height: height * 2.0,
      );

      canvas.drawOval(
        patch,
        Paint()
          ..shader = RadialGradient(
            colors: [
              (raised ? const Color(0xffAEB7B3) : const Color(0xff111A1F))
                  .withOpacity(raised ? 0.030 : 0.038),
              (raised ? const Color(0xff7D8987) : const Color(0xff273238))
                  .withOpacity(0.014),
              Colors.transparent,
            ],
          ).createShader(patch)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8),
      );
    }

    for (int i = 0; i < 18; i++) {
      final seed = i * 53 + 3000;
      final startX = cx - rx * (0.82 + noise(seed) * 0.18);
      final startY = cy + (noise(seed + 7) - 0.5) * ry * 1.25;
      final length = rx * (0.25 + noise(seed + 11) * 0.72);
      final slope = (noise(seed + 17) - 0.5) * ry * 0.75;

      final ridge = Path();
      ridge.moveTo(startX, startY);

      for (int p = 1; p <= 14; p++) {
        final d = p / 14.0;
        final x = startX + length * d;
        final broad = math.sin(d * 5.4 + i * 0.91) * ry * 0.15;
        final rough = math.sin(d * 17.0 + i * 2.7) * ry * 0.065;
        final y = startY + slope * d + broad + rough;
        ridge.lineTo(x, y);
      }

      canvas.drawPath(
        ridge.shift(const Offset(0, 1.15)),
        Paint()
          ..color = const Color(0xff10181D).withOpacity(0.045)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6 + noise(seed + 31) * 1.5
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.1),
      );

      canvas.drawPath(
        ridge.shift(const Offset(0, -0.75)),
        Paint()
          ..color = const Color(0xffAAB3AF).withOpacity(0.025)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.65 + noise(seed + 37) * 0.55
          ..strokeCap = StrokeCap.round,
      );
    }

    for (int i = 0; i < 85; i++) {
      final angle = noise(i * 47 + 4000) * math.pi * 2.0;
      final radial = math.sqrt(noise(i * 61 + 4200)) * 0.88;
      final px = cx + math.cos(angle) * rx * radial;
      final py = cy + math.sin(angle) * ry * radial;

      final r = 0.25 + noise(i * 71 + 4400) * 1.15;
      final deep = noise(i * 79 + 4600);

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(px, py),
          width: r * 2.2,
          height: r * 0.85,
        ),
        Paint()
          ..color = const Color(0xff10181D).withOpacity(0.025 + deep * 0.035)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.35),
      );

      if (r > 0.85) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(px - 0.35, py - 0.25),
            width: r * 1.5,
            height: r * 0.46,
          ),
          Paint()
            ..color = const Color(0xffB0B8B4).withOpacity(0.018)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.45,
        );
      }
    }

    for (int i = 0; i < 175; i++) {
      final angle = noise(i * 83 + 5000) * math.pi * 2.0;
      final radial = math.sqrt(noise(i * 97 + 5200)) * 0.91;
      final px = cx + math.cos(angle) * rx * radial;
      final py = cy + math.sin(angle) * ry * radial;
      final len = 0.6 + noise(i * 107 + 5400) * 2.4;

      canvas.drawLine(
        Offset(px, py),
        Offset(px + len * 0.75, py + math.sin(angle * 2.0) * 0.25),
        Paint()
          ..color =
              (noise(i * 113 + 5600) > 0.52
                      ? const Color(0xffAAB3AF)
                      : const Color(0xff111A1F))
                  .withOpacity(0.014 + noise(i * 127 + 5800) * 0.018)
          ..strokeWidth = 0.35 + noise(i * 131 + 6000) * 0.35
          ..strokeCap = StrokeCap.round,
      );
    }

    canvas.restore();

    canvas.drawPath(
      topPath,
      Paint()
        ..color = const Color(0xff637177).withOpacity(0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, h * 0.0021)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.45),
    );

    canvas.restore();
  }

  // ==============================================================
  // OTP INPUT BOXES - 3D REALISTIC STONE CUBOID
  // ==============================================================

  void _drawOTPBoxes(Canvas canvas, Size size, double horizon) {
    final w = size.width;
    final h = size.height;

    final cx = w * 0.50;
    final baseCy = h * 0.637;
    final phase = t * math.pi * 2.0;

    final slowPlatformPhase = platformAnimation * math.pi * 2.0;

    final microPhase = 0.5 + 0.5 * math.sin(slowPlatformPhase + 0.42);

    final floatY =
        math.sin(phase) * h * 0.018 +
        math.sin(phase * 2.0 + 0.9) * h * 0.007 +
        (microPhase - 0.5) * h * 0.0035;

    final floatX =
        math.sin(phase + 1.2) * w * 0.007 +
        math.sin(phase * 2.0 + 0.4) * w * 0.003 +
        (microPhase - 0.5) * w * 0.0016;

    final tiltX =
        math.sin(phase + 0.6) * (math.pi * 9.0 / 180) +
        math.sin(phase * 2.0 + 1.4) * (math.pi * 2.0 / 180) +
        (microPhase - 0.5) * (math.pi * 0.7 / 180);

    final tiltZ =
        math.sin(phase + 0.35) * (math.pi * 4.8 / 180) +
        math.sin(phase * 2.0 + 1.1) * (math.pi * 1.8 / 180) +
        math.sin(phase * 3.0 + 0.7) * (math.pi * 0.7 / 180) +
        (microPhase - 0.5) * (math.pi * 0.4 / 180);

    final breathe = 1.0 + math.sin(phase + 0.6) * 0.024;

    final cy = baseCy + floatY - h * 0.015;
    final rx = w * 0.235 * breathe;
    final ry = h * 0.060 * breathe;

    final perspectiveY = (1.0 - math.sin(tiltX).abs() * 0.16)
        .clamp(0.84, 1.0)
        .toDouble();
    final perspectiveX = (1.0 + math.sin(tiltX) * 0.055)
        .clamp(0.94, 1.06)
        .toDouble();
    final shearX = math.sin(tiltX) * 0.045;

    // ==============================================================
    // OTP HEADER - LARGER LOGO + LARGER TEXT + MORE SPACING
    // Only header sizing/spacing changed.
    // Water, rain, stone and floating animation remain unchanged.
    // ==============================================================

    final headerX = cx;
    final headerY = baseCy - h * 0.40;

    // Soft glow behind the larger logo.
    canvas.drawCircle(
      Offset(headerX, headerY),
      32,
      Paint()
        ..color = const Color(0xff79CFFF).withOpacity(0.11)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Larger outer circular lock rings.
    canvas.drawCircle(
      Offset(headerX, headerY),
      26,
      Paint()
        ..color = const Color(0xff8DD9FF).withOpacity(0.72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.35,
    );

    canvas.drawCircle(
      Offset(headerX, headerY),
      22,
      Paint()
        ..color = const Color(0xffB8E8FF).withOpacity(0.38)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.85,
    );

    // Bigger shield.
    final shield = Path()
      ..moveTo(headerX, headerY - 17.0)
      ..cubicTo(
        headerX + 10.2,
        headerY - 14.8,
        headerX + 14.0,
        headerY - 11.0,
        headerX + 14.0,
        headerY - 6.2,
      )
      ..cubicTo(
        headerX + 13.8,
        headerY + 5.0,
        headerX + 7.3,
        headerY + 13.0,
        headerX,
        headerY + 17.0,
      )
      ..cubicTo(
        headerX - 7.3,
        headerY + 13.0,
        headerX - 13.8,
        headerY + 5.0,
        headerX - 14.0,
        headerY - 6.2,
      )
      ..cubicTo(
        headerX - 14.0,
        headerY - 11.0,
        headerX - 10.2,
        headerY - 14.8,
        headerX,
        headerY - 17.0,
      )
      ..close();

    canvas.drawPath(
      shield,
      Paint()
        ..color = const Color(0xff8DD9FF).withOpacity(0.84)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.35
        ..strokeJoin = StrokeJoin.round,
    );

    // Bigger lock, centered inside the shield.
    final shackle = Path()
      ..moveTo(headerX - 6.8, headerY + 1.5)
      ..lineTo(headerX - 6.8, headerY - 6.0)
      ..quadraticBezierTo(headerX, headerY - 14.0, headerX + 6.8, headerY - 6.0)
      ..lineTo(headerX + 6.8, headerY + 1.5);

    canvas.drawPath(
      shackle,
      Paint()
        ..color = const Color(0xff8DD9FF).withOpacity(0.90)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.85
        ..strokeCap = StrokeCap.round,
    );

    final lockBody = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(headerX, headerY + 5.0),
        width: 15.5,
        height: 12.5,
      ),
      const Radius.circular(2.8),
    );

    canvas.drawRRect(
      lockBody,
      Paint()
        ..color = const Color(0xff58B8F0).withOpacity(0.20)
        ..style = PaintingStyle.fill,
    );

    canvas.drawRRect(
      lockBody,
      Paint()
        ..color = const Color(0xff8DD9FF).withOpacity(0.88)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.25,
    );

    // Bigger keyhole.
    canvas.drawCircle(
      Offset(headerX, headerY + 4.2),
      1.55,
      Paint()..color = const Color(0xffC3EDFF).withOpacity(0.96),
    );

    canvas.drawLine(
      Offset(headerX, headerY + 5.4),
      Offset(headerX, headerY + 8.6),
      Paint()
        ..color = const Color(0xffC3EDFF).withOpacity(0.96)
        ..strokeWidth = 1.15
        ..strokeCap = StrokeCap.round,
    );

    // 1st line - larger and with more gap from logo.
    final titlePainter = TextPainter(
      text: const TextSpan(
        text: 'Enter OTP',
        style: TextStyle(
          color: Color(0xffF1F4F5),
          fontSize: 27.0,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    titlePainter.paint(
      canvas,
      Offset(headerX - titlePainter.width / 2, headerY + 37),
    );

    // 2nd line - larger and with more vertical spacing.
    final subtitlePainter = TextPainter(
      text: const TextSpan(
        text: "We've sent a 6-digit OTP to",
        style: TextStyle(
          color: Color(0xffC4D0D4),
          fontSize: 17.0,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.05,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    subtitlePainter.paint(
      canvas,
      Offset(headerX - subtitlePainter.width / 2, headerY + 76),
    );

    // 3rd line - larger and with more vertical spacing.
    final phonePainter = TextPainter(
      text: const TextSpan(
        text: '+91 98765 43210',
        style: TextStyle(
          color: Color(0xff58B9EE),
          fontSize: 17.0,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    phonePainter.paint(
      canvas,
      Offset(headerX - phonePainter.width / 2, headerY + 108),
    );

    canvas.save();
    canvas.translate(cx + floatX, cy);
    canvas.rotate(tiltZ);
    canvas.scale(perspectiveX, perspectiveY);
    canvas.skew(shearX, 0.0);
    canvas.translate(-cx, -cy);

    const int boxCount = 6;
    const double boxWidth = 33;
    const double boxHeight = 39;
    const double boxDepth = 9.5;
    const double boxGap = 9;
    final double totalWidth = boxWidth * boxCount + boxGap * (boxCount - 1);
    final double startX = cx - totalWidth / 2;
    final double startY = cy - 30;

    for (int i = 0; i < boxCount; i++) {
      final boxX = startX + i * (boxWidth + boxGap);
      _drawOTPBox(canvas, boxX, startY, boxWidth, boxHeight, boxDepth, i);
    }

    canvas.restore();
  }

  void _drawOTPBox(
    Canvas canvas,
    double x,
    double y,
    double width,
    double height,
    double depth,
    int index,
  ) {
    final seed = index * 733 + 401;

    double j(int n) => (noise(seed + n) - 0.5);

    // Small rough offsets so the cuboid reads as hand-hewn stone
    // rather than a perfect machined box.
    final tl = Offset(j(1) * 1.7, j(2) * 1.35);
    final tr = Offset(j(3) * 1.7, j(4) * 1.35);
    final br = Offset(j(5) * 1.55, j(6) * 1.45);
    final bl = Offset(j(7) * 1.55, j(8) * 1.45);

    final variance = noise(seed + 20);

    final frontTopLeft = Offset(x + tl.dx, y + tl.dy);
    final frontTopRight = Offset(x + width + tr.dx, y + tr.dy);
    final frontBottomRight = Offset(x + width + br.dx, y + height + br.dy);
    final frontBottomLeft = Offset(x + bl.dx, y + height + bl.dy);

    final cornerRadius = math.min(7.8, math.min(width, height) * 0.22);
    final frontPath = Path()
      ..moveTo(frontTopLeft.dx + cornerRadius, frontTopLeft.dy)
      ..lineTo(frontTopRight.dx - cornerRadius, frontTopRight.dy)
      ..quadraticBezierTo(
        frontTopRight.dx,
        frontTopRight.dy,
        frontTopRight.dx,
        frontTopRight.dy + cornerRadius,
      )
      ..lineTo(frontBottomRight.dx, frontBottomRight.dy - cornerRadius)
      ..quadraticBezierTo(
        frontBottomRight.dx,
        frontBottomRight.dy,
        frontBottomRight.dx - cornerRadius,
        frontBottomRight.dy,
      )
      ..lineTo(frontBottomLeft.dx + cornerRadius, frontBottomLeft.dy)
      ..quadraticBezierTo(
        frontBottomLeft.dx,
        frontBottomLeft.dy,
        frontBottomLeft.dx,
        frontBottomLeft.dy - cornerRadius,
      )
      ..lineTo(frontTopLeft.dx, frontTopLeft.dy + cornerRadius)
      ..quadraticBezierTo(
        frontTopLeft.dx,
        frontTopLeft.dy,
        frontTopLeft.dx + cornerRadius,
        frontTopLeft.dy,
      )
      ..close();

    final frontRect = Rect.fromLTWH(x, y, width, height);

    // Contact shadow grounding the block onto the platform.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(x + width / 2 + depth * 0.4, y + height + 2),
        width: width * 1.15,
        height: 6,
      ),
      Paint()
        ..color = Colors.black.withOpacity(0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.2),
    );

    // ---- FRONT FACE : weathered stone gradient ----
    final stoneTop = Color.lerp(
      const Color(0xff5C6A63),
      const Color(0xff4A564F),
      variance,
    )!;
    final stoneMid = Color.lerp(
      const Color(0xff3A453F),
      const Color(0xff2E3833),
      variance,
    )!;
    final stoneBottom = Color.lerp(
      const Color(0xff20211E),
      const Color(0xff181C19),
      variance,
    )!;

    canvas.drawPath(
      frontPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            stoneTop.withOpacity(0.97),
            stoneMid.withOpacity(0.97),
            stoneBottom.withOpacity(0.98),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(frontRect),
    );

    // Directional light falling across the front face.
    canvas.drawPath(
      frontPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xffAEB9AC).withOpacity(0.16),
            Colors.transparent,
            Colors.black.withOpacity(0.18),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(frontRect),
    );

    // ---- HOLLOW NUMBER CAVITY : recessed into the stone ----
    // The dark inset is deliberately drawn on the front face so the
    // digit reads as carved/embedded inside the cuboid, not printed on it.
    final cavityInsetX = width * 0.155;
    final cavityInsetY = height * 0.135;
    final cavityRect = Rect.fromLTWH(
      x + cavityInsetX,
      y + cavityInsetY,
      width - cavityInsetX * 2.0,
      height - cavityInsetY * 2.0,
    );
    final cavityRadius = math.min(6.4, cavityRect.height * 0.28);
    final cavityPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(cavityRect, Radius.circular(cavityRadius)),
      );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        cavityRect.inflate(1.15),
        Radius.circular(cavityRadius + 1.0),
      ),
      Paint()
        ..color = const Color(0xff101613).withOpacity(0.58)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.7),
    );

    canvas.drawPath(
      cavityPath,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 1.15,
          colors: [
            const Color(0xff202923).withOpacity(0.72),
            const Color(0xff0C110E).withOpacity(0.92),
            const Color(0xff070A08).withOpacity(0.96),
          ],
          stops: const [0.0, 0.62, 1.0],
        ).createShader(cavityRect),
    );

    // Inner bevel: lower/right darkness makes the cavity feel physically deep.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        cavityRect.deflate(0.8),
        Radius.circular(math.max(2.0, cavityRadius - 0.8)),
      ),
      Paint()
        ..color = Colors.black.withOpacity(0.34)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.35,
    );

    canvas.drawLine(
      Offset(cavityRect.left + 2.0, cavityRect.top + 1.2),
      Offset(cavityRect.right - 3.0, cavityRect.top + 1.2),
      Paint()
        ..color = const Color(0xffB9C3B9).withOpacity(0.12)
        ..strokeWidth = 0.65
        ..strokeCap = StrokeCap.round,
    );

    // A few irregular dark chips around the cavity keep it from looking
    // like a perfectly manufactured screen cut-out.
    for (int c = 0; c < 7; c++) {
      final cc = noise(seed + 900 + c * 19);
      final cyy = noise(seed + 930 + c * 23);
      final px = cavityRect.left + cc * cavityRect.width;
      final py = cavityRect.top + cyy * cavityRect.height;
      final cr = 0.35 + noise(seed + 960 + c * 29) * 0.85;
      canvas.drawCircle(
        Offset(px, py),
        cr,
        Paint()..color = Colors.black.withOpacity(0.16),
      );
    }

    // ---- TOP FACE : lit stone facet ----
    final topLift = Offset(depth + j(9) * 1.4, -depth * 0.5 + j(10));
    final topLiftR = Offset(depth + j(11) * 1.4, -depth * 0.5 + j(12));

    final topPath = Path()
      ..moveTo(frontTopLeft.dx, frontTopLeft.dy)
      ..lineTo(frontTopLeft.dx + topLift.dx, frontTopLeft.dy + topLift.dy)
      ..lineTo(frontTopRight.dx + topLiftR.dx, frontTopRight.dy + topLiftR.dy)
      ..lineTo(frontTopRight.dx, frontTopRight.dy)
      ..close();

    canvas.drawPath(
      topPath,
      Paint()
        ..color = Color.lerp(
          const Color(0xff7E8A80),
          const Color(0xff69756B),
          variance,
        )!.withOpacity(0.92),
    );

    canvas.drawPath(
      topPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xffD3DBCE).withOpacity(0.22),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(x, y - depth, width + depth, depth)),
    );

    // ---- RIGHT FACE : shaded stone facet ----
    final rightLift = Offset(depth + j(13) * 1.4, -depth * 0.5 + j(14));
    final rightLiftB = Offset(depth + j(15) * 1.4, -depth * 0.5 + j(16));

    final rightPath = Path()
      ..moveTo(frontTopRight.dx, frontTopRight.dy)
      ..lineTo(frontTopRight.dx + rightLift.dx, frontTopRight.dy + rightLift.dy)
      ..lineTo(
        frontBottomRight.dx + rightLiftB.dx,
        frontBottomRight.dy + rightLiftB.dy,
      )
      ..lineTo(frontBottomRight.dx, frontBottomRight.dy)
      ..close();

    canvas.drawPath(
      rightPath,
      Paint()
        ..color = Color.lerp(
          const Color(0xff181F1B),
          const Color(0xff0F1512),
          variance,
        )!.withOpacity(0.95),
    );

    // Soft edge light where the top and right facets catch the sky.
    canvas.drawLine(
      Offset(
        frontTopLeft.dx + topLift.dx * 0.5,
        frontTopLeft.dy + topLift.dy * 0.5,
      ),
      Offset(
        frontTopRight.dx + topLiftR.dx * 0.5,
        frontTopRight.dy + topLiftR.dy * 0.5,
      ),
      Paint()
        ..color = const Color(0xffC7D0C4).withOpacity(0.28)
        ..strokeWidth = 0.9
        ..strokeCap = StrokeCap.round,
    );

    // ---- Surface texture: speckle + hairline cracks ----
    canvas.save();
    canvas.clipPath(frontPath);

    for (int i = 0; i < 18; i++) {
      final nx = noise(seed + i * 17 + 100);
      final ny = noise(seed + i * 23 + 200);
      final nd = noise(seed + i * 31 + 300);

      final px = x + nx * width;
      final py = y + ny * height;
      final r = 0.7 + nd * 2.0;

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(px, py),
          width: r * 1.8,
          height: r * 1.1,
        ),
        Paint()
          ..color = (nd > 0.5 ? Colors.black : const Color(0xffB6C0B3))
              .withOpacity(0.075 + nd * 0.085),
      );
    }

    for (int i = 0; i < 5; i++) {
      final sx = x + noise(seed + i * 41 + 500) * width;
      final sy = y + noise(seed + i * 53 + 600) * height * 0.35;

      final crack = Path()..moveTo(sx, sy);
      crack.lineTo(
        sx + (noise(seed + i * 61 + 700) - 0.5) * 7,
        sy + height * (0.35 + noise(seed + i * 71 + 800) * 0.4),
      );

      canvas.drawPath(
        crack,
        Paint()
          ..color = Colors.black.withOpacity(0.16)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5
          ..strokeCap = StrokeCap.round,
      );
    }

    canvas.restore();

    // Rough rim so the stone edge doesn't look razor-cut.
    canvas.drawPath(
      frontPath,
      Paint()
        ..color = const Color(0xff0A0E0B).withOpacity(0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );

    canvas.drawPath(
      frontPath,
      Paint()
        ..color = const Color(0xff8B958D).withOpacity(0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6,
    );
  }

  // ==============================================================
  // WATER LAPPING OVER THE LOWER EDGE OF THE FLOATING OTP STONES
  // ==============================================================

  // WATER RIPPLES AROUND THE STONE PLATFORM
  // ==============================================================

  void _drawStoneRipples(Canvas canvas, Size size, double horizon) {
    final w = size.width;
    final h = size.height;

    final cx = w * 0.50;
    final baseCy = h * 0.652;
    final phase = t * math.pi * 2.0;

    final slowPlatformPhase = platformAnimation * math.pi * 2.0;

    final microPhase = 0.5 + 0.5 * math.sin(slowPlatformPhase + 0.42);

    final floatY =
        math.sin(phase) * h * 0.018 +
        math.sin(phase * 2.0 + 0.9) * h * 0.007 +
        (microPhase - 0.5) * h * 0.0035;

    final floatX =
        math.sin(phase + 1.2) * w * 0.007 +
        math.sin(phase * 2.0 + 0.4) * w * 0.003 +
        (microPhase - 0.5) * w * 0.0016;

    final tiltX =
        math.sin(phase + 0.6) * (math.pi * 9.0 / 180) +
        math.sin(phase * 2.0 + 1.4) * (math.pi * 2.0 / 180) +
        (microPhase - 0.5) * (math.pi * 0.7 / 180);

    final tiltZ =
        math.sin(phase + 0.35) * (math.pi * 4.8 / 180) +
        math.sin(phase * 2.0 + 1.1) * (math.pi * 1.8 / 180) +
        math.sin(phase * 3.0 + 0.7) * (math.pi * 0.7 / 180) +
        (microPhase - 0.5) * (math.pi * 0.4 / 180);

    final breathe = 1.0 + math.sin(phase + 0.6) * 0.024;

    final cy = baseCy + floatY - h * 0.015;
    final rx = w * 0.235 * breathe;
    final ry = h * 0.060 * breathe;

    final perspectiveY = (1.0 - math.sin(tiltX).abs() * 0.16)
        .clamp(0.84, 1.0)
        .toDouble();

    final perspectiveX = (1.0 + math.sin(tiltX) * 0.055)
        .clamp(0.94, 1.06)
        .toDouble();

    final shearX = math.sin(tiltX) * 0.045;

    final waterRect = Path()
      ..addRect(Rect.fromLTWH(0, horizon, w, h - horizon));

    final leftShore = Path()
      ..moveTo(0, horizon - 3)
      ..cubicTo(
        w * 0.035,
        horizon - 1,
        w * 0.085,
        horizon + 1,
        w * 0.145,
        horizon + 7,
      )
      ..cubicTo(
        w * 0.205,
        horizon + 16,
        w * 0.235,
        h * 0.485,
        w * 0.195,
        h * 0.515,
      )
      ..cubicTo(
        w * 0.172,
        h * 0.535,
        w * 0.150,
        h * 0.552,
        w * 0.126,
        h * 0.575,
      )
      ..cubicTo(
        w * 0.105,
        h * 0.595,
        w * 0.118,
        h * 0.612,
        w * 0.082,
        h * 0.632,
      )
      ..cubicTo(w * 0.058, h * 0.646, w * 0.032, h * 0.658, 0, h * 0.672)
      ..lineTo(0, h)
      ..close();

    final rightShore = Path()
      ..moveTo(w, horizon - 3)
      ..cubicTo(
        w * 0.958,
        horizon - 1,
        w * 0.910,
        horizon + 2,
        w * 0.858,
        horizon + 8,
      )
      ..cubicTo(
        w * 0.805,
        horizon + 15,
        w * 0.770,
        h * 0.482,
        w * 0.808,
        h * 0.510,
      )
      ..cubicTo(
        w * 0.833,
        h * 0.532,
        w * 0.852,
        h * 0.550,
        w * 0.878,
        h * 0.572,
      )
      ..cubicTo(
        w * 0.900,
        h * 0.591,
        w * 0.887,
        h * 0.610,
        w * 0.922,
        h * 0.630,
      )
      ..cubicTo(w * 0.949, h * 0.646, w * 0.977, h * 0.658, w, h * 0.670)
      ..lineTo(w, h)
      ..close();

    var waterOnly = Path.combine(
      PathOperation.difference,
      waterRect,
      leftShore,
    );

    waterOnly = Path.combine(PathOperation.difference, waterOnly, rightShore);

    List<Offset> makeStonePoints({
      required double xRadius,
      required double yRadius,
      required double roughness,
      required double seed,
    }) {
      final points = <Offset>[];

      for (int i = 0; i < 128; i++) {
        final a = (i / 128) * math.pi * 2.0;

        final broad = math.sin(i * 0.73 + seed) * 0.55;
        final medium = math.sin(i * 1.91 + seed * 1.7) * 0.30;
        final fine = math.sin(i * 4.73 + seed * 0.43) * 0.15;

        final n = 1.0 + roughness * (broad + medium + fine);

        points.add(
          Offset(
            cx + math.cos(a) * xRadius * n,
            cy + math.sin(a) * yRadius * n,
          ),
        );
      }

      return points;
    }

    Path smoothClosedPath(List<Offset> points) {
      final path = Path();
      final n = points.length;

      final first = Offset(
        (points[n - 1].dx + points[0].dx) * 0.5,
        (points[n - 1].dy + points[0].dy) * 0.5,
      );

      path.moveTo(first.dx, first.dy);

      for (int i = 0; i < n; i++) {
        final current = points[i];
        final next = points[(i + 1) % n];

        final mid = Offset(
          (current.dx + next.dx) * 0.5,
          (current.dy + next.dy) * 0.5,
        );

        path.quadraticBezierTo(current.dx, current.dy, mid.dx, mid.dy);
      }

      path.close();
      return path;
    }

    Offset transformStonePoint(Offset p) {
      final localX = p.dx - cx;
      final localY = p.dy - cy;

      final sx = localX * perspectiveX + localY * shearX;
      final sy = localY * perspectiveY;

      final cosZ = math.cos(tiltZ);
      final sinZ = math.sin(tiltZ);

      return Offset(
        cx + sx * cosZ - sy * sinZ + floatX,
        cy + sx * sinZ + sy * cosZ,
      );
    }

    final rawStonePoints = makeStonePoints(
      xRadius: rx,
      yRadius: ry,
      roughness: 0.060,
      seed: 2.4,
    );

    final transformedStonePoints = rawStonePoints
        .map(transformStonePoint)
        .toList();

    final stoneTopPath = smoothClosedPath(transformedStonePoints);

    waterOnly = Path.combine(PathOperation.difference, waterOnly, stoneTopPath);

    canvas.save();
    canvas.clipPath(waterOnly);

    final sourceX = cx + floatX;
    final sourceY = cy;

    List<Offset> makeRipplePoints({
      required double expansion,
      required int ring,
      required double timeScale,
      required double deformationAmount,
    }) {
      final points = <Offset>[];

      for (int i = 0; i < transformedStonePoints.length; i++) {
        final source = transformedStonePoints[i];

        final dx = source.dx - sourceX;
        final dy = source.dy - sourceY;

        final a = (i / transformedStonePoints.length) * math.pi * 2.0;

        final broad =
            math.sin(a * 2.15 + ring * 0.77 + t * timeScale) *
            deformationAmount;

        final medium =
            math.sin(a * 5.30 - ring * 0.51 - t * timeScale * 0.71 + 1.3) *
            deformationAmount *
            0.43;

        final fine =
            math.sin(a * 9.70 + ring * 0.33 + t * timeScale * 0.42) *
            deformationAmount *
            0.18;

        final directional =
            math.cos(a - tiltZ) *
            math.sin(tiltX) *
            0.018 *
            math.min(expansion, 3.6);

        final deformation = 1.0 + broad + medium + fine + directional;

        final localX = dx * expansion * deformation;
        final localY = dy * expansion * deformation;

        final driftX =
            math.sin(a * 1.35 + t * 0.46 + ring) * 0.55 * (expansion - 1.0);

        final driftY =
            math.cos(a * 1.80 - t * 0.38 + ring * 0.7) *
            0.20 *
            (expansion - 1.0);

        points.add(
          Offset(sourceX + localX + driftX, sourceY + localY + driftY),
        );
      }

      return points;
    }

    const int ringCount = 18;

    for (int ring = 0; ring < ringCount; ring++) {
      final seed = ring * 37 + 19;

      final speed = 0.72 + noise(seed) * 0.12 + noise(seed + 11) * 0.035;

      final phaseOffset = ring / ringCount + noise(seed + 7) * 0.018;

      var p = (t * speed + phaseOffset) % 1.0;
      if (p < 0) p += 1.0;

      final expansion = 1.008 + p * (1.28 + noise(seed + 31) * 0.18);

      final radiusFade = math.pow((1.0 - p).clamp(0.0, 1.0), 4.2).toDouble();

      final birthFade = (p / 0.105).clamp(0.0, 1.0).toDouble();

      final opacity =
          (0.175 * radiusFade * birthFade * (0.88 + noise(seed + 43) * 0.12))
              .clamp(0.0, 0.19);

      if (opacity < 0.0007) continue;

      final points = makeRipplePoints(
        expansion: expansion,
        ring: ring + 20,
        timeScale: speed * 2.8,
        deformationAmount: 0.006 + noise(seed + 51) * 0.006,
      );

      canvas.drawPath(
        smoothClosedPath(points),
        Paint()
          ..color = const Color(0xffD9F2F3).withOpacity(opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = (1.05 + (1.0 - p) * 0.38 + noise(seed + 8) * 0.08)
              .clamp(0.85, 1.25)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );

      if (p > 0.035) {
        final softPoints = makeRipplePoints(
          expansion: expansion + 0.016,
          ring: ring + 70,
          timeScale: speed * 2.2,
          deformationAmount: 0.0045,
        );

        canvas.drawPath(
          smoothClosedPath(softPoints),
          Paint()
            ..color = const Color(0xffA9DADD).withOpacity(opacity * 0.20)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.48 + (1.0 - p) * 0.16
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.42),
        );
      }
    }

    const int secondaryRingCount = 10;

    for (int ring = 0; ring < secondaryRingCount; ring++) {
      final seed = 401 + ring * 53;
      final speed = 0.58 + noise(seed) * 0.10;
      final phaseOffset = ring / secondaryRingCount + noise(seed + 9) * 0.022;

      var p = (t * speed + phaseOffset) % 1.0;
      if (p < 0) p += 1.0;

      final expansion = 1.035 + p * (1.16 + noise(seed + 14) * 0.14);

      final fade = math.pow((1.0 - p).clamp(0.0, 1.0), 4.0).toDouble();
      final birth = (p / 0.12).clamp(0.0, 1.0).toDouble();

      final alpha = (0.050 * fade * birth * (0.86 + noise(seed + 20) * 0.14))
          .clamp(0.0, 0.058);

      if (alpha < 0.00045) continue;

      final points = makeRipplePoints(
        expansion: expansion,
        ring: ring + 160,
        timeScale: speed * 2.2,
        deformationAmount: 0.005 + noise(seed + 27) * 0.004,
      );

      canvas.drawPath(
        smoothClosedPath(points),
        Paint()
          ..color = const Color(0xffC4E9EA).withOpacity(alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = (0.52 + (1.0 - p) * 0.15 + noise(seed + 27) * 0.04)
              .clamp(0.46, 0.72)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.32),
      );
    }

    final contactPulse = 0.5 + 0.5 * math.sin(phase * 1.15);

    final contactPoints = <Offset>[];

    for (int i = 0; i < transformedStonePoints.length; i++) {
      final source = transformedStonePoints[i];
      final dx = source.dx - sourceX;
      final dy = source.dy - sourceY;
      final a = (i / transformedStonePoints.length) * math.pi * 2.0;

      final wave =
          math.sin(a * 4.8 + phase * 1.25) * 0.007 +
          math.sin(a * 9.8 - phase * 0.78) * 0.0035;

      contactPoints.add(
        Offset(
          sourceX + dx * (1.006 + wave) - math.cos(a) * 0.8 * contactPulse,
          sourceY + dy * (1.006 + wave) - math.sin(a) * 0.25 * contactPulse,
        ),
      );
    }

    final contactPath = smoothClosedPath(contactPoints);

    canvas.drawPath(
      contactPath,
      Paint()
        ..color = const Color(
          0xffD5ECEE,
        ).withOpacity(0.038 + contactPulse * 0.018)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.82
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.55),
    );

    for (int segment = 0; segment < 18; segment++) {
      final seed = segment * 137 + 701;
      final centerIndex = (noise(seed) * transformedStonePoints.length).floor();

      final span = 2 + (noise(seed + 13) * 7).floor();

      final points = <Offset>[];

      for (int j = 0; j <= span; j++) {
        final index = (centerIndex + j) % transformedStonePoints.length;

        final source = transformedStonePoints[index];
        final dx = source.dx - sourceX;
        final dy = source.dy - sourceY;

        final a = (index / transformedStonePoints.length) * math.pi * 2.0;

        final localProgress = (t * 0.24 + noise(seed + 27) * 0.72) % 1.0;

        final scale = 1.45 + localProgress * 1.85;

        final shimmer =
            0.35 + 0.65 * math.max(0.0, math.sin(localProgress * math.pi));

        points.add(
          Offset(
            sourceX + dx * scale + math.sin(a * 2.0 + phase) * 0.35,
            sourceY + dy * scale + math.cos(a * 2.0 - phase) * 0.18,
          ),
        );

        if (points.length > 1) {
          canvas.drawLine(
            points[points.length - 2],
            points[points.length - 1],
            Paint()
              ..color = Colors.white.withOpacity(0.075 * shimmer)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.62
              ..strokeCap = StrokeCap.round
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.42),
          );
        }
      }
    }

    canvas.restore();
  }

  // ==============================================================
  // RAIN
  // ==============================================================

  void _drawRainImpacts(Canvas canvas, Size size, double horizon) {
    for (int i = 0; i < 175; i++) {
      final xSeed = noise(i * 37 + 11);

      final depthSeed = noise(i * 61 + 17);

      final speedSeed = noise(i * 83 + 23);

      final depth = 0.06 + depthSeed * 0.94;

      final y =
          horizon + math.pow(depth, 1.18).toDouble() * (size.height - horizon);

      final x =
          xSeed * size.width +
          math.sin(t * (0.8 + speedSeed * 1.5) + i * 1.91) * (2 + depth * 10);

      final phase = (t * (1.4 + speedSeed * 2.6) + i * 0.739) % 1.0;

      final radius1 = 1.0 + phase * (2.5 + depth * 7);

      final opacity1 = (1.0 - phase) * (0.12 + depth * 0.07);

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: radius1 * (2.8 + depth * 2.0),
          height: radius1 * (0.65 + depth * 0.18),
        ),
        Paint()
          ..color = const Color(0xffE2ECE9).withOpacity(opacity1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.55 + depth * 0.6,
      );

      if (phase > 0.16) {
        final p2 = (phase - 0.16) / 0.84;

        final radius2 = 0.5 + p2 * (4.0 + depth * 10);

        final opacity2 = (1.0 - p2) * (0.075 + depth * 0.045);

        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(x, y),
            width: radius2 * (3.1 + depth * 2.4),
            height: radius2 * (0.55 + depth * 0.15),
          ),
          Paint()
            ..color = const Color(0xffD6E3E0).withOpacity(opacity2)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.45 + depth * 0.45,
        );
      }

      if (phase > 0.32) {
        final p3 = (phase - 0.32) / 0.68;

        final radius3 = p3 * (6 + depth * 12);

        final opacity3 = (1.0 - p3) * (0.035 + depth * 0.025);

        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(x, y),
            width: radius3 * 3.2,
            height: radius3 * 0.45,
          ),
          Paint()
            ..color = const Color(0xffC9D9D6).withOpacity(opacity3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.4,
        );
      }

      if (phase < 0.20) {
        final splash = 1.0 - phase / 0.20;

        canvas.drawLine(
          Offset(x, y),
          Offset(x - 0.4, y - (1.5 + splash * (2.5 + depth * 4))),
          Paint()
            ..color = const Color(
              0xffE4EEEB,
            ).withOpacity(splash * (0.14 + depth * 0.08))
            ..strokeWidth = 0.55 + depth * 0.35
            ..strokeCap = StrokeCap.round,
        );

        canvas.drawLine(
          Offset(x, y),
          Offset(
            x - (1 + splash * (2 + depth * 3)),
            y - splash * (0.7 + depth * 1.5),
          ),
          Paint()
            ..color = const Color(0xffE0EBE8).withOpacity(splash * 0.10)
            ..strokeWidth = 0.45
            ..strokeCap = StrokeCap.round,
        );

        canvas.drawLine(
          Offset(x, y),
          Offset(
            x + (1 + splash * (2 + depth * 3)),
            y - splash * (0.7 + depth * 1.5),
          ),
          Paint()
            ..color = const Color(0xffE0EBE8).withOpacity(splash * 0.10)
            ..strokeWidth = 0.45
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  void _drawRain(Canvas canvas, Size size, double horizon) {
    for (int i = 0; i < 220; i++) {
      final xSeed = noise(i * 17 + 300);

      final ySeed = noise(i * 31 + 500);

      final speedSeed = noise(i * 53 + 700);

      final x = xSeed * (size.width + 100) - 50;

      final speed = 0.35 + speedSeed * 0.35;

      final y = ((ySeed + t * speed) % 1.0) * (size.height + 80) - 40;

      final length = 2.0 + speedSeed * 4.0;

      canvas.drawLine(
        Offset(x, y),
        Offset(x - 0.7, y + length),
        Paint()
          ..color = const Color(
            0xffAFCBD0,
          ).withOpacity(0.045 + speedSeed * 0.025)
          ..strokeWidth = 0.65
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.7),
      );

      canvas.drawLine(
        Offset(x - 0.1, y + 0.5),
        Offset(x - 0.7, y + length - 0.5),
        Paint()
          ..color = const Color(0xffD4E5E8).withOpacity(0.09 + speedSeed * 0.05)
          ..strokeWidth = 0.35
          ..strokeCap = StrokeCap.round,
      );
    }

    for (int i = 0; i < 280; i++) {
      final xSeed = noise(i * 23 + 900);

      final ySeed = noise(i * 47 + 1200);

      final speedSeed = noise(i * 67 + 1500);

      final xStart = xSeed * (size.width + 140) - 70;

      final speed = 0.9 + speedSeed * 0.9;

      final y = ((ySeed + t * speed) % 1.0) * (size.height + 130) - 65;

      final wind = 5.0 + speedSeed * 8.0;

      final x = xStart + wind * (y / size.height);

      final length = 4.5 + speedSeed * 8.0;

      canvas.drawLine(
        Offset(x, y),
        Offset(x - 1.6, y + length),
        Paint()
          ..color = const Color(
            0xff83AEB7,
          ).withOpacity(0.055 + speedSeed * 0.035)
          ..strokeWidth = 1.45 + speedSeed * 0.45
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0),
      );

      canvas.drawLine(
        Offset(x - 0.25, y + 0.6),
        Offset(x - 1.45, y + length - 0.7),
        Paint()
          ..color = const Color(
            0xffD9E9EA,
          ).withOpacity(0.10 + speedSeed * 0.055)
          ..strokeWidth = 0.42 + speedSeed * 0.22
          ..strokeCap = StrokeCap.round,
      );

      canvas.drawCircle(
        Offset(x - 0.15, y + 0.8),
        0.55 + speedSeed * 0.3,
        Paint()
          ..color = const Color(
            0xffC7E0E4,
          ).withOpacity(0.07 + speedSeed * 0.045)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.35),
      );
    }

    for (int i = 0; i < 110; i++) {
      final xSeed = noise(i * 91 + 1900);

      final ySeed = noise(i * 37 + 2200);

      final speedSeed = noise(i * 113 + 2500);

      final xStart = xSeed * (size.width + 180) - 90;

      final speed = 1.15 + speedSeed * 1.0;

      final y = ((ySeed + t * speed) % 1.0) * (size.height + 180) - 90;

      final x = xStart + 13 * (y / size.height);

      final length = 9 + speedSeed * 13;

      canvas.drawLine(
        Offset(x, y),
        Offset(x - 3.0, y + length),
        Paint()
          ..color = const Color(
            0xff8EB9C0,
          ).withOpacity(0.065 + speedSeed * 0.045)
          ..strokeWidth = 2.0 + speedSeed * 0.7
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.4),
      );

      canvas.drawLine(
        Offset(x, y),
        Offset(x - 3.0, y + length),
        Paint()
          ..color = const Color(
            0xffC8DEE1,
          ).withOpacity(0.10 + speedSeed * 0.065)
          ..strokeWidth = 0.65 + speedSeed * 0.4
          ..strokeCap = StrokeCap.round,
      );

      canvas.drawLine(
        Offset(x - 0.3, y + 0.8),
        Offset(x - 2.5, y + length * 0.72),
        Paint()
          ..color = const Color(
            0xffE4F0F1,
          ).withOpacity(0.09 + speedSeed * 0.055)
          ..strokeWidth = 0.3
          ..strokeCap = StrokeCap.round,
      );
    }

    for (int i = 30; i < 58; i++) {
      final xSeed = noise(i * 173 + 3000);

      final ySeed = noise(i * 67 + 3300);

      final phase = (ySeed + t * (1.1 + noise(i * 19) * 0.6)) % 1.0;

      final x = xSeed * size.width;

      final y = phase * (size.height + 100) - 50;

      final dropLength = 13 + noise(i * 51) * 16;

      canvas.drawLine(
        Offset(x, y),
        Offset(x - 3.8, y + dropLength),
        Paint()
          ..color = const Color(0xff9EC3C8).withOpacity(0.075)
          ..strokeWidth = 2.0 + noise(i * 23) * 0.7
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
      );

      canvas.drawLine(
        Offset(x, y),
        Offset(x - 3.4, y + dropLength),
        Paint()
          ..color = const Color(0xffD6E8EA).withOpacity(0.11)
          ..strokeWidth = 0.55
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  // ==============================================================
  // FOREGROUND WATER DEPTH
  // ==============================================================

  void _drawForeground(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      0,
      size.height * 0.66,
      size.width,
      size.height * 0.34,
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Color(0x0E00040A),
            Color(0x26000309),
            Color(0x65000208),
          ],
          stops: [0, 0.23, 0.58, 1],
        ).createShader(rect),
    );

    for (int i = 0; i < 13; i++) {
      final d = i / 12;

      final base = size.height * 0.69 + d * size.height * 0.31;

      final amp = 12 + d * 58;

      final direction = noise(i * 121) > 0.5 ? 1.0 : -1.0;

      final speed = 1.3 + noise(i * 41) * 2.7;

      final path = Path()..moveTo(-250, base);

      for (double x = -250; x <= size.width + 250; x += 5) {
        final p1 = x * (0.006 - d * 0.0013) + i * 1.8 + direction * t * speed;

        final p2 = x * 0.017 - t * 1.5 + i;

        final noiseShape = smoothNoise(x * 0.012, i * 0.3 + t * 0.08);

        path.lineTo(
          x,
          base +
              wave(p1) * amp +
              math.sin(p2) * amp * 0.22 +
              noiseShape * amp * 0.09,
        );
      }

      path
        ..lineTo(size.width + 250, size.height)
        ..lineTo(-250, size.height)
        ..close();

      canvas.drawPath(
        path,
        Paint()
          ..color = Color.lerp(
            const Color(0xff082030),
            const Color(0xff061722),
            d,
          )!.withOpacity(0.065 + d * 0.17)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.4),
      );

      final edge = Path()..moveTo(-250, base);

      for (double x = -250; x <= size.width + 250; x += 7) {
        final p = x * (0.006 - d * 0.0013) + i * 1.8 + direction * t * speed;

        edge.lineTo(x, base + wave(p) * amp);
      }

      canvas.drawPath(
        edge,
        Paint()
          ..color = const Color(0xff2C6885).withOpacity(0.014 + (1 - d) * 0.032)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8 + d * 1.8
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  // ==============================================================
  // FINAL VIGNETTE
  // ==============================================================

  void _drawVignette(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.85,
          colors: [Colors.transparent, Colors.black.withOpacity(0.13)],
          stops: const [0.55, 1],
        ).createShader(rect),
    );

    final topRect = Rect.fromLTWH(0, 0, size.width, size.height * 0.35);

    canvas.drawRect(
      topRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.10), Colors.transparent],
        ).createShader(topRect),
    );

    final bottomRect = Rect.fromLTWH(
      0,
      size.height * 0.82,
      size.width,
      size.height * 0.18,
    );

    canvas.drawRect(
      bottomRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.12)],
        ).createShader(bottomRect),
    );
  }

  @override
  bool shouldRepaint(covariant RealisticOceanPainter oldDelegate) {
    return oldDelegate.waterClock != waterClock ||
        oldDelegate.platformClock != platformClock;
  }
}

// ================================================================
// FLOATING 3D LOGIN BUTTON + WATER EFFECTS
// Reused from the standalone Login button design.
// ================================================================

class LoginWaterButton extends StatelessWidget {
  final ValueListenable<double> clock;
  final AnimationController pressController;
  final int rippleKey;

  final VoidCallback onTapDown;
  final VoidCallback onTapUp;

  const LoginWaterButton({
    super.key,
    required this.clock,
    required this.pressController,
    required this.rippleKey,
    required this.onTapDown,
    required this.onTapUp,
  });

  @override
  Widget build(BuildContext context) {
    // The expensive button visuals are created once. Only the outer transform
    // is rebuilt every frame. The water painters repaint directly from `clock`.
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 42,
          child: CustomPaint(
            size: const Size(330, 90),
            painter: LoginReflectionPainter(clock),
          ),
        ),

        Positioned(
          top: -55,
          child: CustomPaint(
            size: const Size(400, 180),
            painter: LoginRipplePainter(clock, rippleKey),
          ),
        ),

        AnimatedBuilder(
          animation: Listenable.merge([clock, pressController]),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => onTapDown(),
            onTapUp: (_) => onTapUp(),
            onTapCancel: onTapUp,
            child: SizedBox(
              width: 280,
              height: 90,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // ==================================================
                  // DEEP FLOATING SHADOW
                  // ==================================================
                  Positioned(
                    left: 15,
                    right: 15,
                    bottom: 0,
                    child: Transform.scale(
                      scaleX: 1.0,
                      scaleY: .65,
                      child: Container(
                        height: 28,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(80),
                          gradient: RadialGradient(
                            colors: [
                              Colors.black.withOpacity(.48),
                              Colors.black.withOpacity(.22),
                              Colors.transparent,
                            ],
                            stops: const [0, .48, 1],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ==================================================
                  // LOWER 3D CYLINDER
                  // ==================================================
                  Positioned(
                    left: 1,
                    right: 1,
                    top: 17,
                    bottom: 5,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),

                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xff9AC8D8),
                            Color(0xff5D91A4),
                            Color(0xff32677C),
                            Color(0xff123C4D),
                            Color(0xff082B3B),
                          ],
                          stops: [0, .20, .50, .78, 1],
                        ),

                        border: Border.all(
                          color: const Color(0xff9EE5F2),
                          width: 1.2,
                        ),

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.40),
                            blurRadius: 12,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),

                      child: Stack(
                        children: [
                          // DARK LOWER EDGE
                          Positioned(
                            left: 15,
                            right: 15,
                            bottom: 3,
                            child: Container(
                              height: 9,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withOpacity(.05),
                                    Colors.black.withOpacity(.30),
                                    Colors.black.withOpacity(.05),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // CYAN SIDE GLOW
                          Positioned(
                            left: 20,
                            right: 20,
                            bottom: 9,
                            child: Container(
                              height: 2,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: const Color(0xff74D9EE).withOpacity(.40),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ==================================================
                  // MAIN TOP FACE
                  // ==================================================
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    bottom: 18,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(48),

                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xffB8E1EC),
                            Color(0xffEAF8FC),
                            Color(0xffffffff),
                            Color(0xffF6FDFF),
                            Color(0xffA8D8E7),
                          ],
                          stops: [0, .20, .48, .76, 1],
                        ),

                        border: Border.all(color: Colors.white, width: 1.7),

                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(.85),
                            blurRadius: 6,
                            spreadRadius: -1,
                            offset: const Offset(0, -2),
                          ),
                          BoxShadow(
                            color: const Color(0xff267995).withOpacity(.42),
                            blurRadius: 9,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),

                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // =================================================
                          // TOP GLASS HIGHLIGHT
                          // =================================================
                          Positioned(
                            left: 28,
                            right: 28,
                            top: 4,
                            child: Container(
                              height: 7,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    const Color(0xff2D7793).withOpacity(.20),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // =================================================
                          // BOTTOM GLOSS
                          // =================================================
                          Positioned(
                            left: 35,
                            right: 35,
                            bottom: 5,
                            child: Container(
                              height: 12,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.white.withOpacity(.95),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // =================================================
                          // CENTRAL LOGIN CONTENT
                          // =================================================
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Verify OTP',
                                  style: TextStyle(
                                    color: Color(0xff1263A2),
                                    fontSize: 21,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: .2,
                                    shadows: [
                                      Shadow(
                                        color: Colors.white,
                                        blurRadius: 3,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 48),

                                AnimatedBuilder(
                                  animation: pressController,
                                  builder: (context, _) {
                                    final p = Curves.easeInOutCubic.transform(
                                      pressController.value,
                                    );

                                    return Transform.translate(
                                      offset: Offset(p * 2.4, 0),
                                      child: const Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Color(0xff1263A2),
                                        size: 29,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),

                          // =================================================
                          // INNER LIGHT
                          // =================================================
                          Positioned(
                            left: 20,
                            right: 20,
                            top: 12,
                            child: IgnorePointer(
                              child: Container(
                                height: 1,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.white.withOpacity(.75),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ==================================================
                  // WATERLINE OVER BUTTON
                  // ==================================================
                  Positioned(
                    left: 17,
                    right: 17,
                    bottom: 15,
                    child: IgnorePointer(
                      child: CustomPaint(
                        size: const Size(246, 10),
                        painter: LoginWaterlinePainter(clock),
                      ),
                    ),
                  ),

                  // ==================================================
                  // FRONT CONTACT FOAM
                  // ==================================================
                  Positioned(
                    top: 50,
                    child: IgnorePointer(
                      child: CustomPaint(
                        size: const Size(320, 46),
                        painter: LoginContactFoamPainter(clock),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          builder: (context, child) {
            final elapsed = clock.value;

            // Same overall speed as before, but the wobble frequencies are
            // now golden-ratio spaced (0.618 factor) instead of exact
            // halves (0.62 -> 0.31 -> 0.145, 0.34 -> 0.16 -> 0.075).
            // Exact-half frequencies are harmonics of each other, so their
            // combined sine waves periodically reinforce and cancel out
            // (a "beat" pattern) — the combined velocity dips toward zero
            // at regular intervals, which is exactly what reads as the
            // button going "ruka hua" (stuck) before jumping ahead again.
            // Golden-ratio spacing has no common resonance, so the glide
            // stays continuous with no stall points.
            // Continuous float – frequencies spaced by golden-ratio multiples
            // so their combined velocity never approaches zero (no stall).
            // Faster continuous clock with non-harmonic frequencies.
            // This keeps the button gliding instead of reaching regular
            // near-zero velocity points that can look like a brief stop.
            final t = elapsed * 1.08;

            final floatY =
                math.sin(t * 0.618) * 4.75 +
                math.sin(t * 0.3817 + 1.1) * 1.55 +
                math.sin(t * 0.2361 + 2.3) * 0.60 +
                math.sin(t * 0.1459 + 0.7) * 0.25;

            final floatX =
                math.sin(t * 0.3817 + 0.9) * 1.80 +
                math.sin(t * 0.2361 + 2.4) * 0.70 +
                math.sin(t * 0.1459 + 0.5) * 0.30 +
                math.sin(t * 0.0902 + 1.8) * 0.13;

            // Very soft continuous rocking.
            // Subtle 3D rocking: X + Y + Z axes.
            // Kept intentionally small so the original button shape stays
            // exactly the same while the floating tilt becomes noticeable.
            final tiltX =
                -(math.pi * 43.0 / 180) +
                math.sin(t * 0.472 + 0.6) * (math.pi * 2.55 / 180) +
                math.sin(t * 0.2917 + 1.5) * (math.pi * 0.72 / 180) +
                math.sin(t * 0.1803 + 2.1) * (math.pi * 0.24 / 180);

            final tiltY =
                math.sin(t * 0.347 + 1.15) * (math.pi * 1.35 / 180) +
                math.sin(t * 0.2113 + 2.0) * (math.pi * 0.48 / 180) +
                math.sin(t * 0.1327 + 0.4) * (math.pi * 0.18 / 180);

            final tiltZ =
                math.sin(t * 0.3817 + 0.4) * (math.pi * 1.55 / 180) +
                math.sin(t * 0.2361 + 1.2) * (math.pi * 0.54 / 180) +
                math.sin(t * 0.1459 + 0.8) * (math.pi * 0.21 / 180);

            final press = Curves.easeInOutCubic.transform(
              pressController.value,
            );

            // Tiny press depth: it should feel like the button is compressing
            // into the water, not jumping downward.
            final pressDepth = press * 1.65;

            return Transform.translate(
              offset: Offset(floatX, floatY + pressDepth),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0028)
                  ..rotateX(tiltX)
                  ..rotateY(tiltY)
                  ..rotateZ(tiltZ),
                child: child,
              ),
            );
          },
        ),

        Positioned(
          bottom: -32,
          left: 0,
          right: 0,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  // Change phone number action
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  child: Text(
                    'Change phone number',
                    style: TextStyle(
                      color: Color(0xffB9D7DE),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: .15,
                      decoration: TextDecoration.underline,
                      decorationColor: Color(0xffB9D7DE),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class LoginReflectionPainter extends CustomPainter {
  final ValueListenable<double> clock;

  double get elapsed => clock.value;

  LoginReflectionPainter(this.clock) : super(repaint: clock);

  @override
  void paint(Canvas canvas, Size size) {
    final t = elapsed * math.pi * 2;

    final pulse = .5 + .5 * math.sin(t * 1.15);

    final center = Offset(size.width / 2, size.height * .52);

    final rect = Rect.fromCenter(
      center: center,
      width: 250 + pulse * 18,
      height: 32 + pulse * 7,
    );

    canvas.drawOval(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xffA4F1EC).withOpacity(.22),
            const Color(0xff55C6D0).withOpacity(.12),
            const Color(0xff197B8A).withOpacity(.035),
            Colors.transparent,
          ],
          stops: const [0, .35, .70, 1],
        ).createShader(rect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Thin reflected water lines

    for (int i = 0; i < 18; i++) {
      final p = i / 17;

      final y = center.dy - 14 + p * 28;

      final width = 35 + math.sin(p * math.pi) * 115;

      final drift = math.sin(t * 1.3 + i * .7) * (2 + p * 6);

      final opacity = (.025 + math.sin(t * 1.7 + i) * .015).clamp(.01, .07);

      canvas.drawLine(
        Offset(center.dx - width / 2 + drift, y),
        Offset(center.dx + width / 2 + drift, y + math.sin(t * 2 + i) * 1.2),
        Paint()
          ..color = Colors.white.withOpacity(opacity)
          ..strokeWidth = .7
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant LoginReflectionPainter oldDelegate) {
    return false;
  }
}

// ================================================================
// LARGE CONCENTRIC WATER RIPPLES
// ================================================================

class LoginRipplePainter extends CustomPainter {
  final ValueListenable<double> clock;
  final int rippleKey;

  LoginRipplePainter(this.clock, this.rippleKey) : super(repaint: clock);

  static const int ringCount = 7;
  static const int pointsPerRing = 72;
  static const double aspect = 0.235;

  double _hash(double x) {
    final v = math.sin(x * 12.9898 + 78.233) * 43758.5453;
    return v - v.floorToDouble();
  }

  double _signed(double x) => _hash(x) * 2.0 - 1.0;

  double _smooth(double x) => x * x * (3.0 - 2.0 * x);

  double _smoother(double x) => x * x * x * (x * (x * 6.0 - 15.0) + 10.0);

  @override
  void paint(Canvas canvas, Size size) {
    final elapsed = clock.value;
    // Slow, continuous movement specifically for Verify OTP ripples.
    final time = elapsed * math.pi * 2.0 * 0.52;

    final center = Offset(size.width * 0.5, size.height * 0.5);

    for (int ring = 0; ring < ringCount; ring++) {
      final speed = 0.0875 + ring * 0.011 + _hash(ring * 17.37) * 0.007;

      final raw = elapsed * speed + ring * 0.143 + _hash(ring * 9.73) * 0.55;

      var phase = raw - raw.floorToDouble();
      if (phase < 0.0) phase += 1.0;

      final eased = _smoother(phase);
      final envelope = math.sin(phase * math.pi);
      final radius = 15.0 + eased * 198.0;
      final ry = radius * aspect;

      final strength = 0.78 + _hash(ring * 31.71 + 3.0) * 0.30;
      final opacity = (0.145 * envelope * strength * (1.0 - phase * 0.12))
          .clamp(0.0, 0.19);

      if (opacity < 0.003) continue;

      final path = Path();

      for (int i = 0; i <= pointsPerRing; i++) {
        final u = i / pointsPerRing;
        final a = u * math.pi * 2.0;

        final largeWave = math.sin(a * 2.0 + ring * 1.71 + time * 0.17) * 0.065;
        final largeWave2 =
            math.sin(a * 3.0 - ring * 0.91 + time * 0.11 + 1.7) * 0.045;
        final mediumWave =
            math.sin(a * 5.0 + ring * 2.31 - time * 0.13) * 0.030;
        final mediumWave2 =
            math.sin(a * 7.0 - ring * 1.43 + time * 0.09) * 0.020;
        final fineWave = math.sin(a * 11.0 + ring * 3.17 + time * 0.07) * 0.010;
        final randomWave = _signed(ring * 91.7 + i * 5.37) * 0.012;
        final breathing = math.sin(a * 2.0 - time * 0.08 + ring * 0.7) * 0.018;

        final organic =
            1.0 +
            largeWave +
            largeWave2 +
            mediumWave +
            mediumWave2 +
            fineWave +
            randomWave +
            breathing;

        final directional =
            1.0 + math.cos(a * 1.3 + ring * 0.4) * eased * 0.028;

        final finalRadius = radius * organic * directional;
        final x = center.dx + math.cos(a) * finalRadius;
        final y = center.dy + math.sin(a) * finalRadius * aspect;

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
          ..color = Colors.white.withOpacity(opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = (1.35 - phase * 0.34 + _hash(ring * 8.2) * 0.10)
              .clamp(0.78, 1.42)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );

      if (phase > 0.045) {
        final softPath = Path();
        final softRadius = radius + 2.2;

        for (int i = 0; i <= pointsPerRing; i++) {
          final a = i / pointsPerRing * math.pi * 2.0;
          final softDistortion =
              1.0 +
              math.sin(a * 2.0 + ring * 1.8 + time * 0.13) * 0.042 +
              math.sin(a * 6.0 - ring * 0.8 - time * 0.08) * 0.018;

          final x = center.dx + math.cos(a) * softRadius * softDistortion;
          final y =
              center.dy + math.sin(a) * softRadius * aspect * softDistortion;

          if (i == 0) {
            softPath.moveTo(x, y);
          } else {
            softPath.lineTo(x, y);
          }
        }

        softPath.close();

        canvas.drawPath(
          softPath,
          Paint()
            ..color = Colors.white.withOpacity(opacity * 0.16)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.42
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.55),
        );
      }
    }

    // Slow organic contact ripple around the Verify OTP button.
    final contactRaw = elapsed * 0.45 + rippleKey * 0.31;
    var contactPhase = contactRaw - contactRaw.floorToDouble();
    if (contactPhase < 0.0) contactPhase += 1.0;

    final contactEase = _smoother(contactPhase);
    final contactFade = math.sin(contactPhase * math.pi);
    final contactRadius = 34.0 + contactEase * 152.0;
    final contactPath = Path();

    for (int i = 0; i <= 72; i++) {
      final a = i / 72.0 * math.pi * 2.0;
      final wobble =
          1.0 +
          math.sin(a * 2.0 + time * 0.15) * 0.075 +
          math.sin(a * 3.0 - time * 0.11 + 1.7) * 0.043 +
          math.sin(a * 5.0 + time * 0.08) * 0.026 +
          math.sin(a * 8.0 - time * 0.05) * 0.012;

      final x = center.dx + math.cos(a) * contactRadius * wobble;
      final y = center.dy + math.sin(a) * contactRadius * aspect * wobble;

      if (i == 0) {
        contactPath.moveTo(x, y);
      } else {
        contactPath.lineTo(x, y);
      }
    }

    contactPath.close();

    canvas.drawPath(
      contactPath,
      Paint()
        ..color = Colors.white.withOpacity(0.125 * contactFade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (1.35 - contactPhase * 0.30).clamp(0.82, 1.35)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Slow tap ripple.
    if (rippleKey > 0) {
      final tapRaw = elapsed * 0.56 + rippleKey * 0.41;
      var tapPhase = tapRaw - tapRaw.floorToDouble();
      if (tapPhase < 0.0) tapPhase += 1.0;

      final tapEase = _smoother(tapPhase);
      final tapFade = math.sin(tapPhase * math.pi);
      final tapRadius = 28.0 + tapEase * 165.0;
      final tapPath = Path();

      for (int i = 0; i <= 68; i++) {
        final a = i / 68.0 * math.pi * 2.0;
        final wobble =
            1.0 +
            math.sin(a * 2.0 + time * 0.18) * 0.070 +
            math.sin(a * 4.0 - time * 0.12 + 2.1) * 0.038 +
            math.sin(a * 7.0 + time * 0.07) * 0.018;

        final x = center.dx + math.cos(a) * tapRadius * wobble;
        final y = center.dy + math.sin(a) * tapRadius * aspect * wobble;

        if (i == 0) {
          tapPath.moveTo(x, y);
        } else {
          tapPath.lineTo(x, y);
        }
      }

      tapPath.close();

      canvas.drawPath(
        tapPath,
        Paint()
          ..color = Colors.white.withOpacity(0.17 * tapFade)
          ..style = PaintingStyle.stroke
          ..strokeWidth = (1.55 - tapPhase * 0.30).clamp(0.90, 1.55)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant LoginRipplePainter oldDelegate) {
    return oldDelegate.rippleKey != rippleKey;
  }
}

class LoginWaterlinePainter extends CustomPainter {
  final ValueListenable<double> clock;

  double get elapsed => clock.value;

  LoginWaterlinePainter(this.clock) : super(repaint: clock);

  @override
  void paint(Canvas canvas, Size size) {
    final t = elapsed * math.pi * 2;

    final path = Path();

    for (int i = 0; i <= 100; i++) {
      final p = i / 100;

      final x = p * size.width;

      final y =
          size.height / 2 +
          math.sin(p * math.pi * 3.8 + t * 1.4) * 1.2 +
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
        ..color = const Color(0xffE9FFFF).withOpacity(.40)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.15
        ..strokeCap = StrokeCap.round,
    );

    // Lower waterline

    final lower = Path();

    for (int i = 0; i <= 100; i++) {
      final p = i / 100;

      final x = p * size.width;

      final y = size.height / 2 + 2 + math.sin(p * math.pi * 4 + t * 1.3) * .8;

      if (i == 0) {
        lower.moveTo(x, y);
      } else {
        lower.lineTo(x, y);
      }
    }

    canvas.drawPath(
      lower,
      Paint()
        ..color = const Color(0xff4FC5D9).withOpacity(.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant LoginWaterlinePainter oldDelegate) {
    return false;
  }
}

// ================================================================
// FRONT CONTACT FOAM
// ================================================================

class LoginContactFoamPainter extends CustomPainter {
  final ValueListenable<double> clock;

  double get elapsed => clock.value;

  LoginContactFoamPainter(this.clock) : super(repaint: clock);

  double hash(double x) {
    final v = math.sin(x * 12.9898 + 78.233) * 43758.5453;

    return v - v.floorToDouble();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = elapsed * math.pi * 2;

    final cx = size.width / 2;

    // ============================================================
    // BUTTON BOB
    // ============================================================

    final bob = math.sin(t * .82) * 5.6 + math.sin(t * 1.37 + .8) * 2.3;

    final velocity =
        math.cos(t * .82) * .82 * 5.6 + math.cos(t * 1.37 + .8) * 1.37 * 2.3;

    final impact = (velocity / 6).clamp(0.0, 1.0);

    final waterY = 14 + bob * .65 + math.sin(t * 1.15) * 1.4;

    // ============================================================
    // PRESSURE UNDER BUTTON
    // ============================================================

    final pressure = Rect.fromCenter(
      center: Offset(cx, waterY + 5),
      width: 285 + impact * 25,
      height: 32 + impact * 10,
    );

    canvas.drawOval(
      pressure,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xff0A7180).withOpacity(.24),
            const Color(0xff4DBBC6).withOpacity(.12),
            Colors.transparent,
          ],
          stops: const [0, .48, 1],
        ).createShader(pressure)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // ============================================================
    // FRONT WATER WAVES
    // ============================================================

    for (int wave = 0; wave < 5; wave++) {
      final phase = t * (1.05 + wave * .12) + wave * 1.7;

      final path = Path();

      for (int i = 0; i <= 110; i++) {
        final p = i / 110;

        final x = 20 + p * (size.width - 40);

        final envelope = math.sin(p * math.pi);

        final bigWave =
            math.sin(p * math.pi * (3 + wave * .7) + phase) *
            (1.1 + wave * .45);

        final smallWave = math.sin(p * math.pi * 11 + phase * 1.8 + wave) * .35;

        final pressure = envelope * (1.5 + impact * 3.2);

        final y = waterY - pressure + bigWave + smallWave;

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withOpacity(.045 + (4 - wave) * .023)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .65 + (4 - wave) * .18
          ..strokeCap = StrokeCap.round,
      );
    }

    // ============================================================
    // SIDE IMPACT WAVES
    // ============================================================

    const buttonHalf = 130.0;

    for (final side in [-1.0, 1.0]) {
      for (int wave = 0; wave < 5; wave++) {
        final raw = (elapsed * 1.18 + wave * .19 + (side > 0 ? .47 : 0)) % 1;

        final approach = Curves.easeInOut.transform(raw);

        final start = 180 + wave * 8;

        final contact = buttonHalf - 3;

        final distance = start + (contact - start) * approach;

        final x = cx + side * distance;

        final hit = math.sin(approach * math.pi);

        final height = 1.2 + hit * 4.5 + impact * 2;

        final path = Path();

        for (int i = -10; i <= 10; i++) {
          final p = i / 10;

          final localX = x + p * 34;

          final envelope = math.exp(-p * p * 2.2);

          final ripple =
              math.sin(p * math.pi * 2.7 + t * 2.2 + wave * 1.5) *
              (.45 + hit * .9);

          final y = waterY - height * envelope + ripple;

          if (i == -10) {
            path.moveTo(localX, y);
          } else {
            path.lineTo(localX, y);
          }
        }

        canvas.drawPath(
          path,
          Paint()
            ..color = Colors.white.withOpacity((.025 + hit * .11).clamp(0, .16))
            ..style = PaintingStyle.stroke
            ..strokeWidth = .65 + hit * .75
            ..strokeCap = StrokeCap.round,
        );

        // Small collision splash

        if (approach > .78 && approach < .94) {
          final burst = math.sin(((approach - .78) / .16) * math.pi);

          final contactX = cx + side * buttonHalf;

          canvas.drawArc(
            Rect.fromCenter(
              center: Offset(contactX, waterY - 1),
              width: 13 + burst * 18,
              height: 6 + burst * 7,
            ),
            side > 0 ? math.pi * 1.15 : -math.pi * .15,
            math.pi * .72,
            false,
            Paint()
              ..color = Colors.white.withOpacity(.14 * burst)
              ..style = PaintingStyle.stroke
              ..strokeWidth = .9
              ..strokeCap = StrokeCap.round,
          );
        }
      }
    }

    // ============================================================
    // SMALL FOAM PARTICLES
    // ============================================================

    const particleCount = 45;

    for (int i = 0; i < particleCount; i++) {
      final seed = i * 17.31;

      final angle = (i / particleCount) * math.pi * 2 + (hash(seed) - .5) * .20;

      final radius = 115 + hash(seed + 3) * 40;

      final movement = math.sin(
        t * (1 + hash(seed + 6) * .8) + hash(seed + 9) * math.pi * 2,
      );

      final x = cx + math.cos(angle) * radius + movement * 1.2;

      final y = waterY + math.sin(angle) * radius * .12 + movement * .8;

      final opacity = (.018 + hash(seed + 11) * .045).clamp(0, .07);

      canvas.drawCircle(
        Offset(x, y),
        .4 + hash(seed + 14) * .8,
        Paint()..color = Colors.white.withOpacity(opacity.toDouble()),
      );
    }
  }

  @override
  bool shouldRepaint(covariant LoginContactFoamPainter oldDelegate) {
    return false;
  }
}// TODO Implement this library.