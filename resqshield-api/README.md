# ResQShield Disaster Relief API

A comprehensive Node.js/Express REST API serving real-time style data on shelters, medical facilities, river levels, rainfall, flood zones, and landslide zones across India. Designed for the ResQShield Flutter App.

**Focus Regions:** Jharkhand and Delhi NCR, plus major pan-India disaster zones.

## Features

- **Shelters API:** Search, filter, and find nearby relief camps, NDRF bases, and emergency shelters.
- **Medical API:** Search and find nearby hospitals, including trauma centers, ICU capacity, and blood banks.
- **Rivers API:** Real-time water level data, trends, and danger thresholds for major rivers (Yamuna, Damodar, Subarnarekha, etc.).
- **Floods & Landslides API:** Active alerts, historical data, and vulnerability zones (GeoJSON format support).
- **Rainfall API:** Detailed rainfall observations.
- **Emergency Contacts:** National, State, and District level helplines.

## Local Development

```bash
# Install dependencies
npm install

# Start the server (Dev Mode)
npm run dev

# Start the server (Production Mode)
npm start
```
The server will run on `http://localhost:3000` by default.

## Deployment Instructions (Railway/Render)

This API is completely stateless and uses JSON files for data storage, making it incredibly easy to deploy for free on services like [Railway](https://railway.app/) or [Render](https://render.com/).

### Option 1: Deploy on Railway (Recommended)
1. Push this `resqshield-api` folder to a new GitHub repository.
2. Go to [Railway.app](https://railway.app/) and log in with GitHub.
3. Click **New Project** -> **Deploy from GitHub repo**.
4. Select your newly created repository.
5. Railway will automatically detect it as a Node.js app, install dependencies using `npm install`, and start it using `npm start`.
6. Once deployed, Railway will give you a public URL (e.g., `resqshield-api-production.up.railway.app`).

### Option 2: Deploy on Render
1. Push to GitHub.
2. Go to [Render.com](https://render.com/), create a new **Web Service**.
3. Connect your repository.
4. Set Build Command to `npm install`.
5. Set Start Command to `npm start`.
6. Render will provide a free `.onrender.com` URL.

## API Endpoints Overview

- `GET /` - API Overview & Health Check
- `GET /api/stats` - Global aggregate statistics
- `GET /api/shelters` - List all shelters (Supports `?state=`, `?city=`)
- `GET /api/shelters/nearby?lat=...&lng=...&radius=25` - Find nearby shelters
- `GET /api/medical` - List medical facilities
- `GET /api/rivers` - River gauge stations and water levels
- `GET /api/floods/live` - Live flood GeoJSON data
- `GET /api/landslides/zones` - Landslide vulnerability zones
- `GET /api/emergency-contacts` - Helplines

## Frontend Integration (Flutter)

To use this with the ResQShield Flutter app, update `ApiConstants.baseUrl` to your deployed URL (or `http://10.0.2.2:3000/api` for Android Emulator).
