# EMS Mobile — Sprint 01 backlog (≤ 2 weeks)

Goal: a parent on a fresh device can sign in, see children, see fee invoices,
get a push when an invoice is posted in Odoo — in **both** Arabic (RTL) and
English (LTR), in **both** Light and Dark themes — running end-to-end in
local docker-compose with the existing EMS data.

## Definition of done

* The smoke-test flow described in `EMS_IMPLEMENTATION_MASTER_PROMPT.md`
  ("Definition of done — MVP parent app") passes locally on dev machines.
* Webhook signing + idempotency tests are green
  (`altatheeb_mobile_app/mobile_backend/tests/test_webhook_signature.py`,
  `ics_ems_mobile_gateway/tests/test_outbound_signing.py`).
* No Odoo URL or HMAC secret is reachable from the Flutter binary
  (manual inspection of the assembled APK).
* Light + Dark theme widget smoke test passes
  (`altatheeb_mobile_app/app/test/theme_smoke_test.dart`).

## Tasks

### Week 1 — plumbing

| # | Task | Where | Owner |
|---|------|-------|-------|
| T1 | Repo scaffolds (READMEs, Dockerfile, compose, manifest) | All four deliverables | Team |
| T2 | `ics_ems_mobile_gateway` manifest + security + integration settings model + outbound delivery model + cron stub + dispatcher | `ics_ems_mobile_gateway/` | Backend (Odoo) |
| T3 | Outbound HMAC signing + retry/backoff + DLF; unit tests pass | `ics_ems_mobile_gateway/models/outbound_delivery.py` | Backend (Odoo) |
| T4 | FastAPI app + settings + JWT + `/v1/auth/login` calling Odoo `/auth/verify` (parent gate) | `altatheeb_mobile_app/mobile_backend/app/api/v1/auth.py` | Backend |
| T5 | Webhook receiver + HMAC verify + idempotency table + dispatch handlers (stubbed) | `altatheeb_mobile_app/mobile_backend/app/api/integrations/odoo_webhooks.py` | Backend |
| T6 | Postgres schema + Alembic 0001_initial | `altatheeb_mobile_app/mobile_backend/alembic/versions/0001_initial.py` | Backend |

### Week 2 — feature glue

| # | Task | Where | Owner |
|---|------|-------|-------|
| T7 | `/v1/me`, `/v1/children`, `/v1/children/{id}/invoices` reading from mirror with gateway fallback | `altatheeb_mobile_app/mobile_backend/app/api/v1/{me,children}.py` | Backend |
| T8 | Wire `account.move` posted/paid/cancelled → events 4/5/6 + mirror upsert | `ics_ems_mobile_gateway/models/account_move_listener.py`, `altatheeb_mobile_app/mobile_backend/app/services/webhook_dispatcher.py` | Backend (Odoo) + Backend |
| T9 | Wire `ics.student.attendance` create/write → events 7/8 + mirror | `ics_ems_mobile_gateway/models/attendance_listener.py` | Backend (Odoo) |
| T10 | FCM service (no-op in tests, real in dev with creds) + parent-of-student lookup | `altatheeb_mobile_app/mobile_backend/app/services/{fcm,notifications}.py` | Backend |
| T11 | Admin web: login, user list, role assignment, feature flags, min app version, webhook deliveries view | `altatheeb_mobile_app/mobile_admin_web/src/pages/*` | Frontend |
| T12 | Flutter: bootstrap, theme, AR/EN locales, Login, Children list, Invoices list/detail, Settings (theme + lang), FCM registration | `altatheeb_mobile_app/app/lib/**` | Mobile |
| T13 | Smoke E2E in docker-compose: Odoo + Postgres + Redis + backend + admin; one synthetic invoice posted in Odoo → app sees it within 60 s | All | Team |

## Risks & mitigations

* **Odoo addon discoverability** — `ics_ems_mobile_gateway` depends on
  `ics_ems_fees`, `ics_ems_attendance`, `ics_ems_academic`,
  `ics_ems_parent_portal`. Ensure addons_path is correct on shared dev DBs.
* **Webhook reachability** — local dev uses docker bridge network; staging /
  prod must add the backend's public URL to firewall allowlist.
* **Time skew** — webhook signature check has a 300 s skew window; servers
  must run NTP. Document in `altatheeb_mobile_app/mobile_backend/README.md` (already noted).

## Out of scope (Sprint 01)

* Hosted-checkout payment flow (placeholder route present).
* Document upload / download (route stubs present, no controller yet).
* `requests` create/list (route stubs present).
* Teacher / student / office shells.
