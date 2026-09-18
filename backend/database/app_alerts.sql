-- In-app popup alerts (admin campaigns) + per-user dismiss / remind-later state.
-- Run on production before using App Alerts in admin / mobile.

-- UP
CREATE TABLE IF NOT EXISTS `app_alerts` (
  `id` BIGINT(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `title` VARCHAR(255) NOT NULL,
  `content` TEXT NOT NULL,
  `image_url` VARCHAR(500) DEFAULT NULL,
  `video_url` VARCHAR(500) DEFAULT NULL,
  `cta_label` VARCHAR(120) DEFAULT NULL,
  `cta_url` VARCHAR(500) DEFAULT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `starts_at` DATETIME DEFAULT NULL,
  `ends_at` DATETIME DEFAULT NULL,
  `created_by_admin_id` BIGINT(20) UNSIGNED DEFAULT NULL,
  `is_deleted` TINYINT(1) NOT NULL DEFAULT 0,
  `deleted_at` DATETIME DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_app_alerts_active_created` (`is_active`, `is_deleted`, `created_at`),
  KEY `idx_app_alerts_window` (`starts_at`, `ends_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `app_alert_user_states` (
  `id` BIGINT(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `alert_id` BIGINT(20) UNSIGNED NOT NULL,
  `user_id` BIGINT(20) UNSIGNED NOT NULL,
  `status` ENUM('dont_show', 'remind_later') NOT NULL,
  `remind_at` DATETIME DEFAULT NULL,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_app_alert_user` (`alert_id`, `user_id`),
  KEY `idx_app_alert_user_status` (`user_id`, `status`, `remind_at`),
  CONSTRAINT `fk_app_alert_state_alert` FOREIGN KEY (`alert_id`) REFERENCES `app_alerts` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_app_alert_state_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- DOWN
-- ALTER TABLE `app_alert_user_states` DROP FOREIGN KEY `fk_app_alert_state_alert`;
-- ALTER TABLE `app_alert_user_states` DROP FOREIGN KEY `fk_app_alert_state_user`;
-- DROP TABLE IF EXISTS `app_alert_user_states`;
-- DROP TABLE IF EXISTS `app_alerts`;
