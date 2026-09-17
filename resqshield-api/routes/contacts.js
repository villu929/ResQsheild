const express = require('express');
const router = express.Router();
const contacts = require('../data/emergency_contacts.json');
const { matchesFilter } = require('../utils/helpers');

// GET /api/emergency-contacts
router.get('/', (req, res) => {
  const { state, type, district } = req.query;
  let results = contacts;
  if (state) results = results.filter((c) => matchesFilter(c.state, state));
  if (type) results = results.filter((c) => c.type === type.toLowerCase());
  if (district) results = results.filter((c) => matchesFilter(c.district, district));

  res.json({ success: true, data: results, count: results.length, timestamp: new Date().toISOString() });
});

module.exports = router;
