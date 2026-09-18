const { AppAlert } = require('../models/appAlertModels');
const { validateUuid, sendUuidError } = require('../helpers/idParams');
const logger = require('../config/logger');

const DEFAULT_REMIND_HOURS = 24;
const MAX_REMIND_HOURS = 168;

function cleanOptionalUrl(value) {
  if (value == null) return null;
  const trimmed = String(value).trim();
  if (!trimmed) return null;
  return trimmed.slice(0, 500);
}

function cleanOptionalText(value, max = 120) {
  if (value == null) return null;
  const trimmed = String(value).trim();
  if (!trimmed) return null;
  return trimmed.slice(0, max);
}

function parseDateOrNull(value) {
  if (value == null || String(value).trim() === '') return null;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return null;
  return date;
}

function resolveUserId(req) {
  return (
    req.user?.userId ||
    req.user?.id ||
    req.body?.userId ||
    req.query?.userId ||
    null
  );
}

exports.controller = {
  /** Admin: create a new popup alert campaign. */
  create: async (req, res) => {
    try {
      const title = String(req.body.title || '').trim();
      const content = String(req.body.content || req.body.body || '').trim();
      if (!title || !content) {
        return res.status(400).json({
          responseType: 'F',
          responseValue: { message: 'Title and content are required.' },
        });
      }

      const adminId =
        req.admin?.adminId ||
        req.admin?.id ||
        req.user?.adminId ||
        req.user?.id ||
        null;

      const alert = await AppAlert.create({
        title: title.slice(0, 255),
        content,
        imageUrl: cleanOptionalUrl(req.body.imageUrl || req.body.image_url),
        videoUrl: cleanOptionalUrl(req.body.videoUrl || req.body.video_url),
        ctaLabel: cleanOptionalText(req.body.ctaLabel || req.body.cta_label),
        ctaUrl: cleanOptionalUrl(req.body.ctaUrl || req.body.cta_url),
        isActive: req.body.isActive !== false && req.body.is_active !== false,
        startsAt: parseDateOrNull(req.body.startsAt || req.body.starts_at),
        endsAt: parseDateOrNull(req.body.endsAt || req.body.ends_at),
        createdByAdminId: adminId,
      });

      return res.status(200).json({
        responseType: 'S',
        responseValue: alert,
      });
    } catch (error) {
      logger.error('Error creating app alert:', error);
      const status = error.code === 'APP_ALERTS_MISSING' ? 503 : 500;
      return res.status(status).json({
        responseType: 'F',
        responseValue: {
          message:
            error.code === 'APP_ALERTS_MISSING'
              ? 'App alerts are not set up yet. Run backend/database/app_alerts.sql on the database.'
              : error.message || 'Failed to create alert.',
        },
      });
    }
  },

  /** Admin: list alerts. */
  list: async (req, res) => {
    try {
      const limit = Number(req.query.limit || req.body?.limit || 50);
      const offset = Number(req.query.offset || req.body?.offset || 0);
      const result = await AppAlert.listAdmin({ limit, offset });
      return res.status(200).json({
        responseType: 'S',
        responseValue: result.data,
        count: result.data.length,
        totalCount: result.totalCount,
      });
    } catch (error) {
      logger.error('Error listing app alerts:', error);
      return res.status(500).json({
        responseType: 'F',
        responseValue: { message: error.message || 'Failed to list alerts.' },
      });
    }
  },

  /** Admin: update alert. */
  update: async (req, res) => {
    try {
      const alertId = req.body.alertId || req.params.alertId || req.body.id;
      const idCheck = validateUuid(alertId, 'alertId');
      if (!idCheck.ok) return sendUuidError(res, idCheck.message);

      const existing = await AppAlert.findById(alertId);
      if (!existing) {
        return res.status(404).json({
          responseType: 'F',
          responseValue: { message: 'Alert not found.' },
        });
      }

      const payload = {};
      if (req.body.title != null) payload.title = String(req.body.title).trim().slice(0, 255);
      if (req.body.content != null || req.body.body != null) {
        payload.content = String(req.body.content || req.body.body).trim();
      }
      if (req.body.imageUrl != null || req.body.image_url != null) {
        payload.imageUrl = cleanOptionalUrl(req.body.imageUrl || req.body.image_url);
      }
      if (req.body.videoUrl != null || req.body.video_url != null) {
        payload.videoUrl = cleanOptionalUrl(req.body.videoUrl || req.body.video_url);
      }
      if (req.body.ctaLabel != null || req.body.cta_label != null) {
        payload.ctaLabel = cleanOptionalText(req.body.ctaLabel || req.body.cta_label);
      }
      if (req.body.ctaUrl != null || req.body.cta_url != null) {
        payload.ctaUrl = cleanOptionalUrl(req.body.ctaUrl || req.body.cta_url);
      }
      if (req.body.isActive != null || req.body.is_active != null) {
        payload.isActive = req.body.isActive !== false && req.body.is_active !== false &&
          req.body.isActive !== 0 && req.body.is_active !== 0 &&
          String(req.body.isActive ?? req.body.is_active).toLowerCase() !== 'false';
      }
      if (req.body.startsAt != null || req.body.starts_at != null) {
        payload.startsAt = parseDateOrNull(req.body.startsAt || req.body.starts_at);
      }
      if (req.body.endsAt != null || req.body.ends_at != null) {
        payload.endsAt = parseDateOrNull(req.body.endsAt || req.body.ends_at);
      }

      const updated = await AppAlert.update(alertId, payload);
      return res.status(200).json({
        responseType: 'S',
        responseValue: updated,
      });
    } catch (error) {
      logger.error('Error updating app alert:', error);
      return res.status(500).json({
        responseType: 'F',
        responseValue: { message: error.message || 'Failed to update alert.' },
      });
    }
  },

  /** Admin: soft-delete / deactivate. */
  remove: async (req, res) => {
    try {
      const alertId = req.body.alertId || req.params.alertId || req.body.id;
      const idCheck = validateUuid(alertId, 'alertId');
      if (!idCheck.ok) return sendUuidError(res, idCheck.message);

      const deleted = await AppAlert.softDelete(alertId);
      if (!deleted) {
        return res.status(404).json({
          responseType: 'F',
          responseValue: { message: 'Alert not found.' },
        });
      }

      return res.status(200).json({
        responseType: 'S',
        responseValue: { message: 'Alert deleted successfully.', alertId: String(alertId) },
      });
    } catch (error) {
      logger.error('Error deleting app alert:', error);
      return res.status(500).json({
        responseType: 'F',
        responseValue: { message: error.message || 'Failed to delete alert.' },
      });
    }
  },

  /** Mobile: get the next popup alert for the logged-in user. */
  getActive: async (req, res) => {
    try {
      const userId = resolveUserId(req);
      if (!userId) {
        return res.status(400).json({
          responseType: 'F',
          responseValue: { message: 'User ID is required.' },
        });
      }

      const idCheck = validateUuid(userId, 'userId');
      if (!idCheck.ok) return sendUuidError(res, idCheck.message);

      const alert = await AppAlert.findActiveForUser(userId);
      return res.status(200).json({
        responseType: 'S',
        responseValue: alert,
      });
    } catch (error) {
      logger.error('Error fetching active app alert:', error);
      return res.status(500).json({
        responseType: 'F',
        responseValue: { message: error.message || 'Failed to fetch alert.' },
      });
    }
  },

  /**
   * Mobile: record user action.
   * Body: { alertId, action: 'dont_show' | 'remind_later', remindHours? }
   */
  action: async (req, res) => {
    try {
      const userId = resolveUserId(req);
      const alertId = req.body.alertId || req.body.id;
      const action = String(req.body.action || '').trim().toLowerCase();

      if (!userId) {
        return res.status(400).json({
          responseType: 'F',
          responseValue: { message: 'User ID is required.' },
        });
      }

      const userCheck = validateUuid(userId, 'userId');
      if (!userCheck.ok) return sendUuidError(res, userCheck.message);

      const alertCheck = validateUuid(alertId, 'alertId');
      if (!alertCheck.ok) return sendUuidError(res, alertCheck.message);

      if (!['dont_show', 'remind_later', 'dismiss'].includes(action)) {
        return res.status(400).json({
          responseType: 'F',
          responseValue: {
            message: "action must be 'dont_show', 'remind_later', or 'dismiss'.",
          },
        });
      }

      const existing = await AppAlert.findById(alertId);
      if (!existing) {
        return res.status(404).json({
          responseType: 'F',
          responseValue: { message: 'Alert not found.' },
        });
      }

      const status = action === 'remind_later' ? 'remind_later' : 'dont_show';
      let remindAt = null;

      if (status === 'remind_later') {
        let hours = Number(req.body.remindHours ?? DEFAULT_REMIND_HOURS);
        if (!Number.isFinite(hours) || hours <= 0) hours = DEFAULT_REMIND_HOURS;
        hours = Math.min(hours, MAX_REMIND_HOURS);
        remindAt = new Date(Date.now() + hours * 60 * 60 * 1000);
      }

      await AppAlert.upsertUserState({
        alertId,
        userId,
        status,
        remindAt,
      });

      return res.status(200).json({
        responseType: 'S',
        responseValue: {
          message:
            status === 'remind_later'
              ? 'We will remind you later.'
              : 'Alert dismissed.',
          alertId: String(alertId),
          status,
          remindAt,
        },
      });
    } catch (error) {
      logger.error('Error saving app alert action:', error);
      const status = error.code === 'APP_ALERTS_MISSING' ? 503 : 500;
      return res.status(status).json({
        responseType: 'F',
        responseValue: {
          message:
            error.code === 'APP_ALERTS_MISSING'
              ? 'App alerts are not set up yet.'
              : error.message || 'Failed to save action.',
        },
      });
    }
  },
};
