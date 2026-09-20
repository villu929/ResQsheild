import json
with open('c:/Users/vishal/Downloads/ResQsheild-main/backend_python/data/processed/risk/station_risk.json', 'r', encoding='utf-8') as f:
    data = json.load(f)
for row in data:
    if row.get('z_score', 0) > 1.5 or row.get('value', 0) > 150:
        print(f"Location: {row.get('station', 'Unknown')}, District: {row.get('district', 'Unknown')}, Lat: {row.get('latitude')}, Lon: {row.get('longitude')}, Value: {row.get('value')}")
