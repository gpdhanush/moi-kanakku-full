const db = require('../config/database');
const { toBinaryUUID, fromBinaryUUID } = require('../helpers/uuid');
const { LIFETIME_PLAN } = require('../config/exportPayment');

const STATUSES = ['pending', 'approved', 'rejected'];

function mapRow(r) {
    if (!r) return null;
    return {
        id: fromBinaryUUID(r.id),
        userId: fromBinaryUUID(r.user_id),
        userName: r.full_name ?? null,
        userEmail: r.email ?? null,
        userMobile: r.mobile ?? null,
        amount: r.amount != null ? Number(r.amount) : null,
        plan: r.plan ?? null,
        upiTxnId: r.upi_txn_id,
        exportsAllowed: r.exports_allowed != null ? Number(r.exports_allowed) : null,
        exportsUsed: r.exports_used != null ? Number(r.exports_used) : null,
        status: r.status,
        adminRemarks: r.admin_remarks,
        reviewedBy: r.reviewed_by != null ? fromBinaryUUID(r.reviewed_by) : null,
        reviewedByName: r.reviewer_name ?? null,
        reviewedAt: r.reviewed_at,
        createdAt: r.created_at,
        updatedAt: r.updated_at,
    };
}

const SELECT_WITH_USER = `
    SELECT p.id, p.user_id, p.amount, p.plan, p.upi_txn_id, p.status, p.exports_allowed, p.exports_used, p.admin_remarks,
           p.reviewed_by, p.reviewed_at, p.created_at, p.updated_at,
           u.full_name, u.email, u.mobile, a.full_name AS reviewer_name
    FROM export_payments p
    LEFT JOIN users u ON u.id = p.user_id
    LEFT JOIN admins a ON a.id = p.reviewed_by`;

const Model = {
    STATUSES,

    async create({ userId, upiTxnId, amount, plan }) {
        const [result] = await db.query(
            `INSERT INTO export_payments (user_id, amount, plan, upi_txn_id, status)
             VALUES (?, ?, ?, ?, 'pending')`,
            [toBinaryUUID(userId), amount, plan, upiTxnId]
        );
        return { insertId: String(result.insertId) };
    },

    async findByTxnId(upiTxnId) {
        const [rows] = await db.query(
            `SELECT id, user_id, status FROM export_payments WHERE upi_txn_id = ? LIMIT 1`,
            [upiTxnId]
        );
        return rows[0] ? mapRow(rows[0]) : null;
    },

    async readById(id) {
        const [rows] = await db.query(`${SELECT_WITH_USER} WHERE p.id = ? LIMIT 1`, [toBinaryUUID(id)]);
        return mapRow(rows[0]);
    },

    /** Latest submissions for a user, newest first. */
    async listForUser(userId, limit = 10) {
        const [rows] = await db.query(
            `${SELECT_WITH_USER} WHERE p.user_id = ? ORDER BY p.created_at DESC, p.id DESC LIMIT ?`,
            [toBinaryUUID(userId), limit]
        );
        return rows.map(mapRow);
    },

    /** Unused PDF exports across the user's approved counted (non-lifetime) payments. */
    async remainingExports(userId) {
        const [[row]] = await db.query(
            `SELECT COALESCE(SUM(GREATEST(exports_allowed - exports_used, 0)), 0) AS remaining
             FROM export_payments
             WHERE user_id = ? AND status = 'approved' AND (plan IS NULL OR plan <> ?)`,
            [toBinaryUUID(userId), LIFETIME_PLAN]
        );
        return Number(row?.remaining || 0);
    },

    /** True once the user has an approved lifetime payment (unlimited exports). */
    async hasLifetime(userId) {
        const [[row]] = await db.query(
            `SELECT 1 AS found FROM export_payments
             WHERE user_id = ? AND status = 'approved' AND plan = ? LIMIT 1`,
            [toBinaryUUID(userId), LIFETIME_PLAN]
        );
        return Boolean(row?.found);
    },

    /** Exports granted by the user's most recently approved counted payment. */
    async latestApprovedAllowance(userId) {
        const [[row]] = await db.query(
            `SELECT exports_allowed FROM export_payments
             WHERE user_id = ? AND status = 'approved' AND (plan IS NULL OR plan <> ?)
             ORDER BY reviewed_at DESC, id DESC LIMIT 1`,
            [toBinaryUUID(userId), LIFETIME_PLAN]
        );
        return row ? Number(row.exports_allowed || 0) : null;
    },

    /**
     * Use one export from the oldest approved payment that still has some.
     * A single conditional UPDATE, so parallel requests cannot overspend.
     */
    async consumeExport(userId) {
        const [result] = await db.query(
            `UPDATE export_payments
             SET exports_used = exports_used + 1
             WHERE user_id = ? AND status = 'approved' AND exports_used < exports_allowed
               AND (plan IS NULL OR plan <> ?)
             ORDER BY reviewed_at ASC, id ASC
             LIMIT 1`,
            [toBinaryUUID(userId), LIFETIME_PLAN]
        );
        return (result.affectedRows || 0) > 0;
    },

    async listAll({ status = null, search = null, limit = 25, offset = 0 } = {}) {
        const where = [];
        const params = [];
        if (status) {
            where.push('p.status = ?');
            params.push(status);
        }
        if (search) {
            where.push('(p.upi_txn_id LIKE ? OR u.full_name LIKE ? OR u.email LIKE ? OR u.mobile LIKE ?)');
            const like = `%${search}%`;
            params.push(like, like, like, like);
        }
        const whereSql = where.length ? `WHERE ${where.join(' AND ')}` : '';

        const [rows] = await db.query(
            `${SELECT_WITH_USER} ${whereSql} ORDER BY p.created_at DESC, p.id DESC LIMIT ? OFFSET ?`,
            [...params, limit, offset]
        );
        const [[countRow]] = await db.query(
            `SELECT COUNT(*) AS total FROM export_payments p LEFT JOIN users u ON u.id = p.user_id ${whereSql}`,
            params
        );
        return { items: rows.map(mapRow), total: Number(countRow?.total || 0) };
    },

    async stats() {
        const [rows] = await db.query(
            `SELECT status, COUNT(*) AS count FROM export_payments GROUP BY status`
        );
        const result = { total: 0, pending: 0, approved: 0, rejected: 0 };
        rows.forEach((row) => {
            const count = Number(row.count || 0);
            result.total += count;
            if (STATUSES.includes(row.status)) result[row.status] = count;
        });
        return result;
    },

    /**
     * Approve or reject a pending payment. Only pending rows change, so two
     * admins reviewing at once cannot both act on the same request.
     */
    async review(id, { status, adminId, remarks, exportsAllowed }) {
        const [result] = await db.query(
            `UPDATE export_payments
             SET status = ?, admin_remarks = ?, reviewed_by = ?, reviewed_at = NOW(),
                 exports_allowed = COALESCE(?, exports_allowed), exports_used = 0
             WHERE id = ? AND status = 'pending'`,
            [status, remarks || null, adminId != null ? toBinaryUUID(adminId) : null,
                exportsAllowed ?? null, toBinaryUUID(id)]
        );
        return (result.affectedRows || 0) > 0;
    },
};

module.exports = Model;
