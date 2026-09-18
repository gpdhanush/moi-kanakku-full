const Model = require('../models/feedbacks');
const User = require('../models/user');
const db = require('../config/database');
const { generateUUID, toBinaryUUID } = require('../helpers/uuid');
const { validateUuid, sendUuidError } = require('../helpers/idParams');
const { queuePushNotification } = require('./notificationController');
const { Notification, NotificationType } = require('../models/notificationModels');
const {
    queueFeedbackConfirmationEmail,
    queueFeedbackReplyEmail,
} = require('../services/emailService');
const logger = require('../config/logger');
const { recordAuditLog } = require('../helpers/auditLog');

const FEEDBACK_TYPES = ['GENERAL', 'BUG', 'FEATURE', 'COMPLAINT'];
const FEEDBACK_STATUSES = ['OPEN', 'IN_PROGRESS', 'RESOLVED', 'REJECTED'];

const toISOStringOrNull = (value) => {
    if (!value) return null;
    const date = new Date(value);
    return Number.isNaN(date.getTime()) ? null : date.toISOString();
};

exports.controller = {
    create: async (req, res) => {
        try {
            const userId = req.body.userId;
            const message = String(req.body.message ?? req.body.feedbacks ?? '').trim();
            const type = String(req.body.type || 'GENERAL').toUpperCase();

            if (!userId || !message) {
                return res.status(400).json({ responseType: "F", responseValue: { message: "User ID and message are required!" } });
            }

            const idCheck = validateUuid(userId, 'userId');
            if (!idCheck.ok) return sendUuidError(res, idCheck.message);

            if (!FEEDBACK_TYPES.includes(type)) {
                return res.status(400).json({
                    responseType: "F",
                    responseValue: { message: "Invalid feedback type!" }
                });
            }

            const user = await User.findById(userId);
            if (!user) {
                return res.status(404).json({ responseType: "F", responseValue: { message: "Specified user not found!" } });
            }

            const payload = {
                userId,
                message,
                type
            };

            const query = await Model.create(payload);

            if (query) {
                if (user.um_notification_token) {
                    queuePushNotification({
                        userId,
                        title: 'New Feedback Submitted',
                        body: 'Your feedback has been successfully submitted. We will review it shortly.',
                        token: user.um_notification_token,
                        type: NotificationType.GENERAL
                    });
                }
                if (user.um_email) {
                    queueFeedbackConfirmationEmail(user.um_email, user.um_full_name);
                }

                recordAuditLog({
                    userId,
                    action: 'FEEDBACK_CREATE',
                    entityType: 'feedback',
                    entityId: query.insertId,
                    summary: `Feedback submitted (${type})`,
                    metadata: { type },
                    req,
                });

                return res.status(200).json({
                    responseType: "S",
                    responseValue: {
                        message: "Data saved successfully.",
                        id: query.insertId
                    }
                });
            } else {
                return res.status(404).json({ responseType: "F", responseValue: { message: "Failed to save data. Please try again later." } });
            }
        } catch (error) {
            return res.status(500).json({ responseType: "F", responseValue: { message: error.toString() } });
        }
    },
    list: async (req, res) => {
        try {
            const userId =  req.body.userId;
            const status = req.body.status ? String(req.body.status).toUpperCase() : null;
            const type = req.body.type ? String(req.body.type).toUpperCase() : null;
            
            if (!userId) {
                return res.status(400).json({ responseType: "F", responseValue: { message: "User ID is required!" } });
            }

            const idCheck = validateUuid(userId, 'userId');
            if (!idCheck.ok) return sendUuidError(res, idCheck.message);

            if (status && !FEEDBACK_STATUSES.includes(status)) {
                return res.status(400).json({
                    responseType: "F",
                    responseValue: { message: "Invalid feedback status!" }
                });
            }

            if (type && !FEEDBACK_TYPES.includes(type)) {
                return res.status(400).json({
                    responseType: "F",
                    responseValue: { message: "Invalid feedback type!" }
                });
            }

            const user = await User.findById(userId);
            if (!user) {
                return res.status(404).json({ responseType: "F", responseValue: { message: "Specified user not found!" } });
            }

            const feedbacks = await Model.readAll(userId, { status, type });
            if (!feedbacks || feedbacks.length === 0) {
                return res.status(200).json({ responseType: "S", count: 0, responseValue: [] });
            }
            
            const formattedFeedbacks = feedbacks.map(feedback => {
                return {
                    id: feedback.id,
                    userId: feedback.userId,
                    userName: feedback.userName,
                    userEmail: feedback.userEmail,
                    userMobile: feedback.userMobile,
                    type: feedback.type,
                    message: feedback.message || '',
                    adminResponse: feedback.adminResponse || '',
                    status: feedback.status,
                    respondedAt: toISOStringOrNull(feedback.respondedAt),
                    createdAt: toISOStringOrNull(feedback.createdAt),
                    updatedAt: toISOStringOrNull(feedback.updatedAt)
                };
            });
            
            return res.status(200).json({ responseType: "S", count: formattedFeedbacks.length, responseValue: formattedFeedbacks });
        } catch (error) {
            return res.status(500).json({ responseType: "F", responseValue: { message: error.toString() } });
        }
    },

        adminAllFeedbackLists: async (req, res) => {
            try {
                const limit = parseInt(req.query.limit) || 100;
                const offset = parseInt(req.query.offset) || 0;
                const status = req.query.status || null;
                const type = req.query.type || null;

                const feedbacks = await Model.getAllFeedbacks({ limit, offset, status, type });
                
                if (!feedbacks || feedbacks.length === 0) {
                    return res.status(200).json({ responseType: "S", count: 0, responseValue: [] });
                }
                
                const formattedFeedbacks = feedbacks.map(feedback => {
                    return {
                        id: feedback.id,
                        userId: feedback.userId,
                        userName: feedback.userName,
                        userEmail: feedback.userEmail,
                        type: feedback.type,
                        message: feedback.message || '',
                        adminResponse: feedback.adminResponse || '',
                        status: feedback.status,
                        respondedAt: toISOStringOrNull(feedback.respondedAt),
                        createdAt: toISOStringOrNull(feedback.createdAt),
                        updatedAt: toISOStringOrNull(feedback.updatedAt)
                    };
                });
                
                return res.status(200).json({ 
                    responseType: "S", 
                    count: formattedFeedbacks.length, 
                    responseValue: formattedFeedbacks 
                });
            } catch (error) {
                logger.error('Error fetching all feedbacks: ', error);
                return res.status(500).json({ responseType: "F", responseValue: { message: error.toString() } });
            }
        },

        adminReplyFeedback: async (req, res) => {
            try {
                const traceId = generateUUID();
                const { feedbackId, adminResponse, status } = req.body;

                if (!feedbackId || !adminResponse) {
                    return res.status(400).json({ 
                        responseType: "F", 
                        responseValue: { message: "Feedback ID and admin response are required!" } 
                    });
                }

                const idCheck = validateUuid(feedbackId, 'feedbackId');
                if (!idCheck.ok) return sendUuidError(res, idCheck.message);

                logger.info('adminReplyFeedback start', { traceId, feedbackId });

                const adminResponseText = String(adminResponse).trim();
                if (adminResponseText.length === 0) {
                    return res.status(400).json({ 
                        responseType: "F", 
                        responseValue: { message: "Admin response cannot be empty!" } 
                    });
                }

                // Validate status if provided
                const feedbackStatus = status || 'RESOLVED';
                if (!FEEDBACK_STATUSES.includes(feedbackStatus)) {
                    return res.status(400).json({ 
                        responseType: "F", 
                        responseValue: { message: "Invalid feedback status!" } 
                    });
                }

                // Get feedback details to find user
                const feedback = await Model.readById(feedbackId);
                if (!feedback) {
                    return res.status(404).json({ 
                        responseType: "F", 
                        responseValue: { message: "Feedback not found!" } 
                    });
                }

                logger.info('adminReplyFeedback loaded feedback', { traceId, feedbackId, userId: feedback.userId });

                // Update feedback with admin response
                const updated = await Model.addResponse(feedbackId, adminResponseText);
                if (!updated) {
                    return res.status(500).json({ 
                        responseType: "F", 
                        responseValue: { message: "Failed to update feedback!" } 
                    });
                }

                // Update status if provided and different from RESOLVED
                if (status && status !== 'RESOLVED') {
                    await Model.updateStatus(feedbackId, status);
                }

                // Get updated feedback
                const updatedFeedback = await Model.readById(feedbackId);

                // Queue email + FCM (non-blocking isolate queue)
                if (feedback.userEmail) {
                    queueFeedbackReplyEmail(feedback.userEmail, feedback.userName, adminResponseText);
                }

                const notificationTitle = 'Feedback Response';
                const notificationBody = adminResponseText.length > 120
                    ? `${adminResponseText.slice(0, 117)}...`
                    : adminResponseText;

                let pushNotification = {
                    traceId,
                    attempted: false,
                    fcmSent: false,
                    dbSaved: false,
                    notificationId: null,
                    queued: false,
                    jobIds: [],
                    message: null,
                    reason: null,
                    tokensFound: 0,
                };
                try {
                    const [deviceRows] = await db.query(
                        `SELECT fcm_token
                         FROM user_devices
                         WHERE user_id = ?
                           AND is_active = 1
                           AND (is_deleted = 0 OR is_deleted IS NULL)
                         ORDER BY last_used_at DESC, updated_at DESC`,
                        [toBinaryUUID(feedback.userId)]
                    );

                    const tokens = (deviceRows || []).map(r => r.fcm_token).filter(Boolean);
                    pushNotification.tokensFound = tokens.length;
                    logger.info('adminReplyFeedback device tokens', { traceId, userId: feedback.userId, tokensFound: tokens.length });

                    try {
                        const n = await Notification.create({
                            userId: feedback.userId,
                            title: notificationTitle,
                            body: notificationBody,
                            type: NotificationType.GENERAL
                        });
                        pushNotification.dbSaved = true;
                        pushNotification.notificationId = n?.insertId || null;
                    } catch (dbError) {
                        pushNotification.reason = 'NOTIFICATION_DB_SAVE_FAILED';
                        pushNotification.message = dbError?.message || String(dbError);
                        logger.error('Error saving notification to DB: ', dbError);
                    }

                    if (tokens.length > 0) {
                        pushNotification.attempted = true;
                        pushNotification.queued = true;
                        tokens.forEach((token) => {
                            const jobId = queuePushNotification({
                                userId: feedback.userId,
                                title: notificationTitle,
                                body: notificationBody,
                                token,
                                type: NotificationType.GENERAL,
                                skipDbSave: true,
                                traceId
                            });
                            pushNotification.jobIds.push(jobId);
                        });
                        pushNotification.message = 'Push notification queued for background delivery';
                    } else {
                        pushNotification.reason = 'NO_ACTIVE_FCM_TOKEN';
                        pushNotification.message = 'Notification saved to DB (no active device token)';
                    }
                } catch (notifyError) {
                    pushNotification.reason = notifyError?.message || 'PUSH_NOTIFICATION_ERROR';
                    logger.error('Error queueing push notification: ', notifyError);
                }

                return res.status(200).json({ 
                    responseType: "S", 
                    responseValue: {
                        message: "Feedback reply sent successfully!",
                        pushNotification,
                        feedback: {
                            id: updatedFeedback.id,
                            userId: updatedFeedback.userId,
                            userName: updatedFeedback.userName,
                            userEmail: updatedFeedback.userEmail,
                            type: updatedFeedback.type,
                            message: updatedFeedback.message,
                            adminResponse: updatedFeedback.adminResponse,
                            status: updatedFeedback.status,
                            respondedAt: toISOStringOrNull(updatedFeedback.respondedAt),
                            createdAt: toISOStringOrNull(updatedFeedback.createdAt),
                            updatedAt: toISOStringOrNull(updatedFeedback.updatedAt)
                        }
                    } 
                });
            } catch (error) {
                logger.error('Error replying to feedback: ', error);
                return res.status(500).json({ 
                    responseType: "F", 
                    responseValue: { message: error.toString() } 
                });
            }
        },

        adminDeleteFeedback: async (req, res) => {
            try {
                const traceId = generateUUID();
                const { feedbackId } = req.body;

                if (!feedbackId) {
                    return res.status(400).json({
                        responseType: "F",
                        responseValue: { message: "Feedback ID is required!" }
                    });
                }

                const idCheck = validateUuid(feedbackId, 'feedbackId');
                if (!idCheck.ok) return sendUuidError(res, idCheck.message);

                logger.info('adminDeleteFeedback start', { traceId, feedbackId });

                const feedback = await Model.readById(feedbackId);
                if (!feedback) {
                    return res.status(404).json({
                        responseType: "F",
                        responseValue: { message: "Feedback not found!" }
                    });
                }

                const deleted = await Model.delete(feedbackId);
                if (!deleted) {
                    return res.status(500).json({
                        responseType: "F",
                        responseValue: { message: "Failed to delete feedback!" }
                    });
                }

                return res.status(200).json({
                    responseType: "S",
                    responseValue: {
                        message: "Feedback deleted successfully!",
                        traceId,
                        feedbackId
                    }
                });
            } catch (error) {
                logger.error('Error deleting feedback: ', error);
                return res.status(500).json({
                    responseType: "F",
                    responseValue: { message: error.toString() }
                });
            }
        },

        adminDeleteBulk: async (req, res) => {
            try {
                const ids = Array.isArray(req.body?.feedbackIds)
                    ? req.body.feedbackIds
                    : Array.isArray(req.body?.ids)
                        ? req.body.ids
                        : [];
                const uniqueIds = [...new Set(ids.map((id) => String(id).trim()).filter(Boolean))];

                if (uniqueIds.length === 0) {
                    return res.status(400).json({
                        responseType: "F",
                        responseValue: { message: "Select at least one feedback to delete." }
                    });
                }

                for (const id of uniqueIds) {
                    const idCheck = validateUuid(id, 'feedbackId');
                    if (!idCheck.ok) return sendUuidError(res, idCheck.message);
                }

                const deletedCount = await Model.deleteMultiple(uniqueIds);
                if (!deletedCount) {
                    return res.status(404).json({
                        responseType: "F",
                        responseValue: { message: "No matching feedbacks were deleted." }
                    });
                }

                return res.status(200).json({
                    responseType: "S",
                    responseValue: {
                        message: `Deleted ${deletedCount} feedback record(s).`,
                        deletedCount
                    }
                });
            } catch (error) {
                logger.error('Error bulk deleting feedback: ', error);
                return res.status(500).json({
                    responseType: "F",
                    responseValue: { message: error.toString() }
                });
            }
        },

        adminDeleteByScope: async (req, res) => {
            try {
                const scope = String(req.body?.scope || '').toLowerCase();
                if (!['pending', 'resolved', 'all'].includes(scope)) {
                    return res.status(400).json({
                        responseType: "F",
                        responseValue: { message: "Scope must be pending, resolved, or all." }
                    });
                }

                const result = await Model.deleteByScope(scope);
                const deletedCount = result?.affectedRows || 0;
                if (!deletedCount) {
                    return res.status(404).json({
                        responseType: "F",
                        responseValue: {
                            message: `No ${scope === 'all' ? '' : scope + ' '}feedbacks found to delete.`
                        }
                    });
                }

                return res.status(200).json({
                    responseType: "S",
                    responseValue: {
                        message: `Deleted ${deletedCount} ${scope} feedback record(s).`,
                        deletedCount,
                        scope
                    }
                });
            } catch (error) {
                logger.error('Error deleting feedbacks by scope: ', error);
                return res.status(500).json({
                    responseType: "F",
                    responseValue: { message: error.toString() }
                });
            }
        }
};
