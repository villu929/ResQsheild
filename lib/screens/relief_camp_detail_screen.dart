import 'package:flutter/material.dart';
import '../models/incident_models.dart';
import '../services/incident_coordinator.dart';
import 'citizen/citizen_safe_route_view.dart';
import 'authority/resource_shelter_map_screen.dart';

class ReliefCampDetailScreen extends StatefulWidget {
  final String shelterId;
  final bool isAuthority;
  final bool isResponder;
  final bool isHindi;

  const ReliefCampDetailScreen({
    super.key,
    required this.shelterId,
    this.isAuthority = false,
    this.isResponder = false,
    this.isHindi = false,
  });

  @override
  State<ReliefCampDetailScreen> createState() => _ReliefCampDetailScreenState();
}

class _ReliefCampDetailScreenState extends State<ReliefCampDetailScreen> {
  @override
  void initState() {
    super.initState();
    IncidentCoordinator.instance.addListener(_onCoordUpdate);
  }

  @override
  void dispose() {
    IncidentCoordinator.instance.removeListener(_onCoordUpdate);
    super.dispose();
  }

  void _onCoordUpdate() {
    if (mounted) setState(() {});
  }

  ShelterOccupancy? get _shelter {
    try {
      return IncidentCoordinator.instance.shelters.firstWhere((s) => s.id == widget.shelterId);
    } catch (_) {
      return IncidentCoordinator.instance.shelters.isNotEmpty
          ? IncidentCoordinator.instance.shelters.first
          : null;
    }
  }

  void _handleCall(String phone) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.call_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              widget.isHindi ? 'कॉल किया जा रहा है: $phone' : 'Calling In-Charge: $phone',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF007AEB),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _shelter;
    if (s == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Relief Camp')),
        body: const Center(child: Text('Shelter details not found')),
      );
    }

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

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          widget.isHindi ? 'राहत शिविर' : 'Relief Camp',
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              s.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: s.isFavorite ? Colors.red : const Color(0xFF0284C7),
            ),
            tooltip: 'Favorite Camp',
            onPressed: () {
              IncidentCoordinator.instance.toggleFavoriteShelter(s.id);
            },
          ),
          if (widget.isAuthority)
            IconButton(
              icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF007AEB)),
              tooltip: 'Update Camp Details',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ResourceShelterMapScreen(initialTabIndex: 1),
                  ),
                );
              },
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Hero Shelter Banner Image
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 195,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Image.network(
                    s.photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF0A2540),
                      child: const Center(
                        child: Icon(Icons.night_shelter_rounded, color: Colors.white70, size: 54),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 2. Camp Name & Status Pill
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      s.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // 3. Location & Distance Row
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF0284C7)),
                  const SizedBox(width: 4),
                  Text(
                    s.locationName,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.near_me_rounded, size: 14, color: Color(0xFF0284C7)),
                  const SizedBox(width: 4),
                  Text(
                    s.distance,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // 4. Key Supplies & Resources Metric Box
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F8FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBAE6FD), width: 1.0),
                ),
                child: Row(
                  children: [
                    // Food
                    Expanded(
                      child: _buildMetricItem(
                        icon: Icons.bar_chart_rounded,
                        title: widget.isHindi ? 'भोजन' : 'Food',
                        count: '${s.foodPacks}',
                        unit: widget.isHindi ? 'पैकेट्स' : 'packs',
                      ),
                    ),
                    Container(height: 38, width: 1, color: const Color(0xFFBAE6FD)),
                    // Water
                    Expanded(
                      child: _buildMetricItem(
                        icon: Icons.water_drop_rounded,
                        title: widget.isHindi ? 'पानी' : 'Water',
                        count: '${s.waterBottles}',
                        unit: widget.isHindi ? 'बोतलें' : 'bottles',
                      ),
                    ),
                    Container(height: 38, width: 1, color: const Color(0xFFBAE6FD)),
                    // Medical
                    Expanded(
                      child: _buildMetricItem(
                        icon: Icons.person_rounded,
                        title: widget.isHindi ? 'मेडिकल' : 'Medical',
                        count: '${s.medicalTeams}',
                        unit: widget.isHindi ? 'टीमें' : 'teams',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // 5. Facilities Section
              Text(
                widget.isHindi ? 'सुविधाएं (Facilities)' : 'Facilities',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),

              const SizedBox(height: 12),

              // Facilities Grid (Food, Water, Medical, Sanitation, Charging, Security)
              LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = (constraints.maxWidth - 24) / 4;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 10,
                    children: [
                      _buildFacilityTile(Icons.restaurant_rounded, widget.isHindi ? 'भोजन' : 'Food', itemWidth),
                      _buildFacilityTile(Icons.water_drop_rounded, widget.isHindi ? 'पानी' : 'Water', itemWidth),
                      _buildFacilityTile(Icons.medical_services_rounded, widget.isHindi ? 'मेडिकल' : 'Medical', itemWidth),
                      _buildFacilityTile(Icons.clean_hands_rounded, widget.isHindi ? 'स्वच्छता' : 'Sanitation', itemWidth),
                      _buildFacilityTile(Icons.battery_charging_full_rounded, widget.isHindi ? 'चार्जिंग' : 'Charging', itemWidth),
                      _buildFacilityTile(Icons.shield_rounded, widget.isHindi ? 'सुरक्षा' : 'Security', itemWidth),
                    ],
                  );
                },
              ),

              const SizedBox(height: 22),

              // 6. Capacity Progress Bar
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.isHindi ? 'कुल क्षमता (Total Capacity)' : 'Total Capacity',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${s.occupied} / ${s.capacity} beds (${s.available} free)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: s.occupancyPercent,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 7. Get Directions Big Blue Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CitizenSafeRouteView(isHindi: widget.isHindi),
                      ),
                    );
                  },
                  icon: const Icon(Icons.near_me_rounded, size: 20),
                  label: Text(
                    widget.isHindi ? 'दिशा निर्देश प्राप्त करें (Get Directions)' : 'Get Directions',
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AEB),
                    foregroundColor: Colors.white,
                    elevation: 1,
                    shape: const StadiumBorder(),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // 8. Contact Footer Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone_rounded, color: Color(0xFF007AEB), size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.contact,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            widget.isHindi ? '24x7 उपलब्ध • ${s.inchargeName}' : 'Available 24x7 • ${s.inchargeName}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _handleCall(s.contact),
                      icon: const Icon(Icons.call_rounded, size: 14),
                      label: Text(widget.isHindi ? 'कॉल' : 'Call'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEBF5FF),
                        foregroundColor: const Color(0xFF007AEB),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String title,
    required String count,
    required String unit,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Color(0xFFE0F2FE),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(icon, color: const Color(0xFF0284C7), size: 17),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$count ',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              TextSpan(
                text: unit,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFacilityTile(IconData icon, String label, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFFE0F2FE),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(icon, color: const Color(0xFF0284C7), size: 18),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
