import 'package:flutter/material.dart';
import '../../models/incident_models.dart';
import '../../services/incident_coordinator.dart';
import '../relief_camp_detail_screen.dart';
import '../authority/resource_shelter_map_screen.dart';

class CitizenSheltersView extends StatefulWidget {
  final bool isHindi;
  final bool isAuthority;
  final bool isResponder;

  const CitizenSheltersView({
    super.key,
    this.isHindi = false,
    this.isAuthority = false,
    this.isResponder = false,
  });

  @override
  State<CitizenSheltersView> createState() => _CitizenSheltersViewState();
}

class _CitizenSheltersViewState extends State<CitizenSheltersView> {
  String _activeFilter = 'All'; // 'All', 'Open', 'Full', 'Nearby'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    IncidentCoordinator.instance.addListener(_onCoordUpdate);
  }

  @override
  void dispose() {
    _searchController.dispose();
    IncidentCoordinator.instance.removeListener(_onCoordUpdate);
    super.dispose();
  }

  void _onCoordUpdate() {
    if (mounted) setState(() {});
  }

  List<ShelterOccupancy> get _filteredShelters {
    final all = IncidentCoordinator.instance.shelters;
    List<ShelterOccupancy> list = all;

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((s) =>
          s.name.toLowerCase().contains(q) ||
          s.locationName.toLowerCase().contains(q) ||
          s.services.any((svc) => svc.toLowerCase().contains(q))).toList();
    }

    if (_activeFilter == 'Open') {
      list = list.where((s) => s.status.toUpperCase() == 'OPEN' || s.available > 0).toList();
    } else if (_activeFilter == 'Full') {
      list = list.where((s) =>
          s.status.toUpperCase() == 'FULL' ||
          s.status.toUpperCase() == 'LIMITED' ||
          s.status.toUpperCase() == 'NEAR FULL' ||
          s.available == 0).toList();
    } else if (_activeFilter == 'Nearby') {
      list = List.from(list);
      list.sort((a, b) {
        final distA = double.tryParse(a.distance.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 99.0;
        final distB = double.tryParse(b.distance.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 99.0;
        return distA.compareTo(distB);
      });
    }

    return list;
  }

  void _openAddShelterModal(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ResourceShelterMapScreen(initialTabIndex: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = IncidentCoordinator.instance.shelters;
    final allCount = all.length;
    final openCount = all.where((s) => s.status.toUpperCase() == 'OPEN' || s.available > 0).length;
    final fullCount = all.where((s) =>
        s.status.toUpperCase() == 'FULL' ||
        s.status.toUpperCase() == 'LIMITED' ||
        s.status.toUpperCase() == 'NEAR FULL' ||
        s.available == 0).length;

    final shelters = _filteredShelters;

    return Scaffold(
      backgroundColor: const Color(0xFFEFF6FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEFF6FC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A), size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isHindi ? 'राहत शिविर एवं आश्रय' : 'Shelters & Relief Camps',
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: false,
        actions: [
          if (widget.isAuthority)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () => _openAddShelterModal(context),
                icon: const Icon(Icons.add_rounded, size: 16, color: Color(0xFF007AEB)),
                label: Text(
                  widget.isHindi ? '+ नया शिविर' : '+ Add Shelter',
                  style: const TextStyle(
                    color: Color(0xFF007AEB),
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFE0F2FE),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Search Bar & Filter Action (Matching Image 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFD6E4F0), width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    const Icon(Icons.search_rounded, color: Color(0xFF0284C7), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          hintText: widget.isHindi ? 'शिविर या क्षेत्र खोजें...' : 'Search shelter or area...',
                          hintStyle: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.tune_rounded, color: Color(0xFF0284C7), size: 20),
                      tooltip: 'Filter options',
                      onPressed: () {
                        setState(() {
                          _activeFilter = _activeFilter == 'Nearby' ? 'All' : 'Nearby';
                        });
                      },
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),

            // 2. Filter Pills Row (Matching Image 1: All, Open, Full, Nearby)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildPillTab('All', widget.isHindi ? 'सभी ($allCount)' : 'All ($allCount)'),
                    const SizedBox(width: 8),
                    _buildPillTab('Open', widget.isHindi ? 'उपलब्ध ($openCount)' : 'Open ($openCount)'),
                    const SizedBox(width: 8),
                    _buildPillTab('Full', widget.isHindi ? 'सीमित/पूर्ण ($fullCount)' : 'Full ($fullCount)'),
                    const SizedBox(width: 8),
                    _buildPillTab('Nearby', widget.isHindi ? 'नजदीकी' : 'Nearby'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 6),

            // 3. Shelters List View
            Expanded(
              child: shelters.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.night_shelter_outlined, size: 52, color: Color(0xFF94A3B8)),
                          const SizedBox(height: 12),
                          Text(
                            widget.isHindi ? 'कोई शिविर इस फिल्टर से मेल नहीं खाता' : 'No relief shelters match current filter',
                            style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A), fontSize: 14),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.isHindi ? 'कृपया दूसरा नाम या फिल्टर चुनें' : 'Try searching another area or clear filters',
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      itemCount: shelters.length,
                      itemBuilder: (context, index) {
                        return _buildShelterCard(shelters[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: widget.isAuthority
          ? FloatingActionButton.extended(
              onPressed: () => _openAddShelterModal(context),
              backgroundColor: const Color(0xFF007AEB),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_business_rounded, size: 20),
              label: Text(
                widget.isHindi ? 'नया शिविर जोड़ें' : 'Add New Shelter',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
            )
          : null,
    );
  }

  Widget _buildPillTab(String key, String title) {
    final bool isSelected = _activeFilter == key;
    return InkWell(
      onTap: () => setState(() => _activeFilter = key),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF007AEB) : const Color(0xFFE2EDF7),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF007AEB).withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF475569),
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildShelterCard(ShelterOccupancy s) {
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
        ? (widget.isHindi ? 'खुला है' : 'Open')
        : isLimited
            ? (widget.isHindi ? 'सीमित' : 'Limited')
            : (widget.isHindi ? 'भरा हुआ' : 'Full');

    final screenWidth = MediaQuery.of(context).size.width;
    final imageWidth = screenWidth * 0.25;
    const double cardHeight = 156.0; // 0.8x of previous 195.0 height

    return Container(
      height: cardHeight,
      margin: const EdgeInsets.only(bottom: 12),
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
                    isAuthority: widget.isAuthority,
                    isResponder: widget.isResponder,
                    isHindi: widget.isHindi,
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
                                  Colors.black.withValues(alpha: 0.12),
                                ],
                              ),
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
                        // Row 1: Camp Name & Status Badge
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                s.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.2,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
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
                          ],
                        ),

                        // Row 2: Location with Blue Pin
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 13.5, color: Color(0xFF0284C7)),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                s.locationName,
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
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
                                  TextSpan(text: widget.isHindi ? 'क्षमता: ' : 'Capacity: '),
                                  TextSpan(
                                    text: '${s.capacity}',
                                    style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                  ),
                                  const TextSpan(text: ' • '),
                                  TextSpan(text: widget.isHindi ? 'उपलब्ध: ' : 'Available: '),
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
                              _buildTag(Icons.restaurant_rounded, widget.isHindi ? 'भोजन' : 'Food'),
                            if (s.waterAvailable)
                              _buildTag(Icons.water_drop_rounded, widget.isHindi ? 'पानी' : 'Water'),
                            if (s.medicalAvailable)
                              _buildTag(Icons.medical_services_rounded, widget.isHindi ? 'मेडिकल' : 'Medical'),
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
}
