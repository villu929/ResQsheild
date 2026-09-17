const rateLimit = require('express-rate-limit');
const { RATE_LIMIT } = require('../config/constants');

const limiter = rateLimit({
  windowMs: RATE_LIMIT.windowMs,
  max: RATE_LIMIT.max,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    error: {
      message: 'Too many requests. Please try again later.',
      code: 'RATE_LIMIT_EXCEEDED',
      status: 429,
    },
  },
});

module.exports = limiter;
