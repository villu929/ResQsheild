/**
 * Global error handling middleware.
 * Returns structured JSON errors for all unhandled exceptions.
 */
function errorHandler(err, req, res, _next) {
  console.error(`[ERROR] ${req.method} ${req.originalUrl}:`, err.message);

  const status = err.statusCode || 500;
  res.status(status).json({
    success: false,
    error: {
      message: err.message || 'Internal Server Error',
      code: err.code || 'INTERNAL_ERROR',
      status,
    },
    timestamp: new Date().toISOString(),
  });
}

/**
 * 404 handler for undefined routes.
 */
function notFoundHandler(req, res) {
  res.status(404).json({
    success: false,
    error: {
      message: `Route ${req.method} ${req.originalUrl} not found`,
      code: 'NOT_FOUND',
      status: 404,
    },
    timestamp: new Date().toISOString(),
  });
}

module.exports = { errorHandler, notFoundHandler };
