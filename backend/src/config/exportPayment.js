const { ExportPaymentSettings } = require('../models/exportPaymentSettings');

/**
 * Paid PDF export plans and payee settings.
 *
 * Prices are fixed plans (below). Payee details are set in the admin panel
 * (Export Payments → Payment settings), stored in `export_payment_settings`;
 * EXPORT_PAYMENT_UPI_ID and EXPORT_PAYMENT_PAYEE_NAME are fallbacks.
 */

/** `exports: null` means unlimited (lifetime). Order is the order shown in the app. */
const PLANS = Object.freeze([
    Object.freeze({ id: 'single', exports: 1, amount: 19 }),
    Object.freeze({ id: 'pack5', exports: 5, amount: 49 }),
    Object.freeze({ id: 'lifetime', exports: null, amount: 499 }),
]);
const LIFETIME_PLAN = 'lifetime';
/** Used when an older app version submits without choosing a plan. */
const DEFAULT_PLAN = 'pack5';

function findPlan(id) {
    return PLANS.find((plan) => plan.id === id) || null;
}

function buildUpiUri(upiId, payeeName, amount, note = null) {
    if (!upiId) return null;
    // Keep "@" in the VPA literal; some UPI apps do not decode %40 in pa=.
    const enc = (value) => encodeURIComponent(value).replace(/%40/g, '@');
    const query = [
        `pa=${enc(upiId)}`,
        payeeName ? `pn=${enc(payeeName)}` : null,
        `am=${amount.toFixed(2)}`,
        'cu=INR',
        `tn=${enc(note || 'Moi Kanakku PDF export')}`,
    ].filter(Boolean).join('&');
    return `upi://pay?${query}`;
}

/** Absolute URL for a stored "uploads/..." path, based on the incoming request host. */
function publicFileUrl(req, relativePath) {
    if (!relativePath) return null;
    if (/^https?:\/\//i.test(relativePath)) return relativePath;
    const proto = String(req?.get?.('x-forwarded-proto') || req?.protocol || 'https').split(',')[0].trim();
    const host = String(req?.get?.('x-forwarded-host') || req?.get?.('host') || '').split(',')[0].trim();
    const clean = String(relativePath).replace(/^\/+/, '');
    return host ? `${proto}://${host}/${clean}` : `/${clean}`;
}

async function getExportPaymentConfig(req = null) {
    const saved = await ExportPaymentSettings.get();
    const upiId = (saved?.upiId || process.env.EXPORT_PAYMENT_UPI_ID || '').trim();
    const payeeName = (saved?.payeeName || process.env.EXPORT_PAYMENT_PAYEE_NAME || '').trim();
    const qrImagePath = saved?.qrImagePath || '';
    const defaultPlan = findPlan(DEFAULT_PLAN);
    const plans = PLANS.map((plan) => ({
        id: plan.id,
        exports: plan.exports,
        lifetime: plan.exports == null,
        amount: plan.amount,
        upiUri: buildUpiUri(upiId, payeeName, plan.amount, `Moi Kanakku PDF export - ${plan.id}`),
    }));

    return {
        // Payable when the app can show a QR: generated from the UPI ID, or uploaded.
        configured: Boolean((upiId && payeeName) || qrImagePath),
        upiId,
        payeeName,
        plans,
        // Legacy single-price fields (older app versions): the default plan.
        amount: defaultPlan.amount,
        exportsPerPayment: defaultPlan.exports,
        currency: 'INR',
        upiUri: buildUpiUri(upiId, payeeName, defaultPlan.amount),
        qrImagePath,
        qrImageUrl: publicFileUrl(req, qrImagePath),
        updatedAt: saved?.updatedAt || null,
        updatedByName: saved?.updatedByName || null,
    };
}

module.exports = {
    getExportPaymentConfig,
    publicFileUrl,
    findPlan,
    PLANS,
    LIFETIME_PLAN,
    DEFAULT_PLAN,
};
