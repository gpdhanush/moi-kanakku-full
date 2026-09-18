/**
 * Shared bulk email / FCM runner used by both the in-process queue and
 * worker_threads isolate.
 */
require('dotenv').config();

const logger = require('../config/logger');
const { mapWithConcurrency } = require('../helpers/concurrency');
const {
  createEmailTransporter,
  formatEmailFrom,
  buildMailOptions,
  normalizeEmailAddress,
  escapeHtml,
} = require('../services/emailService');

function buildBulkEmailHtml(safeName, body) {
  return `<!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Moi Kanakku</title></head><body style="margin:0;padding:0;background-color:#f5f7fb;font-family:Arial,Helvetica,sans-serif;"><div style="display:none;font-size:1px;color:#f5f7fb;line-height:1px;max-height:0;max-width:0;opacity:0;overflow:hidden;">Moi Kanakku notification</div><table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="padding:30px 10px;"><tr><td align="center"><table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:620px;background:#ffffff;border:1px solid #eaeaea;border-radius:8px;overflow:hidden;"><tr><td style="background:#2f3490;color:#ffffff;text-align:center;padding:20px;"><h2 style="margin:0;font-size:22px;">Moi Kanakku</h2><p style="margin:5px 0 0;font-size:13px;color:#dcdcff;">Manage events, relations & gifts easily</p></td></tr><tr><td style="padding:30px;color:#333333;line-height:1.6;"><p style="margin:0 0 15px;font-size:16px;">Hi <strong>${safeName}</strong>,</p><div style="margin:20px 0;font-size:15px;color:#555;">${body}</div></td></tr><tr><td style="border-top:1px solid #f1f1f1;padding:20px;font-size:14px;color:#666;">Regards,<br><strong style="color:#2f3490;">Moi Kanakku Team</strong></td></tr></table><p style="max-width:620px;margin:20px auto 0;text-align:center;font-size:12px;color:#9ca3af;">© 2026 Moi Kanakku. All rights reserved.<br>If you received this email by mistake, please ignore it.</p></td></tr></table></body></html>`;
}

async function runBulkEmailJob(payload, jobId) {
  const { users = [], subject, body } = payload;
  const transporter = createEmailTransporter({
    pool: true,
    maxConnections: 3,
    maxMessages: 200,
  });

  const summary = {
    jobId,
    total: users.length,
    successful: 0,
    failed: 0,
  };

  try {
    await mapWithConcurrency(users, 3, async (user) => {
      const targetEmail = normalizeEmailAddress(user.email);
      if (!targetEmail) {
        summary.failed += 1;
        return;
      }
      try {
        const safeName = escapeHtml(user.full_name || 'User');
        await transporter.sendMail(
          buildMailOptions({
            from: formatEmailFrom('Moi Kanakku'),
            to: targetEmail,
            subject,
            html: buildBulkEmailHtml(safeName, body),
          }),
        );
        summary.successful += 1;
      } catch (err) {
        summary.failed += 1;
        logger.error(`[bulk-email:${jobId}] failed for ${targetEmail}:`, err);
      }
    });
  } finally {
    transporter.close();
  }

  logger.info(`[bulk-email:${jobId}] done`, summary);
  return summary;
}

async function runBulkFcmJob(payload, jobId) {
  // Lazy-load so email-only workers don't need Firebase unless used.
  const admin = require('firebase-admin');
  const { NotificationType } = require('../models/notificationModels');
  const {
    isInvalidFcmTokenError,
    deactivateUnregisteredFcmToken,
  } = require('../helpers/fcmTokenInvalidation');

  if (!admin.apps.length) {
    const serviceAccount = {
      type: process.env.FIREBASE_TYPE,
      project_id: process.env.FIREBASE_PROJECT_ID,
      private_key_id: process.env.FIREBASE_PRIVATE_KEY_ID,
      private_key: (process.env.FIREBASE_PRIVATE_KEY || '').replace(/\\n/g, '\n'),
      client_email: process.env.FIREBASE_CLIENT_EMAIL,
      client_id: process.env.FIREBASE_CLIENT_ID,
      auth_uri: process.env.FIREBASE_AUTH_URI,
      token_uri: process.env.FIREBASE_TOKEN_URI,
      auth_provider_x509_cert_url: process.env.FIREBASE_AUTH_PROVIDER_X509_CERT_URL,
      client_x509_cert_url: process.env.FIREBASE_CLIENT_X509_CERT_URL,
      universe_domain: process.env.FIREBASE_UNIVERSE_DOMAIN,
    };
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
  }

  const { users = [], title, body, type } = payload;
  const notifType = type || NotificationType.GENERAL;
  const summary = {
    jobId,
    total: users.length,
    successful: 0,
    failed: 0,
    noDeviceToken: 0,
  };

  await mapWithConcurrency(users, 8, async (user) => {
    if (!user.fcm_token) {
      summary.noDeviceToken += 1;
      return;
    }
    try {
      await admin.messaging().send({
        notification: { title, body },
        data: {
          title,
          body,
          type: notifType,
          timestamp: new Date().toISOString(),
          notificationType: notifType,
        },
        token: user.fcm_token,
        android: {
          priority: 'high',
          ttl: 3600 * 1000,
          notification: {
            title,
            body,
            clickAction: 'FLUTTER_NOTIFICATION_CLICK',
          },
        },
        apns: {
          headers: { 'apns-priority': '10' },
          payload: {
            aps: {
              alert: { title, body },
              sound: 'default',
              badge: 1,
              'content-available': 1,
            },
          },
        },
      });
      summary.successful += 1;
    } catch (fcmError) {
      summary.failed += 1;
      logger.error(`[bulk-fcm:${jobId}] failed for user ${user.userId}:`, fcmError);
      if (isInvalidFcmTokenError(fcmError)) {
        try {
          await deactivateUnregisteredFcmToken(user.fcm_token, {
            userId: user.userId,
          });
        } catch (deactErr) {
          logger.error(`[bulk-fcm:${jobId}] token deactivate failed:`, deactErr);
        }
      }
    }
  });

  logger.info(`[bulk-fcm:${jobId}] done`, summary);
  return summary;
}

/**
 * @param {{ type: 'bulk_email' | 'bulk_fcm', payload: object, jobId: string }} job
 */
async function runBulkJob(job) {
  const { type, payload, jobId } = job;
  if (type === 'bulk_email') {
    return runBulkEmailJob(payload, jobId);
  }
  if (type === 'bulk_fcm') {
    return runBulkFcmJob(payload, jobId);
  }
  throw new Error(`Unknown bulk job type: ${type}`);
}

module.exports = {
  runBulkJob,
  runBulkEmailJob,
  runBulkFcmJob,
};
