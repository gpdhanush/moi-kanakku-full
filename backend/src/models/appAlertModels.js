const db = require('../config/database');
const { toBinaryUUID, fromBinaryUUID } = require('../helpers/uuid');
const logger = require('../config/logger');

function isMissingTableError(error) {
  const code = String(error?.code || '');
  const message = String(error?.message || '').toLowerCase();
  return (
    code === 'ER_NO_SUCH_TABLE' ||
    message.includes("doesn't exist") ||
    message.includes('does not exist')
  );
}

function mapAlertRow(row) {
  if (!row) return null;
  return {
    id: fromBinaryUUID(row.id) || String(row.id),
    title: row.title,
    content: row.content,
    imageUrl: row.image_url || null,
    videoUrl: row.video_url || null,
    ctaLabel: row.cta_label || null,
    ctaUrl: row.cta_url || null,
    isActive: row.is_active === 1 || row.is_active === true,
    startsAt: row.starts_at || null,
    endsAt: row.ends_at || null,
    createdByAdminId: row.created_by_admin_id != null
      ? (fromBinaryUUID(row.created_by_admin_id) || String(row.created_by_admin_id))
      : null,
    createdAt: row.created_at || null,
    updatedAt: row.updated_at || null,
  };
}

const AppAlert = {
  async create(data) {
    try {
      const [result] = await db.query(
        `INSERT INTO app_alerts
          (title, content, image_url, video_url, cta_label, cta_url, is_active,
           starts_at, ends_at, created_by_admin_id, is_deleted, created_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, CURRENT_TIMESTAMP)`,
        [
          data.title,
          data.content,
          data.imageUrl || null,
          data.videoUrl || null,
          data.ctaLabel || null,
          data.ctaUrl || null,
          data.isActive === false ? 0 : 1,
          data.startsAt || null,
          data.endsAt || null,
          data.createdByAdminId != null
            ? toBinaryUUID(data.createdByAdminId)
            : null,
        ],
      );
      return await AppAlert.findById(result.insertId);
    } catch (error) {
      if (isMissingTableError(error)) {
        logger.warn('app_alerts table missing — run backend/database/app_alerts.sql');
        throw Object.assign(new Error('App alerts table is not installed.'), {
          code: 'APP_ALERTS_MISSING',
        });
      }
      throw error;
    }
  },

  async findById(alertId) {
    try {
      const [rows] = await db.query(
        `SELECT * FROM app_alerts
         WHERE id = ? AND (is_deleted = 0 OR is_deleted IS NULL)
         LIMIT 1`,
        [toBinaryUUID(alertId)],
      );
      return mapAlertRow(rows[0]);
    } catch (error) {
      if (isMissingTableError(error)) return null;
      throw error;
    }
  },

  async listAdmin({ limit = 50, offset = 0 } = {}) {
    try {
      const safeLimit = Math.min(Math.max(Number(limit) || 50, 1), 100);
      const safeOffset = Math.max(Number(offset) || 0, 0);

      const [countRows] = await db.query(
        `SELECT COUNT(*) AS total
         FROM app_alerts
         WHERE is_deleted = 0 OR is_deleted IS NULL`,
      );
      const [rows] = await db.query(
        `SELECT * FROM app_alerts
         WHERE is_deleted = 0 OR is_deleted IS NULL
         ORDER BY created_at DESC
         LIMIT ? OFFSET ?`,
        [safeLimit, safeOffset],
      );

      return {
        totalCount: Number(countRows[0]?.total) || 0,
        data: rows.map(mapAlertRow),
      };
    } catch (error) {
      if (isMissingTableError(error)) {
        return { totalCount: 0, data: [] };
      }
      throw error;
    }
  },

  async update(alertId, data) {
    const fields = [];
    const params = [];

    const map = {
      title: 'title',
      content: 'content',
      imageUrl: 'image_url',
      videoUrl: 'video_url',
      ctaLabel: 'cta_label',
      ctaUrl: 'cta_url',
      startsAt: 'starts_at',
      endsAt: 'ends_at',
    };

    for (const [key, column] of Object.entries(map)) {
      if (Object.prototype.hasOwnProperty.call(data, key)) {
        fields.push(`${column} = ?`);
        params.push(data[key] == null || data[key] === '' ? null : data[key]);
      }
    }

    if (Object.prototype.hasOwnProperty.call(data, 'isActive')) {
      fields.push('is_active = ?');
      params.push(data.isActive ? 1 : 0);
    }

    if (!fields.length) {
      return AppAlert.findById(alertId);
    }

    params.push(toBinaryUUID(alertId));
    await db.query(
      `UPDATE app_alerts SET ${fields.join(', ')}, updated_at = CURRENT_TIMESTAMP
       WHERE id = ? AND (is_deleted = 0 OR is_deleted IS NULL)`,
      params,
    );
    return AppAlert.findById(alertId);
  },

  async softDelete(alertId) {
    const [result] = await db.query(
      `UPDATE app_alerts
       SET is_active = 0, is_deleted = 1, deleted_at = CURRENT_TIMESTAMP
       WHERE id = ? AND (is_deleted = 0 OR is_deleted IS NULL)`,
      [toBinaryUUID(alertId)],
    );
    return Number(result.affectedRows) || 0;
  },

  /**
   * Latest active alert the user should see now.
   * Skips alerts marked dont_show; allows remind_later only when remind_at <= now.
   */
  async findActiveForUser(userId) {
    try {
      const [rows] = await db.query(
        `SELECT a.*
         FROM app_alerts a
         LEFT JOIN app_alert_user_states s
           ON s.alert_id = a.id AND s.user_id = ?
         WHERE (a.is_deleted = 0 OR a.is_deleted IS NULL)
           AND a.is_active = 1
           AND (a.starts_at IS NULL OR a.starts_at <= NOW())
           AND (a.ends_at IS NULL OR a.ends_at >= NOW())
           AND (
             s.id IS NULL
             OR (s.status = 'remind_later' AND s.remind_at IS NOT NULL AND s.remind_at <= NOW())
           )
         ORDER BY a.created_at DESC
         LIMIT 1`,
        [toBinaryUUID(userId)],
      );
      return mapAlertRow(rows[0]);
    } catch (error) {
      if (isMissingTableError(error)) return null;
      throw error;
    }
  },

  async upsertUserState({ alertId, userId, status, remindAt = null }) {
    try {
      await db.query(
        `INSERT INTO app_alert_user_states
           (alert_id, user_id, status, remind_at, created_at, updated_at)
         VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
         ON DUPLICATE KEY UPDATE
           status = VALUES(status),
           remind_at = VALUES(remind_at),
           updated_at = CURRENT_TIMESTAMP`,
        [
          toBinaryUUID(alertId),
          toBinaryUUID(userId),
          status,
          remindAt,
        ],
      );
      return true;
    } catch (error) {
      if (isMissingTableError(error)) {
        throw Object.assign(new Error('App alerts table is not installed.'), {
          code: 'APP_ALERTS_MISSING',
        });
      }
      throw error;
    }
  },
};

module.exports = { AppAlert };
