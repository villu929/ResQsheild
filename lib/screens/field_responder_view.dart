import 'dart:math' as math;
import 'package:flutter/material.dart';

class FieldResponderView extends StatefulWidget {
  const FieldResponderView({super.key});

  @override
  State<FieldResponderView> createState() => _FieldResponderViewState();
}

class _FieldResponderViewState extends State<FieldResponderView>
    with SingleTickerProviderStateMixin {
  // Navigation & Status State
  int _selectedTabIndex = 0; // 0: Map, 1: Missions, 2: SOS, 3: Profile/Resources
  bool _isOnDuty = true;
  bool _showSafestRoute = true;
  bool _showFloodLayer = true;
  bool _showHazardLayer = true;

  // Mission Step Status: 0: Assigned, 1: Accepted, 2: En Route, 3: Reached, 4: Completed
  int _activeMissionStep = 1; // Default "Accepted"
  final List<String> _missionSteps = [
    'Assigned',
    'Accepted',
    'En Route',
    'Reached',
    'Completed'
  ];

  // Tactical Metrics
  int _rescuedCount = 7;
  final int _totalTrapped = 18;

  // Active Missions List
  final List<Map<String, dynamic>> _missions = [
    {
      'id': 'MSN-8841',
      'title': 'Priority Rescue: Mawryngkneng Village',
      'location': 'Lower Catchment Sector 4, Mawryngkneng',
      'priority': 'CRITICAL',
      'trapped': 18,
      'sosCount': 6,
      'floodDepth': '1.4 m',
      'landslideRisk': 'Medium Risk',
      'recommendedAccess': 'Boat Route #2 (Damodar West)',
      'status': 'In Progress',
      'assignedTeam': 'NDRF Team Bravo (6 Responders)',
      'distance': '1.8 km away',
      'time': 'Just now',
      'icon': Icons.warning_amber_rounded,
      'color': Color(0xFFE92828),
    },
    {
      'id': 'MSN-8840',
      'title': 'Submerged Road & Bus Passenger Extraction',
      'location': 'Damodar River Culvert #4, Dhanbad Road',
      'priority': 'CRITICAL',
      'trapped': 12,
      'sosCount': 4,
      'floodDepth': '1.2 m',
      'landslideRisk': 'Low Risk',
      'recommendedAccess': 'Amphibious Rescue Unit 1',
      'status': 'Accepted',
      'assignedTeam': 'NDRF Team Alpha (4 Responders)',
      'distance': '2.4 km away',
      'time': '12 mins ago',
      'icon': Icons.directions_bus_filled_rounded,
      'color': Color(0xFFE92828),
    },
    {
      'id': 'MSN-8839',
      'title': 'Elderly & Patient Evacuation to St. Xavier',
      'location': 'Ward 7 Community Hall, Low-lying Lane 2',
      'priority': 'HIGH',
      'trapped': 6,
      'sosCount': 2,
      'floodDepth': '0.8 m',
      'landslideRisk': 'None',
      'recommendedAccess': 'High-clearance Rescue Truck',
      'status': 'En Route',
      'assignedTeam': 'SDRF Quick Response #2',
      'distance': '3.2 km away',
      'time': '25 mins ago',
      'icon': Icons.elderly_rounded,
      'color': Color(0xFFF39A20),
    },
    {
      'id': 'MSN-8838',
      'title': 'Tree & Power Cable Clearance',
      'location': 'State Highway 18, Bypass Bridge',
      'priority': 'MODERATE',
      'trapped': 0,
      'sosCount': 1,
      'floodDepth': '0.3 m',
      'landslideRisk': 'High Risk',
      'recommendedAccess': 'PWD Heavy Chainsaw Vehicle',
      'status': 'Dispatched',
      'assignedTeam': 'PWD Rapid Clear Team 3',
      'distance': '4.5 km away',
      'time': '45 mins ago',
      'icon': Icons.handyman_rounded,
      'color': Color(0xFF007AEB),
    },
  ];

  // SOS Emergency List
  final List<Map<String, dynamic>> _sosList = [
    {
      'id': '#1042',
      'name': 'Ramesh Mandal & Family',
      'people': 4,
      'elderly': 1,
      'children': 1,
      'medical': true,
      'urgency': 'CRITICAL',
      'distance': '1.8 km',
      'depth': '1.4 m',
      'note': 'Water entered 1st floor; 1 asthma patient needs inhaler/oxygen.',
      'status': 'Assigned to You',
    },
    {
      'id': '#1039',
      'name': 'Priya Das & Neighbours',
      'people': 6,
      'elderly': 0,
      'children': 3,
      'medical': false,
      'urgency': 'CRITICAL',
      'distance': '2.1 km',
      'depth': '1.6 m',
      'note': 'Terrace surrounded by rapid current, boat required urgently.',
      'status': 'Pending Response',
    },
    {
      'id': '#1036',
      'name': 'Kalyan Sen (Shopkeeper)',
      'people': 2,
      'elderly': 2,
      'children': 0,
      'medical': true,
      'urgency': 'HIGH',
      'distance': '2.8 km',
      'depth': '0.9 m',
      'note': 'Diabetic elderly couple trapped inside single-storey structure.',
      'status': 'SDRF En Route',
    },
    {
      'id': '#1033',
      'name': 'Sunil Soren & Group',
      'people': 6,
      'elderly': 0,
      'children': 1,
      'medical': false,
      'urgency': 'MODERATE',
      'distance': '3.5 km',
      'depth': '0.6 m',
      'note': 'Livestock and families on high mound; need potable water & food.',
      'status': 'Relief Dispatched',
    },
  ];

  late final AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  void _showMessage(String msg, {Color bgColor = const Color(0xFF013973)}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // GROUND SITUATION UPDATE MODAL
  // --------------------------------------------------------------------------
  void _showGroundReportModal() {
    String waterLevel = 'Critical';
    String roadStatus = 'Blocked';
    String bridgeStatus = 'Unsafe';
    String? capturedPhotoName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 18,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Color(0x24013973),
                blurRadius: 24,
                offset: Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF15945C).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.cell_tower_rounded,
                      color: Color(0xFF15945C),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ground Situation Update',
                          style: TextStyle(
                            color: Color(0xFF013973),
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Sync live hazard telemetry to Command Center',
                          style: TextStyle(
                            color: Color(0xFF537392),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: Color(0xFFF1F5F9)),

              // 1. Water Level Selector
              const Text(
                'Current Water Level:',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildOptionChip(
                    'Normal',
                    waterLevel == 'Normal',
                    const Color(0xFF15945C),
                    () => setModalState(() => waterLevel = 'Normal'),
                  ),
                  const SizedBox(width: 8),
                  _buildOptionChip(
                    'Rising / High',
                    waterLevel == 'Rising / High',
                    const Color(0xFFF39A20),
                    () => setModalState(() => waterLevel = 'Rising / High'),
                  ),
                  const SizedBox(width: 8),
                  _buildOptionChip(
                    'Critical / Overflow',
                    waterLevel == 'Critical',
                    const Color(0xFFE92828),
                    () => setModalState(() => waterLevel = 'Critical'),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 2. Road & Bridge Conditions
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Road Access:',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _buildOptionChip(
                              'Open',
                              roadStatus == 'Open',
                              const Color(0xFF15945C),
                              () => setModalState(() => roadStatus = 'Open'),
                            ),
                            const SizedBox(width: 6),
                            _buildOptionChip(
                              'Blocked',
                              roadStatus == 'Blocked',
                              const Color(0xFFE92828),
                              () => setModalState(() => roadStatus = 'Blocked'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bridge Integrity:',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _buildOptionChip(
                              'Safe',
                              bridgeStatus == 'Safe',
                              const Color(0xFF15945C),
                              () => setModalState(() => bridgeStatus = 'Safe'),
                            ),
                            const SizedBox(width: 6),
                            _buildOptionChip(
                              'Unsafe',
                              bridgeStatus == 'Unsafe',
                              const Color(0xFFE92828),
                              () => setModalState(() => bridgeStatus = 'Unsafe'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 3. Photo Evidence
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setModalState(
                            () => capturedPhotoName = 'ground_flood_culvert.jpg');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: capturedPhotoName != null
                              ? const Color(0xFFE8F7F0)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: capturedPhotoName != null
                                ? const Color(0xFF15945C)
                                : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              capturedPhotoName != null
                                  ? Icons.check_circle_rounded
                                  : Icons.photo_camera_rounded,
                              color: capturedPhotoName != null
                                  ? const Color(0xFF15945C)
                                  : const Color(0xFF013973),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              capturedPhotoName != null
                                  ? 'Photo Attached ✓'
                                  : 'Capture Ground Photo',
                              style: TextStyle(
                                color: capturedPhotoName != null
                                    ? const Color(0xFF0E5C38)
                                    : const Color(0xFF013973),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() => _rescuedCount = math.min(_rescuedCount + 2, _totalTrapped));
                    _showMessage(
                      'Ground update broadcasted: Road $roadStatus, Water $waterLevel ✓',
                      bgColor: const Color(0xFF15945C),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF15945C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                  label: const Text(
                    'Submit Field Telemetry',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionChip(
    String label,
    bool isSelected,
    Color activeColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFCBD5E1),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? activeColor : const Color(0xFF64748B),
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // MAIN BUILD
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F6FB),
      appBar: _buildTacticalAppBar(),
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedTabIndex,
            children: [
              _buildLiveMapTab(),
              _buildMissionsTab(),
              _buildSosDeskTab(),
              _buildTacticalProfileTab(),
            ],
          ),

          // Floating Ground Report FAB (available across Map & Missions)
          if (_selectedTabIndex == 0 || _selectedTabIndex == 1)
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton.extended(
                onPressed: _showGroundReportModal,
                backgroundColor: const Color(0xFF15945C),
                elevation: 4,
                icon: const Icon(Icons.cell_tower_rounded,
                    color: Colors.white, size: 20),
                label: const Text(
                  'Ground Report',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // ==========================================================================
  // TOP TACTICAL APP BAR
  // ==========================================================================
  PreferredSizeWidget _buildTacticalAppBar() {
    return AppBar(
      elevation: 0.5,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF013973), size: 18),
        onPressed: () => Navigator.pop(context),
        tooltip: 'Exit to Role Selection',
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'JALGUARD RESPONDER',
                style: TextStyle(
                  color: Color(0xFF013973),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F7F0),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'NDRF-FLD-04',
                  style: TextStyle(
                    color: Color(0xFF0E5C38),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF15945C),
                ),
              ),
              const SizedBox(width: 5),
              const Text(
                'GPS Active • LoRa Mesh Online',
                style: TextStyle(
                  color: Color(0xFF537392),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Duty Status Pill Toggle
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () {
              setState(() => _isOnDuty = !_isOnDuty);
              _showMessage(_isOnDuty
                  ? 'Operational Status: ON-DUTY ACTIVE'
                  : 'Operational Status: STANDBY MODE');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _isOnDuty
                    ? const Color(0xFFE8F7F0)
                    : const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isOnDuty
                      ? const Color(0xFF15945C)
                      : const Color(0xFFF39A20),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isOnDuty
                          ? const Color(0xFF15945C)
                          : const Color(0xFFF39A20),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _isOnDuty ? 'ACTIVE' : 'STANDBY',
                    style: TextStyle(
                      color: _isOnDuty
                          ? const Color(0xFF15945C)
                          : const Color(0xFFF39A20),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // TAB 0: LIVE TACTICAL DISASTER MAP
  // ==========================================================================
  Widget _buildLiveMapTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Interactive Custom Painted Tactical Map Canvas
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _radarController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _TacticalMapPainter(
                      radarPhase: _radarController.value,
                      showFlood: _showFloodLayer,
                      showHazard: _showHazardLayer,
                      showRoute: _showSafestRoute,
                    ),
                  );
                },
              ),
            ),

            // Top Map Filter Chips & Alerts
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Column(
                children: [
                  // Hazard Alert Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2).withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14E92828),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Color(0xFFE92828), size: 18),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'HAZARD: Damodar Culvert #4 Submerged (1.4m) • NH-18 Alternate Safe',
                            style: TextStyle(
                              color: Color(0xFF991B1B),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Layer Toggles
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildMapLayerChip(
                          '🌊 Flood Depth Zone',
                          _showFloodLayer,
                          () => setState(
                              () => _showFloodLayer = !_showFloodLayer),
                        ),
                        const SizedBox(width: 6),
                        _buildMapLayerChip(
                          '🏔️ Landslide Alert',
                          _showHazardLayer,
                          () => setState(
                              () => _showHazardLayer = !_showHazardLayer),
                        ),
                        const SizedBox(width: 6),
                        _buildMapLayerChip(
                          '🟢 Safest Dynamic Route',
                          _showSafestRoute,
                          () => setState(
                              () => _showSafestRoute = !_showSafestRoute),
                          highlight: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Active Mission Mini Card on Map
            Positioned(
              left: 14,
              right: 14,
              bottom: 74,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD6E6F2)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14013973),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '🚨 PRIORITY RESCUE',
                            style: TextStyle(
                              color: Color(0xFFDC2626),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          '1.8 km • Safest Route Active',
                          style: TextStyle(
                            color: Color(0xFF15945C),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Mawryngkneng Village • Sector 4',
                      style: TextStyle(
                        color: Color(0xFF013973),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      '👥 18 Trapped • 6 Critical SOS • Depth 1.4m • Water Rising',
                      style: TextStyle(
                        color: Color(0xFF537392),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() => _selectedTabIndex = 1);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF15945C),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.navigation_rounded, size: 16),
                            label: const Text(
                              'Follow Safest Route',
                              style: TextStyle(
                                  fontSize: 12.5, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () {
                            setState(() => _selectedTabIndex = 2);
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF007AEB)),
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'SOS List (6)',
                            style: TextStyle(
                              color: Color(0xFF007AEB),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
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
      },
    );
  }

  Widget _buildMapLayerChip(
    String label,
    bool isActive,
    VoidCallback onTap, {
    bool highlight = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? (highlight ? const Color(0xFF15945C) : const Color(0xFF013973))
              : Colors.white.withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive
                ? (highlight ? const Color(0xFF15945C) : const Color(0xFF013973))
                : const Color(0xFFCBD5E1),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF475569),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // TAB 1: ACTIVE MISSIONS TAB
  // ==========================================================================
  Widget _buildMissionsTab() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(14),
      children: [
        // Primary Active Mission Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFD6E6F2)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C013973),
                blurRadius: 10,
                offset: Offset(0, 3),
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
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.crisis_alert_rounded,
                      color: Color(0xFFDC2626),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🚨 ACTIVE ASSIGNED MISSION',
                          style: TextStyle(
                            color: Color(0xFFDC2626),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          'Mawryngkneng Flood Rescue',
                          style: TextStyle(
                            color: Color(0xFF013973),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F7F0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'PRIORITY 1',
                      style: TextStyle(
                        color: Color(0xFF0E5C38),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: Color(0xFFF1F5F9)),

              // Key Stats Grid
              Row(
                children: [
                  _buildMissionStat('👥 Trapped', '$_totalTrapped People',
                      const Color(0xFF0F172A)),
                  _buildMissionStat(
                      '🆘 SOS Count', '6 Calls', const Color(0xFFDC2626)),
                  _buildMissionStat(
                      '🌊 Flood Depth', '1.4 Metres', const Color(0xFF007AEB)),
                  _buildMissionStat(
                      '🛣️ Route', 'Boat Route 2', const Color(0xFF15945C)),
                ],
              ),
              const SizedBox(height: 16),

              // Interactive Mission Status Stepper
              const Text(
                'Mission Lifecycle Tracker:',
                style: TextStyle(
                  color: Color(0xFF013973),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              _buildMissionLifecycleStepper(),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _activeMissionStep =
                              math.min(_activeMissionStep + 1, 4);
                        });
                        _showMessage(
                          'Mission Status Updated: ${_missionSteps[_activeMissionStep]}',
                          bgColor: const Color(0xFF15945C),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF15945C),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.check_circle_outline_rounded,
                          size: 18),
                      label: Text(
                        _activeMissionStep == 1
                            ? 'Depart (En Route)'
                            : (_activeMissionStep == 2
                                ? 'Mark Reached'
                                : (_activeMissionStep == 3
                                    ? 'Mark Completed'
                                    : 'Mission Done ✓')),
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _selectedTabIndex = 0),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF007AEB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 14),
                    ),
                    icon: const Icon(Icons.map_rounded,
                        color: Color(0xFF007AEB), size: 18),
                    label: const Text(
                      'Live Map',
                      style: TextStyle(
                          color: Color(0xFF007AEB),
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Section Title
        Row(
          children: const [
            Icon(Icons.format_list_bulleted_rounded,
                color: Color(0xFF013973), size: 18),
            SizedBox(width: 8),
            Text(
              'Other Tactical Sector Tasks',
              style: TextStyle(
                color: Color(0xFF013973),
                fontSize: 14.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Other Missions
        ..._missions.skip(1).map((m) => _buildMissionCard(m)),
      ],
    );
  }

  Widget _buildMissionStat(String title, String value, Color valueColor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionLifecycleStepper() {
    return Row(
      children: List.generate(_missionSteps.length, (index) {
        final bool isPassed = index <= _activeMissionStep;
        final bool isCurrent = index == _activeMissionStep;

        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 3,
                      color: index == 0
                          ? Colors.transparent
                          : (index <= _activeMissionStep
                              ? const Color(0xFF15945C)
                              : const Color(0xFFE2E8F0)),
                    ),
                  ),
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPassed
                          ? const Color(0xFF15945C)
                          : const Color(0xFFE2E8F0),
                      border: isCurrent
                          ? Border.all(color: const Color(0xFF10B981), width: 3)
                          : null,
                    ),
                    child: isPassed
                        ? const Center(
                            child: Icon(Icons.check,
                                color: Colors.white, size: 11),
                          )
                        : null,
                  ),
                  Expanded(
                    child: Container(
                      height: 3,
                      color: index == _missionSteps.length - 1
                          ? Colors.transparent
                          : (index < _activeMissionStep
                              ? const Color(0xFF15945C)
                              : const Color(0xFFE2E8F0)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _missionSteps[index],
                style: TextStyle(
                  color: isCurrent
                      ? const Color(0xFF15945C)
                      : (isPassed
                          ? const Color(0xFF013973)
                          : const Color(0xFF94A3B8)),
                  fontSize: 9.5,
                  fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildMissionCard(Map<String, dynamic> m) {
    final Color priorityColor = m['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD6E6F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(m['icon'] as IconData,
                    color: priorityColor, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  m['title'] as String,
                  style: const TextStyle(
                    color: Color(0xFF013973),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  m['priority'] as String,
                  style: TextStyle(
                    color: priorityColor,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            m['location'] as String,
            style: const TextStyle(
              color: Color(0xFF537392),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.people_outline_rounded,
                  size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(
                m['assignedTeam'] as String,
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                m['distance'] as String,
                style: const TextStyle(
                  color: Color(0xFF007AEB),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 2: EMERGENCY SOS DESK
  // ==========================================================================
  Widget _buildSosDeskTab() {
    final int remaining = _totalTrapped - _rescuedCount;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(14),
      children: [
        // Priority Triage Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF013973),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F013973),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.emergency_share_rounded,
                      color: Color(0xFFFF5252), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'TACTICAL RESCUE STATUS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Counter Row
              Row(
                children: [
                  _buildWhiteStat('Total Trapped', '$_totalTrapped'),
                  _buildWhiteStat('Rescued', '$_rescuedCount',
                      color: const Color(0xFF4ADE80)),
                  _buildWhiteStat('Remaining', '$remaining',
                      color: const Color(0xFFF87171)),
                  _buildWhiteStat('Medical Care', '3 SOS',
                      color: const Color(0xFFFBBF24)),
                ],
              ),
              const SizedBox(height: 14),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _rescuedCount / _totalTrapped,
                  minHeight: 7,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF4ADE80)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: const [
            Icon(Icons.notifications_active_rounded,
                color: Color(0xFFE92828), size: 18),
            SizedBox(width: 8),
            Text(
              'Incoming Civilian SOS Broadcasts',
              style: TextStyle(
                color: Color(0xFF013973),
                fontSize: 14.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        ..._sosList.map((s) => _buildSosCard(s)),
      ],
    );
  }

  Widget _buildWhiteStat(String label, String value, {Color? color}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color ?? Colors.white,
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSosCard(Map<String, dynamic> s) {
    final bool isCritical = s['urgency'] == 'CRITICAL';
    final bool hasMedical = s['medical'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCritical
              ? const Color(0xFFFCA5A5)
              : const Color(0xFFD6E6F2),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A013973),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isCritical
                      ? const Color(0xFFFEE2E2)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  'SOS ${s['id']}',
                  style: TextStyle(
                    color: isCritical
                        ? const Color(0xFFDC2626)
                        : const Color(0xFFD97706),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (hasMedical)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.medical_services_rounded,
                          color: Color(0xFFDC2626), size: 11),
                      SizedBox(width: 4),
                      Text(
                        'MEDICAL NEEDED',
                        style: TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              Text(
                s['distance'] as String,
                style: const TextStyle(
                  color: Color(0xFF007AEB),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Text(
            s['name'] as String,
            style: const TextStyle(
              color: Color(0xFF013973),
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '👥 ${s['people']} People (${s['elderly']} Elderly, ${s['children']} Children) • Depth: ${s['depth']}',
            style: const TextStyle(
              color: Color(0xFF537392),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            s['note'] as String,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 12,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _selectedTabIndex = 0);
                    _showMessage(
                      'Navigating via Safest Route to SOS ${s['id']}',
                      bgColor: const Color(0xFF15945C),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF15945C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.near_me_rounded, size: 16),
                  label: const Text('Safest Route',
                      style: TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {
                  _showMessage('Emergency call connected to ${s['name']}');
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF007AEB)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                ),
                icon: const Icon(Icons.phone_rounded,
                    color: Color(0xFF007AEB), size: 16),
                label: const Text('Call',
                    style: TextStyle(
                        color: Color(0xFF007AEB), fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 3: TACTICAL PROFILE & RESOURCE HUB
  // ==========================================================================
  Widget _buildTacticalProfileTab() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(14),
      children: [
        // Tactical ID Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF013973), Color(0xFF0B2545)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F013973),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF15945C), width: 2),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Color(0xFF013973),
                      size: 34,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Insp. Vikramaditya Singh',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'NDRF Tactical Field Unit • 4th Battalion',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'ID: NDRF-8842-FLD • VHF: CH-08',
                          style: TextStyle(
                            color: Color(0xFF4ADE80),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Available Resources Widget
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD6E6F2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.inventory_2_outlined,
                      color: Color(0xFF013973), size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Field Tactical Assets Available',
                    style: TextStyle(
                      color: Color(0xFF013973),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      _showMessage(
                        'Request sent for 1 additional Inflatable Boat to Command Base ✓',
                        bgColor: const Color(0xFF15945C),
                      );
                    },
                    child: const Text(
                      '+ Request Asset',
                      style: TextStyle(
                        color: Color(0xFF007AEB),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildResourceCard(
                      '🚤 Rescue Boats', '3 Ready', const Color(0xFF007AEB)),
                  _buildResourceCard(
                      '🚑 Ambulances', '2 Active', const Color(0xFFDC2626)),
                  _buildResourceCard(
                      '🚒 4x4 Trucks', '1 Ready', const Color(0xFFF39A20)),
                  _buildResourceCard(
                      '👥 QRT Teams', '4 Units', const Color(0xFF15945C)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Nearest Functional Medical Facility Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD6E6F2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_hospital_rounded,
                      color: Color(0xFF15945C), size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Nearest Functional Medical Facility',
                    style: TextStyle(
                      color: Color(0xFF013973),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F7F0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '🟢 OPERATIONAL',
                      style: TextStyle(
                        color: Color(0xFF0E5C38),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'District General Hospital • Sector 2',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Distance: 4.2 km • 18 Beds Available • 2 Ambulances Stationed • Emergency Trauma Unit OPEN',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Safe Relief Shelter Status
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD6E6F2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.home_work_rounded,
                      color: Color(0xFF007AEB), size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Designated Safe Evacuation Camp',
                    style: TextStyle(
                      color: Color(0xFF013973),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    '2.7 km away',
                    style: TextStyle(
                      color: Color(0xFF007AEB),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'St. Xavier Relief Camp • Capacity: 100',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Occupied: 62 • Vacant: 38 • Potable Water: Available ✓ • Dry Rations: Available ✓',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Offline Mode Status
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F7F0),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFB9E8D3)),
          ),
          child: Row(
            children: const [
              Icon(Icons.offline_pin_rounded,
                  color: Color(0xFF15945C), size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Offline Resilience: Topo maps & victim records cached locally. LoRa peer sync active.',
                  style: TextStyle(
                    color: Color(0xFF0E5C38),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResourceCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // BOTTOM NAVIGATION BAR
  // ==========================================================================
  Widget _buildBottomNavigation() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFD6E6F2), width: 0.8)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            _buildNavTab(0, Icons.map_rounded, 'Live Map'),
            _buildNavTab(1, Icons.crisis_alert_rounded, 'Missions'),
            _buildNavTab(2, Icons.emergency_rounded, 'SOS Desk', badge: '6'),
            _buildNavTab(3, Icons.shield_rounded, 'Profile/Assets'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTab(int index, IconData icon, String label, {String? badge}) {
    final bool isSelected = _selectedTabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: isSelected
                        ? const Color(0xFF15945C)
                        : const Color(0xFF7A9BB8),
                  ),
                  if (badge != null)
                    Positioned(
                      top: -3,
                      right: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE92828),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF15945C)
                      : const Color(0xFF7A9BB8),
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// CUSTOM PAINTER: INTERACTIVE TACTICAL DISASTER MAP
// ============================================================================
class _TacticalMapPainter extends CustomPainter {
  final double radarPhase;
  final bool showFlood;
  final bool showHazard;
  final bool showRoute;

  _TacticalMapPainter({
    required this.radarPhase,
    required this.showFlood,
    required this.showHazard,
    required this.showRoute,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Base Map Background
    final bgPaint = Paint()..color = const Color(0xFFE5EFF7);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // 2. Tactical Grid Lines
    final gridPaint = Paint()
      ..color = const Color(0xFFD0E1F0)
      ..strokeWidth = 0.8;
    for (double x = 0; x < w; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (double y = 0; y < h; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // 3. River Damodar Bed (Meandering Path)
    final riverPaint = Paint()
      ..color = const Color(0xFFB5D7F0)
      ..strokeWidth = 28
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final riverPath = Path();
    riverPath.moveTo(w * 0.1, 0);
    riverPath.cubicTo(w * 0.2, h * 0.3, w * 0.6, h * 0.4, w * 0.85, h);
    canvas.drawPath(riverPath, riverPaint);

    // 4. Flooded Basin Polygon (Layer 1)
    if (showFlood) {
      final floodPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF3B82F6).withValues(alpha: 0.38),
            const Color(0xFF2563EB).withValues(alpha: 0.15),
          ],
        ).createShader(Rect.fromCircle(
            center: Offset(w * 0.65, h * 0.45), radius: w * 0.35))
        ..style = PaintingStyle.fill;

      final floodPath = Path();
      floodPath.moveTo(w * 0.45, h * 0.28);
      floodPath.quadraticBezierTo(w * 0.85, h * 0.32, w * 0.9, h * 0.58);
      floodPath.quadraticBezierTo(w * 0.70, h * 0.75, w * 0.40, h * 0.62);
      floodPath.close();
      canvas.drawPath(floodPath, floodPaint);
    }

    // 5. Landslide High-Risk Zone (Layer 2)
    if (showHazard) {
      final hazardPaint = Paint()
        ..color = const Color(0xFFF97316).withValues(alpha: 0.26)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(w * 0.25, h * 0.48), 38, hazardPaint);

      // Warning circle border
      final hazardBorder = Paint()
        ..color = const Color(0xFFEA580C)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(Offset(w * 0.25, h * 0.48), 38, hazardBorder);
    }

    // 6. Roads:
    // Road A (Blocked direct route through damaged culvert)
    final blockedRoadPaint = Paint()
      ..color = const Color(0xFFEF4444).withValues(alpha: 0.75)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;
    final blockedPath = Path();
    blockedPath.moveTo(w * 0.22, h * 0.72); // Responder location
    blockedPath.lineTo(w * 0.42, h * 0.52); // Culvert position
    blockedPath.lineTo(w * 0.72, h * 0.38); // Destination Mawryngkneng
    canvas.drawPath(blockedPath, blockedRoadPaint);

    // Cross on Culvert
    final crossPaint = Paint()
      ..color = const Color(0xFFDC2626)
      ..strokeWidth = 3.0;
    canvas.drawLine(
        Offset(w * 0.42 - 8, h * 0.52 - 8), Offset(w * 0.42 + 8, h * 0.52 + 8), crossPaint);
    canvas.drawLine(
        Offset(w * 0.42 + 8, h * 0.52 - 8), Offset(w * 0.42 - 8, h * 0.52 + 8), crossPaint);

    // 7. Safest Dynamic Route (Green Path avoiding flooded culvert)
    if (showRoute) {
      final routePaint = Paint()
        ..color = const Color(0xFF10B981)
        ..strokeWidth = 5.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final safeRoutePath = Path();
      safeRoutePath.moveTo(w * 0.22, h * 0.72); // Responder
      safeRoutePath.cubicTo(
        w * 0.15,
        h * 0.60,
        w * 0.32,
        h * 0.25,
        w * 0.72,
        h * 0.38, // Mawryngkneng Village
      );
      canvas.drawPath(safeRoutePath, routePaint);
    }

    // 8. Key Markers:
    // A: Destination SOS Incident (Mawryngkneng)
    final destCenter = Offset(w * 0.72, h * 0.38);
    final pulseRadius = 14 + (radarPhase * 16);
    final pulsePaint = Paint()
      ..color = const Color(0xFFEF4444).withValues(alpha: 1.0 - radarPhase)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(destCenter, pulseRadius, pulsePaint);

    final destPin = Paint()..color = const Color(0xFFDC2626);
    canvas.drawCircle(destCenter, 9, destPin);
    final destInner = Paint()..color = Colors.white;
    canvas.drawCircle(destCenter, 4, destInner);

    // B: Responder Location (📍 YOU)
    final respCenter = Offset(w * 0.22, h * 0.72);
    final respRadar = Paint()
      ..color = const Color(0xFF15945C).withValues(alpha: 1.0 - radarPhase)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(respCenter, 12 + (radarPhase * 18), respRadar);

    final respPin = Paint()..color = const Color(0xFF15945C);
    canvas.drawCircle(respCenter, 10, respPin);
    final respInner = Paint()..color = Colors.white;
    canvas.drawCircle(respCenter, 5, respInner);

    // C: Safe Shelter Pin (St. Xavier)
    final shelterCenter = Offset(w * 0.35, h * 0.85);
    final shelterPaint = Paint()..color = const Color(0xFF007AEB);
    canvas.drawCircle(shelterCenter, 7, shelterPaint);

    // D: Functional Hospital Pin (District Hospital)
    final hospCenter = Offset(w * 0.82, h * 0.78);
    final hospPaint = Paint()..color = const Color(0xFF16A34A);
    canvas.drawCircle(hospCenter, 7, hospPaint);
  }

  @override
  bool shouldRepaint(covariant _TacticalMapPainter oldDelegate) {
    return oldDelegate.radarPhase != radarPhase ||
        oldDelegate.showFlood != showFlood ||
        oldDelegate.showHazard != showHazard ||
        oldDelegate.showRoute != showRoute;
  }
}
