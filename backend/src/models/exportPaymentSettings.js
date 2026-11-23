const db = require('../config/database');
const { toBinaryUUID, fromBinaryUUID } = require('../helpers/uuid');

const SETTINGS_ID = 1;

function mapRow(row) {
    if (!row) return null;
    return {
        upiId: row.upi_id || '',
        payeeName: row.payee_name || '',
        amount: row.amount != null ? Number(row.amount) : null,
        qrImagePath: row.qr_image_path || '',
        updatedBy: row.updated_by != null ? fromBinaryUUID(row.updated_by) : null,
        updatedByName: row.updater_name || null,
        updatedAt: row.updated_at || null,
    };
}

const ExportPaymentSettings = {
    /** Returns null when the row (or the table, before migration) does not exist. */
    async get() {
        try {
            const [rows] = await db.query(
                `SELECT s.upi_id, s.payee_name, s.amount, s.qr_image_path, s.updated_by, s.updated_at,
                        a.full_name AS updater_name
                 FROM export_payment_settings s
                 LEFT JOIN admins a ON a.id = s.updated_by
                 WHERE s.id = ? LIMIT 1`,
                [SETTINGS_ID]
            );
            return mapRow(rows[0]);
        } catch (error) {
            if (error?.code === 'ER_NO_SUCH_TABLE') return null;
            throw error;
        }
    },

    async saveDetails({ upiId, payeeName, amount, updatedBy }) {
        await db.query(
            `INSERT INTO export_payment_settings (id, upi_id, payee_name, amount, updated_by)
             VALUES (?, ?, ?, ?, ?)
             ON DUPLICATE KEY UPDATE
               upi_id = VALUES(upi_id),
               payee_name = VALUES(payee_name),
               amount = VALUES(amount),
               updated_by = VALUES(updated_by)`,
            [SETTINGS_ID, upiId || null, payeeName || null, amount, updatedBy ? toBinaryUUID(updatedBy) : null]
        );
        return ExportPaymentSettings.get();
    },

    async saveQrImage(qrImagePath, updatedBy) {
        await db.query(
            `INSERT INTO export_payment_settings (id, qr_image_path, updated_by)
             VALUES (?, ?, ?)
             ON DUPLICATE KEY UPDATE
               qr_image_path = VALUES(qr_image_path),
               updated_by = VALUES(updated_by)`,
            [SETTINGS_ID, qrImagePath || null, updatedBy ? toBinaryUUID(updatedBy) : null]
        );
        return ExportPaymentSettings.get();
    },
};

module.exports = { ExportPaymentSettings };
