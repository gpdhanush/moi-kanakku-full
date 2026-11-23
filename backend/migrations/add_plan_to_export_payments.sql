-- Export plans: each payment now records which plan the user paid for.
--   single   = 1 PDF export   (₹19)
--   pack5    = 5 PDF exports  (₹49)
--   lifetime = unlimited PDF exports (₹499)
-- Rows created before this migration keep plan = NULL and their stored
-- exports_allowed. Run after add_export_limits_to_export_payments.sql.
ALTER TABLE `export_payments`
  ADD COLUMN `plan` varchar(16) DEFAULT NULL AFTER `amount`,
  ADD KEY `idx_export_payments_user_plan` (`user_id`, `status`, `plan`);
