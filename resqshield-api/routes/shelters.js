const express = require('express');
const router = express.Router();
const { haversineKm, paginate, matchesFilter, formatDistance } = require('../utils/helpers');

// Load all shelter data
const sheltersJharkhand = require('../data/shelters_jharkhand.json');
const sheltersDelhi = require('../data/shelters_delhi.json');
const sheltersIndia = require('../data/shelters_india.json');
const allShelters = [...sheltersJharkhand, ...sheltersDelhi, ...sheltersIndia];

// GET /api/shelters — List all shelters with filters
router.get('/', (req, res) => {
  const { state, city, district, status, type, disasterType, search, page, limit } = req.query;

  let results = allShelters.filter((s) => {
    if (!matchesFilter(s.state, state)) return false;
    if (!matchesFilter(s.city, city)) return false;
    if (!matchesFilter(s.district, district)) return false;
    if (status && s.status.toUpperCase() !== status.toUpperCase()) return false;
    if (type && !matchesFilter(s.type, type)) return false;
    if (disasterType && !s.disasterType.some((d) => d.toLowerCase().includes(disasterType.toLowerCase()))) return false;
    if (search) {
      const q = search.toLowerCase();
      return s.name.toLowerCase().includes(q) || s.city.toLowerCase().includes(q) || s.district.toLowerCase().includes(q);
    }
    return true;
  });

  // Add computed fields
  results = results.map((s) => ({
    ...s,
    available: Math.max(0, s.capacity - s.occupied),
    occupancyPercent: s.capacity > 0 ? +(s.occupied / s.capacity).toFixed(2) : 0,
  }));

  const { data, pagination } = paginate(results, page, limit);
  res.json({ success: true, data, pagination, timestamp: new Date().toISOString() });
});

// GET /api/shelters/nearby — Find shelters near a lat/lng
router.get('/nearby', (req, res) => {
  const { lat, lng, radius = 25 } = req.query;
  if (!lat || !lng) {
    return res.status(400).json({ success: false, error: { message: 'lat and lng query params required', code: 'MISSING_PARAMS' } });
  }

  const userLat = parseFloat(lat);
  const userLng = parseFloat(lng);
  const maxRadius = Math.min(parseFloat(radius), 500);

  let results = allShelters
    .map((s) => {
      const dist = haversineKm(userLat, userLng, s.latitude, s.longitude);
      return { ...s, distanceKm: +dist.toFixed(2), distance: formatDistance(dist), available: Math.max(0, s.capacity - s.occupied), occupancyPercent: s.capacity > 0 ? +(s.occupied / s.capacity).toFixed(2) : 0 };
    })
    .filter((s) => s.distanceKm <= maxRadius)
    .sort((a, b) => a.distanceKm - b.distanceKm);

  res.json({ success: true, data: results, count: results.length, timestamp: new Date().toISOString() });
});

// GET /api/shelters/stats — Aggregate statistics
router.get('/stats', (req, res) => {
  const byState = {};
  let totalCapacity = 0, totalOccupied = 0;

  allShelters.forEach((s) => {
    totalCapacity += s.capacity;
    totalOccupied += s.occupied;
    if (!byState[s.state]) byState[s.state] = { state: s.state, count: 0, totalCapacity: 0, totalOccupied: 0, totalAvailable: 0 };
    byState[s.state].count++;
    byState[s.state].totalCapacity += s.capacity;
    byState[s.state].totalOccupied += s.occupied;
    byState[s.state].totalAvailable += Math.max(0, s.capacity - s.occupied);
  });

  res.json({
    success: true,
    data: {
      totalShelters: allShelters.length,
      totalCapacity,
      totalOccupied,
      totalAvailable: totalCapacity - totalOccupied,
      byState: Object.values(byState),
      statusBreakdown: {
        open: allShelters.filter((s) => s.status === 'OPEN').length,
        nearFull: allShelters.filter((s) => ['NEAR_FULL', 'Near Capacity', 'LIMITED'].includes(s.status)).length,
        full: allShelters.filter((s) => ['FULL', 'Full'].includes(s.status)).length,
        standby: allShelters.filter((s) => s.status === 'STANDBY').length,
      },
    },
    timestamp: new Date().toISOString(),
  });
});

// GET /api/shelters/:id — Get shelter by ID
router.get('/:id', (req, res) => {
  const shelter = allShelters.find((s) => s.id === req.params.id);
  if (!shelter) return res.status(404).json({ success: false, error: { message: `Shelter ${req.params.id} not found`, code: 'NOT_FOUND' } });

  res.json({
    success: true,
    data: {
      ...shelter,
      available: Math.max(0, shelter.capacity - shelter.occupied),
      occupancyPercent: shelter.capacity > 0 ? +(shelter.occupied / shelter.capacity).toFixed(2) : 0,
    },
    timestamp: new Date().toISOString(),
  });
});

// GET /api/shelters/:id/history — Historical events for a shelter
router.get('/:id/history', (req, res) => {
  const shelter = allShelters.find((s) => s.id === req.params.id);
  if (!shelter) return res.status(404).json({ success: false, error: { message: `Shelter ${req.params.id} not found`, code: 'NOT_FOUND' } });

  res.json({
    success: true,
    data: {
      shelterId: shelter.id,
      shelterName: shelter.name,
      operatingSince: shelter.operatingSince,
      historicalEvents: shelter.historicalEvents || [],
    },
    timestamp: new Date().toISOString(),
  });
});

module.exports = router;
