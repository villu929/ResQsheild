import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'citizen_permission_screen.dart';

class CitizenLoginScreen extends StatefulWidget {
  const CitizenLoginScreen({super.key});

  @override
  State<CitizenLoginScreen> createState() => _CitizenLoginScreenState();
}

class _CitizenLoginScreenState extends State<CitizenLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _otpFocusNode = FocusNode();

  bool _otpSent = false;
  bool _isLoading = false;
  int _resendTimer = 30;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    _phoneFocusNode.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _resendTimer = 30;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() => _resendTimer--);
      } else {
        timer.cancel();
      }
    });
  }

  void _showMessage(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isError ? const Color(0xFFE92828) : const Color(0xFF013973),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleSendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 10) {
      _showMessage('Please enter a valid 10-digit mobile number', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _otpSent = true;
    });
    _startCountdown();
    _otpFocusNode.requestFocus();
    _showMessage('OTP sent to +91 $phone (Simulated Code: 1234)');
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length < 4) {
      _showMessage('Please enter the 4-digit OTP', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    setState(() => _isLoading = false);

    // Smooth transition to Mandatory GPS Permission Screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const CitizenPermissionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9F4FB),
      body: Stack(
        children: [
          // Background scenic image matching ResQShield brand
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_bg.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: const Color(0xFFE9F4FB).withValues(alpha: 0.50),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Navigation Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Color(0xFF013973),
                          size: 20,
                        ),
                        onPressed: () => Navigator.maybePop(context),
                        tooltip: 'Back to Role Selection',
                      ),
                      const Spacer(),
                      // Brand Tag
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/app_logo.png',
                            width: 30,
                            height: 30,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 8),
                          RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Res',
                                  style: TextStyle(
                                    color: Color(0xFF013973),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Q',
                                  style: TextStyle(
                                    color: Color(0xFF00FF00),
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Shield',
                                  style: TextStyle(
                                    color: Color(0xFF013973),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                // Main Scrollable Card
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 10),

                        // Citizen Portal Title
                        const Center(
                          child: Text(
                            'Citizen Emergency Portal',
                            style: TextStyle(
                              color: Color(0xFF013973),
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Center(
                          child: Text(
                            'Fast, one-step login to access safe routes, flood risk warnings, and nearest shelters.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF537392),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 1.35,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // White Card Container
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFD6E8F7)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF013973).withValues(alpha: 0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Phone Number Label
                              const Text(
                                'MOBILE NUMBER',
                                style: TextStyle(
                                  color: Color(0xFF013973),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Mobile Input with +91 Prefix
                              TextField(
                                controller: _phoneController,
                                focusNode: _phoneFocusNode,
                                keyboardType: TextInputType.phone,
                                maxLength: 10,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                enabled: !_otpSent,
                                decoration: InputDecoration(
                                  counterText: '',
                                  prefixIcon: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                    child: const Text(
                                      '+91',
                                      style: TextStyle(
                                        color: Color(0xFF013973),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  hintText: 'Enter 10-digit mobile number',
                                  hintStyle: const TextStyle(color: Color(0xFF8CA5BE), fontSize: 14),
                                  filled: true,
                                  fillColor: _otpSent ? const Color(0xFFF0F4F8) : const Color(0xFFF3F8FD),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFD6E8F7)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFD6E8F7)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF007AEB), width: 1.8),
                                  ),
                                  suffixIcon: _otpSent
                                      ? IconButton(
                                          icon: const Icon(Icons.edit_rounded, color: Color(0xFF007AEB), size: 18),
                                          onPressed: () {
                                            setState(() {
                                              _otpSent = false;
                                              _otpController.clear();
                                            });
                                            _phoneFocusNode.requestFocus();
                                          },
                                        )
                                      : null,
                                ),
                              ),

                              const SizedBox(height: 16),

                              // If OTP not yet requested -> Show "Send OTP" button
                              if (!_otpSent) ...[
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _handleSendOtp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF007AEB),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Text(
                                          'Get OTP via SMS',
                                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                                        ),
                                ),
                              ],

                              // If OTP sent -> Show OTP Input & Verify button
                              if (_otpSent) ...[
                                const Text(
                                  'ENTER 4-DIGIT OTP',
                                  style: TextStyle(
                                    color: Color(0xFF013973),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                TextField(
                                  controller: _otpController,
                                  focusNode: _otpFocusNode,
                                  keyboardType: TextInputType.number,
                                  maxLength: 4,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    letterSpacing: 12,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF013973),
                                  ),
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  decoration: InputDecoration(
                                    counterText: '',
                                    hintText: '• • • •',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFFBEDCF5),
                                      letterSpacing: 8,
                                      fontSize: 22,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF3F8FD),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFD6E8F7)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFF007AEB), width: 1.8),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 10),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _resendTimer > 0
                                          ? 'Resend OTP in ${_resendTimer}s'
                                          : 'Didn\'t receive code?',
                                      style: const TextStyle(color: Color(0xFF537392), fontSize: 12),
                                    ),
                                    if (_resendTimer == 0)
                                      TextButton(
                                        onPressed: _handleSendOtp,
                                        child: const Text(
                                          'Resend Now',
                                          style: TextStyle(
                                            color: Color(0xFF007AEB),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                ElevatedButton(
                                  onPressed: _isLoading ? null : _handleVerifyOtp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF15945C),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Verify & Continue',
                                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                                            ),
                                            SizedBox(width: 8),
                                            Icon(Icons.arrow_forward_rounded, size: 18),
                                          ],
                                        ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Fast Testing Quick-Fill Helper (Student / Hackathon Demo Friendly)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF007AEB).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF007AEB).withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF007AEB)),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Demo Mode: Enter any 10-digit number & code (1234) to test.',
                                  style: TextStyle(color: Color(0xFF013973), fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _phoneController.text = '9876543210';
                                    _otpController.text = '1234';
                                    _otpSent = true;
                                  });
                                },
                                child: const Text(
                                  'Auto-Fill',
                                  style: TextStyle(
                                    color: Color(0xFF007AEB),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
