-- Keep soft-deleted accounts distinguishable from inactive accounts.
ALTER TABLE users
  MODIFY COLUMN status ENUM('ACTIVE', 'INACTIVE', 'BLOCKED', 'DELETED') DEFAULT 'ACTIVE';

UPDATE users
SET status = 'DELETED'
WHERE is_deleted = 1
  AND status <> 'DELETED';