import sys

file_path = 'lib/screens/citizen/citizen_dashboard_screen.dart'

with open(file_path, 'rb') as f:
    lines = f.readlines()

# Find the start of _activeAlerts
start_idx = -1
for i, line in enumerate(lines):
    if b'List<Map<String, dynamic>> _activeAlerts = [' in line:
        start_idx = i
        break

if start_idx == -1:
    print("Could not find _activeAlerts initialization")
    sys.exit(1)

# Find the end of _activeAlerts
end_idx = -1
for i in range(start_idx + 1, len(lines)):
    if b'];' in lines[i] and b'// Notifications List' in lines[i+2]:
        end_idx = i
        break

if end_idx == -1:
    # Just try to find `  ];`
    for i in range(start_idx + 1, len(lines)):
        if lines[i].strip() == b'];':
            end_idx = i
            break

if end_idx == -1:
    print("Could not find end of _activeAlerts initialization")
    sys.exit(1)

new_lines = lines[:start_idx]

safe_alert_code = b"""  List<Map<String, dynamic>> _activeAlerts = [
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
"""

new_lines.append(safe_alert_code)
new_lines.extend(lines[end_idx + 1:])

with open(file_path, 'wb') as f:
    f.writelines(new_lines)
print('Done!')
