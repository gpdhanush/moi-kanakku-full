const { ExportPaymentSettings } = require('../models/exportPaymentSettings');

/**
 * Paid PDF export payee settings.
 *
 * Admins set these in the admin panel (Export Payments → Payment settings),
 * stored in `export_payment_settings`. Env vars are the fallback for any value
 * not set there:
 *   EXPORT_PAYMENT_UPI_ID, EXPORT_PAYMENT_PAYEE_NAME, EXPORT_PAYMENT_AMOUNT (default 49)
 */
const DEFAULT_AMOUNT = 49;

function envAmount() {
    const value = Number.parseFloat(process.env.EXPORT_PAYMENT_AMOUNT);
    return Number.isFinite(value) && value > 0 ? Math.round(value * 100) / 100 : DEFAULT_AMOUNT;
}

function buildUpiUri(upiId, payeeName, amount) {
    if (!upiId) return null;
    // Keep "@" in the VPA literal; some UPI apps do not decode %40 in pa=.
    const enc = (value) => encodeURIComponent(value).replace(/%40/g, '@');
    const query = [
        `pa=${enc(upiId)}`,
        payeeName ? `pn=${enc(payeeName)}` : null,
        `am=${amount.toFixed(2)}`,
        'cu=INR',
        `tn=${enc('Moi Kanakku PDF export')}`,
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
    const amount = saved?.amount > 0 ? saved.amount : envAmount();
    const qrImagePath = saved?.qrImagePath || '';

    return {
        // Payable when the app can show a QR: generated from the UPI ID, or uploaded.
        configured: Boolean((upiId && payeeName) || qrImagePath),
        upiId,
        payeeName,
        amount,
        currency: 'INR',
        upiUri: buildUpiUri(upiId, payeeName, amount),
        qrImagePath,
        qrImageUrl: publicFileUrl(req, qrImagePath),
        updatedAt: saved?.updatedAt || null,
        updatedByName: saved?.updatedByName || null,
    };
}

module.exports = { getExportPaymentConfig, publicFileUrl };
