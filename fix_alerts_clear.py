import sys
import re

file_path = 'lib/screens/citizen/citizen_dashboard_screen.dart'

with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
    content = f.read()

# I want to inject the reset logic. 
# It's better to add a helper function `_resetAlertsForNewLocation()` and call it.
# Actually, I can just modify `_fetchBackendAlerts` to NOT just append.
# Or better, just add:
reset_code = """
  void _resetAlertsForNewLocation() {
    setState(() {
      _activeAlerts = [
        {
          'title': 'NO ACTIVE ALERTS - SAFE',
          'titleHi': '\\u0915\\u094b\\u0908 \\u0938\\u0915\\u094d\\u0930\\u093f\\u092f \\u0905\\u0932\\u0930\\u094d\\u091f \\u0928\\u0939\\u0940\\u0902 - \\u0938\\u0941\\u0930\\u0915\\u094d\\u0937\\u093f\\u0924',
          'distance': 'Fetching location data...',
          'distanceHi': '\\u0938\\u094d\\u0925\\u093e\\u0928 \\u0921\\u0947\\u091f\\u093e \\u092a\\u094d\\u0930\\u093e\\u092a\\u094d\\u0924 \\u0915\\u0930 \\u0930\\u0939\\u093e \\u0939\\u0948...',
          'time': 'Just now',
          'timeHi': '\\u0905\\u092d\\u0940-\\u0905\\u092d\\u0940',
          'impact': 'You are in a safe zone.',
          'impactHi': '\\u0906\\u092a \\u0938\\u0941\\u0930\\u0915\\u094d\\u0937\\u093f\\u0924 \\u0915\\u094d\\u0937\\u0947\\u0924\\u094d\\u0930 \\u092e\\u0947\\u0902 \\u0939\\u0948\\u0902\\u0964',
          'badge': 'SAFE',
          'badgeHi': '\\u0938\\u0941\\u0930\\u0915\\u094d\\u0937\\u093f\\u0924',
          'issued': 'System',
          'issuedHi': '\\u0938\\u093f\\u0938\\u094d\\u091f\\u092e',
          'district': 'Fetching...',
          'districtHi': '\\u092a\\u094d\\u0930\\u093e\\u092a\\u094d\\u0924 \\u0915\\u0930 \\u0930\\u0939\\u093e \\u0939\\u0948...',
          'riskLevel': 'Risk Level: SAFE',
          'riskLevelHi': '\\u091c\\u094b\\u0916\\u093f\\u092e \\u0938\\u094d\\u0924\\u0930: \\u0938\\u0941\\u0930\\u0915\\u094d\\u0937\\u093f\\u0924',
          'riskStep': 1,
          'color': const Color(0xFF22C55E),
        }
      ];
      _activeAlertIndex = 0;
    });
  }
"""

with open(file_path, 'rb') as f:
    lines = f.readlines()

new_lines = []
for i, line in enumerate(lines):
    if b'Future<void> _fetchBackendAlerts' in line:
        new_lines.append(reset_code.encode('utf-8'))
        
    if b'await _fetchBackendAlerts(lat, lng);' in line:
        new_lines.append(b"      _resetAlertsForNewLocation();\n")
        
    if b'_fetchBackendAlerts(position.latitude, position.longitude);' in line:
        new_lines.append(b"      _resetAlertsForNewLocation();\n")
        
    new_lines.append(line)

with open(file_path, 'wb') as f:
    f.writelines(new_lines)

print('Done!')
