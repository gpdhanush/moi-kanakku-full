-- ============================================================================
-- MYSQL INDEX OPTIMIZATIONS FOR MOI KANAKKU BACKEND
-- Target Database: floatwal_moi_kanakku_db / prasowla_moi_kanakku_db
-- Optimized for: Shared cPanel Hosting (Node.js + MySQL)
-- ============================================================================

-- 1. Transactions Table Composite Indexes
-- Support user transaction filtering by soft-delete flag, transaction type, person, function, and date ordering.
ALTER TABLE `transactions` ADD INDEX `idx_trans_user_del_type` (`user_id`, `is_deleted`, `type`);
ALTER TABLE `transactions` ADD INDEX `idx_trans_user_del_person` (`user_id`, `is_deleted`, `person_id`);
ALTER TABLE `transactions` ADD INDEX `idx_trans_user_del_func` (`user_id`, `is_deleted`, `transaction_function_id`);
ALTER TABLE `transactions` ADD INDEX `idx_trans_user_del_date` (`user_id`, `is_deleted`, `transaction_date` DESC);

-- 2. Persons Table Composite Index
-- Supports listing user persons sorted alphabetically by first_name.
ALTER TABLE `persons` ADD INDEX `idx_persons_user_del_name` (`user_id`, `first_name`);

-- 3. Transaction Functions Composite Index
-- Supports listing user transaction functions ordered by function_date.
ALTER TABLE `transaction_functions` ADD INDEX `idx_tf_user_del_date` (`user_id`, `is_deleted`, `function_date` DESC);

-- 4. Upcoming Functions Composite Index
-- Supports upcoming function reminders and listing upcoming functions ordered by date.
ALTER TABLE `upcoming_functions` ADD INDEX `idx_uf_user_del_date` (`user_id`, `is_deleted`, `function_date` ASC);

-- 5. Notifications Composite Index
-- Supports listing notifications per user ordered by created_at DESC.
ALTER TABLE `notifications` ADD INDEX `idx_notif_user_del_created` (`user_id`, `is_deleted`, `created_at` DESC);

-- 6. User Devices Composite Index
-- Supports subquery lookup for active FCM tokens: WHERE user_id = ? AND is_active = 1 ORDER BY last_used_at DESC LIMIT 1.
ALTER TABLE `user_devices` ADD INDEX `idx_ud_user_active_used` (`user_id`, `is_active`, `last_used_at` DESC);
