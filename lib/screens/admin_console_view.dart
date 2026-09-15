import 'package:flutter/material.dart';
import 'admin_tabs/overview_tab.dart';
import 'admin_tabs/sensors_tab.dart';
import 'admin_tabs/satellite_tab.dart';
import 'admin_tabs/alerts_tab.dart';

class AdminConsoleView extends StatefulWidget {
  const AdminConsoleView({super.key});

  @override
  State<AdminConsoleView> createState() => _AdminConsoleViewState();
}

class _AdminConsoleViewState extends State<AdminConsoleView> {
  int _selectedTabIndex = 0;
  int _alertBroadcastCount = 14;

  void _showMessage(String msg, {Color bgColor = const Color(0xFF0F172A)}) {
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

  void _showCapBroadcastDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text(
              'CAP Early Warning Override',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        content: const Text(
          'Simulate sending a Common Alerting Protocol (CAP v1.2) emergency payload across all active Citizen & Field Responder devices.',
          style: TextStyle(color: Color(0xFF537392), fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF537392), fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _alertBroadcastCount += 1);
              _showMessage(
                'CAP Emergency Alert payload verified & dispatched to 42,000 devices',
                bgColor: const Color(0xFF7351D8),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7351D8),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text('Execute Broadcast', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: _buildSysadminAppBar(),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _getSelectedTab(),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _getSelectedTab() {
    switch (_selectedTabIndex) {
      case 0:
        return const OverviewTab(key: ValueKey('tab_0'));
      case 1:
        return const SensorsTab(key: ValueKey('tab_1'));
      case 2:
        return const SatelliteTab(key: ValueKey('tab_2'));
      case 3:
        return AlertsTab(
          key: const ValueKey('tab_3'),
          broadcastCount: _alertBroadcastCount,
        );
      default:
        return const OverviewTab(key: ValueKey('tab_0'));
    }
  }

  PreferredSizeWidget _buildSysadminAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 18),
        onPressed: () => Navigator.pop(context),
        tooltip: 'Exit to Role Selection',
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'ResQShield Admin Console',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 15.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F0FC),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Admin Console',
                  style: TextStyle(
                    color: Color(0xFF7351D8),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 12),
              SizedBox(width: 5),
              Text(
                'Telemetry Active • 99.98% SLA',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: IconButton(
            icon: const Icon(Icons.broadcast_on_personal_rounded, color: Color(0xFF7351D8), size: 24),
            onPressed: _showCapBroadcastDialog,
            tooltip: 'Trigger CAP Broadcast',
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 10,
            offset: Offset(0, -4),
          )
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              _buildNavTab(0, Icons.speed_rounded, 'Overview'),
              _buildNavTab(1, Icons.sensors_rounded, 'Sensors'),
              _buildNavTab(2, Icons.satellite_alt_rounded, 'AI Engine'),
              _buildNavTab(3, Icons.list_alt_rounded, 'Logs'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavTab(int index, IconData icon, String label) {
    final bool isSelected = _selectedTabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF3F0FC) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected ? const Color(0xFF7351D8) : const Color(0xFF94A3B8),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF7351D8) : const Color(0xFF94A3B8),
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
