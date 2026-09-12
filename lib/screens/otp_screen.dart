import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'citizen/citizen_dashboard_screen.dart';

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


    // 4. Timer pulse animation for last 10 seconds
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _timerPulse = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Focus and text listeners for smooth borders, lift, and dynamic button opacity
    for (int i = 0; i < _otpLength; i++) {
      final index = i;
      _otpFocusNodes[index].addListener(() {
        setState(() {
          _isFocusedList[index] = _otpFocusNodes[index].hasFocus;
        });
      });
      _otpControllers[index].addListener(() {
        if (mounted) setState(() {});
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

    // Smooth transition to Citizen Dashboard
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const CitizenDashboardScreen()),
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
          final double scaleMin = math.min(scaleW, scaleH);
          final double textScale = (w / 390.0).clamp(0.70, 1.35);

          // Sleek, well-proportioned dimensions (not crowded / not "bhra bhra")
          final double logoSize = (46.0 * scaleH).clamp(34.0, 58.0);
          final double titleFontSize = (19.0 * textScale).clamp(15.0, 24.0);
          final double qFontSize = (21.5 * textScale).clamp(17.0, 27.0);
          final double taglineFontSize = (8.5 * textScale).clamp(7.0, 10.5);

          // Card width standardized to citizen login screen with slight increase
          final double maxCardWidth = 940.0;
          final double availableWidth = w - (24.0 * scaleW).clamp(16.0, 48.0);
          final double cardWidth =
              math.min(availableWidth, maxCardWidth).clamp(280.0, maxCardWidth);
          final bool isWide = cardWidth >= 580;

          final double cardPaddingH = isWide
              ? (26.0 * scaleW).clamp(20.0, 34.0)
              : (16.0 * scaleW).clamp(12.0, 20.0);
          final double cardPaddingV = isWide
              ? (28.0 * scaleH).clamp(22.0, 36.0)
              : (18.0 * scaleH).clamp(14.0, 24.0);
          final double cardTitleSize = (20.0 * textScale).clamp(17.0, 23.0);
          final double cardSubtitleSize = (12.5 * textScale).clamp(11.0, 14.0);
          final double cardPhoneSize = (13.5 * textScale).clamp(12.0, 15.0);

          // 6 OTP boxes responsive width & height (sleek 3D rounded boxes)
          final double leftAvailableWidth = isWide
              ? ((cardWidth - (2 * cardPaddingH) - 36.0) * (11.0 / 19.0))
              : (cardWidth - (2 * cardPaddingH));
          final double boxWidth =
              ((leftAvailableWidth - (5 * 10.0)) / 6).clamp(38.0, 52.0);
          final double boxHeight = (boxWidth * 1.20).clamp(46.0, 62.0);
          final double digitSize = (16.5 * textScale).clamp(13.5, 20.0);

          final double timerSize = (11.5 * textScale).clamp(9.5, 13.5);
          final double btnHeight = (42.0 * scaleH).clamp(38.0, 46.0);
          final double btnFontSize = (13.5 * textScale).clamp(12.0, 15.5);
          final double btnIconSize = (15.0 * textScale).clamp(13.0, 17.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              // ── 1. EXACT USER PROVIDED BACKGROUND IMAGE ──
              Positioned.fill(
                child: Image.asset(
                  'assets/images/screen_bg_2.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),

              // ── 2. SINGLE-SCREEN NON-SCROLLABLE CONTENT ──
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
                        cardWidth: cardWidth,
                        scaleW: scaleW,
                        scaleH: scaleH,
                        scaleMin: scaleMin,
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
  // --------------------------------------------------------------------------
  // MAIN OTP CARD (FITS 1 SCREEN, 2-COLUMN ON DESKTOP/WIDE VIEWPORT)
  // --------------------------------------------------------------------------
  Widget _buildOtpCard({
    required double cardWidth,
    required double scaleW,
    required double scaleH,
    required double scaleMin,
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
    final bool isWide = cardWidth >= 580;

    return Center(
      child: SizedBox(
        width: cardWidth,
        child: Container(
          width: cardWidth,
          padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: paddingV),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular((24.0 * scaleW).clamp(18.0, 28.0)),
            border: Border.all(color: const Color(0xFFE2EDF5), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C013973),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left Column: Verify Form, OTP Boxes & Actions
                    Expanded(
                      flex: 11,
                      child: _buildLeftOtpForm(
                        scaleW: scaleW,
                        scaleH: scaleH,
                        scaleMin: scaleMin,
                        textScale: textScale,
                        titleSize: titleSize,
                        subtitleSize: subtitleSize,
                        phoneSize: phoneSize,
                        boxWidth: boxWidth,
                        boxHeight: boxHeight,
                        digitSize: digitSize,
                        timerSize: timerSize,
                        btnHeight: btnHeight,
                        btnFontSize: btnFontSize,
                        btnIconSize: btnIconSize,
                      ),
                    ),

                    // Vertical Divider Line
                    Container(
                      height: 340,
                      width: 1.2,
                      margin: EdgeInsets.symmetric(
                        horizontal: (22.0 * scaleW).clamp(14.0, 28.0),
                      ),
                      color: const Color(0xFFEDF2F7),
                    ),

                    // Right Column: Graphic Illustration & Security Reassurance
                    Expanded(
                      flex: 8,
                      child: _buildRightSecuritySection(
                        scaleMin,
                        textScale,
                        scaleH,
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLeftOtpForm(
                      scaleW: scaleW,
                      scaleH: scaleH,
                      scaleMin: scaleMin,
                      textScale: textScale,
                      titleSize: titleSize,
                      subtitleSize: subtitleSize,
                      phoneSize: phoneSize,
                      boxWidth: boxWidth,
                      boxHeight: boxHeight,
                      digitSize: digitSize,
                      timerSize: timerSize,
                      btnHeight: btnHeight,
                      btnFontSize: btnFontSize,
                      btnIconSize: btnIconSize,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // LEFT COLUMN: FORM, OTP BOXES, TIMER, BUTTON & RESEND FOOTER
  // --------------------------------------------------------------------------
  Widget _buildLeftOtpForm({
    required double scaleW,
    required double scaleH,
    required double scaleMin,
    required double textScale,
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── TOP ROW: CIRCULAR SHIELD BADGE + TITLE & PHONE ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: (48.0 * scaleMin).clamp(40.0, 52.0),
              height: (48.0 * scaleMin).clamp(40.0, 52.0),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F3FD),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.shield_outlined,
                  color: const Color(0xFF0077C8),
                  size: (24.0 * scaleMin).clamp(20.0, 26.0),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Verify OTP',
                    style: TextStyle(
                      color: const Color(0xFF0F172A),
                      fontSize: titleSize,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "We've sent a 6-digit code to",
                    style: TextStyle(
                      color: const Color(0xFF64748B),
                      fontSize: subtitleSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: _showEditPhoneDialog,
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _phoneNumber,
                          style: TextStyle(
                            color: const Color(0xFF0F172A),
                            fontSize: phoneSize,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.edit_rounded,
                          size: (15.0 * scaleW).clamp(13.0, 17.0),
                          color: const Color(0xFF0077C8),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        SizedBox(height: (18.0 * scaleH).clamp(14.0, 24.0)),

        // ── 6 OTP BOXES (ANIMATED, 3D CLAYMORPHIC KEYCAPS) ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_otpLength, (index) {
            return _buildSingleOtpBox(index, boxWidth, boxHeight, digitSize);
          }),
        ),

        SizedBox(height: (14.0 * scaleH).clamp(10.0, 18.0)),

        // ── RESEND OTP TIMER ROW ──
        _buildResendSection(timerSize),

        SizedBox(height: (16.0 * scaleH).clamp(12.0, 22.0)),

        // ── VERIFY & CONTINUE BUTTON ──
        IgnorePointer(
          ignoring: _verifyState == VerifyButtonState.idle && _currentOtp.length < _otpLength,
          child: AnimatedOpacity(
            opacity: _verifyState != VerifyButtonState.idle
                ? 1.0
                : _currentOtp.length / _otpLength,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: _buildVerifyButton(btnHeight, btnFontSize, btnIconSize),
          ),
        ),

        SizedBox(height: (16.0 * scaleH).clamp(12.0, 20.0)),

        // ── DIVIDER: "Didn't receive the code?" ──
        Row(
          children: [
            const Expanded(child: Divider(color: Color(0xFFE2EDF5), thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                "Didn't receive the code?",
                style: TextStyle(
                  color: const Color(0xFF64748B),
                  fontSize: (11.0 * textScale).clamp(9.5, 12.0),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Expanded(child: Divider(color: Color(0xFFE2EDF5), thickness: 1)),
          ],
        ),

        SizedBox(height: (8.0 * scaleH).clamp(6.0, 12.0)),

        // ── REFRESH ICON + RESEND OTP ──
        GestureDetector(
          onTap: _handleResend,
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.refresh_rounded,
                size: (16.0 * textScale).clamp(14.0, 18.0),
                color: _secondsRemaining == 0
                    ? const Color(0xFF0077C8)
                    : const Color(0xFF0077C8).withValues(alpha: 0.65),
              ),
              const SizedBox(width: 6),
              Text(
                'Resend OTP',
                style: TextStyle(
                  color: _secondsRemaining == 0
                      ? const Color(0xFF0077C8)
                      : const Color(0xFF0077C8).withValues(alpha: 0.65),
                  fontSize: (12.5 * textScale).clamp(11.0, 14.0),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // RIGHT COLUMN: SECURITY ILLUSTRATION & MESSAGE
  // --------------------------------------------------------------------------
  Widget _buildRightSecuritySection(
    double scaleMin,
    double textScale,
    double scaleH,
  ) {
    final bool isUnlocked =
        _currentOtp.length == _otpLength || _verifyState == VerifyButtonState.success;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildRealisticPhoneMockup(scaleMin, scaleH),
        SizedBox(height: (16.0 * scaleH).clamp(10.0, 20.0)),
        Text(
          isUnlocked ? 'Identity Confirmed' : 'Your Security Matters',
          style: TextStyle(
            color: isUnlocked ? const Color(0xFF047857) : const Color(0xFF0F172A),
            fontSize: (16.5 * textScale).clamp(14.5, 18.5),
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        SizedBox(height: (6.0 * scaleH).clamp(4.0, 10.0)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            isUnlocked
                ? 'OTP verified! Tap "Verify & Continue" to proceed safely.'
                : 'Please enter the OTP to verify your identity and continue safely.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF64748B),
              fontSize: (12.0 * textScale).clamp(10.5, 13.5),
              fontWeight: FontWeight.w500,
              height: 1.38,
            ),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // REALISTIC SMARTPHONE MOCKUP (INTERACTIVE LOCK / UNLOCK ANIMATION)
  // --------------------------------------------------------------------------
  Widget _buildRealisticPhoneMockup(double scaleMin, double scaleH) {
    final bool isUnlocked =
        _currentOtp.length == _otpLength || _verifyState == VerifyButtonState.success;
    final double phoneW = (144.0 * scaleMin).clamp(130.0, 156.0);
    final double phoneH = (260.0 * scaleH).clamp(236.0, 276.0);

    return SizedBox(
      width: phoneW + 36,
      height: phoneH + 16,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 1. Radiant Background Halo / Aura
          AnimatedContainer(
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeInOut,
            width: phoneW + (isUnlocked ? 28 : 14),
            height: phoneH + (isUnlocked ? 28 : 14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUnlocked
                  ? const Color(0xFF10B981).withValues(alpha: 0.18)
                  : const Color(0xFF0077C8).withValues(alpha: 0.10),
            ),
          ),

          // 2. Hardware Buttons (Volume Keys Left, Power Key Right)
          // Volume Up (Left)
          Positioned(
            left: 11,
            top: (phoneH * 0.26),
            child: Container(
              width: 3,
              height: 18,
              decoration: const BoxDecoration(
                color: Color(0xFF94A3B8),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(2),
                  bottomLeft: Radius.circular(2),
                ),
              ),
            ),
          ),
          // Volume Down (Left)
          Positioned(
            left: 11,
            top: (phoneH * 0.26) + 24,
            child: Container(
              width: 3,
              height: 18,
              decoration: const BoxDecoration(
                color: Color(0xFF94A3B8),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(2),
                  bottomLeft: Radius.circular(2),
                ),
              ),
            ),
          ),
          // Power Button (Right)
          Positioned(
            right: 11,
            top: (phoneH * 0.30),
            child: Container(
              width: 3,
              height: 28,
              decoration: const BoxDecoration(
                color: Color(0xFF94A3B8),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(2),
                  bottomRight: Radius.circular(2),
                ),
              ),
            ),
          ),

          // 3. Realistic Smartphone Chassis
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: phoneW,
            height: phoneH,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isUnlocked
                    ? const Color(0xFF10B981).withValues(alpha: 0.85)
                    : const Color(0xFF334155),
                width: 3.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isUnlocked
                      ? const Color(0xFF10B981).withValues(alpha: 0.35)
                      : const Color(0xFF0F172A).withValues(alpha: 0.24),
                  blurRadius: isUnlocked ? 28 : 20,
                  offset: const Offset(0, 10),
                  spreadRadius: isUnlocked ? 2 : 0,
                ),
                BoxShadow(
                  color: const Color(0xFF0077C8).withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // OLED Glass Screen Gradient
                  Positioned.fill(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 450),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isUnlocked
                              ? const [
                                  Color(0xFF062D24),
                                  Color(0xFF0A1E29),
                                  Color(0xFF041818),
                                ]
                              : const [
                                  Color(0xFF0F172A),
                                  Color(0xFF0B192C),
                                  Color(0xFF030D1A),
                                ],
                        ),
                      ),
                    ),
                  ),

                  // Diagonal Reflection Gloss
                  Positioned(
                    top: -20,
                    right: -20,
                    width: phoneW * 0.9,
                    height: phoneH * 0.65,
                    child: Transform.rotate(
                      angle: -0.5,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.08),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Phone Screen Content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Top Status Bar: Clock + Notch + Battery/WiFi
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '9:41',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 8.0,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                            // Dynamic Island / Camera Notch
                            Container(
                              width: 36,
                              height: 9,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: const Color(0xFF1E293B),
                                  width: 0.6,
                                ),
                              ),
                              child: Center(
                                child: Container(
                                  width: 3.5,
                                  height: 3.5,
                                  margin: const EdgeInsets.only(left: 18),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF334155),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                            const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.wifi, size: 9, color: Colors.white70),
                                SizedBox(width: 3),
                                Icon(Icons.battery_full_rounded, size: 10, color: Colors.white70),
                              ],
                            ),
                          ],
                        ),

                        const Spacer(),

                        // ── CENTER LOCK / UNLOCK INTERACTIVE DISPLAY ──
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          switchInCurve: Curves.easeOutBack,
                          switchOutCurve: Curves.easeInBack,
                          transitionBuilder: (child, animation) {
                            return ScaleTransition(
                              scale: animation,
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                          child: isUnlocked
                              ? _buildPhoneUnlockedContent()
                              : _buildPhoneLockedContent(),
                        ),

                        const Spacer(),

                        // Bottom Home Indicator Bar
                        Container(
                          width: 44,
                          height: 3.5,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Floating Badge (Shield when locked, Verified when unlocked)
          Positioned(
            top: 24,
            right: 6,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: isUnlocked ? 1.0 : 0.7,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: isUnlocked ? const Color(0xFF10B981) : const Color(0xFF0077C8),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isUnlocked ? const Color(0xFF10B981) : const Color(0xFF0077C8))
                          .withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  isUnlocked ? Icons.verified_user_rounded : Icons.shield_rounded,
                  color: Colors.white,
                  size: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // PHONE LOCKED CONTENT (BIG LOCK ICON + REAL-TIME PASSCODE DOTS)
  // --------------------------------------------------------------------------
  Widget _buildPhoneLockedContent() {
    final int digitsTyped = _currentOtp.length;

    return Column(
      key: const ValueKey('phone_locked_state'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Big Lock Icon Badge
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1D4ED8).withValues(alpha: 0.50),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: const Color(0xFF60A5FA).withValues(alpha: 0.6),
              width: 1.5,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.lock_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),

        const SizedBox(height: 10),

        // "LOCKED" status text
        const Text(
          'DEVICE LOCKED',
          style: TextStyle(
            color: Colors.white,
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),

        const SizedBox(height: 6),

        // Live OTP Code Dots on Phone Screen (fills as user types!)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_otpLength, (i) {
            final bool filled = i < digitsTyped;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 2.2),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? const Color(0xFF38BDF8) : Colors.white.withValues(alpha: 0.18),
                boxShadow: filled
                    ? [
                        BoxShadow(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.8),
                          blurRadius: 4,
                        ),
                      ]
                    : null,
                border: filled
                    ? null
                    : Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                        width: 0.8,
                      ),
              ),
            );
          }),
        ),

        const SizedBox(height: 6),

        Text(
          digitsTyped == 0
              ? 'Enter 6-digit OTP'
              : '$digitsTyped/$_otpLength digits entered',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.60),
            fontSize: 8.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // PHONE UNLOCKED CONTENT (BIG TICK / UNLOCKED BADGE + VERIFIED CONFIRMATION)
  // --------------------------------------------------------------------------
  Widget _buildPhoneUnlockedContent() {
    return Column(
      key: const ValueKey('phone_unlocked_state'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Big Unlocked / Green Tick Badge
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF10B981), Color(0xFF059669)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.70),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: const Color(0xFF6EE7B7),
              width: 2.0,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Unlocked pill chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF34D399),
              width: 1.0,
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_open_rounded,
                color: Color(0xFF6EE7B7),
                size: 10,
              ),
              SizedBox(width: 4),
              Text(
                'UNLOCKED',
                style: TextStyle(
                  color: Color(0xFF6EE7B7),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          'Identity Verified ✓',
          style: TextStyle(
            color: Colors.white,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // SINGLE OTP BOX (3D DEPTH / CLAYMORPHIC KEYCAP WITH INSET WELL)
  // --------------------------------------------------------------------------
  Widget _buildSingleOtpBox(int index, double width, double height, double digitSize) {
    final isFocused = _isFocusedList[index];
    final hasValue = _otpControllers[index].text.isNotEmpty;
    final double outerRadius = (width * 0.30).clamp(10.0, 13.0);
    final double innerRadius = (outerRadius - 2.8).clamp(7.5, 10.5);

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
        transform: Matrix4.translationValues(0, isFocused ? -2.5 : 0.0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(outerRadius),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isFocused
                ? [
                    const Color(0xFFF0F6FE),
                    const Color(0xFFD6E7FC),
                  ]
                : [
                    Colors.white,
                    const Color(0xFFE0EBF5),
                  ],
          ),
          border: Border.all(
            color: isFocused
                ? const Color(0xFF007AEB)
                : (hasValue ? const Color(0xFFC4D5E7) : Colors.white),
            width: isFocused ? 1.6 : 1.4,
          ),
          boxShadow: [
            // Soft elevated ambient drop shadow
            BoxShadow(
              color: isFocused
                  ? const Color(0xFF007AEB).withValues(alpha: 0.28)
                  : const Color(0xFF0B3A66).withValues(alpha: 0.14),
              blurRadius: isFocused ? 11 : 8,
              spreadRadius: isFocused ? 0.5 : 0,
              offset: const Offset(0, 4),
            ),
            // Contact shadow at the bottom edge
            BoxShadow(
              color: const Color(0xFF002B54).withValues(alpha: 0.07),
              blurRadius: 2.5,
              offset: const Offset(0, 1.5),
            ),
            // Top rim specular highlight
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.95),
              blurRadius: 3,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        padding: const EdgeInsets.all(3.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(innerRadius),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isFocused
                  ? [
                      const Color(0xFFF3F8FE),
                      Colors.white,
                    ]
                  : (hasValue
                      ? [
                          const Color(0xFFE8F0F7),
                          const Color(0xFFF7FAFD),
                          Colors.white,
                        ]
                      : [
                          const Color(0xFFE9F0F7),
                          const Color(0xFFF4F8FC),
                          const Color(0xFFFAFCFE),
                        ]),
              stops: isFocused
                  ? const [0.0, 1.0]
                  : const [0.0, 0.42, 1.0],
            ),
            border: Border.all(
              color: isFocused
                  ? const Color(0xFFB4D5F8)
                  : const Color(0xFFD6E2EE),
              width: 0.9,
            ),
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
                      fontSize: (digitSize * 1.05).clamp(14.0, 21.0),
                      fontWeight: FontWeight.w800,
                      height: 1.1,
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
            borderRadius: BorderRadius.circular(14.0),
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
          children: [
            SizedBox(width: btnIconSize + 14),
            Expanded(
              child: Center(
                child: Text(
                  'Verify & Continue',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: btnFontSize,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: btnIconSize),
            const SizedBox(width: 14),
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


