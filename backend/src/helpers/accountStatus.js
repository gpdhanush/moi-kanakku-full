const ACCOUNT_INACTIVE_MESSAGE =
    'உங்கள் கணக்கு செயலிழக்கப்பட்டுள்ளது. தயவுசெய்து நிர்வாகியை தொடர்பு கொள்ளவும்.';
const ACCOUNT_BLOCKED_MESSAGE =
    'உங்கள் கணக்கு தடுக்கப்பட்டுள்ளது. உதவிக்கு நிர்வாகியை தொடர்பு கொள்ளவும்.';

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

function isBlockedStatus(status) {
    return String(status || '').toUpperCase() === 'BLOCKED';
}

function sendBlockedError(res) {
    return res.status(403).json({
        responseType: 'F',
        responseValue: {
            message: ACCOUNT_BLOCKED_MESSAGE,
            account_status: 'BLOCKED',
        },
    });
}

module.exports = {
    ACCOUNT_INACTIVE_MESSAGE,
    ACCOUNT_BLOCKED_MESSAGE,
    isBlockedStatus,
    isInactiveStatus,
    sendBlockedError,
    sendInactiveError,
};
