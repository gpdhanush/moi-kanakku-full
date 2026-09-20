// User controllers: authentication, account management, and notifications
const User = require("../models/user");
const Admin = require("../models/admin");
const MFA = require("../models/mfaModel");
const SessionModel = require("../models/sessions");
const bcrypt = require("bcryptjs");
const crypto = require("crypto");
const jwt = require("jsonwebtoken");
const tokenService = require("../middlewares/tokenService");
const { queuePushNotification } = require("./notificationController");
const { NotificationType } = require("../models/notificationModels");
const multer = require("multer");
const path = require("path");
const fs = require("fs");
const logger = require("../config/logger");
const { validateUuid, sendUuidError } = require("../helpers/idParams");
const { isInactiveStatus, sendInactiveError } = require("../helpers/accountStatus");
const {
  summarizeDevices,
  toAdminDevice,
} = require("../helpers/deviceInstallStatus");
const cache = require("../utils/cache");
const { recordAuditLog } = require("../helpers/auditLog");
const { OAuth2Client } = require('google-auth-library');
const { buildAuthSummary, normalizeSignupType } = require('../helpers/authProvider');
const { validatePassword } = require('../helpers/validators');

const googleClient = new OAuth2Client(
  process.env.GOOGLE_CLIENT_ID,
  process.env.GOOGLE_CLIENT_SECRET,
  process.env.GOOGLE_REDIRECT_URI,
);

function clearAdminUserListCache() {
  cache.delByPrefix("admin:all-user-lists");
  cache.del("dashboard:stats");
  cache.del("dashboard:detailed");
}

const {
  queueEmail,
  getWelcomeEmailContent,
  getAdminRegistrationEmailContent,
  formatEmailFrom,
} = require("../services/emailService");

// Common response messages
const userError = "குறிப்பிடப்பட்ட பயனர் இல்லை!";
const mobileError =
  "இந்த மொபைல் எண் ஏற்கனவே மற்றொரு பயனருக்கு பதிவு செய்யப்பட்டுள்ளது.";

const formatPublicUserDetails = (details) => ({
  id: details.id,
  name: details.full_name,
  email: details.email,
  mobile: details.mobile,
  last_login: details.last_activity_at,
  profile: details.profile,
  device: details.device,
  referrer_id: details.referrer_id,
  referred_count: details.referred_count,
  create_date: details.created_at,
  update_date: details.updated_at,
  status: details.status,
  referral_code: details.referral_code || null,
  is_verified: details.is_verified || 0,
  email_verified_at: details.email_verified_at || null,
});

const formatAdminUserListItem = (details) => {
  const devices = details.devices || (details.device ? [details.device] : []);
  const summary = summarizeDevices(devices);
  const authSummary = buildAuthSummary(details);
  return {
    id: details.id,
    mobile: details.mobile,
    name: details.full_name,
    last_login: details.last_activity_at,
    city: details.profile?.city || null,
    profile_image_url: details.profile?.profile_image_url || null,
    device_name: details.device?.device_name || null,
    status: details.status || "ACTIVE",
    app_status: summary.app_status,
    last_seen_at: summary.last_seen_at,
    device_count: summary.device_count,
    platforms: summary.platforms,
    app_version: summary.app_version,
    signup_type: authSummary.signupType,
    google_linked: authSummary.googleLinked,
    password_set: authSummary.passwordSet,
    email_verified: authSummary.emailVerified,
  };
};

const formatAdminUserDetails = (details) => {
  const devices = details.devices || (details.device ? [details.device] : []);
  const summary = summarizeDevices(devices);
  const authSummary = buildAuthSummary(details);
  return {
    id: details.id,
    name: details.full_name,
    email: details.email,
    mobile: details.mobile,
    last_login: details.last_activity_at,
    profile: details.profile,
    device: toAdminDevice(details.device),
    devices: devices.map((row) => toAdminDevice(row)).filter(Boolean),
    referrer_id: details.referrer_id,
    referred_count: details.referred_count,
    create_date: details.created_at,
    update_date: details.updated_at,
    status: details.status,
    referral_code: details.referral_code || null,
    is_verified: details.is_verified || 0,
    email_verified_at: details.email_verified_at || null,
    signup_type: authSummary.signupType,
    google_linked: authSummary.googleLinked,
    password_set: authSummary.passwordSet,
    email_verified: authSummary.emailVerified,
    app_status: summary.app_status,
    last_seen_at: summary.last_seen_at,
    device_count: summary.device_count,
    platforms: summary.platforms,
    app_version: summary.app_version,
  };
};

exports.userController = {
  googleLogin: async (req, res) => {
    try {
      const { idToken } = req.body || {};
      if (!idToken || typeof idToken !== 'string') {
        return res.status(400).json({
          responseType: 'F',
          responseValue: { message: 'Google ID token is required.' },
        });
      }

      const ticket = await googleClient.verifyIdToken({
        idToken,
        audience: [
          process.env.GOOGLE_CLIENT_ID,
          process.env.GOOGLE_ANDROID_CLIENT_ID,
          process.env.GOOGLE_IOS_CLIENT_ID,
        ].filter(Boolean),
      });

      const payload = ticket.getPayload();
      if (!payload || !payload.sub || !payload.email) {
        return res.status(401).json({
          responseType: 'F',
          responseValue: { message: 'Invalid Google identity token.' },
        });
      }

      const normalizedEmail = String(payload.email).trim().toLowerCase();
      const googleId = String(payload.sub).trim();
      const normalizedName = String(payload.name || payload.email.split('@')[0]).trim();
      const googlePicture = typeof payload.picture === 'string' ? payload.picture.trim() : null;

      let user = await User.findByGoogleId(googleId);
      if (!user) {
        user = await User.findByEmail(normalizedEmail);
      }

      if (!user) {
        const createdUser = await User.createGoogleUser({
          name: normalizedName,
          email: normalizedEmail,
          googleId,
        });
        const created = await User.findById(createdUser.insertId || createdUser.id);
          await User.syncGoogleProfile({
            id: created.id,
            name: normalizedName,
            profileImageUrl: googlePicture,
          });
        return res.status(200).json({
          responseType: 'S',
          responseValue: {
            token: tokenService.generateToken(created.id),
            user: {
              id: created.id,
              name: created.full_name,
              email: created.email,
              profileImageUrl: googlePicture,
              signupType: 'google',
              passwordSet: false,
              emailVerified: true,
            },
            requiresPasswordSetup: true,
          },
        });
      }

      if (user.google_id !== googleId && user.email && user.email.toLowerCase() === normalizedEmail) {
        await User.linkGoogleAccount(user.id, googleId);
        user = await User.findById(user.id);
      }

      await User.syncGoogleProfile({
        id: user.id,
        name: normalizedName,
        profileImageUrl: googlePicture,
      });

      const userID = user.id;
      tokenService.invalidatePreviousToken(userID);
      const jwtToken = tokenService.generateToken(userID);
      await User.updateLastLogin(userID);
      await SessionModel.createSession(userID).catch(() => {});

      return res.status(200).json({
        responseType: 'S',
        responseValue: {
          token: jwtToken,
          user: {
            id: user.id,
            name: user.full_name,
            email: user.email,
            profileImageUrl: googlePicture || user.profile_image_url || null,
            signupType: normalizeSignupType(user.signup_type || 'email'),
            passwordSet: Boolean(user.password_set),
            emailVerified: Boolean(user.email_verified ?? user.is_verified),
          },
          requiresPasswordSetup: !Boolean(user.password_set),
        },
      });
    } catch (error) {
      logger.error('Google login error:', error);
      const message = error?.message || 'Google sign-in failed';
      return res.status(401).json({
        responseType: 'F',
        responseValue: { message: message.includes('Token') || message.includes('ID token') ? 'Invalid or expired Google token.' : 'Google sign-in failed.' },
      });
    }
  },

  setPassword: async (req, res) => {
    try {
      const userId = req.user?.userId;
      if (!userId) {
        return res.status(401).json({ responseType: 'F', responseValue: { message: 'Authentication required.' } });
      }

      const { password } = req.body || {};
      const validation = validatePassword(password);
      if (!validation.isValid) {
        return res.status(400).json({
          responseType: 'F',
          responseValue: { message: validation.errors[0] },
        });
      }

      const user = await User.findById(userId);
      if (!user) {
        return res.status(404).json({ responseType: 'F', responseValue: { message: 'User not found.' } });
      }

      const hashed = await bcrypt.hash(password, 10);
      await User.updatePassword({ id: user.id, password: hashed });
      await User.setPasswordSet(user.id, true);
      return res.status(200).json({
        responseType: 'S',
        responseValue: { message: 'Password created successfully' },
      });
    } catch (error) {
      logger.error('Set password failed:', error);
      return res.status(500).json({ responseType: 'F', responseValue: { message: 'Unable to set password.' } });
    }
  },

  /**
   * Authenticate user and issue JWT.
   * Body: { email, password }
   */
  login: async (req, res) => {
    const { email, password } = req.body;

    try {
      // Try to find active user first
      const user = await User.findByEmail(email);
      if (!user) {
        // Check if user exists but is deleted
        const deletedUser = await User.findByEmailIncludingDeleted(email);
        if (deletedUser && deletedUser.is_deleted) {
          return res.status(403).json({
            responseType: "F",
            responseValue: {
              message:
                "உங்கள் கணக்கு நீக்கப்பட்டுவிட்டது. மீட்டமைக்க கடைய்சு எங்களை தொடர்பு கொள்ளவும்.",
              deleted_at: deletedUser.deleted_at,
              account_status: "DELETED",
            },
          });
        }
        // User doesn't exist at all
        return res.status(404).json({
          responseType: "F",
          responseValue: { message: "தவறான மின்னஞ்சல் ஐடி!" },
        });
      }

      if (isInactiveStatus(user.status)) {
        return sendInactiveError(res);
      }

      // CHECK IF ACCOUNT IS BLOCKED (BEFORE PASSWORD VERIFICATION)
      try {
        const blockStatus = await User.getLoginBlockStatus(user.id);
        if (blockStatus.is_blocked) {
          const minutesRemaining = Math.ceil(
            (new Date(blockStatus.blocked_until) - new Date()) / (1000 * 60),
          );
          return res.status(429).json({
            responseType: "F",
            responseValue: {
              message: `மிக அதிக தோல்வி முயற்சிகள். ${minutesRemaining} நிமிடங்களில் மீண்டும் முயற்சி செய்க.`,
              retry_after_minutes: minutesRemaining,
              blocked_until: blockStatus.blocked_until,
              account_status: "BLOCKED",
            },
          });
        }
      } catch (blockCheckErr) {
        logger.warn("Error checking login block status:", blockCheckErr);
        // Continue with password check - feature graceful degrades if column doesn't exist
      }

      const isPasswordValid = await bcrypt.compare(
        password,
        user.password_hash,
      );
      if (!isPasswordValid) {
        try {
          const failureStatus = await User.incrementFailedLoginAttempts(
            user.id,
          );
          if (failureStatus.blocked) {
            return res.status(429).json({
              responseType: "F",
              responseValue: {
                message:
                  "மிக அதிக தோல்வி முயற்சிகள். கணக்கு 15 நிமிடங்களுக்கு தடுக்கப்பட்டுள்ளது.",
                attempts: failureStatus.attempts,
                blocked_until: failureStatus.blocked_until,
                account_status: "BLOCKED",
              },
            });
          } else {
            return res.status(401).json({
              responseType: "F",
              responseValue: {
                message: `கடவுச்சொல் தவறானது. ${failureStatus.remaining_attempts} முயற்சிகள் மீதமுள்ளது.`,
                remaining_attempts: failureStatus.remaining_attempts,
              },
            });
          }
        } catch (err) {
          logger.warn("Login blocking feature error:", err);
          return res.status(401).json({
            responseType: "F",
            responseValue: { message: "கடவுச்சொல் தவறானது." },
          });
        }
      }

      try {
        await User.resetFailedLoginAttempts(user.id);
      } catch (err) {
        logger.warn("Failed to reset login attempts:", err);
      }

      const userID = user.id;

      // End any previous active session (single-session policy)
      // This sets logout_at for the previous session and terminates it
      try {
        await SessionModel.endSession(userID);
        logger.debug(`Previous session ended for user ${userID}`);
      } catch (sessionErr) {
        logger.warn("Failed to end previous session:", sessionErr);
        // Continue even if previous session end fails - not critical
      }

      // Invalidate old token (single-session policy) and generate a new one
      tokenService.invalidatePreviousToken(userID);
      const jwtToken = tokenService.generateToken(userID);
      // debug logging of token state
      logger.debug(`login for user ${userID}, new token generated`);
      logger.debug("current token store snapshot:", tokenService.userTokens);
      const response = {
        status: user.status,
        id: user.id,
        name: user.full_name,
        mobile: user.mobile,
        email: user.email,
        referral_code: user.referral_code || null,
        last_login: user.last_activity_at,
        profile_image: user.profile_image_url || null,
        fcm_token: user.notification_token || null,
        is_verified: user.is_verified || 0,
        email_verified_at: user.email_verified_at || null,
        token: jwtToken,
      };

      // Update last login timestamp
      await User.updateLastLogin(userID);

      // Create new session record
      try {
        await SessionModel.createSession(userID);
        logger.debug(`New session created for user ${userID}`);
      } catch (sessionErr) {
        logger.warn("Failed to create new session record:", sessionErr);
        // Continue even if session creation fails - not critical
      }

      recordAuditLog({
        userId: userID,
        action: "LOGIN",
        entityType: "user",
        entityId: userID,
        summary: "User logged in",
        metadata: { email: user.email || null },
        req,
      });

      return res
        .status(200)
        .json({ responseType: "S", responseValue: response });
    } catch (error) {
      return res.status(500).json({
        responseType: "F",
        responseValue: { message: error.toString() },
      });
    }
  },

  /**
   * Logout user and end session
   * Header: Authorization: Bearer <token>
   */
  logout: async (req, res) => {
    try {
      // Get user ID from authenticated token (via middleware)
      const userId = req.user?.userId;

      if (!userId) {
        return res.status(401).json({
          responseType: "F",
          responseValue: { message: "JWT டோக்கன் தேவையானது." },
        });
      }

      // End the user session (set logout_at timestamp)
      try {
        const sessionEnded = await SessionModel.endSession(userId);
        if (!sessionEnded) {
          logger.warn(`No active session found for user ${userId}`);
        }
      } catch (sessionErr) {
        logger.error("Error ending session:", sessionErr);
        // Continue even if session end fails - not critical
      }

      // Invalidate the token (remove from memory)
      try {
        tokenService.removeToken(userId);
        logger.debug(`Token invalidated for user ${userId}`);
      } catch (tokenErr) {
        logger.error("Error invalidating token:", tokenErr);
        // Continue even if token invalidation fails
      }

      recordAuditLog({
        userId,
        action: "LOGOUT",
        entityType: "user",
        entityId: userId,
        summary: "User logged out",
        req,
      });

      return res.status(200).json({
        responseType: "S",
        responseValue: {
          message: "வெற்றிகரமாக வெளியேறினர்.",
          user_id: userId,
          logout_at: new Date(),
        },
      });
    } catch (error) {
      logger.error("Logout Error:", error);
      return res.status(500).json({
        responseType: "F",
        responseValue: { message: error.toString() },
      });
    }
  },
  /**
   * Register a new user, send welcome email and admin notification.
   * Body: {
   *   name,
   *   email,
   *   mobile,
   *   password,
   *   referred_by?,
   *   fcm_token?,
   *   device_id?,
   *   brand?,
   *   manufacturer?,
   *   model?,
   *   device_name?,
   *   ram_size?,
   *   android_version? / androidVersion?
   *   city?
   * }
   */
  create: async (req, res) => {
    const {
      name,
      email,
      mobile,
      password,
      city,
      fcm_token,
      device_id,
      brand,
      manufacturer,
      model,
      device_name,
      ram_size,
      android_version,
      androidVersion,
      referred_by,
    } = req.body;
    let userId = null; // Track user ID for rollback

    try {
      // Validate required fields
      if (!name || !email || !mobile || !password) {
        return res.status(400).json({
          responseType: "F",
          responseValue: {
            message:
              "அனைத்து புலங்களும் (பெயர், மின்னஞ்சல், மொபைல், கடவுச்சொல்) தேவையானவை!",
          },
        });
      }

      // Check duplicates by email (including soft-deleted accounts,
      // since the unique key uk_users_email still holds the email)
      const mail = await User.findByEmailIncludingDeleted(email);
      if (mail) {
        if (mail.is_deleted) {
          return res.status(409).json({
            responseType: "F",
            responseValue: {
              message:
                "இந்த மின்னஞ்சலுடன் நீக்கப்பட்ட கணக்கு உள்ளது. கணக்கை மீட்டெடுக்கவும் (restore).",
              account_status: "DELETED",
              can_restore: true,
            },
          });
        }
        return res.status(404).json({
          responseType: "F",
          responseValue: {
            message: "இந்த மின்னஞ்சல் ஏற்கனவே பதிவு செய்யப்பட்டுள்ளது!",
          },
        });
      }
      // Check duplicates by mobile number
      const mbl = await User.findByMobile(mobile);
      if (mbl) {
        return res.status(404).json({
          responseType: "F",
          responseValue: {
            message: "இந்த மொபைல் எண் ஏற்கனவே பதிவு செய்யப்பட்டுள்ளது!",
          },
        });
      }
      // Hash the password
      const hashedPassword = await bcrypt.hash(password, 10);

      // Normalise Android version and SDK values from different client keys
      const normalizedAndroidVersion =
        android_version || androidVersion || null;

      const newUser = {
        name,
        email,
        mobile,
        password: hashedPassword,
        city: city != null && String(city).trim() !== "" ? String(city).trim() : null,
        fcm_token: fcm_token || null,
        device_name: device_name || null,
        device_id: device_id || null,
        brand: brand || null,
        model: model || null,
        manufacturer: manufacturer || null,
        ram_size: ram_size ?? null,
        android_version: normalizedAndroidVersion,
        platform: req.body.platform || 'android',
        app_version: req.body.app_version || req.body.appVersion || null,
      };

      // Save user details (generates unique referral_code)
      const query = await User.create(newUser);
      if (query && query.insertId) {
        userId = query.insertId;
        logger.info(`User created with ID: ${userId}`);

        try {
          // If referred_by (referral code) provided, link referrer -> referred (ignore if invalid)
          if (referred_by && String(referred_by).trim()) {
            try {
              const referrer = await User.findByReferralCode(referred_by);
              if (referrer && referrer.id !== userId) {
                await User.recordReferral(referrer.id, userId);
              }
            } catch (refErr) {
              logger.error("Referral link failed", refErr);
              // Don't rollback for referral errors - non-critical
            }
          }

          const registrationTime = new Date().toLocaleString("en-IN", {
            timeZone: "Asia/Kolkata",
          });

          // Welcome email content (HTML) - generated from emailService
          const emailContent = getWelcomeEmailContent(name);

          // Queue welcome email (non-blocking)
          queueEmail(
            {
              to: email,
              subject: "Welcome to Moi Kanakku!",
              html: emailContent,
              from: formatEmailFrom("Info - Moi Kanakku"),
            },
            `welcome:${email}`,
          );

          // Admin notification email with complete user details - generated from emailService
          const adminEmailContent = getAdminRegistrationEmailContent({
            userId,
            name,
            email,
            mobile,
            city: newUser.city,
            referred_by,
            brand,
            model,
            device_name,
            normalizedAndroidVersion,
            registrationTime,
          });

          // Queue admin notification email (device + registration details)
          queueEmail(
            {
              to: "agprakash406@gmail.com",
              subject: "New user registered successfully",
              html: adminEmailContent,
              from: formatEmailFrom("Info - Moi Kanakku"),
            },
            `admin-reg:${userId}`,
          );

          // Queue FCM notification if fcm_token is provided
          if (fcm_token) {
            queuePushNotification({
              userId: userId,
              title: "பயனர் வெற்றிகரமாக பதிவு செய்யப்பட்டார்",
              body: "இப்போது நீங்கள் இந்த பயன்பாட்டைப் பயன்படுத்தலாம்",
              token: fcm_token,
              type: NotificationType.ACCOUNT,
            });
          }

          recordAuditLog({
            userId,
            action: "SIGNUP",
            entityType: "user",
            entityId: userId,
            summary: "New user registered",
            metadata: { email: email || null, mobile: mobile || null },
            deviceId: device_id || null,
            req,
          });

          return res.status(200).json({
            responseType: "S",
            responseValue: {
              message: "பயனர் வெற்றிகரமாக பதிவு செய்யப்பட்டார்.",
              userId: userId,
            },
          });
        } catch (postCreationError) {
          // Rollback: hard delete the user so the email/mobile are freed for retry
          logger.error("Critical error after user creation, rolling back:", postCreationError);
          try {
            await User.hardDeleteUser(userId);
            logger.info(`User ${userId} rolled back due to: ${postCreationError.message}`);
          } catch (rollbackError) {
            logger.error(`Failed to rollback user ${userId}:`, rollbackError);
          }

          return res.status(500).json({
            responseType: "F",
            responseValue: {
              message: "பயனர் பதிவு தோல்வியடைந்தது. மீண்டும் முயற்சி செய்க.",
              error: postCreationError.toString(),
            },
          });
        }
      } else {
        return res.status(404).json({
          responseType: "F",
          responseValue: { message: "பயனர் பதிவு தோல்வியடைந்தது." },
        });
      }
    } catch (error) {
      logger.error("Error in user creation:", error);
      // Rollback if user was created (hard delete frees the email/mobile for retry)
      if (userId) {
        try {
          await User.hardDeleteUser(userId);
          logger.info(`User ${userId} rolled back due to outer error: ${error.message}`);
        } catch (rollbackError) {
          logger.error(`Failed to rollback user ${userId}:`, rollbackError);
        }
      }
      return res.status(500).json({
        responseType: "F",
        responseValue: { message: error.toString() },
      });
    }
  },
  /**
   * Update user profile (basic info in users table and user_profiles table).
   * Body: { id, name, mobile, email, status, gender, date_of_birth, address_line1, address_line2, city, state, country, postal_code, fcm_token, device_name }
   */
  update: async (req, res) => {
    const { id, name, mobile, email } = req.body;
    try {
      if (!id) {
        return res.status(400).json({
          responseType: "F",
          responseValue: { message: "பயனர் ID தேவை!" },
        });
      }

      const idCheck = validateUuid(id, "id");
      if (!idCheck.ok) return sendUuidError(res, idCheck.message);

      // Check that mobile number is unique (excluding current user)
      if (mobile) {
        const chkMobile = await User.checkMobileNo(mobile, id);
        if (chkMobile) {
          return res.status(404).json({
            responseType: "F",
            responseValue: { message: mobileError },
          });
        }
      }

      // Check that email is unique (excluding current user)
      if (email) {
        const chkEmail = await User.findByEmail(email);
        if (chkEmail && chkEmail.id !== id) {
          return res.status(404).json({
            responseType: "F",
            responseValue: {
              message: "இந்த மின்னஞ்சல் ஏற்கனவே பதிவு செய்யப்பட்டுள்ளது!",
            },
          });
        }
      }

      const chk = await User.findById(id);
      if (!chk) {
        return res
          .status(404)
          .json({ responseType: "F", responseValue: { message: userError } });
      }

      // Call comprehensive update function to handle all tables
      const query = await User.updateUserData(req.body);
      if (query && query.success) {
        // Fetch updated user to return
        const updatedUser = await User.findById(id);
        const response = {
          // id: updatedUser.id,
          // name: updatedUser.full_name,
          // email: updatedUser.email,
          // mobile: updatedUser.mobile,
          // last_login: updatedUser.last_activity_at,
          // profile_image: updatedUser.profile_image_url || null,
          // referral_code: updatedUser.referral_code || null,
          message: "பயனர் தகவல் வெற்றிகரமாக புதுப்பிக்கப்பட்டது.",
        };
        recordAuditLog({
          userId: id,
          action: "PROFILE_UPDATE",
          entityType: "user",
          entityId: id,
          summary: "Profile updated",
          metadata: {
            name: updatedUser?.full_name || name || null,
            email: updatedUser?.email || email || null,
          },
          req,
        });
        return res
          .status(200)
          .json({ responseType: "S", responseValue: response });
      } else {
        return res.status(404).json({
          responseType: "F",
          responseValue: {
            message:
              "புதுப்பித்தல் தோல்வியடைந்தது. மாற்றங்களை சேமிக்க முடியவில்லை.",
          },
        });
      }
    } catch (error) {
      return res.status(500).json({
        responseType: "F",
        responseValue: { message: error.toString() },
      });
    }
  },
  /**
   * Get a user's profile by ID.
   * Params: { id }
   */
  getUser: async (req, res) => {
    const userId = req.params.id;
    try {
      const idCheck = validateUuid(userId, "id");
      if (!idCheck.ok) return sendUuidError(res, idCheck.message);

      const user = await User.findById(userId);
      if (!user) {
        return res
          .status(404)
          .json({ responseType: "F", responseValue: { message: userError } });
      }
      const response = {
        id: user.id,
        name: user.full_name,
        email: user.email,
        mobile: user.mobile,
        last_login: user.last_activity_at,
        profile_image: user.profile_image_url || null,
        referral_code: user.referral_code || null,
      };
      return res
        .status(200)
        .json({ responseType: "S", responseValue: response });
    } catch (error) {
      return res.status(500).json({
        responseType: "F",
        responseValue: { message: error.toString() },
      });
    }
  },

  /**
   * Update password after verifying current password.
   * Body: { id, password, newPassword }
   */
  updatePassword: async (req, res) => {
    const { id, password, newPassword } = req.body;

    if (!id) {
      return res.status(400).json({
        responseType: "F",
        responseValue: { message: "பயனர் ID தேவை!" },
      });
    }

    const idCheck = validateUuid(id, "id");
    if (!idCheck.ok) return sendUuidError(res, idCheck.message);

    const user = await User.findById(id);
    if (!user) {
      return res
        .status(404)
        .json({ responseType: "F", responseValue: { message: userError } });
    }

    const isPasswordValid = await bcrypt.compare(password, user.password_hash);
    if (!isPasswordValid) {
      return res.status(404).json({
        responseType: "F",
        responseValue: {
          message: "கடவுச்சொல் எங்கள் பதிவுகளுடன் பொருந்தவில்லை.",
        },
      });
    }

    // Password and user verified; hash new password
    var hashedPassword = await bcrypt.hash(newPassword, 10);

    var para = {
      password: hashedPassword,
      id: id,
    };

    try {
      var query = await User.updatePassword(para);
      if (query) {
        // Queue push notification when password is changed
        if (user.notification_token) {
          queuePushNotification({
            userId: id,
            title: "கடவுச்சொல் மாற்றப்பட்டது",
            body: "உங்கள் கடவுச்சொல் வெற்றிகரமாக மாற்றப்பட்டது. உங்கள் கணக்கின் பாதுகாப்பை உறுதிப்படுத்த, வழக்கமாக கடவுச்சொல்லை மாற்றவும்.",
            token: user.notification_token,
            type: NotificationType.ACCOUNT,
          });
        }
        recordAuditLog({
          userId: id,
          action: "PASSWORD_UPDATE",
          entityType: "user",
          entityId: id,
          summary: "Password changed",
          req,
        });
        return res.status(200).json({
          responseType: "S",
          responseValue: {
            message: "உங்கள் கடவுச்சொல் வெற்றிகரமாக மாற்றப்பட்டது.",
          },
        });
      } else {
        return res.status(404).json({
          responseType: "F",
          responseValue: {
            message:
              "கடவுச்சொல்லை மாற்ற முடியவில்லை. தயவுசெய்து மீண்டும் முயற்சிக்கவும்.",
          },
        });
      }
    } catch (error) {
      return res.status(500).json({
        responseType: "F",
        responseValue: { message: error.toString() },
      });
    }
  },
  /**
   * Soft delete a user (marks as deleted, doesn't remove from database).
   * Body: { email }
   */
  deleteUser: async (req, res) => {
    const { email } = req.body;
    try {
      const chk = await User.findByEmail(email);
      if (!chk) {
        return res
          .status(404)
          .json({ responseType: "F", responseValue: { message: userError } });
      }
      const query = await User.deleteUser(chk.id);
      if (query) {
        // Remove token from memory when user is deleted (security best practice)
        tokenService.removeToken(chk.id);
        clearAdminUserListCache();
        recordAuditLog({
          userId: chk.id,
          action: "ACCOUNT_DELETE",
          entityType: "user",
          entityId: chk.id,
          summary: "Account soft deleted",
          metadata: { email: chk.email || email || null },
          req,
        });
        return res.status(200).json({
          responseType: "S",
          responseValue: { message: "பயனர் கணக்கு நீக்கப்பட்டது." },
        });
      } else {
        return res.status(404).json({
          responseType: "F",
          responseValue: { message: "பயனர் நீக்குதல் தோல்வியடைந்தது!" },
        });
      }
    } catch (error) {
      return res.status(500).json({
        responseType: "F",
        responseValue: { message: error.toString() },
      });
    }
  },

  /**
   * Restore a deleted user account by email.
   * Body: { email }
   */
  restoreAccount: async (req, res) => {
    const { email } = req.body;
    try {
      if (!email) {
        return res.status(400).json({
          responseType: "F",
          responseValue: { message: "மின்னஞ்சல் தேவையானது!" },
        });
      }

      // Check if user exists (including deleted)
      const user = await User.findByEmailIncludingDeleted(email);
      if (!user) {
        return res.status(404).json({
          responseType: "F",
          responseValue: { message: "தவறான மின்னஞ்சல் ஐடி!" },
        });
      }

      // Check if user is actually deleted
      if (!user.is_deleted) {
        return res.status(400).json({
          responseType: "F",
          responseValue: {
            message: "இந்த கணக்கு ஏற்கனவே செயல்படுத்தப்பட்டுவிட்டது.",
          },
        });
      }

      // Restore the user
      const query = await User.restoreUser(user.id);
      if (query) {
        // Fetch restored user
        const restoredUser = await User.findById(user.id);
        const response = {
          id: restoredUser.id,
          name: restoredUser.full_name,
          email: restoredUser.email,
          status: restoredUser.status,
          message:
            "உங்கள் கணக்கு வெற்றிகரமாக மீட்டமைக்கப்பட்டது. இப்போது நீங்கள் உள்நுழைய முடியும்.",
        };
        recordAuditLog({
          userId: user.id,
          action: "ACCOUNT_RESTORE",
          entityType: "user",
          entityId: user.id,
          summary: "Account restored",
          metadata: { email: restoredUser?.email || email || null },
          req,
        });
        return res
          .status(200)
          .json({ responseType: "S", responseValue: response });
      } else {
        return res.status(500).json({
          responseType: "F",
          responseValue: { message: "கணக்கு மீட்டமைப்பு தோல்வியடைந்தது!" },
        });
      }
    } catch (error) {
      return res.status(500).json({
        responseType: "F",
        responseValue: { message: error.toString() },
      });
    }
  },
  /**
   * Reset password by email (admin/forgot password flow).
   * Body: { email, password }
   */
  resetPassword: async (req, res) => {
    const { email, password } = req.body;

    const user = await User.findByEmail(email);
    if (!user) {
      return res
        .status(404)
        .json({ responseType: "F", responseValue: { message: userError } });
    }

    if (isInactiveStatus(user.status)) {
      return sendInactiveError(res);
    }

    // Hash the provided password
    var hashedPassword = await bcrypt.hash(password, 10);

    var para = {
      password: hashedPassword,
      id: user.id,
    };

    try {
      var query = await User.updatePassword(para);
      if (query) {
        // Queue push notification when password is reset
        if (user.notification_token) {
          queuePushNotification({
            userId: user.id,
            title: "கடவுச்சொல் மீட்டமைக்கப்பட்டது",
            body: "உங்கள் கடவுச்சொல் வெற்றிகரமாக மீட்டமைக்கப்பட்டது. உங்கள் கணக்கின் பாதுகாப்பை உறுதிப்படுத்த, வழக்கமாக கடவுச்சொல்லை மாற்றவும்.",
            token: user.notification_token,
            type: NotificationType.ACCOUNT,
          });
        }
        recordAuditLog({
          userId: user.id,
          action: "PASSWORD_RESET",
          entityType: "user",
          entityId: user.id,
          summary: "Password reset",
          metadata: { email: user.email || email || null },
          req,
        });
        return res.status(200).json({
          responseType: "S",
          responseValue: {
            message: "உங்கள் கடவுச்சொல் வெற்றிகரமாக மீட்டமைக்கப்பட்டது.",
          },
        });
      } else {
        return res.status(404).json({
          responseType: "F",
          responseValue: { message: "கடவுச்சொல்லை மீட்டமைக்க முடியவில்லை." },
        });
      }
    } catch (error) {
      return res.status(500).json({
        responseType: "F",
        responseValue: { message: error.toString() },
      });
    }
  },

  /**
   * Update push notification token for a user.
   * Body: { userId, token }
   */
  updateNotificationToken: async (req, res) => {
    const userId = req.user?.userId;
    const {
      token,
      device_id,
      device_name,
      brand,
      manufacturer,
      model,
      android_version,
      ram_size,
      platform,
      app_version,
      appVersion,
    } = req.body;

    if (!userId) {
      return res.status(401).json({
        responseType: "F",
        responseValue: { message: "JWT டோக்கன் தேவையானது." },
      });
    }

    if (!token || !device_id) {
      return res.status(400).json({
        responseType: "F",
        responseValue: { message: "device_id and token are required!" },
      });
    }

    const tokenValue = String(token).trim();
    if (tokenValue.length < 20 || tokenValue.length > 4096) {
      return res.status(400).json({
        responseType: "F",
        responseValue: { message: "Invalid FCM token." },
      });
    }

    const user = await User.findById(userId);
    if (!user) {
      return res
        .status(404)
        .json({ responseType: "F", responseValue: { message: userError } });
    }

    try {
      const query = await User.updateToken(
        userId,
        device_id,
        tokenValue,
        device_name ?? null,
        brand ?? null,
        manufacturer ?? null,
        model ?? null,
        android_version ?? null,
        ram_size ?? null,
        {
          platform: platform || "android",
          app_version: app_version || appVersion || null,
        },
      );

      if (query && !query.error) {
        logger.info("Device registration successful", { userId: String(userId) });
        recordAuditLog({
          userId,
          action: "DEVICE_REGISTER",
          entityType: "device",
          entityId: device_id || null,
          summary: "Device registered or refreshed",
          metadata: {
            device_name: device_name || null,
            platform: platform || "android",
            app_version: app_version || appVersion || null,
          },
          deviceId: device_id || null,
          req,
        });
        return res.status(200).json({
          responseType: "S",
          responseValue: {
            message: "பயனர் டோக்கன் வெற்றிகரமாக புதுப்பிக்கப்பட்டது.",
          },
        });
      } else {
        return res.status(404).json({
          responseType: "F",
          responseValue: {
            message: "பயனர் டோக்கன் புதுப்பித்தல் தோல்வியடைந்தது!",
          },
        });
      }
    } catch (error) {
      logger.error("Device registration failed", {
        userId: String(userId),
        error: error?.message || String(error),
      });
      return res.status(500).json({
        responseType: "F",
        responseValue: { message: error.toString() },
      });
    }
  },

  /**
   * Update user profile picture in user_profile table.
   * Body: { userId }
   * File: profile image file (multipart/form-data with field name 'profile_image')
   * Schema: user_profile table with profile_image_url column
   * Note: Multer is already configured in the route, so req.file is ready here.
   */
  updateProfilePicture: async (req, res) => {
    const uploadDir = process.env.UPLOAD_DIR || "./uploads";

    try {
      // Debug logging
      logger.info(
        `Profile picture update request received. File exists: ${!!req.file}, Body: ${JSON.stringify(req.body)}`,
      );

      // Check for file from multer (already processed by route middleware)
      if (!req.file) {
        logger.warn("No file received in profile picture upload request");
        return res.status(400).json({
          responseType: "F",
          responseValue: {
            message:
              "கோப்பு பதிவேற்றப்படவில்லை! தயவுசெய்து ஒரு சுயவிவர படத்தை பதிவேற்றவும்.",
          },
        });
      }

      const { userId } = req.body;

      if (!userId) {
        // Clean up uploaded file if userId is missing
        try {
          if (req.file.path && fs.existsSync(req.file.path)) {
            fs.unlinkSync(req.file.path);
          }
        } catch (cleanupError) {
          logger.error(
            "Error cleaning up file after userId validation:",
            cleanupError,
          );
        }

        return res.status(400).json({
          responseType: "F",
          responseValue: { message: "பயனர் ஐடி தேவையானது!" },
        });
      }

      const idCheck = validateUuid(userId, "userId");
      if (!idCheck.ok) {
        try {
          if (req.file.path && fs.existsSync(req.file.path)) {
            fs.unlinkSync(req.file.path);
          }
        } catch (_) { }
        return sendUuidError(res, idCheck.message);
      }

      // Verify user exists
      const user = await User.findById(userId);
      if (!user) {
        // Clean up uploaded file if user doesn't exist
        try {
          if (req.file.path && fs.existsSync(req.file.path)) {
            fs.unlinkSync(req.file.path);
          }
        } catch (cleanupError) {
          logger.error(
            "Error cleaning up file after user validation:",
            cleanupError,
          );
        }

        return res.status(404).json({
          responseType: "F",
          responseValue: { message: userError },
        });
      }

      logger.info(
        `Processing profile picture for user ${userId}. Filename: ${req.file.filename}`,
      );

      // Create profile directory for user
      const userProfileDir = path.join(uploadDir, userId, "profile");
      if (!fs.existsSync(userProfileDir)) {
        fs.mkdirSync(userProfileDir, { recursive: true });
      }

      // Delete old profile image if it exists (from user_profile table)
      if (user.profile_image_url) {
        try {
          const oldImagePath = path.join(
            uploadDir,
            user.profile_image_url.replace("uploads/", ""),
          );
          if (fs.existsSync(oldImagePath)) {
            fs.unlinkSync(oldImagePath);
            logger.info(
              `Deleted old profile image for user ${userId}: ${oldImagePath}`,
            );
          }
        } catch (deleteError) {
          logger.error("Error deleting old profile image:", deleteError);
          // Continue even if old image deletion fails
        }
      }

      // Move uploaded file from temp to final location
      const tempFilePath = req.file.path;
      const finalFilePath = path.join(userProfileDir, req.file.filename);

      try {
        // Move the file
        fs.renameSync(tempFilePath, finalFilePath);

        // Verify file was moved successfully
        if (!fs.existsSync(finalFilePath)) {
          logger.error(`File move verification failed for ${finalFilePath}`);
          return res.status(500).json({
            responseType: "F",
            responseValue: { message: "கோப்பு வெற்றிகரமாக சேமிக்கப்படவில்லை!" },
          });
        }

        logger.info(`File successfully moved to ${finalFilePath}`);

        // Save path to database (use forward slashes for URL-friendly path)
        // Format: uploads/userId/profile/filename.jpg
        const imagePath = `uploads/${userId}/profile/${req.file.filename}`;

        // Update profile_image_url in user_profile table
        const updateResult = await User.updateProfileImage(userId, imagePath);

        if (updateResult) {
          logger.info(
            `Profile image updated in database for user ${userId}: ${imagePath}`,
          );

          // Fetch updated user data to return complete profile
          const updatedUser = await User.findById(userId);

          const userProfile = {
            id: updatedUser.id,
            name: updatedUser.full_name,
            email: updatedUser.email,
            mobile: updatedUser.mobile,
            profile_image_url: updatedUser.profile_image_url || imagePath,
            gender: updatedUser.gender || null,
            date_of_birth: updatedUser.date_of_birth || null,
            address_line1: updatedUser.address_line1 || null,
            address_line2: updatedUser.address_line2 || null,
            city: updatedUser.city || null,
            state: updatedUser.state || null,
            country: updatedUser.country || null,
            postal_code: updatedUser.postal_code || null,
          };

          recordAuditLog({
            userId,
            action: "PROFILE_PHOTO_UPDATE",
            entityType: "user",
            entityId: userId,
            summary: "Profile photo updated",
            req,
          });

          return res.status(200).json({
            responseType: "S",
            responseValue: {
              message: "சுயவிவர படம் வெற்றிகரமாக புதுப்பிக்கப்பட்டது.",
              profile: userProfile,
            },
          });
        } else {
          logger.error(`Database update failed for user ${userId}`);

          // If database update fails, try to clean up the uploaded file
          try {
            if (fs.existsSync(finalFilePath)) {
              fs.unlinkSync(finalFilePath);
            }
          } catch (cleanupError) {
            logger.error(
              "Error cleaning up file after DB update failure:",
              cleanupError,
            );
          }
          return res.status(500).json({
            responseType: "F",
            responseValue: {
              message: "தரவுத்தளத்தில் சுயவிவர படத்தை புதுப்பிக்க முடியவில்லை.",
            },
          });
        }
      } catch (moveError) {
        logger.error("Error moving file:", moveError);
        // Clean up temp file
        try {
          if (fs.existsSync(tempFilePath)) {
            fs.unlinkSync(tempFilePath);
          }
        } catch (cleanupError) {
          logger.error("Error cleaning up temp file:", cleanupError);
        }

        return res.status(500).json({
          responseType: "F",
          responseValue: {
            message: `கோப்பை சேமிக்க முடியவில்லை: ${moveError.message}`,
          },
        });
      }
    } catch (error) {
      logger.error("Error in updateProfilePicture:", error);

      // Clean up temp file if it exists
      try {
        if (req.file && req.file.path && fs.existsSync(req.file.path)) {
          fs.unlinkSync(req.file.path);
        }
      } catch (cleanupError) {
        logger.error("Error cleaning up temp file on error:", cleanupError);
      }

      return res.status(500).json({
        responseType: "F",
        responseValue: { message: error.toString() },
      });
    }
  },

  /**
   * Remove user profile picture (clear DB path and delete file).
   * Body: { userId }
   */
  removeProfilePicture: async (req, res) => {
    const uploadDir = process.env.UPLOAD_DIR || "./uploads";

    try {
      const userId = req.body?.userId || req.user?.userId;
      if (!userId) {
        return res.status(400).json({
          responseType: "F",
          responseValue: { message: "User ID is required!" },
        });
      }

      const idCheck = validateUuid(userId, "userId");
      if (!idCheck.ok) return sendUuidError(res, idCheck.message);

      const user = await User.findById(userId);
      if (!user) {
        return res.status(404).json({
          responseType: "F",
          responseValue: { message: userError },
        });
      }

      const oldImagePath = user.profile_image_url || null;
      if (oldImagePath) {
        try {
          const absolutePath = path.join(
            uploadDir,
            String(oldImagePath).replace(/^uploads\//, ""),
          );
          if (fs.existsSync(absolutePath)) {
            fs.unlinkSync(absolutePath);
            logger.info(`Deleted profile image for user ${userId}: ${absolutePath}`);
          }
        } catch (deleteError) {
          logger.error("Error deleting profile image file:", deleteError);
        }
      }

      await User.updateProfileImage(userId, null);

      recordAuditLog({
        userId,
        action: "PROFILE_PHOTO_UPDATE",
        entityType: "user",
        entityId: userId,
        summary: "Profile photo removed",
        req,
      });

      return res.status(200).json({
        responseType: "S",
        responseValue: {
          message: "Profile photo removed successfully.",
          profile_image_url: null,
          profile_image: null,
        },
      });
    } catch (error) {
      logger.error("Error in removeProfilePicture:", error);
      return res.status(500).json({
        responseType: "F",
        responseValue: { message: error.toString() },
      });
    }
  },

  /**
   * Get important user details from users table.
   * Params: { id }
   */
  getImportantUserDetails: async (req, res) => {
    const userId = req.params.id;
    try {
      const idCheck = validateUuid(userId, "id");
      if (!idCheck.ok) return sendUuidError(res, idCheck.message);

      const details = await User.getPublicDetails(userId);
      if (!details) {
        return res
          .status(404)
          .json({ responseType: "F", responseValue: { message: userError } });
      }

      return res
        .status(200)
        .json({ responseType: "S", responseValue: formatPublicUserDetails(details) });
    } catch (error) {
      return res.status(500).json({
        responseType: "F",
        responseValue: { message: error.toString() },
      });
    }
  },

  /**
   * Get referral code for a user.
   * Query: ?id=<userId> or ?email=<email>
   */
  getReferralCode: async (req, res) => {
    const { id, email } = req.query;
    try {
      let user = null;
      if (id) {
        const idCheck = validateUuid(id, "id");
        if (!idCheck.ok) return sendUuidError(res, idCheck.message);
        user = await User.findById(id);
      } else if (email) {
        user = await User.findByEmail(email);
      } else {
        return res.status(400).json({
          responseType: "F",
          responseValue: {
            message: "பயனர் ஐடி அல்லது மின்னஞ்சல் சேர்க்கவும்.",
          },
        });
      }

      if (!user) {
        return res
          .status(404)
          .json({ responseType: "F", responseValue: { message: userError } });
      }

      return res.status(200).json({
        responseType: "S",
        responseValue: { referral_code: user.referral_code || null },
      });
    } catch (error) {
      return res.status(500).json({
        responseType: "F",
        responseValue: { message: error.toString() },
      });
    }
  },

  /**
   * ADMIN: retrieve a list of all users with public details.
   * returns minimal fields for the admin user list.
   */
  adminAllUserLists: async (req, res) => {
    try {
      const pageNum = Math.max(1, parseInt(req.query.page, 10) || 1);
      const pageSize = Math.min(100, Math.max(1, parseInt(req.query.limit, 10) || 30));
      const offset = (pageNum - 1) * pageSize;

      const { rows, total } = await User.getAllPublicDetails({
        limit: pageSize,
        offset,
      });
      const formatted = rows.map(formatAdminUserListItem);
      const hasMore = offset + formatted.length < total;

      return res.status(200).json({
        responseType: "S",
        count: total,
        page: pageNum,
        limit: pageSize,
        hasMore,
        responseValue: formatted,
      });
    } catch (error) {
      logger.error('adminAllUserLists failure', error);
      return res.status(500).json({
        responseType: "F",
        responseValue: { message: error.toString() },
      });
    }
  },

  /**
   * ADMIN: retrieve a single user with the same shape used in adminAllUserLists.
   */
  adminUserDetails: async (req, res) => {
    const userId = req.params.id;
    try {
      const idCheck = validateUuid(userId, "id");
      if (!idCheck.ok) return sendUuidError(res, idCheck.message);

      const details = await User.getPublicDetails(userId);
      if (!details) {
        return res
          .status(404)
          .json({ responseType: "F", responseValue: { message: userError } });
      }

      return res.status(200).json({
        responseType: "S",
        responseValue: formatAdminUserDetails(details),
      });
    } catch (error) {
      logger.error("adminUserDetails failure", error);
      return res.status(500).json({
        responseType: "F",
        responseValue: { message: error.toString() },
      });
    }
  },

  /**
   * ADMIN: activate or deactivate an app user.
   * Body: { userId, status } where status is ACTIVE or INACTIVE
   */
  adminUpdateUserStatus: async (req, res) => {
    const userId = req.body?.userId || req.body?.id || req.params?.id;
    const status = req.body?.status;

    const idCheck = validateUuid(userId, "userId");
    if (!idCheck.ok) return sendUuidError(res, idCheck.message);

    const normalized = String(status || "").toUpperCase();
    if (!["ACTIVE", "INACTIVE"].includes(normalized)) {
      return res.status(400).json({
        responseType: "F",
        responseValue: { message: "status must be ACTIVE or INACTIVE." },
      });
    }

    try {
      const user = await User.findById(userId);
      if (!user) {
        return res.status(404).json({
          responseType: "F",
          responseValue: { message: userError },
        });
      }

      const result = await User.updateStatus(userId, normalized);
      if (!result || result.affectedRows < 1) {
        return res.status(404).json({
          responseType: "F",
          responseValue: { message: "Could not update user status." },
        });
      }

      if (normalized === "INACTIVE") {
        try {
          tokenService.removeToken(userId);
        } catch (tokenErr) {
          logger.warn("Failed to invalidate token after deactivate:", tokenErr);
        }
        try {
          await SessionModel.endSession(userId);
        } catch (sessionErr) {
          logger.warn("Failed to end session after deactivate:", sessionErr);
        }
      }

      clearAdminUserListCache();

      return res.status(200).json({
        responseType: "S",
        responseValue: {
          message:
            normalized === "INACTIVE"
              ? "User deactivated. They cannot log in or reset password until reactivated."
              : "User activated. They can log in from the mobile app.",
          userId: String(userId),
          status: normalized,
        },
      });
    } catch (error) {
      logger.error("adminUpdateUserStatus failure", error);
      return res.status(500).json({
        responseType: "F",
        responseValue: { message: error.toString() },
      });
    }
  },

  /**
   * ADMIN: soft-delete (keep related records) or permanently wipe a user.
   * Body: { userId, mode: "soft" | "permanent" }
   */
  adminDeleteUser: async (req, res) => {
    const userId = req.body?.userId || req.body?.id || req.params?.id;
    const mode = String(req.body?.mode || "").toLowerCase();

    const idCheck = validateUuid(userId, "userId");
    if (!idCheck.ok) return sendUuidError(res, idCheck.message);

    if (!["soft", "permanent"].includes(mode)) {
      return res.status(400).json({
        responseType: "F",
        responseValue: { message: "mode must be soft or permanent." },
      });
    }

    try {
      const user = await User.findByIdIncludingDeleted(userId);
      if (!user) {
        return res.status(404).json({
          responseType: "F",
          responseValue: { message: userError },
        });
      }

      if (mode === "soft") {
        if (
          user.is_deleted === 1 ||
          user.is_deleted === true ||
          String(user.status || "").toUpperCase() === "DELETED"
        ) {
          return res.status(400).json({
            responseType: "F",
            responseValue: { message: "User is already soft deleted." },
          });
        }

        const result = await User.deleteUser(userId);
        if (!result || result.affectedRows < 1) {
          return res.status(404).json({
            responseType: "F",
            responseValue: { message: "Could not delete user." },
          });
        }
      } else {
        const result = await User.hardDeleteUser(userId);
        if (!result || result.affectedRows < 1) {
          return res.status(404).json({
            responseType: "F",
            responseValue: { message: "Could not permanently delete user." },
          });
        }
      }

      try {
        tokenService.removeToken(userId);
      } catch (tokenErr) {
        logger.warn("Failed to invalidate token after admin delete:", tokenErr);
      }

      if (mode === "soft") {
        try {
          await SessionModel.endSession(userId);
        } catch (sessionErr) {
          logger.warn("Failed to end session after admin delete:", sessionErr);
        }
      }

      clearAdminUserListCache();

      return res.status(200).json({
        responseType: "S",
        responseValue: {
          message:
            mode === "permanent"
              ? "User and related records were permanently deleted."
              : "User was soft deleted. Related records were kept.",
          userId: String(userId),
          mode,
        },
      });
    } catch (error) {
      logger.error("adminDeleteUser failure", error);
      return res.status(500).json({
        responseType: "F",
        responseValue: { message: error.toString() },
      });
    }
  },

  /**
   * ADMIN LOGIN - Authenticate administrator and issue JWT.
   * Body: { identifier / email / mobile, password }
   */
  adminLogin: async (req, res) => {
    const { identifier, email, mobile, password } = req.body;
    const loginIdentifier = identifier || email || mobile;

    if (!loginIdentifier || !password) {
      return res.status(400).json({
        responseType: "F",
        responseValue: { message: "மின்னஞ்சல்/கைபேசி எண் மற்றும் கடவுச்சொல் தேவை!" },
      });
    }

    try {
      let user = await Admin.findByIdentifier(loginIdentifier);
      if (!user) {
        const deletedUser = await Admin.findByIdentifierIncludingDeleted(loginIdentifier);
        if (deletedUser && (deletedUser.is_deleted === 1 || deletedUser.is_deleted === true)) {
          return res.status(403).json({
            responseType: "F",
            responseValue: {
              message:
                "உங்கள் கணக்கு நீக்கப்பட்டுவிட்டது. மீட்டமைக்க எங்களை தொடர்பு கொள்ளவும்.",
              deleted_at: deletedUser.deleted_at,
              account_status: "DELETED",
            },
          });
        }
        return res.status(404).json({
          responseType: "F",
          responseValue: { message: "தவறான மின்னஞ்சல் அல்லது கைபேசி எண்!" },
        });
      }

      // Check account active/inactive status
      if (user.status === 'INACTIVE') {
        return res.status(403).json({
          responseType: "F",
          responseValue: {
            message: "உங்கள் கணக்கு செயலிழக்கப்பட்டுள்ளது. தயவுசெய்து நிர்வாகியை தொடர்பு கொள்ளவும்.",
            account_status: "INACTIVE",
          },
        });
      }

      // Check login block / lock status
      try {
        const blockStatus = await Admin.getLoginBlockStatus(user.id);
        if (blockStatus.is_blocked) {
          const blockedUntilDate = blockStatus.blocked_until ? new Date(blockStatus.blocked_until) : null;
          const minutesRemaining = blockedUntilDate
            ? Math.max(1, Math.ceil((blockedUntilDate - new Date()) / (1000 * 60)))
            : null;

          const msg = minutesRemaining
            ? `மிக அதிக தோல்வி முயற்சிகள். ${minutesRemaining} நிமிடங்களில் மீண்டும் முயற்சி செய்க.`
            : "உங்கள் கணக்கு முடக்கப்பட்ட முறையில் உள்ளது. நிர்வாகியை தொடர்பு கொள்ளவும்.";

          return res.status(429).json({
            responseType: "F",
            responseValue: {
              message: msg,
              retry_after_minutes: minutesRemaining,
              blocked_until: blockStatus.blocked_until,
              account_status: "BLOCKED",
            },
          });
        }
      } catch (blockErr) {
        logger.warn("adminLogin block check error", blockErr);
      }

      const isPasswordValid = await bcrypt.compare(
        password,
        user.password_hash,
      );

      if (!isPasswordValid) {
        try {
          const failureStatus = await Admin.incrementFailedLoginAttempts(user.id);
          if (failureStatus.blocked) {
            return res.status(429).json({
              responseType: "F",
              responseValue: {
                message:
                  "மிக அதிக தோல்வி முயற்சிகள் (3 முறை). கணக்கு 15 நிமிடங்களுக்கு தடுக்கப்பட்டுள்ளது.",
                error_type: "ACCOUNT_LOCKED",
                attempts_made: 3,
                blocked_until: failureStatus.blocked_until,
                account_status: "BLOCKED",
              },
            });
          } else {
            const attempt = 3 - failureStatus.remaining_attempts;
            return res.status(401).json({
              responseType: "F",
              responseValue: {
                message: `கடவுச்சொல் தவறானது. முயற்சி ${attempt}/3. ${failureStatus.remaining_attempts} முயற்சிகள் மீதமுள்ளது.`,
                error_type: "INVALID_PASSWORD",
                attempt: attempt,
                attempts_remaining: failureStatus.remaining_attempts,
                max_attempts: 3,
              },
            });
          }
        } catch (err) {
          logger.warn("adminLogin failureStatus error", err);
          return res.status(401).json({
            responseType: "F",
            responseValue: { message: "கடவுச்சொல் தவறானது." },
          });
        }
      }

      // Successful password match: reset attempts and unlock status to ACTIVE
      try {
        await Admin.resetFailedLoginAttempts(user.id);
      } catch (err) {
        logger.warn("Failed to reset admin login attempts:", err);
      }

      const userID = user.id;

      // Check if MFA is enabled for this admin
      try {
        const mfaRecord = await MFA.findByUserId(userID, 'admin');
        if (mfaRecord && mfaRecord.is_enabled === 1) {
          return res.status(200).json({
            responseType: "S",
            responseValue: {
              mfa_required: true,
              is_mfa_required: true,
              user_id: userID,
              userId: userID,
              account_type: 'admin',
              accountType: 'admin',
              message: "MFA challenge required. Please enter your TOTP verification code or backup code."
            }
          });
        }
      } catch (mfaErr) {
        logger.warn("adminLogin MFA check error:", mfaErr);
      }

      tokenService.invalidatePreviousToken(userID);
      const { accessToken, refreshToken } = tokenService.generateTokenPair(userID);
      logger.debug(`admin login for ${userID}, token generated`);

      const now = new Date();
      if (typeof Admin.updateLastLogin === 'function') {
        try {
          await Admin.updateLastLogin(userID);
        } catch (e) {
          logger.warn('admin updateLastLogin failed', e);
        }
      }

      const response = {
        id: user.id,
        full_name: user.full_name,
        name: user.full_name,
        email: user.email,
        mobile: user.mobile,
        status: 'ACTIVE',
        email_verified_at: user.email_verified_at || null,
        last_login_at: now,
        last_activity_at: now,
        created_at: user.created_at,
        token: accessToken,
        accessToken,
        refreshToken,
      };

      return res
        .status(200)
        .json({ responseType: "S", responseValue: response });
    } catch (error) {
      logger.error("Error during admin login:", error);
      return res.status(500).json({
        responseType: "F",
        responseValue: { message: error.toString() },
      });
    }
  },

  /**
   * ADMIN REFRESH TOKEN - issue a new access token from a valid refresh token.
   * Body: { refreshToken }
   * Survives access-token expiry and in-memory session loss after server restart.
   */
  adminRefreshToken: async (req, res) => {
    const refreshToken = req.body?.refreshToken || req.body?.refresh_token;

    if (!refreshToken) {
      return res.status(400).json({
        responseType: "F",
        responseValue: { message: "Refresh token is required." },
      });
    }

    try {
      const decoded = tokenService.verifyRefreshToken(refreshToken);
      const userId = decoded.userId;
      const admin = await Admin.findById(userId);

      if (!admin || admin.is_deleted === 1 || admin.is_deleted === true) {
        tokenService.removeToken(userId);
        return res.status(401).json({
          responseType: "F",
          responseValue: { message: "Invalid refresh token. Please login again." },
        });
      }

      if (isInactiveStatus(admin.status)) {
        tokenService.removeToken(userId);
        return sendInactiveError(res);
      }

      const pair = tokenService.generateTokenPair(userId);
      const now = new Date();

      return res.status(200).json({
        responseType: "S",
        responseValue: {
          id: admin.id,
          full_name: admin.full_name,
          name: admin.full_name,
          email: admin.email,
          mobile: admin.mobile,
          status: admin.status,
          last_login_at: admin.last_login_at || now,
          token: pair.accessToken,
          accessToken: pair.accessToken,
          refreshToken: pair.refreshToken,
        },
      });
    } catch (error) {
      const expired = error?.name === "TokenExpiredError";
      logger.warn("adminRefreshToken failed", { name: error?.name, message: error?.message });
      return res.status(401).json({
        responseType: "F",
        responseValue: {
          message: expired
            ? "Refresh token expired. Please login again."
            : "Invalid refresh token. Please login again.",
        },
      });
    }
  },

  /**
   * ADMIN FORGOT PASSWORD - send reset token via email
   * Body: { identifier / email }
   */
  adminForgotPassword: async (req, res) => {
    const { identifier, email } = req.body;
    const searchParam = identifier || email;

    if (!searchParam) {
      return res.status(400).json({
        responseType: "F",
        responseValue: { message: "மின்னஞ்சல் அல்லது கைபேசி எண் தேவை!" },
      });
    }

    try {
      const admin = await Admin.findByIdentifier(searchParam);
      if (!admin) {
        return res.status(404).json({
          responseType: "F",
          responseValue: { message: "தவறான மின்னஞ்சல் ஐடி!" },
        });
      }

      const token = crypto.randomBytes(32).toString('hex');
      const expires = new Date(Date.now() + 60 * 60 * 1000);
      await Admin.setResetToken(admin.id, token, expires);

      const baseUrl = process.env.ADMIN_RESET_URL || process.env.FRONTEND_URL || 'https://moi-kanakku-api.prasowlabs.in/admin/reset-password';
      const resetLink = baseUrl.includes('?') ? `${baseUrl}&token=${token}` : `${baseUrl}?token=${token}`;
      const html = `<!DOCTYPE html>
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
              <h2 style="margin:0;font-size:22px;">🔐 Password Reset Request</h2>
            </td>
          </tr>

          <tr>
            <td style="padding:30px;color:#333333;">
              <p style="margin:0 0 15px 0;font-size:16px;">
                Hi <strong>${admin.full_name || ''}</strong>,
              </p>

              <p style="margin:0 0 20px 0;font-size:15px;color:#555;">
                You requested a password reset for your administrator account. Please use the button below to choose a new password.
              </p>

              <div style="text-align:center;margin:30px 0;">
                <a href="${resetLink}" style="display:inline-block;background:#2f3490;color:#ffffff;text-decoration:none;padding:14px 28px;border-radius:8px;font-size:16px;font-weight:700;">
                  Reset Password
                </a>
              </div>

              <p style="text-align:center;font-size:14px;color:#666;margin:0;">
                This link will expire in <strong>one hour</strong>.
              </p>

              <p style="margin-top:20px;font-size:14px;color:#777;">
                If you did not request this password reset, please ignore this email.
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

      queueEmail(
        {
          to: admin.email,
          subject: 'Admin password reset',
          html,
        },
        `admin-forgot:${admin.email}`,
      );

      return res.status(200).json({
        responseType: "S",
        responseValue: { message: "கடவுச்சொல் மீட்டமைப்பு விவரங்கள் உங்கள் மின்னஞ்சலுக்கு அனுப்பப்பட்டன." },
      });
    } catch (err) {
      logger.error("Error in adminForgotPassword:", err);
      return res.status(500).json({
        responseType: "F",
        responseValue: { message: err.toString() },
      });
    }
  },

  /**
   * ADMIN RESET PASSWORD - verify token and update password
   * Body: { token, password }
   */
  adminResetPassword: async (req, res) => {
    const { token, password } = req.body;
    if (!token || !password) {
      return res.status(400).json({
        responseType: "F",
        responseValue: { message: "டோக்கன் மற்றும் கடவுச்சொல் தேவை!" },
      });
    }

    try {
      const record = await Admin.findByResetToken(token);
      if (!record) {
        return res.status(400).json({
          responseType: "F",
          responseValue: { message: "தவறான அல்லது காலாவதியான டோக்கன்" },
        });
      }
      if (record.reset_token_expires_at && new Date(record.reset_token_expires_at) < new Date()) {
        return res.status(400).json({
          responseType: "F",
          responseValue: { message: "டோக்கன் காலாவதியாகிவிட்டது" },
        });
      }
      const hashed = await bcrypt.hash(password, 10);
      await Admin.updatePassword({ id: record.id, password: hashed });
      await Admin.clearResetToken(record.id);
      return res.status(200).json({
        responseType: "S",
        responseValue: { message: "கடவுச்சொல் வெற்றிகரமாக மாற்றப்பட்டது" },
      });
    } catch (err) {
      logger.error("Error in adminResetPassword:", err);
      return res.status(500).json({
        responseType: "F",
        responseValue: { message: err.toString() },
      });
    }
  },

  /**
   * ADMIN UPDATE PROFILE - Update logged-in admin's profile
   * Body: { full_name / name, email, mobile }
   */
  adminUpdateProfile: async (req, res) => {
    const adminId = req.admin?.userId || req.user?.userId;
    if (!adminId) {
      return res.status(401).json({
        responseType: "F",
        responseValue: { message: "நிர்வாகி கணக்கு தேவை!" },
      });
    }

    const { full_name, name, email, mobile } = req.body;
    const fullNameUpdate = full_name || name;

    try {
      const currentAdmin = await Admin.findById(adminId);
      if (!currentAdmin) {
        return res.status(404).json({
          responseType: "F",
          responseValue: { message: "நிர்வாகி கணக்கு காணப்படவில்லை!" },
        });
      }

      // Check if updated email or mobile exists in another active admin account
      if (email || mobile) {
        const isConflict = await Admin.checkEmailOrMobileExists(adminId, email, mobile);
        if (isConflict) {
          return res.status(400).json({
            responseType: "F",
            responseValue: { message: "மின்னஞ்சல் அல்லது கைபேசி எண் ஏற்கனவே பயன்படுத்தப்படுகிறது!" },
          });
        }
      }

      await Admin.updateProfile({
        id: adminId,
        full_name: fullNameUpdate,
        email,
        mobile,
      });

      const updatedAdmin = await Admin.findById(adminId);

      return res.status(200).json({
        responseType: "S",
        responseValue: {
          message: "நிர்வாகி விவரங்கள் வெற்றிகரமாக புதுப்பிக்கப்பட்டன.",
          data: {
            id: updatedAdmin.id,
            full_name: updatedAdmin.full_name,
            name: updatedAdmin.full_name,
            email: updatedAdmin.email,
            mobile: updatedAdmin.mobile,
            status: updatedAdmin.status,
            updated_at: updatedAdmin.updated_at,
          },
        },
      });
    } catch (err) {
      logger.error("Error in adminUpdateProfile:", err);
      return res.status(500).json({
        responseType: "F",
        responseValue: { message: err.toString() },
      });
    }
  },

  /**
   * ADMIN CHANGE PASSWORD - Change logged-in admin's password
   * Body: { current_password / old_password, new_password / password }
   */
  adminChangePassword: async (req, res) => {
    const adminId = req.admin?.userId || req.user?.userId;
    if (!adminId) {
      return res.status(401).json({
        responseType: "F",
        responseValue: { message: "நிர்வாகி கணக்கு தேவை!" },
      });
    }

    const { current_password, old_password, new_password, password } = req.body;
    const oldPass = current_password || old_password;
    const newPass = new_password || password;

    if (!oldPass || !newPass) {
      return res.status(400).json({
        responseType: "F",
        responseValue: { message: "தற்போதைய கடவுச்சொல் மற்றும் புதிய கடவுச்சொல் தேவை!" },
      });
    }

    try {
      const admin = await Admin.findById(adminId);
      if (!admin) {
        return res.status(404).json({
          responseType: "F",
          responseValue: { message: "நிர்வாகி கணக்கு காணப்படவில்லை!" },
        });
      }

      const isValid = await bcrypt.compare(oldPass, admin.password_hash);
      if (!isValid) {
        return res.status(400).json({
          responseType: "F",
          responseValue: { message: "தற்போதைய கடவுச்சொல் தவறானது!" },
        });
      }

      const newHashed = await bcrypt.hash(newPass, 10);
      await Admin.updatePassword({ id: adminId, password: newHashed });

      return res.status(200).json({
        responseType: "S",
        responseValue: { message: "கடவுச்சொல் வெற்றிகரமாக மாற்றப்பட்டது." },
      });
    } catch (err) {
      logger.error("Error in adminChangePassword:", err);
      return res.status(500).json({
        responseType: "F",
        responseValue: { message: err.toString() },
      });
    }
  },
};
