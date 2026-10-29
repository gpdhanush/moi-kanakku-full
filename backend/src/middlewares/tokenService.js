const jwt = require('jsonwebtoken');

// In-memory token storage (consider Redis for multi-instance production)
const userTokens = {};
const refreshTokens = {};

// Short-lived access + longer refresh. Override via env.
const ACCESS_EXPIRES = process.env.JWT_ACCESS_EXPIRES || '1h';
const REFRESH_EXPIRES = process.env.JWT_REFRESH_EXPIRES || '30d';

function getRefreshSecret() {
    return process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET;
}

/**
 * Normalize user/admin ID to UUID string for in-memory token storage.
 * @param {string} userId
 * @returns {string}
 */
function normalizeUserId(userId) {
    if (userId == null) return userId;
    return String(userId).trim();
}

/**
 * Generate a new JWT access token for a user and store it
 * @param {string|number} userId - The user ID (UUID string or legacy number)
 * @returns {string} - The generated JWT token
 */
function generateToken(userId) {
    if (!userId) {
        throw new Error('User ID is required to generate token');
    }
    const key = normalizeUserId(userId);
    const token = jwt.sign(
        { userId: key, type: 'access' },
        process.env.JWT_SECRET,
        { expiresIn: ACCESS_EXPIRES }
    );
    userTokens[key] = token;
    return token;
}

/**
 * Generate a long-lived refresh token. Survives access-token expiry and
 * can rehydrate the in-memory access session after a server restart.
 * @param {string|number} userId
 * @returns {string}
 */
function generateRefreshToken(userId) {
    if (!userId) {
        throw new Error('User ID is required to generate refresh token');
    }
    const key = normalizeUserId(userId);
    const token = jwt.sign(
        { userId: key, type: 'refresh' },
        getRefreshSecret(),
        { expiresIn: REFRESH_EXPIRES }
    );
    refreshTokens[key] = token;
    return token;
}

/**
 * Issue both access and refresh tokens (admin login / refresh).
 * @param {string|number} userId
 * @returns {{ token: string, accessToken: string, refreshToken: string }}
 */
function generateTokenPair(userId) {
    const accessToken = generateToken(userId);
    const refreshToken = generateRefreshToken(userId);
    return {
        token: accessToken,
        accessToken,
        refreshToken,
    };
}

/**
 * Verify a refresh JWT. After a process restart the in-memory store is empty,
 * so a valid signature is enough to rehydrate the stored refresh token.
 * A newer login still revokes older refresh tokens while memory is intact.
 * @param {string} token
 * @returns {{ userId: string, type: string }}
 */
function verifyRefreshToken(token) {
    const decoded = jwt.verify(token, getRefreshSecret());
    if (!decoded || decoded.type !== 'refresh' || !decoded.userId) {
        const err = new Error('Invalid refresh token');
        err.name = 'JsonWebTokenError';
        throw err;
    }
    const key = normalizeUserId(decoded.userId);
    const stored = refreshTokens[key];
    if (stored && stored !== token) {
        const err = new Error('Refresh token revoked');
        err.name = 'TokenRevokedError';
        throw err;
    }
    if (!stored) {
        refreshTokens[key] = token;
    }
    return decoded;
}

/**
 * Single-session check for access tokens.
 * After server restart the map is empty — rehydrate a still-valid JWT so
 * overnight sessions survive process restarts without forcing re-login.
 * If a newer login stored a different token, the old one is rejected.
 *
 * @param {string|number} userId
 * @param {string} token - already signature-verified access JWT
 * @returns {boolean}
 */
function acceptAccessToken(userId, token) {
    if (userId == null || !token) return false;
    const key = normalizeUserId(userId);
    const stored = userTokens[key];
    if (!stored) {
        userTokens[key] = token;
        return true;
    }
    return stored === token;
}

/**
 * Invalidate the previous token for a user (single-session policy)
 * @param {string|number} userId - The user ID
 */
function invalidatePreviousToken(userId) {
    if (userId != null) {
        const key = normalizeUserId(userId);
        if (userTokens[key] !== undefined) delete userTokens[key];
        if (refreshTokens[key] !== undefined) delete refreshTokens[key];
    }
}

/**
 * Get the current valid token for a user
 * @param {string|number} userId - The user ID
 * @returns {string|undefined} - The token if exists, undefined otherwise
 */
function getTokenForUser(userId) {
    if (userId == null) return undefined;
    return userTokens[normalizeUserId(userId)];
}

/**
 * Remove token for a user (e.g., on logout or account deletion)
 * @param {string|number} userId - The user ID
 */
function removeToken(userId) {
    if (userId != null) {
        const key = normalizeUserId(userId);
        if (userTokens[key] !== undefined) delete userTokens[key];
        if (refreshTokens[key] !== undefined) delete refreshTokens[key];
    }
}

/**
 * Check if a token exists for a user
 * @param {string|number} userId - The user ID
 * @returns {boolean} - True if token exists, false otherwise
 */
function hasToken(userId) {
    if (userId == null) return false;
    return userTokens[normalizeUserId(userId)] !== undefined;
}

module.exports = {
    generateToken,
    generateRefreshToken,
    generateTokenPair,
    verifyRefreshToken,
    acceptAccessToken,
    invalidatePreviousToken,
    getTokenForUser,
    removeToken,
    hasToken,
    userTokens,
    ACCESS_EXPIRES,
    REFRESH_EXPIRES,
};
