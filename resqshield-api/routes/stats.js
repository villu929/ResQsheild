const express = require('express');
const router = express.Router();

// Load all data for aggregate stats
const sheltersJH = require('../data/shelters_jharkhand.json');
const sheltersDL = require('../data/shelters_delhi.json');
const sheltersIN = require('../data/shelters_india.json');
const allShelters = [...sheltersJH, ...sheltersDL, ...sheltersIN];

const medJH = require('../data/medical_jharkhand.json');
const medDL = require('../data/medical_delhi.json');
const medIN = require('../data/medical_india.json');
const allMedical = [...medJH, ...medDL, ...medIN];

const rivers = require('../data/rivers.json');
const rainfall = require('../data/rainfall.json');
const floodZones = require('../data/flood_zones.json');
const landslideZones = require('../data/landslide_zones.json');
const contacts = require('../data/emergency_contacts.json');

// GET /api/stats — Dashboard summary
router.get('/', (_req, res) => {
  const totalShelterCapacity = allShelters.reduce((sum, s) => sum + s.capacity, 0);
  const totalShelterOccupied = allShelters.reduce((sum, s) => sum + s.occupied, 0);
  const totalBeds = allMedical.reduce((sum, m) => sum + (m.totalBeds || 0), 0);
  const totalEmergencyBeds = allMedical.reduce((sum, m) => sum + (m.emergencyBeds || 0), 0);
  const totalAmbulances = allMedical.reduce((sum, m) => sum + (m.ambulanceUnits || 0), 0);

  res.json({
    success: true,
    data: {
      shelters: {
        total: allShelters.length,
        totalCapacity: totalShelterCapacity,
        totalOccupied: totalShelterOccupied,
        totalAvailable: totalShelterCapacity - totalShelterOccupied,
        openShelters: allShelters.filter((s) => s.status === 'OPEN').length,
      },
      medicalFacilities: {
        total: allMedical.length,
        totalBeds,
        totalEmergencyBeds,
        totalAmbulances,
        withBloodBank: allMedical.filter((m) => m.bloodBankAvailable).length,
      },
      rivers: {
        totalStations: rivers.length,
        inDanger: rivers.filter((r) => r.status === 'DANGER').length,
        inWarning: rivers.filter((r) => r.status === 'WARNING').length,
        inWatch: rivers.filter((r) => r.status === 'WATCH').length,
      },
      rainfall: {
        totalZones: rainfall.length,
        dangerZones: rainfall.filter((r) => r.status === 'DANGER').length,
        heavyZones: rainfall.filter((r) => r.status === 'HEAVY').length,
      },
      floods: {
        activeZones: floodZones.filter((f) => f.status === 'active').length,
        dangerZones: floodZones.filter((f) => f.severity === 'danger').length,
        totalAffectedPopulation: floodZones.reduce((sum, f) => sum + (f.affectedPopulation || 0), 0),
      },
      landslides: {
        totalZones: landslideZones.length,
        veryHighRisk: landslideZones.filter((z) => z.riskLevel === 'VERY_HIGH').length,
        highRisk: landslideZones.filter((z) => z.riskLevel === 'HIGH').length,
      },
      emergencyContacts: {
        total: contacts.length,
        national: contacts.filter((c) => c.type === 'national').length,
        state: contacts.filter((c) => c.type === 'state').length,
        district: contacts.filter((c) => c.type === 'district').length,
      },
      coverage: {
        states: [...new Set([...allShelters.map((s) => s.state), ...allMedical.map((m) => m.state)])],
        focusStates: ['Jharkhand', 'Delhi'],
      },
    },
    apiVersion: '1.0.0',
    timestamp: new Date().toISOString(),
  });
});

module.exports = router;
