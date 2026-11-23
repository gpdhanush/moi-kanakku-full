-- Admin-editable payee details for paid PDF export (single row, id = 1).
-- Values here override EXPORT_PAYMENT_* env vars. qr_image_path is an
-- uploaded QR image (relative "uploads/..." path) shown in the app when set.
CREATE TABLE IF NOT EXISTS `export_payment_settings` (
  `id` tinyint(3) UNSIGNED NOT NULL DEFAULT 1,
  `upi_id` varchar(100) DEFAULT NULL,
  `payee_name` varchar(100) DEFAULT NULL,
  `amount` decimal(10,2) NOT NULL DEFAULT 49.00,
  `qr_image_path` varchar(255) DEFAULT NULL,
  `updated_by` bigint(20) UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_export_payment_settings_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `admins` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
