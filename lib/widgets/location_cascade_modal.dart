import 'package:flutter/material.dart';
import '../services/location_api_service.dart';

class LocationCascadeModal extends StatefulWidget {
  final bool isHindi;
  final String? currentState;
  final String? currentCity;
  
  const LocationCascadeModal({
    Key? key,
    required this.isHindi,
    this.currentState,
    this.currentCity,
  }) : super(key: key);

  @override
  _LocationCascadeModalState createState() => _LocationCascadeModalState();
}

class _LocationCascadeModalState extends State<LocationCascadeModal> {
  List<String> _states = [];
  List<String> _cities = [];
  
  String? _selectedState;
  String? _selectedCity;
  String _area = '';
  
  bool _isLoadingStates = true;
  bool _isLoadingCities = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedState = widget.currentState;
    _selectedCity = widget.currentCity;
    _fetchStates();
  }

  Future<void> _fetchStates() async {
    setState(() => _isLoadingStates = true);
    final states = await LocationApiService.instance.fetchStates();
    if (mounted) {
      setState(() {
        _states = states;
        _isLoadingStates = false;
      });
      if (_selectedState != null && _states.contains(_selectedState)) {
        _fetchCities(_selectedState!);
      }
    }
  }

  Future<void> _fetchCities(String state) async {
    setState(() {
      _isLoadingCities = true;
      _cities = [];
      if (_selectedState != state) {
        _selectedCity = null;
      }
      _selectedState = state;
    });
    
    final cities = await LocationApiService.instance.fetchCities(state);
    
    if (mounted) {
      setState(() {
        _cities = cities;
        _isLoadingCities = false;
        if (_selectedCity != null && !_cities.contains(_selectedCity)) {
          _selectedCity = null;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedState == null || _selectedCity == null) return;
    
    setState(() => _isSubmitting = true);
    
    final coords = await LocationApiService.instance.fetchCoordinates(
      _selectedState!,
      city: _selectedCity,
    );
    
    if (mounted) {
      setState(() => _isSubmitting = false);
      if (coords != null) {
        String displayName = _selectedCity!;
        if (_area.trim().isNotEmpty) {
          displayName = '${_area.trim()}, $_selectedCity';
        } else {
          displayName = '$_selectedCity, $_selectedState';
        }
        
        Navigator.pop(context, {
          'name': displayName,
          'lat': coords['lat'],
          'lng': coords['lng'],
          'state': _selectedState,
          'city': _selectedCity,
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isHindi ? 'स्थान नहीं मिला' : 'Location coordinates not found'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 12.0,
      ),
      child: Container(
        padding: const EdgeInsets.only(
          top: 24,
          left: 24,
          right: 24,
          bottom: 32,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.isHindi ? 'स्थान चुनें' : 'Select Location',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // State Dropdown
            const Text(
              'State',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 6),
            _isLoadingStates
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    value: _selectedState,
                    hint: Text(widget.isHindi ? 'राज्य चुनें' : 'Select State'),
                    isExpanded: true,
                    decoration: _inputDecoration(),
                    items: _states.map((s) {
                      return DropdownMenuItem(value: s, child: Text(s));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) _fetchCities(val);
                    },
                  ),
            
            const SizedBox(height: 12),
            
            // City Dropdown
            const Text(
              'City',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 6),
            _isLoadingCities
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    value: _selectedCity,
                    hint: Text(widget.isHindi ? 'शहर चुनें' : 'Select City'),
                    isExpanded: true,
                    decoration: _inputDecoration(),
                    items: _cities.map((c) {
                      return DropdownMenuItem(value: c, child: Text(c));
                    }).toList(),
                    onChanged: _selectedState == null
                        ? null
                        : (val) {
                            setState(() => _selectedCity = val);
                          },
                  ),
            
            const SizedBox(height: 12),
            
            // Area TextField
            Text(
              widget.isHindi ? 'क्षेत्र / इलाका (वैकल्पिक)' : 'Area / Locality (Optional)',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 6),
            TextFormField(
              decoration: _inputDecoration().copyWith(
                hintText: widget.isHindi ? 'उदा. सेक्टर 5, अंधेरी पूर्व...' : 'e.g. Sector 5, Andheri East...',
              ),
              onChanged: (val) => _area = val,
            ),
            
            const SizedBox(height: 16),
            
            // Submit Button
            ElevatedButton(
              onPressed: (_selectedState == null || _selectedCity == null || _isSubmitting)
                  ? null
                  : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      widget.isHindi ? 'पुष्टि करें' : 'Confirm Location',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
      ),
    );
  }
}
