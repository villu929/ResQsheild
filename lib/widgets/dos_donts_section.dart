import 'dart:math' as math;
import 'package:flutter/material.dart';

// ============================================================
// DO'S & DON'TS ANIMATED WATER SECTION
// ============================================================

class DosDontsSection extends StatefulWidget {
  final VoidCallback? onViewAll;
  final Function(String message)? onShowMessage;

  const DosDontsSection({
    super.key,
    this.onViewAll,
    this.onShowMessage,
  });

  @override
  State<DosDontsSection> createState() => _DosDontsSectionState();
}

class _DosDontsSectionState extends State<DosDontsSection>
    with SingleTickerProviderStateMixin {
  int _selectedTabIndex = 0; // 0: During Flood, 1: Before Flood, 2: After Flood
  late final AnimationController _waveController;

  final List<String> _tabs = [
    'During Flood',
    'Before Flood',
    'After Flood',
  ];

  final Map<int, List<String>> _dosData = {
    0: [
      'Move to higher ground immediately',
      'Follow safe evacuation routes',
      'Keep emergency kit ready',
    ],
    1: [
      'Store clean drinking water & dry food',
      'Charge mobile phones, power banks & torches',
      'Keep important documents in waterproof bags',
    ],
    2: [
      'Drink only boiled or purified water',
      'Check for structural damage before entering',
      'Report fallen electrical wires & gas leaks',
    ],
  };

  final Map<int, List<String>> _dontsData = {
    0: [
      'Do not walk in flood water',
      'Do not cross submerged roads',
      'Do not touch electrical equipment',
    ],
    1: [
      'Do not ignore official weather & flood alerts',
      'Do not store heavy objects on high shelves',
      'Do not park vehicles in low-lying areas',
    ],
    2: [
      'Do not turn on electrical switches if wet',
      'Do not consume food exposed to flood water',
      'Do not drive through flooded roads or bridges',
    ],
  };

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentDos = _dosData[_selectedTabIndex] ?? _dosData[0]!;
    final currentDonts = _dontsData[_selectedTabIndex] ?? _dontsData[0]!;

    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        final animValue = _waveController.value;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 14),
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF072138),
                Color(0xFF041829),
                Color(0xFF021220),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF00A2FF).withOpacity(0.25),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0066FF).withOpacity(0.12),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header (Shield + Title + View All)
              _buildHeader(),

              const SizedBox(height: 14),

              // 2. Segmented Pill Tab Bar
              _buildTabBar(),

              const SizedBox(height: 16),

              // 3. Do's Card (Green Cyber Glow Card with Water Waves)
              _buildDosCard(currentDos, animValue),

              const SizedBox(height: 14),

              // 4. Don'ts Card (Red Cyber Glow Card with Water Waves)
              _buildDontsCard(currentDonts, animValue),

              const SizedBox(height: 14),

              // 5. Stay Safe Banner with Ripple Animated Shield
              _buildStaySafeBanner(animValue),
            ],
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // 1. HEADER WIDGET
  // ------------------------------------------------------------
  Widget _buildHeader() {
    return Row(
      children: [
        // 3D Glowing Blue Shield
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFF00C3FF).withOpacity(0.35),
                const Color(0xFF0077FF).withOpacity(0.08),
                Colors.transparent,
              ],
            ),
          ),
          child: Center(
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF90E0EF),
                  Color(0xFF00B4D8),
                  Color(0xFF0077B6),
                ],
              ).createShader(bounds),
              child: const Icon(
                Icons.shield_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          "Do's & Don'ts",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
            shadows: [
              Shadow(
                color: Color(0x6600B4D8),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        const Spacer(),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            if (widget.onViewAll != null) {
              widget.onViewAll!();
            } else if (widget.onShowMessage != null) {
              widget.onShowMessage!('All safety guidelines opened');
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'View All',
                  style: TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF38BDF8),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // 2. SEGMENTED TAB BAR
  // ------------------------------------------------------------
  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(3.5),
      decoration: BoxDecoration(
        color: const Color(0xFF031422).withOpacity(0.9),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFF0088FF).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0066FF).withOpacity(0.08),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [
                            Color(0xFF0077FF),
                            Color(0xFF00A6FF),
                          ],
                        )
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF00A6FF).withOpacity(0.6),
                            blurRadius: 10,
                            spreadRadius: 0.5,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    _tabs[index],
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.65),
                      fontSize: 11.5,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ------------------------------------------------------------
  // 3. DO'S CARD (CYBER EMERALD WITH FLOATING WATER ANIMATION)
  // ------------------------------------------------------------
  Widget _buildDosCard(List<String> items, double animValue) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF04201B).withOpacity(0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00E599).withOpacity(0.65),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E599).withOpacity(0.12),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            // Floating Water Wave Custom Painter in background
            Positioned.fill(
              child: CustomPaint(
                painter: _CardWaterWavePainter(
                  animValue: animValue,
                  waveColor: const Color(0xFF00E599),
                ),
              ),
            ),

            // Top-right shield badge with checkmark
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00E599).withOpacity(0.15),
                  border: Border.all(
                    color: const Color(0xFF00E599).withOpacity(0.7),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E599).withOpacity(0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF00E599),
                  size: 14,
                ),
              ),
            ),

            // Rows of Do's
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Column(
                children: List.generate(items.length, (index) {
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Neon circular glowing check
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const RadialGradient(
                                  colors: [
                                    Color(0xFF00F5A0),
                                    Color(0xFF00B36B),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00F5A0)
                                        .withOpacity(0.6),
                                    blurRadius: 8,
                                    spreadRadius: 0.5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 28),
                                child: Text(
                                  items[index],
                                  style: const TextStyle(
                                    color: Color(0xFFF0FDF8),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.1,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (index != items.length - 1)
                        Divider(
                          height: 10,
                          thickness: 0.8,
                          color: const Color(0xFF00E599).withOpacity(0.2),
                          indent: 38,
                          endIndent: 8,
                        ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // 4. DON'TS CARD (CYBER RUBY/CORAL WITH FLOATING WATER ANIMATION)
  // ------------------------------------------------------------
  Widget _buildDontsCard(List<String> items, double animValue) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF260512).withOpacity(0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF3355).withOpacity(0.65),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF3355).withOpacity(0.12),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            // Floating Water Wave Custom Painter in background
            Positioned.fill(
              child: CustomPaint(
                painter: _CardWaterWavePainter(
                  animValue: animValue,
                  waveColor: const Color(0xFFFF3355),
                  isReversed: true,
                ),
              ),
            ),

            // Top-right shield badge with X
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF3355).withOpacity(0.15),
                  border: Border.all(
                    color: const Color(0xFFFF3355).withOpacity(0.7),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF3355).withOpacity(0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Color(0xFFFF3355),
                  size: 14,
                ),
              ),
            ),

            // Rows of Don'ts
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Column(
                children: List.generate(items.length, (index) {
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Neon circular glowing X
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const RadialGradient(
                                  colors: [
                                    Color(0xFFFF4D6D),
                                    Color(0xFFE60039),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF4D6D)
                                        .withOpacity(0.6),
                                    blurRadius: 8,
                                    spreadRadius: 0.5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 28),
                                child: Text(
                                  items[index],
                                  style: const TextStyle(
                                    color: Color(0xFFFFF0F3),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.1,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (index != items.length - 1)
                        Divider(
                          height: 10,
                          thickness: 0.8,
                          color: const Color(0xFFFF3355).withOpacity(0.2),
                          indent: 38,
                          endIndent: 8,
                        ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // 5. STAY SAFE BANNER (WITH ANIMATED WATER RIPPLES & SHIELD)
  // ------------------------------------------------------------
  Widget _buildStaySafeBanner(double animValue) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF041F38).withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00A2FF).withOpacity(0.6),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0091FF).withOpacity(0.18),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background flowing wave lines
            Positioned.fill(
              child: CustomPaint(
                painter: _CardWaterWavePainter(
                  animValue: animValue,
                  waveColor: const Color(0xFF00A6FF),
                  speedMultiplier: 1.2,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
              child: Row(
                children: [
                  // Left Glowing Mini Shield
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00B4D8).withOpacity(0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF90E0EF), Color(0xFF00B4D8)],
                      ).createShader(bounds),
                      child: const Icon(
                        Icons.shield_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Vertical Divider
                  Container(
                    width: 1.5,
                    height: 28,
                    color: const Color(0xFF00A6FF).withOpacity(0.4),
                  ),

                  const SizedBox(width: 12),

                  // Text Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Stay Safe, Stay Informed',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'We are with you in every situation',
                          style: TextStyle(
                            color: Color(0xFF64D2FF),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Right Large Shield with Concentric Water Ripple Effect
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Concentric animated water ripples
                        CustomPaint(
                          painter: _WaterRipplePainter(animValue: animValue),
                          size: const Size(52, 52),
                        ),

                        // Glowing 3D Shield Icon
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00A6FF).withOpacity(0.55),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFFCAF0F8),
                                Color(0xFF48CAE4),
                                Color(0xFF0077B6),
                              ],
                            ).createShader(bounds),
                            child: const Icon(
                              Icons.shield_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// CUSTOM PAINTER: CARD WATER WAVE FLOW ANIMATION
// ============================================================

class _CardWaterWavePainter extends CustomPainter {
  final double animValue;
  final Color waveColor;
  final bool isReversed;
  final double speedMultiplier;

  _CardWaterWavePainter({
    required this.animValue,
    required this.waveColor,
    this.isReversed = false,
    this.speedMultiplier = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final direction = isReversed ? -1.0 : 1.0;
    final phase = animValue * math.pi * 2 * speedMultiplier * direction;

    // Layer 1: Bottom subtle wave lines flowing across the bottom-right
    final wavePaint1 = Paint()
      ..color = waveColor.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    final path1 = Path();
    path1.moveTo(w * 0.35, h);
    for (double x = w * 0.35; x <= w + 10; x += 8) {
      final progress = (x - w * 0.35) / (w * 0.65);
      final y = h - (progress * 28) +
          math.sin(phase + x * 0.035) * 5 +
          math.cos(phase * 1.5 + x * 0.02) * 3;
      path1.lineTo(x, y);
    }
    canvas.drawPath(path1, wavePaint1);

    // Layer 2: Secondary wave harmonic curve
    final wavePaint2 = Paint()
      ..color = waveColor.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path2 = Path();
    path2.moveTo(w * 0.45, h);
    for (double x = w * 0.45; x <= w + 10; x += 8) {
      final progress = (x - w * 0.45) / (w * 0.55);
      final y = h - (progress * 38) +
          math.cos(phase * 1.2 + x * 0.04) * 6 +
          math.sin(phase * 0.8 + x * 0.025) * 4;
      path2.lineTo(x, y);
    }
    canvas.drawPath(path2, wavePaint2);

    // Layer 3: Soft ambient glow gradient at bottom right
    final glowRect = Rect.fromCircle(
      center: Offset(w * 0.9, h * 0.85),
      radius: 45,
    );
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          waveColor.withOpacity(0.15),
          Colors.transparent,
        ],
      ).createShader(glowRect);
    canvas.drawRect(glowRect, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _CardWaterWavePainter oldDelegate) {
    return oldDelegate.animValue != animValue;
  }
}

// ============================================================
// CUSTOM PAINTER: WATER RIPPLE AROUND SHIELD
// ============================================================

class _WaterRipplePainter extends CustomPainter {
  final double animValue;

  _WaterRipplePainter({required this.animValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 3 Concentric ripples expanding outward
    for (int i = 0; i < 3; i++) {
      final progress = (animValue + (i * 0.33)) % 1.0;
      final radius = 16.0 + (progress * 14.0);
      final opacity = (1.0 - progress) * 0.45;

      final ripplePaint = Paint()
        ..color = const Color(0xFF00B4D8).withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;

      canvas.drawCircle(center, radius, ripplePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaterRipplePainter oldDelegate) {
    return oldDelegate.animValue != animValue;
  }
}
