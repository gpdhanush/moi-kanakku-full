-- Each approved export payment now buys a fixed number of PDF exports (default 3).
-- Run after create_export_payments.sql.
ALTER TABLE `export_payments`
  ADD COLUMN `exports_allowed` tinyint(3) UNSIGNED NOT NULL DEFAULT 3 AFTER `status`,
  ADD COLUMN `exports_used` tinyint(3) UNSIGNED NOT NULL DEFAULT 0 AFTER `exports_allowed`;
