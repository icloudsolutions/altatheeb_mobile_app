#!/bin/sh
set -e
EMS_DOMAIN="${EMS_DOMAIN:-emsmobile.icloud-solutions.net}"
export EMS_DOMAIN

if [ -f "/etc/letsencrypt/live/${EMS_DOMAIN}/fullchain.pem" ]; then
  echo "nginx: TLS certificates found for ${EMS_DOMAIN}, enabling HTTPS."
  envsubst '${EMS_DOMAIN}' < /etc/nginx/templates/https.conf.template > /etc/nginx/nginx.conf
else
  echo "nginx: no TLS certs yet for ${EMS_DOMAIN}, HTTP only (use scripts/obtain-cert.sh)."
  envsubst '${EMS_DOMAIN}' < /etc/nginx/templates/http.conf.template > /etc/nginx/nginx.conf
fi

exec nginx -g 'daemon off;'
