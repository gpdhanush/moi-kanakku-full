const db = require('../config/database');
const crypto = require('crypto');
const { generateUUID, toBinaryUUID, fromBinaryUUID } = require('../helpers/uuid');
const { getDbIdMode } = require('../helpers/dbIdMode');
const { normalizeSignupType } = require('../helpers/authProvider');

/**
 * LOGIN SECURITY FEATURE STATUS
 * ============================
 * CURRENT: Enabled (database columns exist and logic is active)
 * 
 * FEATURE: Block account after 3 failed login attempts for 15 minutes
 * COLUMNS IN user_credentials: failed_login_attempts, login_blocked_until
 * 
 * PASSWORD RESET: Uses OTP-based approach (user_otps table)
 * - NOT using token-based reset (more secure with OTP)
 */

const REFERRAL_CODE_LENGTH = 8;
const REFERRAL_CODE_MAX_ATTEMPTS = 10;

/**
 * Generate a short alphanumeric referral code (uppercase, no ambiguous chars 0/O, 1/I/L).
 */
function generateReferralCode() {
    const chars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    let code = '';
    const bytes = crypto.randomBytes(REFERRAL_CODE_LENGTH);
    for (let i = 0; i < REFERRAL_CODE_LENGTH; i++) {
        code += chars[bytes[i] % chars.length];
    }
    return code;
}

const User = {
    async findByReferralCode(code) {
        if (!code || typeof code !== 'string') return null;
        const trimmed = String(code).trim().toUpperCase();
        if (!trimmed) return null;
        const [rows] = await db.query(
            `SELECT id FROM users WHERE referral_code = ? AND (is_deleted = 0 OR is_deleted IS NULL)`,
            [trimmed]
        );
        const r = rows[0];
        if (!r) return null;
        return { id: fromBinaryUUID(r.id) };
    },

    async recordReferral(referrerUserId, referredUserId) {
        try {
            const [result] = await db.query(
                `INSERT INTO user_referrals (referrer_user_id, referred_user_id) VALUES (?, ?)
                 ON DUPLICATE KEY UPDATE referrer_user_id = referrer_user_id`,
                [toBinaryUUID(referrerUserId), toBinaryUUID(referredUserId)]
            );
            return result;
        } catch (e) {
            if (e.code === 'ER_NO_SUCH_TABLE') return null;
            throw e;
        }
    },
    async findByEmail(email) {
        const [rows] = await db.query(
            `SELECT u.id, u.full_name, u.email, u.mobile, u.referral_code, u.status,
                    u.is_verified, u.email_verified_at, u.last_activity_at, u.is_deleted, u.deleted_at,
                    u.created_at, u.updated_at, u.signup_type, u.google_id, u.password_set,
                    uc.password_hash, uc.password_changed_at,
                    COALESCE(up.profile_image_url, NULL) AS profile_image_url,
                    (SELECT ud.fcm_token FROM user_devices ud WHERE ud.user_id = u.id AND ud.is_active = 1 ORDER BY ud.last_used_at DESC LIMIT 1) AS fcm_token
             FROM users u
             INNER JOIN user_credentials uc ON uc.user_id = u.id
             LEFT JOIN user_profiles up ON up.user_id = u.id
             WHERE u.email = ? AND (u.is_deleted = 0 OR u.is_deleted IS NULL)`,
            [email ? String(email).toLowerCase().trim() : email]
        );
        const row = rows[0];
        if (!row) return null;
        // Return full user row (including sensitive fields) so callers like login can validate password
        return mapUserRow(row);
    },

    /**
     * Find user by email including deleted users (for checking account status)
     */
    async findByEmailIncludingDeleted(email) {
        const [rows] = await db.query(
            `SELECT u.id, u.full_name, u.email, u.mobile, u.referral_code, u.status,
                    u.is_verified, u.email_verified_at, u.last_activity_at, u.is_deleted, u.deleted_at,
                    u.created_at, u.updated_at, u.signup_type, u.google_id, u.password_set,
                    uc.password_hash, uc.password_changed_at,
                    COALESCE(up.profile_image_url, NULL) AS profile_image_url
             FROM users u
             INNER JOIN user_credentials uc ON uc.user_id = u.id
             LEFT JOIN user_profiles up ON up.user_id = u.id
             WHERE u.email = ?`,
            [email ? String(email).toLowerCase().trim() : email]
        );
        const row = rows[0];
        if (!row) return null;
        return mapUserRow(row);
    },

    async findById(userId) {
        const [rows] = await db.query(
            `SELECT u.id, u.full_name, u.email, u.mobile, u.referral_code, u.status,
                    u.is_verified, u.email_verified_at, u.last_activity_at, u.is_deleted, u.deleted_at,
                    u.created_at, u.updated_at, u.signup_type, u.google_id, u.password_set,
                    uc.password_hash, uc.password_changed_at,
                    up.profile_image_url,
                    up.gender,
                    up.date_of_birth,
                    up.address_line1,
                    up.address_line2,
                    up.city,
                    up.state,
                    up.country,
                    up.postal_code,
                    (SELECT ud.fcm_token FROM user_devices ud WHERE ud.user_id = u.id AND ud.is_active = 1 ORDER BY ud.last_used_at DESC LIMIT 1) AS fcm_token
             FROM users u
             LEFT JOIN user_credentials uc ON uc.user_id = u.id
             LEFT JOIN user_profiles up ON up.user_id = u.id
             WHERE u.id = ? AND (u.is_deleted = 0 OR u.is_deleted IS NULL)`,
            [toBinaryUUID(userId)]
        );
        const row = rows[0];
        if (!row) return null;
        return mapUserRow(row);
    },

    /**
     * Find user by ID including deleted users (for checking account status)
     */
    async findByIdIncludingDeleted(userId) {
        const [rows] = await db.query(
            `SELECT u.id, u.full_name, u.email, u.mobile, u.referral_code, u.status,
                    u.is_verified, u.email_verified_at, u.last_activity_at, u.is_deleted, u.deleted_at,
                    u.created_at, u.updated_at,
                    uc.password_hash, uc.password_changed_at,
                    COALESCE(up.profile_image_url, NULL) AS profile_image_url
             FROM users u
             LEFT JOIN user_credentials uc ON uc.user_id = u.id
             LEFT JOIN user_profiles up ON up.user_id = u.id
             WHERE u.id = ?`,
            [toBinaryUUID(userId)]
        );
        const row = rows[0];
        if (!row) return null;
        return mapUserRow(row);
    },

    async checkMobileNo(mobile, excludeUserId) {
        const [rows] = await db.query(
            `SELECT id FROM users WHERE mobile = ? AND id != ? AND (is_deleted = 0 OR is_deleted IS NULL)`,
            [mobile, toBinaryUUID(excludeUserId)]
        );
        const r = rows[0];
        if (!r) return null;
        return { id: fromBinaryUUID(r.id) };
    },

    async findByMobile(mobile) {
        const [rows] = await db.query(
            `SELECT u.id, u.full_name, u.email, u.mobile, u.referral_code, u.signup_type, u.google_id, u.password_set, uc.password_hash,
                    (SELECT ud.fcm_token FROM user_devices ud WHERE ud.user_id = u.id AND ud.is_active = 1 ORDER BY ud.last_used_at DESC LIMIT 1) AS fcm_token
             FROM users u
             INNER JOIN user_credentials uc ON uc.user_id = u.id
             WHERE u.mobile = ? AND (u.is_deleted = 0 OR u.is_deleted IS NULL)`,
            [mobile]
        );
        const row = rows[0];
        if (!row) return null;
        return mapUserRow(row);
    },

    async findByGoogleId(googleId) {
        if (!googleId) return null;
        const [rows] = await db.query(
            `SELECT u.id, u.full_name, u.email, u.mobile, u.referral_code, u.status,
                    u.is_verified, u.email_verified_at, u.last_activity_at, u.is_deleted, u.deleted_at,
                    u.created_at, u.updated_at, u.signup_type, u.google_id, u.password_set,
                    uc.password_hash, uc.password_changed_at,
                    COALESCE(up.profile_image_url, NULL) AS profile_image_url
             FROM users u
             INNER JOIN user_credentials uc ON uc.user_id = u.id
             LEFT JOIN user_profiles up ON up.user_id = u.id
             WHERE u.google_id = ? AND (u.is_deleted = 0 OR u.is_deleted IS NULL)`,
            [String(googleId).trim()]
        );
        return rows[0] ? mapUserRow(rows[0]) : null;
    },

    async linkGoogleAccount(userId, googleId) {
        if (!userId || !googleId) return null;
        const [result] = await db.query(
            `UPDATE users SET google_id = ?, signup_type = 'google', is_verified = 1, email_verified_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP WHERE id = ?`,
            [String(googleId).trim(), toBinaryUUID(userId)]
        );
        return result;
    },

    async setPasswordSet(userId, passwordSet = true) {
        const [result] = await db.query(
            `UPDATE users SET password_set = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?`,
            [passwordSet ? 1 : 0, toBinaryUUID(userId)]
        );
        return result;
    },

    async updateLastLogin(userId) {
        const [result] = await db.query(
            `UPDATE users SET last_activity_at = ? WHERE id = ?`,
            [new Date(), toBinaryUUID(userId)]
        );
        return result;
    },

    /**
     * Increment failed login attempts and block if >= 3
     * Returns: { blocked: boolean, remaining_attempts: number, blocked_until: Date }
     */
    async incrementFailedLoginAttempts(userId) {
        const MAX_ATTEMPTS = 3;
        const BLOCK_DURATION_MINUTES = 15;
        
        const idBin = toBinaryUUID(userId);
        const blockedUntil = new Date(Date.now() + BLOCK_DURATION_MINUTES * 60 * 1000);
        
        const [result] = await db.query(
            `UPDATE user_credentials 
             SET failed_login_attempts = failed_login_attempts + 1,
                 login_blocked_until = CASE 
                    WHEN failed_login_attempts + 1 >= ? THEN ?
                    ELSE login_blocked_until
                 END
             WHERE user_id = ?`,
            [MAX_ATTEMPTS, blockedUntil, idBin]
        );
        
        // Fetch updated credentials to return current status
        const [rows] = await db.query(
            `SELECT failed_login_attempts, login_blocked_until FROM user_credentials WHERE user_id = ?`,
            [idBin]
        );
        
        const creds = rows[0];
        const blocked = creds.failed_login_attempts >= MAX_ATTEMPTS;
        const remainingAttempts = Math.max(0, MAX_ATTEMPTS - creds.failed_login_attempts);
        
        return {
            blocked,
            remaining_attempts: remainingAttempts,
            blocked_until: creds.login_blocked_until,
            attempts: creds.failed_login_attempts
        };
    },

    /**
     * Reset failed login attempts after successful login
     */
    async resetFailedLoginAttempts(userId) {
        const [result] = await db.query(
            `UPDATE user_credentials 
             SET failed_login_attempts = 0, login_blocked_until = NULL
             WHERE user_id = ?`,
            [toBinaryUUID(userId)]
        );
        return result;
    },

    /**
     * Check if user is currently blocked and if block has expired
     * Returns: { is_blocked: boolean, blocked_until: Date }
     */
    async getLoginBlockStatus(userId) {
        const [rows] = await db.query(
            `SELECT login_blocked_until FROM user_credentials WHERE user_id = ?`,
            [toBinaryUUID(userId)]
        );
        
        if (!rows[0]) return { is_blocked: false, blocked_until: null };
        
        const blockedUntil = rows[0].login_blocked_until;
        const now = new Date();
        
        // If blocked_until is in the past, the block has expired
        if (blockedUntil && blockedUntil > now) {
            return { is_blocked: true, blocked_until: blockedUntil };
        }
        
        // Block has expired, clear it
        if (blockedUntil && blockedUntil <= now) {
            await db.query(
                `UPDATE user_credentials SET login_blocked_until = NULL, failed_login_attempts = 0 WHERE user_id = ?`,
                [toBinaryUUID(userId)]
            );
        }
        
        return { is_blocked: false, blocked_until: null };
    },

    async create(payload) {
        const {
            name,
            email,
            mobile,
            password,
            city,
            fcm_token,
            device_name,
            device_id,
            brand,
            manufacturer,
            model,
            ram_size,
            android_version,
            signup_type,
            google_id,
            password_set,
            is_verified,
        } = payload;
        const now = new Date();
        const idMode = await getDbIdMode(db);

        let referralCode = null;
        for (let attempt = 0; attempt < REFERRAL_CODE_MAX_ATTEMPTS; attempt++) {
            const candidate = generateReferralCode();
            const [existing] = await db.query(`SELECT 1 FROM users WHERE referral_code = ?`, [candidate]);
            if (!existing || existing.length === 0) {
                referralCode = candidate;
                break;
            }
        }
        if (!referralCode) referralCode = generateReferralCode() + Date.now().toString(36).slice(-4);

        let userId;
        let userIdForFk;

        const signupType = normalizeSignupType(signup_type || 'email');
        const hasPasswordSet = password_set != null ? Boolean(password_set) : Boolean(password && String(password).trim() !== '');
        const isVerifiedValue = is_verified != null ? Boolean(is_verified) : false;

        if (idMode === 'uuid') {
            userId = payload.id || generateUUID();
            userIdForFk = toBinaryUUID(userId);
            await db.query(
                `INSERT INTO users (id, full_name, email, mobile, referral_code, status, signup_type, google_id, password_set, is_verified, email_verified_at, created_at, updated_at)
                 VALUES (?, ?, ?, ?, ?, 'ACTIVE', ?, ?, ?, ?, ?, ?, ?)`,
                [userIdForFk, name, email, mobile || null, referralCode, signupType, google_id || null, hasPasswordSet ? 1 : 0, isVerifiedValue ? 1 : 0, isVerifiedValue ? now : null, now, now]
            );
        } else {
            const [userResult] = await db.query(
                `INSERT INTO users (full_name, email, mobile, referral_code, status, signup_type, google_id, password_set, is_verified, email_verified_at, created_at, updated_at)
                 VALUES (?, ?, ?, ?, 'ACTIVE', ?, ?, ?, ?, ?, ?, ?)`,
                [name, email, mobile || null, referralCode, signupType, google_id || null, hasPasswordSet ? 1 : 0, isVerifiedValue ? 1 : 0, isVerifiedValue ? now : null, now, now]
            );
            userId = userResult.insertId;
            userIdForFk = userId;
        }

        await db.query(
            `INSERT INTO user_credentials (user_id, password_hash, password_changed_at)
             VALUES (?, ?, ?)`,
            [userIdForFk, password || '', now]
        );
        await db.query(
            `INSERT INTO user_profiles (user_id, city) VALUES (?, ?)`,
            [userIdForFk, city || null]
        );
        await this.upsertDevice(userIdForFk, {
            fcm_token,
            device_name,
            device_id,
            brand,
            manufacturer,
            model,
            ram_size,
            android_version,
            platform: payload.platform,
            app_version: payload.app_version,
            last_used_at: now,
        });
        return { insertId: String(userId) };
    },

    /**
     * Insert or update a user device row.
     * Saves the device even when FCM token is missing so signup still records the phone.
     */
    async upsertDevice(userIdForFk, device = {}) {
        const deviceId = device.device_id != null && String(device.device_id).trim() !== ''
            ? String(device.device_id).trim()
            : null;
        const fcmToken = device.fcm_token != null && String(device.fcm_token).trim() !== ''
            ? String(device.fcm_token).trim()
            : '';
        const hasDevice = Boolean(
            deviceId ||
            fcmToken ||
            (device.device_name && String(device.device_name).trim())
        );
        if (!hasDevice) return { skipped: true };

        const resolvedDeviceId = deviceId || `unknown-${Date.now()}`;
        const lastUsedAt = device.last_used_at || new Date();
        const platform = device.platform != null && String(device.platform).trim() !== ''
            ? String(device.platform).trim().toLowerCase()
            : 'android';
        const appVersion = device.app_version != null && String(device.app_version).trim() !== ''
            ? String(device.app_version).trim().slice(0, 32)
            : null;

        try {
            const [result] = await db.query(
                `INSERT INTO user_devices (
                    user_id,
                    device_name,
                    device_id,
                    brand,
                    manufacturer,
                    model,
                    ram_size,
                    fcm_token,
                    android_version,
                    platform,
                    app_version,
                    is_active,
                    token_status,
                    last_used_at,
                    uninstalled_at,
                    is_deleted,
                    deleted_at
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, 'active', ?, NULL, 0, NULL)
                ON DUPLICATE KEY UPDATE
                    last_used_at = VALUES(last_used_at),
                    is_active = 1,
                    token_status = 'active',
                    uninstalled_at = NULL,
                    is_deleted = 0,
                    deleted_at = NULL,
                    updated_at = CURRENT_TIMESTAMP,
                    device_name = COALESCE(VALUES(device_name), device_name),
                    brand = COALESCE(VALUES(brand), brand),
                    manufacturer = COALESCE(VALUES(manufacturer), manufacturer),
                    model = COALESCE(VALUES(model), model),
                    ram_size = COALESCE(VALUES(ram_size), ram_size),
                    android_version = COALESCE(VALUES(android_version), android_version),
                    platform = COALESCE(VALUES(platform), platform),
                    app_version = COALESCE(VALUES(app_version), app_version),
                    fcm_token = IF(VALUES(fcm_token) = '', fcm_token, VALUES(fcm_token))`,
                [
                    userIdForFk,
                    device.device_name ?? null,
                    resolvedDeviceId,
                    device.brand ?? null,
                    device.manufacturer ?? null,
                    device.model ?? null,
                    device.ram_size ?? null,
                    fcmToken,
                    device.android_version ?? null,
                    platform,
                    appVersion,
                    lastUsedAt,
                ]
            );
            return result;
        } catch (error) {
            console.error('Failed to save user device:', error?.message || error);
            return { skipped: true, error };
        }
    },

    async updateStatus(userId, status) {
        const normalized = String(status || '').toUpperCase();
        if (!['ACTIVE', 'INACTIVE'].includes(normalized)) {
            const error = new Error('Invalid status. Allowed values: ACTIVE, INACTIVE.');
            error.code = 'INVALID_STATUS';
            throw error;
        }
        const [result] = await db.query(
            `UPDATE users SET status = ?, updated_at = CURRENT_TIMESTAMP
             WHERE id = ? AND (is_deleted = 0 OR is_deleted IS NULL)`,
            [normalized, toBinaryUUID(userId)]
        );
        return { ...result, status: normalized };
    },

    async update(payload) {
        const { id, name, mobile, email, status } = payload;
        const idBin = toBinaryUUID(id);
        
        // Update users table
        const [result] = await db.query(
            `UPDATE users SET full_name = ?, mobile = ?, email = ?, status = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?`,
            [name || null, mobile || null, email || null, status || 'ACTIVE', idBin]
        );
        return result;
    },

    async updateProfile(payload) {
        const { id, gender, date_of_birth, address_line1, address_line2, city, state, country, postal_code } = payload;
        const idBin = toBinaryUUID(id);
        
        // Update user_profiles table
        const [result] = await db.query(
            `UPDATE user_profiles SET 
                gender = ?, 
                date_of_birth = ?, 
                address_line1 = ?, 
                address_line2 = ?, 
                city = ?, 
                state = ?, 
                country = ?, 
                postal_code = ? 
            WHERE user_id = ?`,
            [gender || null, date_of_birth || null, address_line1 || null, address_line2 || null, 
             city || null, state || null, country || null, postal_code || null, idBin]
        );
        return result;
    },

    async updateUserData(payload) {
        const {
            id,
            // users table
            name, mobile, email, status,
            // user_profiles table
            gender, date_of_birth, address_line1, address_line2, city, state, country, postal_code,
            // user_devices table
            fcm_token, device_name, device_id, brand, manufacturer, model, ram_size, android_version
        } = payload;
        
        const idBin = toBinaryUUID(id);
        const now = new Date();
        
        // Convert ISO datetime to date-only format (YYYY-MM-DD)
        let dobFormatted = date_of_birth;
        if (date_of_birth && typeof date_of_birth === 'string') {
            // Extract only the date part from ISO format: '2026-02-01T18:30:00.000Z' -> '2026-02-01'
            dobFormatted = date_of_birth.split('T')[0];
        }

        try {
            // Update users table
            if (name || mobile || email || status) {
                await db.query(
                    `UPDATE users SET 
                        full_name = COALESCE(?, full_name),
                        mobile = COALESCE(?, mobile),
                        email = COALESCE(?, email),
                        status = COALESCE(?, status),
                        updated_at = CURRENT_TIMESTAMP 
                    WHERE id = ?`,
                    [name || null, mobile || null, email || null, status || null, idBin]
                );
            }

            // Update user_profiles table
            if (gender || date_of_birth || address_line1 || address_line2 || city || state || country || postal_code) {
                await db.query(
                    `UPDATE user_profiles SET 
                        gender = COALESCE(?, gender),
                        date_of_birth = COALESCE(?, date_of_birth),
                        address_line1 = COALESCE(?, address_line1),
                        address_line2 = COALESCE(?, address_line2),
                        city = COALESCE(?, city),
                        state = COALESCE(?, state),
                        country = COALESCE(?, country),
                        postal_code = COALESCE(?, postal_code)
                    WHERE user_id = ?`,
                    [gender || null, dobFormatted || null, address_line1 || null, address_line2 || null,
                     city || null, state || null, country || null, postal_code || null, idBin]
                );
            }

            await this.upsertDevice(idBin, {
                fcm_token,
                device_name,
                device_id,
                brand,
                manufacturer,
                model,
                ram_size,
                android_version,
            });

            return { success: true };
        } catch (error) {
            throw error;
        }
    },

    async updatePassword(payload) {
        const { id, password } = payload;
        const [result] = await db.query(
            `UPDATE user_credentials SET password_hash = ?, password_changed_at = ? WHERE user_id = ?`,
            [password, new Date(), toBinaryUUID(id)]
        );
        return result;
    },

    async createGoogleUser({ name, email, googleId, passwordHash = '' }) {
        const payload = {
            name,
            email,
            mobile: null,
            password: passwordHash,
            signup_type: 'google',
            google_id: googleId,
            password_set: false,
            is_verified: true,
        };
        return this.create(payload);
    },

    async syncGoogleProfile({ id, name, profileImageUrl }) {
        const idBin = toBinaryUUID(id);
        await db.query(
            `UPDATE users SET full_name = COALESCE(?, full_name), updated_at = CURRENT_TIMESTAMP WHERE id = ?`,
            [name || null, idBin]
        );
        if (profileImageUrl) {
            await db.query(
                `INSERT INTO user_profiles (user_id, profile_image_url)
                 VALUES (?, ?)
                 ON DUPLICATE KEY UPDATE profile_image_url = VALUES(profile_image_url)`,
                [idBin, profileImageUrl]
            );
        }
    },

    async findUsersWithOldPasswords(months = 3) {
        const [rows] = await db.query(
            `SELECT u.id, u.full_name, u.email, uc.password_changed_at,
                    (SELECT ud.fcm_token FROM user_devices ud WHERE ud.user_id = u.id AND ud.is_active = 1 ORDER BY ud.last_used_at DESC LIMIT 1) AS fcm_token
             FROM users u
             INNER JOIN user_credentials uc ON uc.user_id = u.id
             WHERE u.status = 'ACTIVE'
               AND (u.is_deleted = 0 OR u.is_deleted IS NULL)
               AND (uc.password_changed_at IS NULL OR uc.password_changed_at < DATE_SUB(NOW(), INTERVAL ? MONTH))
               AND EXISTS (SELECT 1 FROM user_devices ud WHERE ud.user_id = u.id AND ud.is_active = 1)`,
            [months]
        );
        return rows.map(r => ({
            id: fromBinaryUUID(r.id),
            full_name: r.full_name,
            email: r.email,
            notification_token: r.fcm_token,
            password_changed_at: r.password_changed_at,
            um_id: fromBinaryUUID(r.id),
            um_full_name: r.full_name,
            um_email: r.email,
            um_notification_token: r.fcm_token
        }));
    },

    /**
     * Soft delete a user account
     * Sets is_deleted=1, deleted_at=CURRENT_TIMESTAMP, status='DELETED'
     * User data remains in database and can be restored later
     */
    async deleteUser(userId) {
        // Soft delete: mark user as deleted with timestamp and set status to an allowed enum value
        const [result] = await db.query(
          `UPDATE users SET is_deleted = 1, deleted_at = CURRENT_TIMESTAMP, status = 'DELETED', updated_at = CURRENT_TIMESTAMP WHERE id = ?`,
          [toBinaryUUID(userId)],
        );
        return result;
    },

    /**
     * Hard delete a user and all dependent rows in one transaction.
     * Used for admin permanent delete and to roll back failed signups.
     */
    async hardDeleteUser(userId) {
        const idForFk = toBinaryUUID(userId);
        const userIdStr = String(userId);
        const conn = await db.getConnection();
        try {
            await conn.beginTransaction();

            // Child rows first so foreign keys are not left pointing at the user.
            const childTables = [
                'transactions',
                'transaction_functions',
                'persons',
                'upcoming_functions',
                'notifications',
                'feedbacks',
                'user_otps',
                'user_devices',
                'user_sessions',
                'user_profiles',
                'user_credentials',
            ];
            for (const table of childTables) {
                await conn.query(`DELETE FROM ${table} WHERE user_id = ?`, [idForFk]);
            }

            await conn.query(`DELETE FROM user_mfa WHERE user_id = ?`, [userIdStr]);
            await conn.query(
                `DELETE FROM user_referrals WHERE referrer_user_id = ? OR referred_user_id = ?`,
                [idForFk, idForFk]
            );
            const [result] = await conn.query(`DELETE FROM users WHERE id = ?`, [idForFk]);
            await conn.commit();
            return result;
        } catch (error) {
            await conn.rollback();
            throw error;
        } finally {
            conn.release();
        }
    },

    /**
     * Restore a soft-deleted user account
     */
    async restoreUser(userId) {
        const [result] = await db.query(
            `UPDATE users SET is_deleted = 0, deleted_at = NULL, status = 'ACTIVE', updated_at = CURRENT_TIMESTAMP WHERE id = ?`,
            [toBinaryUUID(userId)]
        );
        return result;
    },

    async updateToken(userId, device_id, token, device_name = null, brand = null, manufacturer = null, model = null, android_version = null, ram_size = null, extra = {}) {
        return this.upsertDevice(toBinaryUUID(userId), {
            device_id,
            fcm_token: token,
            device_name,
            brand,
            manufacturer,
            model,
            android_version,
            ram_size,
            platform: extra.platform,
            app_version: extra.app_version,
        });
    },

    /**
     * Get old profile image path before updating (for cleanup)
     */
    async getProfileImagePath(userId) {
        const [rows] = await db.query(
            `SELECT profile_image_url FROM user_profiles WHERE user_id = ?`,
            [toBinaryUUID(userId)]
        );
        return rows && rows[0] ? rows[0].profile_image_url : null;
    },

    async updateProfileImage(userId, imagePath) {
        const [result] = await db.query(
            `UPDATE user_profiles SET profile_image_url = ? WHERE user_id = ?`,
            [imagePath, toBinaryUUID(userId)]
        );
        return result;
    },

    /**
     * Generate a 6-digit OTP
     */
    generateOTP() {
        return Math.floor(100000 + Math.random() * 900000).toString();
    },

    /**
     * Create/store OTP for email verification
     */
    async createVerificationOTP(userId) {
        const otp = this.generateOTP();
        const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes expiry
        
        const [result] = await db.query(
            `INSERT INTO user_otps (user_id, code, type, expires_at, is_used)
             VALUES (?, ?, 'VERIFY', ?, 0)`,
            [toBinaryUUID(userId), otp, expiresAt]
        );
        
        return { otp, expiresAt, id: result.insertId };
    },

    /**
     * Create/store OTP for account restore flow (soft-deleted accounts)
     */
    async createRestoreOTP(userId) {
        const otp = this.generateOTP();
        const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes expiry

        const [result] = await db.query(
            `INSERT INTO user_otps (user_id, code, type, expires_at, is_used)
             VALUES (?, ?, 'RESTORE', ?, 0)`,
            [toBinaryUUID(userId), otp, expiresAt]
        );

        return { otp, expiresAt, id: result.insertId };
    },

    /**
     * Create/store OTP for forgot password flow
     */
    async createForgotOTP(userId) {
        const otp = this.generateOTP();
        const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes expiry (consistent with other flows)

        const [result] = await db.query(
            `INSERT INTO user_otps (user_id, code, type, expires_at, is_used)
             VALUES (?, ?, 'FORGOT', ?, 0)`,
            [toBinaryUUID(userId), otp, expiresAt]
        );

        return { otp, expiresAt, id: result.insertId };
    },

    /**
     * Verify OTP and mark user as verified
     */
    async verifyEmailOTP(userId, otp) {
        const idBin = toBinaryUUID(userId);
        const now = new Date();
        
        // Check if OTP exists, is correct, is not used, and not expired
        const [otpRows] = await db.query(
            `SELECT id, is_used, expires_at FROM user_otps 
             WHERE user_id = ? AND code = ? AND type = 'VERIFY'
             ORDER BY created_at DESC LIMIT 1`,
            [idBin, otp]
        );
        
        if (!otpRows || otpRows.length === 0) {
            return { success: false, message: 'OTP not found!' };
        }
        
        const otpRecord = otpRows[0];
        
        // Check if already used
        if (otpRecord.is_used) {
            return { success: false, message: 'This OTP has already been used!' };
        }
        
        // Check if expired
        if (new Date() > otpRecord.expires_at) {
            return { success: false, message: 'OTP has expired! Please request a new OTP.' };
        }
        
        try {
            // Mark OTP as used
            await db.query(
                `UPDATE user_otps SET is_used = 1 WHERE id = ?`,
                [otpRecord.id]
            );
            
            // Update user as verified
            await db.query(
                `UPDATE users SET is_verified = 1, email_verified_at = ? WHERE id = ?`,
                [now, idBin]
            );
            
            return { success: true, message: 'Email verified successfully!' };
        } catch (error) {
            throw error;
        }
    },

    /**
     * Verify OTP for restore flow and mark OTP as used (does NOT change verified flag)
     */
    async verifyRestoreOTP(userId, otp) {
        const idBin = toBinaryUUID(userId);
        const now = new Date();

        const [otpRows] = await db.query(
            `SELECT id, is_used, expires_at FROM user_otps 
             WHERE user_id = ? AND code = ? AND type = 'RESTORE'
             ORDER BY created_at DESC LIMIT 1`,
            [idBin, otp]
        );

        if (!otpRows || otpRows.length === 0) {
            return { success: false, message: 'OTP not found!' };
        }

        const otpRecord = otpRows[0];

        if (otpRecord.is_used) {
            return { success: false, message: 'This OTP has already been used!' };
        }

        if (new Date() > otpRecord.expires_at) {
            return { success: false, message: 'OTP has expired! Please request a new OTP.' };
        }

        try {
            await db.query(
                `UPDATE user_otps SET is_used = 1 WHERE id = ?`,
                [otpRecord.id]
            );

            return { success: true, message: 'OTP is valid.' };
        } catch (error) {
            throw error;
        }
    },

    /**
     * Verify OTP for forgot password flow and mark OTP as used
     */
    async verifyForgotOTP(userId, otp) {
        const idBin = toBinaryUUID(userId);

        const [otpRows] = await db.query(
            `SELECT id, is_used, expires_at FROM user_otps 
             WHERE user_id = ? AND code = ? AND type = 'FORGOT'
             ORDER BY created_at DESC LIMIT 1`,
            [idBin, otp]
        );

        if (!otpRows || otpRows.length === 0) {
            return { success: false, message: 'OTP not found!' };
        }

        const otpRecord = otpRows[0];

        if (otpRecord.is_used) {
            return { success: false, message: 'This OTP has already been used!' };
        }

        if (new Date() > otpRecord.expires_at) {
            return { success: false, message: 'OTP has expired! Please request a new OTP.' };
        }

        try {
            await db.query(
                `UPDATE user_otps SET is_used = 1 WHERE id = ?`,
                [otpRecord.id]
            );

            return { success: true, message: 'OTP is valid.' };
        } catch (error) {
            throw error;
        }
    },

    /**
     * Check if user is verified
     */
    async isEmailVerified(userId) {
        const [rows] = await db.query(
            `SELECT is_verified, email_verified_at FROM users WHERE id = ?`,
            [toBinaryUUID(userId)]
        );
        
        if (!rows || rows.length === 0) {
            return null;
        }
        
        return {
            is_verified: rows[0].is_verified,
            email_verified_at: rows[0].email_verified_at
        };
    },

    /**
     * Get unverified users (for notification/reminder purposes)
     */
    async getUnverifiedUsers(limit = 50) {
        const [rows] = await db.query(
            `SELECT u.id, u.full_name, u.email, u.created_at,
                    (SELECT ud.fcm_token FROM user_devices ud WHERE ud.user_id = u.id AND ud.is_active = 1 ORDER BY ud.last_used_at DESC LIMIT 1) AS fcm_token
             FROM users u
             WHERE u.is_verified = 0 
               AND u.status = 'ACTIVE'
               AND (u.is_deleted = 0 OR u.is_deleted IS NULL)
             ORDER BY u.created_at DESC
             LIMIT ?`,
            [limit]
        );
        
        return rows.map(r => ({
            id: fromBinaryUUID(r.id),
            full_name: r.full_name,
            email: r.email,
            created_at: r.created_at,
            fcm_token: r.fcm_token
        }));
    },

    /**
     * Get consolidated public (non-sensitive) details for a user across related tables
     */
    async getPublicDetails(userId) {
        const idBin = toBinaryUUID(userId);
        const [uRows] = await db.query(
            `SELECT id, full_name, email, mobile, referral_code, status, is_verified, email_verified_at, last_activity_at, created_at, updated_at
             FROM users WHERE id = ? AND (is_deleted = 0 OR is_deleted IS NULL)`,
            [idBin]
        );
        const u = uRows[0];
        if (!u) return null;

        const [pRows] = await db.query(
            `SELECT gender, date_of_birth, address_line1, address_line2, city, state, country, postal_code, profile_image_url
             FROM user_profiles WHERE user_id = ? LIMIT 1`,
            [idBin]
        );
        const profile = pRows[0] || {};

        // All known devices (active, inactive, and likely uninstalled)
        const [dRows] = await db.query(
            `SELECT id, user_id, fcm_token, device_name, device_id, is_active, token_status,
                    last_used_at, uninstalled_at, created_at, brand, model, manufacturer,
                    android_version, ram_size, platform, app_version
             FROM user_devices
             WHERE user_id = ? AND (is_deleted = 0 OR is_deleted IS NULL)
             ORDER BY last_used_at DESC, updated_at DESC`,
            [idBin]
        );
        const devices = (dRows || []).map(mapDeviceRow);

        const [referrerRows] = await db.query(
            `SELECT referrer_user_id FROM user_referrals WHERE referred_user_id = ? LIMIT 1`,
            [idBin]
        );

        const [referredCountRows] = await db.query(
            `SELECT COUNT(*) AS cnt FROM user_referrals WHERE referrer_user_id = ?`,
            [idBin]
        );

        return {
            id: fromBinaryUUID(u.id),
            full_name: u.full_name,
            email: u.email,
            mobile: u.mobile,
            referral_code: u.referral_code || null,
            status: u.status,
            is_verified: u.is_verified || 0,
            email_verified_at: u.email_verified_at || null,
            last_activity_at: u.last_activity_at,
            created_at: u.created_at,
            updated_at: u.updated_at,
            profile: {
                gender: profile.gender || null,
                date_of_birth: profile.date_of_birth || null,
                address_line1: profile.address_line1 || null,
                address_line2: profile.address_line2 || null,
                city: profile.city || null,
                state: profile.state || null,
                country: profile.country || null,
                postal_code: profile.postal_code || null,
                profile_image_url: profile.profile_image_url || null
            },
            device: devices[0] || null,
            devices,
            referrer_id: referrerRows && referrerRows[0] ? fromBinaryUUID(referrerRows[0].referrer_user_id) : null,
            referred_count: referredCountRows && referredCountRows[0] ? referredCountRows[0].cnt : 0
        };
    },

    // retrieve public details for all active users (admin use)
    async getAllPublicDetails(filters = {}) {
        const { limit = null, offset = 0 } = filters;

        let total = null;
        if (limit != null) {
            const [countRows] = await db.query(
                `SELECT COUNT(*) AS total FROM users u
                 WHERE (u.is_deleted = 0 OR u.is_deleted IS NULL)`
            );
            total = Number(countRows[0]?.total || 0);
        }

        let userQuery = `
             SELECT 
                u.id, u.full_name, u.email, u.mobile, u.referral_code, u.status, 
                u.is_verified, u.email_verified_at, u.last_activity_at, u.created_at, u.updated_at,
                up.gender, up.date_of_birth, up.address_line1, up.address_line2, 
                up.city, up.state, up.country, up.postal_code, up.profile_image_url
             FROM users u
             LEFT JOIN user_profiles up ON up.user_id = u.id
             WHERE (u.is_deleted = 0 OR u.is_deleted IS NULL)
             ORDER BY u.created_at DESC`;
        const userParams = [];
        if (limit != null) {
            userQuery += ` LIMIT ? OFFSET ?`;
            userParams.push(Number(limit), Number(offset) || 0);
        }

        const [rows] = await db.query(userQuery, userParams);

        const userIds = (rows || []).map((r) => fromBinaryUUID(r.id)).filter(Boolean);
        let deviceRows = [];
        if (userIds.length > 0) {
            const placeholders = userIds.map(() => '?').join(',');
            const [devices] = await db.query(
                `SELECT id, user_id, fcm_token, device_name, device_id, is_active, token_status,
                        last_used_at, uninstalled_at, created_at, brand, model, manufacturer,
                        android_version, ram_size, platform, app_version
                 FROM user_devices
                 WHERE (is_deleted = 0 OR is_deleted IS NULL)
                   AND user_id IN (${placeholders})
                 ORDER BY last_used_at DESC, updated_at DESC`,
                userIds.map((id) => toBinaryUUID(id))
            );
            deviceRows = devices || [];
        }

        const devicesByUser = new Map();
        for (const row of deviceRows) {
            const mapped = mapDeviceRow(row);
            const userId = mapped.user_id;
            if (!userId) continue;
            if (!devicesByUser.has(userId)) devicesByUser.set(userId, []);
            devicesByUser.get(userId).push(mapped);
        }

        const mapped = rows.map(r => {
            const id = fromBinaryUUID(r.id);
            const devices = devicesByUser.get(id) || [];
            return {
            id,
            full_name: r.full_name,
            email: r.email,
            mobile: r.mobile,
            referral_code: r.referral_code || null,
            status: r.status,
            is_verified: r.is_verified || 0,
            email_verified_at: r.email_verified_at || null,
            last_activity_at: r.last_activity_at,
            created_at: r.created_at,
            updated_at: r.updated_at,
            profile: {
                gender: r.gender || null,
                date_of_birth: r.date_of_birth || null,
                address_line1: r.address_line1 || null,
                address_line2: r.address_line2 || null,
                city: r.city || null,
                state: r.state || null,
                country: r.country || null,
                postal_code: r.postal_code || null,
                profile_image_url: r.profile_image_url || null
            },
            device: devices[0] || null,
            devices,
            referrer_id: null,
            referred_count: 0
            };
        });

        if (limit != null) {
            return { rows: mapped, total };
        }
        return mapped;
    },

    /**
     * Get pending OTP for user (if any active/non-expired)
     */
    async getPendingOTP(userId) {
        const [rows] = await db.query(
            `SELECT code, expires_at, is_used FROM user_otps
             WHERE user_id = ? AND type = 'VERIFY' AND is_used = 0
             AND expires_at > NOW()
             ORDER BY created_at DESC LIMIT 1`,
            [toBinaryUUID(userId)]
        );
        
        return rows.length > 0 ? rows[0] : null;
    },

    /**
     * Delete expired OTPs
     */
    async deleteExpiredOTPs() {
        const [result] = await db.query(
            `DELETE FROM user_otps WHERE expires_at < NOW()`
        );
        return result;
    },

    /**
     * Mark user email as verified manually (admin/system use)
     */
    async markEmailVerified(userId) {
        const now = new Date();
        const [result] = await db.query(
            `UPDATE users SET is_verified = 1, email_verified_at = ? WHERE id = ?`,
            [now, toBinaryUUID(userId)]
        );
        return result;
    }
};

function mapDeviceRow(row) {
    if (!row) return null;
    return {
        id: row.id != null ? fromBinaryUUID(row.id) : null,
        user_id: row.user_id != null ? fromBinaryUUID(row.user_id) : null,
        fcm_token: row.fcm_token || null,
        device_name: row.device_name || null,
        device_id: row.device_id || null,
        is_active: row.is_active,
        token_status: row.token_status || null,
        last_used_at: row.last_used_at || null,
        uninstalled_at: row.uninstalled_at || null,
        created_at: row.created_at || null,
        brand: row.brand || null,
        model: row.model || null,
        manufacturer: row.manufacturer || null,
        androidVersion: row.android_version || null,
        ram_size: row.ram_size || null,
        platform: row.platform || 'android',
        app_version: row.app_version || null,
    };
}

function mapUserRow(r, includeSensitive = true) {
    const id = fromBinaryUUID(r.id);
    const fcmToken = r.fcm_token || r.notification_token || null;
    const base = {
        id,
        um_id: id,
        full_name: r.full_name,
        um_full_name: r.full_name,
        email: r.email,
        um_email: r.email,
        mobile: r.mobile,
        um_mobile: r.mobile,
        referral_code: r.referral_code || null,
        um_referral_code: r.referral_code || null,
        signup_type: normalizeSignupType(r.signup_type || r.signupType || 'email'),
        google_id: r.google_id || r.googleId || null,
        password_set: r.password_set != null ? Boolean(r.password_set) : false,
        status: r.status,
        is_verified: r.is_verified || 0,
        email_verified_at: r.email_verified_at || null,
        last_activity_at: r.last_activity_at,
        um_last_login: r.last_activity_at,
        is_deleted: r.is_deleted || 0,
        deleted_at: r.deleted_at || null,
        profile_image_url: r.profile_image_url,
        um_profile_image: r.profile_image_url,
        notification_token: fcmToken,
        um_notification_token: fcmToken,
        created_at: r.created_at,
        um_create_dt: r.created_at,
        updated_at: r.updated_at,
        um_update_dt: r.updated_at,
        um_status: r.status
    };

    if (includeSensitive) {
        base.password_hash = r.password_hash;
        base.um_password = r.password_hash;
    }

    return base;
}

module.exports = User;
