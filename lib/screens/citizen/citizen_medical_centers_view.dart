import 'package:flutter/material.dart';
import 'package:resqshield/models/incident_models.dart';
import 'package:resqshield/services/resource_api_service.dart';
import 'package:resqshield/services/location_service.dart';
import 'package:resqshield/widgets/location_search_widget.dart';
import 'citizen_safe_route_view.dart';
import 'medical_center_detail_screen.dart';
import 'package:geolocator/geolocator.dart';

class CitizenMedicalCentersView extends StatefulWidget {
  final bool isHindi;

  const CitizenMedicalCentersView({super.key, required this.isHindi});

  @override
  State<CitizenMedicalCentersView> createState() =>
      _CitizenMedicalCentersViewState();
}

class _CitizenMedicalCentersViewState extends State<CitizenMedicalCentersView> {
  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All',
    'Nearby',
    'Beds Available',
    'Free Treatment',
    'Open 24x7',
  ];

  @override
  void initState() {
    super.initState();
    ResourceApiService.instance.addListener(_onResourceUpdate);
    LocationService.instance.addListener(_onResourceUpdate);
    LocationService.instance.fetchGps();
  }

  @override
  void dispose() {
    ResourceApiService.instance.removeListener(_onResourceUpdate);
    LocationService.instance.removeListener(_onResourceUpdate);
    super.dispose();
  }

  void _onResourceUpdate() {
    if (mounted) setState(() {});
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Light slate background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isHindi
                  ? 'नजदीकी चिकित्सा सहायता'
                  : 'Nearby Medical Centers',
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.isHindi
                  ? 'अस्पताल और क्लीनिक'
                  : 'Hospitals, Clinics & First-Aid',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: Builder(
        builder: (context) {
          final resourceApi = ResourceApiService.instance;
          final allCenters = resourceApi.medicalCenters;

          if (resourceApi.isLoadingFromApi && allCenters.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF007AEB),
              ),
            );
          }

          if (allCenters.isEmpty) {
            return Center(
              child: Text(
                widget.isHindi
                    ? 'कोई चिकित्सा केंद्र नहीं मिला'
                    : 'No medical centers found.',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }

          // Apply filters
          List<MedicalCenterModel> centers = List.from(allCenters);
          if (_selectedFilter == 'Beds Available') {
            centers = centers.where((c) => c.emergencyBeds > 0).toList();
          } else if (_selectedFilter == 'Free Treatment') {
            centers = centers.where((c) => c.freeTreatmentAvailable).toList();
          } else if (_selectedFilter == 'Open 24x7') {
            centers = centers.where((c) => c.isOpen).toList();
          } else if (_selectedFilter == 'Nearby') {
            final lat = LocationService.instance.activeLat;
            final lng = LocationService.instance.activeLng;
            if (lat != null && lng != null) {
              centers = centers.where((c) {
                if (c.latitude == 0.0 && c.longitude == 0.0) return false;
                final dist = Geolocator.distanceBetween(lat, lng, c.latitude, c.longitude);
                c.distance = '${(dist / 1000).toStringAsFixed(1)} km away';
                return dist <= 150000;
              }).toList();
              
              centers.sort((a, b) {
                final distA = Geolocator.distanceBetween(lat, lng, a.latitude, a.longitude);
                final distB = Geolocator.distanceBetween(lat, lng, b.latitude, b.longitude);
                return distA.compareTo(distB);
              });
            } else {
              centers = []; // no location available — UI handles this
            }
          }

          return Column(
            children: [
              // Location search shown only in Nearby mode
              if (_selectedFilter == 'Nearby') const LocationSearchWidget(),
              _buildFilterStrip(),
              Expanded(
                child: _selectedFilter == 'Nearby' &&
                        !LocationService.instance.hasLocation &&
                        !LocationService.instance.isFetchingGps
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_off_rounded,
                                  size: 52, color: Color(0xFF94A3B8)),
                              const SizedBox(height: 12),
                              const Text(
                                'Location unavailable.\nSearch and select a location above,\nor allow browser location access.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 16),
                              TextButton.icon(
                                onPressed: LocationService.instance.fetchGps,
                                icon: const Icon(Icons.my_location_rounded,
                                    size: 16, color: Color(0xFF007AEB)),
                                label: const Text(
                                  'Use GPS Location',
                                  style: TextStyle(
                                      color: Color(0xFF007AEB),
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _selectedFilter == 'Nearby' &&
                            LocationService.instance.isFetchingGps &&
                            !LocationService.instance.hasLocation
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                    color: Color(0xFF007AEB)),
                                SizedBox(height: 12),
                                Text('Fetching your location...',
                                    style: TextStyle(
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          )
                        : centers.isEmpty
                    ? Center(
                        child: Text(
                          widget.isHindi
                              ? 'चयनित श्रेणी में कोई केंद्र नहीं'
                              : 'No centers found in this category',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: centers.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          return _buildMedicalCenterCard(centers[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterStrip() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            
            String displayText = filter;
            if (widget.isHindi) {
              switch (filter) {
                case 'All': displayText = 'सभी'; break;
                case 'Nearby': displayText = 'नजदीकी'; break;
                case 'Beds Available': displayText = 'बेड उपलब्ध'; break;
                case 'Free Treatment': displayText = 'मुफ्त इलाज'; break;
                case 'Open 24x7': displayText = 'खुला 24x7'; break;
              }
            }

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text(
                  displayText,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                backgroundColor: isSelected ? const Color(0xFF007AEB) : Colors.white,
                side: BorderSide(
                  color: isSelected ? const Color(0xFF007AEB) : const Color(0xFFCBD5E1),
                  width: 1,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                onPressed: () {
                  setState(() {
                    _selectedFilter = filter;
                  });
                  if (filter == 'Nearby' && !LocationService.instance.hasLocation) {
                    LocationService.instance.fetchGps();
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMedicalCenterCard(MedicalCenterModel center) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Image Section
            Expanded(
              flex: 32,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      center.photoUrl.startsWith('http')
                          ? Image.network(
                              center.photoUrl,
                              fit: BoxFit.fill,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFF0F172A),
                                child: const Center(
                                  child: Icon(Icons.local_hospital_rounded, color: Colors.white70, size: 32),
                                ),
                              ),
                            )
                          : Image.asset(
                              center.photoUrl,
                              fit: BoxFit.fill,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFF0F172A),
                                child: const Center(
                                  child: Icon(Icons.local_hospital_rounded, color: Colors.white70, size: 32),
                                ),
                              ),
                            ),
                      Container(
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
                        bottom: 12,
                        left: 12,
                        right: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // NEAREST MEDICAL HELP badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFE0F2FE,
                                ).withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                widget.isHindi
                                    ? 'चिकित्सा सहायता'
                                    : 'MEDICAL HELP',
                                style: const TextStyle(
                                  color: Color(0xFF0369A1),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              center.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  size: 12,
                                  color: Color(0xFF38BDF8),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  center.distance,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Text(
                                  ' • ',
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  '${center.emergencyBeds}+ beds',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Text(
                                  ' • ',
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 11,
                                  ),
                                ),
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: center.isOpen
                                        ? const Color(0xFF10B981)
                                        : Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  center.isOpen
                                      ? (widget.isHindi
                                            ? 'खुला 24 × 7'
                                            : 'Open 24 × 7')
                                      : 'Closed',
                                  style: TextStyle(
                                    color: center.isOpen
                                        ? const Color(0xFF10B981)
                                        : Colors.red,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
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
            ),

            // Right Details Section
            Expanded(
              flex: 68,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // The 4 metric cards in a row
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _buildHospitalMetricBox(
                              icon: Icons.bed_rounded,
                              iconBg: const Color(0xFFE0F2FE),
                              iconColor: const Color(0xFF0284C7),
                              label: widget.isHindi
                                  ? 'उपलब्ध बेड'
                                  : 'Available Beds',
                              value: '${center.emergencyBeds}',
                              bottomWidget: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: const LinearProgressIndicator(
                                  value: 0.65,
                                  minHeight: 14,
                                  backgroundColor: Color(0xFFE2E8F0),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF007AEB),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildHospitalMetricBox(
                              icon: Icons.medical_services_outlined,
                              iconBg: const Color(0xFFDCFCE7),
                              iconColor: const Color(0xFF16A34A),
                              label: widget.isHindi
                                  ? 'ड्यूटी पर डॉक्टर'
                                  : 'Doctors On Duty',
                              value: center.emergencyBeds > 10 ? '18' : '5',
                              bottomWidget: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF16A34A),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.isHindi ? 'सक्रिय' : 'Active',
                                    style: const TextStyle(
                                      color: Color(0xFF16A34A),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildHospitalMetricBox(
                              icon: Icons.emergency_outlined,
                              iconBg: const Color(0xFFFEE2E2),
                              iconColor: const Color(0xFFEF4444),
                              label: widget.isHindi
                                  ? 'एम्बुलेंस'
                                  : 'Ambulances',
                              value: '${center.ambulanceUnits}',
                              bottomWidget: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: center.ambulanceUnits > 0
                                          ? const Color(0xFF16A34A)
                                          : Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    center.ambulanceUnits > 0
                                        ? (widget.isHindi
                                              ? 'उपलब्ध'
                                              : 'Available')
                                        : 'Busy',
                                    style: TextStyle(
                                      color: center.ambulanceUnits > 0
                                          ? const Color(0xFF16A34A)
                                          : Colors.red,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildHospitalMetricBox(
                              icon: Icons.phone_rounded,
                              iconBg: const Color(0xFFF3E8FF),
                              iconColor: const Color(0xFF9333EA),
                              label: widget.isHindi
                                  ? 'इमरजेंसी हेल्पलाइन'
                                  : 'Emergency Helpline',
                              value: center.phone.length > 5
                                  ? 'Call'
                                  : center.phone,
                              bottomWidget: const Text(
                                '(24 × 7)',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MedicalCenterDetailScreen(
                                  center: center,
                                  isHindi: widget.isHindi,
                                ),
                              ),
                            ),
                            icon: const Icon(
                              Icons.info_outline_rounded,
                              size: 18,
                              color: Color(0xFF0284C7),
                            ),
                            label: Text(
                              widget.isHindi ? 'विवरण देखें' : 'View Details',
                              style: const TextStyle(
                                color: Color(0xFF0284C7),
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(
                                color: Color(0xFF0284C7),
                                width: 1.5,
                              ),
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CitizenSafeRouteView(
                                  isHindi: widget.isHindi,
                                ),
                              ),
                            ),
                            icon: const Icon(
                              Icons.send_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                            label: Text(
                              widget.isHindi ? 'दिशा-निर्देश प्राप्त करें' : 'Get Directions',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: const Color(0xFF007AEB),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
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
        ),
      ),
    );
  }

  Widget _buildHospitalMetricBox({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
    required Widget bottomWidget,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$label   ',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          bottomWidget,
        ],
      ),
    );
  }
}
