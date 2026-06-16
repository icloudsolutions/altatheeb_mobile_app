# Al Tahtheeb EMS Mobile Platform — Installation & Deployment Guide

> **Version:** 0.2.0  
> **Last updated:** June 2026  
> **Maintained by:** ICloud Solutions — [icloudsolutions.sa](https://icloudsolutions.sa)

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Prerequisites](#prerequisites)
3. [Repository Structure](#repository-structure)
4. [Environment Configuration](#environment-configuration)
5. [Local Development Setup](#local-development-setup)
   - [Backend (FastAPI)](#backend-fastapi)
   - [Flutter Mobile App](#flutter-mobile-app)
   - [Admin Web (React)](#admin-web-react)
6. [Odoo Integration](#odoo-integration)
7. [Production Deployment](#production-deployment)
8. [Firebase / Push Notifications](#firebase--push-notifications)
9. [Database Migrations](#database-migrations)
10. [Running Without Odoo (Offline Mode)](#running-without-odoo-offline-mode)
11. [Admin Panel](#admin-panel)
12. [Troubleshooting](#troubleshooting)
13. [Security Checklist](#security-checklist)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│  Flutter App (iOS / Android)                                    │
│  • BLoC / Cubit state management                                │
│  • go_router navigation                                         │
│  • JWT bearer auth (15 min access / 30 day refresh)             │
└──────────────────────────┬──────────────────────────────────────┘
                           │ HTTPS / JWT
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│  Mobile Backend (FastAPI + PostgreSQL + Redis)                  │
│  • /v1/auth, /v1/me, /v1/children, /v1/invoices                 │
│  • /v1/children/{id}/attendance                                 │
│  • /v1/children/{id}/results                                    │
│  • /v1/announcements, /v1/config, /v1/devices                   │
│  • Mirror DB (EmsStudent, EmsInvoice, EmsAttendance, …)         │
│  • Webhook receiver (/integrations/odoo/v1/webhooks)            │
│  • RQ worker (background jobs)                                  │
└──────────────────────────┬──────────────────────────────────────┘
                           │ Bearer token + HMAC-signed
                           │ (optional — offline mode available)
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│  Odoo 19 + ics_ems_mobile_gateway addon                         │
│  • /ems/integration/v1/* REST endpoints                         │
│  • Outbound signed webhooks on data changes                     │
└─────────────────────────────────────────────────────────────────┘
```

**Key design principle:** The Flutter app **never** talks directly to Odoo.  
The backend acts as a BFF (Backend For Frontend) and can serve data from its
local mirror DB when Odoo is unreachable.

---

## Prerequisites

### Backend
| Tool | Minimum version | Notes |
|------|-----------------|-------|
| Python | 3.11+ | Use `pyenv` or system Python |
| PostgreSQL | 16+ | Can use Docker |
| Redis | 7+ | Can use Docker |
| Docker & Docker Compose | 24+ | For containerised setup |

### Flutter App
| Tool | Minimum version |
|------|-----------------|
| Flutter SDK | 3.22+ |
| Dart SDK | 3.4+ |
| Android SDK | API 26+ (Android 8) |
| Xcode | 15+ (iOS 14+) |
| Node.js | 18+ (for codegen scripts) |

### Admin Web
| Tool | Minimum version |
|------|-----------------|
| Node.js | 18+ |
| npm / pnpm | 9+ |

---

## Repository Structure

```
altatheeb_mobile_app/
├── app/                    # Flutter mobile app
│   ├── lib/
│   │   ├── app/            # Router, theme, localization, shared widgets
│   │   ├── core/           # Dio client, secure storage, config
│   │   └── features/       # auth, children, invoices, attendance,
│   │                       # results, announcements, profile, settings
│   ├── l10n/               # AR + EN ARB translation files
│   ├── android/
│   ├── ios/
│   └── pubspec.yaml
│
├── mobile_backend/         # FastAPI backend
│   ├── app/
│   │   ├── api/            # v1/ and admin/ route handlers
│   │   ├── core/           # settings, security (JWT, HMAC)
│   │   ├── db/             # SQLAlchemy session + Base
│   │   ├── models/         # ORM models (AppUser, EmsStudent, …)
│   │   ├── schemas/        # Pydantic request/response schemas
│   │   └── services/       # OdooGatewayClient, FCM, webhooks
│   ├── alembic/            # Database migrations
│   ├── Dockerfile
│   ├── docker-compose.yml  # Local dev (Postgres + Redis + API)
│   └── pyproject.toml
│
├── mobile_admin_web/       # React admin SPA
│   ├── src/
│   │   ├── pages/          # Users, FeatureFlags, Audit, Webhooks
│   │   └── api/
│   └── package.json
│
├── deploy/ems/             # Production Docker Compose + nginx
│   ├── docker-compose.yml
│   ├── env.production.example
│   └── deploy.sh
│
├── docs/                   # Architecture specs
└── INSTALL.md              # This file
```

---

## Environment Configuration

### Backend — `.env`

Copy the template and fill in all values:

```bash
cp mobile_backend/.env.example mobile_backend/.env
```

| Variable | Required | Description |
|----------|----------|-------------|
| `DATABASE_URL` | ✅ | `postgresql+psycopg2://user:pass@host:5432/ems_mobile` |
| `REDIS_URL` | ✅ | `redis://localhost:6379/0` |
| `JWT_SECRET` | ✅ | Long random string (≥32 chars). **Change in production.** |
| `JWT_ACCESS_TTL` | — | Access token TTL in seconds (default: 900 = 15 min) |
| `JWT_REFRESH_TTL` | — | Refresh token TTL in seconds (default: 2592000 = 30 days) |
| `ODOO_BASE_URL` | — | e.g. `https://erp.altahtheeb.edu.sa` |
| `ODOO_SERVICE_TOKEN` | — | Service bearer token configured in Odoo |
| `USER_CONTEXT_SECRET` | — | HMAC secret for `X-EMS-User-Context` header |
| `ODOO_INBOUND_HMAC_SECRET` | — | HMAC secret for verifying Odoo webhooks |
| `ODOO_OFFLINE_MODE` | — | `true` to disable all Odoo calls (standalone mode) |
| `FCM_PROJECT_ID` | — | Firebase project ID for push notifications |
| `FCM_CREDENTIALS_PATH` | — | Path to Firebase service account JSON |
| `ALLOWED_CORS_ORIGINS` | — | Comma-separated list of allowed origins |
| `APP_ENV` | — | `local` / `staging` / `production` |
| `LOG_LEVEL` | — | `DEBUG` / `INFO` / `WARNING` |

### Flutter App — compile-time defines

Pass via `--dart-define` when building or running:

```bash
flutter run --dart-define=BACKEND_BASE_URL=https://api.altahtheeb.edu.sa
```

| Define | Default | Description |
|--------|---------|-------------|
| `BACKEND_BASE_URL` | `http://10.0.2.2:8000` | Backend API base URL |

### Admin Web — `.env`

```bash
cp mobile_admin_web/.env.example mobile_admin_web/.env
```

| Variable | Description |
|----------|-------------|
| `VITE_API_BASE_URL` | Backend base URL for the admin panel |

---

## Local Development Setup

### Backend (FastAPI)

#### Option A — Docker Compose (recommended)

```bash
cd mobile_backend

# Start Postgres + Redis + API server
docker compose up -d

# Run database migrations
docker compose exec backend alembic upgrade head

# (Optional) Seed demo data
docker compose exec backend python scripts/seed_local.py
```

The API will be available at `http://localhost:8000`.  
Swagger docs: `http://localhost:8000/docs`

#### Option B — Native Python

```bash
cd mobile_backend

# Create virtual environment
python -m venv .venv
source .venv/bin/activate        # macOS/Linux
.venv\Scripts\Activate.ps1       # Windows PowerShell

# Install dependencies
pip install -e ".[dev]"

# Create the .env file and configure it
cp .env.example .env

# Run migrations
alembic upgrade head

# Start the API
uvicorn app.main:app --reload --port 8000

# (Separate terminal) Start the RQ worker
python -m rq worker --with-scheduler
```

---

### Flutter Mobile App

#### 1. Install dependencies

```bash
cd app
flutter pub get
```

#### 2. Generate localizations

```bash
flutter gen-l10n
```

#### 3. Run on Android emulator or device

```bash
# Emulator (uses 10.0.2.2 to reach localhost backend)
flutter run

# Physical device on same Wi-Fi
flutter run --dart-define=BACKEND_BASE_URL=http://192.168.1.x:8000

# Wi-Fi debug helper script (Windows)
.\scripts\run_android_wifi_debug.ps1
```

#### 4. Run on iOS simulator

```bash
flutter run -d "iPhone 15"
```

#### 5. Build release APK

```bash
flutter build apk --release \
  --dart-define=BACKEND_BASE_URL=https://api.altahtheeb.edu.sa
```

#### 6. Build release App Bundle (Play Store)

```bash
flutter build appbundle --release \
  --dart-define=BACKEND_BASE_URL=https://api.altahtheeb.edu.sa
```

#### 7. Build iOS release (IPA)

```bash
flutter build ipa --release \
  --dart-define=BACKEND_BASE_URL=https://api.altahtheeb.edu.sa
```

---

### Admin Web (React)

```bash
cd mobile_admin_web
npm install
cp .env.example .env       # Set VITE_API_BASE_URL

# Development server
npm run dev

# Production build
npm run build
# Output in dist/
```

---

## Odoo Integration

### Required Addon

Install the `ics_ems_mobile_gateway` addon from the `altahtheeb-addons` repository into your Odoo 19 instance.

**Dependency chain (install order):**
```
ics_sa_partner_identification
  → ics_ems_core
      → ics_ems_fees
      → ics_ems_attendance
      → ics_ems_academic
      → ics_ems_parent_portal
      → ics_ems_mobile_gateway   ← required for mobile integration
```

### Service Token

In Odoo, navigate to **EMS → Mobile Gateway → Configuration** and generate a service token. Copy it into `ODOO_SERVICE_TOKEN` in the backend `.env`.

### Webhook Configuration

In Odoo, configure the outbound webhook URL:
```
https://your-backend-domain.com/integrations/odoo/v1/webhooks
```

Set the shared secret in both Odoo and `ODOO_INBOUND_HMAC_SECRET`.

### Deprecated Addons

The following addons are **superseded** and should **not** be used for mobile integration:

| Addon | Status | Reason |
|-------|--------|--------|
| `ics_ems_mobile_app` | ⚠️ Legacy | Direct JSON-RPC to Odoo; use gateway instead |
| `ics_ems_api` | ⚠️ Legacy | Generic API-key auth, not parent-scoped |
| `ics_ems_fulfillment` | ❌ Disabled | `installable: False` — do not install |
| `ics_ems_fin_migration` | 📦 One-time | Only needed for 2025–26 data migration |
| `dev_tools` / `dev_bypass_expiration` | 🚫 Dev-only | Never install in production |

---

## Production Deployment

### Docker Compose Stack

```bash
cd deploy/ems

# Create environment file
cp env.production.example .env
# Edit .env with production values

# Deploy
./deploy.sh

# Or manually
docker compose -f docker-compose.yml up -d
```

The stack starts:
- **PostgreSQL 16** — port 5432 (internal only)
- **Redis 7** — port 6379 (internal only)
- **Backend API** — port 8000 (exposed via nginx)
- **RQ Worker** — background job processor
- **nginx** — reverse proxy on port 18080 (or 443 with TLS)

### TLS / HTTPS (recommended)

```bash
# With Let's Encrypt
docker compose -f docker-compose.yml \
               -f docker-compose.tls-public.yml up -d
```

### nginx Reverse Proxy (external)

If you use an external nginx or Caddy, proxy to port 8000:

```nginx
server {
    listen 443 ssl;
    server_name api.altahtheeb.edu.sa;

    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
    }
}
```

---

## Firebase / Push Notifications

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Add Android app (`com.altahtheeb.ems.altatheeb_mobile_app`) and iOS app
3. Download `google-services.json` → `app/android/app/`
4. Download `GoogleService-Info.plist` → `app/ios/Runner/`
5. Download service account JSON → server path referenced by `FCM_CREDENTIALS_PATH`
6. Set `FCM_PROJECT_ID` in backend `.env`

> **Note:** If Firebase config files are absent, the app initializes gracefully with Firebase disabled (push notifications will not work but the rest of the app functions normally).

---

## Database Migrations

```bash
# Apply all pending migrations
alembic upgrade head

# Create a new migration after model changes
alembic revision --autogenerate -m "describe your change"

# Rollback last migration
alembic downgrade -1

# Show current revision
alembic current
```

---

## Running Without Odoo (Offline Mode)

The backend can operate **fully standalone** without an Odoo instance. In this mode:

- Authentication uses locally stored bcrypt password hashes (set on first Odoo login)
- Children, invoices, attendance, and results are served from the mirror DB tables
- Announcements, config, and devices always work from local DB

**Enable offline mode:**

```env
ODOO_OFFLINE_MODE=true
```

Or simply leave `ODOO_SERVICE_TOKEN` empty — the backend will automatically fall back to the mirror DB on every Odoo connection failure.

**How the mirror DB gets populated:**
- Odoo sends signed webhooks to `/integrations/odoo/v1/webhooks` on every data change
- The backend upserts mirror tables (`EmsStudent`, `EmsInvoice`, `EmsAttendance`, `EmsExamResult`, `EmsAnnouncement`)
- On cold start (empty mirror), the backend proxies live requests to Odoo and caches the results

---

## Admin Panel

Access the React admin SPA at `http://localhost:5173` (dev) or `/admin` (production).

Default admin credentials are set via the seed script or directly in the database.

**Admin features:**
- User management (list, activate/deactivate, Odoo user ID)
- Feature flags (enable/disable app features per environment)
- Minimum app version enforcement (Android + iOS)
- Maintenance banner (bilingual AR/EN)
- Webhook delivery log (inspect Odoo webhook events)
- Audit log

---

## Troubleshooting

### Flutter app cannot reach backend

```
DioException: Connection refused
```

- **Android emulator:** Use `10.0.2.2` (not `localhost`) as the backend host
- **iOS simulator:** Use `127.0.0.1` or your Mac's local IP
- **Physical device:** Use your computer's local network IP; ensure firewall allows port 8000
- Check `BACKEND_BASE_URL` dart-define

### Login returns 503 `odoo_unavailable_no_local_credentials`

The user has never logged in successfully before (no local password hash). Ensure Odoo is reachable for the first login, or manually set `password_hash` in `app_user` table.

### Localizations missing / `AppLocalizations.of(context)` returns null

Run `flutter gen-l10n` from inside the `app/` directory. Ensure `l10n.yaml` exists at `app/l10n.yaml`.

### `alembic upgrade head` fails with `relation already exists`

The database was created before alembic tracking. Stamp it:
```bash
alembic stamp head
```

### Backend 401 on all requests after restart

JWT secret changed. Clients need to log in again. In production, keep `JWT_SECRET` stable.

### Odoo webhooks not arriving

1. Check `ODOO_INBOUND_HMAC_SECRET` matches the Odoo config
2. Verify the webhook URL is reachable from Odoo server (no VPN/firewall blocking)
3. Check backend logs for HMAC verification errors
4. Use the admin panel → Webhook Deliveries to inspect failed deliveries

---

## Security Checklist

Before going to production, verify:

- [ ] `JWT_SECRET` is a random string ≥ 32 characters, never committed to git
- [ ] `ODOO_SERVICE_TOKEN` is rotated and not the default
- [ ] `USER_CONTEXT_SECRET` and `ODOO_INBOUND_HMAC_SECRET` are strong random secrets
- [ ] Database and Redis are not exposed to the public internet
- [ ] HTTPS / TLS is enforced (HTTP redirect to HTTPS in nginx)
- [ ] `APP_ENV=production` (disables debug endpoints)
- [ ] `DEBUG=false` in Flutter release builds (PrettyDioLogger is gated by `kDebugMode`)
- [ ] Firebase google-services files are excluded from public git repositories
- [ ] Admin panel is protected behind VPN or IP allowlist
- [ ] Regular DB backups are scheduled (`pg_dump`)
- [ ] `dev_tools` and `dev_bypass_expiration` Odoo addons are **not** installed in production

---

## Support

For technical issues, contact the development team:

- **GitHub:** [icloudsolutions/altatheeb_mobile_app](https://github.com/icloudsolutions/altatheeb_mobile_app)
- **Email:** dev@icloudsolutions.sa

---

*This document is auto-generated as part of the Al Tahtheeb EMS Mobile Platform.*
