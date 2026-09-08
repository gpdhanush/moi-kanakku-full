const NodeCache = require('node-cache');
const logger = require('../config/logger');

// Standard TTL: 120 seconds, check for expired keys every 150 seconds
const cache = new NodeCache({ stdTTL: 120, checkperiod: 150, useClones: false });

const TTL = {
  SHORT: 30,       // 30 seconds
  MEDIUM: 120,     // 2 minutes
  LONG: 300,       // 5 minutes
  DASHBOARD: 60,   // 1 minute
  DEFAULTS: 300,   // 5 minutes
  USER_STATS: 60,  // 1 minute
  UPCOMING: 120    // 2 minutes
};

/**
 * Get item from cache
 */
function get(key) {
  try {
    return cache.get(key);
  } catch (err) {
    if (logger && logger.error) {
      logger.error(`Cache get error for key [${key}]:`, err);
    }
    return null;
  }
}

/**
 * Set item in cache
 */
function set(key, value, ttl = 120) {
  try {
    return cache.set(key, value, ttl);
  } catch (err) {
    if (logger && logger.error) {
      logger.error(`Cache set error for key [${key}]:`, err);
    }
    return false;
  }
}

/**
 * Delete item from cache by key
 */
function del(key) {
  try {
    return cache.del(key);
  } catch (err) {
    if (logger && logger.error) {
      logger.error(`Cache del error for key [${key}]:`, err);
    }
    return 0;
  }
}

/**
 * Delete items matching key prefix
 */
function delByPrefix(prefix) {
  try {
    const keys = cache.keys();
    const matchingKeys = keys.filter(key => key.startsWith(prefix));
    if (matchingKeys.length > 0) {
      cache.del(matchingKeys);
    }
    return matchingKeys.length;
  } catch (err) {
    if (logger && logger.error) {
      logger.error(`Cache delByPrefix error for prefix [${prefix}]:`, err);
    }
    return 0;
  }
}

/**
 * Flush all cache entries
 */
function flush() {
  try {
    cache.flushAll();
    return true;
  } catch (err) {
    if (logger && logger.error) {
      logger.error('Cache flush error:', err);
    }
    return false;
  }
}

/**
 * Get item from cache, or execute fetch function, store result, and return it
 */
async function getOrSet(key, fetchFn, ttl = 120) {
  const cachedVal = get(key);
  if (cachedVal !== undefined && cachedVal !== null) {
    return cachedVal;
  }
  const freshVal = await fetchFn();
  if (freshVal !== undefined && freshVal !== null) {
    set(key, freshVal, ttl);
  }
  return freshVal;
}

module.exports = {
  get,
  set,
  del,
  delByPrefix,
  flush,
  getOrSet,
  TTL,
  rawCache: cache
};
