require('dotenv').config();

module.exports = {
  PORT: process.env.PORT || 3000,
  API_VERSION: '1.0.0',
  API_NAME: 'ResQShield Disaster Relief API',
  CORS_ORIGINS: process.env.CORS_ORIGINS
    ? process.env.CORS_ORIGINS.split(',')
    : ['*'],
  RATE_LIMIT: {
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 200, // requests per window
  },
  // Default search radius in km for nearby queries
  DEFAULT_RADIUS_KM: 25,
  MAX_RADIUS_KM: 500,
};
