import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'home_screen.dart';

// ============================================================================
// PERMISSION SCREEN
// ============================================================================

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen>
    with TickerProviderStateMixin {
  // --------------------------------------------------------------------------
  // ANIMATION
  // --------------------------------------------------------------------------
  late final AnimationController _bgController;
  late final AnimationController _cardController;
  late final AnimationController _pulseController;
  late final Animation<double> _cardSlide;
  late final Animation<double> _cardFade;
  late final Animation<double> _pulse;

  // --------------------------------------------------------------------------
  // PERMISSION STATE
  // --------------------------------------------------------------------------
  final List<_PermItem> _perms = [
    _PermItem(
      permission: Permission.locationWhenInUse,
      icon: Icons.my_location_rounded,
      title: 'Location Tracking',
      subtitle:
          'Aapki live location track karne ke liye\n(Flood zone alerts & evacuation routes)',
      color: const Color(0xFF0877C9),
      gradient: [const Color(0xFF0877C9), const Color(0xFF05529A)],
    ),
    _PermItem(
      permission: Permission.sms,
      icon: Icons.sms_rounded,
      title: 'SMS Alerts',
      subtitle:
          'Emergency alerts aur SOS messages\nbhejne ke liye permission chahiye',
      color: const Color(0xFF15945C),
      gradient: [const Color(0xFF15945C), const Color(0xFF0D6B43)],
    ),
    _PermItem(
      permission: Permission.notification,
      icon: Icons.notifications_active_rounded,
      title: 'Notifications',
      subtitle:
          'Flood warnings aur rescue updates ke\nliye real-time notifications',
      color: const Color(0xFFF39A20),
      gradient: [const Color(0xFFF39A20), const Color(0xFFD97C0D)],
    ),
    _PermItem(
      permission: Permission.microphone,
      icon: Icons.mic_rounded,
      title: 'Audio Alerts',
      subtitle: 'Emergency audio broadcasts aur\nvoice SOS bhejne ke liye',
      color: const Color(0xFF7351D8),
      gradient: [const Color(0xFF7351D8), const Color(0xFF5436B5)],
    ),
  ];

  bool _requesting = false;
  bool _allDone = false;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _cardSlide = Tween<double>(begin: 60, end: 0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic),
    );
    _cardFade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _cardController, curve: Curves.easeOut));
    _pulse = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _cardController.forward();
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _cardController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // REQUEST ALL PERMISSIONS — timeout-safe, never freezes
  // --------------------------------------------------------------------------
  Future<void> _requestAll() async {
    if (_requesting) return;
    setState(() => _requesting = true);

    for (final item in _perms) {
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
      if (mounted) {
        setState(() {
          item.status = status;
        });
      }
      // Small pause so the user sees each card update
      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (mounted) {
      setState(() {
        _allDone = true;
        _requesting = false;
      });

      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) {
        _navigateToHome();
      }
    }
  }

  Future<void> _requestSingle(_PermItem item) async {
    if (_requesting) return;
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
    if (mounted) {
      setState(() {
        item.status = status;
        if (_perms.every((p) => p.isGranted)) {
          _allDone = true;
        }
      });
      if (_allDone) {
        await Future.delayed(const Duration(milliseconds: 700));
        if (mounted) {
          _navigateToHome();
        }
      }
    }
  }

  void _navigateToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const HomeScreen(),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
      (route) => false,
    );
  }

  // --------------------------------------------------------------------------
  // SKIP (navigate anyway)
  // --------------------------------------------------------------------------
  void _skipToHome() {
    _navigateToHome();
  }

  // --------------------------------------------------------------------------
  // BUILD
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF063A5B),
      body: Stack(
        children: [
          // Animated ocean background
          AnimatedBuilder(
            animation: _bgController,
            builder: (_, _) => CustomPaint(
              painter: _OceanBgPainter(_bgController.value),
              size: Size.infinite,
            ),
          ),

          // Content
          SafeArea(
            child: AnimatedBuilder(
              animation: _cardController,
              builder: (_, child) {
                return Transform.translate(
                  offset: Offset(0, _cardSlide.value),
                  child: Opacity(opacity: _cardFade.value, child: child),
                );
              },
              child: Column(
                children: [
                  const SizedBox(height: 36),

                  // Shield icon + title
                  _buildHeader(),

                  const SizedBox(height: 28),

                  // Permission cards
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          ..._perms.map(
                            (item) => _PermCard(
                              item: item,
                              index: _perms.indexOf(item),
                              onTap: () => _requestSingle(item),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),

                  // Bottom buttons
                  _buildBottomButtons(),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Animated shield
        AnimatedBuilder(
          animation: _pulse,
          builder: (_, child) =>
              Transform.scale(scale: _pulse.value, child: child),
          child: Container(
            width: 95,
            height: 95,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.08),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0877C9).withOpacity(0.4),
                  blurRadius: 28,
                  spreadRadius: 4,
                ),
              ],
              border: Border.all(
                color: const Color(0xFF38BDF8).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(10),
            child: Image.asset(
              'assets/images/app_logo.png',
              fit: BoxFit.contain,
            ),
          ),
        ),

        const SizedBox(height: 18),

        const Text(
          'App Permissions',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),

        const SizedBox(height: 8),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'ResQShield ko better kaam karne ke liye\nneeche diye permissions chahiye',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.72),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Allow all button
          GestureDetector(
            onTap: _requesting ? null : _requestAll,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _allDone
                      ? [const Color(0xFF15945C), const Color(0xFF0D6B43)]
                      : [const Color(0xFF0877C9), const Color(0xFF052F4B)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color:
                        (_allDone
                                ? const Color(0xFF15945C)
                                : const Color(0xFF0877C9))
                            .withOpacity(0.45),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: _requesting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _allDone
                                ? Icons.check_circle_rounded
                                : Icons.shield_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _allDone
                                ? 'Permissions Granted!'
                                : 'Allow All Permissions',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Skip button
          TextButton(
            onPressed: _requesting ? null : _skipToHome,
            child: Text(
              'Skip for now',
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PERMISSION ITEM MODEL
// ============================================================================

class _PermItem {
  final Permission permission;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final List<Color> gradient;
  PermissionStatus? status;

  _PermItem({
    required this.permission,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.gradient,
  });

  bool get isGranted =>
      status == PermissionStatus.granted ||
      status == PermissionStatus.limited ||
      status == PermissionStatus.provisional;

  bool get isDenied =>
      status == PermissionStatus.denied ||
      status == PermissionStatus.permanentlyDenied ||
      status == PermissionStatus.restricted;
}

// ============================================================================
// PERMISSION CARD WIDGET
// ============================================================================

class _PermCard extends StatelessWidget {
  final _PermItem item;
  final int index;
  final VoidCallback? onTap;

  const _PermCard({
    required this.item,
    required this.index,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + index * 120),
      curve: Curves.easeOutCubic,
      builder: (_, value, child) => Transform.translate(
        offset: Offset(0, 30 * (1 - value)),
        child: Opacity(opacity: value, child: child),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: item.status == null
                  ? Colors.white.withOpacity(0.14)
                  : item.isGranted
                  ? item.color.withOpacity(0.6)
                  : Colors.red.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              // Icon circle
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: item.gradient,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: item.color.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(item.icon, color: Colors.white, size: 26),
              ),

              const SizedBox(width: 14),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 11.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // Status indicator
              _StatusBadge(item: item),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final _PermItem item;
  const _StatusBadge({required this.item});

  @override
  Widget build(BuildContext context) {
    if (item.status == null) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Icon(
          Icons.lock_outline_rounded,
          color: Colors.white.withOpacity(0.5),
          size: 16,
        ),
      );
    }
    if (item.isGranted) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFF15945C).withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF15945C).withOpacity(0.6)),
        ),
        child: const Icon(
          Icons.check_rounded,
          color: Color(0xFF15945C),
          size: 18,
        ),
      );
    }
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.5)),
      ),
      child: const Icon(Icons.close_rounded, color: Colors.red, size: 18),
    );
  }
}

// ============================================================================
// OCEAN BACKGROUND PAINTER
// ============================================================================

class _OceanBgPainter extends CustomPainter {
  final double t;
  _OceanBgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // Sky gradient
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF021C2E), Color(0xFF063A5B), Color(0xFF0A5580)],
        stops: [0.0, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);

    // Subtle animated waves at bottom
    _drawWave(canvas, size, 0.78, const Color(0xFF0877C9), 0.12, t, 1.0);
    _drawWave(canvas, size, 0.82, const Color(0xFF063A5B), 0.18, t, 1.3);
    _drawWave(canvas, size, 0.87, const Color(0xFF052F4B), 0.25, t, 0.7);
  }

  void _drawWave(
    Canvas canvas,
    Size size,
    double yFrac,
    Color color,
    double opacity,
    double time,
    double speed,
  ) {
    final paint = Paint()..color = color.withOpacity(opacity);
    final path = Path();
    final y = size.height * yFrac;
    path.moveTo(0, y);
    for (double x = 0; x <= size.width; x++) {
      final wave =
          math.sin(
            (x / size.width * 2 * math.pi) + time * 2 * math.pi * speed,
          ) *
          16;
      path.lineTo(x, y + wave);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_OceanBgPainter old) => old.t != t;
}
