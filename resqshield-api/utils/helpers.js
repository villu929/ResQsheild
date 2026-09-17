/**
 * Calculate distance between two lat/lng points using Haversine formula.
 * @returns Distance in kilometres.
 */
function haversineKm(lat1, lon1, lat2, lon2) {
  const R = 6371; // Earth radius in km
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) *
      Math.cos(toRad(lat2)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

function toRad(deg) {
  return (deg * Math.PI) / 180;
}

/**
 * Apply pagination to an array.
 */
function paginate(arr, page = 1, limit = 50) {
  const p = Math.max(1, parseInt(page) || 1);
  const l = Math.min(200, Math.max(1, parseInt(limit) || 50));
  const start = (p - 1) * l;
  return {
    data: arr.slice(start, start + l),
    pagination: {
      page: p,
      limit: l,
      total: arr.length,
      totalPages: Math.ceil(arr.length / l),
    },
  };
}

/**
 * Case-insensitive string match.
 */
function matchesFilter(value, filter) {
  if (!filter) return true;
  return (value || '').toLowerCase().includes(filter.toLowerCase());
}

/**
 * Format distance for display.
 */
function formatDistance(km) {
  if (km < 1) return `${Math.round(km * 1000)} m`;
  return `${km.toFixed(1)} km`;
}

/**
 * Generate a realistic "last updated" timestamp (within the last N minutes).
 */
function recentTimestamp(maxMinutesAgo = 30) {
  const ms = Date.now() - Math.floor(Math.random() * maxMinutesAgo * 60 * 1000);
  return new Date(ms).toISOString();
}

module.exports = {
  haversineKm,
  paginate,
  matchesFilter,
  formatDistance,
  recentTimestamp,
};
