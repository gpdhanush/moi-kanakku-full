const express = require('express');
const { controller } = require('../controllers/emailControllers');
const { authenticateToken, authenticateAdminToken } = require('../middlewares/auth');

const router = express.Router();

// ==================== UNIFIED ENDPOINTS ====================

/**
 * Send email with OTP or custom content
 * POST /api/email/sendEmail
 * Body: { type, email, id, subject?, content?, sendNotification?, ...notifPayload }
 * type: 'restore' | 'verification' | 'forgot' | 'custom'
 */
router.post('/sendEmail', controller.sendEmail);

/**
 * Verify OTP (unified for all types)
 * POST /api/email/verifyOtp
 * Body: { email|emailId|id, otp, type? }
 * type: 'forgot' | 'verification' | 'restore' (default: 'forgot')
 */
router.post('/verifyOtp', controller.verifyOtp);

// ==================== ADMIN ENDPOINTS ====================

/**
 * Send bulk emails to multiple users
 * POST /api/email/admin/send-bulk
 * Body: { userIds: [], subject, body, type? }
 * type: 'notification' | 'announcement' | 'custom' (default: 'custom')
 */
router.post('/admin/send-bulk', authenticateAdminToken, controller.sendBulkEmails);

/**
 * Send a token-link verification email to one user
 * POST /api/email/admin/send-verify-email
 * Body: { userId }
 */
router.post('/admin/send-verify-email', authenticateAdminToken, controller.sendAdminVerifyEmail);

/**
 * Verify email from the link in the verification email
 * GET /api/email/verify-email?token=
 */
router.get('/verify-email', controller.verifyEmailByToken);

module.exports = router;
