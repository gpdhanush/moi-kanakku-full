-- ========================================================
-- MOI KANAKKU FRANCHISE MANAGEMENT SYSTEM MIGRATION
-- Safe & Additive Migration Script
-- ========================================================

-- 1. FRANCHISES TABLE
CREATE TABLE IF NOT EXISTS `franchises` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` varchar(150) NOT NULL,
  `code` varchar(50) NOT NULL,
  `mobile` varchar(20) DEFAULT NULL,
  `email` varchar(150) DEFAULT NULL,
  `address` text DEFAULT NULL,
  `city` varchar(100) DEFAULT NULL,
  `state` varchar(100) DEFAULT NULL,
  `pincode` varchar(20) DEFAULT NULL,
  `status` enum('ACTIVE','INACTIVE','SUSPENDED','CLOSED') NOT NULL DEFAULT 'ACTIVE',
  `is_deleted` tinyint(1) NOT NULL DEFAULT 0,
  `deleted_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_franchises_code` (`code`),
  KEY `idx_franchises_status` (`status`,`is_deleted`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. FRANCHISE ADMINS TABLE
CREATE TABLE IF NOT EXISTS `franchise_admins` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `franchise_id` bigint(20) UNSIGNED NOT NULL,
  `admin_id` bigint(20) UNSIGNED NOT NULL,
  `status` enum('ACTIVE','INACTIVE','REVOKED') NOT NULL DEFAULT 'ACTIVE',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_franchise_admin` (`franchise_id`,`admin_id`),
  KEY `idx_fa_franchise_status` (`franchise_id`,`status`),
  KEY `idx_fa_admin` (`admin_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. FRANCHISE STAFF TABLE
CREATE TABLE IF NOT EXISTS `franchise_staff` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `franchise_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `status` enum('ACTIVE','INACTIVE','REVOKED') NOT NULL DEFAULT 'ACTIVE',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_franchise_staff` (`franchise_id`,`user_id`),
  KEY `idx_fs_franchise_status` (`franchise_id`,`status`),
  KEY `idx_fs_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. FRANCHISE CUSTOMERS TABLE
CREATE TABLE IF NOT EXISTS `franchise_customers` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `franchise_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `customer_code` varchar(50) DEFAULT NULL,
  `status` enum('ACTIVE','INACTIVE','BLOCKED','REMOVED') NOT NULL DEFAULT 'ACTIVE',
  `joined_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `removed_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_franchise_customer` (`franchise_id`,`user_id`),
  UNIQUE KEY `uk_franchise_customer_code` (`franchise_id`,`customer_code`),
  KEY `idx_fc_franchise_status` (`franchise_id`,`status`),
  KEY `idx_fc_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. FRANCHISE FUNCTIONS TABLE
CREATE TABLE IF NOT EXISTS `franchise_functions` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `franchise_id` bigint(20) UNSIGNED NOT NULL,
  `function_id` bigint(20) UNSIGNED NOT NULL,
  `customer_user_id` bigint(20) UNSIGNED NOT NULL,
  `status` enum('ACTIVE','COMPLETED','ARCHIVED','REVOKED') NOT NULL DEFAULT 'ACTIVE',
  `created_by_admin_id` bigint(20) UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_franchise_function` (`franchise_id`,`function_id`),
  KEY `idx_ff_customer` (`franchise_id`,`customer_user_id`),
  KEY `idx_ff_status` (`franchise_id`,`status`),
  KEY `idx_ff_function` (`function_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. FRANCHISE STAFF FUNCTION ACCESS TABLE
CREATE TABLE IF NOT EXISTS `franchise_staff_function_access` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `franchise_id` bigint(20) UNSIGNED NOT NULL,
  `staff_user_id` bigint(20) UNSIGNED NOT NULL,
  `function_id` bigint(20) UNSIGNED NOT NULL,
  `status` enum('ACTIVE','REVOKED') NOT NULL DEFAULT 'ACTIVE',
  `can_view` tinyint(1) NOT NULL DEFAULT 1,
  `can_add_customer` tinyint(1) NOT NULL DEFAULT 0,
  `can_edit_customer` tinyint(1) NOT NULL DEFAULT 0,
  `can_add_transaction` tinyint(1) NOT NULL DEFAULT 1,
  `can_edit_transaction` tinyint(1) NOT NULL DEFAULT 0,
  `can_delete_transaction` tinyint(1) NOT NULL DEFAULT 0,
  `can_view_report` tinyint(1) NOT NULL DEFAULT 0,
  `created_by_admin_id` bigint(20) UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_staff_function` (`franchise_id`,`staff_user_id`,`function_id`),
  KEY `idx_sfsa_staff` (`franchise_id`,`staff_user_id`,`status`),
  KEY `idx_sfsa_function` (`franchise_id`,`function_id`,`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7. FRANCHISE AUDIT LOGS TABLE
CREATE TABLE IF NOT EXISTS `franchise_audit_logs` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `franchise_id` bigint(20) UNSIGNED NOT NULL,
  `actor_type` enum('ADMIN','STAFF','CUSTOMER','SYSTEM') NOT NULL,
  `actor_user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `actor_admin_id` bigint(20) UNSIGNED DEFAULT NULL,
  `action` varchar(100) NOT NULL,
  `entity_type` varchar(100) DEFAULT NULL,
  `entity_id` bigint(20) UNSIGNED DEFAULT NULL,
  `description` text DEFAULT NULL,
  `old_values` longtext DEFAULT NULL,
  `new_values` longtext DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` varchar(500) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_fal_franchise_date` (`franchise_id`,`created_at`),
  KEY `idx_fal_action` (`action`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
