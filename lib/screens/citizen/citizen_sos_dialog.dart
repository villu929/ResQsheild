import 'package:flutter/material.dart';

class CitizenSosDialog extends StatefulWidget {
  final bool isHindi;

  const CitizenSosDialog({super.key, this.isHindi = false});

  static Future<void> show(BuildContext context, {bool isHindi = false}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CitizenSosDialog(isHindi: isHindi),
    );
  }

  @override
  State<CitizenSosDialog> createState() => _CitizenSosDialogState();
}

class _CitizenSosDialogState extends State<CitizenSosDialog> {
  String _selectedReason = 'Trapped in Rising Water';
  bool _isTransmitting = false;
  bool _isSent = false;
  final String _sosId = 'SOS-9482';

  final List<Map<String, dynamic>> _reasons = [
    {
      'label': 'Trapped in Rising Water',
      'labelHi': 'बढ़ते पानी में फंसे हुए हैं',
      'icon': Icons.flood_rounded,
      'color': Color(0xFFE92828),
    },
    {
      'label': 'Medical Emergency / Patient',
      'labelHi': 'चिकित्सा आपातकाल / गंभीर मरीज',
      'icon': Icons.medical_services_rounded,
      'color': Color(0xFFE92828),
    },
    {
      'label': 'Elderly / Unable to Evacuate',
      'labelHi': 'बुजुर्ग / चलने में असमर्थ',
      'icon': Icons.accessible_rounded,
      'color': Color(0xFFF39A20),
    },
    {
      'label': 'House Structurally Damaged',
      'labelHi': 'मकान क्षतिग्रस्त / खतरा',
      'icon': Icons.house_siding_rounded,
      'color': Color(0xFFF39A20),
    },
  ];

  Future<void> _transmitSos() async {
    setState(() => _isTransmitting = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _isTransmitting = false;
      _isSent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')} IST';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFBEDCF5),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (!_isSent) ...[
            // Header
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE92828).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.sos_rounded, color: Color(0xFFE92828), size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isHindi ? 'आपातकालीन सहायता अनुरोध' : 'Emergency SOS Dispatch',
                        style: const TextStyle(
                          color: Color(0xFF013973),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        widget.isHindi
                            ? 'एनडीआरएफ एवं स्थानीय बचाव दल को तत्काल अलर्ट'
                            : 'Broadcasts GPS beacon directly to NDRF & State Control',
                        style: const TextStyle(color: Color(0xFF537392), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Live Telemetry Metadata Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F8FD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD6E8F7)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.gps_fixed_rounded, size: 14, color: Color(0xFF007AEB)),
                      SizedBox(width: 6),
                      Text(
                        '23.7957° N, 86.4304° E',
                        style: TextStyle(
                          color: Color(0xFF013973),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF537392)),
                      const SizedBox(width: 6),
                      Text(
                        timeStr,
                        style: const TextStyle(
                          color: Color(0xFF537392),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'SELECT EMERGENCY TYPE:',
              style: TextStyle(
                color: Color(0xFF013973),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 10),

            // Emergency Reason Radios
            ..._reasons.map((r) {
              final isSelected = _selectedReason == r['label'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => setState(() => _selectedReason = r['label'] as String),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFFFEEEE) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFE92828) : const Color(0xFFE5E9EE),
                        width: isSelected ? 1.8 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(r['icon'] as IconData, color: r['color'] as Color, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.isHindi ? (r['labelHi'] as String) : (r['label'] as String),
                            style: TextStyle(
                              color: isSelected ? const Color(0xFFE92828) : const Color(0xFF013973),
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded, color: Color(0xFFE92828), size: 18),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 14),

            // Big Action Button
            ElevatedButton(
              onPressed: _isTransmitting ? null : _transmitSos,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE92828),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
                shadowColor: const Color(0xFFE92828).withValues(alpha: 0.5),
              ),
              child: _isTransmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.emergency_share_rounded, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          widget.isHindi ? 'आपातकालीन संकेत प्रसारित करें' : 'TRANSMIT RESCUE SOS BEACON',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.4),
                        ),
                      ],
                    ),
            ),
          ] else ...[
            // Confirmation Screen
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF8F0),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF15945C)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF15945C), size: 54),
                  const SizedBox(height: 10),
                  const Text(
                    'SOS BEACON ACTIVE',
                    style: TextStyle(
                      color: Color(0xFF15945C),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tracking ID: $_sosId • Priority: CRITICAL',
                    style: const TextStyle(color: Color(0xFF013973), fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'NDRF Tactical Boat Team Alpha (Sector 4) has acknowledged your distress signal.\nEstimated Arrival: 14 - 18 minutes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF0F2642), fontSize: 13, height: 1.4, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.phone_in_talk_rounded, color: Color(0xFF15945C), size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Direct Line: 1070 (Disaster Control Room)',
                          style: TextStyle(color: Color(0xFF013973), fontSize: 12, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF013973),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Back to Dashboard', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ],
      ),
    );
  }
}
