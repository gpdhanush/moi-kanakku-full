require('dotenv').config();
const User = require('../models/user');
const logger = require('../config/logger');
const { validateUuid, validateUuidList, sendUuidError } = require('../helpers/idParams');
const { isBlockedStatus, isInactiveStatus, sendBlockedError, sendInactiveError } = require('../helpers/accountStatus');
const jwt = require('jsonwebtoken');
const {
    formatEmailFrom,
    normalizeEmailAddress,
    getEmailVerificationContent,
    queueEmail,
    sendEmail,
} = require('../services/emailService');
const { enqueueBulkIsolate } = require('../services/backgroundJobQueue');
const { queuePushNotification } = require('./notificationController');

const cache = require('../utils/cache');

const userError = 'User not found!';
const EMAIL_VERIFY_TYPE = 'email_verify';
const EMAIL_VERIFY_EXPIRES = process.env.EMAIL_VERIFY_EXPIRES || '24h';
const EMAIL_VERIFY_HOURS = Number(process.env.EMAIL_VERIFY_HOURS) || 24;

function clearAdminUserListCache() {
    cache.delByPrefix('admin:all-user-lists');
}

function getEmailVerifyLink(req, token) {
    const configured = (process.env.EMAIL_VERIFY_URL || '').trim().replace(/\/$/, '');
    const base = configured || (() => {
        const proto = String(req.get('x-forwarded-proto') || req.protocol || 'https')
            .split(',')[0]
            .trim();
        const host = String(req.get('x-forwarded-host') || req.get('host') || '')
            .split(',')[0]
            .trim();
        return `${proto}://${host}/apis/email/verify-email`;
    })();
    const separator = base.includes('?') ? '&' : '?';
    return `${base}${separator}token=${encodeURIComponent(token)}`;
}

/**
 * Build + send a verification-link email for a user record.
 * Throws Error with .status / .code for controller mapping.
 */
async function dispatchVerifyEmail(req, user) {
    if (!user) {
        const err = new Error(userError);
        err.status = 404;
        throw err;
    }
    if (Number(user.is_verified) === 1) {
        const err = new Error('This email is already verified.');
        err.status = 400;
        throw err;
    }

    const targetEmail = normalizeEmailAddress(user.email);
    if (!targetEmail) {
        const err = new Error('This user does not have an email address.');
        err.status = 400;
        throw err;
    }

    if (!process.env.JWT_SECRET) {
        logger.error('dispatchVerifyEmail: JWT_SECRET is not set');
        const err = new Error('Email verification is not configured.');
        err.status = 500;
        throw err;
    }

    const token = jwt.sign(
        {
            userId: String(user.id),
            email: targetEmail,
            type: EMAIL_VERIFY_TYPE,
        },
        process.env.JWT_SECRET,
        { expiresIn: EMAIL_VERIFY_EXPIRES }
    );
    const verifyLink = getEmailVerifyLink(req, token);
    const html = getEmailVerificationContent({
        name: user.full_name,
        verifyLink,
        expiresInHours: EMAIL_VERIFY_HOURS,
    });

    const result = await sendEmail({
        from: formatEmailFrom('Admin - Moi Kanakku Team'),
        to: targetEmail,
        subject: 'Moi Kanakku - Verify your email',
        text: `Verify your Moi Kanakku email by opening this link: ${verifyLink}`,
        html,
    });

    return {
        targetEmail,
        messageId: result?.messageId || null,
        response: result?.response || null,
    };
}

function renderVerifyEmailPage({ success, title, message }) {
    const headingColor = success ? '#166534' : '#991b1b';
    const badgeBg = success ? '#dcfce7' : '#fee2e2';
    return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="color-scheme" content="light">
  <meta name="supported-color-schemes" content="light">
  <title>${title}</title>

  <style>
    :root {
      --bg: #f7f7f3;
      --card: #ffffff;
      --surface: #f1efe7;
      --border: #e4e1d9;
      --text: #171717;
      --muted: #686868;
      --subtle: #8a8882;
      --button: #171717;
      --button-hover: #303030;
    }

    * { box-sizing: border-box; }

    body {
      margin: 0;
      padding: 0;
      background: var(--bg);
      font-family: Arial, Helvetica, sans-serif;
      color: var(--text);
    }

    table {
      border-spacing: 0;
    }

    .email-wrapper {
      width: 100%;
      padding: 40px 16px;
    }

    .email-card {
      width: 100%;
      max-width: 560px;
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: 22px;
      overflow: hidden;
      box-shadow: 0 8px 30px rgba(23, 23, 23, 0.06);
    }

    .brand-section {
      padding: 28px 30px;
      background: #ffffff;
      border-bottom: 1px solid var(--border);
      text-align: center;
    }

    .brand-mark {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      width: 46px;
      height: 46px;
      overflow: hidden;
      border-radius: 14px;
      background: #ffffff;
      box-shadow: 0 0 0 1px rgba(23, 23, 23, 0.05);
      vertical-align: middle;
    }

    .brand-mark img {
      display: block;
      width: 100%;
      height: 100%;
      object-fit: contain;
    }

    .brand-name {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      margin-left: 10px;
      vertical-align: middle;
      height: 46px;
    }

    .brand-name img {
      display: block;
      width: 174px;
      height: auto;
      object-fit: contain;
    }

    .content {
      padding: 32px 30px 30px;
    }

    .badge {
      display: inline-block;
      padding: 8px 13px;
      border-radius: 999px;
      background: ${badgeBg};
      color: ${headingColor};
      font-size: 12px;
      line-height: 16px;
      font-weight: 700;
    }

    .title {
      margin: 20px 0 12px;
      color: var(--text);
      font-size: 28px;
      line-height: 36px;
      font-weight: 700;
      letter-spacing: -0.5px;
    }

    .message {
      margin: 0;
      color: var(--muted);
      font-size: 16px;
      line-height: 26px;
    }

    .divider {
      height: 1px;
      background: var(--border);
      margin: 28px 0 24px;
    }

    .info-text {
      margin: 0;
      color: var(--subtle);
      font-size: 13px;
      line-height: 20px;
    }

    .button-wrapper {
      margin-top: 28px;
      text-align: center;
    }

    .close-button {
      display: inline-block;
      border: none;
      padding: 13px 28px;
      background: var(--button);
      color: #ffffff !important;
      border-radius: 10px;
      font-size: 14px;
      font-weight: 700;
      line-height: 20px;
      letter-spacing: 0.01em;
      cursor: pointer;
      text-decoration: none;
      transition: background 0.2s ease;
    }

    .close-button:hover {
      background: var(--button-hover);
    }

    .footer {
      padding: 22px 30px 26px;
      background: var(--surface);
      text-align: center;
    }

    .footer-text {
      margin: 0;
      color: var(--muted);
      font-size: 12px;
      line-height: 19px;
    }

    .footer-brand {
      margin: 5px 0 0;
      color: var(--text);
      font-size: 12px;
      font-weight: 700;
    }

    @media only screen and (max-width: 600px) {
      .email-wrapper {
        padding: 24px 12px;
      }

      .email-card {
        border-radius: 16px;
      }

      .brand-section {
        padding: 22px;
      }

      .brand-name img {
        width: 150px;
      }

      .content {
        padding: 26px 22px;
      }

      .footer {
        padding: 20px 22px 24px;
      }

      .title {
        font-size: 24px;
        line-height: 32px;
      }

      .message {
        font-size: 15px;
        line-height: 24px;
      }

      .close-button {
        display: block;
        width: auto;
        padding: 13px 20px;
      }
    }
  </style>
</head>

<body>
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
    <tr>
      <td align="center">
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" class="email-wrapper">
          <tr>
            <td align="center">
              <table role="presentation" width="100%" cellpadding="0" cellspacing="0" class="email-card">
                <tr>
                  <td class="brand-section">
                    <span class="brand-mark">
                      <img src="/assets/app-logo-light.png" alt="Moi Kanakku logo" />
                    </span>
                    <span class="brand-name">
                      <img src="/assets/label-dark.png" alt="Moi Kanakku" />
                    </span>
                  </td>
                </tr>

                <tr>
                  <td class="content">
                    <div class="badge">${title}</div>
                    <h1 class="title">${title}</h1>
                    <p class="message">${message}</p>

                    <div class="divider"></div>

                    <p class="info-text">
                      This message was sent automatically by Moi Kanakku.
                      You can safely close this page after viewing this message.
                    </p>

                    <div class="button-wrapper">
                      <button
                        type="button"
                        class="close-button"
                        onclick="try { window.close(); } catch (e) {} ; setTimeout(function(){ if (window.opener) { try { window.close(); } catch (e) {} } else { alert('You can close this browser tab manually.'); } }, 150); return false;"
                      >
                        Close tab
                      </button>
                    </div>
                  </td>
                </tr>

                <tr>
                  <td class="footer">
                    <p class="footer-text">Thank you for using Moi Kanakku.</p>
                    <p class="footer-brand">© Moi Kanakku</p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;
}

function sendVerifyEmailPage(res, { success, title, message, status = 200 }) {
    res.status(status);
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.setHeader('Content-Security-Policy', "default-src 'none'; img-src 'self' data:; style-src 'unsafe-inline'; script-src 'unsafe-inline';");
    return res.send(renderVerifyEmailPage({ success, title, message }));
}

exports.controller = {
    /**
     * Unified OTP verification endpoint. Body: { email, id, otp, type }
     * type: 'forgot' | 'verification' | 'restore' (default: 'forgot' for backward compatibility)
     */
    verifyOtp: async (req, res) => {
        const { emailId, email, id, otp, type } = req.body;
        
        try {
            // For backward compatibility, use emailId if provided
            let user = null;
            let verifyType = type || 'forgot';
            
            // For restore flow, we need to find deleted users
            const useIncludingDeleted = verifyType === 'restore';
            
            // Find user by emailId (legacy), email, or id
            if (emailId) {
                user = useIncludingDeleted 
                    ? await User.findByEmailIncludingDeleted(emailId)
                    : await User.findByEmail(emailId);
            } else if (email) {
                user = useIncludingDeleted 
                    ? await User.findByEmailIncludingDeleted(email)
                    : await User.findByEmail(email);
            } else if (id) {
                const idCheck = validateUuid(id, 'id');
                if (!idCheck.ok) return sendUuidError(res, idCheck.message);
                user = useIncludingDeleted 
                    ? await User.findByIdIncludingDeleted(id)
                    : await User.findById(id);
            }
            
            if (!user) {
                return res.status(404).json({ responseType: "F", responseValue: { message: 'Invalid email ID!' } });
            }

            if (verifyType === 'forgot' && isInactiveStatus(user.status)) {
                return sendInactiveError(res);
            }
            
            if (!otp) {
                return res.status(400).json({ responseType: "F", responseValue: { message: 'OTP is required' } });
            }
            
            // Route to appropriate verification method
            let result;
            if (verifyType === 'forgot') {
                result = await User.verifyForgotOTP(user.id, otp);
            } else if (verifyType === 'verification' || verifyType === 'verify') {
                result = await User.verifyEmailOTP(user.id, otp);
            } else if (verifyType === 'restore') {
                result = await User.verifyRestoreOTP(user.id, otp);
            } else {
                return res.status(400).json({ responseType: "F", responseValue: { message: 'Unknown OTP type' } });
            }
            
            if (!result.success) {
                return res.status(400).json({ responseType: "F", responseValue: { message: result.message } });
            }
            
            return res.status(200).json({ responseType: "S", responseValue: { message: result.message } });
        } catch (error) {
            logger.error('verifyOtp failed', error);
            return res.status(500).json({ responseType: "F", responseValue: { message: error.toString() } });
        }
    },

    /**
     * Unified sendEmail endpoint. Body: { type, email, id, subject, content }
     * type: 'restore' | 'verification' | 'forgot' | 'custom'
     */
    sendEmail: async (req, res) => {
        const { type, email, id, subject, content } = req.body;

        try {
            if (!type) {
                return res.status(400).json({ responseType: "F", responseValue: { message: 'type is required' } });
            }

            const expireTime = new Date(Date.now() + 10 * 60 * 1000);

            // helper: queue push notification if requested (non-blocking)
            const queueNotifIfRequested = (userId, title, body, token, notifType) => {
                try {
                    if (req.body.sendNotification) {
                        const nUserId = req.body.notificationUserId || userId;
                        const nToken = req.body.notificationToken || token;
                        const nTitle = req.body.notificationTitle || title;
                        const nBody = req.body.notificationBody || body;
                        const nType = req.body.notificationType || notifType;
                        if (nUserId && nToken && nTitle && nBody) {
                            queuePushNotification({
                                userId: nUserId,
                                title: nTitle,
                                body: nBody,
                                token: nToken,
                                type: nType,
                            });
                        } else {
                            logger.warn('sendEmail: sendNotification requested but missing notification payload');
                        }
                    }
                } catch (notifErr) {
                    logger.error('Error queueing push notification from sendEmail:', notifErr);
                }
            };

            // Handler for restore: send RESTORE OTP to deleted account
            if (type === 'restore') {
                const targetEmail = normalizeEmailAddress(email);
                if (!targetEmail) return res.status(400).json({ responseType: "F", responseValue: { message: 'email is required for restore' } });
                const user = await User.findByEmailIncludingDeleted(targetEmail);
                if (!user) return res.status(404).json({ responseType: "F", responseValue: { message: 'Invalid email ID!' } });
                if (!user.is_deleted) return res.status(400).json({ responseType: "F", responseValue: { message: 'This account is not deleted.' } });

                const otpData = await User.createRestoreOTP(user.id);
                const emailContent = `<!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"></head><body style="margin:0;padding:0;font-family:Arial,Helvetica,sans-serif;background-color:#f5f7fb;"><table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="padding:30px 10px;"><tr><td align="center"><table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:620px;background:#ffffff;border:1px solid #eaeaea;border-radius:8px;overflow:hidden;"><tr><td style="background:#2f3490;color:#ffffff;text-align:center;padding:20px;"><h2 style="margin:0;font-size:22px;">🔁 Account Restore OTP</h2></td></tr><tr><td style="padding:30px;color:#333333;"><p style="margin:0 0 15px 0;font-size:16px;">Hi <strong>${user.full_name || user.um_full_name}</strong>,</p><p style="margin:0 0 20px 0;font-size:15px;color:#555;">Use the OTP below to verify ownership and restore your account.</p><div style="text-align:center;margin:30px 0;"><span style="display:inline-block;padding:16px 26px;background:#f3f4ff;border-radius:8px;font-size:34px;letter-spacing:8px;font-family:monospace;font-weight:700;color:#2f3490;">${otpData.otp}</span></div><p style="text-align:center;font-size:14px;color:#666;margin:0;">This OTP will expire in <strong>10 minutes</strong>.</p><p style="margin-top:20px;font-size:14px;color:#777;">If you did not request this account restore, please ignore this email.</p></td></tr><tr><td style="border-top:1px solid #f1f1f1;padding:20px;font-size:14px;color:#666;">Regards,<br><strong style="color:#2f3490;">Moi Kanakku Team</strong></td></tr></table><p style="max-width:620px;margin:20px auto 0;text-align:center;font-size:12px;color:#9ca3af;">© 2026 Moi Kanakku. All rights reserved.</p></td></tr></table></body></html>`;

                const jobId = queueEmail({
                    from: formatEmailFrom('Admin - Moi Kanakku Team'),
                    to: targetEmail,
                    subject: subject || 'Moi Kanakku - Account Restore OTP',
                    html: emailContent,
                }, `restore-otp:${targetEmail}`);
                queueNotifIfRequested(user.id, 'Account restored', 'Your account restore OTP was sent', user.notification_token, 'account');
                return res.status(200).json({
                    responseType: "S",
                    responseValue: {
                        message: 'OTP sent for restore',
                        expires_in_minutes: 10,
                        queued: true,
                        jobId,
                    },
                });
            }

            // Handler for verification: send VERIFY OTP
            if (type === 'verification' || type === 'verify') {
                let user = null;
                if (id) {
                    const idCheck = validateUuid(id, 'id');
                    if (!idCheck.ok) return sendUuidError(res, idCheck.message);
                    user = await User.findById(id);
                } else if (email) user = await User.findByEmail(normalizeEmailAddress(email));
                if (!user) return res.status(404).json({ responseType: "F", responseValue: { message: userError } });
                if (user.is_verified) return res.status(400).json({ responseType: "F", responseValue: { message: 'This email is already verified!' } });

                const otpData = await User.createVerificationOTP(user.id);
                otpData.expireTime = expireTime.toLocaleString("en-US", {
                  hour: "2-digit",
                  minute: "2-digit",
                  hour12: true,
                });
                const emailContent = `<!doctype html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head><body style="margin:0;padding:0;background-color:#f5f7fb;font-family:Arial,Helvetica,sans-serif;"><table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="padding:30px 10px;"><tr><td align="center"><table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:620px;background:#ffffff;border:1px solid #e5e7eb;border-radius:10px;overflow:hidden;"><tr><td style="background:#2f3490;padding:22px;text-align:center;color:#ffffff;"><h2 style="margin:0;font-size:22px;">🔐 Email Verification</h2></td></tr><tr><td style="padding:30px 28px;color:#333333;"><p style="margin:0 0 18px 0;font-size:16px;">Hi <strong>${user.full_name}</strong>,</p><p style="margin:0 0 20px 0;font-size:15px;color:#555;">Use the following OTP to verify your email address.</p><div style="text-align:center;margin:30px 0;"><span style="display:inline-block;padding:16px 26px;background:#f3f4ff;border-radius:8px;font-size:34px;letter-spacing:10px;font-family:monospace;font-weight:700;color:#2f3490;">${otpData.otp}</span></div><p style="text-align:center;font-size:14px;color:#666;margin:0;">This OTP will expire in <strong>10 minutes</strong></p><p style="text-align:center;font-size:13px;color:#999;margin-top:6px;">Expires at: <strong>${otpData.expireTime}</strong></p></td></tr><tr><td style="border-top:1px solid #f1f1f1;padding:20px 28px;font-size:14px;color:#666;">Regards,<br><strong style="color:#2f3490;">Moi Kanakku Team</strong></td></tr></table></td></tr></table></body></html>`;

                const jobId = queueEmail({
                    from: formatEmailFrom('Admin - Moi Kanakku Team'),
                    to: user.email,
                    subject: subject || 'Moi Kanakku - Email Verification OTP',
                    html: emailContent,
                }, `verify-otp:${user.email}`);
                queueNotifIfRequested(user.id, 'Verify email', 'Verification OTP sent to your email', user.notification_token, 'account');
                return res.status(200).json({
                    responseType: "S",
                    responseValue: {
                        message: 'Verification OTP sent',
                        expires_in_minutes: 10,
                        queued: true,
                        jobId,
                    },
                });
            }

            // Handler for forgot password: use unified user_otps table
            if (type === 'forgot') {
                const targetEmail = normalizeEmailAddress(email);
                if (!targetEmail) return res.status(400).json({ responseType: "F", responseValue: { message: 'email is required for forgot' } });
                const user = await User.findByEmail(targetEmail);
                if (!user) return res.status(404).json({ responseType: "F", responseValue: { message: 'Invalid email ID!' } });
                if (isInactiveStatus(user.status)) {
                    return sendInactiveError(res);
                }
                if (isBlockedStatus(user.status)) {
                    return sendBlockedError(res);
                }

                // Create forgot OTP using unified method
                const otpData = await User.createForgotOTP(user.id);

                const emailContent = `<!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head><body style="margin:0;padding:0;background-color:#f5f7fb;font-family:Arial,Helvetica,sans-serif;"><table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="padding:30px 10px;"><tr><td align="center"><table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:620px;background:#ffffff;border:1px solid #e5e7eb;border-radius:10px;overflow:hidden;box-shadow:0 6px 18px rgba(0,0,0,0.06);"><tr><td style="background:#2f3490;padding:22px;text-align:center;color:#ffffff;"><h2 style="margin:0;font-size:22px;font-weight:600;">Forgot Password - OTP</h2></td></tr><tr><td style="padding:30px 28px;color:#333333;"><p style="margin:0 0 18px 0;font-size:16px;">Hi <strong>${user.full_name || user.um_full_name}</strong>,</p><p style="margin:0 0 20px 0;font-size:15px;color:#555;">Use the following OTP to reset your password.</p><div style="text-align:center;margin:30px 0;"><span style="display:inline-block;padding:16px 28px;background:#f3f4ff;border-radius:8px;font-size:34px;letter-spacing:10px;font-family:monospace;font-weight:700;color:#2f3490;">${otpData.otp}</span></div><p style="text-align:center;font-size:14px;color:#666;margin:0;">This OTP will expire in <strong>10 minutes</strong>.</p><p style="margin-top:20px;font-size:14px;color:#777;">If you did not request a password reset, please ignore this email.</p></td></tr><tr><td style="border-top:1px solid #f1f1f1;padding:20px 28px;font-size:14px;color:#666;">Regards,<br><strong style="color:#2f3490;">Moi Kanakku Team</strong></td></tr></table><p style="max-width:620px;margin:20px auto 0;text-align:center;font-size:12px;color:#9ca3af;">© 2026 Moi Kanakku. All rights reserved.</p></td></tr></table></body></html>`;

                const jobId = queueEmail({
                    from: formatEmailFrom('Admin - Moi Kanakku Team'),
                    to: targetEmail,
                    subject: subject || 'Moi Kanakku - Password Reset OTP',
                    html: emailContent,
                }, `forgot-otp:${targetEmail}`);
                queueNotifIfRequested(user.id, 'Forgot password', 'Forgot password OTP sent to your email', user.notification_token, 'account');
                const responseValue = {
                    message: 'Forgot OTP sent',
                    expires_in_minutes: 10,
                    queued: true,
                    jobId,
                };
                if (process.env.EMAIL_DEBUG === 'true') {
                    responseValue.sent_to = targetEmail;
                }
                return res.status(200).json({ responseType: "S", responseValue });
            }

            // Fallback: custom/raw send using provided subject/content
            if (type === 'custom' || type === 'raw') {
                if (!email || !content) return res.status(400).json({ responseType: "F", responseValue: { message: 'email and content required for custom send' } });
                const jobId = queueEmail({
                    from: formatEmailFrom('Admin - Moi Kanakku'),
                    to: email,
                    subject: subject || 'Moi Kanakku',
                    html: content,
                }, `custom:${email}`);
                queueNotifIfRequested(null, subject || 'Moi Kanakku', subject || 'Email sent', null, 'general');
                return res.status(200).json({
                    responseType: "S",
                    responseValue: {
                        message: 'Email queued successfully.',
                        queued: true,
                        jobId,
                    },
                });
            }

            return res.status(400).json({ responseType: "F", responseValue: { message: 'Unknown type' } });
        } catch (error) {
            logger.error('sendEmail failed', error);
            return res.status(500).json({ responseType: "F", responseValue: { message: error.toString() } });
        }
    },

    /**
     * Send bulk emails to multiple users
     * Body: { userIds: [], subject, body, type? }
     * type: 'notification' | 'announcement' | 'custom' (default: 'custom')
     */
    sendBulkEmails: async (req, res) => {
        try {
            const { userIds, subject, body, type } = req.body;

            // Validate input
            if (!userIds || !Array.isArray(userIds) || userIds.length === 0) {
                return res.status(400).json({
                    responseType: "F",
                    responseValue: { message: 'An array of user IDs is required.' }
                });
            }

            const listCheck = validateUuidList(userIds, 'userIds');
            if (!listCheck.ok) return sendUuidError(res, listCheck.message);

            if (!subject || !body) {
                return res.status(400).json({
                    responseType: "F",
                    responseValue: { message: 'Subject and body are required.' }
                });
            }

            const db = require('../config/database');
            const { toBinaryUUID, fromBinaryUUID } = require('../helpers/uuid');

            // Get users and their emails
            const userIdsFormatted = userIds.map(id => toBinaryUUID(id));
            const placeholders = userIdsFormatted.map(() => '?').join(',');
            
            const [users] = await db.query(
                `SELECT u.id, u.email, u.full_name
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

            const emailUsers = users.map((user) => ({
                id: fromBinaryUUID(user.id),
                email: user.email || null,
                full_name: user.full_name || null,
            }));

            const { jobId, mode } = enqueueBulkIsolate('bulk_email', {
                users: emailUsers,
                subject,
                body,
                type: type || 'custom',
            });

            return res.status(200).json({
                responseType: "S",
                responseValue: {
                    message: `Emails queued for ${users.length} users. Delivery continues in background.`,
                    queued: true,
                    jobId,
                    mode,
                    totalRequested: userIds.length,
                    usersFound: users.length,
                }
            });

        } catch (error) {
            logger.error('Error in sendBulkEmails:', error);
            return res.status(500).json({
                responseType: "F",
                responseValue: { message: error.toString() }
            });
        }
    },

    /**
     * Mobile (logged-in): send verification email to the current user.
     */
    sendUserVerifyEmail: async (req, res) => {
        const userId = req.user?.userId || req.user?.id || req.body?.userId;
        const idCheck = validateUuid(userId, 'userId');
        if (!idCheck.ok) return sendUuidError(res, idCheck.message);

        try {
            const user = await User.findById(userId);
            const sent = await dispatchVerifyEmail(req, user);
            logger.info(
                `Verification email sent to ${sent.targetEmail} for user ${userId}: ${sent.response || 'ok'}`,
            );
            return res.status(200).json({
                responseType: 'S',
                responseValue: {
                    message: `Verification email sent to ${sent.targetEmail}.`,
                    sent: true,
                    sent_to: sent.targetEmail,
                    messageId: sent.messageId,
                    expires_in_hours: EMAIL_VERIFY_HOURS,
                },
            });
        } catch (error) {
            const status = error.status || (String(error.message || '').includes('SMTP') ? 502 : 500);
            if (status >= 500) {
                logger.error('sendUserVerifyEmail failed', error);
            }
            return res.status(status).json({
                responseType: 'F',
                responseValue: { message: error.message || error.toString() },
            });
        }
    },

    /**
     * Admin: send a verification email with a clickable token link.
     * Body: { userId }
     */
    sendAdminVerifyEmail: async (req, res) => {
        const userId = req.body?.userId || req.body?.id || req.params?.id;
        const idCheck = validateUuid(userId, 'userId');
        if (!idCheck.ok) return sendUuidError(res, idCheck.message);

        try {
            const user = await User.findById(userId);
            const sent = await dispatchVerifyEmail(req, user);
            logger.info(
                `Verification email sent to ${sent.targetEmail} for user ${userId}: ${sent.response || 'ok'}`,
            );

            return res.status(200).json({
                responseType: 'S',
                responseValue: {
                    message: `Verification email sent to ${sent.targetEmail}.`,
                    queued: false,
                    sent: true,
                    sent_to: sent.targetEmail,
                    messageId: sent.messageId,
                    expires_in_hours: EMAIL_VERIFY_HOURS,
                },
            });
        } catch (error) {
            const status = error.status || 500;
            if (status >= 500) {
                logger.error('sendAdminVerifyEmail failed', error);
            }
            const reason = String(error?.message || error || 'Unable to send verification email');
            return res.status(status === 400 || status === 404 ? status : 502).json({
                responseType: 'F',
                responseValue: { message: reason },
            });
        }
    },

    /**
     * Public: verify email from the link in the verification email.
     * Query: ?token=
     */
    verifyEmailByToken: async (req, res) => {
        const token = String(req.query?.token || req.body?.token || '').trim();
        if (!token) {
            return sendVerifyEmailPage(res, {
                success: false,
                status: 400,
                title: 'Invalid link',
                message: 'This verification link is missing a token. Please request a new verification email.',
            });
        }

        try {
            const decoded = jwt.verify(token, process.env.JWT_SECRET);
            if (!decoded || decoded.type !== EMAIL_VERIFY_TYPE || !decoded.userId) {
                return sendVerifyEmailPage(res, {
                    success: false,
                    status: 400,
                    title: 'Invalid link',
                    message: 'This verification link is not valid. Please request a new verification email.',
                });
            }

            const idCheck = validateUuid(decoded.userId, 'userId');
            if (!idCheck.ok) {
                return sendVerifyEmailPage(res, {
                    success: false,
                    status: 400,
                    title: 'Invalid link',
                    message: 'This verification link is not valid. Please request a new verification email.',
                });
            }

            const user = await User.findById(decoded.userId);
            if (!user) {
                return sendVerifyEmailPage(res, {
                    success: false,
                    status: 404,
                    title: 'Account not found',
                    message: 'We could not find this account. The user may have been removed.',
                });
            }

            const currentEmail = normalizeEmailAddress(user.email);
            if (decoded.email && currentEmail !== String(decoded.email).toLowerCase()) {
                return sendVerifyEmailPage(res, {
                    success: false,
                    status: 400,
                    title: 'Email changed',
                    message: 'This link was issued for a previous email address. Please request a new verification email.',
                });
            }

            if (Number(user.is_verified) === 1) {
                return sendVerifyEmailPage(res, {
                    success: true,
                    title: 'Already verified',
                    message: 'This email address is already verified. You can close this page.',
                });
            }

            await User.markEmailVerified(user.id);
            clearAdminUserListCache();

            return sendVerifyEmailPage(res, {
                success: true,
                title: 'Email verified',
                message: 'Your email address was verified successfully. You can close this page and return to the app.',
            });
        } catch (error) {
            if (error && (error.name === 'TokenExpiredError' || error.name === 'JsonWebTokenError')) {
                return sendVerifyEmailPage(res, {
                    success: false,
                    status: 400,
                    title: error.name === 'TokenExpiredError' ? 'Link expired' : 'Invalid link',
                    message: error.name === 'TokenExpiredError'
                        ? 'This verification link has expired. Please ask an administrator to send a new one.'
                        : 'This verification link is not valid. Please request a new verification email.',
                });
            }
            logger.error('verifyEmailByToken failed', error);
            return sendVerifyEmailPage(res, {
                success: false,
                status: 500,
                title: 'Something went wrong',
                message: 'We could not verify this email right now. Please try again later.',
            });
        }
    },
}
