import 'package:flutter/material.dart';
import '../../widgets/admin/shared_admin_widgets.dart';

class SatelliteTab extends StatelessWidget {
  const SatelliteTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(14),
      children: [
        // 1. Satellite Ingest Telemetry Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A0F172A),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.satellite_alt_rounded,
                      color: Color(0xFF0284C7),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SATELLITE DATA PIPELINE',
                          style: TextStyle(
                            color: Color(0xFF0284C7),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Sentinel-1 / Sentinel-2 Feed',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const AnimatedStatusChip(
                    label: 'ONLINE',
                    color: Color(0xFF0E5C38),
                    icon: Icons.circle,
                  ),
                ],
              ),
              const Divider(height: 32, color: Color(0xFFF1F5F9)),

              // Pipeline Timeline
              _buildTimelineStep(
                icon: Icons.link_rounded,
                title: 'Data Connection',
                description: 'Connected to NRSC / ESA Hub',
                isCompleted: true,
                isLast: false,
              ),
              _buildTimelineStep(
                icon: Icons.cloud_download_rounded,
                title: 'Latest Imagery',
                description: 'SAR Cloud-Penetrating Ingested',
                isCompleted: true,
                isLast: false,
              ),
              _buildTimelineStep(
                icon: Icons.grid_on_rounded,
                title: 'Ortho Processing',
                description: 'Sub-meter Gridding Complete',
                isCompleted: true,
                isLast: false,
              ),
              _buildTimelineStep(
                icon: Icons.water_rounded,
                title: 'Flood Extent Detection',
                description: 'Water Surface Mask Active',
                isCompleted: true,
                isLast: false,
              ),
              _buildTimelineStep(
                icon: Icons.layers_rounded,
                title: 'Change Detection',
                description: 'Damodar Basin Masked (+18% Δ)',
                isCompleted: true,
                isLast: true,
              ),

              const Divider(height: 24, color: Color(0xFFF1F5F9)),
              Row(
                children: const [
                  Icon(Icons.schedule_rounded, size: 16, color: Color(0xFF64748B)),
                  SizedBox(width: 8),
                  Text(
                    'Last Update: Just now',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 2. AI Engine Status Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A0F172A),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F0FC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.psychology_rounded,
                      color: Color(0xFF7351D8),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI PREDICTION ENGINE',
                          style: TextStyle(
                            color: Color(0xFF7351D8),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'ResQShield-Flood-v2.1',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const AnimatedStatusChip(
                    label: 'INFERENCE',
                    color: Color(0xFF0E5C38),
                    icon: Icons.play_arrow_rounded,
                  ),
                ],
              ),
              const Divider(height: 32, color: Color(0xFFF1F5F9)),

              _buildPipelineStatusItem('Flood Depth Prediction', 'Running (3-hr ahead forecast)'),
              _buildPipelineStatusItem('GLOF Analysis', 'Running (Upper glacial lakes normal)'),
              _buildPipelineStatusItem('Landslide Detection', 'Running (Slope instability scan)'),
              _buildPipelineStatusItem('Risk Classification', 'Running (Triage category matrix)'),
              const Divider(height: 24, color: Color(0xFFF1F5F9)),

              Row(
                children: const [
                  Icon(Icons.bolt_rounded, size: 18, color: Color(0xFF7351D8)),
                  SizedBox(width: 6),
                  Text(
                    'Last Prediction Run: 32 sec ago (0 pipeline errors)',
                    style: TextStyle(
                      color: Color(0xFF7351D8),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 3. AI Insights Summary
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F0F172A),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.auto_awesome_rounded, color: Color(0xFFFCD34D), size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Latest AI Operational Summary',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInsightBullet('Damodar Basin water accumulation is rising at 0.5m/hr, expected to plateau within 2 hours based on SAR imagery.'),
              _buildInsightBullet('Soil saturation at Catchment Sector 4 is critical (>85%). High likelihood of minor landslides in the next 12 hours.'),
              _buildInsightBullet('Downstream evacuation routes (NH-18) currently show no inundation risk for the next 24 hours.'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineStep({
    required IconData icon,
    required String title,
    required String description,
    required bool isCompleted,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isCompleted ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineStatusItem(String label, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 14),
          const SizedBox(width: 6),
          Text(
            status,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.circle, color: Color(0xFFFCD34D), size: 8),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 12.5,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
