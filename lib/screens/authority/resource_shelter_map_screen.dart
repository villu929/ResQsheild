import 'package:flutter/material.dart';
import '../../models/incident_models.dart';
import '../../services/incident_coordinator.dart';
import '../relief_camp_detail_screen.dart';

class ResourceShelterMapScreen extends StatefulWidget {
  final int initialTabIndex;
  const ResourceShelterMapScreen({super.key, this.initialTabIndex = 1});

  @override
  State<ResourceShelterMapScreen> createState() => _ResourceShelterMapScreenState();
}

class _ResourceShelterMapScreenState extends State<ResourceShelterMapScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _shelterFilter = 'All'; // 'All', 'Available', 'Near Full', 'Medical On-Site'
  String _shelterSearch = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    IncidentCoordinator.instance.addListener(_onCoordUpdate);
  }

  @override
  void dispose() {
    IncidentCoordinator.instance.removeListener(_onCoordUpdate);
    _tabController.dispose();
    super.dispose();
  }

  void _onCoordUpdate() {
    if (mounted) setState(() {});
  }

  void _showNotification(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w700))),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFDC2626) : const Color(0xFF013973),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
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
              'RESOURCE & SHELTER MAP',
              style: TextStyle(
                color: Color(0xFF013973),
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              'NDRF Units, Shelter Capacities & Route Infrastructure',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business_rounded, color: Color(0xFF007AEB)),
            tooltip: 'Add New Shelter Camp',
            onPressed: () => _openShelterForm(context),
          ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF007AEB),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF007AEB),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          tabs: const [
            Tab(icon: Icon(Icons.support_rounded, size: 18), text: 'NDRF Teams'),
            Tab(icon: Icon(Icons.night_shelter_rounded, size: 18), text: 'Shelters'),
            Tab(icon: Icon(Icons.local_hospital_rounded, size: 18), text: 'Medical'),
            Tab(icon: Icon(Icons.alt_route_rounded, size: 18), text: 'Bridges/Roads'),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(
              onPressed: () => _openShelterForm(context),
              backgroundColor: const Color(0xFF013973),
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add_location_alt_rounded, size: 20),
              label: const Text(
                'Add New Shelter',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNdrfTab(),
          _buildSheltersTab(),
          _buildMedicalTab(),
          _buildRoadsTab(),
        ],
      ),
    );
  }

  // 1. NDRF Teams Tab
  Widget _buildNdrfTab() {
    final teams = [
      _NdrfTeam(
        unit: 'NDRF 04 Bn - Alpha QRT',
        location: 'Aluva Old Bridge Bank',
        personnel: 24,
        boats: 6,
        status: 'ON RESCUE MISSION',
        statusColor: const Color(0xFFDC2626),
        commander: 'Cmdr. R. K. Nair',
        contact: '9447101234',
        mission: 'Evacuating 42 marooned families in Sector 3',
      ),
      _NdrfTeam(
        unit: 'NDRF 04 Bn - Bravo Team',
        location: 'Paravur High School Staging',
        personnel: 18,
        boats: 4,
        status: 'DEPLOYED ON GROUND',
        statusColor: const Color(0xFF0284C7),
        commander: 'Insp. Vikram Singh',
        contact: '9447105678',
        mission: 'Reinforcing river levee & assisting senior citizens',
      ),
      _NdrfTeam(
        unit: 'SDRF Disaster Response Unit #2',
        location: 'Kalamassery Central Depot',
        personnel: 30,
        boats: 8,
        status: 'STANDBY READY',
        statusColor: const Color(0xFF16A34A),
        commander: 'Sub-Insp. Priya Menon',
        contact: '9447109012',
        mission: 'Equipped with heavy water pumps & inflatable crafts',
      ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: teams.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _ndrfCard(teams[i]),
    );
  }

  Widget _ndrfCard(_NdrfTeam t) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: t.statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.shield_rounded, color: t.statusColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.unit, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: Color(0xFF0F172A))),
                    Text(t.location, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: t.statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(t.status, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: t.statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Current Task: ${t.mission}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('👤 ${t.personnel} Personnel', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
              const SizedBox(width: 12),
              Text('🚤 ${t.boats} Rescue Boats', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0284C7))),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showNotification('Calling ${t.commander}: ${t.contact}'),
                icon: const Icon(Icons.phone_rounded, size: 12),
                label: const Text('Contact', style: TextStyle(fontSize: 10.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AEB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. Shelters Tab (Fully Reactive & Dynamic from IncidentCoordinator)
  Widget _buildSheltersTab() {
    final allShelters = IncidentCoordinator.instance.shelters;

    // Summary calculations
    final totalCap = allShelters.fold<int>(0, (sum, s) => sum + s.capacity);
    final totalOccupied = allShelters.fold<int>(0, (sum, s) => sum + s.occupied);
    final totalAvail = (totalCap - totalOccupied).clamp(0, totalCap);
    final foodReadyCount = allShelters.where((s) => s.foodAvailable).length;
    final medReadyCount = allShelters.where((s) => s.medicalAvailable).length;

    // Filter list
    final filteredShelters = allShelters.where((s) {
      if (_shelterSearch.isNotEmpty) {
        final q = _shelterSearch.toLowerCase();
        final match = s.name.toLowerCase().contains(q) ||
            s.locationName.toLowerCase().contains(q) ||
            s.foodDetails.toLowerCase().contains(q) ||
            s.medicalDetails.toLowerCase().contains(q);
        if (!match) return false;
      }
      if (_shelterFilter == 'Available' && s.available < 20) return false;
      if (_shelterFilter == 'Near Full' && (s.available >= 20 || s.status == 'FULL')) return false;
      if (_shelterFilter == 'Medical On-Site' && !s.medicalAvailable) return false;
      return true;
    }).toList();

    return Column(
      children: [
        // Summary Header Cards
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Column(
            children: [
              // Top metric tiles row
              Row(
                children: [
                  _shelterMetricBadge('Total Shelters', '${allShelters.length}', const Color(0xFF013973), Icons.domain_rounded),
                  const SizedBox(width: 8),
                  _shelterMetricBadge('Total Capacity', '$totalCap Beds', const Color(0xFF0284C7), Icons.hotel_rounded),
                  const SizedBox(width: 8),
                  _shelterMetricBadge('Available Beds', '$totalAvail Free', const Color(0xFF16A34A), Icons.check_circle_outline_rounded),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _shelterSubMetric('🍲 Food Stock: $foodReadyCount/${allShelters.length} Camps Ready', const Color(0xFF16A34A)),
                  const SizedBox(width: 8),
                  _shelterSubMetric('🩺 Medical: $medReadyCount/${allShelters.length} Triage Active', const Color(0xFF0284C7)),
                ],
              ),
              const SizedBox(height: 10),
              // Search & Filter Bar
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        onChanged: (v) => setState(() => _shelterSearch = v),
                        style: const TextStyle(fontSize: 12.5),
                        decoration: const InputDecoration(
                          hintText: 'Search shelters...',
                          hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          prefixIcon: Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 9),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _filterChip('All'),
                          const SizedBox(width: 6),
                          _filterChip('Available'),
                          const SizedBox(width: 6),
                          _filterChip('Near Full'),
                          const SizedBox(width: 6),
                          _filterChip('Medical On-Site'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _openShelterForm(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AEB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Shelter', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Shelter Cards List
        Expanded(
          child: filteredShelters.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.night_shelter_outlined, size: 48, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 10),
                      const Text('No relief shelters match the current filter', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _openShelterForm(context),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Open New Shelter Camp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007AEB),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: filteredShelters.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 0),
                  itemBuilder: (context, i) => _shelterCard(filteredShelters[i]),
                ),
        ),
      ],
    );
  }

  Widget _shelterMetricBadge(String title, String val, Color c, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: c, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                  Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: c)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shelterSubMetric(String text, Color c) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: c),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _filterChip(String title) {
    final bool isSelected = _shelterFilter == title;
    return ChoiceChip(
      label: Text(title),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _shelterFilter = title);
      },
      selectedColor: const Color(0xFF007AEB),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF013973),
        fontWeight: FontWeight.w700,
        fontSize: 11,
      ),
      backgroundColor: const Color(0xFFF1F5F9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _shelterCard(ShelterOccupancy s) {
    final isOpen = s.status.toUpperCase() == 'OPEN' || s.available > 0;
    final isLimited = s.status.toUpperCase() == 'LIMITED' || s.status.toUpperCase() == 'NEAR FULL';
    final statusBg = isOpen
        ? const Color(0xFFDCFCE7)
        : isLimited
            ? const Color(0xFFFEF3C7)
            : const Color(0xFFFEE2E2);
    final statusColor = isOpen
        ? const Color(0xFF16A34A)
        : isLimited
            ? const Color(0xFFD97706)
            : const Color(0xFFDC2626);
    final statusText = isOpen
        ? 'Open'
        : isLimited
            ? 'Limited'
            : 'Full';

    final screenWidth = MediaQuery.of(context).size.width;
    final imageWidth = screenWidth * 0.25;
    const double cardHeight = 182.0;

    return Container(
      height: cardHeight,
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReliefCampDetailScreen(
                    shelterId: s.id,
                    isAuthority: true,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left: Shelter Image (Full height of container, 25% screen width, curved circular border on all 4 sides)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: imageWidth,
                      height: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            s.photoUrl,
                            width: imageWidth,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFF0F172A),
                              child: const Center(
                                child: Icon(Icons.night_shelter_rounded, color: Colors.white70, size: 32),
                              ),
                            ),
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.85),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 6,
                            left: 6,
                            right: 6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  s.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    height: 1.1,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.location_on_rounded, size: 12, color: Colors.white70),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        s.locationName,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Right: Details and Actions
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Row 1: Status Badge
                        Align(
                          alignment: Alignment.topRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: statusColor.withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Row 3: Capacity & Available + visual occupancy bar (1.5x width = 202.5, 7.0 height)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                children: [
                                  const TextSpan(text: 'Capacity: '),
                                  TextSpan(
                                    text: '${s.capacity}',
                                    style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                  ),
                                  const TextSpan(text: ' • '),
                                  const TextSpan(text: 'Available: '),
                                  TextSpan(
                                    text: '${s.available}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: isOpen ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final double barWidth = (202.5).clamp(0.0, constraints.maxWidth);
                                return SizedBox(
                                  width: barWidth,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: s.capacity > 0 ? (s.occupied / s.capacity).clamp(0.0, 1.0) : 0.0,
                                      minHeight: 7.0,
                                      backgroundColor: const Color(0xFFE2E8F0),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        isOpen ? const Color(0xFF0284C7) : const Color(0xFFEF4444),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),

                        // Row 4: Provision Tags (Food, Water, Medical)
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            if (s.foodAvailable)
                              _buildTag(Icons.restaurant_rounded, 'Food'),
                            if (s.waterAvailable)
                              _buildTag(Icons.water_drop_rounded, 'Water'),
                            if (s.medicalAvailable)
                              _buildTag(Icons.medical_services_rounded, 'Medical'),
                          ],
                        ),

                        // Row 5: Distance & Navigation chevron
                        Row(
                          children: [
                            const Icon(Icons.near_me_rounded, size: 13.5, color: Color(0xFF0284C7)),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                s.distance,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0284C7),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 19,
                              color: Color(0xFF0284C7),
                            ),
                          ],
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
    );
  }

  Widget _buildTag(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBAE6FD), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11.5, color: const Color(0xFF0284C7)),
          const SizedBox(width: 3.5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0284C7),
            ),
          ),
        ],
      ),
    );
  }

  // 3. Medical Tab
  Widget _buildMedicalTab() {
    final hospitals = [
      _Hospital(
        name: 'General District Hospital Aluva',
        emergencyBeds: 45,
        icuBeds: 12,
        ambulances: 4,
        status: 'OPERATIONAL - HIGH LOAD',
        statusColor: const Color(0xFF0284C7),
      ),
      _Hospital(
        name: 'Amrita Institute of Medical Sciences',
        emergencyBeds: 120,
        icuBeds: 35,
        ambulances: 10,
        status: 'MAJOR TRAUMA CENTER',
        statusColor: const Color(0xFF16A34A),
      ),
      _Hospital(
        name: 'Paravur Community Health Centre',
        emergencyBeds: 8,
        icuBeds: 0,
        ambulances: 2,
        status: 'LIMITED EMERGENCY CAPACITY',
        statusColor: const Color(0xFFEA580C),
      ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: hospitals.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final h = hospitals[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 3))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(h.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: Color(0xFF0F172A))),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(color: h.statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                    child: Text(h.status, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: h.statusColor)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _medBadge('Emergency Beds', '${h.emergencyBeds} Available', const Color(0xFF0284C7)),
                  const SizedBox(width: 8),
                  _medBadge('ICU Units', '${h.icuBeds} Free', const Color(0xFF16A34A)),
                  const SizedBox(width: 8),
                  _medBadge('108 Ambulances', '${h.ambulances} Standby', const Color(0xFFDC2626)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _medBadge(String title, String val, Color c) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 8.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
            Text(val, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: c)),
          ],
        ),
      ),
    );
  }

  // 4. Roads & Bridges Tab
  Widget _buildRoadsTab() {
    final infrastructure = [
      _RoadItem(
        name: 'Aluva Old Bridge (NH-544)',
        type: 'Bridge Crossing',
        status: 'BLOCKED / WATERLOGGED',
        statusColor: const Color(0xFFDC2626),
        detail: 'Water height 0.6m above deck level. Closed for all traffic.',
        bypass: 'Use NH-32 Bypass Highground Bridge',
      ),
      _RoadItem(
        name: 'NH-32 Highground Bypass',
        type: 'National Highway',
        status: 'OPEN & CLEAR',
        statusColor: const Color(0xFF16A34A),
        detail: 'Pavement dry, dedicated priority emergency corridor active.',
        bypass: 'Primary route for all relief transport',
      ),
      _RoadItem(
        name: 'Varapuzha River Bridge',
        type: 'State Highway',
        status: 'UNSAFE / MONITORING',
        statusColor: const Color(0xFFEA580C),
        detail: 'Scour sensors show strong river undercurrents. Heavy vehicles diverted.',
        bypass: 'Light vehicles only at max 20 km/h',
      ),
      _RoadItem(
        name: 'Paravur Lowland Arterial Road',
        type: 'District Road',
        status: 'BLOCKED',
        statusColor: const Color(0xFFDC2626),
        detail: 'Submerged by 1.2m overflowing irrigation canal.',
        bypass: 'Accessible only via NDRF rescue boat',
      ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: infrastructure.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final r = infrastructure[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 3))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: Color(0xFF0F172A))),
                        Text(r.type, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(color: r.statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                    child: Text(r.status, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: r.statusColor)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(r.detail, style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155), height: 1.3)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                child: Row(
                  children: [
                    const Icon(Icons.alt_route_rounded, size: 13, color: Color(0xFF007AEB)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text('Corridor Note: ${r.bypass}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF007AEB))),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // ADD & UPDATE SHELTER MODAL BOTTOM SHEET
  // ─────────────────────────────────────────────────────────────────────────────
  void _openShelterForm(BuildContext context, {ShelterOccupancy? shelterToEdit}) {
    final isEditing = shelterToEdit != null;

    final nameCtrl = TextEditingController(text: shelterToEdit?.name ?? '');
    final locationCtrl = TextEditingController(text: shelterToEdit?.locationName ?? 'Sector 4 Safe Zone, Highground');
    final capacityCtrl = TextEditingController(text: (shelterToEdit?.capacity ?? 300).toString());
    final occupiedCtrl = TextEditingController(text: (shelterToEdit?.occupied ?? 0).toString());
    final latCtrl = TextEditingController(text: (shelterToEdit?.latitude ?? 25.4600).toString());
    final lngCtrl = TextEditingController(text: (shelterToEdit?.longitude ?? 91.7500).toString());
    final foodDetailsCtrl = TextEditingController(text: shelterToEdit?.foodDetails ?? '3 Hot Cooked Meals Daily & Dry Rations');
    final waterDetailsCtrl = TextEditingController(text: shelterToEdit?.waterDetails ?? '24/7 RO Potable Drinking Water & Tankers');
    final medicalDetailsCtrl = TextEditingController(text: shelterToEdit?.medicalDetails ?? 'Doctor & 2 SDRF Paramedics On-Site');
    final inchargeCtrl = TextEditingController(text: shelterToEdit?.inchargeName ?? 'Officer In-Charge');
    final contactCtrl = TextEditingController(text: shelterToEdit?.contact ?? '+91 94361 20000');

    bool foodAvail = shelterToEdit?.foodAvailable ?? true;
    bool waterAvail = shelterToEdit?.waterAvailable ?? true;
    bool medicalAvail = shelterToEdit?.medicalAvailable ?? true;
    String status = shelterToEdit?.status ?? 'OPEN';
    String selectedPhoto = shelterToEdit?.photoUrl ?? 'https://images.unsplash.com/photo-1586769852044-692d6e3703f0?auto=format&fit=crop&w=600&q=80';

    final photoPresets = [
      {'title': 'School Building', 'url': 'https://images.unsplash.com/photo-1580582932707-520aed937b7b?auto=format&fit=crop&w=600&q=80'},
      {'title': 'Community Hall', 'url': 'https://images.unsplash.com/photo-1517457373958-b7bdd4587205?auto=format&fit=crop&w=600&q=80'},
      {'title': 'Indoor Stadium', 'url': 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?auto=format&fit=crop&w=600&q=80'},
      {'title': 'Relief Center Camp', 'url': 'https://images.unsplash.com/photo-1586769852044-692d6e3703f0?auto=format&fit=crop&w=600&q=80'},
    ];

    final servicesSet = (shelterToEdit?.services ?? ['Clean Meals', 'Drinking Water', 'Doctor On-Site', 'Generators', 'Sanitation']).toSet();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.90,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Top Drag Bar & Title
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF013973).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isEditing ? Icons.edit_location_alt_rounded : Icons.add_business_rounded,
                            color: const Color(0xFF013973),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEditing ? 'UPDATE RELIEF SHELTER' : 'ADD NEW RELIEF SHELTER',
                                style: const TextStyle(
                                  color: Color(0xFF013973),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const Text(
                                'Live sync with Citizens & Field Responders',
                                style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),

                  // Form Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Shelter Name & Location
                          _formSectionTitle('1. Shelter Identification & Location'),
                          const SizedBox(height: 8),
                          _formTextField(nameCtrl, 'Shelter Camp Name', 'e.g. St. Xavier Relief Center', Icons.home_work_rounded),
                          const SizedBox(height: 10),
                          _formTextField(locationCtrl, 'Address / Sector Location', 'e.g. Sector 4 High Ground, Mawphlang', Icons.place_rounded),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(child: _formTextField(latCtrl, 'Latitude', '25.4600', Icons.my_location_rounded, isNumber: true)),
                              const SizedBox(width: 10),
                              Expanded(child: _formTextField(lngCtrl, 'Longitude', '91.7500', Icons.my_location_rounded, isNumber: true)),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // 2. Photo Selection
                          _formSectionTitle('2. Shelter Photo & Camp Image'),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 80,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: photoPresets.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 10),
                              itemBuilder: (context, idx) {
                                final p = photoPresets[idx];
                                final isSel = selectedPhoto == p['url'];
                                return GestureDetector(
                                  onTap: () => setModalState(() => selectedPhoto = p['url']!),
                                  child: Container(
                                    width: 110,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSel ? const Color(0xFF007AEB) : const Color(0xFFCBD5E1),
                                        width: isSel ? 2.5 : 1,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.network(p['url']!, fit: BoxFit.cover),
                                          Container(color: Colors.black.withValues(alpha: isSel ? 0.2 : 0.45)),
                                          Align(
                                            alignment: Alignment.bottomCenter,
                                            child: Padding(
                                              padding: const EdgeInsets.all(4),
                                              child: Text(
                                                p['title']!,
                                                style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                          if (isSel)
                                            const Positioned(
                                              top: 4,
                                              right: 4,
                                              child: Icon(Icons.check_circle_rounded, color: Color(0xFF007AEB), size: 16),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 18),

                          // 3. Space & Capacity
                          _formSectionTitle('3. Bed Capacity & Space Allocation'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: _formTextField(capacityCtrl, 'Total Space (Beds)', '350', Icons.hotel_rounded, isNumber: true)),
                              const SizedBox(width: 10),
                              Expanded(child: _formTextField(occupiedCtrl, 'Currently Occupied', '120', Icons.groups_rounded, isNumber: true)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Text('Camp Operational Status: ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                              const Spacer(),
                              DropdownButton<String>(
                                value: status,
                                items: const [
                                  DropdownMenuItem(value: 'OPEN', child: Text('🟢 OPEN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                  DropdownMenuItem(value: 'NEAR FULL', child: Text('🟠 NEAR FULL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                  DropdownMenuItem(value: 'FULL', child: Text('🔴 FULL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                  DropdownMenuItem(value: 'STANDBY', child: Text('⚪ STANDBY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                ],
                                onChanged: (v) {
                                  if (v != null) setModalState(() => status = v);
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // 4. Khana (Food) Provisions
                          _formSectionTitle('4. Khana / Food Supply Provisions'),
                          const SizedBox(height: 6),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Food Available (Khana Milega)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                            subtitle: const Text('Cooked meals, dry rations, or infant nutrition on site', style: TextStyle(fontSize: 11)),
                            value: foodAvail,
                            activeColor: const Color(0xFF16A34A),
                            onChanged: (v) => setModalState(() => foodAvail = v),
                          ),
                          if (foodAvail)
                            _formTextField(foodDetailsCtrl, 'Food Description / Rations', 'e.g. 3 Hot Meals Daily + Infant Milk', Icons.restaurant_rounded),

                          const SizedBox(height: 18),

                          // 5. Paani (Water) Supply
                          _formSectionTitle('5. Paani / Clean Potable Water'),
                          const SizedBox(height: 6),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Clean Drinking Water (Paani Milega)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                            subtitle: const Text('24/7 RO water, mobile tankers, or packaged water', style: TextStyle(fontSize: 11)),
                            value: waterAvail,
                            activeColor: const Color(0xFF007AEB),
                            onChanged: (v) => setModalState(() => waterAvail = v),
                          ),
                          if (waterAvail)
                            _formTextField(waterDetailsCtrl, 'Water Supply Details', 'e.g. 24/7 RO Potable Water & Tanker Supply', Icons.water_drop_rounded),

                          const SizedBox(height: 18),

                          // 6. Medical Facilities
                          _formSectionTitle('6. Medical Facilities & Doctors On-Site'),
                          const SizedBox(height: 6),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Medical Team & Triage Active', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                            subtitle: const Text('Doctor, paramedics, first-aid, or emergency oxygen beds', style: TextStyle(fontSize: 11)),
                            value: medicalAvail,
                            activeColor: const Color(0xFFDC2626),
                            onChanged: (v) => setModalState(() => medicalAvail = v),
                          ),
                          if (medicalAvail)
                            _formTextField(medicalDetailsCtrl, 'Medical Facilities Available', 'e.g. Doctor & 2 SDRF Paramedics On-Duty', Icons.medical_services_rounded),

                          const SizedBox(height: 18),

                          // 7. Amenities Checkboxes
                          _formSectionTitle('7. Additional Camp Amenities'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              'Clean Meals',
                              'Drinking Water',
                              'Doctor On-Site',
                              'Generators',
                              'Sanitation',
                              'Bedding',
                              'Infant Care',
                              'Women & Child Wing',
                              'Wi-Fi & Charging',
                            ].map((amenity) {
                              final isChecked = servicesSet.contains(amenity);
                              return FilterChip(
                                label: Text(amenity),
                                selected: isChecked,
                                onSelected: (sel) {
                                  setModalState(() {
                                    if (sel) {
                                      servicesSet.add(amenity);
                                    } else {
                                      servicesSet.remove(amenity);
                                    }
                                  });
                                },
                                selectedColor: const Color(0xFF007AEB),
                                checkmarkColor: Colors.white,
                                labelStyle: TextStyle(
                                  color: isChecked ? Colors.white : const Color(0xFF013973),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 18),

                          // 8. In-charge Contact
                          _formSectionTitle('8. In-charge Contact Information'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: _formTextField(inchargeCtrl, 'Incharge Name', 'e.g. Officer R. Sharma', Icons.person_rounded)),
                              const SizedBox(width: 10),
                              Expanded(child: _formTextField(contactCtrl, 'Phone Number', '+91 94361 20000', Icons.phone_rounded, isNumber: true)),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Save Action Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if (nameCtrl.text.trim().isEmpty) {
                                  _showNotification('Please enter a valid shelter name', isError: true);
                                  return;
                                }

                                final cap = int.tryParse(capacityCtrl.text.trim()) ?? 200;
                                final occ = int.tryParse(occupiedCtrl.text.trim()) ?? 0;
                                final lat = double.tryParse(latCtrl.text.trim()) ?? 25.4600;
                                final lng = double.tryParse(lngCtrl.text.trim()) ?? 91.7500;

                                if (isEditing) {
                                  IncidentCoordinator.instance.updateShelter(
                                    id: shelterToEdit.id,
                                    name: nameCtrl.text.trim(),
                                    locationName: locationCtrl.text.trim(),
                                    capacity: cap,
                                    occupied: occ,
                                    latitude: lat,
                                    longitude: lng,
                                    foodAvailable: foodAvail,
                                    foodDetails: foodDetailsCtrl.text.trim(),
                                    waterAvailable: waterAvail,
                                    waterDetails: waterDetailsCtrl.text.trim(),
                                    medicalAvailable: medicalAvail,
                                    medicalDetails: medicalDetailsCtrl.text.trim(),
                                    photoUrl: selectedPhoto,
                                    services: servicesSet.toList(),
                                    contact: contactCtrl.text.trim(),
                                    inchargeName: inchargeCtrl.text.trim(),
                                    status: status,
                                  );
                                  _showNotification('✓ Shelter "${nameCtrl.text.trim()}" updated successfully!');
                                } else {
                                  IncidentCoordinator.instance.addShelter(
                                    name: nameCtrl.text.trim(),
                                    locationName: locationCtrl.text.trim(),
                                    capacity: cap,
                                    occupied: occ,
                                    latitude: lat,
                                    longitude: lng,
                                    foodAvailable: foodAvail,
                                    foodDetails: foodDetailsCtrl.text.trim(),
                                    waterAvailable: waterAvail,
                                    waterDetails: waterDetailsCtrl.text.trim(),
                                    medicalAvailable: medicalAvail,
                                    medicalDetails: medicalDetailsCtrl.text.trim(),
                                    photoUrl: selectedPhoto,
                                    services: servicesSet.toList(),
                                    contact: contactCtrl.text.trim(),
                                    inchargeName: inchargeCtrl.text.trim(),
                                    status: status,
                                  );
                                  _showNotification('✓ New Shelter "${nameCtrl.text.trim()}" published live to Citizen & Responder views!');
                                }

                                Navigator.pop(ctx);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF013973),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 3,
                              ),
                              icon: Icon(isEditing ? Icons.save_rounded : Icons.add_circle_outline_rounded),
                              label: Text(
                                isEditing ? 'SAVE CHANGES' : 'PUBLISH RELIEF SHELTER',
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, letterSpacing: 0.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (isEditing)
                            Center(
                              child: TextButton.icon(
                                onPressed: () {
                                  IncidentCoordinator.instance.deleteShelter(shelterToEdit.id);
                                  Navigator.pop(ctx);
                                  _showNotification('Shelter decommissioned');
                                },
                                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 18),
                                label: const Text('Decommission Shelter', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _formSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w900,
        color: Color(0xFF0F172A),
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _formTextField(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF007AEB)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF007AEB), width: 1.5),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS FOR NDRF, HOSPITALS, AND ROADS
// ─────────────────────────────────────────────────────────────────────────────
class _NdrfTeam {
  final String unit;
  final String location;
  final int personnel;
  final int boats;
  final String status;
  final Color statusColor;
  final String commander;
  final String contact;
  final String mission;

  _NdrfTeam({
    required this.unit,
    required this.location,
    required this.personnel,
    required this.boats,
    required this.status,
    required this.statusColor,
    required this.commander,
    required this.contact,
    required this.mission,
  });
}

class _Hospital {
  final String name;
  final int emergencyBeds;
  final int icuBeds;
  final int ambulances;
  final String status;
  final Color statusColor;

  _Hospital({
    required this.name,
    required this.emergencyBeds,
    required this.icuBeds,
    required this.ambulances,
    required this.status,
    required this.statusColor,
  });
}

class _RoadItem {
  final String name;
  final String type;
  final String status;
  final Color statusColor;
  final String detail;
  final String bypass;

  _RoadItem({
    required this.name,
    required this.type,
    required this.status,
    required this.statusColor,
    required this.detail,
    required this.bypass,
  });
}
