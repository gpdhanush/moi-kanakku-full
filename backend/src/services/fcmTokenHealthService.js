require('../controllers/notificationController');

const admin = require('firebase-admin');
const db = require('../config/database');
const logger = require('../config/logger');
const { fromBinaryUUID } = require('../helpers/uuid');
const {
  isInvalidFcmTokenError,
  deactivateUnregisteredFcmToken,
} = require('../helpers/fcmTokenInvalidation');

function getHealthCheckBatchSize() {
  const size = Number(process.env.FCM_HEALTH_CHECK_BATCH_SIZE);
  return Number.isFinite(size) && size > 0 ? Math.min(size, 500) : 100;
}

/**
 * Sends data-only FCM messages to detect unregistered tokens.
 *
 * This is NOT a guaranteed uninstall event. Tokens can stay valid after
 * uninstall for a while, and invalid tokens can also come from notification
 * being disabled, data clear, or token rotation.
 */
async function runFcmTokenHealthCheck() {
  const [rows] = await db.query(
    `SELECT user_id, fcm_token
     FROM user_devices
     WHERE is_active = 1
       AND (is_deleted = 0 OR is_deleted IS NULL)
       AND fcm_token IS NOT NULL
       AND fcm_token <> ''
       AND (token_status = 'active' OR token_status IS NULL)`
  );

  const devices = (rows || []).filter((row) => row.fcm_token);
  if (devices.length === 0) {
    logger.info('FCM health check completed', { checked: 0, invalidated: 0, failed: 0 });
    return { checked: 0, invalidated: 0, failed: 0 };
  }
  let checked = 0;
  let invalidated = 0;
  let failed = 0;
  const batchSize = getHealthCheckBatchSize();

  for (let i = 0; i < devices.length; i += batchSize) {
    const batch = devices.slice(i, i + batchSize);
    const messages = batch.map((row) => ({
      token: row.fcm_token,
      data: { type: 'device_health_check' },
      android: { priority: 'normal' },
    }));

    try {
      const response = await admin.messaging().sendEach(messages);
      checked += batch.length;
      for (let index = 0; index < response.responses.length; index += 1) {
        const result = response.responses[index];
        if (result.success) continue;
        const row = batch[index];
        if (isInvalidFcmTokenError(result.error)) {
          await deactivateUnregisteredFcmToken(row.fcm_token, {
            userId: fromBinaryUUID(row.user_id),
          });
          invalidated += 1;
        } else {
          failed += 1;
          logger.warn('FCM health check send failed', {
            userId: fromBinaryUUID(row.user_id),
            code: result.error?.code || null,
          });
        }
      }
    } catch (error) {
      failed += batch.length;
      logger.error('FCM health check batch failed', {
        error: error?.message || String(error),
        batchSize: batch.length,
      });
    }
  }

  logger.info('FCM health check completed', {
    checked,
    invalidated,
    failed,
  });

  return { checked, invalidated, failed };
}

module.exports = { runFcmTokenHealthCheck };
