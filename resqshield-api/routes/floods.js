const express = require('express');
const router = express.Router();
const floodZones = require('../data/flood_zones.json');
const { matchesFilter } = require('../utils/helpers');

// GET /api/floods/live — GeoJSON features (matches FloodLiveResponse.fromJson)
router.get('/live', (req, res) => {
  const features = floodZones.map((fz) => ({
    type: 'Feature',
    id: fz.id,
    geometry: {
      type: 'Point',
      coordinates: [fz.longitude, fz.latitude],
    },
    properties: {
      id: fz.id,
      title: fz.name,
      description: fz.description,
      severity: fz.severity,
      level: fz.severity,
      status: fz.status,
      type: fz.type,
      state: fz.state,
      districts: fz.districts,
      affectedPopulation: fz.affectedPopulation,
      radius_km: fz.radius_km,
    },
  }));

  res.json({
    type: 'FeatureCollection',
    features,
    meta: {
      source: 'ResQShield Flood Monitoring — CWC + NDMA + State SDMAs',
      data_type: 'observed flood extent + alert zones',
      status: 'near_real_time',
      raster_layer: true,
      note: 'Combined flood zone data for Jharkhand, Delhi and pan-India',
      updated_at: new Date().toISOString(),
    },
    timestamp: new Date().toISOString(),
  });
});

// GET /api/floods/alerts — Active government alerts
router.get('/alerts', (req, res) => {
  const activeAlerts = floodZones
    .filter((fz) => fz.status === 'active' && (fz.severity === 'danger' || fz.severity === 'warning'))
    .map((fz) => ({
      type: 'Feature',
      id: fz.id,
      geometry: { type: 'Point', coordinates: [fz.longitude, fz.latitude] },
      properties: {
        id: fz.id,
        title: `${fz.severity.toUpperCase()} ALERT: ${fz.name}`,
        description: fz.description,
        severity: fz.severity,
        event: fz.type.replace(/_/g, ' '),
        instruction: `Evacuation advisory for ${fz.districts.join(', ')}. Contact local SDRF/NDRF.`,
        state: fz.state,
        districts: fz.districts,
      },
    }));

  res.json({
    type: 'FeatureCollection',
    features: activeAlerts,
    meta: {
      source: 'SACHET / NDMA / CWC Alert System',
      status: 'active',
      updated_at: new Date().toISOString(),
    },
    timestamp: new Date().toISOString(),
  });
});

// GET /api/floods/sources
router.get('/sources', (req, res) => {
  res.json({
    success: true,
    data: {
      sources: [
        { name: 'Central Water Commission (CWC)', type: 'River water levels & flood forecasting', url: 'https://cwc.gov.in', status: 'active' },
        { name: 'India Meteorological Department (IMD)', type: 'Rainfall & weather warnings', url: 'https://mausam.imd.gov.in', status: 'active' },
        { name: 'National Disaster Management Authority (NDMA)', type: 'Government alerts & advisories', url: 'https://ndma.gov.in', status: 'active' },
        { name: 'SACHET Early Warning Platform', type: 'Multi-hazard early warning dissemination', url: 'https://sachet.ndma.gov.in', status: 'active' },
        { name: 'CEMS Global Flood Monitoring (GFM)', type: 'Satellite flood inundation mapping', url: 'https://global-flood.emergency.copernicus.eu', status: 'active' },
        { name: 'State Disaster Management Authorities', type: 'State-level alerts (JSDMA, DDMA, etc.)', status: 'active' },
      ],
    },
    timestamp: new Date().toISOString(),
  });
});

// GET /api/floods/zones — Flood-prone zone mapping
router.get('/zones', (req, res) => {
  const { state } = req.query;
  let results = floodZones;
  if (state) results = results.filter((fz) => matchesFilter(fz.state, state));

  res.json({ success: true, data: results, count: results.length, timestamp: new Date().toISOString() });
});

module.exports = router;
