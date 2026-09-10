import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart';

class AuthorityVerificationScreen extends StatefulWidget {
  const AuthorityVerificationScreen({super.key});

  @override
  State<AuthorityVerificationScreen> createState() =>
      _AuthorityVerificationScreenState();
}

class _AuthorityVerificationScreenState
    extends State<AuthorityVerificationScreen> with TickerProviderStateMixin {
  // --------------------------------------------------------------------------
  // FLOW STAGE: 0 = Form, 1 = Aadhaar OTP
  // --------------------------------------------------------------------------
  int _currentStep = 0; // 0: Form, 1: OTP

  // --------------------------------------------------------------------------
  // FORM CONTROLLERS & FOCUS NODES
  // --------------------------------------------------------------------------
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _aadhaarController = TextEditingController();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _aadhaarFocus = FocusNode();

  String _selectedDepartment = 'NDRF Quick Response Team (QRT)';
  final List<String> _departments = [
    'NDRF Quick Response Team (QRT)',
    'SDMA State Emergency Center',
    'District Disaster Management (DDMA)',
    'Central Water Commission (CWC)',
    'State Police Flood Monitoring Cell',
  ];

  // Attached Document file names
  String? _aadhaarPhotoName;
  String? _officerPhotoName;

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
    _aadhaarController.addListener(_formatAadhaar);

    // Rebuild listeners for dynamic border outline & soft light glow
    _nameFocus.addListener(_onFieldUpdate);
    _emailFocus.addListener(_onFieldUpdate);
    _aadhaarFocus.addListener(_onFieldUpdate);

    _nameController.addListener(_onFieldUpdate);
    _emailController.addListener(_onFieldUpdate);

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
    _aadhaarController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _aadhaarFocus.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // AADHAAR FORMATTER: XXXX XXXX XXXX
  // --------------------------------------------------------------------------
  void _formatAadhaar() {
    final raw = _aadhaarController.text.replaceAll(' ', '');
    if (raw.length > 12) {
      _aadhaarController.text = raw.substring(0, 12);
      _aadhaarController.selection = TextSelection.fromPosition(
        TextPosition(offset: _aadhaarController.text.length),
      );
      return;
    }
    final buffer = StringBuffer();
    for (int i = 0; i < raw.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(raw[i]);
    }
    final formatted = buffer.toString();
    if (formatted != _aadhaarController.text) {
      _aadhaarController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  // --------------------------------------------------------------------------
  // OTP TIMER
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

  // --------------------------------------------------------------------------
  // IMAGE PICKER MODAL (CAMERA / GALLERY SIMULATION)
  // --------------------------------------------------------------------------
  void _showImagePickerModal({
    required String title,
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
                      color: const Color(0xFF013973).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Color(0xFF013973),
                      size: 20,
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
                        const Text(
                          'Capture live photo or choose an image from gallery',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                onTap: () {
                  Navigator.pop(ctx);
                  final simulated =
                      '${title.toLowerCase().replaceAll(' ', '_')}_camera.jpg';
                  onSelected(simulated);
                  _showSnack('$title captured via camera ✓');
                },
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF5FC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.photo_camera_rounded,
                    color: Color(0xFF007AEB),
                  ),
                ),
                title: const Text(
                  'Open Camera',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: const Text(
                  'Take instant photo for verification',
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
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: Color(0xFF16A34A),
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
                  'Upload existing document image',
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

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor:
            isError ? const Color(0xFFE11D48) : const Color(0xFF013973),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // STEP 1: CONTINUE TO OTP (NO MANDATORY FILLING REQUIRED)
  // --------------------------------------------------------------------------
  Future<void> _handleContinueToOtp() async {
    // If empty, auto-fill demo fallback values so user can click directly without typing
    if (_nameController.text.trim().isEmpty) {
      _nameController.text = 'Rajesh Kumar Sharma';
    }
    if (_emailController.text.trim().isEmpty) {
      _emailController.text = 'officer.ndrf@gov.in';
    }
    if (_aadhaarController.text.trim().isEmpty) {
      _aadhaarController.text = '5489 7721 8841';
    }
    _aadhaarPhotoName ??= 'aadhaar_card_doc.jpg';
    _officerPhotoName ??= 'officer_verification_photo.jpg';

    setState(() => _isFormSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() {
      _isFormSubmitting = false;
      _currentStep = 1;
    });
    _startTimer();
    _showSnack('Aadhaar OTP sent to linked mobile number');
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted && _otpFocusNodes[0].canRequestFocus) {
        _otpFocusNodes[0].requestFocus();
      }
    });
  }

  // --------------------------------------------------------------------------
  // STEP 2: OTP VERIFICATION & NAVIGATION TO HOMESCREEN
  // --------------------------------------------------------------------------
  Future<void> _handleVerifyOtp() async {
    // If OTP is empty, auto-populate code so user can click directly
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

    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    // Navigate directly to Authority Command Center (HomeScreen)
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
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
          final double textScale = (math.min(w / 390.0, h / 800.0)).clamp(0.70, 1.25);

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. Background Image
              Positioned.fill(
                child: Image.asset(
                  'assets/images/screen_bg_1.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),

              // 2. Main Content
              SafeArea(
                child: Column(
                  children: [
                    // Header Bar with Back Button
                    _buildHeaderBar(scaleW, scaleH, scaleMin, textScale),

                    // Content Area (Form or OTP)
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                          horizontal: (18.0 * scaleW).clamp(14.0, 26.0),
                          vertical: (10.0 * scaleH).clamp(6.0, 16.0),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 320),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(opacity: animation, child: child),
                          child: _currentStep == 0
                              ? _buildAuthorizationForm(
                                  scaleW, scaleH, scaleMin, textScale)
                              : _buildAadhaarOtpSection(
                                  scaleW, scaleH, scaleMin, textScale),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TOP BAR
  // --------------------------------------------------------------------------
  Widget _buildHeaderBar(
    double scaleW,
    double scaleH,
    double scaleMin,
    double textScale,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (16.0 * scaleW).clamp(12.0, 22.0),
        vertical: (8.0 * scaleH).clamp(6.0, 12.0),
      ),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () {
              if (_currentStep == 1) {
                setState(() => _currentStep = 0);
              } else {
                Navigator.pop(context);
              }
            },
            child: Container(
              width: (38.0 * scaleMin).clamp(32.0, 44.0),
              height: (38.0 * scaleMin).clamp(32.0, 44.0),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD6E8F7), width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x10013973),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: (16.0 * scaleMin).clamp(13.0, 19.0),
                color: const Color(0xFF013973),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF013973).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'GOVT OF INDIA • DISASTER AUTHORITY',
                        style: TextStyle(
                          color: const Color(0xFF013973),
                          fontSize: (8.5 * textScale).clamp(7.5, 10.0),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  _currentStep == 0
                      ? 'Authority Authorization'
                      : 'Aadhaar e-KYC Verification',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF013973),
                    fontSize: (16.5 * textScale).clamp(14.0, 19.0),
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          // Govt Emblem / Shield
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD6E8F7)),
            ),
            child: Icon(
              Icons.admin_panel_settings_rounded,
              size: (22.0 * scaleMin).clamp(18.0, 26.0),
              color: const Color(0xFF013973),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // STEP 1: AUTHORIZATION CREDENTIALS FORM
  // --------------------------------------------------------------------------
  Widget _buildAuthorizationForm(
    double scaleW,
    double scaleH,
    double scaleMin,
    double textScale,
  ) {
    return Container(
      key: const ValueKey('auth_form'),
      padding: EdgeInsets.symmetric(
        horizontal: (18.0 * scaleW).clamp(14.0, 24.0),
        vertical: (18.0 * scaleH).clamp(14.0, 24.0),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius:
            BorderRadius.circular((20.0 * scaleMin).clamp(16.0, 24.0)),
        border: Border.all(color: const Color(0xFFE0EEF8), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14013973),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_user_rounded,
                  size: 16,
                  color: Color(0xFF1D4ED8),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Restricted to verified NDRF, SDMA & DDMA authority officials.',
                    style: TextStyle(
                      color: const Color(0xFF1E40AF),
                      fontSize: (11.0 * textScale).clamp(9.5, 12.5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: (16.0 * scaleH).clamp(12.0, 20.0)),

          // 1. Officer Full Name
          _buildFieldLabel('OFFICER FULL NAME', Icons.person_outline_rounded,
              scaleMin, textScale),
          SizedBox(height: (6.0 * scaleH).clamp(4.0, 8.0)),
          _buildTextInput(
            controller: _nameController,
            focusNode: _nameFocus,
            hint: 'e.g. Rajesh Kumar Sharma',
            keyboardType: TextInputType.name,
            icon: Icons.badge_outlined,
            scaleH: scaleH,
            scaleMin: scaleMin,
            textScale: textScale,
          ),

          SizedBox(height: (14.0 * scaleH).clamp(10.0, 18.0)),

          // 2. Department Selection
          _buildFieldLabel('COMMAND UNIT / DEPARTMENT',
              Icons.account_balance_outlined, scaleMin, textScale),
          SizedBox(height: (6.0 * scaleH).clamp(4.0, 8.0)),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular((12.0 * scaleMin).clamp(10.0, 14.0)),
              border: Border.all(
                color: const Color(0xFF007AEB).withValues(alpha: 0.55),
                width: 1.3,
              ),
              boxShadow: [
                // Soft radiating outline glow
                BoxShadow(
                  color: const Color(0xFF007AEB).withValues(alpha: 0.10),
                  blurRadius: 7,
                  spreadRadius: 0.6,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedDepartment,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF013973)),
                style: TextStyle(
                  color: const Color(0xFF0F172A),
                  fontSize: (13.5 * textScale).clamp(11.5, 15.0),
                  fontWeight: FontWeight.w700,
                ),
                items: _departments.map((dept) {
                  return DropdownMenuItem(value: dept, child: Text(dept));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedDepartment = val);
                },
              ),
            ),
          ),

          SizedBox(height: (14.0 * scaleH).clamp(10.0, 18.0)),

          // 3. Official Government Email Address
          _buildFieldLabel('OFFICIAL GOVERNMENT EMAIL',
              Icons.mail_outline_rounded, scaleMin, textScale),
          SizedBox(height: (6.0 * scaleH).clamp(4.0, 8.0)),
          _buildTextInput(
            controller: _emailController,
            focusNode: _emailFocus,
            hint: 'officer.qrt@ndrf.gov.in / @nic.in',
            keyboardType: TextInputType.emailAddress,
            icon: Icons.alternate_email_rounded,
            scaleH: scaleH,
            scaleMin: scaleMin,
            textScale: textScale,
          ),

          SizedBox(height: (14.0 * scaleH).clamp(10.0, 18.0)),

          // 4. Aadhaar Card Number
          _buildFieldLabel('AADHAAR CARD NUMBER',
              Icons.credit_card_rounded, scaleMin, textScale),
          SizedBox(height: (6.0 * scaleH).clamp(4.0, 8.0)),
          _buildTextInput(
            controller: _aadhaarController,
            focusNode: _aadhaarFocus,
            hint: 'XXXX  XXXX  XXXX',
            keyboardType: TextInputType.number,
            icon: Icons.lock_outline_rounded,
            scaleH: scaleH,
            scaleMin: scaleMin,
            textScale: textScale,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(12),
            ],
          ),

          SizedBox(height: (16.0 * scaleH).clamp(12.0, 20.0)),

          // 5. Upload Aadhaar Photo & Officer Verification Photo
          Row(
            children: [
              // Aadhaar Card Photo
              Expanded(
                child: _buildUploadCard(
                  title: 'Aadhaar Photo',
                  subtitle: _aadhaarPhotoName ?? 'Tap to Upload',
                  isUploaded: _aadhaarPhotoName != null,
                  icon: Icons.document_scanner_rounded,
                  color: const Color(0xFF007AEB),
                  onTap: () {
                    _showImagePickerModal(
                      title: 'Aadhaar Card Photo',
                      onSelected: (name) =>
                          setState(() => _aadhaarPhotoName = name),
                    );
                  },
                  scaleMin: scaleMin,
                  textScale: textScale,
                ),
              ),
              const SizedBox(width: 12),
              // Officer Photo
              Expanded(
                child: _buildUploadCard(
                  title: 'Officer Photo',
                  subtitle: _officerPhotoName ?? 'Tap for Selfie/ID',
                  isUploaded: _officerPhotoName != null,
                  icon: Icons.camera_front_rounded,
                  color: const Color(0xFF15945C),
                  onTap: () {
                    _showImagePickerModal(
                      title: 'Officer Photo',
                      onSelected: (name) =>
                          setState(() => _officerPhotoName = name),
                    );
                  },
                  scaleMin: scaleMin,
                  textScale: textScale,
                ),
              ),
            ],
          ),

          SizedBox(height: (22.0 * scaleH).clamp(16.0, 28.0)),

          // Continue Button
          _buildContinueButton(scaleW, scaleH, scaleMin, textScale),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // STEP 2: AADHAAR OTP VERIFICATION SECTION
  // --------------------------------------------------------------------------
  Widget _buildAadhaarOtpSection(
    double scaleW,
    double scaleH,
    double scaleMin,
    double textScale,
  ) {
    final aadhaarRaw = _aadhaarController.text.replaceAll(' ', '');
    final last4 = aadhaarRaw.length >= 4
        ? aadhaarRaw.substring(aadhaarRaw.length - 4)
        : '8841';

    return Container(
      key: const ValueKey('otp_section'),
      padding: EdgeInsets.symmetric(
        horizontal: (20.0 * scaleW).clamp(16.0, 26.0),
        vertical: (24.0 * scaleH).clamp(18.0, 30.0),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius:
            BorderRadius.circular((20.0 * scaleMin).clamp(16.0, 24.0)),
        border: Border.all(color: const Color(0xFFE0EEF8), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14013973),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Aadhaar Shield Icon
          Container(
            width: (60.0 * scaleMin).clamp(50.0, 72.0),
            height: (60.0 * scaleMin).clamp(50.0, 72.0),
            decoration: BoxDecoration(
              color: const Color(0xFF013973).withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF013973), width: 1.5),
            ),
            child: Icon(
              Icons.shield_rounded,
              size: (30.0 * scaleMin).clamp(24.0, 36.0),
              color: const Color(0xFF013973),
            ),
          ),

          SizedBox(height: (14.0 * scaleH).clamp(10.0, 18.0)),

          Text(
            'UIDAI Aadhaar e-KYC',
            style: TextStyle(
              color: const Color(0xFF013973),
              fontSize: (18.5 * textScale).clamp(16.0, 22.0),
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'One-Time Password has been sent to the mobile number registered with Aadhaar (•••• •••• $last4).',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF537392),
              fontSize: (12.0 * textScale).clamp(10.5, 14.0),
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),

          SizedBox(height: (20.0 * scaleH).clamp(16.0, 26.0)),

          // 6 OTP Digit Boxes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_otpLength, (index) {
              return _buildOtpDigitBox(index, scaleMin, textScale);
            }),
          ),

          SizedBox(height: (18.0 * scaleH).clamp(14.0, 22.0)),

          // Resend Timer Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _secondsRemaining > 0
                    ? 'Resend OTP in '
                    : "Didn't receive code? ",
                style: TextStyle(
                  color: const Color(0xFF64748B),
                  fontSize: (12.0 * textScale).clamp(10.5, 13.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (_secondsRemaining > 0)
                Text(
                  '00:${_secondsRemaining.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: const Color(0xFF013973),
                    fontSize: (12.5 * textScale).clamp(11.0, 14.0),
                    fontWeight: FontWeight.w800,
                  ),
                )
              else
                GestureDetector(
                  onTap: () {
                    for (final c in _otpControllers) {
                      c.clear();
                    }
                    _startTimer();
                    _showSnack('New Aadhaar OTP sent to registered number');
                  },
                  child: Text(
                    'Resend Now',
                    style: TextStyle(
                      color: const Color(0xFF007AEB),
                      fontSize: (12.5 * textScale).clamp(11.0, 14.0),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(height: (22.0 * scaleH).clamp(16.0, 28.0)),

          // Verify Button
          _buildVerifyButton(scaleW, scaleH, scaleMin, textScale),

          SizedBox(height: (12.0 * scaleH).clamp(8.0, 16.0)),

          // Change details button
          TextButton(
            onPressed: () => setState(() => _currentStep = 0),
            child: Text(
              'Edit Authorization Details',
              style: TextStyle(
                color: const Color(0xFF537392),
                fontSize: (12.0 * textScale).clamp(10.5, 13.5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // OTP DIGIT BOX WIDGET
  // --------------------------------------------------------------------------
  Widget _buildOtpDigitBox(int index, double scaleMin, double textScale) {
    final boxSize = (44.0 * scaleMin).clamp(38.0, 52.0);
    final bool isFilled = _otpControllers[index].text.isNotEmpty;
    final bool isFocused = _otpFocusNodes[index].hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: boxSize,
      height: boxSize * 1.12,
      transform: Matrix4.translationValues(0, isFocused ? -2.0 : 0.0, 0),
      decoration: BoxDecoration(
        color: isFocused
            ? Colors.white
            : (isFilled ? const Color(0xFFF1F8FE) : const Color(0xFFF8FAFC)),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isFocused
              ? const Color(0xFF007AEB)
              : isFilled
                  ? const Color(0xFF013973)
                  : const Color(0xFFCBD5E1),
          width: isFocused ? 2.0 : 1.2,
        ),
        boxShadow: isFocused
            ? [
                // Soft colored outline glow radiating around the OTP box
                BoxShadow(
                  color: const Color(0xFF007AEB).withValues(alpha: 0.28),
                  blurRadius: 10,
                  spreadRadius: 1.2,
                  offset: const Offset(0, 0),
                ),
                BoxShadow(
                  color: const Color(0xFF007AEB).withValues(alpha: 0.14),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]
            : (isFilled
                ? [
                    BoxShadow(
                      color: const Color(0xFF013973).withValues(alpha: 0.12),
                      blurRadius: 6,
                      spreadRadius: 0.5,
                      offset: const Offset(0, 0),
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: Color(0x04000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ]),
      ),
      child: Center(
        child: TextField(
          controller: _otpControllers[index],
          focusNode: _otpFocusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          style: TextStyle(
            color: const Color(0xFF013973),
            fontSize: (19.0 * textScale).clamp(16.0, 23.0),
            fontWeight: FontWeight.w900,
          ),
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
            isDense: true,
          ),
          onChanged: (val) {
            if (val.isNotEmpty && index < _otpLength - 1) {
              _otpFocusNodes[index + 1].requestFocus();
            } else if (val.isEmpty && index > 0) {
              _otpFocusNodes[index - 1].requestFocus();
            }
            setState(() {});
          },
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // HELPERS: FIELD LABEL, TEXT INPUT, UPLOAD CARD
  // --------------------------------------------------------------------------
  Widget _buildFieldLabel(
    String label,
    IconData icon,
    double scaleMin,
    double textScale,
  ) {
    return Row(
      children: [
        Icon(icon,
            size: (13.0 * scaleMin).clamp(11.0, 15.0),
            color: const Color(0xFF013973)),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF013973),
            fontSize: (10.5 * textScale).clamp(9.0, 12.0),
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required TextInputType keyboardType,
    required IconData icon,
    required double scaleH,
    required double scaleMin,
    required double textScale,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final bool isFocused = focusNode.hasFocus;
    final bool hasText = controller.text.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isFocused ? Colors.white : const Color(0xFFF8FAFC),
        borderRadius:
            BorderRadius.circular((12.0 * scaleMin).clamp(10.0, 14.0)),
        border: Border.all(
          color: isFocused
              ? const Color(0xFF007AEB)
              : (hasText ? const Color(0xFF013973) : const Color(0xFFE2E8F0)),
          width: isFocused ? 1.8 : (hasText ? 1.4 : 1.0),
        ),
        boxShadow: isFocused
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
                    // Subtle light halo when text is typed
                    BoxShadow(
                      color: const Color(0xFF013973).withValues(alpha: 0.10),
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
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: (_) => _onFieldUpdate(),
        style: TextStyle(
          color: const Color(0xFF0F172A),
          fontSize: (14.0 * textScale).clamp(12.0, 16.0),
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          isDense: true,
          prefixIcon: Icon(
            icon,
            size: (18.0 * scaleMin).clamp(15.0, 22.0),
            color: isFocused
                ? const Color(0xFF007AEB)
                : (hasText
                    ? const Color(0xFF013973)
                    : const Color(0xFF64748B)),
          ),
          hintText: hint,
          hintStyle: TextStyle(
            color: const Color(0xFF94A3B8),
            fontSize: (13.0 * textScale).clamp(11.0, 15.0),
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 14,
            vertical: (13.0 * scaleH).clamp(10.0, 16.0),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadCard({
    required String title,
    required String subtitle,
    required bool isUploaded,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required double scaleMin,
    required double textScale,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUploaded
              ? color.withValues(alpha: 0.08)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUploaded ? color : const Color(0xFFE2E8F0),
            width: isUploaded ? 1.8 : 1.0,
          ),
          boxShadow: isUploaded
              ? [
                  // Radiant colored light glow around the card
                  BoxShadow(
                    color: color.withValues(alpha: 0.22),
                    blurRadius: 10,
                    spreadRadius: 1.2,
                    offset: const Offset(0, 0),
                  ),
                  BoxShadow(
                    color: color.withValues(alpha: 0.12),
                    blurRadius: 4,
                    spreadRadius: 0.5,
                    offset: const Offset(0, 1),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isUploaded
                        ? color.withValues(alpha: 0.15)
                        : const Color(0xFFE2E8F0),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isUploaded ? Icons.check_circle_rounded : icon,
                    size: (16.0 * scaleMin).clamp(14.0, 20.0),
                    color: isUploaded ? color : const Color(0xFF64748B),
                  ),
                ),
                const Spacer(),
                if (isUploaded)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'ATTACHED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: const Color(0xFF0F172A),
                fontSize: (12.5 * textScale).clamp(11.0, 14.5),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isUploaded ? color : const Color(0xFF64748B),
                fontSize: (10.5 * textScale).clamp(9.0, 12.0),
                fontWeight: isUploaded ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // PRIMARY BUTTONS
  // --------------------------------------------------------------------------
  Widget _buildContinueButton(
    double scaleW,
    double scaleH,
    double scaleMin,
    double textScale,
  ) {
    return ElevatedButton(
      onPressed: _isFormSubmitting ? null : _handleContinueToOtp,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF013973),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          vertical: (14.0 * scaleH).clamp(11.0, 17.0),
        ),
        elevation: 3,
        shadowColor: const Color(0xFF013973).withValues(alpha: 0.35),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: _isFormSubmitting
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: Colors.white,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Continue to Aadhaar OTP',
                  style: TextStyle(
                    fontSize: (14.5 * textScale).clamp(12.5, 16.5),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
    );
  }

  Widget _buildVerifyButton(
    double scaleW,
    double scaleH,
    double scaleMin,
    double textScale,
  ) {
    return ElevatedButton(
      onPressed: _isOtpVerifying ? null : _handleVerifyOtp,
      style: ElevatedButton.styleFrom(
        backgroundColor: _isOtpSuccess
            ? const Color(0xFF16A34A)
            : const Color(0xFF013973),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          vertical: (14.0 * scaleH).clamp(11.0, 17.0),
        ),
        elevation: 3,
        shadowColor: const Color(0xFF013973).withValues(alpha: 0.35),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: _isOtpVerifying
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: Colors.white,
              ),
            )
          : _isOtpSuccess
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.check_circle_rounded,
                        size: 20, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Access Granted ✓',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Verify & Access Command Center',
                      style: TextStyle(
                        fontSize: (14.0 * textScale).clamp(12.0, 16.0),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.lock_open_rounded, size: 18),
                  ],
                ),
    );
  }
}
