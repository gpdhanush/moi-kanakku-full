const Model = require('../models/exportPayments');
const db = require('../config/database');
const logger = require('../config/logger');
const { toBinaryUUID } = require('../helpers/uuid');
const { validateUuid, sendUuidError } = require('../helpers/idParams');
const { recordAuditLog } = require('../helpers/auditLog');
const path = require('path');
const fs = require('fs');
const multer = require('multer');
const { getExportPaymentConfig } = require('../config/exportPayment');
const { ExportPaymentSettings } = require('../models/exportPaymentSettings');
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
async function buildStatus(userId, req) {
    const config = await getExportPaymentConfig(req);
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
            qrImageUrl: config.qrImageUrl,
        },
    };
}

// UPI VPA: handle@provider (e.g. name@okaxis, 9876543210@ybl).
const UPI_ID_PATTERN = /^[a-zA-Z0-9._-]{2,256}@[a-zA-Z][a-zA-Z0-9.-]{1,64}$/;
const MAX_QR_BYTES = 2 * 1024 * 1024;
const QR_MIME_EXT = { 'image/png': '.png', 'image/jpeg': '.jpg', 'image/webp': '.webp' };

// Same folder app.js serves at /uploads.
const UPLOAD_ROOT = process.env.UPLOAD_DIR
    ? path.resolve(process.env.UPLOAD_DIR)
    : path.resolve(__dirname, '../../uploads');
const QR_SUBDIR = 'export-payment';

const qrUpload = multer({
    storage: multer.memoryStorage(),
    limits: { fileSize: MAX_QR_BYTES, files: 1 },
    fileFilter: (req, file, cb) => {
        if (QR_MIME_EXT[file.mimetype]) return cb(null, true);
        return cb(new Error('Upload a PNG, JPG or WEBP image.'));
    },
}).single('file');

/** Check real image bytes, not just the client-sent mimetype. */
function detectImageExt(buf) {
    if (!buf || buf.length < 12) return null;
    if (buf[0] === 0x89 && buf.toString('ascii', 1, 4) === 'PNG') return '.png';
    if (buf[0] === 0xff && buf[1] === 0xd8 && buf[2] === 0xff) return '.jpg';
    if (buf.toString('ascii', 0, 4) === 'RIFF' && buf.toString('ascii', 8, 12) === 'WEBP') return '.webp';
    return null;
}

function removeStoredQr(relativePath) {
    if (!relativePath || !relativePath.startsWith(`uploads/${QR_SUBDIR}/`)) return;
    const filePath = path.join(UPLOAD_ROOT, relativePath.slice('uploads/'.length));
    fs.promises.unlink(filePath).catch(() => {});
}

async function settingsResponse(req) {
    const config = await getExportPaymentConfig(req);
    return {
        upiId: config.upiId,
        payeeName: config.payeeName,
        amount: config.amount,
        qrImageUrl: config.qrImageUrl,
        upiUri: config.upiUri,
        configured: config.configured,
        updatedAt: toISOStringOrNull(config.updatedAt),
        updatedByName: config.updatedByName,
    };
}

const adminIdOf = (req) => req.admin?.userId ?? req.user?.userId ?? null;

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
            return res.status(200).json({ responseType: 'S', responseValue: await buildStatus(userId, req) });
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

            const config = await getExportPaymentConfig(req);
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

            return res.status(200).json({ responseType: 'S', responseValue: await buildStatus(userId, req) });
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
            const adminId = adminIdOf(req);
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

    /** GET /export-payments/admin/settings */
    adminGetSettings: async (req, res) => {
        try {
            return res.status(200).json({ responseType: 'S', responseValue: await settingsResponse(req) });
        } catch (error) {
            logger.error('Export payment settings read failed:', error);
            return fail(res, 500, 'Unable to load payment settings.');
        }
    },

    /** PUT /export-payments/admin/settings { upiId, payeeName, amount } */
    adminSaveSettings: async (req, res) => {
        try {
            const upiId = String(req.body?.upiId ?? '').trim();
            const payeeName = String(req.body?.payeeName ?? '').trim().replace(/\s+/g, ' ');
            const amount = Number.parseFloat(req.body?.amount);

            if (upiId && !UPI_ID_PATTERN.test(upiId)) return fail(res, 400, 'Enter a valid UPI ID, e.g. name@okaxis.');
            if (upiId && !payeeName) return fail(res, 400, 'Payee name is required with a UPI ID.');
            if (payeeName.length > 100) return fail(res, 400, 'Payee name must be 100 characters or less.');
            if (!Number.isFinite(amount) || amount < 1 || amount > 100000) {
                return fail(res, 400, 'Amount must be between ₹1 and ₹1,00,000.');
            }

            await ExportPaymentSettings.saveDetails({
                upiId,
                payeeName,
                amount: Math.round(amount * 100) / 100,
                updatedBy: adminIdOf(req),
            });
            return res.status(200).json({ responseType: 'S', responseValue: await settingsResponse(req) });
        } catch (error) {
            if (error?.code === 'ER_NO_SUCH_TABLE') {
                return fail(res, 503, 'Run migrations/create_export_payment_settings.sql first.');
            }
            logger.error('Export payment settings save failed:', error);
            return fail(res, 500, 'Unable to save payment settings.');
        }
    },

    /** POST /export-payments/admin/settings/qr (multipart, field "file") */
    adminUploadQr: (req, res) => {
        qrUpload(req, res, async (uploadError) => {
            try {
                if (uploadError) {
                    const message = uploadError.code === 'LIMIT_FILE_SIZE'
                        ? 'QR image must be 2 MB or smaller.'
                        : uploadError.message || 'Upload failed.';
                    return fail(res, 400, message);
                }
                if (!req.file) return fail(res, 400, 'Choose a QR image to upload (field "file").');

                const ext = detectImageExt(req.file.buffer);
                if (!ext) return fail(res, 400, 'The file is not a valid PNG, JPG or WEBP image.');

                const dir = path.join(UPLOAD_ROOT, QR_SUBDIR);
                await fs.promises.mkdir(dir, { recursive: true });
                const filename = `upi-qr-${Date.now()}-${Math.round(Math.random() * 1e6)}${ext}`;
                await fs.promises.writeFile(path.join(dir, filename), req.file.buffer);

                const previous = (await ExportPaymentSettings.get())?.qrImagePath;
                const relativePath = `uploads/${QR_SUBDIR}/${filename}`;
                try {
                    await ExportPaymentSettings.saveQrImage(relativePath, adminIdOf(req));
                } catch (dbError) {
                    removeStoredQr(relativePath);
                    throw dbError;
                }
                if (previous && previous !== relativePath) removeStoredQr(previous);

                return res.status(200).json({ responseType: 'S', responseValue: await settingsResponse(req) });
            } catch (error) {
                if (error?.code === 'ER_NO_SUCH_TABLE') {
                    return fail(res, 503, 'Run migrations/create_export_payment_settings.sql first.');
                }
                logger.error('Export payment QR upload failed:', error);
                return fail(res, 500, 'Unable to upload QR image.');
            }
        });
    },

    /** DELETE /export-payments/admin/settings/qr */
    adminRemoveQr: async (req, res) => {
        try {
            const previous = (await ExportPaymentSettings.get())?.qrImagePath;
            if (previous) {
                await ExportPaymentSettings.saveQrImage(null, adminIdOf(req));
                removeStoredQr(previous);
            }
            return res.status(200).json({ responseType: 'S', responseValue: await settingsResponse(req) });
        } catch (error) {
            logger.error('Export payment QR remove failed:', error);
            return fail(res, 500, 'Unable to remove QR image.');
        }
    },
};
