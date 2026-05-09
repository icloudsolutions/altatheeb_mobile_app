#!/usr/bin/env bash
# Run on the server in /home/ems after DNS A record points to this host and ports 80/443 reach nginx.
# Usage: EMS_DOMAIN=emsmobile.icloud-solutions.net CERTBOT_EMAIL=you@example.com ./scripts/obtain-cert.sh
set -euo pipefail
cd "$(dirname "$0")/.."
DOMAIN="${EMS_DOMAIN:-emsmobile.icloud-solutions.net}"
EMAIL="${CERTBOT_EMAIL:?Set CERTBOT_EMAIL for Let's Encrypt registration}"

docker compose run --rm certbot certonly \
  --webroot -w /var/www/certbot \
  -d "$DOMAIN" \
  --email "$EMAIL" \
  --agree-tos \
  --non-interactive

# Entrypoint picks HTTPS template only at container start — must restart nginx.
docker compose restart nginx
echo "Certificate issued for $DOMAIN. Nginx restarted with HTTPS."
