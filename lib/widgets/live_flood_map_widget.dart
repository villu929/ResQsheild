import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/flood_data_models.dart';
import '../services/api_constants.dart';
import '../services/flood_api_service.dart';

class LiveFloodMapWidget extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final String locationName;

  const LiveFloodMapWidget({
    super.key,
    this.latitude,
    this.longitude,
    this.locationName = 'Current Location',
  });

  @override
  State<LiveFloodMapWidget> createState() => _LiveFloodMapWidgetState();
}

class _LiveFloodMapWidgetState extends State<LiveFloodMapWidget>
    with SingleTickerProviderStateMixin {
  final FloodApiService _apiService = FloodApiService();
  final MapController _mapController = MapController();

  FloodLiveResponse? _floodData;
  List<FloodFeatureItem> _alertMarkers = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _showInundationLayer = true;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Default fallback center: India center or user location
  LatLng get _effectiveCenter {
    if (widget.latitude != null && widget.longitude != null) {
      return LatLng(widget.latitude!, widget.longitude!);
    }
    // Default to a recognized regional coordinate if GPS is pending
    return const LatLng(23.6102, 85.2799); // Jharkhand regional center
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadData();
  }

  @override
  void didUpdateWidget(covariant LiveFloodMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.latitude != oldWidget.latitude ||
        widget.longitude != oldWidget.longitude) {
      if (widget.latitude != null && widget.longitude != null) {
        _mapController.move(
          LatLng(widget.latitude!, widget.longitude!),
          _mapController.camera.zoom,
        );
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _apiService.fetchLiveFloods(
          lat: widget.latitude,
          lng: widget.longitude,
        ),
        _apiService.fetchGovernmentAlerts(),
        _apiService.fetchLayers(),
      ]);

      if (mounted) {
        setState(() {
          _floodData = results[0] as FloodLiveResponse;
          _alertMarkers = results[1] as List<FloodFeatureItem>;
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  FloodDataStatus get _currentStatus {
    return _apiService.evaluateStatus(
      response: _floodData,
      isLoading: _isLoading,
      hasError: _hasError,
    );
  }

  String _formatUpdatedTime(DateTime? time) {
    if (time == null) return 'NRT Feed';
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 2) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${time.day}/${time.month} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final status = _currentStatus;
    final center = _effectiveCenter;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title + Live Status Badge + Refresh
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Flood Map Overview',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'CEMS GFM Inundation + Real GPS',
                    style: TextStyle(
                      color: const Color(0xFF64748B),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // Dynamic Status Badge
              _buildStatusBadge(status),

              const SizedBox(width: 8),

              // Refresh Button
              GestureDetector(
                onTap: _isLoading ? null : _loadData,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(7),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF0284C7),
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.refresh_rounded,
                          color: Color(0xFF475569),
                          size: 16,
                        ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Map View Container
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: SizedBox(
              height: 210,
              width: double.infinity,
              child: Stack(
                children: [
                  // Actual FlutterMap
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: 10.5,
                      minZoom: 4.0,
                      maxZoom: 16.0,
                    ),
                    children: [
                      // Base OpenStreetMap Tile Layer
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.resqshield.app',
                      ),

                      // Live Flood Inundation WMS-T Raster Layer from Railway backend
                      if (_showInundationLayer)
                        TileLayer(
                          urlTemplate: ApiConstants.floodTileTemplate,
                          userAgentPackageName: 'com.resqshield.app',
                        ),

                      // Markers Layer
                      MarkerLayer(
                        markers: [
                          // Real GPS Location Marker
                          Marker(
                            point: center,
                            width: 50,
                            height: 50,
                            child: AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 34 * _pulseAnimation.value,
                                      height: 34 * _pulseAnimation.value,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF0284C7)
                                            .withValues(alpha: 0.25),
                                      ),
                                    ),
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0284C7),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.3),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.my_location_rounded,
                                        color: Colors.white,
                                        size: 11,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),

                          // Real Government Alert Markers from API
                          for (final alert in _alertMarkers)
                            Marker(
                              point: alert.point,
                              width: 34,
                              height: 34,
                              child: GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${alert.title}: ${alert.description}',
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE11D48),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.3),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  // Inundation Layer Toggle Pill
                  Positioned(
                    top: 10,
                    left: 10,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _showInundationLayer = !_showInundationLayer;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _showInundationLayer
                              ? const Color(0xFF0F172A)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF334155)
                                .withValues(alpha: 0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.water_drop_rounded,
                              size: 12,
                              color: _showInundationLayer
                                  ? const Color(0xFF38BDF8)
                                  : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _showInundationLayer
                                  ? 'Flood Layer ON'
                                  : 'Flood Layer OFF',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _showInundationLayer
                                    ? Colors.white
                                    : const Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Floating Map Controls (Zoom In, Zoom Out, Recenter)
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _mapControlBtn(
                          icon: Icons.add_rounded,
                          onTap: () {
                            _mapController.move(
                              _mapController.camera.center,
                              _mapController.camera.zoom + 1,
                            );
                          },
                        ),
                        const SizedBox(height: 6),
                        _mapControlBtn(
                          icon: Icons.remove_rounded,
                          onTap: () {
                            _mapController.move(
                              _mapController.camera.center,
                              _mapController.camera.zoom - 1,
                            );
                          },
                        ),
                        const SizedBox(height: 6),
                        _mapControlBtn(
                          icon: Icons.my_location_rounded,
                          iconColor: const Color(0xFF0284C7),
                          onTap: () {
                            _mapController.move(center, 12.0);
                          },
                        ),
                      ],
                    ),
                  ),

                  // Error Overlay (if failed)
                  if (_hasError && _floodData == null)
                    Positioned.fill(
                      child: Container(
                        color: Colors.white.withValues(alpha: 0.88),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.cloud_off_rounded,
                                  color: Color(0xFFE11D48),
                                  size: 32,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _errorMessage ?? 'API Connection Failed',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton.icon(
                                  onPressed: _loadData,
                                  icon: const Icon(Icons.refresh, size: 14),
                                  label: const Text('Retry Connection'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0F172A),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    textStyle: const TextStyle(fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Footer: Source Attribution + Updated Time + Legend
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          size: 12,
                          color: Color(0xFF0284C7),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Source: ${_floodData?.meta.source ?? 'CEMS Global Flood Monitoring'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF475569),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Last Synced: ${_formatUpdatedTime(_floodData?.meta.updatedAt ?? _apiService.lastFetchTime)}',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Legend indicators
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _legendDot(const Color(0xFF0284C7), 'GPS'),
                  const SizedBox(width: 8),
                  _legendDot(const Color(0xFF38BDF8), 'Inundation'),
                  if (_alertMarkers.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _legendDot(const Color(0xFFE11D48), 'Alert'),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(FloodDataStatus status) {
    Color bg;
    Color fg;
    String label;
    bool showDot;

    switch (status) {
      case FloodDataStatus.live:
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        label = 'Live GFM';
        showDot = true;
        break;
      case FloodDataStatus.stale:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        label = 'Stale Sync';
        showDot = false;
        break;
      case FloodDataStatus.loading:
        bg = const Color(0xFFE0F2FE);
        fg = const Color(0xFF0369A1);
        label = 'Connecting...';
        showDot = false;
        break;
      case FloodDataStatus.empty:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF475569);
        label = 'No Active Flood';
        showDot = false;
        break;
      case FloodDataStatus.error:
        bg = const Color(0xFFFFE4E6);
        fg = const Color(0xFFBE123C);
        label = 'Offline';
        showDot = false;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: fg,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapControlBtn({
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 17,
          color: iconColor ?? const Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          text,
          style: const TextStyle(
            fontSize: 9,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
