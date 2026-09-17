const express = require('express');
const router = express.Router();
const landslideZones = require('../data/landslide_zones.json');
const { matchesFilter } = require('../utils/helpers');

// GET /api/landslides/zones
router.get('/zones', (req, res) => {
  const { state, riskLevel } = req.query;
  let results = landslideZones;
  if (state) results = results.filter((z) => matchesFilter(z.state, state));
  if (riskLevel) results = results.filter((z) => z.riskLevel.toUpperCase() === riskLevel.toUpperCase());

  res.json({ success: true, data: results, count: results.length, timestamp: new Date().toISOString() });
});

// GET /api/landslides/alerts — Active high-risk zones
router.get('/alerts', (_req, res) => {
  const alerts = landslideZones.filter((z) => z.riskLevel === 'VERY_HIGH' || z.riskLevel === 'HIGH');
  res.json({ success: true, data: alerts, count: alerts.length, timestamp: new Date().toISOString() });
});

// GET /api/landslides/historical
router.get('/historical', (_req, res) => {
  const historical = landslideZones.map((z) => ({
    id: z.id,
    name: z.name,
    state: z.state,
    riskLevel: z.riskLevel,
    lastMajorEvent: z.lastMajorEvent,
    affectedVillages: z.affectedVillages,
    mitigationMeasures: z.mitigationMeasures,
  }));
  res.json({ success: true, data: historical, timestamp: new Date().toISOString() });
});

module.exports = router;
