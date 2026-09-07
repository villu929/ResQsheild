import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'permission_screen.dart';

void main() {
  runApp(const WaterWavesApp());
}

// ============================================================================
// APP ENTRY POINT FOR PREVIEW / TESTING
// ============================================================================

class WaterWavesApp extends StatelessWidget {
  const WaterWavesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ResQShield - OTP Verification',
      home: WaterWavesScreen(),
    );
  }
}

// Convenient alias for code clarity
typedef OtpScreen = WaterWavesScreen;

// Button state enum
enum VerifyButtonState { idle, loading, success }

// ============================================================================
// OTP VERIFICATION SCREEN
// ============================================================================

class WaterWavesScreen extends StatefulWidget {
  const WaterWavesScreen({super.key});

  @override
  State<WaterWavesScreen> createState() => _WaterWavesScreenState();
}

class _WaterWavesScreenState extends State<WaterWavesScreen>
    with TickerProviderStateMixin {
  // --------------------------------------------------------------------------
  // ANIMATION CONTROLLERS
  // --------------------------------------------------------------------------
  late final AnimationController _logoController;
  late final Animation<double> _logoFloating;
  late final Animation<double> _logoScale;

  late final AnimationController _waveController;
  late final AnimationController _pulseController;
  late final Animation<double> _timerPulse;

  // --------------------------------------------------------------------------
  // OTP STATE & CONTROLLERS
  // --------------------------------------------------------------------------
  static const int _otpLength = 6;
  final List<TextEditingController> _otpControllers = List.generate(
    _otpLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(
    _otpLength,
    (_) => FocusNode(),
  );
  final List<bool> _isFocusedList = List.generate(_otpLength, (_) => false);

  // --------------------------------------------------------------------------
  // PHONE & RESEND TIMER STATE
  // --------------------------------------------------------------------------
  String _phoneNumber = '+91 98765 43210';
  static const int _initialCountdown = 48;
  int _secondsRemaining = _initialCountdown;
  Timer? _timer;
  bool _isResending = false;

  // --------------------------------------------------------------------------
  // VERIFY BUTTON STATE
  // --------------------------------------------------------------------------
  VerifyButtonState _verifyState = VerifyButtonState.idle;
  bool _buttonPressed = false;
  bool _backPressed = false;

  @override
  void initState() {
    super.initState();

    // 1. Logo breathing & floating animation (3.5s cycle, 2-3px vertical, scale 1.0 -> 1.015)
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);

    _logoFloating = Tween<double>(begin: 0.0, end: -2.5).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOutSine),
    );

    _logoScale = Tween<double>(begin: 1.0, end: 1.015).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOutSine),
    );

    // 2. Calm bottom water wave animation (12s cycle)
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // 4. Timer pulse animation for last 10 seconds
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _timerPulse = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Focus listeners for smooth borders and lift
    for (int i = 0; i < _otpLength; i++) {
      final index = i;
      _otpFocusNodes[index].addListener(() {
        setState(() {
          _isFocusedList[index] = _otpFocusNodes[index].hasFocus;
        });
      });
    }

    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    _secondsRemaining = _initialCountdown;
    _pulseController.reset();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
          if (_secondsRemaining <= 10 && _secondsRemaining > 0) {
            if (!_pulseController.isAnimating) {
              _pulseController.repeat(reverse: true);
            }
          } else {
            if (_pulseController.isAnimating) {
              _pulseController.reset();
            }
          }
        } else {
          timer.cancel();
          _pulseController.reset();
        }
      });
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _waveController.dispose();
    _pulseController.dispose();
    _timer?.cancel();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // OTP LOGIC & KEYBOARD HANDLING
  // --------------------------------------------------------------------------
  void _onOtpChanged(String value, int index) {
    if (value.length > 1) {
      // Handle paste of multiple characters (e.g. 6-digit OTP from clipboard)
      final digits = value.replaceAll(RegExp(r'\D'), '');
      if (digits.isNotEmpty) {
        for (int i = 0; i < _otpLength; i++) {
          if (i < digits.length) {
            _otpControllers[i].text = digits[i];
          }
        }
        final nextFocus = math.min(digits.length, _otpLength - 1);
        _otpFocusNodes[nextFocus].requestFocus();
      }
      setState(() {});
      return;
    }

    if (value.isNotEmpty) {
      // Automatically advance to next box
      if (index < _otpLength - 1) {
        _otpFocusNodes[index + 1].requestFocus();
      } else {
        _otpFocusNodes[index].unfocus();
      }
    }
    setState(() {});
  }

  void _onOtpKeyEvent(KeyEvent event, int index) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_otpControllers[index].text.isEmpty && index > 0) {
        _otpFocusNodes[index - 1].requestFocus();
        _otpControllers[index - 1].clear();
        setState(() {});
      }
    }
  }

  String get _currentOtp {
    return _otpControllers.map((c) => c.text).join();
  }

  // --------------------------------------------------------------------------
  // ACTIONS: RESEND & VERIFY
  // --------------------------------------------------------------------------
  Future<void> _handleResend() async {
    if (_secondsRemaining > 0 || _isResending) return;

    setState(() {
      _isResending = true;
    });

    // Brief progress indicator
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;

    setState(() {
      _isResending = false;
      for (final c in _otpControllers) {
        c.clear();
      }
    });

    _startCountdown();
    _otpFocusNodes[0].requestFocus();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('New 6-digit code sent to $_phoneNumber'),
        backgroundColor: const Color(0xFF013973),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _handleVerify() async {
    if (_verifyState != VerifyButtonState.idle) return;

    final otp = _currentOtp;
    if (otp.length < _otpLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter all 6 digits of the OTP'),
          backgroundColor: const Color(0xFF013973),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    // IDLE -> LOADING
    setState(() {
      _verifyState = VerifyButtonState.loading;
    });

    // Simulate government-grade secure OTP verification
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;

    // LOADING -> SUCCESS
    setState(() {
      _verifyState = VerifyButtonState.success;
    });

    // Smooth transition to Permission Screen
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const PermissionScreen()),
    );
  }

  void _showEditPhoneDialog() {
    final textCtrl = TextEditingController(text: _phoneNumber);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Edit Phone Number',
          style: TextStyle(
            color: Color(0xFF013973),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: TextField(
          controller: textCtrl,
          keyboardType: TextInputType.phone,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '+91 98765 43210',
            filled: true,
            fillColor: const Color(0xFFF1F5F9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              if (textCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _phoneNumber = textCtrl.text.trim();
                  _startCountdown();
                });
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0077C8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // UI BUILD
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isReducedMotion = media.disableAnimations;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF0F6FA),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double w = constraints.maxWidth;
          final double h = constraints.maxHeight;

          // Responsive scaling directly driven by constraints:
          // Reference viewport: 390w x 844h
          final double scaleW = (w / 390.0).clamp(0.65, 1.45);
          final double scaleH = (h / 844.0).clamp(0.60, 1.35);
          final double textScale = (w / 390.0).clamp(0.70, 1.35);

          // Sleek, well-proportioned dimensions (not crowded / not "bhra bhra")
          final double logoSize = (46.0 * scaleH).clamp(34.0, 58.0);
          final double titleFontSize = (19.0 * textScale).clamp(15.0, 24.0);
          final double qFontSize = (21.5 * textScale).clamp(17.0, 27.0);
          final double taglineFontSize = (8.5 * textScale).clamp(7.0, 10.5);

          final double cardPaddingH = (18.0 * scaleW).clamp(14.0, 22.0);
          final double cardPaddingV = (14.0 * scaleH).clamp(10.0, 18.0);
          final double cardTitleSize = (17.5 * textScale).clamp(14.5, 21.0);
          final double cardSubtitleSize = (11.5 * textScale).clamp(9.5, 13.5);
          final double cardPhoneSize = (12.5 * textScale).clamp(10.5, 14.5);

          // 6 OTP boxes responsive width & height (sleek rounded boxes)
          final double boxWidth =
              ((w - (44.0 * scaleW).clamp(32.0, 56.0) - (2 * cardPaddingH) - (5 * 6.0)) / 6)
                  .clamp(31.0, 42.0);
          final double boxHeight = (boxWidth * 1.15).clamp(36.0, 48.0);
          final double digitSize = (16.5 * textScale).clamp(13.5, 20.0);

          final double timerSize = (11.5 * textScale).clamp(9.5, 13.5);
          final double btnHeight = (40.0 * scaleH).clamp(36.0, 44.0);
          final double btnFontSize = (13.5 * textScale).clamp(12.0, 15.5);
          final double btnIconSize = (15.0 * textScale).clamp(13.0, 17.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              // ── 1. EXACT USER PROVIDED BACKGROUND IMAGE ──
              Positioned.fill(
                child: Image.asset(
                  'assets/images/otp_bg.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),

              // ── 2. BOTTOM CALM REALISTIC WATER WAVES (ANIMATION PRESERVED) ──
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: (h * 0.18).clamp(80.0, 145.0),
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, _) {
                      final progress = isReducedMotion ? 0.0 : _waveController.value;
                      return CustomPaint(
                        painter: _CalmRealisticWaterPainter(progress),
                        size: Size.infinite,
                      );
                    },
                  ),
                ),
              ),

              // ── 3. SINGLE-SCREEN NON-SCROLLABLE CONTENT ──
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: (20.0 * scaleW).clamp(16.0, 28.0),
                    vertical: (6.0 * scaleH).clamp(4.0, 10.0),
                  ),
                  child: Column(
                    children: [
                      // Top Header Row with Back Button
                      Row(
                        children: [
                          _buildBackButton(scaleW, scaleH),
                          const Spacer(),
                        ],
                      ),

                      const Spacer(flex: 1),

                      // ── 1. LOGO & BRAND HEADER ──
                      _buildLogoHeader(
                        isReducedMotion,
                        logoSize,
                        titleFontSize,
                        qFontSize,
                        taglineFontSize,
                        scaleH,
                      ),

                      const Spacer(flex: 2),

                      // ── 2. OTP VERIFICATION CARD (FITS 1 SCREEN) ──
                      _buildOtpCard(
                        scaleW: scaleW,
                        scaleH: scaleH,
                        textScale: textScale,
                        paddingH: cardPaddingH,
                        paddingV: cardPaddingV,
                        titleSize: cardTitleSize,
                        subtitleSize: cardSubtitleSize,
                        phoneSize: cardPhoneSize,
                        boxWidth: boxWidth,
                        boxHeight: boxHeight,
                        digitSize: digitSize,
                        timerSize: timerSize,
                        btnHeight: btnHeight,
                        btnFontSize: btnFontSize,
                        btnIconSize: btnIconSize,
                      ),

                      const Spacer(flex: 3),
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
  // BACK BUTTON
  // --------------------------------------------------------------------------
  Widget _buildBackButton(double scaleW, double scaleH) {
    final double btnDim = (38.0 * scaleH).clamp(32.0, 44.0);

    return GestureDetector(
      onTapDown: (_) => setState(() => _backPressed = true),
      onTapUp: (_) {
        setState(() => _backPressed = false);
        Navigator.maybePop(context);
      },
      onTapCancel: () => setState(() => _backPressed = false),
      child: AnimatedScale(
        scale: _backPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 140),
        child: Container(
          width: btnDim,
          height: btnDim,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0E000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.chevron_left_rounded,
              color: const Color(0xFF1E293B),
              size: (24.0 * scaleW).clamp(20.0, 28.0),
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // LOGO & BRAND HEADER (SUBTLE FLOATING)
  // --------------------------------------------------------------------------
  Widget _buildLogoHeader(
    bool isReducedMotion,
    double logoSize,
    double titleFontSize,
    double qFontSize,
    double taglineFontSize,
    double scaleH,
  ) {
    Widget logoWidget = Image.asset(
      'assets/images/app_logo.png',
      width: logoSize,
      height: logoSize,
      fit: BoxFit.contain,
    );

    if (!isReducedMotion) {
      logoWidget = AnimatedBuilder(
        animation: _logoController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _logoFloating.value),
            child: Transform.scale(
              scale: _logoScale.value,
              child: child,
            ),
          );
        },
        child: logoWidget,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        logoWidget,
        SizedBox(height: (6.0 * scaleH).clamp(3.0, 10.0)),

        // Brand Name: Res (Blue), Q (Green), Shield (Blue)
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
                  letterSpacing: 0.4,
                ),
              ),
              TextSpan(
                text: 'Q',
                style: TextStyle(
                  color: const Color(0xFF00FF00),
                  fontSize: qFontSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                  shadows: const [
                    Shadow(
                      color: Color(0x6600FF00),
                      blurRadius: 6,
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
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: (2.0 * scaleH).clamp(1.0, 4.0)),

        // Tagline
        Text(
          'SAFER ROUTES. STRONGER COMMUNITIES.',
          style: TextStyle(
            color: const Color(0xFF013973),
            fontSize: taglineFontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // MAIN OTP CARD (FITS 1 SCREEN)
  // --------------------------------------------------------------------------
  Widget _buildOtpCard({
    required double scaleW,
    required double scaleH,
    required double textScale,
    required double paddingH,
    required double paddingV,
    required double titleSize,
    required double subtitleSize,
    required double phoneSize,
    required double boxWidth,
    required double boxHeight,
    required double digitSize,
    required double timerSize,
    required double btnHeight,
    required double btnFontSize,
    required double btnIconSize,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: paddingV),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular((22.0 * scaleW).clamp(16.0, 26.0)),
        border: Border.all(color: const Color(0xFFE2EDF5), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C013973),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Verify OTP',
            style: TextStyle(
              color: const Color(0xFF0F172A),
              fontSize: titleSize,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),

          SizedBox(height: (4.0 * scaleH).clamp(2.0, 6.0)),

          // Subtitle
          Text(
            "We've sent a 6-digit code to",
            style: TextStyle(
              color: const Color(0xFF64748B),
              fontSize: subtitleSize,
              fontWeight: FontWeight.w500,
            ),
          ),

          SizedBox(height: (2.0 * scaleH).clamp(1.0, 4.0)),

          // Phone Row with Edit Icon
          Row(
            children: [
              Text(
                _phoneNumber,
                style: TextStyle(
                  color: const Color(0xFF0F172A),
                  fontSize: phoneSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _showEditPhoneDialog,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: Icon(
                    Icons.edit_outlined,
                    size: (15.0 * scaleW).clamp(13.0, 18.0),
                    color: const Color(0xFF0077C8).withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: (14.0 * scaleH).clamp(8.0, 20.0)),

          // ── 6 OTP BOXES ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_otpLength, (index) {
              return _buildSingleOtpBox(index, boxWidth, boxHeight, digitSize);
            }),
          ),

          SizedBox(height: (12.0 * scaleH).clamp(6.0, 16.0)),

          // ── RESEND OTP SECTION ──
          _buildResendSection(timerSize),

          SizedBox(height: (14.0 * scaleH).clamp(8.0, 18.0)),

          // ── VERIFY & CONTINUE BUTTON ──
          _buildVerifyButton(btnHeight, btnFontSize, btnIconSize),

          SizedBox(height: (10.0 * scaleH).clamp(6.0, 14.0)),

          // ── DIDN'T RECEIVE THE CODE? RESEND OTP ──
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Didn't receive the code?",
                  style: TextStyle(
                    color: const Color(0xFF64748B),
                    fontSize: (11.5 * textScale).clamp(9.5, 13.0),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: _handleResend,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                    child: Text(
                      'Resend OTP',
                      style: TextStyle(
                        color: _secondsRemaining == 0
                            ? const Color(0xFF0077C8)
                            : const Color(0xFF0077C8).withValues(alpha: 0.75),
                        fontSize: (12.5 * textScale).clamp(10.5, 14.0),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
  // SINGLE OTP BOX (FOCUS GLOW + LIFT + FADE/SCALE ON DIGIT)
  // --------------------------------------------------------------------------
  Widget _buildSingleOtpBox(int index, double width, double height, double digitSize) {
    final isFocused = _isFocusedList[index];
    final hasValue = _otpControllers[index].text.isNotEmpty;

    return Focus(
      onKeyEvent: (node, event) {
        _onOtpKeyEvent(event, index);
        return KeyEventResult.ignored;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: width,
        height: height,
        transform: Matrix4.translationValues(0, isFocused ? -2.0 : 0.0, 0),
        decoration: BoxDecoration(
          color: isFocused ? Colors.white : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: isFocused
                ? const Color(0xFF0077C8)
                : (hasValue ? const Color(0xFF94A3B8) : const Color(0xFFE2E8F0)),
            width: isFocused ? 1.8 : 1.2,
          ),
          boxShadow: isFocused
              ? [
                  BoxShadow(
                    color: const Color(0xFF0077C8).withValues(alpha: 0.18),
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  const BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Underlying TextField for keyboard handling
            TextField(
              controller: _otpControllers[index],
              focusNode: _otpFocusNodes[index],
              autofocus: index == 0,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              showCursor: false,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              style: const TextStyle(color: Colors.transparent),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              onChanged: (val) => _onOtpChanged(val, index),
            ),

            // Visible smooth animated digit (Fade + Scale on entry, duration ~160ms)
            IgnorePointer(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.85, end: 1.0).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  _otpControllers[index].text,
                  key: ValueKey(_otpControllers[index].text),
                  style: TextStyle(
                    color: const Color(0xFF0F172A),
                    fontSize: digitSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // RESEND TIMER ROW
  // --------------------------------------------------------------------------
  Widget _buildResendSection(double timerSize) {
    final String minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final String seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    final bool isLast10Sec = _secondsRemaining <= 10 && _secondsRemaining > 0;

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time_rounded,
            size: (timerSize * 1.25).clamp(13.0, 18.0),
            color: isLast10Sec ? const Color(0xFF0077C8) : const Color(0xFF64748B),
          ),
          const SizedBox(width: 6),
          if (_isResending) ...[
            SizedBox(
              width: (timerSize * 1.1).clamp(12.0, 16.0),
              height: (timerSize * 1.1).clamp(12.0, 16.0),
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Color(0xFF0077C8)),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Sending code...',
              style: TextStyle(
                color: const Color(0xFF64748B),
                fontSize: timerSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else if (_secondsRemaining > 0) ...[
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = isLast10Sec ? _timerPulse.value : 1.0;
                return Transform.scale(
                  scale: scale,
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Resend OTP in ',
                          style: TextStyle(
                            color: const Color(0xFF64748B),
                            fontSize: timerSize,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: '$minutes:$seconds',
                          style: TextStyle(
                            color: isLast10Sec
                                ? const Color(0xFF0077C8)
                                : const Color(0xFF013973),
                            fontSize: timerSize,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ] else ...[
            GestureDetector(
              onTap: _handleResend,
              child: Text(
                'Resend OTP',
                style: TextStyle(
                  color: const Color(0xFF0077C8),
                  fontSize: timerSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // VERIFY & CONTINUE BUTTON (IDLE -> LOADING -> SUCCESS)
  // --------------------------------------------------------------------------
  Widget _buildVerifyButton(double btnHeight, double btnFontSize, double btnIconSize) {
    Color btnBgColor;
    Gradient? btnGradient;

    switch (_verifyState) {
      case VerifyButtonState.idle:
        btnBgColor = const Color(0xFF0077C8);
        btnGradient = const LinearGradient(
          colors: [Color(0xFF0077C8), Color(0xFF015294)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
        break;
      case VerifyButtonState.loading:
        btnBgColor = const Color(0xFF0077C8);
        btnGradient = const LinearGradient(
          colors: [Color(0xFF0077C8), Color(0xFF015294)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
        break;
      case VerifyButtonState.success:
        btnBgColor = const Color(0xFF16A34A); // Government-grade ResQShield green
        btnGradient = const LinearGradient(
          colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
        break;
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _buttonPressed = true),
      onTapUp: (_) {
        setState(() => _buttonPressed = false);
        _handleVerify();
      },
      onTapCancel: () => setState(() => _buttonPressed = false),
      child: AnimatedScale(
        scale: _buttonPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 140),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          height: btnHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: btnBgColor,
            gradient: btnGradient,
            borderRadius: BorderRadius.circular(24.0),
            boxShadow: [
              BoxShadow(
                color: (_verifyState == VerifyButtonState.success
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF0077C8))
                    .withValues(alpha: 0.32),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _buildButtonContent(btnFontSize, btnIconSize),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonContent(double btnFontSize, double btnIconSize) {
    switch (_verifyState) {
      case VerifyButtonState.idle:
        return Row(
          key: const ValueKey('idle'),
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Verify & Continue',
              style: TextStyle(
                color: Colors.white,
                fontSize: btnFontSize,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: btnIconSize),
          ],
        );

      case VerifyButtonState.loading:
        return Row(
          key: const ValueKey('loading'),
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: btnIconSize,
              height: btnIconSize,
              child: const CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Verifying...',
              style: TextStyle(
                color: Colors.white,
                fontSize: btnFontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );

      case VerifyButtonState.success:
        return Row(
          key: const ValueKey('success'),
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: btnIconSize + 1),
            const SizedBox(width: 8),
            Text(
              'Verified ✓',
              style: TextStyle(
                color: Colors.white,
                fontSize: btnFontSize,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        );
    }
  }
}

// ============================================================================
// CALM REALISTIC WATER WAVES PAINTER
// ----------------------------------------------------------------------------
// Extremely slow, gentle horizontal movement (10-15s cycle) of calm water layers
// ============================================================================

class _CalmRealisticWaterPainter extends CustomPainter {
  final double progress;

  _CalmRealisticWaterPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final t = progress * math.pi * 2;

    // Layer 1: Deep Back Wave
    final path1 = Path();
    path1.moveTo(0, h);
    for (double x = 0; x <= w; x += 3) {
      final y = h * 0.45 +
          math.sin(x * 0.012 + t * 0.8) * 8.0 +
          math.sin(x * 0.024 - t * 0.5) * 4.0;
      path1.lineTo(x, y);
    }
    path1.lineTo(w, h);
    path1.close();
    canvas.drawPath(
      path1,
      Paint()..color = const Color(0xFF1E6F9F).withValues(alpha: 0.22),
    );

    // Layer 2: Mid Calm Water
    final path2 = Path();
    path2.moveTo(0, h);
    for (double x = 0; x <= w; x += 3) {
      final y = h * 0.58 +
          math.sin(x * 0.014 - t * 1.1 + 1.5) * 7.0 +
          math.sin(x * 0.028 + t * 0.7) * 3.5;
      path2.lineTo(x, y);
    }
    path2.lineTo(w, h);
    path2.close();
    canvas.drawPath(
      path2,
      Paint()..color = const Color(0xFF2980B9).withValues(alpha: 0.38),
    );

    // Layer 3: Foreground Calm Water with Soft Highlight
    final path3 = Path();
    path3.moveTo(0, h);
    for (double x = 0; x <= w; x += 3) {
      final y = h * 0.70 +
          math.sin(x * 0.016 + t * 1.0 + 3.0) * 6.0 +
          math.sin(x * 0.032 - t * 0.9) * 2.5;
      path3.lineTo(x, y);
    }
    path3.lineTo(w, h);
    path3.close();

    final paint3 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF3498DB).withValues(alpha: 0.55),
          const Color(0xFF0F52BA).withValues(alpha: 0.75),
        ],
      ).createShader(Rect.fromLTWH(0, h * 0.65, w, h * 0.35));

    canvas.drawPath(path3, paint3);

    // Subtle Surface Water Crest Line
    final crestPath = Path();
    for (double x = 0; x <= w; x += 4) {
      final y = h * 0.70 +
          math.sin(x * 0.016 + t * 1.0 + 3.0) * 6.0 +
          math.sin(x * 0.032 - t * 0.9) * 2.5;
      if (x == 0) {
        crestPath.moveTo(x, y);
      } else {
        crestPath.lineTo(x, y);
      }
    }
    canvas.drawPath(
      crestPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _CalmRealisticWaterPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
