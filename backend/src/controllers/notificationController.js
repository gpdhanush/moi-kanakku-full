const admin = require('firebase-admin');
const { Notification, NotificationType, isValidNotificationType } = require('../models/notificationModels');
const logger = require('../config/logger');
const { validateUuid, validateUuidList, sendUuidError } = require('../helpers/idParams');

const serviceAccount = {
    type: process.env.FIREBASE_TYPE,
    project_id: process.env.FIREBASE_PROJECT_ID,
    private_key_id: process.env.FIREBASE_PRIVATE_KEY_ID,
    private_key: (process.env.FIREBASE_PRIVATE_KEY || '').replace(/\\n/g, '\n'),
    client_email: process.env.FIREBASE_CLIENT_EMAIL,
    client_id: process.env.FIREBASE_CLIENT_ID,
    auth_uri: process.env.FIREBASE_AUTH_URI,
    token_uri: process.env.FIREBASE_TOKEN_URI,
    auth_provider_x509_cert_url: process.env.FIREBASE_AUTH_PROVIDER_X509_CERT_URL,
    client_x509_cert_url: process.env.FIREBASE_CLIENT_X509_CERT_URL,
    universe_domain: process.env.FIREBASE_UNIVERSE_DOMAIN,
};

if (!admin.apps.length) {
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
    });
}

const {
    isInvalidFcmTokenError,
    deactivateUnregisteredFcmToken,
} = require('../helpers/fcmTokenInvalidation');
const { mapWithConcurrency } = require('../helpers/concurrency');

/**
 * Helper function to send push notification (can be called directly without HTTP request/response)
 * @param {Object} params - { userId, title, body, token, type, skipDbSave, traceId }
 * @returns {Promise<Object>} - { success: boolean, message: string, fcmSent: boolean, dbSaved: boolean, messageId?: string, fcmError?: {code?: string, message?: string} }
 */
async function sendPushNotification({ userId, title, body, token, type, skipDbSave = false, traceId = null }) {
    // Validate required fields
    if (!token || !title || !body) {
        throw new Error('Token, title, and body are required.');
    }

    if (!userId) {
        throw new Error('User ID is required.');
    }

    // Validate notification type if provided
    if (type && !isValidNotificationType(type)) {
        throw new Error(`Invalid notification type. Allowed types: ${Object.values(NotificationType).join(', ')}`);
    }

    const message = {
        notification: {
            title: title,
            body: body,
        },
        data: {
            title: title,
            body: body,
            type: type || NotificationType.GENERAL,
            timestamp: new Date().toISOString(),
            notificationType: type || 'general'
        },
        token: token, // Target device FCM token
        android: {
            priority: 'high',
            ttl: 3600 * 1000,
            notification: {
                title: title,
                body: body,
                clickAction: 'FLUTTER_NOTIFICATION_CLICK'
            }
        },
        apns: {
            headers: {
                'apns-priority': '10'
            },
            payload: {
                aps: {
                    alert: {
                        title: title,
                        body: body
                    },
                    sound: 'default',
                    badge: 1,
                    'content-available': 1
                }
            }
        }
    };

    // Save notification to database first (unless skipDbSave is true)
    let notificationId = null;
    let dbSaveError = null;
    if (!skipDbSave) {
        try {
            const notificationResult = await Notification.create({
                userId: userId,
                title: title,
                body: body,
                type: type || NotificationType.GENERAL
            });
            notificationId = notificationResult.insertId;
            logger.info('Notification saved to DB', { traceId, userId, notificationId, type: type || NotificationType.GENERAL });
        } catch (dbError) {
            dbSaveError = { message: dbError?.message || String(dbError) };
            logger.error('Error saving notification to database:', { traceId, userId, error: dbSaveError.message });
            // Continue trying to send FCM even if DB save fails
        }
    }

    try {
        // Send notification via FCM
        const tokenPrefix = String(token).substring(0, 12);
        const tokenLength = String(token).length;
        logger.info('Sending FCM push', { traceId, userId, type: type || NotificationType.GENERAL, tokenPrefix, tokenLength, skipDbSave });
        const messageId = await admin.messaging().send(message);
        logger.info('FCM sent successfully', { traceId, userId, messageId });
        return {
            success: true,
            message: 'Notification sent successfully',
            fcmSent: true,
            dbSaved: !!notificationId,
            notificationId,
            dbSaveError,
            messageId
        };
    } catch (error) {
        // FCM send failed
        logger.error('FCM send error:', {
            traceId,
            userId,
            code: error?.code || null,
            message: error?.message || String(error)
        });

        if (isInvalidFcmTokenError(error)) {
            await deactivateUnregisteredFcmToken(token, { userId, traceId });
        }

        // Return success if notification was saved to DB, even if FCM failed
        if (notificationId) {
            return {
                success: true,
                message: 'Notification saved to database, but FCM could not be sent',
                fcmSent: false,
                dbSaved: true,
                notificationId,
                dbSaveError,
                fcmError: {
                    code: error.code || null,
                    message: error.message || String(error)
                }
            };
        }

        if (traceId) error.traceId = traceId;
        throw error;
    }
}

exports.sendPushNotification = sendPushNotification;
exports.isInvalidFcmTokenError = isInvalidFcmTokenError;
exports.deactivateUnregisteredFcmToken = deactivateUnregisteredFcmToken;

/**
 * Queue FCM send in background isolate queue — returns jobId immediately.
 * @param {Object} params - same as sendPushNotification
 * @returns {string} jobId
 */
function queuePushNotification(params) {
    const { enqueueFcm } = require('../services/backgroundJobQueue');
    const label = `fcm:${params?.userId || 'unknown'}`;
    return enqueueFcm(label, async () => {
        await sendPushNotification(params);
    });
}

exports.queuePushNotification = queuePushNotification;

function isAdminRequest(req) {
    return req.user?.accountType === 'admin' || Boolean(req.admin);
}

exports.controller = {
    /**
     * Check Firebase and notification system status (for debugging)
     */
    checkStatus: async (req, res) => {
        try {
            const status = {
                firebase: {
                    initialized: admin.apps.length > 0,
                    projectId: process.env.FIREBASE_PROJECT_ID || 'NOT_SET',
                    hasCredentials: !!(process.env.FIREBASE_PRIVATE_KEY && process.env.FIREBASE_CLIENT_EMAIL)
                },
                database: null,
                tokens: null
            };

            // Check database connection
            try {
                const db = require('../config/database');
                const [result] = await db.query('SELECT 1');
                status.database = { connected: true };
            } catch (dbError) {
                status.database = { connected: false, error: dbError.message };
            }

            // Check sample FCM tokens
            try {
                const db = require('../config/database');
                const [tokens] = await db.query(
                    `SELECT COUNT(*) as total, 
                            SUM(CASE WHEN is_active = 1 THEN 1 ELSE 0 END) as active
                     FROM user_devices`
                );
                status.tokens = tokens[0];
            } catch (tokenError) {
                status.tokens = { error: tokenError.message };
            }

            return res.status(200).json({
                responseType: "S",
                responseValue: status
            });
        } catch (error) {
            logger.error('Error checking status:', error);
            return res.status(500).json({
                responseType: "F",
                responseValue: { message: error.toString() }
            });
        }
    },
    /**
     * Send push notification via FCM and save notification to database
     * Body: { userId, title, body, token, type }
     * type: moi, moiOut, function, account, settings, feedback, general (default: general)
     */
    sendNotification: async (req, res) => {
        const { userId, title, body, token, type } = req.body;

        const idCheck = validateUuid(userId, 'userId');
        if (!idCheck.ok) return sendUuidError(res, idCheck.message);

        try {
            const jobId = queuePushNotification({ userId, title, body, token, type });
            return res.status(200).json({
                responseType: "S",
                responseValue: {
                    message: 'Notification queued for delivery.',
                    queued: true,
                    jobId,
                }
            });
        } catch (error) {
            // FCM send failed, don't save to database
            logger.error('FCM queue error:', error);

            // Handle FCM-specific errors
            let errorMessage = 'Could not send notification.';
            let statusCode = 500;

            if (error.code) {
                switch (error.code) {
                    case 'messaging/invalid-registration-token':
                    case 'messaging/registration-token-not-registered':
                        errorMessage = 'Invalid or expired device token. The user may have uninstalled the app or the token is no longer valid.';
                        statusCode = 400;
                        break;
                    case 'messaging/invalid-argument':
                        errorMessage = 'Invalid notification data provided.';
                        statusCode = 400;
                        break;
                    case 'messaging/unavailable':
                        errorMessage = 'FCM service is temporarily unavailable. Please try again later.';
                        statusCode = 503;
                        break;
                    case 'messaging/internal-error':
                        errorMessage = 'Internal FCM error occurred. Please try again later.';
                        statusCode = 500;
                        break;
                    default:
                        // Check error message for common patterns
                        if (error.message && error.message.includes('Requested entity was not found')) {
                            errorMessage = 'Invalid or expired device token. The device may have been uninstalled or the token is no longer valid.';
                            statusCode = 400;
                        } else if (error.message) {
                            errorMessage = error.message;
                        }
                }
            } else if (error.message) {
                // Handle error messages directly
                if (error.message.includes('Requested entity was not found')) {
                    errorMessage = 'Invalid or expired device token. The device may have been uninstalled or the token is no longer valid.';
                    statusCode = 400;
                } else {
                    errorMessage = error.message;
                }
            }

            return res.status(statusCode).json({
                responseType: "F",
                responseValue: { message: errorMessage }
            });
        }
    },

    /**
     * Get all notifications for the authenticated user (with pagination)
     * Uses userId from req.user (set by authenticateToken middleware)
     * Query: { limit?, offset? }
     */
    getAllNotifications: async (req, res) => {
        try {
            const userId = req.user.userId;
            const { limit = 50, offset = 0 } = req.body;

            if (!userId) {
                return res.status(400).json({
                    responseType: "F",
                    responseValue: { message: 'User ID is required.' }
                });
            }

            const notifications = await Notification.findByUserId(userId, Math.min(parseInt(limit), 100), parseInt(offset));
            const unreadCount = await Notification.getUnreadCount(userId);
            const totalCount = await Notification.getTotalCountByUserId(userId);

            return res.status(200).json({
                responseType: "S",
                count: notifications.length,
                totalCount: totalCount,
                unreadCount: unreadCount,
                responseValue: notifications
            });
        } catch (error) {
            logger.error('Error fetching notifications:', error);
            return res.status(500).json({
                responseType: "F",
                responseValue: { message: error.toString() }
            });
        }
    },

    /**
     * Get unread notification count for the authenticated user
     */
    getUnreadCount: async (req, res) => {
        try {
            const userId = req.user.userId;

            if (!userId) {
                return res.status(400).json({
                    responseType: "F",
                    responseValue: { message: 'User ID is required.' }
                });
            }

            const count = await Notification.getUnreadCount(userId);

            return res.status(200).json({
                responseType: "S",
                responseValue: { unreadCount: Number(count) || 0 }
            });
        } catch (error) {
            logger.error('Error fetching unread count:', error);
            return res.status(500).json({
                responseType: "F",
                responseValue: { message: error.toString() }
            });
        }
    },

    /**
     * Mark notification as read
     * Body: { notificationId }
     */
    markAsRead: async (req, res) => {
        try {
            const { notificationId } = req.body;

            if (!notificationId) {
                return res.status(400).json({
                    responseType: "F",
                    responseValue: { message: 'Notification ID is required.' }
                });
            }

            const idCheck = validateUuid(notificationId, 'notificationId');
            if (!idCheck.ok) return sendUuidError(res, idCheck.message);

            // Check if notification exists
            const notification = await Notification.findById(notificationId);
            if (!notification) {
                return res.status(404).json({
                    responseType: "F",
                    responseValue: { message: 'No details found.' }
                });
            }

            // Check if notification belongs to the authenticated user
            const userId = req.user.userId;
            if (notification.userId !== userId) {
                return res.status(403).json({
                    responseType: "F",
                    responseValue: { message: 'You do not have permission to access this notification.' }
                });
            }

            // Update read status
            const result = await Notification.markAsRead(notificationId);

            if (result && result.affectedRows > 0) {
                return res.status(200).json({
                    responseType: "S",
                    responseValue: { message: 'Notification successfully marked as read.' }
                });
            } else {
                return res.status(404).json({
                    responseType: "F",
                    responseValue: { message: 'Could not update notification status.' }
                });
            }
        } catch (error) {
            logger.error('Error marking notification as read:', error);
            return res.status(500).json({
                responseType: "F",
                responseValue: { message: error.toString() }
            });
        }
    },

    /**
     * Mark notification as unread
     * Body: { notificationId }
     */
    markAsUnread: async (req, res) => {
        try {
            const { notificationId } = req.body;

            if (!notificationId) {
                return res.status(400).json({
                    responseType: "F",
                    responseValue: { message: 'Notification ID is required.' }
                });
            }

            const idCheck = validateUuid(notificationId, 'notificationId');
            if (!idCheck.ok) return sendUuidError(res, idCheck.message);

            // Check if notification exists
            const notification = await Notification.findById(notificationId);
            if (!notification) {
                return res.status(404).json({
                    responseType: "F",
                    responseValue: { message: 'No details found.' }
                });
            }

            // Check if notification belongs to the authenticated user
            const userId = req.user.userId;
            if (notification.userId !== userId) {
                return res.status(403).json({
                    responseType: "F",
                    responseValue: { message: 'You do not have permission to access this notification.' }
                });
            }

            // Update read status
            const result = await Notification.markAsUnread(notificationId);

            if (result && result.affectedRows > 0) {
                return res.status(200).json({
                    responseType: "S",
                    responseValue: { message: 'Notification successfully marked as unread.' }
                });
            } else {
                return res.status(404).json({
                    responseType: "F",
                    responseValue: { message: 'Could not update notification status.' }
                });
            }
        } catch (error) {
            logger.error('Error marking notification as unread:', error);
            return res.status(500).json({
                responseType: "F",
                responseValue: { message: error.toString() }
            });
        }
    },

    /**
     * Delete a single notification (hard delete)
     * Body/Query/Params: { notificationId } or /delete/:notificationId
     */
    delete: async (req, res) => {
        try {
            const notificationId = req.body?.notificationId || req.body?.id || req.query?.notificationId || req.query?.id || req.params?.notificationId || req.params?.id;

            if (!notificationId) {
                return res.status(400).json({
                    responseType: "F",
                    responseValue: { message: 'Notification ID is required.' }
                });
            }

            const idCheck = validateUuid(notificationId, 'notificationId');
            if (!idCheck.ok) return sendUuidError(res, idCheck.message);

            // Check if notification exists
            const notification = await Notification.findById(notificationId);
            if (!notification) {
                return res.status(404).json({
                    responseType: "F",
                    responseValue: { message: 'No details found.' }
                });
            }

            // Users may only delete their own notifications. Admins can delete any.
            const userId = req.user?.userId;
            if (!isAdminRequest(req) && userId && String(notification.userId) !== String(userId)) {
                return res.status(403).json({
                    responseType: "F",
                    responseValue: { message: 'You do not have permission to delete this notification.' }
                });
            }

            // Delete notification
            const result = await Notification.delete(notificationId);

            if (result && result.affectedRows > 0) {
                return res.status(200).json({
                    responseType: "S",
                    responseValue: { message: 'Notification deleted successfully.' }
                });
            } else {
                return res.status(404).json({
                    responseType: "F",
                    responseValue: { message: 'Could not delete notification.' }
                });
            }
        } catch (error) {
            logger.error('Error deleting notification:', error);
            return res.status(500).json({
                responseType: "F",
                responseValue: { message: error.toString() }
            });
        }
    },

    /**
     * Delete multiple notifications (hard delete)
     * Body: { notificationIds: [] } or { ids: [] }
     */
    deleteMultiple: async (req, res) => {
        try {
            const notificationIds = req.body?.notificationIds || req.body?.ids || req.body?.notification_ids;

            if (!notificationIds || !Array.isArray(notificationIds) || notificationIds.length === 0) {
                return res.status(400).json({
                    responseType: "F",
                    responseValue: { message: 'An array of notification IDs is required.' }
                });
            }

            const listCheck = validateUuidList(notificationIds, 'notificationIds');
            if (!listCheck.ok) return sendUuidError(res, listCheck.message);

            const userId = req.user?.userId;
            if (!isAdminRequest(req) && userId) {
                const db = require('../config/database');
                const { toBinaryUUID } = require('../helpers/uuid');
                const binaryIds = notificationIds.map(id => toBinaryUUID(id));
                const placeholders = binaryIds.map(() => '?').join(',');

                const [result] = await db.query(
                    `DELETE FROM notifications WHERE id IN (${placeholders}) AND user_id = ?`,
                    [...binaryIds, toBinaryUUID(userId)]
                );

                return res.status(200).json({
                    responseType: "S",
                    responseValue: {
                        message: 'Selected notifications deleted successfully.',
                        deletedCount: result.affectedRows
                    }
                });
            }

            const result = await Notification.deleteMultiple(notificationIds);

            return res.status(200).json({
                responseType: "S",
                responseValue: {
                    message: 'Selected notifications deleted successfully.',
                    deletedCount: result.affectedRows
                }
            });
        } catch (error) {
            logger.error('Error deleting multiple notifications:', error);
            return res.status(500).json({
                responseType: "F",
                responseValue: { message: error.toString() }
            });
        }
    },

    /**
     * Admin: hard-delete notifications by scope (read, unread, all)
     * Body: { scope: 'read' | 'unread' | 'all' }
     */
    deleteByScope: async (req, res) => {
        try {
            if (!isAdminRequest(req)) {
                return res.status(403).json({
                    responseType: "F",
                    responseValue: { message: 'Admin access is required.' }
                });
            }

            const scope = String(req.body?.scope || req.query?.scope || '').toLowerCase();
            if (!['read', 'unread', 'all'].includes(scope)) {
                return res.status(400).json({
                    responseType: "F",
                    responseValue: { message: "scope must be read, unread, or all." }
                });
            }

            const result = await Notification.deleteByScope(scope);
            return res.status(200).json({
                responseType: "S",
                responseValue: {
                    message: `Deleted ${result.affectedRows || 0} ${scope} notification(s).`,
                    deletedCount: result.affectedRows || 0,
                    scope
                }
            });
        } catch (error) {
            logger.error('Error deleting notifications by scope:', error);
            return res.status(500).json({
                responseType: "F",
                responseValue: { message: error.toString() }
            });
        }
    },

    /**
     * Mark all notifications as read for the authenticated user
     */
    markAllAsRead: async (req, res) => {
        try {
            const userId = req.user.userId;

            if (!userId) {
                return res.status(400).json({
                    responseType: "F",
                    responseValue: { message: 'User ID is required.' }
                });
            }

            const result = await Notification.markAllAsRead(userId);

            return res.status(200).json({
                responseType: "S",
                responseValue: {
                    message: 'All notifications successfully marked as read.',
                    updatedCount: result.changedRows
                }
            });
        } catch (error) {
            logger.error('Error marking all as read:', error);
            return res.status(500).json({
                responseType: "F",
                responseValue: { message: error.toString() }
            });
        }
    },

    /**
     * Send bulk notifications to multiple users
     * Body: { userIds: [], title, body, type }
     * Steps:
     * 1. Validate users exist in users table
     * 2. Get FCM tokens from user_devices table
     * 3. Send FCM push notifications
     * 4. Save notifications to database
     * 5. Return results with success/failure counts
     */
    sendBulkNotifications: async (req, res) => {
        try {
            const { userIds, title, body, type } = req.body;

            // Validate input
            if (!userIds || !Array.isArray(userIds) || userIds.length === 0) {
                return res.status(400).json({
                    responseType: "F",
                    responseValue: { message: 'An array of user IDs is required.' }
                });
            }

            const listCheck = validateUuidList(userIds, 'userIds');
            if (!listCheck.ok) return sendUuidError(res, listCheck.message);

            if (!title || !body) {
                return res.status(400).json({
                    responseType: "F",
                    responseValue: { message: 'Title and body are required.' }
                });
            }

            // Validate notification type if provided
            if (type && !isValidNotificationType(type)) {
                return res.status(400).json({
                    responseType: "F",
                    responseValue: { message: `Invalid notification type. Allowed types: ${Object.values(NotificationType).join(', ')}` }
                });
            }

            const db = require('../config/database');
            const { toBinaryUUID, fromBinaryUUID } = require('../helpers/uuid');

            // Step 1: Get all users and their FCM tokens
            const userIdsFormatted = userIds.map(id => toBinaryUUID(id));
            const placeholders = userIdsFormatted.map(() => '?').join(',');

            // Use a subquery to get the most recent active device for each user
            const [users] = await db.query(
                `SELECT u.id, u.full_name, u.email,
                        (SELECT ud.fcm_token FROM user_devices ud 
                         WHERE ud.user_id = u.id AND ud.is_active = 1 
                         ORDER BY ud.last_used_at DESC LIMIT 1) AS fcm_token
                 FROM users u
                 WHERE u.id IN (${placeholders}) AND (u.is_deleted = 0 OR u.is_deleted IS NULL)`,
                userIdsFormatted
            );

            if (users.length === 0) {
                return res.status(404).json({
                    responseType: "F",
                    responseValue: { message: 'No users found for the provided user IDs.' }
                });
            }

            // Save notifications to DB first (fast), then queue FCM in background isolate.
            const notificationsToSave = users.map((user) => ({
                userId: fromBinaryUUID(user.id),
                title: title,
                body: body,
                type: type || NotificationType.GENERAL
            }));

            if (notificationsToSave.length > 0) {
                try {
                    await Notification.createBulk(notificationsToSave);
                    logger.info(`Queued bulk: saved ${notificationsToSave.length} notifications in DB.`);
                } catch (dbError) {
                    logger.error('Error saving bulk notifications to DB:', dbError);
                }
            }

            const fcmUsers = users.map((user) => ({
                userId: fromBinaryUUID(user.id),
                email: user.email || null,
                fcm_token: user.fcm_token || null,
                full_name: user.full_name || null,
            }));

            const { enqueueBulkIsolate } = require('../services/backgroundJobQueue');
            const { jobId, mode } = enqueueBulkIsolate('bulk_fcm', {
                users: fcmUsers,
                title,
                body,
                type: type || NotificationType.GENERAL,
            });

            return res.status(200).json({
                responseType: "S",
                responseValue: {
                    message: `Notifications queued for ${users.length} users. Delivery continues in background.`,
                    queued: true,
                    jobId,
                    mode,
                    totalRequested: userIds.length,
                    usersFound: users.length,
                    dbSaved: notificationsToSave.length,
                }
            });

        } catch (error) {
            logger.error('Error in sendBulkNotifications:', error);
            return res.status(500).json({
                responseType: "F",
                responseValue: { message: error.toString() }
            });
        }
    },

    /**
     * Send admin notification to a single user based on userId
     * Body: { userId, title, body, type }
     */
    sendNotificationToUser: async (req, res) => {
        try {
            const { userId, title, body, type } = req.body;

            if (!userId) {
                return res.status(400).json({
                    responseType: "F",
                    responseValue: { message: 'User ID is required.' }
                });
            }

            const idCheck = validateUuid(userId, 'userId');
            if (!idCheck.ok) return sendUuidError(res, idCheck.message);

            if (!title || !body) {
                return res.status(400).json({
                    responseType: "F",
                    responseValue: { message: 'Title and body are required.' }
                });
            }

            if (type && !isValidNotificationType(type)) {
                return res.status(400).json({
                    responseType: "F",
                    responseValue: { message: `Invalid notification type. Allowed types: ${Object.values(NotificationType).join(', ')}` }
                });
            }

            const db = require('../config/database');
            const { toBinaryUUID } = require('../helpers/uuid');

            // Find user and their most recent active FCM token
            const [users] = await db.query(
                `SELECT u.id, u.full_name, u.email,
                        (SELECT ud.fcm_token FROM user_devices ud 
                         WHERE ud.user_id = u.id AND ud.is_active = 1 
                         ORDER BY ud.last_used_at DESC LIMIT 1) AS fcm_token
                 FROM users u
                 WHERE u.id = ? AND (u.is_deleted = 0 OR u.is_deleted IS NULL)`,
                [toBinaryUUID(userId)]
            );

            if (users.length === 0) {
                return res.status(404).json({
                    responseType: "F",
                    responseValue: { message: 'User not found.' }
                });
            }

            const user = users[0];

            if (!user.fcm_token) {
                // Save notification to DB even if FCM token is missing
                let notificationId = null;
                try {
                    const notificationResult = await Notification.create({
                        userId: userId,
                        title: title,
                        body: body,
                        type: type || NotificationType.GENERAL
                    });
                    notificationId = notificationResult.insertId;
                } catch (dbError) {
                    logger.error(`Error saving notification to DB for user ${userId}:`, dbError);
                }

                return res.status(200).json({
                    responseType: "S",
                    responseValue: {
                        message: 'Notification saved to database (FCM device token not available).',
                        fcmSent: false,
                        dbSaved: !!notificationId,
                        notificationId
                    }
                });
            }

            const result = queuePushNotification({
                userId,
                title,
                body,
                token: user.fcm_token,
                type
            });

            return res.status(200).json({
                responseType: "S",
                responseValue: {
                    message: 'Notification queued for delivery.',
                    queued: true,
                    jobId: result,
                    fcmSent: false,
                    dbSaved: false,
                }
            });
        } catch (error) {
            logger.error('Error in sendNotificationToUser:', error);
            return res.status(500).json({
                responseType: "F",
                responseValue: { message: error.toString() }
            });
        }
    },

    /**
     * Get all notifications for a specific user based on userId (Admin Endpoint)
     * Supports both GET and POST requests
     * Body/Query/Params: { userId, limit?, offset? }
     */
    getNotificationsByUserId: async (req, res) => {
        try {
            const userId = req.body?.userId || req.query?.userId || req.params?.userId;
            const limit = req.body?.limit || req.query?.limit || 50;
            const offset = req.body?.offset || req.query?.offset || 0;

            if (!userId) {
                return res.status(400).json({
                    responseType: "F",
                    responseValue: { message: 'User ID is required.' }
                });
            }

            const idCheck = validateUuid(userId, 'userId');
            if (!idCheck.ok) return sendUuidError(res, idCheck.message);

            const db = require('../config/database');
            const { toBinaryUUID } = require('../helpers/uuid');

            // Verify user exists
            const [users] = await db.query(
                `SELECT id FROM users WHERE id = ? AND (is_deleted = 0 OR is_deleted IS NULL)`,
                [toBinaryUUID(userId)]
            );

            if (users.length === 0) {
                return res.status(404).json({
                    responseType: "F",
                    responseValue: { message: 'User not found.' }
                });
            }

            const notifications = await Notification.findByUserId(userId, Math.min(parseInt(limit), 100), parseInt(offset));
            const unreadCount = await Notification.getUnreadCount(userId);
            const totalCount = await Notification.getTotalCountByUserId(userId);

            return res.status(200).json({
                responseType: "S",
                count: notifications.length,
                totalCount: totalCount,
                unreadCount: unreadCount,
                responseValue: notifications
            });
        } catch (error) {
            logger.error('Error fetching notifications by userId:', error);
            return res.status(500).json({
                responseType: "F",
                responseValue: { message: error.toString() }
            });
        }
    },

    /**
     * Get all notifications across all users without userId (Admin Endpoint)
     * Method: GET / POST
     * Query/Body: { limit?, offset? }
     */
    getAllNotificationsAdmin: async (req, res) => {
        try {
            const limit = req.query?.limit || req.body?.limit || 50;
            const offset = req.query?.offset || req.body?.offset || 0;

            const parsedLimit = Math.min(Math.max(parseInt(limit) || 50, 1), 100);
            const parsedOffset = Math.max(parseInt(offset) || 0, 0);

            const notifications = await Notification.findAll(parsedLimit, parsedOffset);
            const totalCount = await Notification.getTotalCount();

            return res.status(200).json({
                responseType: "S",
                count: notifications.length,
                totalCount: totalCount,
                responseValue: notifications
            });
        } catch (error) {
            logger.error('Error fetching all notifications for admin:', error);
            return res.status(500).json({
                responseType: "F",
                responseValue: { message: error.toString() }
            });
        }
    },
}
