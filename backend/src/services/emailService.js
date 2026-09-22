require('dotenv').config();
const path = require('path');
const nodemailer = require('nodemailer');
const logger = require('../config/logger');

function escapeHtml(text = '') {
    return String(text ?? '').replace(/[&<>"']/g, (m) => ({
        "&": "&amp;",
        "<": "&lt;",
        ">": "&gt;",
        '"': "&quot;",
        "'": "&#039;"
    }[m]));
}

function htmlToText(html = '') {
    return String(html)
        .replace(/<style[\s\S]*?<\/style>/gi, '')
        .replace(/<script[\s\S]*?<\/script>/gi, '')
        .replace(/<br\s*\/?>/gi, '\n')
        .replace(/<\/(p|div|h[1-6]|li|tr)>/gi, '\n')
        .replace(/<[^>]+>/g, '')
        .replace(/&nbsp;/gi, ' ')
        .replace(/&amp;/gi, '&')
        .replace(/&lt;/gi, '<')
        .replace(/&gt;/gi, '>')
        .replace(/&quot;/gi, '"')
        .replace(/&#039;/gi, "'")
        .replace(/[ \t]+\n/g, '\n')
        .replace(/\n{3,}/g, '\n\n')
        .trim();
}

/**
 * Extract display name and optional reply-to from EMAIL_FROM.
 */
function parseEmailFromEnv() {
    const fromEnv = (process.env.EMAIL_FROM || '').trim();
    if (!fromEnv) return { displayName: null, replyTo: null };

    const formatted = fromEnv.match(/^"?([^"<]*)"?\s*<([^>]+)>$/);
    if (formatted) {
        return {
            displayName: formatted[1].trim() || null,
            replyTo: formatted[2].trim(),
        };
    }
    if (fromEnv.includes('@')) {
        return { displayName: null, replyTo: fromEnv };
    }
    return { displayName: fromEnv, replyTo: null };
}

/**
 * Build a valid From address using the authenticated SMTP mailbox.
 * Using EMAIL_USER as From avoids SPF/DMARC rejection when EMAIL_FROM is another domain.
 */
function formatEmailFrom(displayName = 'Moi Kanakku') {
    const smtpUser = (process.env.EMAIL_USER || '').trim();
    const { displayName: envName } = parseEmailFromEnv();
    const name = envName || displayName;
    return `"${name}" <${smtpUser}>`;
}

function getReplyToEmail() {
    const smtpUser = (process.env.EMAIL_USER || '').trim();
    const { replyTo } = parseEmailFromEnv();
    if (!replyTo || replyTo.toLowerCase() === smtpUser.toLowerCase()) {
        return undefined;
    }
    // Cross-domain Reply-To (e.g. noreply@moikanakku.com while sending as gp@prasowlabs.in)
    // often causes Gmail/Outlook to drop or spam-filter transactional mail.
    const smtpDomain = smtpUser.split('@')[1]?.toLowerCase();
    const replyDomain = replyTo.split('@')[1]?.toLowerCase();
    if (!smtpDomain || !replyDomain || smtpDomain !== replyDomain) {
        return undefined;
    }
    return replyTo;
}

function normalizeEmailAddress(email) {
    return String(email || '').trim().toLowerCase();
}

function buildMailOptions({ to, subject, html, from, text }) {
    const mailOptions = {
        from: from || formatEmailFrom('Moi Kanakku'),
        to,
        subject,
        html,
        text: text || htmlToText(html),
        attachments: [
            {
                filename: 'app-logo-light.png',
                path: path.join(__dirname, '../../assets/app-logo-light.png'),
                cid: 'moi-app-logo',
            },
            {
                filename: 'label-dark.png',
                path: path.join(__dirname, '../../assets/label-dark.png'),
                cid: 'moi-label-dark',
            },
        ],
    };
    const replyTo = getReplyToEmail();
    if (replyTo) mailOptions.replyTo = replyTo;
    return mailOptions;
}

function createEmailTransporter(overrides = {}) {
    const port = Number(process.env.EMAIL_PORT) || 465;
    const connectionTimeout = Number(process.env.EMAIL_CONN_TIMEOUT) || 15000;
    const greetingTimeout = Number(process.env.EMAIL_GREETING_TIMEOUT) || 15000;
    const socketTimeout = Number(process.env.EMAIL_SOCKET_TIMEOUT) || 20000;
    const secureEnv = String(process.env.EMAIL_SECURE || '').toLowerCase();
    const secure =
        secureEnv === 'true' || secureEnv === '1'
            ? true
            : secureEnv === 'false' || secureEnv === '0'
              ? false
              : port === 465;
    const rejectUnauthorized = ['true', '1'].includes(
        String(process.env.EMAIL_TLS_REJECT || '').toLowerCase()
    );
    const debug =
        process.env.EMAIL_DEBUG === 'true' || process.env.EMAIL_DEBUG === '1';
    const enableLogger =
        process.env.EMAIL_LOGGER === 'true' || process.env.EMAIL_LOGGER === '1';

    return nodemailer.createTransport({
        host: process.env.EMAIL_HOST,
        port,
        secure,
        auth: {
            user: process.env.EMAIL_USER,
            pass: process.env.EMAIL_PASS,
        },
        connectionTimeout,
        greetingTimeout,
        socketTimeout,
        tls: {
            // Most cPanel SMTP hosts use shared/self-signed certs.
            rejectUnauthorized,
            servername: process.env.EMAIL_HOST,
        },
        logger: enableLogger,
        debug,
        ...overrides,
    });
}

let sharedTransporter = null;

function getSharedTransporter() {
    if (!sharedTransporter) {
        sharedTransporter = createEmailTransporter();
    }
    return sharedTransporter;
}

/**
 * Verify SMTP credentials at startup (logs only; does not block server).
 */
async function verifyEmailTransport() {
    if (!process.env.EMAIL_HOST || !process.env.EMAIL_USER || !process.env.EMAIL_PASS) {
        logger.warn('Email transport not configured: EMAIL_HOST, EMAIL_USER, or EMAIL_PASS is missing');
        return false;
    }
    const transporter = createEmailTransporter({ logger: false, debug: false });
    try {
        await transporter.verify();
        logger.info(
            `Email transport verified successfully (${process.env.EMAIL_HOST}:${process.env.EMAIL_PORT || 465}, secure=${String(
                process.env.EMAIL_SECURE || (Number(process.env.EMAIL_PORT) || 465) === 465
            )})`
        );
        return true;
    } catch (err) {
        logger.error('Email transport verification failed:', err.message || err);
        return false;
    } finally {
        transporter.close();
    }
}

verifyEmailTransport();

/**
 * Send email when user submits feedback (confirmation to user)
 */
async function getLegacyFeedbackConfirmationEmail(toEmail, userName) {
    if (!toEmail) return;
    try {
        const html = `<!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Feedback Submitted</title></head><body style="margin:0;padding:0;background:#f3f4f6;font-family:Arial,Helvetica,sans-serif;"><table width="100%" cellpadding="0" cellspacing="0" style="padding:40px 10px;"><tr><td align="center"><table width="100%" cellpadding="0" cellspacing="0" style="max-width:600px;background:#ffffff;border-radius:8px;border:1px solid #e5e7eb;box-shadow:0 4px 10px rgba(0,0,0,0.05);"><tr><td style="border-bottom:1px solid #e5e7eb;padding:20px 24px;"><h1 style="margin:0;font-size:20px;font-weight:600;color:#1e3a8a;"> Moi Kanakku </h1></td></tr><tr><td style="padding:24px;color:#374151;line-height:1.6;font-size:15px;"><p style="margin:0 0 15px;"> Hi <strong style="color:#111827;">${userName || "User"}</strong>, </p><p style="margin:0 0 15px;"> Your feedback has been successfully submitted. We will review it shortly. </p><p style="margin:0 0 15px;"> 🙏 <strong>Thanks for using the Moi Kanakku app!</strong><br> Your feedback helps us improve the app for everyone. </p><div style="background:#eff6ff;border:1px solid #dbeafe;border-radius:6px;padding:16px;margin-top:20px;"><p style="margin:0 0 8px;font-weight:600;color:#1e3a8a;"> 🎉 Help us grow! </p><p style="margin:0 0 8px;font-size:14px;color:#374151;"> If you like Moi Kanakku, please share it with your friends and family. Your support helps more people manage their accounts easily. </p><p style="margin:0;font-size:14px;color:#374151;"> Stay tuned for upcoming features and promotions in the app! </p></div><p style="margin-top:25px;font-size:14px;color:#4b5563;"> Regards,<br><strong style="color:#1e3a8a;">Moi Kanakku Team</strong></p></td></tr><tr><td style="border-top:1px solid #e5e7eb;text-align:center;padding:15px;font-size:12px;color:#6b7280;"> © 2026 Moi Kanakku. All rights reserved. </td></tr></table></td></tr></table></body></html>`;
        await sendEmail({
            from: formatEmailFrom('Admin - Moi Kanakku Team'),
            to: toEmail,
            subject: 'Feedback Submission - Moi Kanakku',
            html,
        });
    } catch (err) {
        logger.error('Error sending feedback confirmation email', err);
    }
}

/**
 * Send email when admin replies to feedback (reply content to user)
 */
async function getLegacyFeedbackReplyEmail(toEmail, userName, replyText) {
    if (!toEmail) return;
    try {
        const html = `<!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"></head><body style="margin:0;padding:0;background:#f5f7fb;font-family:Helvetica,Arial,sans-serif;"><table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="padding:30px 10px;"><tr><td align="center"><table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:620px;background:#ffffff;border:1px solid #e5e7eb;border-radius:8px;"><tr><td style="padding:20px;border-bottom:1px solid #eee;"><a href="#" style="font-size:20px;color:#00466a;text-decoration:none;font-weight:600;"> Moi Kanakku </a></td></tr><tr><td style="padding:25px;color:#333;line-height:1.7;"><p style="font-size:16px;margin:0 0 15px 0;"> Hi <strong style="color:#2c2c54;">${userName || "User"}</strong>, </p><p style="margin:0 0 15px 0;"> A response has been provided for your feedback. </p><div style="background:#f5f5f5;padding:15px;border-radius:6px;margin:15px 0;font-size:14px;"> ${escapeHtml(replyText).replace(/\n/g, "<br/>")} </div><p style="margin-top:15px;"> 🙏 <strong>Thanks for using Moi Kanakku!</strong> Your feedback helps us improve the app experience. </p><div style="background:#eef4ff;border:1px solid #dbe7ff;padding:15px;border-radius:6px;margin-top:20px;font-size:14px;"><strong>🚀 Share Moi Kanakku</strong><br> If you like our app, please share it with your friends and family. More features and promotions are coming soon! </div><p style="margin-top:25px;font-size:14px;color:#666;"> Regards,<br><strong>Moi Kanakku Team</strong></p></td></tr><tr><td style="border-top:1px solid #eee;padding:15px;text-align:center;font-size:12px;color:#999;"> © 2026 Moi Kanakku. All rights reserved. </td></tr></table></td></tr></table></body></html>`;
        await sendEmail({
            from: formatEmailFrom('Admin - Moi Kanakku Team'),
            to: toEmail,
            subject: 'Response to your feedback - Moi Kanakku',
            html,
        });
    } catch (err) {
        logger.error('Error sending feedback reply email', err);
    }
}

/**
 * Generic sendEmail function for sending emails with custom subject, content
 * @param {Object} options - { to, subject, html, from?, text? }
 */
async function sendEmail(options) {
    const { to, subject, html, from, text } = options;
    
    if (!to || !subject || !html) {
        logger.error('sendEmail: Missing required parameters (to, subject, html)');
        throw new Error('to, subject, html are required');
    }

    const mailOptions = buildMailOptions({
        from: from || formatEmailFrom('Moi Kanakku'),
        to,
        subject,
        html,
        text,
    });

    const attemptSend = async (transporter) => transporter.sendMail(mailOptions);

    try {
        const result = await attemptSend(getSharedTransporter());
        logger.info(`Email sent successfully to ${to} from ${mailOptions.from}: ${result.response}`);
        return result;
    } catch (err) {
        const message = String(err?.message || err || '');
        const shouldRetry =
            /timeout|timed out|econnreset|econnrefused|socket|connection|greeting/i.test(message);
        if (!shouldRetry) {
            logger.error(`Error sending email to ${to}:`, err);
            throw err;
        }

        logger.warn(`Email send to ${to} failed (${message}); retrying with a fresh SMTP connection`);
        try {
            if (sharedTransporter) {
                try {
                    sharedTransporter.close();
                } catch (_) {
                    /* ignore */
                }
                sharedTransporter = null;
            }
            const fresh = createEmailTransporter({ logger: false, debug: false });
            sharedTransporter = fresh;
            const result = await attemptSend(fresh);
            logger.info(`Email sent successfully to ${to} from ${mailOptions.from}: ${result.response}`);
            return result;
        } catch (retryErr) {
            logger.error(`Error sending email to ${to} after retry:`, retryErr);
            throw retryErr;
        }
    }
}

/**
 * Queue email in background isolate queue — does not block the HTTP request.
 * @param {Object} options - same as sendEmail
 * @param {string} [label]
 * @returns {string} jobId
 */
function queueEmail(options, label) {
    const { enqueueEmail } = require('./backgroundJobQueue');
    const to = options?.to || 'unknown';
    return enqueueEmail(label || `email:${to}`, async () => {
        await sendEmail(options);
    });
}

/**
 * Queue feedback confirmation email (non-blocking).
 */
function queueFeedbackConfirmationEmail(toEmail, userName) {
    if (!toEmail) return null;
    const { enqueueEmail } = require('./backgroundJobQueue');
    return enqueueEmail(`feedback-confirm:${toEmail}`, async () => {
        await sendFeedbackConfirmationEmail(toEmail, userName);
    });
}

/**
 * Queue feedback reply email (non-blocking).
 */
function queueFeedbackReplyEmail(toEmail, userName, replyText) {
    if (!toEmail) return null;
    const { enqueueEmail } = require('./backgroundJobQueue');
    return enqueueEmail(`feedback-reply:${toEmail}`, async () => {
        await sendFeedbackReplyEmail(toEmail, userName, replyText);
    });
}

/**
 * Generate welcome email HTML for new user registration
 * @param {string} name - User's name
 * @returns {string} HTML email content
 */
function getLegacyWelcomeEmailContent(name) {
    return `<!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"></head><body style="margin:0;padding:0;background:#f5f7fb;font-family:Helvetica,Arial,sans-serif;"><table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="padding:30px 10px;"><tr><td align="center"><table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:620px;background:#ffffff;border:1px solid #e5e7eb;border-radius:8px;"><tr><td style="padding:20px;border-bottom:1px solid #eee;"><a href="#" style="font-size:20px;color:#00466a;text-decoration:none;font-weight:600;"> Moi Kanakku </a></td></tr><tr><td style="padding:25px;color:#333;line-height:1.7;"><p style="font-size:16px;margin:0 0 15px 0;"> Hi <strong style="color:#2c2c54;">${name}</strong>, </p><p style="margin:0 0 15px 0;"> We are pleased to welcome you to Moi Kanakku. Our platform helps you manage events, relations, and gift records in a simple and organized way. </p><div style="background:#f5f5f5;padding:15px;border-radius:6px;margin:15px 0;font-size:14px;"><p style="margin:0 0 10px;font-weight:600;color:#2c2c54;">Getting started with Moi Kanakku:</p><ul style="padding-left:18px;margin:0;"><li style="margin-bottom:8px;">Create and manage special events.</li><li style="margin-bottom:8px;">Maintain relations and guest details.</li><li style="margin-bottom:8px;">Track gifts received in cash or kind.</li><li>Export your records anytime in Excel format.</li></ul></div><p style="margin-top:15px;"> 🙏 Thank you for choosing Moi Kanakku. We are committed to helping you manage your records easily and efficiently. </p><div style="background:#eef4ff;border:1px solid #dbe7ff;padding:15px;border-radius:6px;margin-top:20px;font-size:14px;"><strong>🚀 Share Moi Kanakku</strong><br> If you find Moi Kanakku useful, please consider sharing it with your friends and family. More features and improvements will be available soon! </div><p style="margin-top:25px;font-size:14px;color:#666;"> Best regards,<br><strong>Moi Kanakku Team</strong></p></td></tr><tr><td style="border-top:1px solid #eee;padding:15px;text-align:center;font-size:12px;color:#999;"> © 2026 Moi Kanakku. All rights reserved. </td></tr></table></td></tr></table></body></html>`;
}

/**
 * Generate email-verification HTML with a clickable Verify Email button.
 * @param {{ name?: string, verifyLink: string, expiresInHours?: number }} options
 * @returns {string} HTML email content
 */
function getLegacyEmailVerificationContent({ name, verifyLink, expiresInHours = 24 }) {
    const safeName = escapeHtml(name || 'User');
    const safeLink = escapeHtml(verifyLink || '#');
    const hours = Number(expiresInHours) || 24;

    return `<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
</head>
<body style="margin:0;padding:0;font-family:Arial,Helvetica,sans-serif;background-color:#f5f7fb;">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="padding:30px 10px;">
    <tr>
      <td align="center">
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:620px;background:#ffffff;border:1px solid #eaeaea;border-radius:8px;overflow:hidden;">
          <tr>
            <td style="background:#2f3490;color:#ffffff;text-align:center;padding:20px;">
              <h2 style="margin:0;font-size:22px;">Verify your email</h2>
            </td>
          </tr>
          <tr>
            <td style="padding:30px;color:#333333;">
              <p style="margin:0 0 15px 0;font-size:16px;">Hi <strong>${safeName}</strong>,</p>
              <p style="margin:0 0 20px 0;font-size:15px;color:#555;">
                Please confirm this email address for your Moi Kanakku account by clicking the button below.
              </p>
              <div style="text-align:center;margin:30px 0;">
                <a href="${safeLink}" style="display:inline-block;background:#2f3490;color:#ffffff;text-decoration:none;padding:14px 28px;border-radius:8px;font-size:16px;font-weight:700;">
                  Verify Email
                </a>
              </div>
              <p style="text-align:center;font-size:14px;color:#666;margin:0;">
                This link will expire in <strong>${hours} hour${hours === 1 ? '' : 's'}</strong>.
              </p>
              <p style="margin-top:20px;font-size:13px;color:#777;word-break:break-all;">
                If the button does not work, copy and paste this link into your browser:<br>
                <a href="${safeLink}" style="color:#2f3490;">${safeLink}</a>
              </p>
              <p style="margin-top:20px;font-size:14px;color:#777;">
                If you did not expect this email, you can ignore it.
              </p>
            </td>
          </tr>
          <tr>
            <td style="border-top:1px solid #f1f1f1;padding:20px;font-size:14px;color:#666;">
              Regards,<br>
              <strong style="color:#2f3490;">Moi Kanakku Team</strong>
            </td>
          </tr>
        </table>
        <p style="max-width:620px;margin:20px auto 0;text-align:center;font-size:12px;color:#9ca3af;">
          © 2026 Moi Kanakku. All rights reserved.
        </p>
      </td>
    </tr>
  </table>
</body>
</html>`;
}

function getEmailAssetUrl(assetName) {
    return assetName === 'app-logo-light.png'
        ? 'cid:moi-app-logo'
        : 'cid:moi-label-dark';
}

function getBrandedEmailContent({ title, body, logoUrl, labelUrl }) {
    const safeTitle = escapeHtml(title || 'Moi Kanakku');
    const safeLogoUrl = escapeHtml(
        logoUrl || getEmailAssetUrl('app-logo-light.png'),
    );
    const safeLabelUrl = escapeHtml(
        labelUrl || getEmailAssetUrl('label-dark.png'),
    );
    const copyrightYear = new Date().getFullYear();

    return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="color-scheme" content="light">
    <meta name="supported-color-schemes" content="light">
    <title>${safeTitle}</title>
</head>
<body style="margin:0;padding:0;background-color:#f7f7f3;font-family:Arial,Helvetica,sans-serif;color:#171717;">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="width:100%;border-spacing:0;background-color:#f7f7f3;">
        <tr><td align="center" style="width:100%;padding:24px 12px;">
            <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="width:100%;max-width:900px;background-color:#ffffff;border:1px solid #e4e1d9;border-radius:22px;overflow:hidden;border-spacing:0;">
            <tr><td align="center" style="width:100%;padding:20px 24px;background-color:#ffffff;border-bottom:1px solid #e4e1d9;">
                    <table role="presentation" cellpadding="0" cellspacing="0" border="0" style="margin:0 auto;border-spacing:0;"><tr>
                        <td valign="middle" style="padding:0;vertical-align:middle;"><img src="${safeLogoUrl}" width="46" height="46" alt="Moi Kanakku" style="display:block;width:46px;height:46px;object-fit:contain;border:0;"></td>
                        <td valign="middle" style="padding-left:10px;vertical-align:middle;"><img src="${safeLabelUrl}" width="174" alt="Moi Kanakku" style="display:block;width:174px;height:auto;border:0;"></td>
                    </tr></table>
                </td></tr>
                <tr><td style="width:100%;padding:28px 32px 34px;background-color:#ffffff;">${body}</td></tr>
                <tr><td align="center" style="width:100%;padding:20px 24px 24px;background-color:#f1efe7;">
                    <p style="margin:0;color:#686868;font-size:12px;line-height:19px;">This message was sent automatically by Moi Kanakku.</p>
                    <p style="margin:6px 0 0;color:#171717;font-size:12px;line-height:19px;font-weight:700;">Thank you for using Moi Kanakku.</p>
                    <p style="margin:6px 0 0;color:#8a8882;font-size:11px;line-height:18px;">© ${copyrightYear} Moi Kanakku. All rights reserved.</p>
                </td></tr>
            </table>
        </td></tr>
    </table>
    <style>
        @media only screen and (max-width: 600px) {
            body { background-color:#f7f7f3 !important; }
            td[style*="padding:28px 32px 34px"] { padding:24px 20px 28px !important; }
            td[style*="padding:20px 24px"] { padding:18px !important; }
            h1 { font-size:26px !important; line-height:34px !important; }
        }
    </style>
</body>
</html>`;
}

async function sendFeedbackConfirmationEmail(toEmail, userName) {
    if (!toEmail) return;
    try {
        const safeName = escapeHtml(userName || 'User');
        const html = getBrandedEmailContent({
            title: 'Feedback Submitted',
            body: `<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="width:100%;border-spacing:0;"><tr><td style="padding:0;"><p style="margin:0 0 10px;color:#171717;font-size:17px;line-height:27px;">Hi <strong>${safeName}</strong>,</p><p style="margin:0;color:#686868;font-size:16px;line-height:27px;">Your feedback has been successfully submitted. We will review it shortly.</p><div style="margin:32px 0 18px;padding:22px;background:#f1efe7;border:1px solid #e4e1d9;border-radius:16px;color:#686868;font-size:15px;line-height:25px;"><strong style="color:#171717;">Help us grow!</strong><br>If you like Moi Kanakku, please share it with your friends and family. Your support helps us improve the app for everyone.</div></td></tr></table>`,
        });
        await sendEmail({ from: formatEmailFrom('Admin - Moi Kanakku Team'), to: toEmail, subject: 'Feedback Submission - Moi Kanakku', html });
    } catch (err) {
        logger.error('Error sending feedback confirmation email', err);
    }
}

async function sendFeedbackReplyEmail(toEmail, userName, replyText) {
    if (!toEmail) return;
    try {
        const safeName = escapeHtml(userName || 'User');
        const safeReply = escapeHtml(replyText || '').replace(/\n/g, '<br>');
        const html = getBrandedEmailContent({
            title: 'Feedback Response',
            body: `<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="width:100%;border-spacing:0;"><tr><td style="padding:0;"><p style="margin:0 0 10px;color:#171717;font-size:17px;line-height:27px;">Hi <strong>${safeName}</strong>,</p><p style="margin:0 0 18px;color:#686868;font-size:16px;line-height:27px;">A response has been provided for your feedback.</p><div style="padding:22px;background:#f1efe7;border:1px solid #e4e1d9;border-radius:16px;color:#686868;font-size:15px;line-height:25px;">${safeReply}</div></td></tr></table>`,
        });
        await sendEmail({ from: formatEmailFrom('Admin - Moi Kanakku Team'), to: toEmail, subject: 'Response to your feedback - Moi Kanakku', html });
    } catch (err) {
        logger.error('Error sending feedback reply email', err);
    }
}

function getAdminRegistrationEmailContent(userData) {
    const labels = {
        userId: 'User ID', name: 'Name', email: 'Email', mobile: 'Mobile', city: 'City',
        referred_by: 'Referred By', brand: 'Brand', model: 'Model', device_name: 'Device Name',
        normalizedAndroidVersion: 'Android Version', registrationTime: 'Registration Time',
    };
    const rows = Object.entries(labels).map(([key, label]) => `<tr><td style="padding:8px 0;color:#686868;"><strong style="color:#171717;">${label}:</strong> ${escapeHtml(userData[key] || 'N/A')}</td></tr>`).join('');
    return getBrandedEmailContent({
        title: 'New User Registration',
        body: `<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="width:100%;border-spacing:0;"><tr><td style="padding:0;"><p style="margin:0 0 18px;color:#171717;font-size:17px;line-height:27px;">Hi Admin,</p><p style="margin:0 0 18px;color:#686868;font-size:16px;line-height:27px;">A new user has registered on Moi Kanakku.</p><table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="width:100%;border-spacing:0;padding:12px 22px;background:#f1efe7;border:1px solid #e4e1d9;border-radius:16px;font-size:15px;line-height:22px;">${rows}</table></td></tr></table>`,
    });
}

function getWelcomeEmailContent(name) {
    const safeName = escapeHtml(name || 'User');
    return getBrandedEmailContent({
        title: 'Welcome to Moi Kanakku',
        body: `<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="width:100%;border-spacing:0;">
            <tr><td style="padding:0;"><p style="margin:0 0 10px;color:#171717;font-size:17px;line-height:27px;">Hi <strong>${safeName}</strong>,</p></td></tr>
            <tr><td style="padding:0;"><p style="margin:0;color:#686868;font-size:16px;line-height:27px;">We are pleased to welcome you to Moi Kanakku. Our platform helps you manage events, relations, and gift records in a simple and organized way.</p></td></tr>
            <tr><td style="padding:0;"><div style="margin:32px 0 18px;padding:22px;background-color:#f1efe7;border:1px solid #e4e1d9;border-radius:16px;color:#686868;font-size:15px;line-height:25px;"><strong style="color:#171717;">Getting started with Moi Kanakku:</strong><br>Create and manage events, maintain relations and guest details, track gifts, and export your records anytime.</div></td></tr>
            <tr><td style="padding:0;"><p style="margin:0;color:#8a8882;font-size:13px;line-height:21px;">Thank you for choosing Moi Kanakku. We are committed to helping you manage your records easily and efficiently.</p></td></tr>
        </table>`,
    });
}

function getEmailVerificationContent({ name, verifyLink, expiresInHours = 24 }) {
    const safeName = escapeHtml(name || 'User');
    const safeLink = escapeHtml(verifyLink || '#');
    const hours = Number(expiresInHours) || 24;
    return getBrandedEmailContent({
        title: 'Verify your email',
        body: `<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="width:100%;border-spacing:0;">
            <tr><td style="padding:0;"><p style="margin:0 0 10px;color:#171717;font-size:17px;line-height:27px;">Hi <strong>${safeName}</strong>,</p></td></tr>
            <tr><td style="padding:0;"><p style="margin:0;color:#686868;font-size:16px;line-height:27px;">Please confirm this email address for your Moi Kanakku account by clicking the button below.</p></td></tr>
            <tr><td align="center" style="padding:32px 0 18px;"><a href="${safeLink}" style="display:inline-block;padding:14px 28px;background-color:#171717;color:#ffffff;text-decoration:none;border-radius:8px;font-size:16px;font-weight:700;">Verify Email</a></td></tr>
            <tr><td align="center" style="padding:0;"><p style="margin:0;color:#686868;font-size:14px;line-height:21px;">This link will expire in <strong style="color:#171717;">${hours} hour${hours === 1 ? '' : 's'}</strong>.</p></td></tr>
            <tr><td style="padding:0;"><div style="height:1px;background-color:#e4e1d9;margin:32px 0 26px;"></div><p style="margin:0;color:#8a8882;font-size:13px;line-height:21px;word-break:break-all;">If the button does not work, copy and paste this link into your browser:<br><a href="${safeLink}" style="color:#171717;">${safeLink}</a><br><br>If you did not expect this email, you can safely ignore it.</p></td></tr>
        </table>`,
    });
}

/**
 * Generate the shared OTP email template.
 * @param {{ name?: string, otp: string, title: string, message: string, expiresAt?: string, expiresInMinutes?: number }} options
 * @returns {string} HTML email content
 */
function getOtpEmailContent({
        name,
        otp,
        title,
        message,
        expiresAt = '',
        expiresInMinutes = 10,
    securityMessage = 'If you did not request this code, you can safely ignore this email.',
    automaticMessage = 'This message was sent automatically by Moi Kanakku.',
    thanksMessage = 'Thank you for using Moi Kanakku.',
    logoUrl,
    labelUrl,
    copyrightYear = new Date().getFullYear(),
}) {
        const safeName = escapeHtml(name || 'User');
        const safeOtp = escapeHtml(otp || '');
        const safeTitle = escapeHtml(title || 'Email Verification');
        const safeMessage = escapeHtml(message || 'Use the verification code below to continue.');
        const safeExpiresAt = escapeHtml(expiresAt || '');
        const safeSecurityMessage = escapeHtml(securityMessage);
        const safeAutomaticMessage = escapeHtml(automaticMessage);
        const safeThanksMessage = escapeHtml(thanksMessage);
        const safeLogoUrl = escapeHtml(
            logoUrl || getEmailAssetUrl('app-logo-light.png'),
        );
        const safeLabelUrl = escapeHtml(
            labelUrl || getEmailAssetUrl('label-dark.png'),
        );
        const safeCopyrightYear = escapeHtml(copyrightYear);
        const minutes = Number(expiresInMinutes) || 10;

        return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="color-scheme" content="light">
    <meta name="supported-color-schemes" content="light">
    <title>${safeTitle}</title>
</head>
<body style="margin:0;padding:0;background-color:#f7f7f3;font-family:Arial,Helvetica,sans-serif;color:#171717;">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="width:100%;border-spacing:0;background-color:#f7f7f3;">
        <tr>
            <td align="center" style="width:100%;padding:40px 20px;">
                <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="width:100%;max-width:900px;background-color:#ffffff;border:1px solid #e4e1d9;border-radius:22px;overflow:hidden;border-spacing:0;">
                    <tr>
                        <td align="center" style="width:100%;padding:30px 40px;background-color:#ffffff;border-bottom:1px solid #e4e1d9;">
                            <table role="presentation" cellpadding="0" cellspacing="0" border="0" style="margin:0 auto;border-spacing:0;">
                                <tr>
                                    <td valign="middle" style="padding:0;vertical-align:middle;">
                                        <img src="${safeLogoUrl}" width="46" height="46" alt="Moi Kanakku" style="display:block;width:46px;height:46px;object-fit:contain;border:0;">
                                    </td>
                                    <td valign="middle" style="padding-left:10px;vertical-align:middle;">
                                        <img src="${safeLabelUrl}" width="174" alt="Moi Kanakku" style="display:block;width:174px;height:auto;border:0;">
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                    <tr>
                        <td style="width:100%;padding:45px 60px 50px;background-color:#ffffff;">
                            <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="width:100%;border-spacing:0;">
                                <tr><td style="padding:0;"><p style="margin:0 0 10px;padding:0;color:#171717;font-size:17px;line-height:27px;">Hi <strong>${safeName}</strong>,</p></td></tr>
                                <tr><td style="padding:0;"><p style="margin:0;padding:0;color:#686868;font-size:16px;line-height:27px;">${safeMessage}</p></td></tr>
                                <tr>
                                    <td style="padding:0;">
                                        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="width:100%;margin:32px 0 18px;border-spacing:0;">
                                            <tr><td align="center" style="padding:30px 20px;background-color:#f1efe7;border:1px solid #e4e1d9;border-radius:16px;"><div style="color:#171717;font-size:36px;line-height:44px;font-weight:700;letter-spacing:10px;font-family:Arial,Helvetica,sans-serif;">${safeOtp}</div></td></tr>
                                        </table>
                                    </td>
                                </tr>
                                <tr><td align="center" style="padding:0;"><p style="margin:0;color:#686868;font-size:14px;line-height:21px;">This verification code will expire in <strong style="color:#171717;">${minutes} minutes</strong>.</p></td></tr>
                                ${safeExpiresAt ? `<tr><td align="center" style="padding:0;"><p style="margin:6px 0 0;color:#8a8882;font-size:13px;line-height:20px;">Expires at: <strong style="color:#686868;">${safeExpiresAt}</strong></p></td></tr>` : ''}
                                <tr><td style="padding:0;"><div style="height:1px;background-color:#e4e1d9;margin:32px 0 26px;"></div></td></tr>
                                <tr><td style="padding:0;"><p style="margin:0;padding:0;color:#8a8882;font-size:13px;line-height:21px;">${safeSecurityMessage}</p></td></tr>
                            </table>
                        </td>
                    </tr>
                    <tr>
                        <td align="center" style="width:100%;padding:28px 40px 32px;background-color:#f1efe7;">
                            <p style="margin:0;padding:0;color:#686868;font-size:12px;line-height:19px;">${safeAutomaticMessage}</p>
                            <p style="margin:6px 0 0;padding:0;color:#171717;font-size:12px;line-height:19px;font-weight:700;">${safeThanksMessage}</p>
                            <p style="margin:6px 0 0;padding:0;color:#8a8882;font-size:11px;line-height:18px;">© ${safeCopyrightYear} Moi Kanakku. All rights reserved.</p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
    <style>
        @media only screen and (max-width: 600px) {
            body { background-color:#f7f7f3 !important; }
            td[style*="padding:45px 60px 50px"] { padding:30px 22px 34px !important; }
            td[style*="padding:30px 40px"] { padding:22px !important; }
            h1 { font-size:26px !important; line-height:34px !important; }
            div[style*="font-size:36px"] { font-size:30px !important; line-height:38px !important; letter-spacing:7px !important; }
        }
    </style>
</body>
</html>`;
}

/**
 * Generate admin notification email HTML for new user registration
 * @param {Object} userData - User registration data { userId, name, email, mobile, city, referred_by, brand, model, device_name, normalizedAndroidVersion, registrationTime }
 * @returns {string} HTML email content
 */
function getLegacyAdminRegistrationEmailContent(userData) {
    const {
        userId,
        name,
        email,
        mobile,
        city,
        referred_by,
        brand,
        model,
        device_name,
        normalizedAndroidVersion,
        registrationTime,
    } = userData;

    return `<!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>New User Registration</title></head><body style="margin:0;padding:0;background:#f4f6fb;font-family:Arial,Helvetica,sans-serif;"><span style="display:none!important;visibility:hidden;mso-hide:all;font-size:1px;color:#ffffff;line-height:1px;max-height:0;max-width:0;opacity:0;overflow:hidden;">New user registered</span><div style="padding:30px 10px;display:flex;justify-content:center;"><div style="max-width:620px;width:100%;background:#ffffff;border:1px solid #e5e7eb;border-radius:10px;overflow:hidden;"><div style="background:#2f3490;color:#ffffff;text-align:center;padding:25px;"><h2 style="margin:0;font-size:22px;font-weight:600;"> New User Registered </h2><p style="margin-top:6px;font-size:14px;"> A new user has registered on Moi Kanakku </p></div><div style="padding:28px;color:#333;font-size:15px;line-height:1.6;"><p style="margin:0 0 12px;font-size:16px;"> Hi Admin, </p><p style="margin:0 0 16px;"> A new user has registered on Moi Kanakku with the following details:</p><ul style="padding-left:18px;margin:0;color:#333;"><li style="margin-bottom:8px;"><strong>User ID:</strong> ${userId}</li><li style="margin-bottom:8px;"><strong>Name:</strong> ${name}</li><li style="margin-bottom:8px;"><strong>Email:</strong> ${email}</li><li style="margin-bottom:8px;"><strong>Mobile:</strong> ${mobile}</li><li style="margin-bottom:8px;"><strong>City:</strong> ${city || "N/A"}</li><li style="margin-bottom:8px;"><strong>Referred By:</strong> ${referred_by || "N/A"}</li><li style="margin-bottom:8px;"><strong>Brand:</strong> ${brand || "N/A"}</li><li style="margin-bottom:8px;"><strong>Model:</strong> ${model || "N/A"}</li><li style="margin-bottom:8px;"><strong>Device Name:</strong> ${device_name || "N/A"}</li><li style="margin-bottom:8px;"><strong>Android Version:</strong> ${normalizedAndroidVersion || "N/A"}</li><li style="margin-bottom:8px;"><strong>Registration Time:</strong> ${registrationTime}</li></ul></div><div style="border-top:1px solid #eee;text-align:center;padding:15px;font-size:12px;color:#888;"> © 2026 Moi Kanakku. All rights reserved.<br> If you did not sign up for Moi Kanakku, please ignore this email. </div></div></div></body></html>`;
}

module.exports = {
    sendFeedbackConfirmationEmail,
    sendFeedbackReplyEmail,
    queueFeedbackConfirmationEmail,
    queueFeedbackReplyEmail,
    sendEmail,
    queueEmail,
    getWelcomeEmailContent,
    getEmailVerificationContent,
    getOtpEmailContent,
    getBrandedEmailContent,
    getAdminRegistrationEmailContent,
    createEmailTransporter,
    formatEmailFrom,
    getReplyToEmail,
    normalizeEmailAddress,
    buildMailOptions,
    verifyEmailTransport,
    escapeHtml,
};
