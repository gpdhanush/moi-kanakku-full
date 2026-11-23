-- Paid PDF export: one row per UPI payment a user submits for review.
-- An approved row unlocks PDF export for that user (all future exports).
-- IDs follow the production schema (BIGINT UNSIGNED auto-increment).
CREATE TABLE IF NOT EXISTS `export_payments` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `amount` decimal(10,2) NOT NULL DEFAULT 49.00,
  `upi_txn_id` varchar(64) NOT NULL,
  `status` enum('pending','approved','rejected') NOT NULL DEFAULT 'pending',
  `admin_remarks` varchar(500) DEFAULT NULL,
  `reviewed_by` bigint(20) UNSIGNED DEFAULT NULL,
  `reviewed_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_export_payments_upi_txn_id` (`upi_txn_id`),
  KEY `idx_export_payments_user_id` (`user_id`),
  KEY `idx_export_payments_status` (`status`),
  CONSTRAINT `fk_export_payments_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_export_payments_reviewed_by` FOREIGN KEY (`reviewed_by`) REFERENCES `admins` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
