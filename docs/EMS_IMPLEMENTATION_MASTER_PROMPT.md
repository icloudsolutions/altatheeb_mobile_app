## PROMPT

You are a senior full-stack team implementing an **Education Management System (EMS) mobile platform** integrated with **Odoo 19** and existing ICS EMS addons in the repository **`altahtheeb-addons`**.

### Non-negotiable architecture

1. **Flutter (Android + iOS)**
   - Talks **only** to the **mobile backend** over HTTPS JSON (REST).
   - **No** Odoo URLs, **no** Odoo credentials, **no** direct Odoo JSON-RPC from the app.
   - Stack: **Clean Architecture** (presentation / application / domain / data); **Dio**, **Cubit** (`flutter_bloc`), **GoRouter**, **flutter_secure_storage**, **Hive** (structured cache + outbox), **shared_preferences** (only flags); **Arabic + English** with **RTL/LTR** from day one (`intl` + ARB).
   - **Two visual themes** in the mobile app: **Light** and **Dark** — implement with `ThemeData` (or `ColorScheme.fromSeed`), persist user choice (`ThemeMode`: `system` / `light` / `dark`) in Hive, ensure **all** MVP screens, dialogs, sheets, and webviews/chrome are readable in both themes; respect **platform contrast** (WCAG-style checks where feasible).

2. **Mobile backend — adopted stack: FastAPI (Python 3.11) + PostgreSQL + Redis + RQ**
   - Justification: same language as Odoo team, easy local dev with the existing repo, first-class async + Pydantic for OpenAPI auto-generation, excellent Hypercorn / Uvicorn deployment story, mature SQLAlchemy 2.x and Alembic migrations.
   - Owns **PostgreSQL** for **platform users**, **app roles**, **sessions/JWT** (refresh tokens rotated), **FCM device tokens**, **EMS mirror tables** (or materialised views), **webhook delivery log**, **idempotency keys**, **outbox** from mobile clients, **audit log**.
   - Exposes versioned API: `/v1/auth`, `/v1/me`, `/v1/children`, `/v1/invoices`, `/v1/results`, `/v1/documents`, `/v1/requests`, `/v1/sync`, `/v1/store` (feature-flagged), `/v1/notifications`, `/v1/config`, `/integrations/odoo/v1/webhooks` (inbound **from** Odoo), `/admin/v1/*` (mobile admin web).
   - **FCM** sending happens **here** after processing Odoo webhooks or local events.
   - Implements **HMAC-SHA256** verification on all inbound Odoo webhooks (header `X-EMS-Signature: t=<unix_ts>,v1=<hex>`); replay window 5 minutes; stores `delivery_id` for idempotency.

3. **Mobile administration web (SPA) — adopted stack: React 18 + Vite + TypeScript + TanStack Query + Tailwind**
   - Talks to the same backend via `/admin/v1/*` (BFF pattern; admin auth uses MFA-capable backend route).
   - Manages **mobile app users**, **invites**, **password reset for app**, **app roles** (`parent`, later `student`, `teacher`, `office`), **audit log**, **feature flags**, **minimum app version**, **maintenance banner**, optional **push audience** definitions, **webhook delivery dashboard** (read view of `webhook_delivery_log`).
   - **Does not** replace Odoo EMS staff UIs (no fee structure design, no admission pipeline management).

4. **Odoo 19 — new dedicated addon: `ics_ems_mobile_gateway`**
   - Depends on **`ics_ems_core`**, **`ics_ems_fees`**, **`ics_ems_attendance`**, **`ics_ems_academic`**, **`ics_ems_parent_portal`**, **`mail`**.
   - **Outbound:** on relevant EMS model changes (`create`/`write`/workflow), enqueue **signed HTTPS POST** to the mobile backend webhook URL with payload: `integration_contract_version`, `delivery_id`, `event`, `resource`, `ids`, `school_id`, `write_date` (or version), minimal metadata; **retry queue + DLQ** in Odoo if backend returns 5xx/timeout (model `ics.mobile.gateway.delivery`, cron every minute, max 8 retries with exponential backoff `30s → 1m → 5m → 15m → 1h → 4h → 12h → 24h`).
   - **Inbound:** authenticated REST controllers under `/ems/integration/v1/*` for: bootstrap/reconciliation, parent-scoped reads, writes that must hit EMS models (requests, document hand-off, payment confirm), always enforcing **Odoo record rules** and never trusting the phone — only the **mobile backend service identity** (Bearer service token) plus **signed end-user context** header `X-EMS-User-Context` containing HMAC of `parent_id|user_id|timestamp` scoped to backend secret.
   - **Do not** duplicate business rules already on `ics.student`, fee moves, etc. — **call existing models/methods**.
   - Reference existing patterns in `ics_ems_mobile_app/controllers/mobile_api.py` and `ics_ems_api/controllers/api_v1.py` only as **examples**; the production contract is this new module.

5. **EMS data exchange**
   - **Primary path:** Odoo → **webhooks** → mobile backend → update **EMS mirror** → optional FCM.
   - **Writes:** mobile app → backend → Odoo **inbound API**; Odoo persists; optional follow-up webhook for state.
   - **Reconciliation:** scheduled job on backend (every 15 minutes) calls `/ems/integration/v1/reconcile?since=<cursor>` to pull deltas if webhooks were missed.

### MVP product scope

- **Parent-only** app role for first release: reject non-parent at backend **and** Odoo on write paths.
- Screens: Login, Forgot password, Home/dashboard, Children selector, Invoices list/detail, Results, Documents upload/download, Requests/forms, Payment success/failure, FCM + deep links.
- **Light + Dark themes** with in-app or settings toggle (and optional follow-system).
- Store module (catalog/cart/checkout) **out of MVP**, stub behind feature flag `feature.store_enabled`.

### Repository context

- Read **`MODULES_OVERVIEW.md`** and **`ics_ems_*` manifests** at repo root `altahtheeb-addons`.
- **EMS product and integration docs (mandatory read before coding):**
  - `altatheeb_mobile_app/docs/EMS_FLUTTER_MOBILE_SPECIFICATION.md`
  - `altatheeb_mobile_app/docs/EMS_FLUTTER_MOBILE_ARCHITECTURE.md`

### Example Flutter apps — reuse when helpful

Under **`altatheeb_mobile_app/examples/`** you may **reuse or adapt** the following **when it reduces risk and matches the agreed stack** (prefer **Cubit + Dio + GoRouter** in new code; migrating copied code from Provider/GetX is acceptable as a first step):

| Example | Path | Safe to reuse (typical) | Do **not** reuse |
|---------|------|-------------------------|------------------|
| **Our E-School** | `examples/Our-E-School-master/Our-E-School-master/` | Screen flows, MVVM layout ideas, multi-role navigation patterns, child switcher UX, chat/post **UI** sketches | Firebase / Firestore / Cloud Functions URLs, `server.dart` secrets, pre-null-safety patterns without migration |
| **SchoolMate** | `examples/SchoolMate-App-main/SchoolMate-App-main/` | Student/teacher/**school UI** navigation trees, announcements/tasks/marks **screen structure**, card layouts | Any hard-coded API base URLs, legacy auth tied to non-Odoo backends |

**Rules for reuse:** (1) **Replace all networking** with calls to **your mobile backend** only. (2) **Replace all state management** with **Cubit** (or wrap legacy in adapters temporarily and schedule refactor). (3) **Copy UI/widgets** only under your app's package and licence; attribute in code comments if the example is third-party OSS. (4) If a feature from examples is **out of MVP scope**, stub it behind a feature flag.

### Documentation — review, enhance, then implement

**Before and during implementation:**

1. **Re-read** the specification and architecture docs above; if you find gaps, contradictions, or missing webhook events / API routes needed for the sprint, **update those markdown files** in the same PR/sprint (concise edits only — no scope creep).
2. **Keep docs in sync** with what you ship: e.g. add a short **"Implementation notes"** subsection or bump **document version** in the spec footer when behaviour stabilises.
3. If you add a new env var, route, or event type, document it in **architecture** (webhook contract / OpenAPI) or in a small **`README.md`** next to the new service or Odoo addon.

**Workflow:** document drift you discover → patch docs → then implement (or minimal spike → doc update → full implement). Do not leave the repo with code that contradicts the spec without updating the spec or an explicit "Open decisions" item.

### Deliverables (in order)

1. **Odoo addon** `ics_ems_mobile_gateway`: `__manifest__.py`, security CSV, models for **integration settings**, **outbound delivery queue**, **inbound delivery log**, controllers (`/ems/integration/v1/{auth/verify,me,children,invoices,results,documents,requests,reconcile,webhooks/inbound}`), data for crons + sequences, README with env vars.
2. **Mobile backend** folder `altatheeb_mobile_app/mobile_backend/`: Dockerfile + docker-compose, OpenAPI spec auto-generated, Alembic migrations, seed script for local dev, integration tests against **Odoo running the new module**, FCM admin SDK wiring, RQ worker.
3. **Mobile admin web** `altatheeb_mobile_app/mobile_admin_web/`: React + Vite + TS, auth via backend, user list, role assignment, link to Odoo `partner_id`/`user_id` (federation fields shown), audit log, feature flags, min app version, webhook deliveries view.
4. **Flutter app** `altatheeb_mobile_app/app/`: feature modules matching MVP; environment config for **backend base URL only**; **theme layer** (`AppTheme.light` / `AppTheme.dark`) documented in README.

### Concrete env vars (single source of truth — keep in sync per service)

| Service | Variable | Purpose |
|---------|----------|---------|
| Odoo addon | `EMS_GATEWAY_BACKEND_URL` | HTTPS URL of mobile backend (`/integrations/odoo/v1/webhooks`) |
| Odoo addon | `EMS_GATEWAY_OUTBOUND_SECRET` | HMAC secret for outbound webhook signing (rotated quarterly) |
| Odoo addon | `EMS_GATEWAY_INBOUND_SERVICE_TOKEN` | Bearer token the backend sends to Odoo |
| Odoo addon | `EMS_GATEWAY_USER_CONTEXT_SECRET` | HMAC secret for `X-EMS-User-Context` |
| Odoo addon | `EMS_GATEWAY_CONTRACT_VERSION` | e.g. `1` (major), `1.0` published |
| Backend | `DATABASE_URL` | Postgres DSN |
| Backend | `REDIS_URL` | Redis DSN for RQ + caching |
| Backend | `JWT_SECRET` / `JWT_ALG` | App user JWT signing |
| Backend | `JWT_ACCESS_TTL` / `JWT_REFRESH_TTL` | Access/refresh TTL |
| Backend | `ODOO_BASE_URL` | Odoo HTTPS URL |
| Backend | `ODOO_SERVICE_TOKEN` | Bearer token sent to Odoo gateway |
| Backend | `ODOO_INBOUND_HMAC_SECRET` | Verifies signed webhooks **from** Odoo |
| Backend | `USER_CONTEXT_SECRET` | Same value as Odoo `EMS_GATEWAY_USER_CONTEXT_SECRET` |
| Backend | `FCM_PROJECT_ID`, `FCM_CREDENTIALS_PATH` | Firebase Admin SDK |
| Backend | `MIN_APP_VERSION_ANDROID`, `MIN_APP_VERSION_IOS` | Force-upgrade gate (overridable from admin) |
| Backend | `ALLOWED_CORS_ORIGINS` | Mobile admin SPA origin |
| Admin web | `VITE_API_BASE_URL` | Backend public URL |
| Flutter | `BACKEND_BASE_URL` (compile-time `--dart-define`) | Backend public URL only |

### Security model (concise)

- **Outbound (Odoo → backend):** sign canonical body with HMAC-SHA256; header `X-EMS-Signature: t=<unix_ts>,v1=<hex>`; reject if `|now - t| > 300s` or signature mismatch; idempotency on `delivery_id` (UUIDv4); 5xx/timeout → retry with backoff; >max retries → DLQ row in `ics.mobile.gateway.delivery` with state `dead`.
- **Inbound (backend → Odoo):** TLS + Bearer service token + signed user context header. Odoo gateway validates token, derives `parent_id`/`user_id`, then `with_user(user_id)` to apply Odoo record rules.
- **Flutter ↔ backend:** JWT access (15 min) + refresh (30 days, rotated). Tokens in `flutter_secure_storage` only. Logout on password change / role change / remote wipe.
- **Admin web ↔ backend:** session cookie (HttpOnly, Secure, SameSite=Lax) + CSRF token; admin role required; MFA recommended.
- **No secrets in app binary**; CI verifies with a secret scanner pre-merge.

### Webhook event catalogue v0 (12 events)

All events use payload envelope:

```json
{
  "integration_contract_version": "1.0",
  "delivery_id": "uuid-v4",
  "event": "<event name>",
  "resource": "<odoo model>",
  "ids": [123],
  "school_id": 1,
  "occurred_at": "2026-05-09T10:15:00Z",
  "write_date": "2026-05-09T10:14:59Z",
  "data": { /* minimal fields, see catalogue */ }
}
```

| # | Event | Resource (Odoo model) | When | Notify (FCM)? | Mirror table on backend |
|---|-------|-----------------------|------|---------------|--------------------------|
| 1 | `student.created` | `ics.student` | create | no | `ems_student` |
| 2 | `student.updated` | `ics.student` | write of indexed fields | no | `ems_student` |
| 3 | `student.parent_link.changed` | `ics.parent` ↔ `ics.student` M2M | link added/removed | no | `ems_student_parent` |
| 4 | `fee.invoice.posted` | `account.move` (student fee) | state → posted | yes (`fee_due`) | `ems_invoice` |
| 5 | `fee.invoice.paid` | `account.move` | payment_state → paid | yes (`fee_paid`) | `ems_invoice` |
| 6 | `fee.invoice.cancelled` | `account.move` | state → cancel | no | `ems_invoice` |
| 7 | `attendance.recorded` | `ics.student.attendance` | create | yes if absent (`attendance_absent`) | `ems_attendance` |
| 8 | `attendance.updated` | `ics.student.attendance` | write of `status` | conditional | `ems_attendance` |
| 9 | `exam.result.published` | `ics.student.grade` | state → published | yes (`exam_result`) | `ems_exam_result` |
| 10 | `report_card.published` | `ics.report.card` | state → published | yes (`report_card`) | `ems_report_card` |
| 11 | `leave_request.state_changed` | `ics.leave.request` | workflow change | yes (`leave_state`) | `ems_leave_request` |
| 12 | `announcement.published` | `mail.message` (school channel) or custom | when sent to scope | yes (`announcement`) | `ems_announcement` |

### REST API outline (mobile backend, public surface)

```
POST   /v1/auth/login                  -> {access, refresh, user, app_role, school_id}
POST   /v1/auth/refresh                -> {access, refresh}
POST   /v1/auth/logout                 -> {ok}
POST   /v1/auth/forgot-password        -> {ok}     (always 200 to avoid enumeration)
POST   /v1/auth/reset-password         -> {ok}

GET    /v1/me                          -> profile + linked students summary
GET    /v1/children                    -> [{student_id, name, grade, division, school_id}]
GET    /v1/children/{id}               -> details
GET    /v1/children/{id}/attendance    -> ?from=&to= paginated
GET    /v1/children/{id}/results       -> exam results / report cards
GET    /v1/children/{id}/invoices      -> ?state= paginated

GET    /v1/invoices/{id}               -> details + lines + payment_state
POST   /v1/invoices/{id}/pay-init      -> {payment_url} (hosted checkout)

GET    /v1/results/{id}
GET    /v1/documents                   -> list
POST   /v1/documents                   -> multipart upload (proxied to Odoo ir.attachment)
GET    /v1/documents/{id}/download

GET    /v1/requests                    -> list parent-submitted requests
POST   /v1/requests                    -> create (with client_operation_id)
GET    /v1/requests/{id}

POST   /v1/sync                        -> { cursors:{...} } returns deltas + new cursors
POST   /v1/devices                     -> register FCM token
DELETE /v1/devices/{id}

GET    /v1/config                      -> {min_app_version, maintenance_banner, feature_flags}
GET    /v1/notifications               -> in-app inbox

POST   /integrations/odoo/v1/webhooks  -> inbound from Odoo (HMAC-protected)

# Admin (cookie + admin role)
GET    /admin/v1/users
POST   /admin/v1/users/invite
POST   /admin/v1/users/{id}/role
POST   /admin/v1/users/{id}/disable
GET    /admin/v1/audit
GET    /admin/v1/feature-flags
PUT    /admin/v1/feature-flags/{key}
GET    /admin/v1/min-app-version
PUT    /admin/v1/min-app-version
GET    /admin/v1/webhook-deliveries
POST   /admin/v1/webhook-deliveries/{id}/replay
```

### REST API outline (Odoo gateway, server-to-server only)

```
POST   /ems/integration/v1/auth/verify        # verify backend-issued login against Odoo identity
GET    /ems/integration/v1/me
GET    /ems/integration/v1/children            # parent's students
GET    /ems/integration/v1/children/{id}
GET    /ems/integration/v1/children/{id}/attendance
GET    /ems/integration/v1/children/{id}/results
GET    /ems/integration/v1/children/{id}/invoices
GET    /ems/integration/v1/invoices/{id}
POST   /ems/integration/v1/invoices/{id}/pay-init
GET    /ems/integration/v1/documents
POST   /ems/integration/v1/documents           # multipart, proxied
GET    /ems/integration/v1/requests
POST   /ems/integration/v1/requests
GET    /ems/integration/v1/reconcile           # ?since=<iso8601>&resource=<name>
POST   /ems/integration/v1/webhooks/inbound    # optional inbound webhook style
```

### Quality gates

- Unit tests on backend business logic; **contract tests** for webhook signature and idempotency (replay attack must fail; double-delivery must be a no-op).
- Integration test: simulate Odoo webhook POST → mirror row updated → FCM payload shape validated (mock FCM).
- Flutter: golden or widget tests for **RTL/LTR** critical screens; **smoke test** critical flows in **both Light and Dark** themes (no invisible text/icons).
- Security: no secrets in git; document rotation for webhook HMAC and Odoo API key; CI runs `gitleaks` (or equivalent) on every PR.

### First sprint (≤ 2 weeks) — task list

**Week 1**
- [ ] T1 Repo scaffolds: `ics_ems_mobile_gateway`, `altatheeb_mobile_app/mobile_backend/`, `altatheeb_mobile_app/mobile_admin_web/`, `altatheeb_mobile_app/deploy/ems/`, `altatheeb_mobile_app/app/` with READMEs.
- [ ] T2 `ics_ems_mobile_gateway` manifest + security + integration settings model + outbound delivery model + cron stub + `_dispatch_event` mixin called by stubs (no auto-listeners yet).
- [ ] T3 Outbound HMAC signing + retry/backoff implementation; unit-tested.
- [ ] T4 Backend skeleton: FastAPI app, settings (Pydantic), `/v1/auth/login` (parent-only gate against Odoo `/auth/verify`), JWT + refresh.
- [ ] T5 Backend `/integrations/odoo/v1/webhooks` with HMAC verification, idempotency table, dispatcher to handlers (handlers stubbed).
- [ ] T6 Postgres schema + Alembic migration for `app_users`, `app_devices`, `webhook_delivery_log`, `idempotency_keys`, `ems_student`, `ems_invoice`, `ems_attendance`, `ems_exam_result`, `audit_log`, `feature_flags`, `min_app_version`.

**Week 2**
- [ ] T7 Backend `/v1/me` + `/v1/children` + `/v1/children/{id}/invoices` reading from mirror.
- [ ] T8 Wire Odoo `account.move` (student fee) `posted/paid/cancelled` to gateway dispatcher (events 4/5/6) and mirror them on the backend.
- [ ] T9 Wire `ics.student.attendance` create/write to events 7/8 and mirror.
- [ ] T10 Backend FCM dispatcher (mock in tests, real in dev with FCM emulator).
- [ ] T11 Admin web: login, user list, role assignment, feature flags, min app version, webhook deliveries view.
- [ ] T12 Flutter: bootstrap, theme layer (Light/Dark), localisation (AR/EN), Login, Children list, Invoices list/detail (read from `/v1/`), FCM registration, settings screen with theme + language toggle.
- [ ] T13 Smoke E2E: docker-compose with Odoo + Postgres + Redis + backend + admin; one synthetic invoice posted in Odoo → app sees it within 60s.

### Output format

Produce **concrete file trees**, **OpenAPI outline** (above), **webhook event catalogue v0** (above — extend per release), and **first sprint task list** (above). Include a **one-page "Doc changes"** summary if you edited `EMS_FLUTTER_MOBILE_SPECIFICATION.md` or `EMS_FLUTTER_MOBILE_ARCHITECTURE.md`. Note **which example-app paths** you borrowed from (if any) and what was rewritten for the backend-only architecture.

Implement code where the environment allows; otherwise output full patches per component.

### Definition of done (MVP parent app)

- A parent installs the app, logs in (backend → Odoo verify), sees children, opens a posted student-fee invoice, taps Pay → hosted checkout opens; once paid in Odoo, app refreshes invoice status within 60s via webhook → FCM → mirror update.
- Same flow works in both Arabic (RTL) and English (LTR) and in both Light and Dark themes.
- All Odoo writes from the app are auditable end-to-end (`client_operation_id` → backend outbox → Odoo log).
- No Odoo URLs / credentials are present in the Flutter binary (verified by inspection of the assembled APK / IPA).
- Security checklist (HMAC outbound, Bearer + signed user context inbound, JWT rotation, secret scanner) is green.

---

## PROMPT (copy until here)

### Local references

| Document | Path |
|----------|------|
| Product specification | `altatheeb_mobile_app/docs/EMS_FLUTTER_MOBILE_SPECIFICATION.md` |
| Technical architecture | `altatheeb_mobile_app/docs/EMS_FLUTTER_MOBILE_ARCHITECTURE.md` |
| This prompt | `altatheeb_mobile_app/docs/EMS_IMPLEMENTATION_MASTER_PROMPT.md` |
| Doc changes log | `altatheeb_mobile_app/docs/EMS_DOC_CHANGES.md` |
| First-sprint backlog | `altatheeb_mobile_app/docs/EMS_SPRINT_01.md` |
| Flutter example apps (optional reuse) | `altatheeb_mobile_app/examples/` |
| Odoo gateway addon | `ics_ems_mobile_gateway/` |
| Mobile backend | `altatheeb_mobile_app/mobile_backend/` |
| Mobile admin web | `altatheeb_mobile_app/mobile_admin_web/` |
| EMS Docker deploy | `altatheeb_mobile_app/deploy/ems/` |
| Flutter app | `altatheeb_mobile_app/app/` |

---

*This prompt file is maintained alongside the EMS mobile specification (v1.6+). Last updated: locked stack picks (FastAPI + React + Flutter + new Odoo addon `ics_ems_mobile_gateway`), env-var contract, security model, webhook catalogue v0 (12 events), full REST surface, and first-sprint backlog.*
