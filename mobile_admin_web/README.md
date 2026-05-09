# Altatheeb Mobile Admin Web

React 18 + Vite + TypeScript + TanStack Query + Tailwind. Talks to the
mobile backend at `${VITE_API_BASE_URL}/admin/v1/...`.

## Pages

| Path | Purpose |
|------|---------|
| `/login` | Admin login (POST `/admin/v1/auth/login`). |
| `/users` | App user list, role assignment, disable. |
| `/feature-flags` | Toggle / add feature flags. |
| `/min-app-version` | Force-upgrade gate. |
| `/webhook-deliveries` | Live view of inbound webhook deliveries with replay. |
| `/audit` | Audit log viewer. |

## Run

```bash
cp .env.example .env
npm install
npm run dev
```

Default backend URL: `http://localhost:8000`. Default seed credentials:
`admin@local / admin` (see `../mobile_backend/scripts/seed_local.py`).
