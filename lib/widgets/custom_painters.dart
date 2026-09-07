import 'dart:math' as math;
import 'package:flutter/material.dart';

// ============================================================
// BACKGROUND WATER ANIMATED WIDGET
// ============================================================

class BackgroundWater extends StatefulWidget {
  const BackgroundWater({super.key});

  @override
  State<BackgroundWater> createState() => _BackgroundWaterState();
}

class _BackgroundWaterState extends State<BackgroundWater>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _BackgroundWaterPainter(_controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _BackgroundWaterPainter extends CustomPainter {
  final double animationValue;

  _BackgroundWaterPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Soft blue-grey background gradient
    final bgGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [
        Color(0xFF7E98AE), // Top/primary: #7E98AE
        Color(0xFF8FA9BC), // Main: #8FA9BC
        Color(0xFFB4C9D8), // Lighter areas: #B4C9D8
        Color(0xFF99ADBF), // Bottom: #99ADBF
      ],
      stops: const [0.0, 0.35, 0.70, 1.0],
    );

    canvas.drawRect(rect, Paint()..shader = bgGradient.createShader(rect));

    // Radial ambient light at top right for soft lighter areas (#B4C9D8)
    final ambientGlow = RadialGradient(
      center: const Alignment(0.6, -0.6),
      radius: 0.95,
      colors: [
        const Color(0xFFB4C9D8).withOpacity(0.40),
        Colors.transparent,
      ],
    );
    canvas.drawRect(rect, Paint()..shader = ambientGlow.createShader(rect));

    // Secondary soft glow for lighter areas mid-left (#B4C9D8)
    final midGlow = RadialGradient(
      center: const Alignment(-0.4, 0.25),
      radius: 0.85,
      colors: [
        const Color(0xFFB4C9D8).withOpacity(0.28),
        Colors.transparent,
      ],
    );
    canvas.drawRect(rect, Paint()..shader = midGlow.createShader(rect));

    final phase = animationValue * math.pi * 2;

    // Wave layer 1 (Background soft ripple highlight)
    final path1 = Path();
    path1.moveTo(0, size.height * 0.25);
    for (double x = 0; x <= size.width; x += 10) {
      final y = size.height * 0.25 +
          math.sin(phase + x * 0.008) * 12 +
          math.sin(phase * 2 + x * 0.015) * 6;
      path1.lineTo(x, y);
    }
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();

    canvas.drawPath(
      path1,
      Paint()
        ..color = const Color(0xFFB4C9D8).withOpacity(0.22)
        ..style = PaintingStyle.fill,
    );

    // Wave layer 2 (Midground translucent soft light)
    final path2 = Path();
    path2.moveTo(0, size.height * 0.55);
    for (double x = 0; x <= size.width; x += 10) {
      final y = size.height * 0.55 +
          math.cos(phase * 1.5 + x * 0.01) * 16 +
          math.sin(phase + x * 0.02) * 8;
      path2.lineTo(x, y);
    }
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();

    canvas.drawPath(
      path2,
      Paint()
        ..color = Colors.white.withOpacity(0.12)
        ..style = PaintingStyle.fill,
    );

    // Ambient floating water drops / shimmer
    final random = math.Random(42);
    for (int i = 0; i < 15; i++) {
      final seedX = random.nextDouble() * size.width;
      final seedY = random.nextDouble() * size.height;
      final speed = 0.5 + random.nextDouble() * 0.8;
      final offsetY = (seedY - (animationValue * size.height * speed)) % size.height;
      final radius = 1.5 + random.nextDouble() * 2.5;

      canvas.drawCircle(
        Offset(seedX + math.sin(phase + i) * 6, offsetY),
        radius,
        Paint()
          ..color = Colors.white.withOpacity(0.18 + (i % 3) * 0.06)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundWaterPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

// ============================================================
// RAIN CLOUD ILLUSTRATION
// ============================================================

class RainCloudIllustration extends StatelessWidget {
  const RainCloudIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RainCloudPainter(),
    );
  }
}

class _RainCloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Soft glow shadow behind cloud
    final glowPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset(w * 0.5, h * 0.4), w * 0.35, glowPaint);

    // Cloud path
    final cloudPath = Path();
    cloudPath.moveTo(w * 0.22, h * 0.55);
    cloudPath.cubicTo(w * 0.05, h * 0.55, w * 0.05, h * 0.35, w * 0.22, h * 0.35);
    cloudPath.cubicTo(w * 0.22, h * 0.18, w * 0.45, h * 0.12, w * 0.58, h * 0.25);
    cloudPath.cubicTo(w * 0.68, h * 0.15, w * 0.88, h * 0.22, w * 0.85, h * 0.38);
    cloudPath.cubicTo(w * 0.98, h * 0.42, w * 0.96, h * 0.58, w * 0.82, h * 0.58);
    cloudPath.lineTo(w * 0.22, h * 0.58);
    cloudPath.close();

    // Cloud gradient
    final cloudGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [
        Colors.white,
        Color(0xFFE2F1F8),
        Color(0xFFB8DDF0),
      ],
    );

    canvas.drawPath(
      cloudPath,
      Paint()..shader = cloudGradient.createShader(Offset.zero & size),
    );

    // Rain drops
    final dropPaint = Paint()
      ..color = const Color(0xFF35A9E8)
      ..style = PaintingStyle.fill;

    final drops = [
      Offset(w * 0.28, h * 0.68),
      Offset(w * 0.45, h * 0.76),
      Offset(w * 0.62, h * 0.68),
      Offset(w * 0.36, h * 0.85),
      Offset(w * 0.54, h * 0.88),
      Offset(w * 0.72, h * 0.82),
    ];

    for (final drop in drops) {
      final dropPath = Path();
      dropPath.moveTo(drop.dx, drop.dy - 5);
      dropPath.quadraticBezierTo(
        drop.dx - 3,
        drop.dy + 3,
        drop.dx,
        drop.dy + 5,
      );
      dropPath.quadraticBezierTo(
        drop.dx + 3,
        drop.dy + 3,
        drop.dx,
        drop.dy - 5,
      );
      canvas.drawPath(dropPath, dropPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================
// FLOOD MAP PAINTER
// ============================================================

class FloodMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Land base background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF132B3C),
    );

    // Grid lines (Tactical overview grid)
    final gridPaint = Paint()
      ..color = const Color(0xFF1E3F57).withOpacity(0.4)
      ..strokeWidth = 1.0;

    for (double x = 0; x < w; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (double y = 0; y < h; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // High Flood Danger Zone 1 (Aluva Red Zone)
    final floodZone1 = Path();
    floodZone1.moveTo(w * 0.15, h * 0.2);
    floodZone1.cubicTo(w * 0.4, h * 0.1, w * 0.55, h * 0.4, w * 0.45, h * 0.65);
    floodZone1.cubicTo(w * 0.3, h * 0.75, w * 0.1, h * 0.5, w * 0.15, h * 0.2);
    floodZone1.close();

    final redGradient = RadialGradient(
      colors: [
        const Color(0xFFE92828).withOpacity(0.55),
        const Color(0xFFE92828).withOpacity(0.1),
      ],
    );
    canvas.drawPath(
      floodZone1,
      Paint()..shader = redGradient.createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    canvas.drawPath(
      floodZone1,
      Paint()
        ..color = const Color(0xFFE92828).withOpacity(0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Moderate Flood Risk Zone 2 (Orange Zone)
    final floodZone2 = Path();
    floodZone2.moveTo(w * 0.6, h * 0.45);
    floodZone2.cubicTo(w * 0.85, h * 0.4, w * 0.95, h * 0.75, w * 0.7, h * 0.85);
    floodZone2.cubicTo(w * 0.5, h * 0.8, w * 0.55, h * 0.55, w * 0.6, h * 0.45);
    floodZone2.close();

    final orangeGradient = RadialGradient(
      colors: [
        const Color(0xFFF39A20).withOpacity(0.45),
        const Color(0xFFF39A20).withOpacity(0.08),
      ],
    );
    canvas.drawPath(
      floodZone2,
      Paint()..shader = orangeGradient.createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // River Periyar (Hydro-Blue Main River Branch)
    final riverPath = Path();
    riverPath.moveTo(-10, h * 0.3);
    riverPath.cubicTo(w * 0.25, h * 0.25, w * 0.35, h * 0.5, w * 0.65, h * 0.35);
    riverPath.cubicTo(w * 0.8, h * 0.25, w * 0.85, h * 0.6, w + 10, h * 0.75);

    canvas.drawPath(
      riverPath,
      Paint()
        ..color = const Color(0xFF35A9E8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      riverPath,
      Paint()
        ..color = const Color(0xFF75D1FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );

    // Safe Evacuation Highway (Green Line)
    final highwayPath = Path();
    highwayPath.moveTo(w * 0.05, h * 0.9);
    highwayPath.lineTo(w * 0.4, h * 0.85);
    highwayPath.lineTo(w * 0.7, h * 0.2);
    highwayPath.lineTo(w * 0.95, h * 0.15);

    final roadPaint = Paint()
      ..color = const Color(0xFF15945C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(highwayPath, roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================
// SHELTER ILLUSTRATION
// ============================================================

class ShelterIllustration extends StatelessWidget {
  final int type;
  final double width;
  final double height;

  const ShelterIllustration({
    super.key,
    required this.type,
    this.width = 67,
    this.height = 67,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFEBF4FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: CustomPaint(
        painter: _ShelterPainter(type),
      ),
    );
  }
}

class _ShelterPainter extends CustomPainter {
  final int type;

  _ShelterPainter(this.type);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final primaryColor = type == 0
        ? const Color(0xFF0877C9)
        : type == 1
            ? const Color(0xFF15945C)
            : const Color(0xFF7351D8);

    // Building Body
    final bodyPaint = Paint()
      ..color = primaryColor.withOpacity(0.18)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.2, h * 0.4, w * 0.6, h * 0.45),
        const Radius.circular(4),
      ),
      bodyPaint,
    );

    // Roof
    final roofPath = Path();
    roofPath.moveTo(w * 0.15, h * 0.42);
    roofPath.lineTo(w * 0.5, h * 0.18);
    roofPath.lineTo(w * 0.85, h * 0.42);
    roofPath.close();

    canvas.drawPath(
      roofPath,
      Paint()..color = primaryColor,
    );

    // Door
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.42, h * 0.6, w * 0.16, h * 0.25),
        const Radius.circular(2),
      ),
      Paint()..color = primaryColor,
    );

    // Windows
    final windowPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(w * 0.27, h * 0.48, w * 0.1, h * 0.1), windowPaint);
    canvas.drawRect(Rect.fromLTWH(w * 0.63, h * 0.48, w * 0.1, h * 0.1), windowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================
// HOSPITAL ILLUSTRATION
// ============================================================

class HospitalIllustration extends StatelessWidget {
  final int type;
  final double width;
  final double height;

  const HospitalIllustration({
    super.key,
    required this.type,
    this.width = 64,
    this.height = 54,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F7FA),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFE2E9F0)),
      ),
      child: CustomPaint(
        painter: _HospitalPainter(type),
      ),
    );
  }
}

class _HospitalPainter extends CustomPainter {
  final int type;

  _HospitalPainter(this.type);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Building Structure
    final bldgPaint = Paint()
      ..color = const Color(0xFF0877C9).withOpacity(0.15)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.18, h * 0.25, w * 0.64, h * 0.6),
        const Radius.circular(5),
      ),
      bldgPaint,
    );

    // Medical Cross Icon (Red Emblem)
    final crossPaint = Paint()..color = const Color(0xFFE92828);

    final cx = w * 0.5;
    final cy = h * 0.45;

    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, cy), width: 14, height: 4.5),
      crossPaint,
    );
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, cy), width: 4.5, height: 14),
      crossPaint,
    );

    // Door entrance
    canvas.drawRect(
      Rect.fromLTWH(w * 0.43, h * 0.65, w * 0.14, h * 0.2),
      Paint()..color = const Color(0xFF0877C9),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================
// AMBULANCE ILLUSTRATION
// ============================================================

class AmbulanceIllustration extends StatelessWidget {
  final double width;
  final double height;

  const AmbulanceIllustration({
    super.key,
    this.width = 64,
    this.height = 54,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEEE),
        borderRadius: BorderRadius.circular(9),
      ),
      child: CustomPaint(
        painter: _AmbulancePainter(),
      ),
    );
  }
}

class _AmbulancePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Body
    final bodyPaint = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.15, h * 0.35, w * 0.65, h * 0.4),
        const Radius.circular(4),
      ),
      bodyPaint,
    );

    // Cabin front
    final cabinPath = Path();
    cabinPath.moveTo(w * 0.65, h * 0.4);
    cabinPath.lineTo(w * 0.82, h * 0.48);
    cabinPath.lineTo(w * 0.82, h * 0.75);
    cabinPath.lineTo(w * 0.65, h * 0.75);
    cabinPath.close();

    canvas.drawPath(cabinPath, Paint()..color = const Color(0xFFE92828));

    // Wheels
    final wheelPaint = Paint()..color = const Color(0xFF10233D);
    canvas.drawCircle(Offset(w * 0.3, h * 0.75), 5, wheelPaint);
    canvas.drawCircle(Offset(w * 0.7, h * 0.75), 5, wheelPaint);

    // Emergency Light Siren
    canvas.drawRect(
      Rect.fromLTWH(w * 0.45, h * 0.28, w * 0.08, h * 0.07),
      Paint()..color = const Color(0xFFE92828),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================
// SAFE ROUTES PAINTER
// ============================================================

class SafeRoutesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Dark Map Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(10),
      ),
      Paint()..color = const Color(0xFF0D2536),
    );

    // Grid lines
    final grid = Paint()
      ..color = const Color(0xFF193B52)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(w * 0.33, 0), Offset(w * 0.33, h), grid);
    canvas.drawLine(Offset(w * 0.66, 0), Offset(w * 0.66, h), grid);

    // River Submerged Hazard
    final river = Path();
    river.moveTo(0, h * 0.4);
    river.quadraticBezierTo(w * 0.5, h * 0.2, w, h * 0.5);
    canvas.drawPath(
      river,
      Paint()
        ..color = const Color(0xFF0877C9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12,
    );

    // Safe Evacuation Route (Green Solid Path)
    final safeRoute = Path();
    safeRoute.moveTo(w * 0.1, h * 0.85);
    safeRoute.lineTo(w * 0.45, h * 0.75);
    safeRoute.lineTo(w * 0.5, h * 0.25);
    safeRoute.lineTo(w * 0.9, h * 0.15);

    canvas.drawPath(
      safeRoute,
      Paint()
        ..color = const Color(0xFF15945C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round,
    );

    // Blocked Bridge Path (Red Cross Marker)
    final blockedRoute = Path();
    blockedRoute.moveTo(w * 0.25, h * 0.15);
    blockedRoute.lineTo(w * 0.35, h * 0.45);

    canvas.drawPath(
      blockedRoute,
      Paint()
        ..color = const Color(0xFFE92828)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
