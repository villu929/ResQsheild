const express = require('express');
const router = express.Router();
const rainfallData = require('../data/rainfall.json');
const { matchesFilter } = require('../utils/helpers');

// GET /api/rainfall — All rainfall data
router.get('/', (req, res) => {
  const { state, status } = req.query;
  let results = rainfallData;
  if (state) results = results.filter((r) => matchesFilter(r.state, state));
  if (status) results = results.filter((r) => r.status.toUpperCase() === status.toUpperCase());

  res.json({ success: true, data: results, count: results.length, timestamp: new Date().toISOString() });
});

// GET /api/rainfall/alerts — Areas with HEAVY or DANGER rainfall
router.get('/alerts', (_req, res) => {
  const alerts = rainfallData.filter((r) => r.status === 'HEAVY' || r.status === 'DANGER');
  res.json({ success: true, data: alerts, count: alerts.length, timestamp: new Date().toISOString() });
});

// GET /api/rainfall/:id
router.get('/:id', (req, res) => {
  const area = rainfallData.find((r) => r.id === req.params.id);
  if (!area) return res.status(404).json({ success: false, error: { message: `Rainfall area ${req.params.id} not found` } });
  res.json({ success: true, data: area, timestamp: new Date().toISOString() });
});

module.exports = router;
