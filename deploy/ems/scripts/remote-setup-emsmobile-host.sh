#!/usr/bin/env bash
# Run ON the VPS as root after deploy (copies snippet, reloads nginx, obtains cert, seeds admin).
set -eu
DOMAIN="${EMS_DOMAIN:-emsmobile.icloud-solutions.net}"
EMAIL="${CERTBOT_EMAIL:-hello@icloud-solutions.net}"
EMS_HOME="${EMS_HOME:-/home/ems}"

cd "$EMS_HOME"

docker compose up -d --remove-orphans

if [[ ! -f "$EMS_HOME/snippets/host-nginx-emsmobile.icloud-solutions.net.conf" ]]; then
  echo "Missing $EMS_HOME/snippets/host-nginx-emsmobile.icloud-solutions.net.conf — deploy first." >&2
  exit 1
fi

install -m 644 "$EMS_HOME/snippets/host-nginx-emsmobile.icloud-solutions.net.conf" \
  "/etc/nginx/sites-available/${DOMAIN}.conf"
ln -sf "/etc/nginx/sites-available/${DOMAIN}.conf" "/etc/nginx/sites-enabled/${DOMAIN}.conf"
nginx -t
systemctl reload nginx

PW="$(python3 -c "import secrets,string as s; a=s.ascii_letters+s.digits; print(''.join(__import__('secrets').choice(a) for _ in range(24)))")"
echo "$PW" > "$EMS_HOME/.initial_admin_password"
chmod 600 "$EMS_HOME/.initial_admin_password"

grep -vE '^(EMS_DOMAIN|ALLOWED_CORS_ORIGINS|INITIAL_ADMIN_|CERTBOT_EMAIL)=' .env > .env.tmp 2>/dev/null || cp .env .env.tmp
mv .env.tmp .env
{
  echo "EMS_DOMAIN=${DOMAIN}"
  echo "CERTBOT_EMAIL=${EMAIL}"
  echo "ALLOWED_CORS_ORIGINS=https://${DOMAIN}"
  echo "INITIAL_ADMIN_LOGIN=admin@${DOMAIN}"
  echo "INITIAL_ADMIN_EMAIL=admin@${DOMAIN}"
  echo "INITIAL_ADMIN_FULL_NAME=EMS Administrator"
  echo "INITIAL_ADMIN_PASSWORD=${PW}"
} >> .env

docker compose up -d --force-recreate backend worker
sleep 6
docker compose exec -T backend python scripts/seed_local.py

certbot --nginx -d "${DOMAIN}" --non-interactive --agree-tos -m "${EMAIL}" --redirect

echo "Done. Admin password saved in ${EMS_HOME}/.initial_admin_password (login admin@${DOMAIN})."
