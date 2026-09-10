import 'package:flutter/material.dart';

class ResourceShelterMapScreen extends StatefulWidget {
  const ResourceShelterMapScreen({super.key});

  @override
  State<ResourceShelterMapScreen> createState() => _ResourceShelterMapScreenState();
}

class _ResourceShelterMapScreenState extends State<ResourceShelterMapScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Calling ${t.commander}: ${t.contact}'))),
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

  // 2. Shelters Tab
  Widget _buildSheltersTab() {
    final shelters = [
      _Shelter(
        name: 'Govt. Model Higher Secondary School',
        location: 'Aluva Town Central',
        occupied: 480,
        totalCapacity: 500,
        status: 'ALMOST FULL',
        statusColor: const Color(0xFFEA580C),
        foodAvailable: true,
        waterAvailable: true,
        coordinator: 'K. S. Varma (0484-242231)',
      ),
      _Shelter(
        name: 'St. Mary Community Auditorium',
        location: 'Paravur Road, Aluva',
        occupied: 320,
        totalCapacity: 350,
        status: 'ALMOST FULL',
        statusColor: const Color(0xFFEA580C),
        foodAvailable: true,
        waterAvailable: true,
        coordinator: 'Sister Teresa (0484-263341)',
      ),
      _Shelter(
        name: 'Municipal Indoor Sports Complex',
        location: 'Kalamassery Highground',
        occupied: 340,
        totalCapacity: 800,
        status: 'AVAILABLE',
        statusColor: const Color(0xFF16A34A),
        foodAvailable: true,
        waterAvailable: true,
        coordinator: 'Municipal Officer (0484-284451)',
      ),
      _Shelter(
        name: 'Union Christian College Relief Camp',
        location: 'UC College Post, Aluva',
        occupied: 200,
        totalCapacity: 200,
        status: 'FULL',
        statusColor: const Color(0xFFDC2626),
        foodAvailable: true,
        waterAvailable: false,
        coordinator: 'Camp Lead Roy (0484-290011)',
      ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: shelters.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _shelterCard(shelters[i]),
    );
  }

  Widget _shelterCard(_Shelter s) {
    final pct = (s.occupied / s.totalCapacity).clamp(0.0, 1.0);

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
                    Text(s.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: Color(0xFF0F172A))),
                    Text(s.location, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: s.statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(s.status, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: s.statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('Occupancy: ${s.occupied} / ${s.totalCapacity}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
              const Spacer(),
              Text('${(pct * 100).toInt()}% Capacity', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: s.statusColor)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: const Color(0xFFE2E8F0),
              color: s.statusColor,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _supplyTag(Icons.restaurant_rounded, 'Food Supply', s.foodAvailable),
              const SizedBox(width: 8),
              _supplyTag(Icons.water_drop_rounded, 'Clean Water', s.waterAvailable),
              const Spacer(),
              Text(s.coordinator.split(' ').first, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _supplyTag(IconData icon, String label, bool ok) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: ok ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
        const SizedBox(width: 3),
        Text(
          ok ? label : 'No $label',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: ok ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
        ),
      ],
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
}

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

class _Shelter {
  final String name;
  final String location;
  final int occupied;
  final int totalCapacity;
  final String status;
  final Color statusColor;
  final bool foodAvailable;
  final bool waterAvailable;
  final String coordinator;

  _Shelter({
    required this.name,
    required this.location,
    required this.occupied,
    required this.totalCapacity,
    required this.status,
    required this.statusColor,
    required this.foodAvailable,
    required this.waterAvailable,
    required this.coordinator,
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
