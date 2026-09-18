const AuditLogs = require('../models/auditLogs');
const logger = require('../config/logger');

function truncate(value, max) {
  if (value == null) return null;
  const str = String(value);
  return str.length > max ? str.slice(0, max) : str;
}

function getClientIp(req) {
  if (!req) return null;
  const forwarded = req.headers?.['x-forwarded-for'];
  if (forwarded) {
    return String(forwarded).split(',')[0].trim() || null;
  }
  return req.ip || req.socket?.remoteAddress || null;
}

/**
 * Fire-and-forget mobile user audit log.
 * Never throws into the main request path.
 */
function recordAuditLog({
  userId,
  action,
  entityType = null,
  entityId = null,
  summary,
  metadata = null,
  deviceId = null,
  req = null,
} = {}) {
  if (!userId || !action || !summary) return;

  const payload = {
    userId,
    action: String(action).trim().toUpperCase(),
    entityType: entityType ? String(entityType).trim() : null,
    entityId: entityId != null ? String(entityId) : null,
    summary: truncate(summary, 255),
    metadata,
    ipAddress: truncate(getClientIp(req), 64),
    userAgent: truncate(req?.headers?.['user-agent'] || null, 255),
    deviceId: truncate(
      deviceId ||
        req?.body?.device_id ||
        req?.body?.deviceId ||
        null,
      500
    ),
  };

  Promise.resolve()
    .then(() => AuditLogs.create(payload))
    .catch((err) => {
      logger.warn('recordAuditLog failed', {
        action: payload.action,
        userId: String(userId),
        message: err?.message || String(err),
      });
    });
}

module.exports = {
  recordAuditLog,
};
