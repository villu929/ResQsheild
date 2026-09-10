import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'field_responder_view.dart';

class FieldResponderVerificationScreen extends StatefulWidget {
  const FieldResponderVerificationScreen({super.key});

  @override
  State<FieldResponderVerificationScreen> createState() =>
      _FieldResponderVerificationScreenState();
}

class _FieldResponderVerificationScreenState
    extends State<FieldResponderVerificationScreen>
    with TickerProviderStateMixin {
  // --------------------------------------------------------------------------
  // FLOW STAGE: 0 = Form, 1 = OTP Verification
  // --------------------------------------------------------------------------
  int _currentStep = 0;

  // --------------------------------------------------------------------------
  // FORM CONTROLLERS & FOCUS NODES
  // --------------------------------------------------------------------------
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _responderIdController = TextEditingController();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _mobileFocus = FocusNode();
  final FocusNode _responderIdFocus = FocusNode();

  String _selectedOrganization = 'NDRF (National Disaster Response Force)';
  final List<String> _organizations = [
    'NDRF (National Disaster Response Force)',
    'SDRF (State Disaster Response Force)',
    'Fire & Emergency Services',
    'State Police & Flood Rescue Cell',
    'Authorized Quick Rescue Organization',
    'Civil Defence Volunteer Corps',
  ];

  // Attached document state
  String? _idCardPhotoName;
  String? _personalPhotoName;

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

    // Rebuild listeners for dynamic border outline & soft glowing light effect
    _nameFocus.addListener(_onFieldUpdate);
    _mobileFocus.addListener(_onFieldUpdate);
    _responderIdFocus.addListener(_onFieldUpdate);

    _nameController.addListener(_onFieldUpdate);
    _mobileController.addListener(_onFieldUpdate);
    _responderIdController.addListener(_onFieldUpdate);

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
    _mobileController.dispose();
    _responderIdController.dispose();
    _nameFocus.dispose();
    _mobileFocus.dispose();
    _responderIdFocus.dispose();

    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // TIMER & SNACKBAR HELPERS
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
        backgroundColor: const Color(0xFF15945C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // IMAGE PICKER MODAL (CAMERA / GALLERY SIMULATION)
  // --------------------------------------------------------------------------
  void _showImagePickerModal({
    required String title,
    required bool isSelfie,
    required void Function(String fileName) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Color(0x1F013973),
              blurRadius: 24,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF15945C).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isSelfie ? Icons.face_rounded : Icons.badge_rounded,
                      color: const Color(0xFF15945C),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upload $title',
                          style: const TextStyle(
                            color: Color(0xFF013973),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          isSelfie
                              ? 'Capture live face verification or pick photo'
                              : 'Upload clear front view of Official ID Card',
                          style: const TextStyle(
                            color: Color(0xFF537392),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ListTile(
                onTap: () {
                  Navigator.pop(ctx);
                  final simulated =
                      '${title.toLowerCase().replaceAll(' ', '_')}_camera.jpg';
                  onSelected(simulated);
                  _showSnack('$title captured successfully ✓');
                },
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F6EF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.photo_camera_rounded,
                    color: Color(0xFF15945C),
                  ),
                ),
                title: Text(
                  isSelfie ? 'Open Camera (Take Selfie)' : 'Open Camera (Scan ID)',
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: const Text(
                  'Immediate verification snapshot',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              ListTile(
                onTap: () {
                  Navigator.pop(ctx);
                  final simulated =
                      '${title.toLowerCase().replaceAll(' ', '_')}_gallery.jpg';
                  onSelected(simulated);
                  _showSnack('$title selected from gallery ✓');
                },
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF5FC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: Color(0xFF007AEB),
                  ),
                ),
                title: const Text(
                  'Choose from Gallery',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: const Text(
                  'Select existing photo from device storage',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // STEP 1: CONTINUE TO OTP (WITH SMART ZERO-FRICTION FALLBACKS)
  // --------------------------------------------------------------------------
  Future<void> _handleContinueToOtp() async {
    // If empty, auto-populate realistic fallback values so testing is instant
    if (_nameController.text.trim().isEmpty) {
      _nameController.text = 'Inspector Vikramaditya Singh';
    }
    if (_mobileController.text.trim().isEmpty) {
      _mobileController.text = '9876543210';
    }
    if (_responderIdController.text.trim().isEmpty) {
      _responderIdController.text = 'NDRF-8842-FLD';
    }
    _idCardPhotoName ??= 'official_id_card_doc.jpg';
    _personalPhotoName ??= 'responder_selfie_verified.jpg';

    setState(() => _isFormSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 320));
    if (!mounted) return;

    setState(() {
      _isFormSubmitting = false;
      _currentStep = 1;
    });
    _startTimer();
    _showSnack('Tactical OTP sent to registered mobile number');

    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted && _otpFocusNodes[0].canRequestFocus) {
        _otpFocusNodes[0].requestFocus();
      }
    });
  }

  // --------------------------------------------------------------------------
  // STEP 2: OTP VERIFICATION & NAVIGATION TO FIELD RESPONDER DASHBOARD
  // --------------------------------------------------------------------------
  Future<void> _handleVerifyOtp() async {
    // If OTP empty, auto-populate 1..6 so user can test directly
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

    // Navigate to Field Responder Tactical Dashboard
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const FieldResponderView()),
      (route) => false,
    );
  }

  // --------------------------------------------------------------------------
  // MAIN BUILD
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FA),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double w = constraints.maxWidth;
          final double h = constraints.maxHeight;

          final double scaleW = (w / 390.0).clamp(0.70, 1.40);
          final double scaleH = (h / 844.0).clamp(0.65, 1.35);
          final double scaleMin = math.min(scaleW, scaleH);
          final double textScale =
              (math.min(w / 390.0, h / 800.0)).clamp(0.70, 1.25);

          return Stack(
            fit: StackFit.expand,
            children: [
              // Ambient Background Image
              Positioned.fill(
                child: Image.asset(
                  'assets/images/screen_bg_2.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),

              // Tactical Ambient Gradient Glow
              Positioned(
                top: -80,
                right: -60,
                width: 260,
                height: 260,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF15945C).withValues(alpha: 0.16),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -100,
                left: -80,
                width: 320,
                height: 320,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF013973).withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Main SafeArea Content
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
                      ? _buildFormView(scaleW, scaleH, scaleMin, textScale)
                      : _buildOtpView(scaleW, scaleH, scaleMin, textScale),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==========================================================================
  // VIEW 1: FIELD RESPONDER VERIFICATION FORM
  // ==========================================================================
  Widget _buildFormView(
    double scaleW,
    double scaleH,
    double scaleMin,
    double textScale,
  ) {
    return Column(
      key: const ValueKey('responder_form_view'),
      children: [
        _buildCustomAppBar(
          title: 'Field Responder Authorization',
          subtitle: 'Tactical Ground Units • JalGuard',
          badgeText: 'TACTICAL UNIT',
          badgeColor: const Color(0xFF15945C),
          onBack: () => Navigator.pop(context),
          textScale: textScale,
        ),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: (18 * scaleW).clamp(14.0, 24.0),
              vertical: (8 * scaleH).clamp(6.0, 16.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F7F0),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFB9E8D3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF15945C).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_user_rounded,
                          color: Color(0xFF15945C),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Authorized identity & deployment verification for ground rescue teams.',
                          style: TextStyle(
                            color: Color(0xFF0E5C38),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 14 * scaleH),

                // 1. Full Name Field
                _buildFieldLabel('Full Name', isRequired: true),
                const SizedBox(height: 6),
                _buildGlowingTextField(
                  controller: _nameController,
                  focusNode: _nameFocus,
                  hintText: 'e.g. Inspector Vikramaditya Singh',
                  prefixIcon: Icons.person_outline_rounded,
                ),
                SizedBox(height: 12 * scaleH),

                // 2. Mobile Number Field
                _buildFieldLabel('Mobile Number (For OTP Verification)',
                    isRequired: true),
                const SizedBox(height: 6),
                _buildGlowingTextField(
                  controller: _mobileController,
                  focusNode: _mobileFocus,
                  hintText: '98765 43210',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_android_rounded,
                  isPhonePrefix: true,
                ),
                SizedBox(height: 12 * scaleH),

                // 3. Responder / Employee ID Field
                _buildFieldLabel('Responder / Employee ID', isRequired: true),
                const SizedBox(height: 6),
                _buildGlowingTextField(
                  controller: _responderIdController,
                  focusNode: _responderIdFocus,
                  hintText: 'e.g. NDRF-8842-FLD',
                  prefixIcon: Icons.badge_outlined,
                ),
                SizedBox(height: 12 * scaleH),

                // 4. Organization / Department Dropdown
                _buildFieldLabel('Organization / Department', isRequired: true),
                const SizedBox(height: 6),
                _buildOrganizationDropdown(),
                SizedBox(height: 16 * scaleH),

                // 5. Verification Documents Section Header
                Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 17,
                      color: Color(0xFF013973),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Required Verification Documents',
                      style: TextStyle(
                        color: const Color(0xFF013973),
                        fontSize: (13.5 * textScale).clamp(12.5, 15.0),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Row of Document Cards (Official ID + Selfie)
                Row(
                  children: [
                    // Official ID Card
                    Expanded(
                      child: _buildUploadCard(
                        title: 'Official ID Card',
                        subtitle: 'Front Photo',
                        icon: Icons.credit_card_rounded,
                        fileName: _idCardPhotoName,
                        onTap: () {
                          _showImagePickerModal(
                            title: 'Official ID Card',
                            isSelfie: false,
                            onSelected: (name) =>
                                setState(() => _idCardPhotoName = name),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Personal Photo / Selfie
                    Expanded(
                      child: _buildUploadCard(
                        title: 'Personal Photo',
                        subtitle: 'Live Selfie / Face',
                        icon: Icons.face_retouching_natural_rounded,
                        fileName: _personalPhotoName,
                        onTap: () {
                          _showImagePickerModal(
                            title: 'Personal Photo',
                            isSelfie: true,
                            onSelected: (name) =>
                                setState(() => _personalPhotoName = name),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20 * scaleH),

                // Submit Button: Verify & Continue to OTP
                _buildSubmitButton(
                  title: 'Verify & Request Tactical OTP',
                  icon: Icons.lock_outline_rounded,
                  isLoading: _isFormSubmitting,
                  onTap: _handleContinueToOtp,
                  accentColor: const Color(0xFF15945C),
                  textScale: textScale,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // VIEW 2: TACTICAL OTP VERIFICATION
  // ==========================================================================
  Widget _buildOtpView(
    double scaleW,
    double scaleH,
    double scaleMin,
    double textScale,
  ) {
    final displayPhone = _mobileController.text.trim().isNotEmpty
        ? _mobileController.text.trim()
        : '9876543210';
    final maskedPhone = displayPhone.length >= 4
        ? '+91 ******${displayPhone.substring(displayPhone.length - 4)}'
        : '+91 ******3210';

    return Column(
      key: const ValueKey('responder_otp_view'),
      children: [
        _buildCustomAppBar(
          title: 'Tactical OTP Verification',
          subtitle: 'High-Security 2FA Authentication',
          badgeText: 'SECURITY STEP 2/2',
          badgeColor: const Color(0xFF007AEB),
          onBack: () => setState(() => _currentStep = 0),
          textScale: textScale,
        ),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: (18 * scaleW).clamp(14.0, 24.0),
              vertical: (12 * scaleH).clamp(8.0, 20.0),
            ),
            child: Column(
              children: [
                SizedBox(height: 10 * scaleH),
                // Tactile Key Shield Icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF15945C).withValues(alpha: 0.20),
                        blurRadius: 18,
                        spreadRadius: 2,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.phonelink_lock_rounded,
                      color: Color(0xFF15945C),
                      size: 34,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  'Enter 6-Digit Tactical OTP',
                  style: TextStyle(
                    color: const Color(0xFF013973),
                    fontSize: (18 * textScale).clamp(16.0, 20.0),
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Emergency verification code sent to $maskedPhone',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF537392),
                    fontSize: (12.5 * textScale).clamp(11.0, 14.0),
                    fontWeight: FontWeight.w500,
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
                          : const Color(0xFF15945C),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _secondsRemaining > 0
                          ? 'Resend OTP in ${_secondsRemaining}s'
                          : 'Didn\'t receive OTP?',
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
                          _showSnack('New OTP sent to $maskedPhone');
                        },
                        child: const Text(
                          'Resend Now',
                          style: TextStyle(
                            color: Color(0xFF15945C),
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

                // Verify Button
                _buildSubmitButton(
                  title: 'Verify & Access Field Portal',
                  icon: Icons.check_circle_outline_rounded,
                  isLoading: _isOtpVerifying,
                  isSuccess: _isOtpSuccess,
                  onTap: _handleVerifyOtp,
                  accentColor: const Color(0xFF15945C),
                  textScale: textScale,
                ),
                const SizedBox(height: 18),

                // Security Note
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.lock_rounded,
                      size: 13,
                      color: Color(0xFF64748B),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'End-to-end encrypted dispatch network protocol',
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
      ],
    );
  }

  // ==========================================================================
  // WIDGET HELPERS: APPBAR, INPUTS, DROPDOWN, UPLOAD CARDS, OTP BOXES
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
                color: Color(0xFF013973),
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
                          color: const Color(0xFF013973),
                          fontSize: (15.5 * textScale).clamp(14.0, 17.5),
                          fontWeight: FontWeight.w800,
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
            color: Color(0xFF013973),
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
    bool isPhonePrefix = false,
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
          color: isActive ? const Color(0xFF15945C) : const Color(0xFFD3E4F2),
          width: isActive ? 1.6 : 1.0,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFF15945C).withValues(alpha: 0.22),
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
          prefixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 12),
              Icon(
                prefixIcon,
                size: 20,
                color: isActive
                    ? const Color(0xFF15945C)
                    : const Color(0xFF7A9BB8),
              ),
              if (isPhonePrefix) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F7F0),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text(
                    '+91',
                    style: TextStyle(
                      color: Color(0xFF0E5C38),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 8),
            ],
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
            color: Color(0xFF013973),
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
                    Icons.shield_rounded,
                    size: 16,
                    color: Color(0xFF15945C),
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

  Widget _buildUploadCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String? fileName,
    required VoidCallback onTap,
  }) {
    final bool isUploaded = fileName != null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUploaded ? const Color(0xFF15945C) : const Color(0xFFD3E4F2),
            width: isUploaded ? 1.6 : 1.0,
          ),
          boxShadow: isUploaded
              ? [
                  BoxShadow(
                    color: const Color(0xFF15945C).withValues(alpha: 0.16),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Color(0x06013973),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isUploaded
                        ? const Color(0xFFE8F7F0)
                        : const Color(0xFFEBF5FC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: isUploaded
                        ? const Color(0xFF15945C)
                        : const Color(0xFF007AEB),
                  ),
                ),
                const Spacer(),
                if (isUploaded)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF15945C),
                    size: 18,
                  )
                else
                  const Icon(
                    Icons.add_a_photo_outlined,
                    color: Color(0xFF7A9BB8),
                    size: 18,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF013973),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isUploaded ? fileName : subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isUploaded
                    ? const Color(0xFF15945C)
                    : const Color(0xFF64748B),
                fontSize: 11,
                fontWeight: isUploaded ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
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
                  ? const Color(0xFF15945C)
                  : (hasText
                      ? const Color(0xFF007AEB)
                      : const Color(0xFFD0DFEC)),
              width: hasFocus ? 2.0 : 1.2,
            ),
            boxShadow: hasFocus
                ? [
                    BoxShadow(
                      color: const Color(0xFF15945C).withValues(alpha: 0.28),
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
                color: const Color(0xFF013973),
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
                : [accentColor, const Color(0xFF013973)],
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
                          'Verified ✓',
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
