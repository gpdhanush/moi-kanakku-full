-- Safe migration for Google / provider-aware auth support
-- Run against the existing users table without destroying current data.

ALTER TABLE `users`
  ADD COLUMN IF NOT EXISTS `signup_type` ENUM('email', 'google', 'mobile_app', 'admin') NOT NULL DEFAULT 'email' AFTER `status`,
  ADD COLUMN IF NOT EXISTS `google_id` VARCHAR(255) NULL DEFAULT NULL AFTER `signup_type`,
  ADD COLUMN IF NOT EXISTS `password_set` TINYINT(1) NOT NULL DEFAULT 0 AFTER `google_id`,
  ADD COLUMN IF NOT EXISTS `email_verified` TINYINT(1) NOT NULL DEFAULT 0 AFTER `password_set`;

-- Backfill existing users to preserve current behavior and avoid breaking legacy email accounts.
UPDATE `users` u
LEFT JOIN `user_credentials` uc ON uc.user_id = u.id
SET u.signup_type = CASE
  WHEN u.signup_type IS NULL OR u.signup_type = '' THEN 'email'
  ELSE u.signup_type
END,
    u.password_set = CASE
      WHEN uc.password_hash IS NOT NULL AND TRIM(uc.password_hash) <> '' THEN 1
      ELSE 0
    END,
    u.email_verified = CASE
      WHEN u.is_verified = 1 OR u.email_verified_at IS NOT NULL THEN 1
      ELSE 0
    END;

-- Keep Google link data empty unless a Google account is explicitly linked.
-- Existing app users continue to use email-based authentication unless explicitly updated.

-- Optional index for faster provider-based lookups.
ALTER TABLE `users`
  ADD INDEX IF NOT EXISTS `idx_users_signup_type` (`signup_type`),
  ADD INDEX IF NOT EXISTS `idx_users_google_id` (`google_id`);
