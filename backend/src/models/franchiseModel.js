const pool = require('../config/database');
const logger = require('../config/logger');

const FranchiseModel = {
  // ==========================================
  // FRANCHISE CRUD
  // ==========================================
  async createFranchise(franchiseData, client = pool) {
    const { name, code, mobile, email, address, city, state, pincode, status } = franchiseData;
    const sql = `
      INSERT INTO franchises (name, code, mobile, email, address, city, state, pincode, status)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;
    const [result] = await client.query(sql, [
      name, code, mobile || null, email || null, address || null,
      city || null, state || null, pincode || null, status || 'ACTIVE'
    ]);
    return result.insertId;
  },

  async findFranchiseById(id, client = pool) {
    const sql = `SELECT * FROM franchises WHERE id = ? AND is_deleted = 0`;
    const [rows] = await client.query(sql, [id]);
    return rows[0] || null;
  },

  async findFranchiseByCode(code, client = pool) {
    const sql = `SELECT * FROM franchises WHERE code = ? AND is_deleted = 0`;
    const [rows] = await client.query(sql, [code]);
    return rows[0] || null;
  },

  async findAllFranchises({ limit = 20, offset = 0, search = '' }, client = pool) {
    let sql = `SELECT * FROM franchises WHERE is_deleted = 0`;
    const params = [];

    if (search && search.trim() !== '') {
      sql += ` AND (name LIKE ? OR code LIKE ? OR city LIKE ? OR mobile LIKE ?)`;
      const term = `%${search.trim()}%`;
      params.push(term, term, term, term);
    }

    sql += ` ORDER BY id DESC LIMIT ? OFFSET ?`;
    params.push(Number(limit), Number(offset));

    const [rows] = await client.query(sql, params);

    let countSql = `SELECT COUNT(*) AS total FROM franchises WHERE is_deleted = 0`;
    const countParams = [];
    if (search && search.trim() !== '') {
      countSql += ` AND (name LIKE ? OR code LIKE ? OR city LIKE ? OR mobile LIKE ?)`;
      const term = `%${search.trim()}%`;
      countParams.push(term, term, term, term);
    }

    const [countRows] = await client.query(countSql, countParams);
    return { data: rows, total: countRows[0].total };
  },

  async updateFranchise(id, franchiseData, client = pool) {
    const fields = [];
    const params = [];

    const allowedFields = ['name', 'mobile', 'email', 'address', 'city', 'state', 'pincode', 'status'];
    for (const key of allowedFields) {
      if (franchiseData[key] !== undefined) {
        fields.push(`${key} = ?`);
        params.push(franchiseData[key]);
      }
    }

    if (fields.length === 0) return false;

    params.push(id);
    const sql = `UPDATE franchises SET ${fields.join(', ')} WHERE id = ? AND is_deleted = 0`;
    const [result] = await client.query(sql, params);
    return result.affectedRows > 0;
  },

  async updateFranchiseStatus(id, status, client = pool) {
    const sql = `UPDATE franchises SET status = ? WHERE id = ? AND is_deleted = 0`;
    const [result] = await client.query(sql, [status, id]);
    return result.affectedRows > 0;
  },

  // ==========================================
  // FRANCHISE ADMINS
  // ==========================================
  async assignFranchiseAdmin(franchiseId, adminId, client = pool) {
    const sql = `
      INSERT INTO franchise_admins (franchise_id, admin_id, status)
      VALUES (?, ?, 'ACTIVE')
      ON DUPLICATE KEY UPDATE status = 'ACTIVE', updated_at = CURRENT_TIMESTAMP
    `;
    const [result] = await client.query(sql, [franchiseId, adminId]);
    return result.insertId || true;
  },

  async removeFranchiseAdmin(franchiseId, adminId, client = pool) {
    const sql = `UPDATE franchise_admins SET status = 'REVOKED' WHERE franchise_id = ? AND admin_id = ?`;
    const [result] = await client.query(sql, [franchiseId, adminId]);
    return result.affectedRows > 0;
  },

  async findFranchiseAdminByAdminId(adminId, client = pool) {
    const sql = `
      SELECT fa.*, f.name AS franchise_name, f.code AS franchise_code, f.status AS franchise_status
      FROM franchise_admins fa
      JOIN franchises f ON fa.franchise_id = f.id
      WHERE fa.admin_id = ? AND fa.status = 'ACTIVE' AND f.is_deleted = 0 AND f.status = 'ACTIVE'
    `;
    const [rows] = await client.query(sql, [adminId]);
    return rows[0] || null;
  },

  async findAdminsByFranchiseId(franchiseId, client = pool) {
    const sql = `
      SELECT a.id, a.full_name, a.email, a.mobile, fa.status, fa.created_at AS assigned_at
      FROM franchise_admins fa
      JOIN admins a ON fa.admin_id = a.id
      WHERE fa.franchise_id = ? AND a.is_deleted = 0
    `;
    const [rows] = await client.query(sql, [franchiseId]);
    return rows;
  },

  // ==========================================
  // FRANCHISE STAFF
  // ==========================================
  async assignFranchiseStaff(franchiseId, userId, client = pool) {
    const sql = `
      INSERT INTO franchise_staff (franchise_id, user_id, status)
      VALUES (?, ?, 'ACTIVE')
      ON DUPLICATE KEY UPDATE status = 'ACTIVE', updated_at = CURRENT_TIMESTAMP
    `;
    const [result] = await client.query(sql, [franchiseId, userId]);
    return result.insertId || true;
  },

  async findStaffByUserId(userId, client = pool) {
    const sql = `
      SELECT fs.*, f.name AS franchise_name, f.code AS franchise_code, f.status AS franchise_status
      FROM franchise_staff fs
      JOIN franchises f ON fs.franchise_id = f.id
      WHERE fs.user_id = ? AND fs.status = 'ACTIVE' AND f.is_deleted = 0 AND f.status = 'ACTIVE'
    `;
    const [rows] = await client.query(sql, [userId]);
    return rows[0] || null;
  },

  async findStaffByFranchiseId(franchiseId, client = pool) {
    const sql = `
      SELECT u.id, u.full_name, u.email, u.mobile, fs.status, fs.created_at AS joined_at
      FROM franchise_staff fs
      JOIN users u ON fs.user_id = u.id
      WHERE fs.franchise_id = ? AND u.is_deleted = 0
    `;
    const [rows] = await client.query(sql, [franchiseId]);
    return rows;
  },

  async updateStaffStatus(franchiseId, userId, status, client = pool) {
    const sql = `UPDATE franchise_staff SET status = ? WHERE franchise_id = ? AND user_id = ?`;
    const [result] = await client.query(sql, [status, franchiseId, userId]);
    return result.affectedRows > 0;
  },

  // ==========================================
  // FRANCHISE CUSTOMERS
  // ==========================================
  async linkFranchiseCustomer(franchiseId, userId, customerCode = null, client = pool) {
    const sql = `
      INSERT INTO franchise_customers (franchise_id, user_id, customer_code, status)
      VALUES (?, ?, ?, 'ACTIVE')
      ON DUPLICATE KEY UPDATE status = 'ACTIVE', customer_code = COALESCE(?, customer_code), updated_at = CURRENT_TIMESTAMP
    `;
    const [result] = await client.query(sql, [franchiseId, userId, customerCode, customerCode]);
    return result.insertId || true;
  },

  async findCustomerByUserId(userId, client = pool) {
    const sql = `
      SELECT fc.*, f.name AS franchise_name, f.code AS franchise_code, f.status AS franchise_status
      FROM franchise_customers fc
      JOIN franchises f ON fc.franchise_id = f.id
      WHERE fc.user_id = ? AND fc.status = 'ACTIVE' AND f.is_deleted = 0 AND f.status = 'ACTIVE'
    `;
    const [rows] = await client.query(sql, [userId]);
    return rows[0] || null;
  },

  async findCustomersByFranchiseId(franchiseId, { limit = 50, offset = 0, search = '' }, client = pool) {
    let sql = `
      SELECT u.id, u.full_name, u.email, u.mobile, fc.customer_code, fc.status, fc.joined_at,
             up.city, up.profile_image_url
      FROM franchise_customers fc
      JOIN users u ON fc.user_id = u.id
      LEFT JOIN user_profiles up ON u.id = up.user_id
      WHERE fc.franchise_id = ? AND u.is_deleted = 0
    `;
    const params = [franchiseId];

    if (search && search.trim() !== '') {
      sql += ` AND (u.full_name LIKE ? OR u.mobile LIKE ? OR u.email LIKE ? OR fc.customer_code LIKE ?)`;
      const term = `%${search.trim()}%`;
      params.push(term, term, term, term);
    }

    sql += ` ORDER BY fc.id DESC LIMIT ? OFFSET ?`;
    params.push(Number(limit), Number(offset));

    const [rows] = await client.query(sql, params);

    let countSql = `
      SELECT COUNT(*) AS total
      FROM franchise_customers fc
      JOIN users u ON fc.user_id = u.id
      WHERE fc.franchise_id = ? AND u.is_deleted = 0
    `;
    const countParams = [franchiseId];
    if (search && search.trim() !== '') {
      countSql += ` AND (u.full_name LIKE ? OR u.mobile LIKE ? OR u.email LIKE ? OR fc.customer_code LIKE ?)`;
      const term = `%${search.trim()}%`;
      countParams.push(term, term, term, term);
    }

    const [countRows] = await client.query(countSql, countParams);
    return { data: rows, total: countRows[0].total };
  },

  async updateCustomerStatus(franchiseId, userId, status, client = pool) {
    const removedAt = status === 'REMOVED' ? new Date() : null;
    const sql = `UPDATE franchise_customers SET status = ?, removed_at = ? WHERE franchise_id = ? AND user_id = ?`;
    const [result] = await client.query(sql, [status, removedAt, franchiseId, userId]);
    return result.affectedRows > 0;
  },

  async searchUsersForCustomerLinking(searchTerm, client = pool) {
    const term = `%${searchTerm.trim()}%`;
    const sql = `
      SELECT u.id, u.full_name, u.email, u.mobile, up.city, up.profile_image_url
      FROM users u
      LEFT JOIN user_profiles up ON u.id = up.user_id
      WHERE u.is_deleted = 0 AND (u.full_name LIKE ? OR u.mobile LIKE ? OR u.email LIKE ?)
      LIMIT 10
    `;
    const [rows] = await client.query(sql, [term, term, term]);
    return rows;
  },

  // ==========================================
  // FRANCHISE FUNCTIONS
  // ==========================================
  async linkFranchiseFunction(franchiseId, functionId, customerUserId, adminId = null, client = pool) {
    const sql = `
      INSERT INTO franchise_functions (franchise_id, function_id, customer_user_id, status, created_by_admin_id)
      VALUES (?, ?, ?, 'ACTIVE', ?)
      ON DUPLICATE KEY UPDATE status = 'ACTIVE', updated_at = CURRENT_TIMESTAMP
    `;
    const [result] = await client.query(sql, [franchiseId, functionId, customerUserId, adminId]);
    return result.insertId || true;
  },

  async findFranchiseFunction(franchiseId, functionId, client = pool) {
    const sql = `
      SELECT ff.*, tf.function_name, tf.function_date, tf.location, tf.notes, tf.image_url,
             u.full_name AS customer_name, u.mobile AS customer_mobile
      FROM franchise_functions ff
      JOIN transaction_functions tf ON ff.function_id = tf.id
      JOIN users u ON ff.customer_user_id = u.id
      WHERE ff.franchise_id = ? AND ff.function_id = ? AND tf.is_deleted = 0
    `;
    const [rows] = await client.query(sql, [franchiseId, functionId]);
    return rows[0] || null;
  },

  async findFunctionsByFranchiseId(franchiseId, { limit = 50, offset = 0, search = '' }, client = pool) {
    let sql = `
      SELECT ff.*, tf.function_name, tf.function_date, tf.location, tf.notes, tf.image_url,
             u.full_name AS customer_name, u.mobile AS customer_mobile
      FROM franchise_functions ff
      JOIN transaction_functions tf ON ff.function_id = tf.id
      JOIN users u ON ff.customer_user_id = u.id
      WHERE ff.franchise_id = ? AND tf.is_deleted = 0
    `;
    const params = [franchiseId];

    if (search && search.trim() !== '') {
      sql += ` AND (tf.function_name LIKE ? OR u.full_name LIKE ? OR u.mobile LIKE ?)`;
      const term = `%${search.trim()}%`;
      params.push(term, term, term);
    }

    sql += ` ORDER BY tf.function_date DESC LIMIT ? OFFSET ?`;
    params.push(Number(limit), Number(offset));

    const [rows] = await client.query(sql, params);

    let countSql = `
      SELECT COUNT(*) AS total
      FROM franchise_functions ff
      JOIN transaction_functions tf ON ff.function_id = tf.id
      JOIN users u ON ff.customer_user_id = u.id
      WHERE ff.franchise_id = ? AND tf.is_deleted = 0
    `;
    const countParams = [franchiseId];
    if (search && search.trim() !== '') {
      countSql += ` AND (tf.function_name LIKE ? OR u.full_name LIKE ? OR u.mobile LIKE ?)`;
      const term = `%${search.trim()}%`;
      countParams.push(term, term, term);
    }

    const [countRows] = await client.query(countSql, countParams);
    return { data: rows, total: countRows[0].total };
  },

  async findFunctionsByCustomerUserId(franchiseId, customerUserId, client = pool) {
    const sql = `
      SELECT ff.*, tf.function_name, tf.function_date, tf.location, tf.notes, tf.image_url
      FROM franchise_functions ff
      JOIN transaction_functions tf ON ff.function_id = tf.id
      WHERE ff.franchise_id = ? AND ff.customer_user_id = ? AND ff.status = 'ACTIVE' AND tf.is_deleted = 0
      ORDER BY tf.function_date DESC
    `;
    const [rows] = await client.query(sql, [franchiseId, customerUserId]);
    return rows;
  },

  async updateFranchiseFunctionStatus(franchiseId, functionId, status, client = pool) {
    const sql = `UPDATE franchise_functions SET status = ? WHERE franchise_id = ? AND function_id = ?`;
    const [result] = await client.query(sql, [status, franchiseId, functionId]);
    return result.affectedRows > 0;
  },

  // ==========================================
  // FRANCHISE STAFF FUNCTION ACCESS
  // ==========================================
  async setStaffFunctionAccess(accessData, client = pool) {
    const {
      franchise_id, staff_user_id, function_id,
      can_view = 1, can_add_customer = 0, can_edit_customer = 0,
      can_add_transaction = 1, can_edit_transaction = 0,
      can_delete_transaction = 0, can_view_report = 0,
      created_by_admin_id = null
    } = accessData;

    const sql = `
      INSERT INTO franchise_staff_function_access (
        franchise_id, staff_user_id, function_id, status,
        can_view, can_add_customer, can_edit_customer,
        can_add_transaction, can_edit_transaction, can_delete_transaction, can_view_report,
        created_by_admin_id
      )
      VALUES (?, ?, ?, 'ACTIVE', ?, ?, ?, ?, ?, ?, ?, ?)
      ON DUPLICATE KEY UPDATE
        status = 'ACTIVE',
        can_view = VALUES(can_view),
        can_add_customer = VALUES(can_add_customer),
        can_edit_customer = VALUES(can_edit_customer),
        can_add_transaction = VALUES(can_add_transaction),
        can_edit_transaction = VALUES(can_edit_transaction),
        can_delete_transaction = VALUES(can_delete_transaction),
        can_view_report = VALUES(can_view_report),
        created_by_admin_id = VALUES(created_by_admin_id),
        updated_at = CURRENT_TIMESTAMP
    `;
    const [result] = await client.query(sql, [
      franchise_id, staff_user_id, function_id,
      can_view ? 1 : 0, can_add_customer ? 1 : 0, can_edit_customer ? 1 : 0,
      can_add_transaction ? 1 : 0, can_edit_transaction ? 1 : 0,
      can_delete_transaction ? 1 : 0, can_view_report ? 1 : 0,
      created_by_admin_id
    ]);
    return result.insertId || true;
  },

  async revokeStaffFunctionAccess(franchiseId, staffUserId, functionId, client = pool) {
    const sql = `
      UPDATE franchise_staff_function_access
      SET status = 'REVOKED'
      WHERE franchise_id = ? AND staff_user_id = ? AND function_id = ?
    `;
    const [result] = await client.query(sql, [franchiseId, staffUserId, functionId]);
    return result.affectedRows > 0;
  },

  async getStaffFunctionAccess(franchiseId, staffUserId, functionId, client = pool) {
    const sql = `
      SELECT sfsa.*, fs.status AS staff_status
      FROM franchise_staff_function_access sfsa
      JOIN franchise_staff fs ON sfsa.franchise_id = fs.franchise_id AND sfsa.staff_user_id = fs.user_id
      WHERE sfsa.franchise_id = ? AND sfsa.staff_user_id = ? AND sfsa.function_id = ?
    `;
    const [rows] = await client.query(sql, [franchiseId, staffUserId, functionId]);
    return rows[0] || null;
  },

  async getAssignedFunctionsForStaff(franchiseId, staffUserId, client = pool) {
    const sql = `
      SELECT sfsa.*, tf.function_name, tf.function_date, tf.location, tf.notes, tf.image_url,
             u.full_name AS customer_name, u.mobile AS customer_mobile
      FROM franchise_staff_function_access sfsa
      JOIN transaction_functions tf ON sfsa.function_id = tf.id
      JOIN franchise_functions ff ON sfsa.franchise_id = ff.franchise_id AND sfsa.function_id = ff.function_id
      JOIN users u ON ff.customer_user_id = u.id
      WHERE sfsa.franchise_id = ? AND sfsa.staff_user_id = ? AND sfsa.status = 'ACTIVE'
        AND ff.status = 'ACTIVE' AND tf.is_deleted = 0
      ORDER BY tf.function_date DESC
    `;
    const [rows] = await client.query(sql, [franchiseId, staffUserId]);
    return rows;
  },

  async getStaffForFunction(franchiseId, functionId, client = pool) {
    const sql = `
      SELECT sfsa.*, u.full_name, u.email, u.mobile
      FROM franchise_staff_function_access sfsa
      JOIN users u ON sfsa.staff_user_id = u.id
      WHERE sfsa.franchise_id = ? AND sfsa.function_id = ? AND u.is_deleted = 0
    `;
    const [rows] = await client.query(sql, [franchiseId, functionId]);
    return rows;
  },

  // ==========================================
  // FRANCHISE AUDIT LOGS
  // ==========================================
  async createAuditLog(logData, client = pool) {
    const {
      franchise_id, actor_type, actor_user_id = null, actor_admin_id = null,
      action, entity_type = null, entity_id = null, description = null,
      old_values = null, new_values = null, ip_address = null, user_agent = null
    } = logData;

    const sql = `
      INSERT INTO franchise_audit_logs (
        franchise_id, actor_type, actor_user_id, actor_admin_id, action,
        entity_type, entity_id, description, old_values, new_values, ip_address, user_agent
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;

    const oldValStr = typeof old_values === 'object' ? JSON.stringify(old_values) : old_values;
    const newValStr = typeof new_values === 'object' ? JSON.stringify(new_values) : new_values;

    const [result] = await client.query(sql, [
      franchise_id, actor_type, actor_user_id, actor_admin_id, action,
      entity_type, entity_id, description, oldValStr, newValStr, ip_address, user_agent
    ]);
    return result.insertId;
  },

  async getAuditLogsByFranchiseId(franchiseId, { limit = 50, offset = 0 }, client = pool) {
    const sql = `
      SELECT fal.*,
             COALESCE(u.full_name, a.full_name) AS actor_name
      FROM franchise_audit_logs fal
      LEFT JOIN users u ON fal.actor_user_id = u.id
      LEFT JOIN admins a ON fal.actor_admin_id = a.id
      WHERE fal.franchise_id = ?
      ORDER BY fal.id DESC
      LIMIT ? OFFSET ?
    `;
    const [rows] = await client.query(sql, [franchiseId, Number(limit), Number(offset)]);

    const countSql = `SELECT COUNT(*) AS total FROM franchise_audit_logs WHERE franchise_id = ?`;
    const [countRows] = await client.query(countSql, [franchiseId]);

    return { data: rows, total: countRows[0].total };
  },

  // ==========================================
  // TRANSACTION EXTRA METHODS
  // ==========================================
  async getTransactionsByFunctionId(functionId, { limit = 50, offset = 0, type = null }, client = pool) {
    let sql = `
      SELECT t.*, p.first_name, p.last_name, p.mobile AS person_mobile, p.city AS person_city
      FROM transactions t
      JOIN persons p ON t.person_id = p.id
      WHERE t.transaction_function_id = ? AND t.is_deleted = 0
    `;
    const params = [functionId];

    if (type) {
      sql += ` AND t.type = ?`;
      params.push(type);
    }

    sql += ` ORDER BY t.transaction_date DESC, t.id DESC LIMIT ? OFFSET ?`;
    params.push(Number(limit), Number(offset));

    const [rows] = await client.query(sql, params);

    let countSql = `SELECT COUNT(*) AS total FROM transactions WHERE transaction_function_id = ? AND is_deleted = 0`;
    const countParams = [functionId];
    if (type) {
      countSql += ` AND type = ?`;
      countParams.push(type);
    }

    const [countRows] = await client.query(countSql, countParams);
    return { data: rows, total: countRows[0].total };
  },

  async updateTransaction(txId, txData, client = pool) {
    const fields = [];
    const params = [];
    const allowed = ['amount', 'type', 'transaction_date', 'notes', 'item_name'];
    for (const key of allowed) {
      if (txData[key] !== undefined) {
        fields.push(`${key} = ?`);
        params.push(txData[key]);
      }
    }
    if (fields.length === 0) return false;
    params.push(txId);

    const sql = `UPDATE transactions SET ${fields.join(', ')} WHERE id = ? AND is_deleted = 0`;
    const [result] = await client.query(sql, params);
    return result.affectedRows > 0;
  },

  async deleteTransaction(txId, client = pool) {
    const sql = `UPDATE transactions SET is_deleted = 1, deleted_at = CURRENT_TIMESTAMP WHERE id = ?`;
    const [result] = await client.query(sql, [txId]);
    return result.affectedRows > 0;
  },

  async getPersonsForFunction(functionId, client = pool) {
    const sql = `
      SELECT p.*
      FROM franchise_functions ff
      JOIN persons p ON ff.customer_user_id = p.user_id
      WHERE ff.function_id = ?
      ORDER BY p.first_name ASC
    `;
    const [rows] = await client.query(sql, [functionId]);
    return rows;
  },

  // ==========================================
  // FRANCHISE FINANCIAL REPORTS / SUMMARY
  // ==========================================
  async getFranchiseReport(franchiseId, client = pool) {
    const sql = `
      SELECT 
        COUNT(DISTINCT ff.function_id) AS total_functions,
        COUNT(DISTINCT fc.user_id) AS total_customers,
        COUNT(DISTINCT fs.user_id) AS total_staff,
        COALESCE(SUM(CASE WHEN t.type = 'INVEST' AND t.is_deleted = 0 THEN t.amount ELSE 0 END), 0) AS total_invest_amount,
        COALESCE(SUM(CASE WHEN t.type = 'RETURN' AND t.is_deleted = 0 THEN t.amount ELSE 0 END), 0) AS total_return_amount,
        COUNT(CASE WHEN t.is_deleted = 0 THEN t.id END) AS total_transactions
      FROM franchises f
      LEFT JOIN franchise_functions ff ON f.id = ff.franchise_id AND ff.status = 'ACTIVE'
      LEFT JOIN franchise_customers fc ON f.id = fc.franchise_id AND fc.status = 'ACTIVE'
      LEFT JOIN franchise_staff fs ON f.id = fs.franchise_id AND fs.status = 'ACTIVE'
      LEFT JOIN transactions t ON ff.function_id = t.transaction_function_id AND t.is_deleted = 0
      WHERE f.id = ?
      GROUP BY f.id
    `;
    const [rows] = await client.query(sql, [franchiseId]);
    return rows[0] || {
      total_functions: 0,
      total_customers: 0,
      total_staff: 0,
      total_invest_amount: 0,
      total_return_amount: 0,
      total_transactions: 0
    };
  }
};

module.exports = FranchiseModel;
