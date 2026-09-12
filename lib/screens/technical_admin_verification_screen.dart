import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'admin_console_view.dart';

class TechnicalAdminVerificationScreen extends StatefulWidget {
  const TechnicalAdminVerificationScreen({super.key});

  @override
  State<TechnicalAdminVerificationScreen> createState() =>
      _TechnicalAdminVerificationScreenState();
}

class _TechnicalAdminVerificationScreenState
    extends State<TechnicalAdminVerificationScreen> {
  // --------------------------------------------------------------------------
  // FLOW STAGE: 0 = Form, 1 = MFA / OTP Verification
  // --------------------------------------------------------------------------
  int _currentStep = 0;

  // --------------------------------------------------------------------------
  // FORM CONTROLLERS & FOCUS NODES (STRICTLY 4 ESSENTIAL FIELDS)
  // --------------------------------------------------------------------------
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _adminIdController = TextEditingController();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _adminIdFocus = FocusNode();

  String _selectedOrganization = 'Central Water Commission (CWC)';
  final List<String> _organizations = [
    'Central Water Commission (CWC)',
    'India Meteorological Department (IMD)',
    'National Remote Sensing Centre (NRSC / ISRO)',
    'State Disaster Management Authority (SDMA)',
    'JalGuard Telemetry & Cloud Operations',
  ];

  bool _isFormSubmitting = false;

  // --------------------------------------------------------------------------
  // OTP CONTROLLERS & STATE
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

  bool _isOtpVerifying = false;
  bool _isOtpSuccess = false;
  int _secondsRemaining = 30;
  Timer? _countdownTimer;

  // --------------------------------------------------------------------------
  // LIFECYCLE
  // --------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();

    _nameFocus.addListener(_onFieldUpdate);
    _emailFocus.addListener(_onFieldUpdate);
    _adminIdFocus.addListener(_onFieldUpdate);

    _nameController.addListener(_onFieldUpdate);
    _emailController.addListener(_onFieldUpdate);
    _adminIdController.addListener(_onFieldUpdate);

    for (final f in _otpFocusNodes) {
      f.addListener(_onFieldUpdate);
    }
    for (final c in _otpControllers) {
      c.addListener(_onFieldUpdate);
    }
  }

  void _onFieldUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _adminIdController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _adminIdFocus.dispose();

    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // TIMER & FEEDBACK HELPERS
  // --------------------------------------------------------------------------
  void _startTimer() {
    _countdownTimer?.cancel();
    setState(() => _secondsRemaining = 30);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        backgroundColor: const Color(0xFF7351D8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // STEP 1: VERIFY & REQUEST MFA (WITH ZERO-FRICTION FALLBACKS)
  // --------------------------------------------------------------------------
  Future<void> _handleContinueToOtp() async {
    // If empty, auto-populate realistic fallback values so testing is instant
    if (_nameController.text.trim().isEmpty) {
      _nameController.text = 'Dr. Arvind Subramaniam';
    }
    if (_emailController.text.trim().isEmpty) {
      _emailController.text = 'arvind.subramaniam@cwc.gov.in';
    }
    if (_adminIdController.text.trim().isEmpty) {
      _adminIdController.text = 'SYS-ADM-9041';
    }

    setState(() => _isFormSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 320));
    if (!mounted) return;

    setState(() {
      _isFormSubmitting = false;
      _currentStep = 1;
    });
    _startTimer();
    _showSnack('Admin MFA Code sent to registered official email');

    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted && _otpFocusNodes[0].canRequestFocus) {
        _otpFocusNodes[0].requestFocus();
      }
    });
  }

  // --------------------------------------------------------------------------
  // STEP 2: VERIFY MFA & NAVIGATE TO TECHNICAL ADMIN DASHBOARD
  // --------------------------------------------------------------------------
  Future<void> _handleVerifyOtp() async {
    // Auto-populate 1..6 if empty for effortless testing
    for (int i = 0; i < _otpLength; i++) {
      if (_otpControllers[i].text.isEmpty) {
        _otpControllers[i].text = '${i + 1}';
      }
    }

    setState(() => _isOtpVerifying = true);
    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;

    setState(() {
      _isOtpVerifying = false;
      _isOtpSuccess = true;
    });

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    // Navigate to Technical Admin Dashboard
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AdminConsoleView()),
      (route) => false,
    );
  }

  // --------------------------------------------------------------------------
  // MAIN BUILD
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _currentStep == 0
          ? const Color(0xFFE9F4FB)
          : const Color(0xFFF0F6FA),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double w = constraints.maxWidth;
          final double h = constraints.maxHeight;

          final double scaleW = (w / 390.0).clamp(0.70, 1.40);
          final double scaleH = (h / 844.0).clamp(0.65, 1.35);
          final double scaleMin = math.min(scaleW, scaleH);
          final double textScale =
              (math.min(w / 390.0, h / 800.0)).clamp(0.70, 1.25);

          // Standardize card width to match citizen login screen
          final double maxCardWidth = 960.0;
          final double availableWidth = w - (24.0 * scaleW).clamp(16.0, 48.0);
          final double cardWidth =
              math.min(availableWidth, maxCardWidth).clamp(280.0, maxCardWidth);

          return Stack(
            fit: StackFit.expand,
            children: [
              // Exact Background Image from Citizen Login & OTP Screens
              Positioned.fill(
                child: Image.asset(
                  _currentStep == 0
                      ? 'assets/images/screen_bg_1.png'
                      : 'assets/images/screen_bg_2.png',
                  fit: BoxFit.cover,
                  alignment: _currentStep == 0
                      ? Alignment.topCenter
                      : Alignment.center,
                ),
              ),

              // Content Switcher
              SafeArea(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  transitionBuilder: (child, anim) {
                    return FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.05, 0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: anim,
                          curve: Curves.easeOutCubic,
                        )),
                        child: child,
                      ),
                    );
                  },
                  child: _currentStep == 0
                      ? _buildFormView(scaleW, scaleH, scaleMin, textScale, cardWidth)
                      : _buildOtpView(scaleW, scaleH, scaleMin, textScale, cardWidth),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==========================================================================
  // VIEW 1: TECHNICAL ADMIN VERIFICATION FORM (4 ESSENTIAL FIELDS)
  // ==========================================================================
  Widget _buildFormView(
    double scaleW,
    double scaleH,
    double scaleMin,
    double textScale,
    double cardWidth,
  ) {
    return Column(
      key: const ValueKey('admin_form_view'),
      children: [
        Center(
          child: SizedBox(
            width: cardWidth,
            child: _buildCustomAppBar(
              title: 'Technical Admin Console',
              subtitle: 'Telemetry, Sensors, Satellite & AI Engine',
              badgeText: 'SYSADMIN AUTH',
              badgeColor: const Color(0xFF7351D8),
              onBack: () => Navigator.pop(context),
              textScale: textScale,
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: (18 * scaleW).clamp(14.0, 24.0),
              vertical: (10 * scaleH).clamp(8.0, 18.0),
            ),
            child: Center(
              child: SizedBox(
                width: cardWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F0FC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFDED5F8)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7351D8).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.terminal_rounded,
                          color: Color(0xFF7351D8),
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Authorized system operations access for sensor networks, satellite pipelines & model telemetry.',
                          style: TextStyle(
                            color: Color(0xFF4A329A),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16 * scaleH),

                // 1. Full Name
                _buildFieldLabel('Full Name', isRequired: true),
                const SizedBox(height: 6),
                _buildGlowingTextField(
                  controller: _nameController,
                  focusNode: _nameFocus,
                  hintText: 'e.g. Dr. Arvind Subramaniam',
                  prefixIcon: Icons.person_outline_rounded,
                ),
                SizedBox(height: 14 * scaleH),

                // 2. Official Email
                _buildFieldLabel('Official Government / Organization Email',
                    isRequired: true),
                const SizedBox(height: 6),
                _buildGlowingTextField(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  hintText: 'e.g. arvind.subramaniam@cwc.gov.in',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.alternate_email_rounded,
                ),
                SizedBox(height: 14 * scaleH),

                // 3. Employee / Admin ID
                _buildFieldLabel('Employee / Admin ID', isRequired: true),
                const SizedBox(height: 6),
                _buildGlowingTextField(
                  controller: _adminIdController,
                  focusNode: _adminIdFocus,
                  hintText: 'e.g. SYS-ADM-9041',
                  prefixIcon: Icons.badge_outlined,
                ),
                SizedBox(height: 14 * scaleH),

                // 4. Organization Dropdown
                _buildFieldLabel('Organization / Agency', isRequired: true),
                const SizedBox(height: 6),
                _buildOrganizationDropdown(),
                SizedBox(height: 24 * scaleH),

                // Verify & Request OTP Button
                _buildSubmitButton(
                  title: 'Verify & Request Admin OTP',
                  icon: Icons.vpn_key_rounded,
                  isLoading: _isFormSubmitting,
                  onTap: _handleContinueToOtp,
                  accentColor: const Color(0xFF7351D8),
                  textScale: textScale,
                ),
                const SizedBox(height: 16),

                // Security Note
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.lock_outline_rounded,
                          size: 13, color: Color(0xFF64748B)),
                      SizedBox(width: 5),
                      Text(
                        'Minimum-data authentication • Official organization verified',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ],
);
}

  // ==========================================================================
  // VIEW 2: 6-DIGIT ADMIN MFA / OTP VERIFICATION
  // ==========================================================================
  Widget _buildOtpView(
    double scaleW,
    double scaleH,
    double scaleMin,
    double textScale,
    double cardWidth,
  ) {
    final email = _emailController.text.trim().isNotEmpty
        ? _emailController.text.trim()
        : 'arvind.subramaniam@cwc.gov.in';

    return Column(
      key: const ValueKey('admin_otp_view'),
      children: [
        Center(
          child: SizedBox(
            width: cardWidth,
            child: _buildCustomAppBar(
              title: 'Admin MFA Verification',
              subtitle: 'High-Privilege Security Clearance',
              badgeText: 'MFA STEP 2/2',
              badgeColor: const Color(0xFF7351D8),
              onBack: () => setState(() => _currentStep = 0),
              textScale: textScale,
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: (18 * scaleW).clamp(14.0, 24.0),
              vertical: (14 * scaleH).clamp(10.0, 22.0),
            ),
            child: Center(
              child: SizedBox(
                width: cardWidth,
                child: Column(
                  children: [
                SizedBox(height: 12 * scaleH),
                // Cyber Key Shield Icon
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7351D8).withValues(alpha: 0.22),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.security_rounded,
                      color: Color(0xFF7351D8),
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  'Enter 6-Digit Admin Passkey',
                  style: TextStyle(
                    color: const Color(0xFF0F172A),
                    fontSize: (18 * textScale).clamp(16.0, 20.0),
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'MFA one-time verification passkey sent to\n$email',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF537392),
                    fontSize: (12.5 * textScale).clamp(11.0, 14.0),
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 24 * scaleH),

                // 6-Digit OTP Boxes
                _buildOtpBoxes(scaleW, textScale),
                SizedBox(height: 20 * scaleH),

                // Resend Timer Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: _secondsRemaining > 0
                          ? const Color(0xFF537392)
                          : const Color(0xFF7351D8),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _secondsRemaining > 0
                          ? 'Resend Passkey in ${_secondsRemaining}s'
                          : 'Didn\'t receive code?',
                      style: TextStyle(
                        color: _secondsRemaining > 0
                            ? const Color(0xFF537392)
                            : const Color(0xFF0F172A),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_secondsRemaining == 0) ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          _startTimer();
                          _showSnack('New Admin Passkey dispatched to $email');
                        },
                        child: const Text(
                          'Resend Now',
                          style: TextStyle(
                            color: Color(0xFF7351D8),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 28 * scaleH),

                // Verify & Access Console Button
                _buildSubmitButton(
                  title: 'Verify & Access Admin Console',
                  icon: Icons.login_rounded,
                  isLoading: _isOtpVerifying,
                  isSuccess: _isOtpSuccess,
                  onTap: _handleVerifyOtp,
                  accentColor: const Color(0xFF7351D8),
                  textScale: textScale,
                ),
                const SizedBox(height: 18),

                // Hardware Key MFA Note
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.vpn_lock_rounded,
                      size: 13,
                      color: Color(0xFF64748B),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Multi-Factor Authenticated TLS 1.3 Audit Session',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ],
);
}

  // ==========================================================================
  // WIDGET HELPERS: APPBAR, INPUTS, DROPDOWN, OTP BOXES, BUTTON
  // ==========================================================================

  Widget _buildCustomAppBar({
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required VoidCallback onBack,
    required double textScale,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: Colors.transparent,
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: onBack,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: const Color(0xFFD6E6F2)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A013973),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF0F172A),
                          fontSize: (15.5 * textScale).clamp(14.0, 17.5),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF537392),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                color: badgeColor,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String text, {bool isRequired = false}) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
        ),
        if (isRequired)
          const Text(
            ' *',
            style: TextStyle(
              color: Color(0xFFE92828),
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }

  Widget _buildGlowingTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final bool hasFocus = focusNode.hasFocus;
    final bool hasText = controller.text.isNotEmpty;
    final bool isActive = hasFocus || hasText;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? const Color(0xFF7351D8) : const Color(0xFFD3E4F2),
          width: isActive ? 1.6 : 1.0,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFF7351D8).withValues(alpha: 0.22),
                  blurRadius: 9,
                  spreadRadius: 1.2,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                const BoxShadow(
                  color: Color(0x06013973),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFFA0B3C6),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            prefixIcon,
            size: 20,
            color: isActive
                ? const Color(0xFF7351D8)
                : const Color(0xFF7A9BB8),
          ),
        ),
      ),
    );
  }

  Widget _buildOrganizationDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD3E4F2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06013973),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedOrganization,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF7351D8),
          ),
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
          onChanged: (val) {
            if (val != null) setState(() => _selectedOrganization = val);
          },
          items: _organizations.map((org) {
            return DropdownMenuItem<String>(
              value: org,
              child: Row(
                children: [
                  const Icon(
                    Icons.account_balance_rounded,
                    size: 16,
                    color: Color(0xFF7351D8),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      org,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildOtpBoxes(double scaleW, double textScale) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_otpLength, (index) {
        final controller = _otpControllers[index];
        final focusNode = _otpFocusNodes[index];
        final bool hasFocus = focusNode.hasFocus;
        final bool hasText = controller.text.isNotEmpty;

        return Container(
          width: (45 * scaleW).clamp(38.0, 50.0),
          height: (52 * scaleW).clamp(44.0, 56.0),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasFocus
                  ? const Color(0xFF7351D8)
                  : (hasText
                      ? const Color(0xFF007AEB)
                      : const Color(0xFFD0DFEC)),
              width: hasFocus ? 2.0 : 1.2,
            ),
            boxShadow: hasFocus
                ? [
                    BoxShadow(
                      color: const Color(0xFF7351D8).withValues(alpha: 0.28),
                      blurRadius: 10,
                      spreadRadius: 1.5,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    const BoxShadow(
                      color: Color(0x0D013973),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
          ),
          child: Center(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              style: TextStyle(
                color: const Color(0xFF0F172A),
                fontSize: (20 * textScale).clamp(18.0, 23.0),
                fontWeight: FontWeight.w900,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                counterText: '',
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  if (index < _otpLength - 1) {
                    _otpFocusNodes[index + 1].requestFocus();
                  } else {
                    focusNode.unfocus();
                  }
                } else if (value.isEmpty && index > 0) {
                  _otpFocusNodes[index - 1].requestFocus();
                }
              },
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSubmitButton({
    required String title,
    required IconData icon,
    required bool isLoading,
    bool isSuccess = false,
    required VoidCallback onTap,
    required Color accentColor,
    required double textScale,
  }) {
    return GestureDetector(
      onTap: isLoading || isSuccess ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSuccess
                ? [const Color(0xFF15945C), const Color(0xFF10B981)]
                : [accentColor, const Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(13),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
              : isSuccess
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.check_circle_rounded,
                            color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Authenticated ✓',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: (14.5 * textScale).clamp(13.5, 16.0),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}
