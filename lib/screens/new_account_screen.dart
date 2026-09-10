import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'otp_screen.dart';

class NewAccountScreen extends StatefulWidget {
  const NewAccountScreen({super.key});

  @override
  State<NewAccountScreen> createState() => _NewAccountScreenState();
}

class _NewAccountScreenState extends State<NewAccountScreen> {
  // --------------------------------------------------------------------------
  // FORM CONTROLLERS (COMPULSORY)
  // --------------------------------------------------------------------------
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _addressFocus = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;

  // --------------------------------------------------------------------------
  // OPTIONAL / ADDITIONAL INFO (GOVERNMENT IDs)
  // --------------------------------------------------------------------------
  bool _isAdditionalInfoExpanded = false;

  // Attached document states (null = not uploaded yet)
  String? _aadhaarFileName;
  String? _panFileName;
  String? _rationFileName;

  // Segmented auth tab selection: 0 = Sign In, 1 = New Account
  int _selectedAuthTab = 1;
  bool _isSwitchingTab = false;

  Future<void> _handleAuthTabTap(int index) async {
    if (_selectedAuthTab == index || _isSwitchingTab) return;
    setState(() {
      _selectedAuthTab = index;
      _isSwitchingTab = true;
    });

    if (index == 0) {
      // Slide back to Sign In smoothly before popping
      await Future.delayed(const Duration(milliseconds: 240));
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onFieldUpdate);
    _nameController.addListener(_onFieldUpdate);
    _emailController.addListener(_onFieldUpdate);
    _passwordController.addListener(_onFieldUpdate);
    _addressController.addListener(_onFieldUpdate);

    _phoneFocus.addListener(_onFieldUpdate);
    _nameFocus.addListener(_onFieldUpdate);
    _emailFocus.addListener(_onFieldUpdate);
    _passwordFocus.addListener(_onFieldUpdate);
    _addressFocus.addListener(_onFieldUpdate);
  }

  void _onFieldUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    _phoneFocus.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _addressFocus.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // PHOTO UPLOAD MODAL (CAMERA OR GALLERY)
  // --------------------------------------------------------------------------
  void _showDocumentPickerModal({
    required String documentTitle,
    required void Function(String fileName) onFileSelected,
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
              color: Color(0x1A013973),
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Modal Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AEB).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.document_scanner_rounded,
                      color: Color(0xFF007AEB),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upload $documentTitle',
                          style: const TextStyle(
                            color: Color(0xFF013973),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'Select camera or choose an image from device gallery',
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

              const SizedBox(height: 18),

              // Camera Option
              ListTile(
                onTap: () {
                  Navigator.pop(ctx);
                  final simulatedName =
                      '${documentTitle.toLowerCase().replaceAll(' ', '_')}_photo.jpg';
                  onFileSelected(simulatedName);
                  _showSnack('$documentTitle captured via camera ✓');
                },
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF5FC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Color(0xFF007AEB),
                    size: 22,
                  ),
                ),
                title: const Text(
                  'Take Photo by Camera',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: const Text(
                  'Snap a clear picture of physical document',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFF94A3B8),
                ),
                contentPadding: EdgeInsets.zero,
              ),

              const Divider(height: 16, color: Color(0xFFF1F5F9)),

              // Gallery Option
              ListTile(
                onTap: () {
                  Navigator.pop(ctx);
                  final simulatedName =
                      '${documentTitle.toLowerCase().replaceAll(' ', '_')}_gallery.jpg';
                  onFileSelected(simulatedName);
                  _showSnack('$documentTitle selected from gallery ✓');
                },
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF8F0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: Color(0xFF15945C),
                    size: 22,
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
                  'Select JPG, PNG or PDF document file',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFF94A3B8),
                ),
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF013973),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // CREATE ACCOUNT SUBMISSION
  // --------------------------------------------------------------------------
  void _handleCreateAccount() async {
    final phone = _phoneController.text.trim();
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final address = _addressController.text.trim();

    if (phone.length != 10) {
      _showSnack('Please enter a valid 10-digit mobile number');
      _phoneFocus.requestFocus();
      return;
    }

    if (name.isEmpty) {
      _showSnack('Please enter your full name');
      _nameFocus.requestFocus();
      return;
    }

    if (email.isEmpty || !email.contains('@')) {
      _showSnack('Please enter a valid email address');
      _emailFocus.requestFocus();
      return;
    }

    if (password.length < 4) {
      _showSnack('Password must be at least 4 characters');
      _passwordFocus.requestFocus();
      return;
    }

    if (address.isEmpty) {
      _showSnack('Please enter your residential address or village/ward');
      _addressFocus.requestFocus();
      return;
    }

    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    setState(() => _isLoading = false);

    _showSnack('Account created successfully! Verifying phone...');

    // Navigate to OTP Screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WaterWavesScreen()),
    );
  }

  // --------------------------------------------------------------------------
  // MAIN BUILD
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final clampedTextScaler = mediaQuery.textScaler.clamp(
      minScaleFactor: 0.85,
      maxScaleFactor: 1.15,
    );

    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: clampedTextScaler),
      child: Scaffold(
        backgroundColor: const Color(0xFFE9F4FB),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Background image (Same background as requested)
            Positioned.fill(
              child: Image.asset(
                'assets/images/screen_bg_1.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),

            // 2. High readability soft tint
            Positioned.fill(
              child: Container(
                color: const Color(0xFFE9F4FB).withValues(alpha: 0.40),
              ),
            ),

            // 3. Scrollable Content
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double w = constraints.maxWidth;
                  final double maxCardWidth = w > 650 ? 560 : w - 32;

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxCardWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Top Navigation Bar ──
                            _buildTopBar(context),

                            const SizedBox(height: 6),

                            // ── Big Centered Logo & ResQShield Brand Header ──
                            _buildCenteredBrandHeader(),

                            const SizedBox(height: 14),

                            // ── Main Card (Segmented Switch + Registration Form) ──
                            _buildNewAccountCard(),

                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TOP BAR
  // --------------------------------------------------------------------------
  Widget _buildTopBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
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
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD6E6F2)),
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
            children: const [
              Text('🇮🇳', style: TextStyle(fontSize: 12)),
              SizedBox(width: 4),
              Text(
                'EN',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 2),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF475569),
                size: 15,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // CENTERED BRAND HEADER
  // --------------------------------------------------------------------------
  Widget _buildCenteredBrandHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF013973).withValues(alpha: 0.14),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/app_logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Icon(
              Icons.shield_rounded,
              size: 50,
              color: Color(0xFF013973),
            ),
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Res',
                style: TextStyle(
                  color: Color(0xFF013973),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              TextSpan(
                text: 'Q',
                style: TextStyle(
                  color: Color(0xFF00FF00),
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                  shadows: [
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
                  color: Color(0xFF013973),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'Safer Routes • Real-Time Alert • Stronger Communities',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF537392),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // NEW ACCOUNT CARD
  // --------------------------------------------------------------------------
  Widget _buildNewAccountCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── SEGMENTED AUTH TOGGLE PILL: [ Sign In ] [ New Account ] ──
          _buildAuthTogglePill(),

          const SizedBox(height: 14),

          // ── Heading ──
          const Text(
            'Create Citizen Profile',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Mandatory details for rapid disaster aid & emergency broadcast.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 11.5),
          ),

          const SizedBox(height: 14),

          // ── 1. PHONE NUMBER (MATCHING REFERENCE UI: +91 | 10 digit number) ──
          _buildFieldHeader('Phone number', '${_phoneController.text.length}/10'),
          const SizedBox(height: 5),
          _buildPhoneField(),

          const SizedBox(height: 12),

          // ── 2. FULL NAME ──
          _buildFieldHeader('Full Name', 'Compulsory'),
          const SizedBox(height: 5),
          _buildStandardField(
            controller: _nameController,
            focusNode: _nameFocus,
            hint: 'Enter your legal full name',
            icon: Icons.person_outline_rounded,
          ),

          const SizedBox(height: 12),

          // ── 3. EMAIL ADDRESS ──
          _buildFieldHeader('Email Address', 'Compulsory'),
          const SizedBox(height: 5),
          _buildStandardField(
            controller: _emailController,
            focusNode: _emailFocus,
            hint: 'e.g. resident@gmail.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 12),

          // ── 4. PASSWORD ──
          _buildFieldHeader('Account Password', 'Compulsory'),
          const SizedBox(height: 5),
          _buildPasswordField(),

          const SizedBox(height: 12),

          // ── 5. RESIDENTIAL ADDRESS / WARD ──
          _buildFieldHeader('Residential Address / Village / Ward', 'Compulsory'),
          const SizedBox(height: 5),
          _buildStandardField(
            controller: _addressController,
            focusNode: _addressFocus,
            hint: 'House/Ward No., Village/Town, District',
            icon: Icons.location_on_outlined,
            maxLines: 2,
          ),

          const SizedBox(height: 16),

          // ── 6. ADDITIONAL INFO ACCORDION (OPTIONAL - OPENS ON TAP) ──
          _buildAdditionalInfoAccordion(),

          const SizedBox(height: 18),

          // ── CREATE ACCOUNT ACTION BUTTON ──
          ElevatedButton(
            onPressed: _isLoading ? null : _handleCreateAccount,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007AEB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 3,
              shadowColor: const Color(0xFF007AEB).withValues(alpha: 0.35),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
          ),

          const SizedBox(height: 10),

          // Government Portal Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.verified_user_rounded, size: 13, color: Color(0xFF007AEB)),
              SizedBox(width: 5),
              Text(
                'Data encrypted & stored on Secure Cloud Infrastructure',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // SEGMENTED AUTH TOGGLE PILL
  // --------------------------------------------------------------------------
  Widget _buildAuthTogglePill() {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(3.5),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF3FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD6E6F2)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double tabWidth = (constraints.maxWidth - 4) / 2;
          return Stack(
            children: [
              // Sliding active blue pill indicator
              AnimatedPositioned(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeInOutCubic,
                left: _selectedAuthTab == 0 ? 0 : tabWidth + 4,
                width: tabWidth,
                top: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF013973),
                    borderRadius: BorderRadius.circular(9),
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
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeInOut,
                          style: TextStyle(
                            color: _selectedAuthTab == 0
                                ? Colors.white
                                : const Color(0xFF537392),
                            fontSize: 13,
                            fontWeight: _selectedAuthTab == 0
                                ? FontWeight.w800
                                : FontWeight.w700,
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
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeInOut,
                          style: TextStyle(
                            color: _selectedAuthTab == 1
                                ? Colors.white
                                : const Color(0xFF537392),
                            fontSize: 13,
                            fontWeight: _selectedAuthTab == 1
                                ? FontWeight.w800
                                : FontWeight.w700,
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
  // FIELD HEADER ROW (Label on left, counter or note on right)
  // --------------------------------------------------------------------------
  Widget _buildFieldHeader(String label, String note) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          note,
          style: TextStyle(
            color: note == 'Compulsory'
                ? const Color(0xFFE92828)
                : const Color(0xFF64748B),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // PHONE FIELD (+91 | 10 digit number)
  // --------------------------------------------------------------------------
  Widget _buildPhoneField() {
    final bool isFocused = _phoneFocus.hasFocus;
    final bool hasText = _phoneController.text.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isFocused ? Colors.white : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFocused
              ? const Color(0xFF007AEB)
              : (hasText ? const Color(0xFF007AEB).withValues(alpha: 0.7) : const Color(0xFFE2E8F0)),
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
      child: Row(
        children: [
          // Country prefix pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius: BorderRadius.horizontal(left: Radius.circular(11)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.phone_android_rounded, size: 16, color: Color(0xFF013973)),
                SizedBox(width: 4),
                Text(
                  '+91',
                  style: TextStyle(
                    color: Color(0xFF013973),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 26, color: const Color(0xFFCBD5E1)),
          Expanded(
            child: TextField(
              controller: _phoneController,
              focusNode: _phoneFocus,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              onChanged: (_) => _onFieldUpdate(),
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
              decoration: const InputDecoration(
                isDense: true,
                hintText: '10 digit number',
                hintStyle: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.2,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // STANDARD INPUT FIELD
  // --------------------------------------------------------------------------
  Widget _buildStandardField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    final bool isFocused = focusNode.hasFocus;
    final bool hasText = controller.text.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isFocused ? Colors.white : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFocused
              ? const Color(0xFF007AEB)
              : (hasText ? const Color(0xFF007AEB).withValues(alpha: 0.7) : const Color(0xFFE2E8F0)),
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
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        maxLines: maxLines,
        onChanged: (_) => _onFieldUpdate(),
        style: const TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 12.5,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            icon,
            color: isFocused
                ? const Color(0xFF007AEB)
                : (hasText ? const Color(0xFF013973) : const Color(0xFF64748B)),
            size: 18,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // PASSWORD FIELD
  // --------------------------------------------------------------------------
  Widget _buildPasswordField() {
    final bool isFocused = _passwordFocus.hasFocus;
    final bool hasText = _passwordController.text.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isFocused ? Colors.white : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFocused
              ? const Color(0xFF007AEB)
              : (hasText ? const Color(0xFF007AEB).withValues(alpha: 0.7) : const Color(0xFFE2E8F0)),
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
        focusNode: _passwordFocus,
        obscureText: _obscurePassword,
        onChanged: (_) => _onFieldUpdate(),
        style: const TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Create secure password',
          hintStyle: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 12.5,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            Icons.lock_outline_rounded,
            color: isFocused
                ? const Color(0xFF007AEB)
                : (hasText ? const Color(0xFF013973) : const Color(0xFF64748B)),
            size: 18,
          ),
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _obscurePassword = !_obscurePassword),
            child: Icon(
              _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: const Color(0xFF64748B),
              size: 18,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // ADDITIONAL INFO ACCORDION (OPTIONAL - OPENS ON TAP)
  // --------------------------------------------------------------------------
  Widget _buildAdditionalInfoAccordion() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F9FD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isAdditionalInfoExpanded
              ? const Color(0xFF007AEB).withValues(alpha: 0.4)
              : const Color(0xFFD6E8F7),
        ),
      ),
      child: Column(
        children: [
          // Accordion Header Bar
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              setState(() {
                _isAdditionalInfoExpanded = !_isAdditionalInfoExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AEB).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.folder_shared_rounded,
                      color: Color(0xFF007AEB),
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Additional Info & ID Documents',
                          style: TextStyle(
                            color: Color(0xFF013973),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Aadhaar, PAN & Ration Card (Optional)',
                          style: TextStyle(
                            color: Color(0xFF537392),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Optional',
                      style: TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _isAdditionalInfoExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF013973),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Collapsible Details
          if (_isAdditionalInfoExpanded) ...[
            const Divider(height: 1, color: Color(0xFFD6E8F7)),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Tap any document to snap photo by camera or select from gallery:',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 1. Aadhaar Card Uploader
                  _buildDocumentUploadTile(
                    title: 'Aadhaar Card',
                    subtitle: 'Citizen identification & verification',
                    icon: Icons.badge_outlined,
                    fileName: _aadhaarFileName,
                    onTap: () => _showDocumentPickerModal(
                      documentTitle: 'Aadhaar Card',
                      onFileSelected: (name) => setState(() => _aadhaarFileName = name),
                    ),
                    onClear: () => setState(() => _aadhaarFileName = null),
                  ),

                  const SizedBox(height: 10),

                  // 2. PAN Card Uploader
                  _buildDocumentUploadTile(
                    title: 'PAN Card',
                    subtitle: 'Income tax & emergency claim audit',
                    icon: Icons.credit_card_rounded,
                    fileName: _panFileName,
                    onTap: () => _showDocumentPickerModal(
                      documentTitle: 'PAN Card',
                      onFileSelected: (name) => setState(() => _panFileName = name),
                    ),
                    onClear: () => setState(() => _panFileName = null),
                  ),

                  const SizedBox(height: 10),

                  // 3. Ration Card Uploader
                  _buildDocumentUploadTile(
                    title: 'Ration Card',
                    subtitle: 'Relief supply quota & food packet allocation',
                    icon: Icons.receipt_long_rounded,
                    fileName: _rationFileName,
                    onTap: () => _showDocumentPickerModal(
                      documentTitle: 'Ration Card',
                      onFileSelected: (name) => setState(() => _rationFileName = name),
                    ),
                    onClear: () => setState(() => _rationFileName = null),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // DOCUMENT UPLOAD TILE (Shows upload trigger or green attached state)
  // --------------------------------------------------------------------------
  Widget _buildDocumentUploadTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required String? fileName,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    final bool isUploaded = fileName != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isUploaded ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUploaded ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
          width: isUploaded ? 1.5 : 1.0,
        ),
        boxShadow: isUploaded
            ? [
                // Soft radiating green light glow when document is attached
                BoxShadow(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.22),
                  blurRadius: 10,
                  spreadRadius: 1.2,
                  offset: const Offset(0, 0),
                ),
                BoxShadow(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.12),
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
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isUploaded
                  ? const Color(0xFF22C55E).withValues(alpha: 0.12)
                  : const Color(0xFF007AEB).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isUploaded ? Icons.check_circle_rounded : icon,
              color: isUploaded ? const Color(0xFF16A34A) : const Color(0xFF007AEB),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  isUploaded ? fileName : subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isUploaded ? const Color(0xFF15803D) : const Color(0xFF64748B),
                    fontSize: 10.5,
                    fontWeight: isUploaded ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isUploaded)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
              onPressed: onClear,
              tooltip: 'Remove',
            )
          else
            ElevatedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.camera_alt_outlined, size: 14),
              label: const Text('Upload', style: TextStyle(fontSize: 11)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AEB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
