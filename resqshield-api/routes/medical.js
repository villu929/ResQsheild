const express = require('express');
const router = express.Router();
const { haversineKm, paginate, matchesFilter, formatDistance } = require('../utils/helpers');

const medJharkhand = require('../data/medical_jharkhand.json');
const medDelhi = require('../data/medical_delhi.json');
const medIndia = require('../data/medical_india.json');
const allMedical = [...medJharkhand, ...medDelhi, ...medIndia];

// GET /api/medical — List all medical facilities
router.get('/', (req, res) => {
  const { state, city, district, type, hasBloodBank, is24x7, search, page, limit } = req.query;

  let results = allMedical.filter((m) => {
    if (!matchesFilter(m.state, state)) return false;
    if (!matchesFilter(m.city, city)) return false;
    if (!matchesFilter(m.district, district)) return false;
    if (type && !matchesFilter(m.type, type)) return false;
    if (hasBloodBank === 'true' && !m.bloodBankAvailable) return false;
    if (is24x7 === 'true' && !m.is24x7) return false;
    if (search) {
      const q = search.toLowerCase();
      return m.name.toLowerCase().includes(q) || m.city.toLowerCase().includes(q);
    }
    return true;
  });

  const { data, pagination } = paginate(results, page, limit);
  res.json({ success: true, data, pagination, timestamp: new Date().toISOString() });
});

// GET /api/medical/nearby
router.get('/nearby', (req, res) => {
  const { lat, lng, radius = 25 } = req.query;
  if (!lat || !lng) return res.status(400).json({ success: false, error: { message: 'lat and lng required', code: 'MISSING_PARAMS' } });

  const userLat = parseFloat(lat);
  const userLng = parseFloat(lng);
  const maxRadius = Math.min(parseFloat(radius), 500);

  let results = allMedical
    .map((m) => {
      const dist = haversineKm(userLat, userLng, m.latitude, m.longitude);
      return { ...m, distanceKm: +dist.toFixed(2), distance: formatDistance(dist) };
    })
    .filter((m) => m.distanceKm <= maxRadius)
    .sort((a, b) => a.distanceKm - b.distanceKm);

  res.json({ success: true, data: results, count: results.length, timestamp: new Date().toISOString() });
});

// GET /api/medical/stats
router.get('/stats', (req, res) => {
  const byState = {};
  let totalBeds = 0, totalEmergencyBeds = 0, totalICU = 0, totalAmbulance = 0;

  allMedical.forEach((m) => {
    totalBeds += m.totalBeds || 0;
    totalEmergencyBeds += m.emergencyBeds || 0;
    totalICU += m.icuBeds || 0;
    totalAmbulance += m.ambulanceUnits || 0;
    if (!byState[m.state]) byState[m.state] = { state: m.state, count: 0, totalBeds: 0, emergencyBeds: 0, bloodBanks: 0 };
    byState[m.state].count++;
    byState[m.state].totalBeds += m.totalBeds || 0;
    byState[m.state].emergencyBeds += m.emergencyBeds || 0;
    if (m.bloodBankAvailable) byState[m.state].bloodBanks++;
  });

  res.json({
    success: true,
    data: {
      totalFacilities: allMedical.length,
      totalBeds,
      totalEmergencyBeds,
      totalICUBeds: totalICU,
      totalAmbulances: totalAmbulance,
      facilitiesWithBloodBank: allMedical.filter((m) => m.bloodBankAvailable).length,
      byState: Object.values(byState),
    },
    timestamp: new Date().toISOString(),
  });
});

// GET /api/medical/:id
router.get('/:id', (req, res) => {
  const facility = allMedical.find((m) => m.id === req.params.id);
  if (!facility) return res.status(404).json({ success: false, error: { message: `Medical facility ${req.params.id} not found` } });
  res.json({ success: true, data: facility, timestamp: new Date().toISOString() });
});

module.exports = router;
