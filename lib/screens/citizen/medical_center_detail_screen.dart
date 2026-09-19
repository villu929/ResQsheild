import 'package:flutter/material.dart';
import 'package:resqshield/models/incident_models.dart';

class MedicalCenterDetailScreen extends StatelessWidget {
  final MedicalCenterModel center;
  final bool isHindi;

  const MedicalCenterDetailScreen({
    super.key,
    required this.center,
    required this.isHindi,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: CustomScrollView(
        slivers: [
          _buildHeroAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusRow(),
                  const SizedBox(height: 16),
                  _buildQuickStats(),
                  const SizedBox(height: 16),
                  _buildContactCard(),
                  const SizedBox(height: 16),
                  if (center.specialties.isNotEmpty) ...[
                    _buildSpecialtiesCard(),
                    const SizedBox(height: 16),
                  ],
                  _buildServicesCard(),
                  const SizedBox(height: 16),
                  if (center.waterborneDiseasesTreated.isNotEmpty) ...[
                    _buildWaterborneCard(),
                    const SizedBox(height: 16),
                  ],
                  if (center.disasterServices.isNotEmpty) ...[
                    _buildDisasterServicesCard(),
                    const SizedBox(height: 16),
                  ],
                  _buildAddressCard(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: const Color(0xFF0F172A),
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              center.photoUrl,
              fit: BoxFit.fill,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFF0F172A),
                child: const Center(
                  child: Icon(Icons.local_hospital_rounded,
                      color: Colors.white38, size: 64),
                ),
              ),
            ),
            // Dark gradient overlay
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0xCC0F172A),
                  ],
                  stops: [0.4, 1.0],
                ),
              ),
            ),
            // Name at bottom
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AEB),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      center.facilityType.isNotEmpty
                          ? center.facilityType.toUpperCase()
                          : 'MEDICAL FACILITY',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    center.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 13, color: Color(0xFF38BDF8)),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          center.locationName,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
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
    );
  }

  Widget _buildStatusRow() {
    return Row(
      children: [
        _buildBadge(
          icon: Icons.circle,
          iconColor: const Color(0xFF10B981),
          label: isHindi ? 'खुला 24×7' : 'Open 24×7',
          bg: const Color(0xFFDCFCE7),
          textColor: const Color(0xFF16A34A),
        ),
        const SizedBox(width: 8),
        _buildBadge(
          icon: Icons.directions_walk_rounded,
          iconColor: const Color(0xFF0284C7),
          label: center.distance,
          bg: const Color(0xFFE0F2FE),
          textColor: const Color(0xFF0284C7),
        ),
        if (center.freeTreatmentAvailable) ...[
          const SizedBox(width: 8),
          _buildBadge(
            icon: Icons.volunteer_activism_rounded,
            iconColor: const Color(0xFF9333EA),
            label: isHindi ? 'मुफ्त इलाज' : 'Free Treatment',
            bg: const Color(0xFFF3E8FF),
            textColor: const Color(0xFF9333EA),
          ),
        ],
      ],
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Color bg,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: iconColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.bed_rounded,
            iconBg: const Color(0xFFE0F2FE),
            iconColor: const Color(0xFF0284C7),
            title: isHindi ? 'उपलब्ध बेड' : 'Available Beds',
            value: '${center.emergencyBeds}',
            subtitle: '/ ${center.bedsTotal} ${isHindi ? 'कुल' : 'total'}',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            icon: Icons.medical_services_rounded,
            iconBg: const Color(0xFFDCFCE7),
            iconColor: const Color(0xFF16A34A),
            title: isHindi ? 'ड्यूटी पर डॉक्टर' : 'Doctors On Duty',
            value: '${center.doctorsOnDuty}',
            subtitle: isHindi ? 'सक्रिय' : 'active',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            icon: Icons.emergency_rounded,
            iconBg: const Color(0xFFFEE2E2),
            iconColor: const Color(0xFFEF4444),
            title: isHindi ? 'एम्बुलेंस' : 'Ambulances',
            value: '${center.ambulanceUnits}',
            subtitle: isHindi ? 'उपलब्ध' : 'available',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return _buildSection(
      title: isHindi ? 'संपर्क करें' : 'Contact',
      icon: Icons.call_rounded,
      child: Column(
        children: [
          if (center.phone.isNotEmpty)
            _buildInfoRow(
              icon: Icons.phone_rounded,
              iconColor: const Color(0xFF16A34A),
              label: isHindi ? 'मुख्य नंबर' : 'Main Number',
              value: center.phone,
            ),
          if (center.emergencyHelpline.isNotEmpty &&
              center.emergencyHelpline != center.phone) ...[
            const SizedBox(height: 10),
            _buildInfoRow(
              icon: Icons.emergency_rounded,
              iconColor: const Color(0xFFEF4444),
              label: isHindi ? 'इमरजेंसी हेल्पलाइन' : 'Emergency Helpline',
              value: center.emergencyHelpline,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpecialtiesCard() {
    return _buildSection(
      title: isHindi ? 'विशेषताएं' : 'Specialties',
      icon: Icons.star_rounded,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: center.specialties
            .map(
              (s) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Text(
                  s,
                  style: const TextStyle(
                    color: Color(0xFF1D4ED8),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildServicesCard() {
    return _buildSection(
      title: isHindi ? 'सेवाएं और सुविधाएं' : 'Services & Amenities',
      icon: Icons.local_hospital_rounded,
      child: Column(
        children: [
          _buildServiceRow(
            icon: Icons.volunteer_activism_rounded,
            label: isHindi ? 'मुफ्त इलाज' : 'Free Treatment',
            available: center.freeTreatmentAvailable,
          ),
          const SizedBox(height: 8),
          _buildServiceRow(
            icon: Icons.medication_rounded,
            label: isHindi ? 'मुफ्त दवाइयां' : 'Free Medicines',
            available: center.freeMedicinesAvailable,
          ),
          const SizedBox(height: 8),
          _buildServiceRow(
            icon: Icons.restaurant_rounded,
            label: isHindi ? 'खाना वितरण' : 'Food Distribution',
            available: center.foodDistribution,
          ),
          const SizedBox(height: 8),
          _buildServiceRow(
            icon: Icons.bloodtype_rounded,
            label: isHindi ? 'ब्लड बैंक' : 'Blood Bank',
            available: center.bloodBankAvailable,
          ),
          if (center.freeMedicinesNote.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 16, color: Color(0xFF16A34A)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      center.freeMedicinesNote,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF166534),
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWaterborneCard() {
    return _buildSection(
      title: isHindi ? 'जलजनित रोग उपचार' : 'Waterborne Disease Treatment',
      icon: Icons.water_drop_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: center.waterborneDiseasesTreated
                .map(
                  (d) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFEFF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFA5F3FC)),
                    ),
                    child: Text(
                      d,
                      style: const TextStyle(
                        color: Color(0xFF0E7490),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          if (center.waterborneDiseaseNote.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFECFEFF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFA5F3FC)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 16, color: Color(0xFF0E7490)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      center.waterborneDiseaseNote,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF164E63),
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDisasterServicesCard() {
    return _buildSection(
      title: isHindi ? 'आपदा सेवाएं' : 'Disaster Services',
      icon: Icons.shield_rounded,
      child: Column(
        children: center.disasterServices
            .map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF9C3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.check_circle_rounded,
                          size: 16, color: Color(0xFFCA8A04)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildAddressCard() {
    return _buildSection(
      title: isHindi ? 'पता और स्थान' : 'Address & Location',
      icon: Icons.place_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (center.address.isNotEmpty)
            _buildInfoRow(
              icon: Icons.location_on_rounded,
              iconColor: const Color(0xFF0284C7),
              label: isHindi ? 'पूरा पता' : 'Full Address',
              value: center.address,
            ),
          if (center.latitude != 0 && center.longitude != 0) ...[
            const SizedBox(height: 10),
            _buildInfoRow(
              icon: Icons.my_location_rounded,
              iconColor: const Color(0xFF9333EA),
              label: isHindi ? 'निर्देशांक' : 'Coordinates',
              value:
                  '${center.latitude.toStringAsFixed(4)}° N, ${center.longitude.toStringAsFixed(4)}° E',
            ),
          ],
          if (center.lastUpdated.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildInfoRow(
              icon: Icons.update_rounded,
              iconColor: const Color(0xFF64748B),
              label: isHindi ? 'अपडेट समय' : 'Last Updated',
              value: center.lastUpdated.length > 10
                  ? center.lastUpdated.substring(0, 10)
                  : center.lastUpdated,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: const Color(0xFF1D4ED8)),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFFE2E8F0), height: 1),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServiceRow({
    required IconData icon,
    required String label,
    required bool available,
  }) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: available
                ? const Color(0xFFDCFCE7)
                : const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            available ? Icons.check_rounded : Icons.close_rounded,
            size: 16,
            color: available
                ? const Color(0xFF16A34A)
                : const Color(0xFFDC2626),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon,
            size: 16,
            color: available
                ? const Color(0xFF16A34A)
                : const Color(0xFF94A3B8)),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: available
                ? const Color(0xFF0F172A)
                : const Color(0xFF94A3B8),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
