import sys

file_path = 'c:/Users/vishal/Downloads/ResQsheild-main/backend_python/app/api/v1/predict.py'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

target = '    val = float(nearest.get("value") or 0.0)'

replacement = """    val = float(nearest.get("value") or 0.0)
    
    # --- LIVE DATA INJECTION ---
    if nearest.get("kind") == "rainfall":
        try:
            import httpx
            url = f"https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}&current=precipitation"
            resp = httpx.get(url, timeout=3.0)
            if resp.status_code == 200:
                data = resp.json()
                live_val = data.get("current", {}).get("precipitation")
                if live_val is not None:
                    val = float(live_val)
                    nearest["value"] = val
                    nearest["source"] = "Open-Meteo Live API"
                    
                    # Optional: recalculate z-score roughly if we wanted, 
                    # but for ML model, raw value is key feature.
        except Exception:
            pass
    # ---------------------------"""

if target in content:
    new_content = content.replace(target, replacement)
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print("Patched successfully!")
else:
    print("Could not find target string!")
