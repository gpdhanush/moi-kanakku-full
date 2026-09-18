// Admin controllers for system management and monitoring
const db = require('../config/database');
const { fromBinaryUUID } = require('../helpers/uuid');
const logger = require('../config/logger');
const AuditLogs = require('../models/auditLogs');

exports.adminControllers = {
  /**
   * List all OTPs with user details
   * Query params: ?page=1&limit=25&type=LOGIN&is_used=0
   */
  listOTPs: async (req, res) => {
    try {
      const { page = 1, limit = 25, type, is_used } = req.query;
      const offset = (parseInt(page) - 1) * parseInt(limit);
      const pageSize = parseInt(limit);

      // Build query with optional filters
      let query = `
        SELECT 
          o.id,
          o.user_id,
          u.full_name as username,
          u.email,
          u.mobile,
          o.code,
          o.type,
          o.expires_at,
          o.is_used,
          o.created_at
        FROM user_otps o
        JOIN users u ON o.user_id = u.id
        WHERE 1=1
      `;
      const params = [];

      // Add filters
      if (type) {
        query += ` AND o.type = ?`;
        params.push(type);
      }
      if (is_used !== undefined) {
        query += ` AND o.is_used = ?`;
        params.push(parseInt(is_used));
      }

      query += ` ORDER BY o.created_at DESC LIMIT ? OFFSET ?`;
      params.push(pageSize, offset);

      const [rows] = await db.query(query, params);

      // Convert binary user_id to UUID string
      const formattedOTPs = rows.map(row => ({
        id: row.id,
        user_id: fromBinaryUUID(row.user_id),
        name: row.username || row.name || "N/A",
        email: row.email,
        mobile: row.mobile,
        code: row.code,
        type: row.type,
        expires_at: row.expires_at,
        is_used: row.is_used === 1 ? true : false,
        created_at: row.created_at,
      }));

      // Get total count
      let countQuery = `SELECT COUNT(*) as total FROM user_otps o WHERE 1=1`;
      const countParams = [];

      if (type) {
        countQuery += ` AND o.type = ?`;
        countParams.push(type);
      }
      if (is_used !== undefined) {
        countQuery += ` AND o.is_used = ?`;
        countParams.push(parseInt(is_used));
      }

      const [countResult] = await db.query(countQuery, countParams);
      const total = countResult[0].total;

      return res.status(200).json({
        responseType: "S",
        responseValue: {
          message: "OTP list retrieved successfully",
          data: formattedOTPs,
          pagination: {
            page: parseInt(page),
            limit: pageSize,
            total: total,
            pages: Math.ceil(total / pageSize),
          },
        },
      });
    } catch (error) {
      logger.error("Error listing OTPs:", error);
      return res.status(500).json({
        responseType: "F",
        responseValue: { message: error.toString() },
      });
    }
  },

  /**
   * Delete expired OTPs (cleanup)
   * Options via Query/Body: ?type=LOGIN&include_used=true
   */
  deleteExpiredOTPs: async (req, res) => {
    try {
      const { type, include_used } = { ...req.query, ...req.body };

      let query = `DELETE FROM user_otps WHERE (expires_at <= NOW()`;
      
      // If include_used is explicitly passed as true, also clean up used OTPs
      if (include_used === 'true' || include_used === true || include_used === '1') {
        query += ` OR is_used = 1`;
      }
      query += `)`;

      const params = [];
      if (type) {
        query += ` AND type = ?`;
        params.push(type);
      }

      const [result] = await db.query(query, params);

      logger.info(`Deleted ${result.affectedRows} expired/used OTPs`);

      return res.status(200).json({
        responseType: "S",
        responseValue: {
          message: "Expired OTPs deleted successfully",
          deleted_count: result.affectedRows,
        },
      });
    } catch (error) {
      logger.error("Error deleting expired OTPs:", error);
      return res.status(500).json({
        responseType: "F",
        responseValue: { message: error.toString() },
      });
    }
  },

  /**
   * Clear OTPs by scope: used | unused | all
   * Body: { scope }
   */
  clearOTPs: async (req, res) => {
    try {
      const scope = String(req.body?.scope || req.query?.scope || '').toLowerCase();
      let query;
      let label;

      if (scope === 'used') {
        query = 'DELETE FROM user_otps WHERE is_used = 1';
        label = 'used';
      } else if (scope === 'unused') {
        query = 'DELETE FROM user_otps WHERE is_used = 0';
        label = 'unused';
      } else if (scope === 'all') {
        query = 'DELETE FROM user_otps';
        label = 'all';
      } else {
        return res.status(400).json({
          responseType: 'F',
          responseValue: { message: 'scope must be used, unused, or all.' },
        });
      }

      const [result] = await db.query(query);
      logger.info(`Cleared ${result.affectedRows} ${label} OTPs`);

      return res.status(200).json({
        responseType: 'S',
        responseValue: {
          message: `Deleted ${result.affectedRows} ${label} OTP record(s).`,
          deleted_count: result.affectedRows,
          scope,
        },
      });
    } catch (error) {
      logger.error('Error clearing OTPs:', error);
      return res.status(500).json({
        responseType: 'F',
        responseValue: { message: error.toString() },
      });
    }
  },

  /**
   * List mobile user audit logs
   * Query: ?page=1&limit=25&userId=&action=&q=
   */
  listAuditLogs: async (req, res) => {
    try {
      const { page = 1, limit = 25, userId, action, q } = req.query;
      const result = await AuditLogs.listAdmin({
        page,
        limit,
        userId,
        action,
        q,
      });

      return res.status(200).json({
        responseType: 'S',
        responseValue: {
          message: 'Audit logs retrieved successfully',
          data: result.data,
          pagination: result.pagination,
        },
      });
    } catch (error) {
      if (error?.code === 'INVALID_USER_ID') {
        return res.status(400).json({
          responseType: 'F',
          responseValue: { message: error.message },
        });
      }
      logger.error('Error listing audit logs:', error);
      return res.status(500).json({
        responseType: 'F',
        responseValue: { message: error.toString() },
      });
    }
  },
};
