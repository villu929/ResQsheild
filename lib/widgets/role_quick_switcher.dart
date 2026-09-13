import 'dart:async';
import 'package:flutter/material.dart';
import '../models/incident_models.dart';
import '../services/incident_coordinator.dart';
import '../screens/citizen/citizen_dashboard_screen.dart';
import '../screens/home_screen.dart';
import '../screens/field_responder_view.dart';

enum CurrentDashboardRole { citizen, authority, fieldResponder }

/// A floating live synchronizer and role quick switcher bar
class RoleQuickSwitcherOverlay extends StatefulWidget {
  final CurrentDashboardRole currentRole;
  final Widget child;

  const RoleQuickSwitcherOverlay({
    super.key,
    required this.currentRole,
    required this.child,
  });

  @override
  State<RoleQuickSwitcherOverlay> createState() =>
      _RoleQuickSwitcherOverlayState();
}

class _RoleQuickSwitcherOverlayState extends State<RoleQuickSwitcherOverlay> {
  bool _expanded = false;
  LiveEvent? _latestEvent;
  StreamSubscription<LiveEvent>? _eventSub;

  @override
  void initState() {
    super.initState();
    _eventSub = IncidentCoordinator.instance.eventStream.listen((event) {
      if (mounted) {
        setState(() {
          _latestEvent = event;
        });
        // Auto-show mini toast for 4 seconds
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted && _latestEvent == event) {
            setState(() => _latestEvent = null);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
  }

  void _switchRole(CurrentDashboardRole targetRole) {
    if (targetRole == widget.currentRole) {
      setState(() => _expanded = false);
      return;
    }

    Widget nextScreen;
    switch (targetRole) {
      case CurrentDashboardRole.citizen:
        nextScreen = const CitizenDashboardScreen();
        break;
      case CurrentDashboardRole.authority:
        nextScreen = const HomeScreen();
        break;
      case CurrentDashboardRole.fieldResponder:
        nextScreen = const FieldResponderView();
        break;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a1, a2) => nextScreen,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,

        // ── Real-Time Incident Toast Notification ────────────────────────────
        if (_latestEvent != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF38BDF8),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _latestEvent!.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _latestEvent!.message,
                            style: const TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 11,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16, color: Colors.white70),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => setState(() => _latestEvent = null),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // ── Role Quick Switcher Floating Button ──────────────────────────────
        Positioned(
          bottom: 72,
          right: 14,
          child: Material(
            color: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_expanded) ...[
                  _buildRoleBtn(
                    role: CurrentDashboardRole.citizen,
                    title: 'Citizen App',
                    icon: Icons.person_pin_circle_rounded,
                    color: const Color(0xFF0284C7),
                    isActive: widget.currentRole == CurrentDashboardRole.citizen,
                  ),
                  const SizedBox(height: 8),
                  _buildRoleBtn(
                    role: CurrentDashboardRole.authority,
                    title: 'Authority Command',
                    icon: Icons.admin_panel_settings_rounded,
                    color: const Color(0xFF2563EB),
                    isActive:
                        widget.currentRole == CurrentDashboardRole.authority,
                  ),
                  const SizedBox(height: 8),
                  _buildRoleBtn(
                    role: CurrentDashboardRole.fieldResponder,
                    title: 'Field Responder',
                    icon: Icons.local_fire_department_rounded,
                    color: const Color(0xFF16A34A),
                    isActive: widget.currentRole ==
                        CurrentDashboardRole.fieldResponder,
                  ),
                  const SizedBox(height: 10),
                ],

                // Toggle FAB
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _currentRoleLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _expanded
                              ? Icons.close_rounded
                              : Icons.swap_horiz_rounded,
                          size: 16,
                          color: const Color(0xFF38BDF8),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String get _currentRoleLabel {
    switch (widget.currentRole) {
      case CurrentDashboardRole.citizen:
        return 'View: Citizen';
      case CurrentDashboardRole.authority:
        return 'View: Authority';
      case CurrentDashboardRole.fieldResponder:
        return 'View: Responder';
    }
  }

  Widget _buildRoleBtn({
    required CurrentDashboardRole role,
    required String title,
    required IconData icon,
    required Color color,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () => _switchRole(role),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.white : const Color(0xFF475569),
            width: isActive ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check, size: 14, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }
}
