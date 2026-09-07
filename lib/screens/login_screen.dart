import 'dart:math' as math;
import 'package:flutter/material.dart';
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
      title: 'ResQShield - Flood & Disaster Protection',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
        scaffoldBackgroundColor: const Color(0xFFF0F6FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007AEB),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

// ============================================================================
// LOGIN SCREEN
// ============================================================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // --------------------------------------------------------------------------
  // CONTROLLERS & FORM STATE
  // --------------------------------------------------------------------------
  final TextEditingController _identityController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _identityFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _isIdentityFocused = false;
  bool _isPasswordFocused = false;
  bool _isIdentityValid = false;
  bool _obscurePassword = true;
  bool _rememberMe = true;

  // --------------------------------------------------------------------------
  // BUTTON & FLOW STATES
  // --------------------------------------------------------------------------
  bool _buttonPressed = false;
  bool _isLoading = false;
  bool _isSuccess = false;

  // --------------------------------------------------------------------------
  // FEATURE CARDS TAP STATES
  // --------------------------------------------------------------------------
  int? _tappedFeatureIndex;

  // --------------------------------------------------------------------------
  // AMBIENT ANIMATION CONTROLLERS
  // --------------------------------------------------------------------------
  late final AnimationController _waveController;
  late final AnimationController _dropletController;
  late final AnimationController _successController;
  late final Animation<double> _successScale;

  @override
  void initState() {
    super.initState();

    // 12s ambient wave cycle
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // 4s floating droplet cycle
    _dropletController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // Success checkmark animation
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _successScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.easeOutBack),
    );

    // Input listeners for focus & live validation
    _identityFocusNode.addListener(() {
      setState(() {
        _isIdentityFocused = _identityFocusNode.hasFocus;
      });
    });

    _passwordFocusNode.addListener(() {
      setState(() {
        _isPasswordFocused = _passwordFocusNode.hasFocus;
      });
    });

    _identityController.addListener(_validateIdentityInput);
  }

  void _validateIdentityInput() {
    final text = _identityController.text.trim();
    // Valid if standard email pattern or 10-digit mobile number
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    final phoneRegex = RegExp(r'^[0-9]{10}$');
    final isValid = emailRegex.hasMatch(text) || phoneRegex.hasMatch(text);

    if (isValid != _isIdentityValid) {
      setState(() {
        _isIdentityValid = isValid;
      });
    }
  }

  @override
  void dispose() {
    _identityController.dispose();
    _passwordController.dispose();
    _identityFocusNode.dispose();
    _passwordFocusNode.dispose();
    _waveController.dispose();
    _dropletController.dispose();
    _successController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // LOGIN SUBMIT LOGIC
  // --------------------------------------------------------------------------
  Future<void> _handleLogin() async {
    if (_isLoading || _isSuccess) return;

    if (_identityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter your email or mobile number'),
          backgroundColor: const Color(0xFF013973),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      _identityFocusNode.requestFocus();
      return;
    }

    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter your password'),
          backgroundColor: const Color(0xFF013973),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      _passwordFocusNode.requestFocus();
      return;
    }

    // STATE 2: LOADING
    setState(() {
      _isLoading = true;
    });

    // Simulate authentication
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;

    // STATE 3: SUCCESS
    setState(() {
      _isLoading = false;
      _isSuccess = true;
    });
    _successController.forward();

    // After success animation, navigate to OTP screen
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WaterWavesScreen()),
    );
  }

  // --------------------------------------------------------------------------
  // UI BUILD - SINGLE SCREEN, RESPONSIVE LAYOUTBUILDER (NO SCROLLING)
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFE9F4FB),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double w = constraints.maxWidth;
          final double h = constraints.maxHeight;

          // Responsive scaling directly driven by LayoutBuilder constraints:
          // Reference viewport: 390w x 844h (standard mobile display)
          final double scaleW = (w / 390.0).clamp(0.65, 1.45);
          final double scaleH = (h / 844.0).clamp(0.55, 1.35);
          final double scaleMin = math.min(scaleW, scaleH);
          final double textScale = (math.min(w / 390.0, h / 800.0)).clamp(0.65, 1.25);

          final double padH = (18.0 * scaleW).clamp(12.0, 24.0);
          final double padV = (8.0 * scaleH).clamp(4.0, 12.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              // ==================================================================
              // 1. SCENIC BACKGROUND IMAGE (USER PROVIDED 1ST IMAGE)
              // ==================================================================
              Positioned.fill(
                child: Image.asset(
                  'assets/images/login_bg.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),

              // ==================================================================
              // 2. AMBIENT CALM WATER WAVES (BOTTOM)
              // ==================================================================
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: (h * 0.16).clamp(70.0, 140.0),
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _LoginCalmWavePainter(_waveController.value),
                        size: Size.infinite,
                      );
                    },
                  ),
                ),
              ),

              // ==================================================================
              // 3. FLOATING WATER DROPLETS (SUBTLE AMBIENT)
              // ==================================================================
              Positioned(
                left: 0,
                right: 0,
                bottom: (20.0 * scaleH).clamp(10.0, 30.0),
                height: (h * 0.20).clamp(80.0, 170.0),
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _dropletController,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _WaterDropletsPainter(_dropletController.value),
                        size: Size.infinite,
                      );
                    },
                  ),
                ),
              ),

              // ==================================================================
              // 4. MAIN SINGLE SCREEN CONTENT (NO SCROLLING, ZERO OVERFLOW)
              // ==================================================================
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── TOP BAR: LOGO & LANGUAGE SELECTOR ──
                      _buildTopBar(scaleW, scaleH, scaleMin, textScale),

                      const Spacer(flex: 2),

                      // ── HERO AREA: TITLE & SUBTITLE ──
                      _buildHeroArea(scaleW, scaleH, scaleMin, textScale),

                      const Spacer(flex: 2),

                      // ── FEATURE ICON ROW (4 CARDS) ──
                      _buildFeatureCardsRow(scaleW, scaleH, scaleMin, textScale, w, padH),

                      const Spacer(flex: 2),

                      // ── LOGIN CARD / SUCCESS CARD ──
                      _buildLoginCard(scaleW, scaleH, scaleMin, textScale),

                      const Spacer(flex: 1),
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
  // TOP BAR: LOGO + BRAND NAME + LANGUAGE PILL
  // --------------------------------------------------------------------------
  Widget _buildTopBar(double scaleW, double scaleH, double scaleMin, double textScale) {
    final double logoSize = (38.0 * scaleMin).clamp(28.0, 48.0);
    final double resSize = (18.0 * textScale).clamp(14.0, 22.0);
    final double qSize = (20.0 * textScale).clamp(15.0, 24.0);
    final double taglineSize = (8.5 * textScale).clamp(6.8, 10.5);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Brand: Logo + Name + Tagline
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/app_logo.png',
              width: logoSize,
              height: logoSize,
              fit: BoxFit.contain,
            ),
            SizedBox(width: (7.0 * scaleW).clamp(4.0, 10.0)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Res',
                        style: TextStyle(
                          color: const Color(0xFF013973),
                          fontSize: resSize,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                      ),
                      TextSpan(
                        text: 'Q',
                        style: TextStyle(
                          color: const Color(0xFF00FF00),
                          fontSize: qSize,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                          shadows: const [
                            Shadow(
                              color: Color(0x5500FF00),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      TextSpan(
                        text: 'Shield',
                        style: TextStyle(
                          color: const Color(0xFF013973),
                          fontSize: resSize,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Safer Routes. Stronger Communities.',
                  style: TextStyle(
                    color: const Color(0xFF013973).withValues(alpha: 0.75),
                    fontSize: taglineSize,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ],
        ),

        // Language Selector Pill (🇮🇳 EN v)
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Language set to English (IN)'),
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: (9.0 * scaleW).clamp(6.0, 12.0),
              vertical: (5.0 * scaleH).clamp(3.0, 7.0),
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD6E6F2), width: 1.0),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A013973),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🇮🇳', style: TextStyle(fontSize: (11.5 * textScale).clamp(9.5, 13.0))),
                const SizedBox(width: 4),
                Text(
                  'EN',
                  style: TextStyle(
                    color: const Color(0xFF0F172A),
                    fontSize: (11.0 * textScale).clamp(9.0, 13.0),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: const Color(0xFF475569),
                  size: (15.0 * scaleMin).clamp(12.0, 17.0),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // HERO AREA
  // --------------------------------------------------------------------------
  Widget _buildHeroArea(double scaleW, double scaleH, double scaleMin, double textScale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Together for a',
          style: TextStyle(
            color: const Color(0xFF013973),
            fontSize: (18.0 * textScale).clamp(14.0, 23.0),
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        Text(
          'Safer Tomorrow',
          style: TextStyle(
            color: const Color(0xFF005BC5),
            fontSize: (23.0 * textScale).clamp(17.0, 29.0),
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
            height: 1.15,
          ),
        ),
        SizedBox(height: (4.0 * scaleH).clamp(2.0, 7.0)),
        Text(
          'Real-time flood monitoring, alerts and emergency support for stronger, safer communities.',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: const Color(0xFF335C80),
            fontSize: (11.0 * textScale).clamp(9.0, 13.0),
            fontWeight: FontWeight.w500,
            height: 1.30,
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // FEATURE ICON ROW (4 CARDS WITH SUBTLE MICRO-INTERACTION)
  // --------------------------------------------------------------------------
  Widget _buildFeatureCardsRow(
    double scaleW,
    double scaleH,
    double scaleMin,
    double textScale,
    double screenW,
    double padH,
  ) {
    final features = [
      {'title': 'Live Alerts', 'icon': Icons.notifications_none_rounded},
      {'title': 'Safe Shelters', 'icon': Icons.home_rounded},
      {'title': 'Rescue Help', 'icon': Icons.shield_rounded},
      {'title': 'Community', 'icon': Icons.groups_rounded},
    ];

    final double availableWidth = screenW - (padH * 2) - 18.0; // 3 gaps of 6.0
    final double cardWidth = (availableWidth / 4).clamp(52.0, 95.0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(features.length, (index) {
        final item = features[index];
        final isTapped = _tappedFeatureIndex == index;

        return GestureDetector(
          onTapDown: (_) => setState(() => _tappedFeatureIndex = index),
          onTapUp: (_) => setState(() => _tappedFeatureIndex = null),
          onTapCancel: () => setState(() => _tappedFeatureIndex = null),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            transform: Matrix4.translationValues(0, isTapped ? -2.0 : 0.0, 0),
            width: cardWidth,
            padding: EdgeInsets.symmetric(
              vertical: (6.0 * scaleH).clamp(4.0, 10.0),
              horizontal: 3.0,
            ),
            decoration: BoxDecoration(
              color: isTapped
                  ? const Color(0xFFEBF5FC)
                  : Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular((13.0 * scaleMin).clamp(10.0, 16.0)),
              border: Border.all(
                color: isTapped
                    ? const Color(0xFF007AEB).withValues(alpha: 0.4)
                    : const Color(0xFFDCEAF5),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isTapped
                      ? const Color(0x18007AEB)
                      : const Color(0x0A013973),
                  blurRadius: isTapped ? 8 : 5,
                  offset: Offset(0, isTapped ? 3 : 1.5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item['icon'] as IconData,
                  color: const Color(0xFF007AEB),
                  size: (19.0 * scaleMin).clamp(15.0, 24.0),
                ),
                SizedBox(height: (4.0 * scaleH).clamp(2.0, 6.0)),
                Text(
                  item['title'] as String,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF334155),
                    fontSize: (9.2 * textScale).clamp(7.5, 11.0),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // --------------------------------------------------------------------------
  // LOGIN CARD / SUCCESS TRANSITION
  // --------------------------------------------------------------------------
  Widget _buildLoginCard(double scaleW, double scaleH, double scaleMin, double textScale) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: (16.0 * scaleW).clamp(12.0, 22.0),
        vertical: (12.0 * scaleH).clamp(8.0, 18.0),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular((20.0 * scaleMin).clamp(16.0, 24.0)),
        border: Border.all(color: const Color(0xFFE0EEF8), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14013973),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        child: _isSuccess
            ? _buildSuccessCardContent(scaleW, scaleH, scaleMin, textScale)
            : _buildLoginFormContent(scaleW, scaleH, scaleMin, textScale),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // LOGIN FORM CONTENT
  // --------------------------------------------------------------------------
  Widget _buildLoginFormContent(double scaleW, double scaleH, double scaleMin, double textScale) {
    return Column(
      key: const ValueKey('login_form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title
        Text(
          'Welcome Back',
          style: TextStyle(
            color: const Color(0xFF0F172A),
            fontSize: (17.0 * textScale).clamp(14.0, 21.0),
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        SizedBox(height: (2.0 * scaleH).clamp(1.0, 4.0)),
        Text(
          'Login to continue to ResQShield',
          style: TextStyle(
            color: const Color(0xFF64748B),
            fontSize: (11.0 * textScale).clamp(9.0, 13.0),
            fontWeight: FontWeight.w500,
          ),
        ),

        SizedBox(height: (10.0 * scaleH).clamp(5.0, 14.0)),

        // ── EMAIL OR MOBILE FIELD ──
        _buildIdentityTextField(scaleW, scaleH, scaleMin, textScale),

        SizedBox(height: (7.0 * scaleH).clamp(4.0, 10.0)),

        // ── PASSWORD FIELD ──
        _buildPasswordTextField(scaleW, scaleH, scaleMin, textScale),

        SizedBox(height: (7.0 * scaleH).clamp(4.0, 10.0)),

        // ── REMEMBER ME & FORGOT PASSWORD ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Remember Me
            GestureDetector(
              onTap: () => setState(() => _rememberMe = !_rememberMe),
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: (15.0 * scaleMin).clamp(12.0, 17.0),
                    height: (15.0 * scaleMin).clamp(12.0, 17.0),
                    decoration: BoxDecoration(
                      color: _rememberMe
                          ? const Color(0xFF007AEB)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _rememberMe
                            ? const Color(0xFF007AEB)
                            : const Color(0xFFCBD5E1),
                        width: 1.4,
                      ),
                    ),
                    child: _rememberMe
                        ? Icon(Icons.check, size: (11.0 * scaleMin).clamp(9.0, 13.0), color: Colors.white)
                        : null,
                  ),
                  SizedBox(width: (6.0 * scaleW).clamp(4.0, 8.0)),
                  Text(
                    'Remember me',
                    style: TextStyle(
                      color: const Color(0xFF475569),
                      fontSize: (10.5 * textScale).clamp(8.5, 12.0),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Forgot Password Link
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Password reset instructions sent'),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  color: const Color(0xFF007AEB),
                  fontSize: (10.5 * textScale).clamp(8.5, 12.0),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: (10.0 * scaleH).clamp(6.0, 14.0)),

        // ── LOGIN BUTTON (3 CLEAN STATES) ──
        _buildLoginButton(scaleW, scaleH, scaleMin, textScale),

        SizedBox(height: (7.0 * scaleH).clamp(4.0, 10.0)),

        // ── OR DIVIDER ──
        Row(
          children: [
            const Expanded(
              child: Divider(color: Color(0xFFE2E8F0), thickness: 1.0),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'OR',
                style: TextStyle(
                  color: const Color(0xFF94A3B8),
                  fontSize: (9.5 * textScale).clamp(8.0, 11.5),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Expanded(
              child: Divider(color: Color(0xFFE2E8F0), thickness: 1.0),
            ),
          ],
        ),

        SizedBox(height: (7.0 * scaleH).clamp(4.0, 10.0)),

        // ── SOCIAL LOGIN BUTTONS ROW ──
        Row(
          children: [
            // Continue with Google
            Expanded(
              child: _buildSocialButton(
                scaleW: scaleW,
                scaleH: scaleH,
                scaleMin: scaleMin,
                textScale: textScale,
                label: 'Google',
                iconWidget: _buildGoogleIcon(scaleMin),
                onTap: () => _handleLogin(),
              ),
            ),
            const SizedBox(width: 8),
            // Continue with Apple
            Expanded(
              child: _buildSocialButton(
                scaleW: scaleW,
                scaleH: scaleH,
                scaleMin: scaleMin,
                textScale: textScale,
                label: 'Apple',
                iconWidget: Icon(
                  Icons.apple,
                  size: (16.0 * scaleMin).clamp(13.0, 19.0),
                  color: Colors.black,
                ),
                onTap: () => _handleLogin(),
              ),
            ),
          ],
        ),

        SizedBox(height: (7.0 * scaleH).clamp(4.0, 10.0)),

        // ── SECURITY FOOTER (GOVERNMENT GRADE) ──
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: (12.0 * scaleMin).clamp(10.0, 14.0),
                color: const Color(0xFF007AEB),
              ),
              const SizedBox(width: 4),
              Text(
                'Secure Government Portal',
                style: TextStyle(
                  color: const Color(0xFF475569),
                  fontSize: (9.5 * textScale).clamp(8.0, 11.5),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // EMAIL / MOBILE INPUT FIELD
  // --------------------------------------------------------------------------
  Widget _buildIdentityTextField(double scaleW, double scaleH, double scaleMin, double textScale) {
    Color borderColor = const Color(0xFFE2E8F0);
    if (_isIdentityValid) {
      borderColor = const Color(0xFF22C55E); // Subtle green
    } else if (_isIdentityFocused) {
      borderColor = const Color(0xFF007AEB); // Primary blue
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      transform: Matrix4.translationValues(0, _isIdentityFocused ? -1.0 : 0.0, 0),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular((11.0 * scaleMin).clamp(9.0, 14.0)),
        border: Border.all(color: borderColor, width: _isIdentityFocused ? 1.5 : 1.0),
        boxShadow: _isIdentityFocused
            ? [
                BoxShadow(
                  color: (_isIdentityValid
                          ? const Color(0xFF22C55E)
                          : const Color(0xFF007AEB))
                      .withValues(alpha: 0.14),
                  blurRadius: 6,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ]
            : const [
                BoxShadow(
                  color: Color(0x04000000),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
      ),
      child: TextField(
        controller: _identityController,
        focusNode: _identityFocusNode,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        style: TextStyle(
          color: const Color(0xFF0F172A),
          fontSize: (12.5 * textScale).clamp(10.5, 14.5),
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Email or Mobile Number',
          hintStyle: TextStyle(
            color: const Color(0xFF94A3B8),
            fontSize: (11.5 * textScale).clamp(9.5, 13.5),
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            Icons.mail_outline_rounded,
            color: _isIdentityFocused
                ? const Color(0xFF007AEB)
                : const Color(0xFF64748B),
            size: (17.0 * scaleMin).clamp(14.0, 20.0),
          ),
          suffixIcon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _isIdentityValid
                ? Icon(
                    Icons.check_rounded,
                    key: const ValueKey('valid_check'),
                    color: const Color(0xFF16A34A),
                    size: (16.0 * scaleMin).clamp(13.0, 19.0),
                  )
                : (_identityController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () => _identityController.clear(),
                        child: Icon(
                          Icons.close_rounded,
                          key: const ValueKey('clear_icon'),
                          color: const Color(0xFF94A3B8),
                          size: (15.0 * scaleMin).clamp(12.0, 17.0),
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('empty'))),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 10,
            vertical: (8.0 * scaleH).clamp(5.0, 12.0),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // PASSWORD INPUT FIELD
  // --------------------------------------------------------------------------
  Widget _buildPasswordTextField(double scaleW, double scaleH, double scaleMin, double textScale) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      transform: Matrix4.translationValues(0, _isPasswordFocused ? -1.0 : 0.0, 0),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular((11.0 * scaleMin).clamp(9.0, 14.0)),
        border: Border.all(
          color: _isPasswordFocused
              ? const Color(0xFF007AEB)
              : const Color(0xFFE2E8F0),
          width: _isPasswordFocused ? 1.5 : 1.0,
        ),
        boxShadow: _isPasswordFocused
            ? [
                BoxShadow(
                  color: const Color(0xFF007AEB).withValues(alpha: 0.14),
                  blurRadius: 6,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ]
            : const [
                BoxShadow(
                  color: Color(0x04000000),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
      ),
      child: TextField(
        controller: _passwordController,
        focusNode: _passwordFocusNode,
        obscureText: _obscurePassword,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _handleLogin(),
        style: TextStyle(
          color: const Color(0xFF0F172A),
          fontSize: (12.5 * textScale).clamp(10.5, 14.5),
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Password',
          hintStyle: TextStyle(
            color: const Color(0xFF94A3B8),
            fontSize: (11.5 * textScale).clamp(9.5, 13.5),
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            Icons.lock_outline_rounded,
            color: _isPasswordFocused
                ? const Color(0xFF007AEB)
                : const Color(0xFF64748B),
            size: (17.0 * scaleMin).clamp(14.0, 20.0),
          ),
          suffixIcon: GestureDetector(
            onTap: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
            behavior: HitTestBehavior.opaque,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                key: ValueKey(_obscurePassword),
                color: const Color(0xFF64748B),
                size: (17.0 * scaleMin).clamp(14.0, 20.0),
              ),
            ),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 10,
            vertical: (8.0 * scaleH).clamp(5.0, 12.0),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // PRIMARY LOGIN BUTTON (IDLE -> LOADING -> SUCCESS)
  // --------------------------------------------------------------------------
  Widget _buildLoginButton(double scaleW, double scaleH, double scaleMin, double textScale) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _buttonPressed = true),
      onTapUp: (_) {
        setState(() => _buttonPressed = false);
        _handleLogin();
      },
      onTapCancel: () => setState(() => _buttonPressed = false),
      child: AnimatedScale(
        scale: _buttonPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 140),
        child: Container(
          height: (36.0 * scaleH).clamp(30.0, 44.0),
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF007AEB), Color(0xFF005BC5)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular((18.0 * scaleMin).clamp(14.0, 22.0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x38007AEB),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _isLoading
                  ? Row(
                      key: const ValueKey('loading'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: (15.0 * scaleMin).clamp(12.0, 16.0),
                          height: (15.0 * scaleMin).clamp(12.0, 16.0),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Logging in...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: (13.0 * textScale).clamp(11.0, 15.0),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      key: const ValueKey('idle'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Login',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: (13.5 * textScale).clamp(11.5, 15.5),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: (15.0 * scaleMin).clamp(12.0, 17.0),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // SOCIAL LOGIN BUTTON (GOOGLE / APPLE)
  // --------------------------------------------------------------------------
  Widget _buildSocialButton({
    required double scaleW,
    required double scaleH,
    required double scaleMin,
    required double textScale,
    required String label,
    required Widget iconWidget,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: (32.0 * scaleH).clamp(26.0, 40.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular((12.0 * scaleMin).clamp(9.0, 15.0)),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget,
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFF1E293B),
                  fontSize: (10.0 * textScale).clamp(8.5, 12.0),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // GOOGLE 'G' ICON
  // --------------------------------------------------------------------------
  Widget _buildGoogleIcon(double scaleMin) {
    final double dim = (15.0 * scaleMin).clamp(12.0, 17.0);
    return CustomPaint(
      size: Size(dim, dim),
      painter: _GoogleIconPainter(),
    );
  }

  // --------------------------------------------------------------------------
  // SUCCESS STATE (CARD CONTENT)
  // --------------------------------------------------------------------------
  Widget _buildSuccessCardContent(double scaleW, double scaleH, double scaleMin, double textScale) {
    final double iconDim = (48.0 * scaleMin).clamp(36.0, 60.0);
    final double checkDim = (28.0 * scaleMin).clamp(20.0, 34.0);

    return ScaleTransition(
      scale: _successScale,
      child: Column(
        key: const ValueKey('login_success'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: (8.0 * scaleH).clamp(4.0, 14.0)),
          Container(
            width: iconDim,
            height: iconDim,
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A).withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF22C55E), width: 1.8),
            ),
            child: Center(
              child: Icon(
                Icons.check_rounded,
                color: const Color(0xFF16A34A),
                size: checkDim,
              ),
            ),
          ),
          SizedBox(height: (10.0 * scaleH).clamp(6.0, 16.0)),
          Text(
            'Login Successful!',
            style: TextStyle(
              color: const Color(0xFF0F172A),
              fontSize: (17.0 * textScale).clamp(14.0, 21.0),
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: (3.0 * scaleH).clamp(1.0, 5.0)),
          Text(
            'Welcome back to ResQShield',
            style: TextStyle(
              color: const Color(0xFF64748B),
              fontSize: (11.5 * textScale).clamp(9.5, 13.5),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: (12.0 * scaleH).clamp(6.0, 18.0)),
        ],
      ),
    );
  }
}

// ============================================================================
// GOOGLE MULTI-COLOR 'G' ICON PAINTER
// ============================================================================

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    final paintBlue = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.butt;

    final paintGreen = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.butt;

    final paintYellow = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.butt;

    final paintRed = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.butt;

    final rect = Rect.fromCircle(center: center, radius: radius - 1.6);

    // Blue arc + bar
    canvas.drawArc(rect, -math.pi / 4, math.pi / 2, false, paintBlue);
    canvas.drawLine(
      Offset(center.dx, center.dy),
      Offset(center.dx + radius - 1.6, center.dy),
      paintBlue,
    );

    // Green arc
    canvas.drawArc(rect, math.pi / 4, math.pi / 2, false, paintGreen);

    // Yellow arc
    canvas.drawArc(rect, 3 * math.pi / 4, math.pi / 2, false, paintYellow);

    // Red arc
    canvas.drawArc(rect, 5 * math.pi / 4, math.pi / 2, false, paintRed);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// CALM WATER WAVES PAINTER (BOTTOM WAVES)
// ============================================================================

class _LoginCalmWavePainter extends CustomPainter {
  final double progress;

  _LoginCalmWavePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final t = progress * math.pi * 2;

    // Layer 1: Deep Soft Wave
    final path1 = Path();
    path1.moveTo(0, h);
    for (double x = 0; x <= w; x += 3) {
      final y = h * 0.48 +
          math.sin(x * 0.012 + t * 0.8) * 8.0 +
          math.sin(x * 0.024 - t * 0.5) * 4.0;
      path1.lineTo(x, y);
    }
    path1.lineTo(w, h);
    path1.close();
    canvas.drawPath(
      path1,
      Paint()..color = const Color(0xFF75B2DF).withValues(alpha: 0.35),
    );

    // Layer 2: Mid Calm Water Wave
    final path2 = Path();
    path2.moveTo(0, h);
    for (double x = 0; x <= w; x += 3) {
      final y = h * 0.62 +
          math.sin(x * 0.014 - t * 1.0 + 1.5) * 6.5 +
          math.sin(x * 0.028 + t * 0.7) * 3.0;
      path2.lineTo(x, y);
    }
    path2.lineTo(w, h);
    path2.close();
    canvas.drawPath(
      path2,
      Paint()..color = const Color(0xFF539ED6).withValues(alpha: 0.45),
    );

    // Layer 3: Foreground Crisp Wave
    final path3 = Path();
    path3.moveTo(0, h);
    for (double x = 0; x <= w; x += 3) {
      final y = h * 0.76 +
          math.sin(x * 0.016 + t * 0.9 + 3.0) * 5.0 +
          math.sin(x * 0.032 - t * 0.8) * 2.0;
      path3.lineTo(x, y);
    }
    path3.lineTo(w, h);
    path3.close();

    final paint3 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF4FA0DE).withValues(alpha: 0.65),
          const Color(0xFF2C7EC4).withValues(alpha: 0.85),
        ],
      ).createShader(Rect.fromLTWH(0, h * 0.70, w, h * 0.30));

    canvas.drawPath(path3, paint3);

    // Subtle Surface Crest Highlight
    final crestPath = Path();
    for (double x = 0; x <= w; x += 4) {
      final y = h * 0.76 +
          math.sin(x * 0.016 + t * 0.9 + 3.0) * 5.0 +
          math.sin(x * 0.032 - t * 0.8) * 2.0;
      if (x == 0) {
        crestPath.moveTo(x, y);
      } else {
        crestPath.lineTo(x, y);
      }
    }
    canvas.drawPath(
      crestPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.50)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _LoginCalmWavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ============================================================================
// WATER DROPLETS PAINTER (GENTLE FLOATING TRANSLUCENT SPHERES)
// ============================================================================

class _WaterDropletsPainter extends CustomPainter {
  final double animationValue;

  _WaterDropletsPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final t = animationValue * math.pi * 2;

    final droplets = [
      Offset(w * 0.22, h * 0.72 + math.sin(t) * 4.0),
      Offset(w * 0.40, h * 0.85 + math.cos(t * 1.1) * 3.5),
      Offset(w * 0.76, h * 0.78 + math.sin(t * 0.9 + 1.0) * 4.5),
      Offset(w * 0.88, h * 0.62 + math.cos(t * 1.2 + 2.0) * 3.0),
    ];

    final radii = [6.5, 4.5, 5.5, 4.0];

    for (int i = 0; i < droplets.length; i++) {
      final center = droplets[i];
      final r = radii[i];

      // Droplet body (translucent aqua/blue)
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.75),
              const Color(0xFF6EC6FF).withValues(alpha: 0.45),
              const Color(0xFF1E88E5).withValues(alpha: 0.25),
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(Rect.fromCircle(center: center, radius: r)),
      );

      // Droplet rim
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );

      // Droplet specular highlight glint
      canvas.drawCircle(
        Offset(center.dx - r * 0.35, center.dy - r * 0.35),
        r * 0.25,
        Paint()..color = Colors.white.withValues(alpha: 0.90),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaterDropletsPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
