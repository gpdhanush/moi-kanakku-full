-- user_devices install / uninstall tracking
-- Run this on production BEFORE deploying the backend that reads these columns.
-- Existing rows stay. Absence of a device row still means Unknown, not Uninstalled.

-- UP
ALTER TABLE `user_devices`
  ADD COLUMN `platform` VARCHAR(20) NOT NULL DEFAULT 'android' AFTER `android_version`,
  ADD COLUMN `app_version` VARCHAR(32) DEFAULT NULL AFTER `platform`,
  ADD COLUMN `token_status` ENUM('active','invalid') NOT NULL DEFAULT 'active' AFTER `is_active`,
  ADD COLUMN `uninstalled_at` DATETIME DEFAULT NULL AFTER `last_used_at`;

UPDATE `user_devices`
SET `token_status` = 'invalid',
    `uninstalled_at` = COALESCE(`uninstalled_at`, `updated_at`)
WHERE `is_active` = 0
  AND (`token_status` IS NULL OR `token_status` = 'active');

ALTER TABLE `user_devices`
  ADD INDEX `idx_ud_token_status` (`token_status`);

-- DOWN (run only if you need to reverse this change)
-- ALTER TABLE `user_devices` DROP INDEX `idx_ud_token_status`;
-- ALTER TABLE `user_devices`
--   DROP COLUMN `uninstalled_at`,
--   DROP COLUMN `token_status`,
--   DROP COLUMN `app_version`,
--   DROP COLUMN `platform`;
