#!/usr/bin/env bash
# Idempotent repository bootstrap for the Moi Kanakku monorepo.
# Runs after the source is checked out. Installs dependencies for all three
# apps and provisions the local development database.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

log "== Backend: installing Node dependencies =="
( cd "$REPO_ROOT/backend" && npm install )

log "== Admin app: installing Node dependencies =="
( cd "$REPO_ROOT/admin-app" && npm install )

log "== Mobile app: resolving Flutter packages =="
( cd "$REPO_ROOT/mobile-app" && flutter pub get )

log "== Backend: generating local .env =="
bash "$REPO_ROOT/.cursor/gen-backend-env.sh"

log "== Database: provisioning and seeding =="
bash "$REPO_ROOT/.cursor/db-setup.sh"

log "Install complete."
