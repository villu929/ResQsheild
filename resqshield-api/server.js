const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');
const { errorHandler } = require('./middleware/errorHandler');
const rateLimiter = require('./middleware/rateLimiter');

const app = express();
const PORT = process.env.PORT || 3000;

// ─── Core Middleware ──────────────────────────────────────────────────
app.use(helmet({ contentSecurityPolicy: false }));
app.use(cors({ origin: '*', methods: ['GET', 'POST', 'OPTIONS'], allowedHeaders: ['Content-Type', 'Authorization'] }));
app.use(compression());
app.use(express.json({ limit: '1mb' }));
app.use(morgan('dev'));
app.use(rateLimiter);

// ─── Health Check ─────────────────────────────────────────────────────
app.get('/', (_req, res) => {
  res.json({
    name: 'ResQShield API',
    version: '1.0.0',
    description: 'Comprehensive disaster management API for flash floods and landslides across India with major focus on Jharkhand and Delhi',
    status: 'operational',
    uptime: `${Math.floor(process.uptime())}s`,
    endpoints: {
      shelters: {
        list: 'GET /api/shelters',
        nearby: 'GET /api/shelters/nearby?lat=23.34&lng=85.31&radius=25',
        stats: 'GET /api/shelters/stats',
        detail: 'GET /api/shelters/:id',
        history: 'GET /api/shelters/:id/history',
      },
      medical: {
        list: 'GET /api/medical',
        nearby: 'GET /api/medical/nearby?lat=28.63&lng=77.22&radius=10',
        stats: 'GET /api/medical/stats',
        detail: 'GET /api/medical/:id',
      },
      rivers: {
        list: 'GET /api/rivers',
        detail: 'GET /api/rivers/:id',
        observations: 'GET /api/rivers/:id/observations',
        waterLevels: 'GET /api/rivers/water-levels',
      },
      rainfall: {
        list: 'GET /api/rainfall',
        alerts: 'GET /api/rainfall/alerts',
        detail: 'GET /api/rainfall/:id',
      },
      floods: {
        live: 'GET /api/floods/live',
        alerts: 'GET /api/floods/alerts',
        zones: 'GET /api/floods/zones',
        sources: 'GET /api/floods/sources',
      },
      landslides: {
        zones: 'GET /api/landslides/zones',
        alerts: 'GET /api/landslides/alerts',
        historical: 'GET /api/landslides/historical',
      },
      emergencyContacts: 'GET /api/emergency-contacts',
      stats: 'GET /api/stats',
    },
    documentation: {
      queryParams: {
        pagination: 'Use ?page=1&limit=20 on list endpoints',
        filtering: 'Use ?state=Jharkhand, ?city=Ranchi, ?district=Ranchi on list endpoints',
        nearby: 'Use ?lat=XX&lng=YY&radius=ZZ on /nearby endpoints (radius in km, default 25)',
        search: 'Use ?search=RIMS on shelter/medical list endpoints',
      },
      coverage: {
        focusStates: ['Jharkhand', 'Delhi'],
        otherStates: ['Assam', 'Bihar', 'Kerala', 'Uttarakhand', 'West Bengal', 'Odisha', 'Maharashtra', 'Karnataka', 'Meghalaya', 'Manipur', 'Himachal Pradesh', 'Tamil Nadu'],
      },
    },
    timestamp: new Date().toISOString(),
  });
});

app.get('/api', (_req, res) => {
  res.redirect('/');
});

// ─── API Routes ───────────────────────────────────────────────────────
app.use('/api/shelters', require('./routes/shelters'));
app.use('/api/medical', require('./routes/medical'));
app.use('/api/rivers', require('./routes/rivers'));
app.use('/api/rainfall', require('./routes/rainfall'));
app.use('/api/floods', require('./routes/floods'));
app.use('/api/landslides', require('./routes/landslides'));
app.use('/api/emergency-contacts', require('./routes/contacts'));
app.use('/api/stats', require('./routes/stats'));

// Water-levels alias at top-level (matches ApiConstants.waterLevels pattern)
const riversRouter = require('./routes/rivers');
app.use('/api/water-levels', (req, res, next) => {
  // Forward to the water-levels route inside rivers
  req.url = '/water-levels';
  riversRouter(req, res, next);
});

// ─── 404 Handler ──────────────────────────────────────────────────────
app.use((_req, res) => {
  res.status(404).json({
    success: false,
    error: {
      message: 'Endpoint not found. Visit / for API documentation.',
      code: 'NOT_FOUND',
    },
    timestamp: new Date().toISOString(),
  });
});

// ─── Error Handler ────────────────────────────────────────────────────
app.use(errorHandler);

// ─── Start Server ─────────────────────────────────────────────────────
app.listen(PORT, () => {
  console.log(`
╔═══════════════════════════════════════════════════════════════╗
║                     ResQShield API v1.0.0                    ║
║   Disaster Management API — Flash Floods & Landslides India  ║
╠═══════════════════════════════════════════════════════════════╣
║  Server:      http://localhost:${PORT}                         ║
║  Status:      ✅ OPERATIONAL                                 ║
║  Environment: ${(process.env.NODE_ENV || 'development').padEnd(15)}                        ║
║  Focus:       Jharkhand + Delhi                              ║
╠═══════════════════════════════════════════════════════════════╣
║  API Docs:    http://localhost:${PORT}/                         ║
║  Shelters:    http://localhost:${PORT}/api/shelters               ║
║  Medical:     http://localhost:${PORT}/api/medical                ║
║  Rivers:      http://localhost:${PORT}/api/rivers                 ║
║  Floods:      http://localhost:${PORT}/api/floods/live             ║
║  Landslides:  http://localhost:${PORT}/api/landslides/zones        ║
║  Stats:       http://localhost:${PORT}/api/stats                  ║
╚═══════════════════════════════════════════════════════════════╝
  `);
});

module.exports = app;
