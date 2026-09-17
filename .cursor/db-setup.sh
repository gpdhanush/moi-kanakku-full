#!/usr/bin/env bash
# Provision and seed the local MariaDB database from the committed dump.
# Idempotent: creates the DB/user if missing and imports the dump only when empty.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

start_mariadb

log "Ensuring database '$DB_NAME' and user '$DB_USER' exist..."
sudo mysql -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;"

TABLE_COUNT="$(sudo mysql -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$DB_NAME';")"

if [ "${TABLE_COUNT:-0}" -eq 0 ]; then
  log "Importing schema + data from dump..."
  sudo mysql "$DB_NAME" < "$DB_DUMP"
  if [ -f "$DB_INDEXES" ]; then
    log "Applying optimization indexes..."
    sudo mysql "$DB_NAME" < "$DB_INDEXES" 2>/dev/null || true
  fi
else
  log "Database already has $TABLE_COUNT tables; skipping import."
fi

# Set a known password for the seeded admin so the dashboard can be logged into
# during local development. This only touches the local dev database.
DEMO_ADMIN_EMAIL="agprakash406@gmail.com"
DEMO_ADMIN_PASSWORD="Admin@123"
if sudo mysql -N -e "SELECT 1 FROM \`$DB_NAME\`.admins WHERE email='$DEMO_ADMIN_EMAIL' LIMIT 1;" | grep -q 1; then
  HASH="$(cd "$REPO_ROOT/backend" && node -e "console.log(require('bcryptjs').hashSync(process.argv[1],10))" "$DEMO_ADMIN_PASSWORD")"
  sudo mysql -e "UPDATE \`$DB_NAME\`.admins
    SET password_hash='$HASH', status='ACTIVE', failed_login_attempts=0, locked_until=NULL, is_deleted=0
    WHERE email='$DEMO_ADMIN_EMAIL';"
  log "Local admin login ready -> $DEMO_ADMIN_EMAIL / $DEMO_ADMIN_PASSWORD"
fi

log "Database setup complete."
