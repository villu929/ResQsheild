import re

with open('lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Remove mock classes
content = re.sub(r'class _SosItem \{.*?\n\}\n', '', content, flags=re.DOTALL)
content = re.sub(r'class _RescueTeam \{.*?\n\}\n', '', content, flags=re.DOTALL)
content = re.sub(r'class _ShelterItem \{.*?\n\}\n', '', content, flags=re.DOTALL)

# 2. Remove mock lists declarations
content = re.sub(r'late List<_SosItem> _sosList;\n', '', content)
content = re.sub(r'late List<_RescueTeam> _rescueTeams;\n', '', content)
content = re.sub(r'late List<_ShelterItem> _shelters;\n', '', content)

# 3. Replace _initData
content = re.sub(r'void _initData\(\) \{.*?\n  \}', '''void _initData() {
    _actionLogs = [
      '19:42 — Evacuation order broadcast issued for Mawphlang Sector by Capt. R. Sharma',
      '19:37 — Team 02 (SDRF Bravo) assigned to SOS #284 (Medical Emergency)',
      '19:30 — Shelter B (St. Anthony Relief Hall) activated at 92% capacity',
      '19:18 — Emergency multi-channel alert sent via App + SMS + Siren to 21,400 citizens',
      '19:04 — Main Valley Bridge closed due to high water velocity & structural inspection',
      '18:55 — Umiam River level reached 7.42m (+18 cm/hr rise rate trigger)',
    ];
  }''', content, flags=re.DOTALL)

# 4. Replace List usages
content = content.replace('_sosList', 'IncidentCoordinator.instance.sosRequests')
content = content.replace('_rescueTeams', 'IncidentCoordinator.instance.responderTeams')
content = content.replace('_shelters', 'IncidentCoordinator.instance.shelters')

# 5. Fix property access mapping
content = content.replace('team.members,', 'team.membersCount,')
content = content.replace('team.boats,', 'team.boatCount,')
content = content.replace('team.ambulances,', 'team.ambulanceCount,')
content = content.replace('team.mission', 'team.currentMissionId ?? \"Standby\"')
content = content.replace('team.eta', 'team.etaEstimate')
content = content.replace('team.location', '\", \"')

content = content.replace('shelter.coords.latitude', 'shelter.latitude')
content = content.replace('shelter.coords.longitude', 'shelter.longitude')
content = content.replace('shelter.coords', 'LatLng(shelter.latitude, shelter.longitude)')
content = content.replace('shelter.food,', 'shelter.foodDetails,')
content = content.replace('shelter.water,', 'shelter.waterDetails,')
content = content.replace('shelter.medical', 'shelter.medicalAvailable')
content = content.replace('shelter.statusColor', 'CmdColors.safeGreen') # Fallback

with open('lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Python script executed successfully.")
