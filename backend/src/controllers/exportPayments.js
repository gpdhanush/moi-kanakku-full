const Model = require('../models/exportPayments');
const db = require('../config/database');
const logger = require('../config/logger');
const { toBinaryUUID } = require('../helpers/uuid');
const { validateUuid, sendUuidError } = require('../helpers/idParams');
const { recordAuditLog } = require('../helpers/auditLog');
const { getExportPaymentConfig } = require('../config/exportPayment');
const { queuePushNotification } = require('./notificationController');
const { Notification, NotificationType } = require('../models/notificationModels');

// UPI transaction reference numbers (UTR / "UPI Ref No.") are 12 digits.
const UPI_TXN_ID_PATTERN = /^\d{12}$/;
const MAX_REMARKS_LENGTH = 500;

const toISOStringOrNull = (value) => {
    if (!value) return null;
    const date = new Date(value);
    return Number.isNaN(date.getTime()) ? null : date.toISOString();
};

const normalizeTxnId = (value) => String(value ?? '').replace(/\s+/g, '').trim();

const formatPayment = (p) => p && ({
    id: p.id,
    userId: p.userId,
    userName: p.userName,
    userEmail: p.userEmail,
    userMobile: p.userMobile,
    amount: p.amount,
    upiTxnId: p.upiTxnId,
    status: p.status,
    adminRemarks: p.adminRemarks || '',
    reviewedBy: p.reviewedBy,
    reviewedByName: p.reviewedByName,
    reviewedAt: toISOStringOrNull(p.reviewedAt),
    createdAt: toISOStringOrNull(p.createdAt),
    updatedAt: toISOStringOrNull(p.updatedAt),
});

const fail = (res, code, message) =>
    res.status(code).json({ responseType: 'F', responseValue: { message } });

/**
 * Export access for a user. One approved payment unlocks PDF export for all
 * future exports: the PDF is built on the device from live ledger data, so
 * there is no server-side export to count against a single purchase.
 */
async function buildStatus(userId) {
    const config = getExportPaymentConfig();
    const [approved, history] = await Promise.all([
        Model.hasApproved(userId),
        Model.listForUser(userId, 5),
    ]);
    const latest = history[0] || null;
    let status = 'none';
    if (approved) status = 'approved';
    else if (latest) status = latest.status;

    return {
        status,
        canExport: approved,
        latest: formatPayment(latest),
        payment: {
            configured: config.configured,
            upiId: config.upiId,
            payeeName: config.payeeName,
            amount: config.amount,
            currency: config.currency,
            upiUri: config.upiUri,
        },
    };
}

async function notifyUser(userId, title, body) {
    try {
        await Notification.create({ userId, title, body, type: NotificationType.GENERAL });
        const [rows] = await db.query(
            `SELECT fcm_token FROM user_devices
             WHERE user_id = ? AND is_active = 1 AND (is_deleted = 0 OR is_deleted IS NULL)`,
            [toBinaryUUID(userId)]
        );
        (rows || []).map((r) => r.fcm_token).filter(Boolean).forEach((token) => {
            queuePushNotification({ userId, title, body, token, type: NotificationType.GENERAL, skipDbSave: true });
        });
    } catch (error) {
        logger.error('Export payment notification failed:', error);
    }
}

exports.controller = {
    /** GET /export-payments/status — current user's export access + payee details. */
    status: async (req, res) => {
        try {
            const userId = req.user?.userId;
            const idCheck = validateUuid(userId, 'userId');
            if (!idCheck.ok) return sendUuidError(res, idCheck.message);
            return res.status(200).json({ responseType: 'S', responseValue: await buildStatus(userId) });
        } catch (error) {
            logger.error('Export payment status failed:', error);
            return fail(res, 500, 'Unable to load payment status. Please try again later.');
        }
    },

    /** POST /export-payments/submit { upiTxnId } */
    submit: async (req, res) => {
        try {
            const userId = req.user?.userId;
            const idCheck = validateUuid(userId, 'userId');
            if (!idCheck.ok) return sendUuidError(res, idCheck.message);

            const upiTxnId = normalizeTxnId(req.body?.upiTxnId);
            if (!UPI_TXN_ID_PATTERN.test(upiTxnId)) {
                return fail(res, 400, 'Enter the 12-digit UPI transaction ID (UTR).');
            }

            const config = getExportPaymentConfig();
            if (!config.configured) {
                return fail(res, 503, 'Payments are not available right now. Please try again later.');
            }

            if (await Model.hasApproved(userId)) {
                return fail(res, 409, 'PDF export is already unlocked for your account.');
            }

            const history = await Model.listForUser(userId, 1);
            if (history[0]?.status === 'pending') {
                return fail(res, 409, 'Your payment is already under review.');
            }

            if (await Model.findByTxnId(upiTxnId)) {
                return fail(res, 409, 'This transaction ID has already been used.');
            }

            let created;
            try {
                created = await Model.create({ userId, upiTxnId, amount: config.amount });
            } catch (error) {
                if (error?.code === 'ER_DUP_ENTRY') {
                    return fail(res, 409, 'This transaction ID has already been used.');
                }
                throw error;
            }

            recordAuditLog({
                userId,
                action: 'EXPORT_PAYMENT_SUBMIT',
                entityType: 'export_payment',
                entityId: created.insertId,
                summary: 'Submitted UPI payment for PDF export',
                metadata: { amount: config.amount },
                req,
            });

            return res.status(200).json({ responseType: 'S', responseValue: await buildStatus(userId) });
        } catch (error) {
            logger.error('Export payment submit failed:', error);
            return fail(res, 500, 'Unable to submit payment. Please try again later.');
        }
    },

    /** GET /export-payments/admin/list?status=&search=&page=&limit= */
    adminList: async (req, res) => {
        try {
            const status = req.query.status ? String(req.query.status).toLowerCase() : null;
            if (status && !Model.STATUSES.includes(status)) return fail(res, 400, 'Invalid status.');
            const search = req.query.search ? String(req.query.search).trim().slice(0, 100) : null;
            const limit = Math.min(Math.max(parseInt(req.query.limit, 10) || 25, 1), 100);
            const page = Math.max(parseInt(req.query.page, 10) || 1, 1);

            const [{ items, total }, stats] = await Promise.all([
                Model.listAll({ status, search, limit, offset: (page - 1) * limit }),
                Model.stats(),
            ]);

            return res.status(200).json({
                responseType: 'S',
                responseValue: items.map(formatPayment),
                pagination: { page, limit, total, totalPages: Math.max(Math.ceil(total / limit), 1) },
                stats,
            });
        } catch (error) {
            logger.error('Export payment admin list failed:', error);
            return fail(res, 500, 'Unable to load payments.');
        }
    },

    /** POST /export-payments/admin/review { paymentId, action: approve|reject, remarks } */
    adminReview: async (req, res) => {
        try {
            const { paymentId } = req.body || {};
            const action = String(req.body?.action || '').toLowerCase();
            const remarks = String(req.body?.remarks ?? '').trim().slice(0, MAX_REMARKS_LENGTH);

            const idCheck = validateUuid(paymentId, 'paymentId');
            if (!idCheck.ok) return sendUuidError(res, idCheck.message);
            if (!['approve', 'reject'].includes(action)) return fail(res, 400, 'Action must be approve or reject.');
            if (action === 'reject' && !remarks) return fail(res, 400, 'Add a reason when rejecting a payment.');

            const payment = await Model.readById(paymentId);
            if (!payment) return fail(res, 404, 'Payment not found.');
            if (payment.status !== 'pending') return fail(res, 409, `Payment is already ${payment.status}.`);

            const status = action === 'approve' ? 'approved' : 'rejected';
            const adminId = req.admin?.userId ?? req.user?.userId ?? null;
            const updated = await Model.review(paymentId, { status, adminId, remarks });
            if (!updated) return fail(res, 409, 'Payment was already reviewed.');

            if (status === 'approved') {
                notifyUser(payment.userId, 'PDF export unlocked',
                    'Your payment was verified. You can now export your Moi ledger as PDF.');
            } else {
                notifyUser(payment.userId, 'Payment not verified',
                    remarks.length > 120 ? `${remarks.slice(0, 117)}...` : remarks);
            }

            return res.status(200).json({
                responseType: 'S',
                responseValue: formatPayment(await Model.readById(paymentId)),
            });
        } catch (error) {
            logger.error('Export payment review failed:', error);
            return fail(res, 500, 'Unable to update payment.');
        }
    },
};
