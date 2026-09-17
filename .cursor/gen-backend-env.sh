#!/usr/bin/env bash
# Generate backend/.env with local development defaults if it does not exist.
# Secrets here are non-production placeholders. A throwaway RSA key is generated
# so firebase-admin can parse a private key at boot (push sending is a no-op locally).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

ENV_FILE="$REPO_ROOT/backend/.env"

if [ -f "$ENV_FILE" ]; then
  log "backend/.env already exists; leaving it untouched."
  exit 0
fi

log "Generating backend/.env for local development..."
FB_KEY_ESCAPED="$(openssl genrsa 2048 2>/dev/null | awk 'BEGIN{ORS="\\n"}{print}')"

cat > "$ENV_FILE" <<EOF
PORT=3000
NODE_ENV=development
TRUST_PROXY=false

# Database (local MariaDB provisioned by the Cloud Agent environment)
DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_NAME=$DB_NAME

# Auth / security (local dev placeholders)
JWT_SECRET=dev_jwt_secret_change_me
API_SECRET_KEY=dev_api_secret_change_me

# CORS: allow the local admin app and mobile client
ALLOWED_ORIGINS=*

# Firebase Admin (push notifications) - throwaway values for local dev only.
FIREBASE_TYPE=service_account
FIREBASE_PROJECT_ID=local-dev
FIREBASE_PRIVATE_KEY_ID=localdevkeyid
FIREBASE_PRIVATE_KEY="$FB_KEY_ESCAPED"
FIREBASE_CLIENT_EMAIL=local-dev@local-dev.iam.gserviceaccount.com
FIREBASE_CLIENT_ID=000000000000000000000
FIREBASE_AUTH_URI=https://accounts.google.com/o/oauth2/auth
FIREBASE_TOKEN_URI=https://oauth2.googleapis.com/token
FIREBASE_AUTH_PROVIDER_X509_CERT_URL=https://www.googleapis.com/oauth2/v1/certs
FIREBASE_CLIENT_X509_CERT_URL=https://www.googleapis.com/robot/v1/metadata/x509/local-dev
FIREBASE_UNIVERSE_DOMAIN=googleapis.com
EOF

log "backend/.env created."
