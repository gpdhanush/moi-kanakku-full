-- Consolidate email verification state on users.is_verified.
-- email_verified_at remains the verification timestamp.

SET @email_verified_exists = (
  SELECT COUNT(*)
  FROM information_schema.columns
  WHERE table_schema = DATABASE()
    AND table_name = 'users'
    AND column_name = 'email_verified'
);

SET @drop_email_verified = IF(
  @email_verified_exists > 0,
  'ALTER TABLE users DROP COLUMN email_verified',
  'SELECT 1'
);

PREPARE drop_email_verified_statement FROM @drop_email_verified;
EXECUTE drop_email_verified_statement;
DEALLOCATE PREPARE drop_email_verified_statement;