const db = require('../config/database');
const logger = require('../config/logger');

function isInvalidFcmTokenError(error) {
  const code = error?.code || '';
  const message = String(error?.message || '');
  return (
    code === 'messaging/invalid-registration-token' ||
    code === 'messaging/registration-token-not-registered' ||
    message.includes('Requested entity was not found')
  );
}

/**
 * FCM token invalidation is not an instantaneous uninstall event.
 * Mark the device Likely Uninstalled without changing last_used_at,
 * so inactivity can still be distinguished from an invalid token.
 */
async function deactivateUnregisteredFcmToken(token, { userId, traceId } = {}) {
  if (!token) return;
  try {
    await db.query(
      `UPDATE user_devices
       SET is_active = 0,
           token_status = 'invalid',
           uninstalled_at = COALESCE(uninstalled_at, CURRENT_TIMESTAMP),
           updated_at = CURRENT_TIMESTAMP
       WHERE fcm_token = ?`,
      [token]
    );
    logger.info('Device token invalidated (likely uninstalled)', {
      traceId: traceId || null,
      userId: userId || null,
    });
  } catch (dbError) {
    logger.error('Error deactivating FCM token:', {
      traceId: traceId || null,
      userId: userId || null,
      error: dbError?.message || String(dbError),
    });
  }
}

module.exports = {
  isInvalidFcmTokenError,
  deactivateUnregisteredFcmToken,
};
