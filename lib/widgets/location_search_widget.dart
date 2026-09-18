import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/location_service.dart';

class LocationSearchWidget extends StatefulWidget {
  const LocationSearchWidget({super.key});

  @override
  State<LocationSearchWidget> createState() => _LocationSearchWidgetState();
}

class _LocationSearchWidgetState extends State<LocationSearchWidget> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focus = FocusNode();
  List<_Place> _suggestions = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final name = LocationService.instance.activeName;
    if (name != null) _ctrl.text = name;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().length < 3) {
      setState(() => _suggestions = []);
      return;
    }
    setState(() => _loading = true);
    try {
      final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&countrycodes=in');
      final resp = await http
          .get(uri, headers: {'User-Agent': 'ResQshieldApp'})
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final List data = json.decode(resp.body);
        setState(() {
          _suggestions = data
              .map((e) => _Place(
                    name: e['display_name']?.toString() ?? '',
                    lat: double.tryParse(e['lat']?.toString() ?? '') ?? 0,
                    lng: double.tryParse(e['lon']?.toString() ?? '') ?? 0,
                  ))
              .where((p) => p.lat != 0 && p.lng != 0)
              .toList();
        });
      }
    } catch (_) {
      setState(() => _suggestions = []);
    } finally {
      setState(() => _loading = false);
    }
  }

  void _select(_Place place) {
    final parts = place.name.split(', ');
    final shortName = parts.length >= 2 ? '${parts[0]}, ${parts[1]}' : parts[0];
    _ctrl.text = shortName;
    _focus.unfocus();
    setState(() => _suggestions = []);
    LocationService.instance.setManualLocation(place.lat, place.lng, shortName);
  }

  void _clear() {
    _ctrl.clear();
    setState(() => _suggestions = []);
    LocationService.instance.clearManualLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 42,
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFF93C5FD), width: 1.2),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              const Icon(Icons.location_on_rounded, size: 18, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focus,
                  onChanged: _search,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                  decoration: const InputDecoration(
                    hintText: 'Search location (e.g. Guwahati, Rohini...)',
                    hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
                  ),
                )
              else if (_ctrl.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),
                  onPressed: _clear,
                ),
            ],
          ),
        ),
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 2, 16, 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD6E4F0)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 3))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _suggestions
                  .map((p) => InkWell(
                        onTap: () => _select(p),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              const Icon(Icons.place_outlined, size: 16, color: Color(0xFF0284C7)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  p.name,
                                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF0F172A)),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }
}

class _Place {
  final String name;
  final double lat;
  final double lng;
  const _Place({required this.name, required this.lat, required this.lng});
}