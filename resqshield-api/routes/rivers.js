const express = require('express');
const router = express.Router();
const rivers = require('../data/rivers.json');
const { matchesFilter } = require('../utils/helpers');

// GET /api/rivers — All rivers
router.get('/', (req, res) => {
  const { state, status } = req.query;
  let results = rivers;
  if (state) results = results.filter((r) => matchesFilter(r.state, state));
  if (status) results = results.filter((r) => r.status.toUpperCase() === status.toUpperCase());

  res.json({ success: true, data: results, count: results.length, timestamp: new Date().toISOString() });
});

// GET /api/rivers/:id
router.get('/:id', (req, res) => {
  const river = rivers.find((r) => r.id === req.params.id);
  if (!river) return res.status(404).json({ success: false, error: { message: `River ${req.params.id} not found` } });
  res.json({ success: true, data: river, timestamp: new Date().toISOString() });
});

// GET /api/rivers/:id/observations
router.get('/:id/observations', (req, res) => {
  const river = rivers.find((r) => r.id === req.params.id);
  if (!river) return res.status(404).json({ success: false, error: { message: `River ${req.params.id} not found` } });

  res.json({
    success: true,
    data: {
      riverId: river.id,
      riverName: river.name,
      stationName: river.stationName,
      observations: river.observations,
      dangerLevelM: river.dangerLevelM,
      warningLevelM: river.warningLevelM,
      watchLevelM: river.watchLevelM,
    },
    timestamp: new Date().toISOString(),
  });
});

// GET /api/water-levels — Summary of all water levels (matches existing ApiConstants.waterLevels)
router.get('/water-levels', (_req, res) => {
  const summary = rivers.map((r) => ({
    id: r.id,
    name: r.name,
    station: r.stationName,
    location: r.location,
    state: r.state,
    currentLevelM: r.currentLevelM,
    dangerLevelM: r.dangerLevelM,
    warningLevelM: r.warningLevelM,
    status: r.status,
    trend: r.trend,
    rateOfRise: r.rateOfRise,
    lastUpdated: r.lastUpdated,
  }));

  res.json({ success: true, data: summary, count: summary.length, timestamp: new Date().toISOString() });
});

module.exports = router;
