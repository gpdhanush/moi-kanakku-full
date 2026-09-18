-- Mobile user audit logs
-- Run this on production BEFORE relying on the admin Audit Logs feature.
-- Missing table is handled softly by the backend helper (APIs keep working).

-- UP
CREATE TABLE IF NOT EXISTS `user_audit_logs` (
  `id` BIGINT(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT(20) UNSIGNED NOT NULL,
  `action` VARCHAR(64) NOT NULL,
  `entity_type` VARCHAR(64) DEFAULT NULL,
  `entity_id` VARCHAR(64) DEFAULT NULL,
  `summary` VARCHAR(255) NOT NULL,
  `metadata` JSON DEFAULT NULL,
  `ip_address` VARCHAR(64) DEFAULT NULL,
  `user_agent` VARCHAR(255) DEFAULT NULL,
  `device_id` VARCHAR(500) DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_ual_user_created` (`user_id`, `created_at`),
  KEY `idx_ual_action_created` (`action`, `created_at`),
  KEY `idx_ual_created` (`created_at`),
  CONSTRAINT `fk_ual_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- DOWN (run only if you need to reverse this change)
-- ALTER TABLE `user_audit_logs` DROP FOREIGN KEY `fk_ual_user`;
-- DROP TABLE IF EXISTS `user_audit_logs`;
