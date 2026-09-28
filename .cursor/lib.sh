#!/usr/bin/env bash
# Shared helpers for Moi Kanakku Cloud Agent environment scripts.
set -euo pipefail

# Repository root (parent of the .cursor directory that holds this file).
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export REPO_ROOT

# Make the Flutter SDK available (installed under $HOME/flutter in the base image).
if [ -d "$HOME/flutter/bin" ]; then
  export PATH="$HOME/flutter/bin:$PATH"
fi

# Local development database configuration. These are non-secret dev defaults;
# real credentials are supplied via environment secrets in production.
DB_NAME="${DB_NAME:-prasowla_moi_kanakku_db}"
DB_USER="${DB_USER:-moi}"
DB_PASSWORD="${DB_PASSWORD:-moi_dev_pass}"
DB_DUMP="$REPO_ROOT/backend/database/prasowla_moi_kanakku_db.sql"
DB_INDEXES="$REPO_ROOT/backend/database/optimizations_indexes.sql"
export DB_NAME DB_USER DB_PASSWORD

log() { printf '\033[1;36m[moi-env]\033[0m %s\n' "$*"; }

# Start MariaDB (idempotent). Safe to call multiple times / on every boot.
start_mariadb() {
  sudo mkdir -p /var/run/mysqld /var/log/mysql
  sudo chown mysql:mysql /var/run/mysqld /var/log/mysql

  if sudo mysqladmin ping >/dev/null 2>&1; then
    log "MariaDB already running."
    return 0
  fi

  log "Starting MariaDB daemon..."
  sudo bash -c 'nohup mariadbd-safe --datadir=/var/lib/mysql >/var/log/mysql/safe.log 2>&1 &'

  for _ in $(seq 1 30); do
    if sudo mysqladmin ping >/dev/null 2>&1; then
      log "MariaDB is up."
      return 0
    fi
    sleep 1
  done

  log "ERROR: MariaDB did not become ready in time."
  sudo tail -n 40 /var/log/mysql/safe.log || true
  return 1
}
