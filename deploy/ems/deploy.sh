#!/usr/bin/env bash
# Same as deploy.ps1 — Admin SPA is built inside the nginx Docker image on the server (no local Node required).
set -euo pipefail

SERVER_HOST="${EMS_DEPLOY_HOST:-209.38.212.146}"
REMOTE_DIR="${EMS_REMOTE_DIR:-/home/ems}"
SSH_USER="${EMS_DEPLOY_USER:-root}"
SERVER="${SSH_USER}@${SERVER_HOST}"

# altatheeb_mobile_app/
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
EMS_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

ADMIN_SRC="$ROOT/mobile_admin_web"
BACKEND_SRC="$ROOT/mobile_backend"
if [[ ! -f "$ADMIN_SRC/package.json" ]]; then
  echo "Admin web not found at $ADMIN_SRC" >&2
  exit 1
fi
if [[ ! -f "$BACKEND_SRC/app/main.py" ]]; then
  echo "Backend not found at $BACKEND_SRC" >&2
  exit 1
fi

echo "=== Remote dirs ==="
ssh "$SERVER" "mkdir -p $REMOTE_DIR/nginx/templates $REMOTE_DIR/scripts $REMOTE_DIR/snippets $REMOTE_DIR/data/postgres $REMOTE_DIR/data/redis"

echo "=== Upload mobile_backend ==="
ssh "$SERVER" "rm -rf $REMOTE_DIR/mobile_backend"
scp -r "$BACKEND_SRC" "${SERVER}:${REMOTE_DIR}/mobile_backend"

echo "=== Upload mobile_admin_web ==="
ssh "$SERVER" "rm -rf $REMOTE_DIR/mobile_admin_web"
scp -r "$ADMIN_SRC" "${SERVER}:${REMOTE_DIR}/mobile_admin_web"

echo "=== Upload compose + nginx + Dockerfile ==="
scp "$EMS_DIR/docker-compose.yml" "${SERVER}:${REMOTE_DIR}/"
scp "$EMS_DIR/Dockerfile.nginx" "${SERVER}:${REMOTE_DIR}/"
scp "$EMS_DIR/nginx/docker-entrypoint.sh" "${SERVER}:${REMOTE_DIR}/nginx/"
scp -r "$EMS_DIR/nginx/templates" "${SERVER}:${REMOTE_DIR}/nginx/"
scp "$EMS_DIR/scripts/obtain-cert.sh" "${SERVER}:${REMOTE_DIR}/scripts/"
ssh "$SERVER" "chmod +x $REMOTE_DIR/scripts/obtain-cert.sh $REMOTE_DIR/nginx/docker-entrypoint.sh"
if [[ -f "$EMS_DIR/snippets/host-nginx-emsmobile.icloud-solutions.net.conf" ]]; then
  ssh "$SERVER" "mkdir -p $REMOTE_DIR/snippets"
  scp "$EMS_DIR/snippets/host-nginx-emsmobile.icloud-solutions.net.conf" "${SERVER}:${REMOTE_DIR}/snippets/"
fi
scp "$EMS_DIR/docker-compose.tls-public.yml" "${SERVER}:${REMOTE_DIR}/"
scp "$EMS_DIR/context.dockerignore" "${SERVER}:${REMOTE_DIR}/.dockerignore"

scp "$EMS_DIR/env.production.example" "${SERVER}:${REMOTE_DIR}/env.production.example"
ssh "$SERVER" "test -f $REMOTE_DIR/.env || cp $REMOTE_DIR/env.production.example $REMOTE_DIR/.env"

echo "=== docker compose ==="
ssh "$SERVER" "cd $REMOTE_DIR && docker compose build && docker compose up -d"

echo "=== curl healthz (HTTP on port 80 after TLS setup, or use domain) ==="
curl -sS "http://${SERVER_HOST}/healthz" || true
