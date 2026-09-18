const db = require('../config/database');
const { toBinaryUUID, fromBinaryUUID } = require('../helpers/uuid');
const { validateUuid } = require('../helpers/idParams');

function parseMetadata(value) {
  if (value == null) return null;
  if (typeof value === 'object') return value;
  try {
    return JSON.parse(value);
  } catch {
    return null;
  }
}

const AuditLogs = {
  async create({
    userId,
    action,
    entityType = null,
    entityId = null,
    summary,
    metadata = null,
    ipAddress = null,
    userAgent = null,
    deviceId = null,
  }) {
    const userIdBin = toBinaryUUID(userId);
    if (userIdBin == null) {
      throw new Error('Invalid userId for audit log');
    }

    const metadataJson =
      metadata == null
        ? null
        : typeof metadata === 'string'
          ? metadata
          : JSON.stringify(metadata);

    const [result] = await db.query(
      `INSERT INTO user_audit_logs
        (user_id, action, entity_type, entity_id, summary, metadata, ip_address, user_agent, device_id)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        userIdBin,
        action,
        entityType,
        entityId,
        summary,
        metadataJson,
        ipAddress,
        userAgent,
        deviceId,
      ]
    );
    return result;
  },

  async listAdmin({ page = 1, limit = 25, userId = null, action = null, q = null } = {}) {
    const pageNum = Math.max(1, parseInt(page, 10) || 1);
    const pageSize = Math.min(100, Math.max(1, parseInt(limit, 10) || 25));
    const offset = (pageNum - 1) * pageSize;

    const where = ['1=1'];
    const params = [];

    if (userId != null && String(userId).trim() !== '') {
      const idCheck = validateUuid(userId, 'userId');
      if (!idCheck.ok) {
        const error = new Error(idCheck.message);
        error.code = 'INVALID_USER_ID';
        throw error;
      }
      where.push('a.user_id = ?');
      params.push(toBinaryUUID(userId));
    }

    if (action != null && String(action).trim() !== '' && String(action).toUpperCase() !== 'ALL') {
      where.push('a.action = ?');
      params.push(String(action).trim().toUpperCase());
    }

    if (q != null && String(q).trim() !== '') {
      const like = `%${String(q).trim()}%`;
      where.push(
        `(u.full_name LIKE ? OR u.email LIKE ? OR u.mobile LIKE ? OR a.summary LIKE ? OR a.action LIKE ? OR a.entity_type LIKE ? OR CAST(a.entity_id AS CHAR) LIKE ?)`
      );
      params.push(like, like, like, like, like, like, like);
    }

    const whereClause = where.join(' AND ');

    const [countRows] = await db.query(
      `SELECT COUNT(*) AS total
       FROM user_audit_logs a
       JOIN users u ON u.id = a.user_id
       WHERE ${whereClause}`,
      params
    );
    const total = Number(countRows[0]?.total || 0);

    const [rows] = await db.query(
      `SELECT
         a.id,
         a.user_id,
         a.action,
         a.entity_type,
         a.entity_id,
         a.summary,
         a.metadata,
         a.ip_address,
         a.user_agent,
         a.device_id,
         a.created_at,
         u.full_name,
         u.email,
         u.mobile
       FROM user_audit_logs a
       JOIN users u ON u.id = a.user_id
       WHERE ${whereClause}
       ORDER BY a.created_at DESC, a.id DESC
       LIMIT ? OFFSET ?`,
      [...params, pageSize, offset]
    );

    const data = (rows || []).map((row) => ({
      id: row.id,
      user_id: fromBinaryUUID(row.user_id),
      name: row.full_name || 'N/A',
      email: row.email || null,
      mobile: row.mobile || null,
      action: row.action,
      entity_type: row.entity_type || null,
      entity_id: row.entity_id != null ? String(row.entity_id) : null,
      summary: row.summary,
      metadata: parseMetadata(row.metadata),
      ip_address: row.ip_address || null,
      user_agent: row.user_agent || null,
      device_id: row.device_id || null,
      created_at: row.created_at,
    }));

    return {
      data,
      pagination: {
        page: pageNum,
        limit: pageSize,
        total,
        pages: Math.max(1, Math.ceil(total / pageSize)),
      },
    };
  },
};

module.exports = AuditLogs;
