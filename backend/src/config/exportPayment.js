/**
 * Paid PDF export settings. Set these in backend/.env:
 *   EXPORT_PAYMENT_UPI_ID=yourname@bank       (payee VPA shown in the QR code)
 *   EXPORT_PAYMENT_PAYEE_NAME=Moi Kanakku       (payee name shown in UPI apps)
 *   EXPORT_PAYMENT_AMOUNT=49                    (rupees, optional, default 49)
 */
function readAmount() {
    const value = Number.parseFloat(process.env.EXPORT_PAYMENT_AMOUNT);
    return Number.isFinite(value) && value > 0 ? Math.round(value * 100) / 100 : 49;
}

function getExportPaymentConfig() {
    const upiId = String(process.env.EXPORT_PAYMENT_UPI_ID || '').trim();
    const payeeName = String(process.env.EXPORT_PAYMENT_PAYEE_NAME || '').trim();
    const amount = readAmount();
    const configured = upiId.length > 0 && payeeName.length > 0;

    // Keep "@" in the VPA literal; some UPI apps do not decode %40 in pa=.
    const enc = (value) => encodeURIComponent(value).replace(/%40/g, '@');
    const query = [
        `pa=${enc(upiId)}`,
        `pn=${enc(payeeName)}`,
        `am=${amount.toFixed(2)}`,
        'cu=INR',
        `tn=${enc('Moi Kanakku PDF export')}`,
    ].join('&');

    return {
        configured,
        upiId,
        payeeName,
        amount,
        currency: 'INR',
        upiUri: configured ? `upi://pay?${query}` : null,
    };
}

module.exports = { getExportPaymentConfig };
