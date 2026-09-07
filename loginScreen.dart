import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'otp_screen.dart';
void main() {
  runApp(const ResQShieldApp());
}

class ResQShieldApp extends StatelessWidget {
  const ResQShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// ============================================================================
// LOGIN SCREEN STATE
// ----------------------------------------------------------------------------
// FIX FOR THE "STUTTER" ISSUE:
//
// Previously this screen used THREE separate AnimationControllers, each
// with `..repeat()`. A repeating AnimationController's value climbs from
// 0 -> 1 over its duration and then SNAPS straight back to 0. All of the
// floating math (floatY, floatX, tiltX, tiltZ, ripple phases, wave
// speeds, etc.) uses sine waves with non-integer frequency multipliers
// (e.g. sin(t * .82), sin(t * 1.37)). For a snap-back loop to look
// seamless, every one of those frequencies would need to complete a
// whole number of cycles exactly at the loop boundary — they don't, so
// at the exact moment the controller reset (every 7s for the login
// platform, 8s for the boats, 26s for the ocean) the values jumped,
// which read as a visible "ruk jaana" / stutter.
//
// THE FIX: instead of a bounded, resetting 0..1 controller, drive
// everything from a single Ticker whose elapsed time NEVER resets — it
// just keeps counting up for as long as the screen is alive. We divide
// that elapsed time by the old "duration" to get an equivalent phase
// value, but because it never wraps back to a start point, there is no
// seam for any sine wave (integer-frequency or not) to jump across. The
// motion's speed/character is identical to before — only the reset
// glitch is gone.
// ============================================================================

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late final Ticker _ticker;

  // Keeps counting upward forever — never resets, so nothing ever
  // "snaps" back to a starting value.
  double _elapsedSeconds = 0;
  double _scrollOffset = 0.0;

  bool passwordVisible = false;
  bool _loginPressed = false;

  // --------------------------------------------------------------------
  // LOGIN BUTTON PRESS ANIMATION
  //
  // A short, dedicated AnimationController (separate from the endless
  // floating Ticker above) that drives the "keycap sinking in" feel
  // when the login button is pressed. It sinks in quickly (like real
  // hardware/keyboard feedback) and eases back out with a touch of
  // overshoot so the release feels springy/realistic instead of linear.
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
    final identity = _identityController.text.trim();
    final password = _passwordController.text;

    final isEmail = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(identity);
    final isPhone = RegExp(r'^\d{10}$').hasMatch(identity);

    // Any valid email OR any 10-digit phone number is accepted,
    // and demo password or any entered password.
    final isValid = (isEmail || isPhone) &&
        (password == 'ResQsheild' ||
            password == 'ResQshield' ||
            password.isNotEmpty);

    if (isValid) {
      FocusScope.of(context).unfocus();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const WaterWavesScreen(),
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Invalid Details'),
        content: const Text(
          'Please enter valid details.\n\n'
              '• Enter a valid email address OR a 10-digit phone number.\n'
              '• Password must be correct.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
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
    final double boatValue = _elapsedSeconds / _boatCycle;
    final double loginValue = _elapsedSeconds / _loginCycle;

    return Scaffold(
      backgroundColor: const Color(0xff000208),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Responsive shell: the original 390dp design is preserved
            // exactly, then scaled to the available device width.
            // MediaQuery is used for safe-area/orientation-aware sizing,
            // while LayoutBuilder handles the actual available width.
            final media = MediaQuery.of(context);
            final screenWidth = media.size.width;
            final availableWidth = constraints.maxWidth;
            final horizontalPadding = screenWidth < 360 ? 12.0 : 16.0;
            final responsiveWidth =
                (availableWidth - horizontalPadding * 2).clamp(280.0, 430.0);
            final designWidth = 390.0;
            final scale = (responsiveWidth / designWidth).clamp(0.72, 1.10);
            final designHeight = media.size.height / scale;

            return NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollUpdateNotification) {
                  setState(() {
                    _scrollOffset = notification.metrics.pixels;
                  });
                }
                return false;
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Ocean background moves vertically as user scrolls
                  Positioned(
                    top: -_scrollOffset,
                    left: 0,
                    right: 0,
                    height: media.size.height + 1500,
                    child: CustomPaint(
                      painter: RealisticOceanPainter(
                        waterValue,
                        referenceHeight: media.size.height + 1500,
                      ),
                    ),
                  ),

                  // 2. Scroll gesture surface (enables smooth scrolling physics for background)
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: SizedBox(
                      height: media.size.height + 1000,
                    ),
                  ),

                  // 3. Text fields, buttons, and logo stay 100% FIXED on screen (DO NOT MOVE)
                  Center(
                    child: SizedBox(
                      width: responsiveWidth,
                      child: Transform.scale(
                        scale: scale,
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: designWidth,
                          child: Column(
                            children: [
                  const SizedBox(height: 55),

                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.25),
                          blurRadius: 25,
                          spreadRadius: 4,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(10),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Res',
                          style: TextStyle(
                            color: Color(0xFF38BDF8),
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .5,
                            shadows: [
                              Shadow(
                                color: Colors.black45,
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                        ),
                        TextSpan(
                          text: 'Q',
                          style: TextStyle(
                            color: Color(0xFF22C55E),
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .5,
                            shadows: [
                              Shadow(
                                color: Colors.black45,
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                        ),
                        TextSpan(
                          text: 'Shield',
                          style: TextStyle(
                            color: Color(0xFF38BDF8),
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .5,
                            shadows: [
                              Shadow(
                                color: Colors.black45,
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    'Safer Routes. Stronger Communities.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(.88),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),

                  const SizedBox(height: 65),


                  BoatTextField(
                    hintText: 'Enter Email or Phone No.',
                    icon: Icons.person,
                    animationValue: boatValue,
                    boatIndex: 0,
                    controller: _identityController,
                  ),

                  const SizedBox(height: 12),

                  BoatTextField(
                    hintText: 'Password',
                    icon: Icons.lock_outline,
                    animationValue: boatValue,
                    boatIndex: 1,
                    obscureText: true,
                    isVisible: passwordVisible,
                    onVisibilityPressed: () {
                      setState(() {
                        passwordVisible = !passwordVisible;
                      });
                    },
                    controller: _passwordController,
                  ),

                  const SizedBox(height: 8),

                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 45),
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: Colors.white.withOpacity(.9),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),


                  // ==========================================================
                  // WATER FLOATING 3D LOGIN PLATFORM
                  // (No AnimatedBuilder needed anymore — the whole tree
                  // already rebuilds every frame via the Ticker above, and
                  // `loginValue` never resets, so this motion never jumps.)
                  // ==========================================================
                  Builder(
                    builder: (_) {
                      final t = loginValue * math.pi * 2;

                      // ------------------------------------------------------
                      // GENTLE BOAT-LIKE BOBBING
                      // ------------------------------------------------------
                      final floatY =
                          math.sin(t * .82) * 5.6 +
                              math.sin(t * 1.37 + .8) * 2.3;

                      // ------------------------------------------------------
                      // VERY SUBTLE HORIZONTAL DRIFT
                      // ------------------------------------------------------
                      final floatX = math.sin(t * .43 + 1.2) * 2.7;

                      // ------------------------------------------------------
                      // X-AXIS ROCKING
                      //
                      // Keeps the strong top-view perspective tilt while
                      // continuously rocking approximately between
                      // 45° and 60°.
                      // ------------------------------------------------------
                      final tiltX =
                          -(math.pi * 52.5 / 180) +
                              math.sin(t * .78 + .6) * (math.pi * 10 / 180);

                      // ------------------------------------------------------
                      // Z-AXIS BOAT ROLL
                      // ------------------------------------------------------
                      final tiltZ =
                          math.sin(t * .72 + .35) * (math.pi * 4.6 / 180) +
                              math.sin(t * 1.17 + 1.1) * (math.pi * 1.7 / 180);

                      // ------------------------------------------------------
                      // ROCK BIAS
                      //
                      // Derived straight from the platform's own Z roll.
                      // Positive => currently leaning/dipping to the right,
                      // negative => leaning to the left. Fed into the
                      // ripple and foam painters below so the water
                      // visibly reacts more on whichever side the
                      // platform is pressing into it at that instant.
                      // ------------------------------------------------------
                      final rockBias = math.sin(tiltZ) * 6;

                      // How far the top cap has sunk in right now (0 = not
                      // pressed, 1 = fully pressed). elasticOut on release
                      // briefly overshoots past 1 and back, which is what
                      // gives the little springy "pop" as it comes back up.
                      final pressT = _pressAnimation.value;
                      final pressSink = pressT * 5.2;

                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (_) => _setLoginPressed(true),
                        onTapUp: (_) {
                          _setLoginPressed(false);
                          _validateLogin();
                        },
                        onTapCancel: () => _setLoginPressed(false),
                        child: Transform.translate(
                          offset: Offset(
                            floatX,
                            floatY,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              // ------------------------------------------------
                              // SUBMERGED SHADOW + WATER REFLECTION
                              // Raised close to the capsule.
                              // ------------------------------------------------
                              Positioned(
                                top: 27,
                                child: CustomPaint(
                                  size: const Size(300, 72),
                                  painter: LoginWaterReflectionPainter(
                                    loginValue,
                                  ),
                                ),
                              ),

                              // ------------------------------------------------
                              // WATER RIPPLE RINGS
                              //
                              // Sized and centered to fully surround the
                              // capsule (above, below, and both sides) so
                              // ripples born at its contact edge can
                              // expand outward in every direction, not
                              // just downward into the space below it.
                              // ------------------------------------------------
                              Positioned(
                                top: -49,
                                child: CustomPaint(
                                  size: const Size(380, 160),
                                  painter: LoginWaterRipplePainter(
                                    loginValue,
                                    rockBias,
                                  ),
                                ),
                              ),

                              // ------------------------------------------------
                              // EXISTING 3D TILTED CAPSULE
                              // ------------------------------------------------
                              Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.0028)
                                  ..rotateX(tiltX)
                                  ..rotateZ(tiltZ),
                                child: Container(
                                  width: 260,
                                  height: 62,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(40),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xff063F52)
                                            .withOpacity(.62),
                                        blurRadius: 24,
                                        spreadRadius: -3,
                                        offset: const Offset(0, 26),
                                      ),
                                      BoxShadow(
                                        color: const Color(0xff54C9F4)
                                            .withOpacity(.30),
                                        blurRadius: 28,
                                        spreadRadius: 1,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    clipBehavior: Clip.none,
                                    children: [
                                      // ----------------------------------------
                                      // LOWER SUBMERGED PART
                                      // ----------------------------------------
                                      Positioned(
                                        left: 1,
                                        right: 1,
                                        top: 11,
                                        bottom: 0,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              40,
                                            ),
                                            gradient: const LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Color(0xff8FC4D8),
                                                Color(0xff3D7E99),
                                                Color(0xff123444),
                                              ],
                                            ),
                                            border: Border.all(
                                              color: const Color(0xff6DC9E7),
                                              width: 1.2,
                                            ),
                                          ),
                                        ),
                                      ),

                                      // ----------------------------------------
                                      // MAIN TOP SURFACE
                                      // ----------------------------------------
                                      Positioned(
                                        left: 0,
                                        right: 0,
                                        top: 0,
                                        bottom: 11,
                                        // The top cap slides DOWN into the
                                        // capsule as it's pressed (not the
                                        // whole button dropping) — the same
                                        // feel as a phone/keyboard key being
                                        // pushed into its housing.
                                        child: Transform.translate(
                                          offset: Offset(0, pressSink),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(
                                                40,
                                              ),
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
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 1.6,
                                              ),
                                              boxShadow: [
                                                // Top highlight fades as it
                                                // sinks — less light catches
                                                // the edge the deeper it goes.
                                                BoxShadow(
                                                  color: Colors.white.withOpacity(
                                                    .80 * (1 - pressT * .6),
                                                  ),
                                                  blurRadius: 5,
                                                  spreadRadius: -1,
                                                  offset: const Offset(0, -1),
                                                ),
                                                // Under-shadow tightens and
                                                // darkens — the cap is now
                                                // closer to/pressing into the
                                                // capsule body beneath it.
                                                BoxShadow(
                                                  color: const Color(0xff2D7793)
                                                      .withOpacity(
                                                    .40 + pressT * .30,
                                                  ),
                                                  blurRadius: 6 - pressT * 3,
                                                  spreadRadius: -pressT * 1.2,
                                                  offset: Offset(
                                                    0,
                                                    5 - pressT * 3,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            child: Stack(
                                              children: [
                                                Positioned(
                                                  left: 24,
                                                  right: 24,
                                                  top: 3,
                                                  child: Container(
                                                    height: 6,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                      BorderRadius.circular(20),
                                                      gradient: LinearGradient(
                                                        begin: Alignment.centerLeft,
                                                        end: Alignment.centerRight,
                                                        colors: [
                                                          const Color(0xff2D7793)
                                                              .withOpacity(0.0),
                                                          const Color(0xff2D7793)
                                                              .withOpacity(0.22),
                                                          const Color(0xff2D7793)
                                                              .withOpacity(0.0),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),

                                                Positioned(
                                                  left: 28,
                                                  right: 28,
                                                  bottom: 3,
                                                  child: Container(
                                                    height: 12,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                      BorderRadius.circular(20),
                                                      gradient: LinearGradient(
                                                        begin: Alignment.centerLeft,
                                                        end: Alignment.centerRight,
                                                        colors: [
                                                          Colors.white.withOpacity(
                                                            0.0,
                                                          ),
                                                          Colors.white.withOpacity(
                                                            0.95,
                                                          ),
                                                          Colors.white.withOpacity(
                                                            0.0,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),

                                                const Center(
                                                  child: Row(
                                                    mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                    children: [
                                                      Text(
                                                        'Login',
                                                        style: TextStyle(
                                                          color: Color(0xff1263A2),
                                                          fontSize: 22,
                                                          fontWeight:
                                                          FontWeight.bold,
                                                          shadows: [
                                                            Shadow(
                                                              color: Colors.white,
                                                              blurRadius: 2,
                                                              offset: Offset(0, 1),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      SizedBox(width: 45),
                                                      Icon(
                                                        Icons.arrow_forward,
                                                        color: Color(0xff1263A2),
                                                        size: 28,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),

                                      // ----------------------------------------
                                      // WATERLINE
                                      // Directly over the capsule's
                                      // lower water-contact edge.
                                      // ----------------------------------------
                                      Positioned(
                                        left: 14,
                                        right: 14,
                                        bottom: 7,
                                        child: IgnorePointer(
                                          child: CustomPaint(
                                            size: const Size(232, 9),
                                            painter: LoginWaterlinePainter(
                                              loginValue,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // ------------------------------------------------
                              // FRONT / SIDE CONTACT FOAM
                              // Raised to meet the capsule.
                              // ------------------------------------------------
                              Positioned(
                                top: 42,
                                child: IgnorePointer(
                                  child: CustomPaint(
                                    size: const Size(300, 42),
                                    painter: LoginContactFoamPainter(
                                      loginValue,
                                      rockBias,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),


                  const SizedBox(height: 35),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _line(),
                      const SizedBox(width: 12),
                      Text(
                        'or continue with',
                        style: TextStyle(
                          color: Colors.white.withOpacity(.85),
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _line(),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SocialButton(
                        animationValue: loginValue,
                        phase: 0.00,
                        child: const Text(
                          'G',
                          style: TextStyle(
                            fontSize: 37,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff4285F4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 45),
                      SocialButton(
                        animationValue: loginValue,
                        phase: 0.38,
                        child: const Icon(
                          Icons.apple,
                          color: Colors.black,
                          size: 38,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "Don't have an account? ",
                          style: TextStyle(
                            color: Colors.white.withOpacity(.85),
                            fontSize: 15,
                          ),
                        ),
                        const TextSpan(
                          text: 'Signup',
                          style: TextStyle(
                            color: Color(0xff4DC8F4),
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 35),

                ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
          },
        ),
      ),
    );
  }

  Widget _line() {
    return Container(
      width: 80,
      height: 1,
      color: Colors.white.withOpacity(.45),
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
      width: 255 + pulse * 12,
      height: 34 + pulse * 5,
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

      final y = center.dy - 13 + p * 27;

      final width = 45 + math.sin(p * math.pi) * 105;

      final drift = math.sin(t * 1.4 + i * .75) * (3 + p * 7);

      final opacity = (.045 + math.sin(t * 1.8 + i) * .018).clamp(.015, .08).toDouble();

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

      final baseOpacity = (.20 * fade * ringStrength * (1 - p * .3)).clamp(
        0.0,
        .26,
      ).toDouble();

      if (baseOpacity < .006) continue;

      final rx = 18 + p * 236;
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
        final strokeWidth = (baseStrokeWidth * (.5 + segStrength * .8)).clamp(
          .9,
          4.2,
        ).toDouble();

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

    final floatBob =
        math.sin(t * .82) * 5.6 +
            math.sin(t * 1.37 + .8) * 2.3;

    final bobVelocity =
        math.cos(t * .82) * .82 * 5.6 +
            math.cos(t * 1.37 + .8) * 1.37 * 2.3;

    final downwardImpact =
    (bobVelocity / 6.0).clamp(0.0, 1.0).toDouble();

    final waterY =
        12 +
            floatBob * .65 +
            math.sin(t * 1.15) * 1.4;

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

        final buttonPressure =
            envelope * (1.5 + downwardImpact * 3.2);

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
          ..color = Colors.white.withOpacity(
            .045 + (3 - wave) * .025,
          )
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
            (animationValue * 1.18 +
                wave * .19 +
                (side > 0 ? .47 : 0.0)) %
                1.0;

        final approach = Curves.easeInOut.transform(raw);
        final startDistance = 175.0 + wave * 8.0;
        final contactDistance = buttonHalf - 3.0;

        final distance =
            startDistance +
                (contactDistance - startDistance) * approach;

        final x = cx + side * distance;
        final impact = math.sin(approach * math.pi);

        final waveHeight =
            1.2 + impact * 4.5 + downwardImpact * 2.0;

        final path = Path();
        const spread = 34.0;

        for (int i = -10; i <= 10; i++) {
          final p = i / 10;
          final localX = x + p * spread;
          final envelope = math.exp(-p * p * 2.2);

          final ripple =
              math.sin(
                p * math.pi * 2.7 + t * 2.2 + wave * 1.5,
              ) * (.45 + impact * .9);

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
          final burst = math.sin(
            ((approach - .78) / .16) * math.pi,
          );

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
            t * (.16 + _hash(seed) * .08) +
                _hash(seed + 2.0) * math.pi * 2;

        final climb = .5 + .5 * math.sin(phase);
        final strength = .35 + _hash(seed + 4.2) * .65;
        final rise = climb * climb * strength;
        final maxRise = 5.0 + _hash(seed + 7.0) * 11.0;
        final streamRise = rise * maxRise;

        final x = cx +
            side * (buttonHalf - 2 + stream * .65);

        final path = Path();

        for (int i = 0; i <= 18; i++) {
          final p = i / 18;

          final y = waterY - streamRise * p;
          final drift =
              math.sin(p * math.pi * 2 + phase * 1.3 + stream) *
                  (.7 + p * 1.7);

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
          (i / particleCount) * math.pi * 2 +
              (_hash(seed) - .5) * .20;

      final radius = 118 + _hash(seed + 3) * 36;

      final bob = math.sin(
        t * (1.0 + _hash(seed + 6) * .8) +
            _hash(seed + 9) * math.pi * 2,
      );

      final x = cx + math.cos(angle) * radius + bob * 1.2;
      final y = waterY + math.sin(angle) * radius * .12 + bob * .8;

      final proximity =
      (1 - ((radius - 118) / 36)).clamp(0.0, 1.0).toDouble();

      final opacity =
          (.018 + _hash(seed + 11) * .045) * proximity;

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
// BOAT
// ============================================================================

class BoatPainter extends CustomPainter {
  final double animationValue;
  final int boatIndex;

  BoatPainter(this.animationValue, this.boatIndex);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;

    final hull = Path()
      ..moveTo(18, 25)
      ..quadraticBezierTo(8, 27, 12, 41)
      ..quadraticBezierTo(21, 79, 57, 99)
      ..quadraticBezierTo(w * .5, 116, w - 57, 99)
      ..quadraticBezierTo(w - 21, 79, w - 12, 41)
      ..quadraticBezierTo(w - 8, 27, w - 18, 25)
      ..quadraticBezierTo(w * .5, 18, 18, 25)
      ..close();

    canvas.drawPath(
      hull,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xffffffff),
            Color(0xffEAF5FA),
            Color(0xffC5DDE8),
            Color(0xff789FAF),
          ],
          stops: [0, .32, .66, 1],
        ).createShader(Rect.fromLTWH(0, 0, w, 125)),
    );

    canvas.drawPath(
      hull,
      Paint()
        ..color = const Color(0xffB9E8FA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );

    final inside = Path()
      ..moveTo(34, 31)
      ..quadraticBezierTo(23, 34, 31, 49)
      ..quadraticBezierTo(50, 67, w * .5, 73)
      ..quadraticBezierTo(w - 50, 67, w - 31, 49)
      ..quadraticBezierTo(w - 23, 34, w - 34, 31)
      ..quadraticBezierTo(w * .5, 24, 34, 31)
      ..close();

    canvas.drawPath(
      inside,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xffF7FCFF), Color(0xffDCEEF6), Color(0xffB5D2DE)],
        ).createShader(Rect.fromLTWH(0, 20, w, 60)),
    );

    final lowerHull = Path()
      ..moveTo(22, 57)
      ..quadraticBezierTo(43, 100, w * .5, 111)
      ..quadraticBezierTo(w - 43, 100, w - 22, 57)
      ..quadraticBezierTo(w * .5, 82, 22, 57)
      ..close();

    canvas.drawPath(
      lowerHull,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x557BA6B6), Color(0xAA527D8D), Color(0xE03A5968)],
        ).createShader(Rect.fromLTWH(0, 50, w, 62)),
    );

    final edge = Path()
      ..moveTo(34, 86)
      ..quadraticBezierTo(w * .5, 112, w - 34, 86);

    canvas.drawPath(
      edge,
      Paint()
        ..color = const Color(0xff355D6D).withOpacity(.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );

    final highlight = Path()
      ..moveTo(30, 69)
      ..quadraticBezierTo(w * .5, 94, w - 30, 69);

    canvas.drawPath(
      highlight,
      Paint()
        ..color = Colors.white.withOpacity(.36)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );

    final left = Path()
      ..moveTo(18, 29)
      ..quadraticBezierTo(21, 64, 54, 91);

    final right = Path()
      ..moveTo(w - 18, 29)
      ..quadraticBezierTo(w - 21, 64, w - 54, 91);

    for (final path in [left, right]) {
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xff59C9F2).withOpacity(.38)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round,
      );
    }

    canvas.drawArc(
      Rect.fromCenter(center: Offset(w / 2, 109), width: w * .74, height: 7),
      0,
      math.pi,
      false,
      Paint()
        ..color = const Color(0xffE8FFFF).withOpacity(.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .9,
    );

    final top = Path()
      ..moveTo(48, 28)
      ..quadraticBezierTo(w * .5, 20, w - 48, 28);

    canvas.drawPath(
      top,
      Paint()
        ..color = Colors.white.withOpacity(.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant BoatPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.boatIndex != boatIndex;
  }
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
    final bob =
        math.sin(t * .82) * 5.6 +
            math.sin(t * 1.37 + .8) * 2.3;

    // Same subtle horizontal drift as the Login button.
    final drift =
        math.sin(t * .43 + 1.2) * 2.7;

    // Same top-view rocking/perspective as the Login button.
    final tiltX =
        -(math.pi * 52.5 / 180) +
            math.sin(t * .78 + .6) * (math.pi * 10 / 180);

    final tiltZ =
        math.sin(t * .72 + .35) * (math.pi * 4.6 / 180) +
            math.sin(t * 1.17 + 1.1) * (math.pi * 1.7 / 180);

    final shadowScale =
        1.0 + math.sin(t * .82 + .35) * .07;

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
  final double referenceHeight;

  RealisticOceanPainter(
    this.t, {
    required this.referenceHeight,
  });

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
    // Keep the original sky/sun proportions based on the phone viewport,
    // while allowing the water itself to continue through the full
    // scrollable content height.
    final horizon = referenceHeight * .48;

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

    final sun = Offset(size.width * .78, referenceHeight * .19);

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
