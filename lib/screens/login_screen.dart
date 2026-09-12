import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'otp_screen.dart';
import 'new_account_screen.dart';

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

  // Segmented auth tab selection: 0 = Sign In, 1 = New Account
  int _selectedAuthTab = 0;
  bool _isSwitchingTab = false;

  // --------------------------------------------------------------------------
  // BUTTON & FLOW STATES
  // --------------------------------------------------------------------------
  bool _buttonPressed = false;
  bool _isLoading = false;
  bool _isSuccess = false;

  // --------------------------------------------------------------------------
  // AMBIENT ANIMATION CONTROLLERS
  // --------------------------------------------------------------------------
  late final AnimationController _successController;
  late final Animation<double> _successScale;

  @override
  void initState() {
    super.initState();

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

    _identityController.addListener(() {
      _validateIdentityInput();
      if (mounted) setState(() {});
    });

    _passwordController.addListener(() {
      if (mounted) setState(() {});
    });
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
    _successController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // AUTH TAB SLIDE & NAVIGATION
  // --------------------------------------------------------------------------
  Future<void> _handleAuthTabTap(int index) async {
    if (_selectedAuthTab == index || _isSwitchingTab) return;
    setState(() {
      _selectedAuthTab = index;
      _isSwitchingTab = true;
    });

    if (index == 1) {
      // Wait for the blue container to slide smoothly across to New Account
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;

      await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const NewAccountScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 220),
        ),
      );

      // When returning from New Account screen, reset back to Sign In
      if (mounted) {
        setState(() {
          _selectedAuthTab = 0;
          _isSwitchingTab = false;
        });
      }
    }
  }

  // --------------------------------------------------------------------------
  // LOGIN SUBMIT LOGIC
  // --------------------------------------------------------------------------
  Future<void> _handleLogin() async {
    if (_isLoading || _isSuccess) return;

    if (_identityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter your phone number'),
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
                  'assets/images/screen_bg_1.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),

              // ==================================================================
              // 2. MAIN SINGLE SCREEN CONTENT (NO SCROLLING, ZERO OVERFLOW)
              // ==================================================================
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── TOP NAV BAR (BACK BUTTON & LANGUAGE SELECTOR) ──
                      _buildTopBar(context, scaleW, scaleH, scaleMin, textScale),

                      const Spacer(flex: 1),

                      // ── BIG CENTERED LOGO + RESQSHIELD + 1-LINE MOTTO ──
                      _buildCenteredBrandHeader(scaleW, scaleH, scaleMin, textScale),

                      SizedBox(height: (12.0 * scaleH).clamp(8.0, 18.0)),

                      // ── LOGIN CARD / SUCCESS CARD ──
                      _buildLoginCard(scaleW, scaleH, scaleMin, textScale, screenWidth: w),

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
  // TOP BAR: BACK BUTTON + LANGUAGE SELECTOR
  // --------------------------------------------------------------------------
  Widget _buildTopBar(
    BuildContext context,
    double scaleW,
    double scaleH,
    double scaleMin,
    double textScale,
  ) {
    final bool canPop = Navigator.canPop(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (canPop)
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF013973),
              size: 20,
            ),
            onPressed: () => Navigator.maybePop(context),
            tooltip: 'Back',
          )
        else
          const SizedBox(width: 36),

        // Language Selector Pill (🇮🇳 EN v)
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Language set to English (IN)'),
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
                Text(
                  '🇮🇳',
                  style: TextStyle(fontSize: (11.5 * textScale).clamp(9.5, 13.0)),
                ),
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
  // BIG CENTERED LOGO + RESQSHIELD NAME + 1-LINE MOTTO
  // --------------------------------------------------------------------------
  Widget _buildCenteredBrandHeader(
    double scaleW,
    double scaleH,
    double scaleMin,
    double textScale,
  ) {
    final double logoSize = (66.0 * scaleMin).clamp(54.0, 80.0);
    final double resSize = (26.0 * textScale).clamp(22.0, 30.0);
    final double qSize = (28.0 * textScale).clamp(24.0, 32.0);
    final double mottoSize = (11.5 * textScale).clamp(9.5, 13.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Big Centered Logo with soft ambient shadow
        Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF013973).withValues(alpha: 0.14),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/app_logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Icon(
              Icons.shield_rounded,
              size: logoSize * 0.9,
              color: const Color(0xFF013973),
            ),
          ),
        ),

        SizedBox(height: (10.0 * scaleH).clamp(6.0, 14.0)),

        // Big Centered Brand Name
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Res',
                style: TextStyle(
                  color: const Color(0xFF013973),
                  fontSize: resSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              TextSpan(
                text: 'Q',
                style: TextStyle(
                  color: const Color(0xFF00FF00),
                  fontSize: qSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
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
                  fontSize: resSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: (4.0 * scaleH).clamp(2.0, 6.0)),

        // 1-Line Clean Motto
        Text(
          'Safer Routes • Real-Time Alert • Stronger Communities',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: const Color(0xFF537392),
            fontSize: mottoSize,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // LOGIN CARD / SUCCESS TRANSITION
  // --------------------------------------------------------------------------
  Widget _buildLoginCard(
    double scaleW,
    double scaleH,
    double scaleMin,
    double textScale, {
    required double screenWidth,
  }) {
    // Doubled container width (up to 960px, 2x of previous 480px cap),
    // safely bounded by available screen width so there is zero overflow on mobile/tablet,
    // and strictly center aligned.
    final double maxCardWidth = 960.0;
    final double availableWidth = screenWidth - (24.0 * scaleW).clamp(16.0, 48.0);
    final double cardWidth = math.min(availableWidth, maxCardWidth).clamp(280.0, maxCardWidth);

    return Center(
      child: SizedBox(
        width: cardWidth,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
          width: cardWidth,
          padding: EdgeInsets.symmetric(
            horizontal: (22.0 * scaleW).clamp(16.0, 32.0),
            vertical: (20.0 * scaleH).clamp(16.0, 26.0),
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
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
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // SEGMENTED AUTH TOGGLE PILL: [ Sign In ] [ New Account ]
  // --------------------------------------------------------------------------
  Widget _buildAuthTogglePill(
    double scaleW,
    double scaleH,
    double scaleMin,
    double textScale,
  ) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF3FA),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFD6E6F2)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double tabWidth = (constraints.maxWidth - 4) / 2;
          return Stack(
            children: [
              // Sliding active blue pill indicator
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                left: _selectedAuthTab == 0 ? 0 : tabWidth + 4,
                width: tabWidth,
                top: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF013973),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF013973).withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),

              // Labels on top
              Row(
                children: [
                  // Sign In Tab
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _handleAuthTabTap(0),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        alignment: Alignment.center,
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          style: TextStyle(
                            color: _selectedAuthTab == 0
                                ? Colors.white
                                : const Color(0xFF537392),
                            fontSize: (15.5 * textScale).clamp(14.0, 17.5),
                            fontWeight: _selectedAuthTab == 0
                                ? FontWeight.w800
                                : FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                          child: const Text('Sign In'),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // New Account Tab
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _handleAuthTabTap(1),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        alignment: Alignment.center,
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          style: TextStyle(
                            color: _selectedAuthTab == 1
                                ? Colors.white
                                : const Color(0xFF537392),
                            fontSize: (15.5 * textScale).clamp(14.0, 17.5),
                            fontWeight: _selectedAuthTab == 1
                                ? FontWeight.w800
                                : FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                          child: const Text('New Account'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
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
        // ── SEGMENTED AUTH TOGGLE PILL: [ Sign In ] [ New Account ] ──
        _buildAuthTogglePill(scaleW, scaleH, scaleMin, textScale),

        SizedBox(height: (12.0 * scaleH).clamp(8.0, 16.0)),

        // Title
        Text(
          'Welcome Back',
          style: TextStyle(
            color: const Color(0xFF0F172A),
            fontSize: (19.0 * textScale).clamp(16.0, 23.0),
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        SizedBox(height: (3.0 * scaleH).clamp(1.5, 5.0)),
        Text(
          'Login to continue to ResQShield',
          style: TextStyle(
            color: const Color(0xFF64748B),
            fontSize: (12.0 * textScale).clamp(10.0, 14.5),
            fontWeight: FontWeight.w500,
          ),
        ),

        SizedBox(height: (10.0 * scaleH).clamp(5.0, 14.0)),

        // ── PHONE NUMBER FIELD ──
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
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => setState(() => _rememberMe = !_rememberMe),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: (17.0 * scaleMin).clamp(14.0, 19.0),
                        height: (17.0 * scaleMin).clamp(14.0, 19.0),
                        decoration: BoxDecoration(
                          color: _rememberMe
                              ? const Color(0xFF007AEB)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(4.5),
                          border: Border.all(
                            color: _rememberMe
                                ? const Color(0xFF007AEB)
                                : const Color(0xFFCBD5E1),
                            width: 1.4,
                          ),
                        ),
                        child: _rememberMe
                            ? Icon(Icons.check, size: (12.0 * scaleMin).clamp(10.0, 14.0), color: Colors.white)
                            : null,
                      ),
                      SizedBox(width: (6.0 * scaleW).clamp(4.0, 8.0)),
                      Text(
                        'Remember me',
                        style: TextStyle(
                          color: const Color(0xFF334155),
                          fontSize: (12.5 * textScale).clamp(11.0, 14.5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Forgot Password Link
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: GestureDetector(
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
                      fontSize: (12.0 * textScale).clamp(10.5, 14.0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: (11.0 * scaleH).clamp(7.0, 15.0)),

        // ── LOGIN BUTTON (3 CLEAN STATES) ──
        _buildLoginButton(scaleW, scaleH, scaleMin, textScale),

        SizedBox(height: (8.0 * scaleH).clamp(5.0, 12.0)),

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
                  fontSize: (10.0 * textScale).clamp(8.5, 12.0),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Expanded(
              child: Divider(color: Color(0xFFE2E8F0), thickness: 1.0),
            ),
          ],
        ),

        SizedBox(height: (8.0 * scaleH).clamp(5.0, 12.0)),

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
                  size: (21.5 * scaleMin).clamp(18.0, 25.0),
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
  // --------------------------------------------------------------------------
  // MOBILE NUMBER INPUT FIELD (CENTERED & LARGE DIGITS)
  // --------------------------------------------------------------------------
  // --------------------------------------------------------------------------
  // EMAIL / IDENTITY INPUT FIELD (EQUAL SIZING WITH PREFIX ICON)
  // --------------------------------------------------------------------------
  Widget _buildIdentityTextField(double scaleW, double scaleH, double scaleMin, double textScale) {
    final bool hasText = _identityController.text.isNotEmpty;

    Color borderColor = const Color(0xFFE2E8F0);
    if (_isIdentityValid) {
      borderColor = const Color(0xFF22C55E); // Subtle green
    } else if (_isIdentityFocused) {
      borderColor = const Color(0xFF007AEB); // Primary blue
    } else if (hasText) {
      borderColor = const Color(0xFF007AEB).withValues(alpha: 0.7);
    }

    final double inputFontSize = (17.5 * textScale).clamp(15.5, 20.0);
    final double hintFontSize = (14.0 * textScale).clamp(12.0, 16.0);
    final double iconSize = (20.0 * scaleMin).clamp(17.0, 22.0);
    final double boxHeight = (52.0 * scaleH).clamp(46.0, 56.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      height: boxHeight,
      alignment: Alignment.center,
      transform: Matrix4.translationValues(0, _isIdentityFocused ? -1.0 : 0.0, 0),
      decoration: BoxDecoration(
        color: _isIdentityFocused ? Colors.white : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular((13.0 * scaleMin).clamp(11.0, 16.0)),
        border: Border.all(
          color: borderColor,
          width: _isIdentityFocused ? 1.8 : (hasText ? 1.4 : 1.0),
        ),
        boxShadow: _isIdentityFocused
            ? [
                // Soft radiating light glow around the border
                BoxShadow(
                  color: (_isIdentityValid
                          ? const Color(0xFF22C55E)
                          : const Color(0xFF007AEB))
                      .withValues(alpha: 0.24),
                  blurRadius: 10,
                  spreadRadius: 1.2,
                  offset: const Offset(0, 0),
                ),
                BoxShadow(
                  color: (_isIdentityValid
                          ? const Color(0xFF22C55E)
                          : const Color(0xFF007AEB))
                      .withValues(alpha: 0.12),
                  blurRadius: 4,
                  spreadRadius: 0.5,
                  offset: const Offset(0, 1),
                ),
              ]
            : (hasText
                ? [
                    // Subtle light halo when text is entered
                    BoxShadow(
                      color: (_isIdentityValid
                              ? const Color(0xFF22C55E)
                              : const Color(0xFF007AEB))
                          .withValues(alpha: 0.12),
                      blurRadius: 7,
                      spreadRadius: 0.6,
                      offset: const Offset(0, 0),
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: Color(0x04000000),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ]),
      ),
      child: TextField(
        controller: _identityController,
        focusNode: _identityFocusNode,
        keyboardType: TextInputType.phone,
        textAlign: TextAlign.center,
        textInputAction: TextInputAction.next,
        style: TextStyle(
          color: const Color(0xFF013973),
          fontSize: inputFontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Enter Phone Number',
          hintStyle: TextStyle(
            color: const Color(0xFF94A3B8),
            fontSize: hintFontSize,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
          border: InputBorder.none,
          prefixIcon: Icon(
            Icons.phone_outlined,
            color: _isIdentityFocused
                ? const Color(0xFF007AEB)
                : (_isIdentityValid
                    ? const Color(0xFF22C55E)
                    : const Color(0xFF94A3B8)),
            size: iconSize,
          ),
          prefixIconConstraints: BoxConstraints(
            minWidth: (42.0 * scaleMin).clamp(36.0, 48.0),
            minHeight: boxHeight,
          ),
          suffixIcon: _identityController.text.isNotEmpty
              ? GestureDetector(
                  onTap: () => _identityController.clear(),
                  child: Icon(
                    Icons.close_rounded,
                    color: const Color(0xFF94A3B8),
                    size: (17.0 * scaleMin).clamp(14.0, 20.0),
                  ),
                )
              : SizedBox(width: (42.0 * scaleMin).clamp(36.0, 48.0)),
          suffixIconConstraints: BoxConstraints(
            minWidth: (42.0 * scaleMin).clamp(36.0, 48.0),
            minHeight: boxHeight,
          ),
          contentPadding: EdgeInsets.symmetric(
            vertical: (14.0 * scaleH).clamp(11.0, 16.0),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // PASSWORD INPUT FIELD (EQUAL SIZING WITH PREFIX ICON)
  // --------------------------------------------------------------------------
  Widget _buildPasswordTextField(double scaleW, double scaleH, double scaleMin, double textScale) {
    final bool hasText = _passwordController.text.isNotEmpty;

    Color borderColor = _isPasswordFocused
        ? const Color(0xFF007AEB)
        : (hasText ? const Color(0xFF007AEB).withValues(alpha: 0.7) : const Color(0xFFE2E8F0));

    final double inputFontSize = (17.5 * textScale).clamp(15.5, 20.0);
    final double hintFontSize = (14.0 * textScale).clamp(12.0, 16.0);
    final double iconSize = (20.0 * scaleMin).clamp(17.0, 22.0);
    final double boxHeight = (52.0 * scaleH).clamp(46.0, 56.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      height: boxHeight,
      alignment: Alignment.center,
      transform: Matrix4.translationValues(0, _isPasswordFocused ? -1.0 : 0.0, 0),
      decoration: BoxDecoration(
        color: _isPasswordFocused ? Colors.white : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular((13.0 * scaleMin).clamp(11.0, 16.0)),
        border: Border.all(
          color: borderColor,
          width: _isPasswordFocused ? 1.8 : (hasText ? 1.4 : 1.0),
        ),
        boxShadow: _isPasswordFocused
            ? [
                // Soft radiating light glow around the border
                BoxShadow(
                  color: const Color(0xFF007AEB).withValues(alpha: 0.24),
                  blurRadius: 10,
                  spreadRadius: 1.2,
                  offset: const Offset(0, 0),
                ),
                BoxShadow(
                  color: const Color(0xFF007AEB).withValues(alpha: 0.12),
                  blurRadius: 4,
                  spreadRadius: 0.5,
                  offset: const Offset(0, 1),
                ),
              ]
            : (hasText
                ? [
                    // Subtle light halo when text is entered
                    BoxShadow(
                      color: const Color(0xFF007AEB).withValues(alpha: 0.12),
                      blurRadius: 7,
                      spreadRadius: 0.6,
                      offset: const Offset(0, 0),
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: Color(0x04000000),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ]),
      ),
      child: TextField(
        controller: _passwordController,
        focusNode: _passwordFocusNode,
        obscureText: _obscurePassword,
        textAlign: TextAlign.center,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _handleLogin(),
        style: TextStyle(
          color: const Color(0xFF013973),
          fontSize: inputFontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: _obscurePassword ? 3.5 : 1.2,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Enter Password',
          hintStyle: TextStyle(
            color: const Color(0xFF94A3B8),
            fontSize: hintFontSize,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
          border: InputBorder.none,
          prefixIcon: Icon(
            Icons.lock_outline_rounded,
            color: _isPasswordFocused
                ? const Color(0xFF007AEB)
                : const Color(0xFF94A3B8),
            size: iconSize,
          ),
          prefixIconConstraints: BoxConstraints(
            minWidth: (42.0 * scaleMin).clamp(36.0, 48.0),
            minHeight: boxHeight,
          ),
          suffixIcon: GestureDetector(
            onTap: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
            behavior: HitTestBehavior.opaque,
            child: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              key: ValueKey(_obscurePassword),
              color: const Color(0xFF64748B),
              size: (18.0 * scaleMin).clamp(15.0, 22.0),
            ),
          ),
          suffixIconConstraints: BoxConstraints(
            minWidth: (42.0 * scaleMin).clamp(36.0, 48.0),
            minHeight: boxHeight,
          ),
          contentPadding: EdgeInsets.symmetric(
            vertical: (14.0 * scaleH).clamp(11.0, 16.0),
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
          height: (50.0 * scaleH).clamp(46.0, 56.0),
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF007AEB), Color(0xFF005BC5)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular((16.0 * scaleMin).clamp(13.0, 20.0)),
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
                          width: (16.0 * scaleMin).clamp(13.0, 18.0),
                          height: (16.0 * scaleMin).clamp(13.0, 18.0),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Logging in...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: (14.5 * textScale).clamp(12.5, 17.0),
                            fontWeight: FontWeight.w700,
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
                            fontSize: (15.5 * textScale).clamp(14.0, 18.0),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: (17.5 * scaleMin).clamp(15.0, 20.0),
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
        height: (48.0 * scaleH).clamp(44.0, 54.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular((14.0 * scaleMin).clamp(12.0, 17.0)),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget,
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFF1E293B),
                  fontSize: (14.5 * textScale).clamp(13.0, 17.0),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
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
    final double dim = (20.5 * scaleMin).clamp(18.0, 24.0);
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


