# Altatheeb Mobile Backend

FastAPI service that is the **only** thing the Flutter app talks to. It also
hosts the BFF for the mobile administration web (React/Vite) and receives
signed webhooks from the Odoo `ics_ems_mobile_gateway` addon.

## Stack

| Concern | Choice |
|---------|--------|
| Web framework | FastAPI (Pydantic v2) |
| ORM | SQLAlchemy 2.x (sync) |
| Migrations | Alembic |
| Database | PostgreSQL 16 |
| Cache / queues | Redis 7 + RQ |
| Auth (app) | JWT (HS256), 15 min access + 30 d refresh |
| Auth (admin) | Same backend, role=`admin` |
| Outbound to Odoo | `httpx` + Bearer service token + signed user context |
| Inbound from Odoo | HMAC-SHA256 signature, replay window 5 min, idempotent on `delivery_id` |

## Quick start

```bash
cp .env.example .env
docker compose up --build
docker compose exec backend alembic upgrade head
docker compose exec backend python scripts/seed_local.py
# OpenAPI: http://localhost:8000/docs
```

Default admin credentials after seeding: `admin@local / admin`.

### Stack control

From `mobile_backend/`:

```bash
chmod +x scripts/stack.sh   # once, on Linux/macOS

./scripts/stack.sh stop       # stop containers (keep data)
./scripts/stack.sh restart    # restart all services
./scripts/stack.sh down       # remove containers (volumes kept)
./scripts/stack.sh up         # start detached
./scripts/stack.sh ps         # status
./scripts/stack.sh logs backend
```

Windows PowerShell: `.\scripts\stack.ps1 stop|restart|down|up|ps|logs`

**Linux `bash\r` error:** the script was checked out with Windows line endings. Fix once:

```bash
cd /home/altatheeb_mobile_app
git pull
sed -i 's/\r$//' mobile_backend/scripts/stack.sh
chmod +x mobile_backend/scripts/stack.sh
./mobile_backend/scripts/stack.sh ps
```

## Folder layout

```
mobile_backend/
├── app/
│   ├── api/
│   │   ├── v1/           # Public surface for the Flutter app
│   │   ├── admin/        # Mobile admin web BFF
│   │   └── integrations/ # /integrations/odoo/v1/webhooks
│   ├── core/             # settings, security primitives
│   ├── db/               # SQLAlchemy base + session
│   ├── models/           # ORM tables
│   ├── schemas/          # Pydantic DTOs
│   ├── services/         # Odoo gateway client, FCM, webhook dispatch, notifications
│   ├── workers/          # RQ worker entry point
│   └── main.py           # FastAPI app factory
├── alembic/              # Migrations
├── scripts/seed_local.py # Local-dev seed
├── tests/                # Pytest tests (HMAC, idempotency, replay, healthz)
├── Dockerfile
├── docker-compose.yml
└── pyproject.toml
```

## Key contracts

* **Webhook** envelope and signing rules: see
  `altatheeb_mobile_app/docs/EMS_FLUTTER_MOBILE_ARCHITECTURE.md` §4.7.
* **Public API** routes: §4.8 in the same doc.
* **Odoo gateway** server-to-server routes: §4.9.

## Tests

```bash
pip install -e ".[dev]"
pytest -q
```

Webhook signature, idempotency, and replay-attack tests live in
`tests/test_webhook_signature.py`.
