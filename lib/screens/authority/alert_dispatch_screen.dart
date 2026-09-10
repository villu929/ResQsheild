import 'package:flutter/material.dart';

class AlertDispatchScreen extends StatefulWidget {
  final String? preselectedVillage;

  const AlertDispatchScreen({super.key, this.preselectedVillage});

  @override
  State<AlertDispatchScreen> createState() => _AlertDispatchScreenState();
}

class _AlertDispatchScreenState extends State<AlertDispatchScreen> {
  // Target Selection mode: 'single', 'multiple', 'wholeDistrict'
  String _targetMode = 'multiple';

  final List<String> _availableVillages = [
    'Aluva Riverside',
    'Paravur Lowlands',
    'Varapuzha Bridge',
    'Chalakudy North',
    'Chalakudy West',
    'Thodupuzha Riverbank',
    'Perumbavoor East',
  ];

  late Set<String> _selectedVillages;

  // Channels
  bool _chSms = true;
  bool _chCellBroadcast = true;
  bool _chPush = true;
  bool _chSiren = false;

  // Selected Template
  String _selectedTemplate = 'EVACUATE NOW';
  late TextEditingController _messageController;

  final Map<String, String> _templates = {
    'EVACUATE NOW':
        'EMERGENCY FLOOD EVACUATION: Water levels have exceeded danger threshold. Inundation expected within 1-2 hours. Move immediately to designated high-ground relief camps via NH-32 bypass.',
    'MONITOR SITUATION':
        'FLOOD ADVISORY - LEVEL 2: Damodar & Periyar River gauges are rising rapidly due to heavy upstream rainfall. Keep emergency survival kits ready and monitor local SDMA announcements.',
    'ALL CLEAR':
        'ALL CLEAR NOTICE: River water has receded below the warning threshold. Flood warning withdrawn. Please follow official instructions before returning to low-lying homes.',
  };

  @override
  void initState() {
    super.initState();
    if (widget.preselectedVillage != null) {
      _selectedVillages = {widget.preselectedVillage!};
      _targetMode = 'single';
    } else {
      _selectedVillages = {'Aluva Riverside', 'Paravur Lowlands'};
    }
    _messageController = TextEditingController(text: _templates['EVACUATE NOW']);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  int get _estimatedReach {
    if (_targetMode == 'wholeDistrict') {
      return 148500; // whole district
    }
    int total = 0;
    for (final v in _selectedVillages) {
      total += (v.contains('Aluva') ? 16400 : v.contains('Paravur') ? 22100 : 18000);
    }
    return total == 0 ? 15000 : total;
  }

  void _showConfirmationDialog() {
    if (_selectedVillages.isEmpty && _targetMode != 'wholeDistrict') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one village or choose Whole District!')),
      );
      return;
    }
    if (!_chSms && !_chCellBroadcast && !_chPush && !_chSiren) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one broadcast channel!')),
      );
      return;
    }

    final channels = [
      if (_chCellBroadcast) 'Govt Cell Broadcast (Tier 1)',
      if (_chSms) 'SMS Carrier Broadcast',
      if (_chPush) 'ResQShield App Push',
      if (_chSiren) 'IoT Physical River Sirens (3 Units)',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 26),
            SizedBox(width: 8),
            Text('Confirm Alert Dispatch', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'You are about to transmit a high-priority emergency broadcast:',
                style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 12),
              _reviewRow('Target Mode:', _targetMode.toUpperCase()),
              _reviewRow(
                'Recipients:',
                _targetMode == 'wholeDistrict'
                    ? 'Entire Ernakulam District'
                    : _selectedVillages.join(', '),
              ),
              _reviewRow(
                'Estimated Reach:',
                '~${_estimatedReach.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} Citizens',
              ),
              _reviewRow('Active Channels:', channels.join('\n• ')),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('MESSAGE PAYLOAD:', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFFDC2626))),
                    const SizedBox(height: 4),
                    Text(
                      _messageController.text,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF991B1B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel / Edit'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _executeDispatch();
            },
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('AUTHORIZE & TRANSMIT'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewRow(String title, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
          ),
          Expanded(
            child: Text(val, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          ),
        ],
      ),
    );
  }

  void _executeDispatch() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(height: 10),
            CircularProgressIndicator(color: Color(0xFFDC2626)),
            SizedBox(height: 16),
            Text(
              'Transmitting Multi-Channel Emergency Broadcast...',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
            SizedBox(height: 6),
            Text(
              'Synchronizing with Cell Broadcast Center (CBC) & Physical River Sirens...',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('EMERGENCY ALERT DISPATCHED SUCCESSFULLY! Logged in Coordination Trail.'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF16A34A),
          duration: const Duration(seconds: 4),
        ),
      );

      Navigator.pop(context); // Return to command center
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF013973)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'ALERT DISPATCH PANEL',
              style: TextStyle(
                color: Color(0xFF013973),
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              'NDRF & SDMA Multi-Channel Broadcast Console',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // STEP 1: TARGET SELECTION
            _sectionHeader('1. SELECT TARGET RECIPIENTS', Icons.place_rounded),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _targetChip('Single Village', 'single'),
                      const SizedBox(width: 8),
                      _targetChip('Multi Village', 'multiple'),
                      const SizedBox(width: 8),
                      _targetChip('Whole District', 'wholeDistrict'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_targetMode != 'wholeDistrict') ...[
                    const Text(
                      'Choose Target Villages:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _availableVillages.map((v) {
                        final isSel = _selectedVillages.contains(v);
                        return FilterChip(
                          label: Text(v, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.w800 : FontWeight.w500)),
                          selected: isSel,
                          selectedColor: const Color(0xFFE0F2FE),
                          checkmarkColor: const Color(0xFF0284C7),
                          onSelected: (selected) {
                            setState(() {
                              if (_targetMode == 'single') {
                                _selectedVillages = {v};
                              } else {
                                if (selected) {
                                  _selectedVillages.add(v);
                                } else {
                                  _selectedVillages.remove(v);
                                }
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.public_rounded, color: Color(0xFF0284C7), size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'District-wide broadcast will reach all active SIMs and connected citizens in the jurisdiction.',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Divider(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.people_alt_rounded, size: 16, color: Color(0xFF0284C7)),
                      const SizedBox(width: 6),
                      Text(
                        'Estimated Reach: ~${_estimatedReach.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} Citizens',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0284C7)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // STEP 2: CHANNELS SELECTION
            _sectionHeader('2. BROADCAST CHANNELS', Icons.cell_tower_rounded),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _channelCheckbox(
                    title: 'Cell Broadcast (CBC)',
                    subtitle: 'Direct hardware emergency buzzer on all mobile phones',
                    value: _chCellBroadcast,
                    icon: Icons.cell_tower_rounded,
                    color: const Color(0xFFDC2626),
                    onChanged: (val) => setState(() => _chCellBroadcast = val!),
                  ),
                  const Divider(height: 12),
                  _channelCheckbox(
                    title: 'App Push Notification',
                    subtitle: 'ResQShield critical push alert with evacuation route map',
                    value: _chPush,
                    icon: Icons.notifications_active_rounded,
                    color: const Color(0xFF0284C7),
                    onChanged: (val) => setState(() => _chPush = val!),
                  ),
                  const Divider(height: 12),
                  _channelCheckbox(
                    title: 'SMS Carrier Push',
                    subtitle: 'Telecom bulk SMS to local towers without data connection',
                    value: _chSms,
                    icon: Icons.sms_rounded,
                    color: const Color(0xFF16A34A),
                    onChanged: (val) => setState(() => _chSms = val!),
                  ),
                  const Divider(height: 12),
                  _channelCheckbox(
                    title: 'Physical IoT River Sirens',
                    subtitle: 'Trigger acoustic warning sirens installed at riverbank towers',
                    value: _chSiren,
                    icon: Icons.campaign_rounded,
                    color: const Color(0xFFD97706),
                    onChanged: (val) => setState(() => _chSiren = val!),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // STEP 3: MESSAGE TEMPLATES & CONTENT
            _sectionHeader('3. ALERT MESSAGE & TEMPLATE', Icons.edit_note_rounded),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pre-Written Emergency Templates:',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _templates.keys.map((t) {
                      final isSel = _selectedTemplate == t;
                      return ChoiceChip(
                        label: Text(t, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.w900 : FontWeight.w600)),
                        selected: isSel,
                        selectedColor: t == 'EVACUATE NOW'
                            ? const Color(0xFFFEE2E2)
                            : t == 'MONITOR SITUATION'
                                ? const Color(0xFFFFF7ED)
                                : const Color(0xFFDCFCE7),
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _selectedTemplate = t;
                              _messageController.text = _templates[t]!;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _messageController,
                    maxLines: 4,
                    maxLength: 240,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'Type or customize emergency broadcast message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // DISPATCH BUTTON
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _showConfirmationDialog,
                icon: const Icon(Icons.emergency_share_rounded, size: 20),
                label: const Text(
                  'REVIEW & TRANSMIT ALERT',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF007AEB)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF013973)),
        ),
      ],
    );
  }

  Widget _targetChip(String label, String mode) {
    final isSelected = _targetMode == mode;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500)),
      selected: isSelected,
      selectedColor: const Color(0xFFE8F3FD),
      onSelected: (val) {
        if (val) {
          setState(() {
            _targetMode = mode;
            if (mode == 'single' && _selectedVillages.length > 1) {
              _selectedVillages = {_selectedVillages.first};
            }
          });
        }
      },
    );
  }

  Widget _channelCheckbox({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required Color color,
    required ValueChanged<bool?> onChanged,
  }) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      activeColor: color,
      contentPadding: EdgeInsets.zero,
      dense: true,
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
    );
  }
}
