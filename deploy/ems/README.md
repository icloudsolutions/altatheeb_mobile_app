# EMS mobile stack on `/home/ems` (Docker Compose)

Deploys **FastAPI backend** + **RQ worker** + **PostgreSQL** + **Redis** + **nginx** (admin SPA built inside the image). Published on **`EMS_PUBLISH_HTTP`** (default **18080** → container port 80) so it can coexist with **host nginx** on :80/:443.

Target server: **`209.38.212.146`**. Paths: **`/home/ems`**.

## Layout on server

```
/home/ems/
  docker-compose.yml
  docker-compose.tls-public.yml   # optional: Docker owns :80/:443 + in-container certbot
  Dockerfile.nginx
  .env
  .initial_admin_password         # created by scripts/remote-setup-emsmobile-host.sh (chmod 600)
  nginx/docker-entrypoint.sh
  nginx/templates/                # HTTP / HTTPS nginx configs (envsubst + EMS_DOMAIN)
  snippets/host-nginx-emsmobile.icloud-solutions.net.conf   # copy to host nginx for TLS + reverse proxy
  scripts/obtain-cert.sh          # only when using docker-compose.tls-public.yml
  scripts/remote-setup-emsmobile-host.sh   # host nginx + certbot + seed (typical VPS with host nginx)
  mobile_backend/
  mobile_admin_web/
  data/postgres/
  data/redis/
```

## One-time server prep

```bash
sudo mkdir -p /home/ems/data/postgres /home/ems/data/redis /home/ems/nginx/templates /home/ems/scripts /home/ems/snippets
sudo chown -R "$USER:$USER" /home/ems
```

Docker Engine + Compose: https://docs.docker.com/engine/install/

Firewall: open **18080** for the stack; **80/443** are used by host nginx for public HTTPS.

## Deploy from your PC (Windows)

```powershell
$env:EMS_DEPLOY_USER = "root"
.\altatheeb_mobile_app\deploy\ems\deploy.ps1
```

Requires **OpenSSH** and **Docker** on the remote host.

## Public HTTPS domain (host nginx + Certbot) — **emsmobile.icloud-solutions.net**

When **host nginx** already listens on **80/443** (this project’s VPS):

1. **DNS**: `A` record `emsmobile.icloud-solutions.net` → server IP.
2. Deploy the stack (Docker nginx on **18080**).
3. On the server, run **`scripts/remote-setup-emsmobile-host.sh`** (installs the site under `/etc/nginx/sites-available/`, reloads nginx, runs **certbot --nginx**, recreates backend with updated `.env`, runs **seed**):

```bash
cd /home/ems
chmod +x scripts/remote-setup-emsmobile-host.sh
EMS_DOMAIN=emsmobile.icloud-solutions.net CERTBOT_EMAIL=you@example.com bash scripts/remote-setup-emsmobile-host.sh
```

4. **Admin login**: `admin@<EMS_DOMAIN>` (e.g. `admin@emsmobile.icloud-solutions.net`). **Password** is written to **`/home/ems/.initial_admin_password`** (not printed by seed). Change it after first login.

5. **Admin UI**: `https://emsmobile.icloud-solutions.net/`  
   **API**: same origin (`/v1/`, `/admin/`, …).

**CORS**: the script sets `ALLOWED_CORS_ORIGINS=https://<EMS_DOMAIN>` in `.env`.

### Alternative: TLS entirely in Docker

On a **dedicated** host where **nothing** else binds to **80/443**:

```bash
cd /home/ems
docker compose -f docker-compose.yml -f docker-compose.tls-public.yml up -d --build
CERTBOT_EMAIL=you@example.com EMS_DOMAIN=emsmobile.icloud-solutions.net ./scripts/obtain-cert.sh
docker compose restart nginx
```

## Verify

```bash
curl -sS https://emsmobile.icloud-solutions.net/healthz
# curl -sS http://127.0.0.1:18080/healthz   # direct to Docker nginx
```

## Flutter / mobile app

```powershell
cd altatheeb_mobile_app\app
flutter run --debug --dart-define=BACKEND_BASE_URL=https://emsmobile.icloud-solutions.net
```

## `.env` essentials

Set strong values for **`JWT_SECRET`**, **`POSTGRES_PASSWORD`**, **`ODOO_*`**, **`ODOO_INBOUND_HMAC_SECRET`**, and **`INITIAL_ADMIN_PASSWORD`** (or let `remote-setup-emsmobile-host.sh` generate it).
