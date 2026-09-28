#!/usr/bin/env bash
# Per-boot startup: bring up MariaDB and make sure the dev database is seeded.
# The backend and admin dev servers run as named terminals (see environment.json).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

start_mariadb

# Ensure the schema/data exist (no-op if the datadir already has them).
bash "$REPO_ROOT/.cursor/db-setup.sh"

log "Startup complete. MariaDB is ready on 127.0.0.1:3306."
