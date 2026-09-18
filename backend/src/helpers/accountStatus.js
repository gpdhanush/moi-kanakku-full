const ACCOUNT_INACTIVE_MESSAGE =
    'உங்கள் கணக்கு செயலிழக்கப்பட்டுள்ளது. தயவுசெய்து நிர்வாகியை தொடர்பு கொள்ளவும்.';

function isInactiveStatus(status) {
    return String(status || '').toUpperCase() === 'INACTIVE';
}

function sendInactiveError(res) {
    return res.status(403).json({
        responseType: 'F',
        responseValue: {
            message: ACCOUNT_INACTIVE_MESSAGE,
            account_status: 'INACTIVE',
        },
    });
}

module.exports = {
    ACCOUNT_INACTIVE_MESSAGE,
    isInactiveStatus,
    sendInactiveError,
};
