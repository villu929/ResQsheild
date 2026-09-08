import 'package:flutter/material.dart';

class CitizenHazardReportView extends StatefulWidget {
  final bool isHindi;

  const CitizenHazardReportView({super.key, this.isHindi = false});

  @override
  State<CitizenHazardReportView> createState() => _CitizenHazardReportViewState();
}

class _CitizenHazardReportViewState extends State<CitizenHazardReportView> {
  String _selectedCategory = 'Flooded Road';
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  bool _hasPhoto = false;
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _categories = [
    {'title': 'Flooded Road', 'icon': Icons.water_rounded, 'color': Color(0xFF007AEB)},
    {'title': 'Bridge Damage', 'icon': Icons.warning_amber_rounded, 'color': Color(0xFFE92828)},
    {'title': 'Landslide / Mudflow', 'icon': Icons.landslide_rounded, 'color': Color(0xFFF39A20)},
    {'title': 'Fallen Electric Pole', 'icon': Icons.bolt_rounded, 'color': Color(0xFF7351D8)},
  ];

  @override
  void dispose() {
    _descController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF013973),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _submitReport() async {
    if (_landmarkController.text.trim().isEmpty) {
      _showMessage('Please enter the landmark or location details');
      return;
    }

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 750));
    if (!mounted) return;

    setState(() => _isSubmitting = false);
    _showMessage('Hazard reported successfully. Tagged as UNVERIFIED community report.');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9F4FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF013973)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isHindi ? 'खतरे की रिपोर्ट करें' : 'Report Hazard',
          style: const TextStyle(
            color: Color(0xFF013973),
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // UNVERIFIED Warning Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5E7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF39A20)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_rounded, color: Color(0xFFF39A20), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'All citizen hazard reports are initially marked "UNVERIFIED" until inspected and verified by on-duty Field Responders.',
                      style: TextStyle(
                        color: Color(0xFF945200),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Category Selection
            const Text(
              'HAZARD CATEGORY',
              style: TextStyle(
                color: Color(0xFF013973),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((c) {
                final isSelected = _selectedCategory == c['title'];
                final color = c['color'] as Color;

                return ChoiceChip(
                  avatar: Icon(c['icon'] as IconData, size: 16, color: isSelected ? Colors.white : color),
                  label: Text(c['title'] as String),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedCategory = c['title'] as String),
                  selectedColor: const Color(0xFF013973),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF013973),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF013973) : const Color(0xFFD6E8F7),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Landmark & Details Form
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD6E8F7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Landmark & Road Name *',
                    style: TextStyle(color: Color(0xFF013973), fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _landmarkController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Near Bokaro Culvert #3 on Bypass Road',
                      hintStyle: const TextStyle(color: Color(0xFF8CA5BE), fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFFF3F8FD),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFD6E8F7)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  const Text(
                    'Observed Condition / Details',
                    style: TextStyle(color: Color(0xFF013973), fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'e.g. Water is 2 feet deep and flowing fast. Two-wheelers cannot cross.',
                      hintStyle: const TextStyle(color: Color(0xFF8CA5BE), fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFFF3F8FD),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFD6E8F7)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // GPS Auto-Tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F8FD),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFD6E8F7)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.location_searching_rounded, size: 16, color: Color(0xFF007AEB)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Auto-tagged GPS: 23.7957° N, 86.4304° E (Accuracy: ±4m)',
                            style: TextStyle(color: Color(0xFF013973), fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Photo Upload Placeholder
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD6E8F7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hazard Photo (Optional but Recommended)',
                    style: TextStyle(color: Color(0xFF013973), fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  if (!_hasPhoto)
                    InkWell(
                      onTap: () {
                        setState(() => _hasPhoto = true);
                        _showMessage('Hazard photo captured from camera placeholder');
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 110,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F8FD),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBEDCF5), style: BorderStyle.solid),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.camera_alt_rounded, size: 32, color: Color(0xFF007AEB)),
                            SizedBox(height: 6),
                            Text(
                              'Tap to Capture / Attach Photo',
                              style: TextStyle(color: Color(0xFF007AEB), fontSize: 12, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Stack(
                      children: [
                        Container(
                          height: 140,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: const DecorationImage(
                              image: AssetImage('assets/images/river_bg.jpg'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: CircleAvatar(
                            backgroundColor: Colors.black54,
                            radius: 14,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.close, size: 16, color: Colors.white),
                              onPressed: () => setState(() => _hasPhoto = false),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Photo attached • Verified geotag',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Submit Button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AEB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 3,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.send_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          widget.isHindi ? 'खतरे की रिपोर्ट सबमिट करें' : 'SUBMIT HAZARD REPORT',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.3),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
