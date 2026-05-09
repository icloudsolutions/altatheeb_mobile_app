# EMS Flutter Mobile App — Product Specification

**Version:** 1.6 · **Language:** English (primary)  
**Audience:** product owners, solution architects, and engineering leads implementing the mobile platform, mobile admin web, mobile backend, and Odoo EMS integration.

This document defines the **multi-role** Flutter application (Android and iOS) for **parents, students, teachers**, and—**only where needed—school office users** with the same *class* of product features (requests, chat, announcements). It is aligned with **ICS Education Management System (EMS)** capabilities in the `altahtheeb-addons` repository (Odoo **19.0** manifests).

### Executive summary

The solution is an **autonomous mobile platform** (Flutter app + **dedicated mobile backend** + **platform database** + **mobile administration web**). The mobile client **never** calls Odoo. **EMS business data** lives in **Odoo 19 + `ics_ems_*` modules**; the platform stays consistent with Odoo through a **dedicated Odoo integration module** that implements **signed webhooks** (primarily Odoo → backend) and **authenticated APIs** (backend → Odoo) for writes, bootstrap, and reconciliation. **EMS staff administration** (fees setup, admissions office, accounting configuration, etc.) remains on **Odoo web** only; the mobile admin web manages **app users and app roles**, not Odoo back-office.

### Definitions

| Term | Meaning |
|------|---------|
| **Mobile platform** | Mobile backend API + its database + file storage + FCM orchestration + mobile admin web. |
| **EMS mirror** | Data replicated or derived from Odoo on the platform DB for read-optimised mobile responses; Odoo remains source of truth for EMS invariants. |
| **Dedicated integration module** | New Odoo 19 addon (e.g. `ics_ems_mobile_gateway`): sole technical bridge for webhooks and server-to-server APIs to EMS models. |
| **App role** | Role used by the mobile platform (`parent`, `student`, `teacher`, `office`) — enforced on the backend and again in Odoo where EMS writes occur. |

**Target integration model (adopted):**

| Layer | Role |
|-------|------|
| **Flutter mobile app** | **Separated** from all other systems: talks **only** to the **mobile backend**; no Odoo URLs, no Odoo credentials, no runtime dependency on Odoo in the client. |
| **Mobile platform (backend + DB + files + admin web)** | **Own resources** and lifecycle: auth, users, roles, caching, FCM, store/chat/requests as designed **on the platform**. The app **works as one system**; it does not “call Odoo” from the phone. |
| **Web application (mobile administration)** | **User administration and app roles** (invites, resets, audit, feature flags, min app version). Separate from Odoo EMS staff screens. |
| **Odoo 19 + EMS** | **Authoritative** for **EMS business data** (fees, grades, attendance, master identity links, …). The mobile backend **does not** replace Odoo for those domains; it **exchanges** EMS-related updates with Odoo through a **defined webhook contract** (and supporting APIs where a pull or confirm is required — see architecture doc). |

**Principle — autonomy vs EMS:**

- **Autonomous:** Login, navigation, notifications delivery, and any features implemented **fully on the mobile platform** operate **without depending on another system** at runtime (beyond the mobile backend itself).
- **EMS-aligned:** Data that **originates or is owned** in Odoo is **replicated or updated on the mobile backend** through **webhooks** (Odoo → backend) and **signed outbound calls / optional inbound webhooks** (backend → Odoo) so both sides stay consistent without the mobile app ever talking to Odoo directly.

**Odoo EMS administration** (admissions processing, fee structure design, accounting configuration, EMS security groups for staff, reporting builders, etc.) remains on **Odoo web**; it is **not** duplicated on the mobile admin web unless you explicitly choose to surface read-only links.

**Related documents:** [EMS_FLUTTER_MOBILE_ARCHITECTURE.md](./EMS_FLUTTER_MOBILE_ARCHITECTURE.md) (technical architecture) · [EMS_IMPLEMENTATION_MASTER_PROMPT.md](./EMS_IMPLEMENTATION_MASTER_PROMPT.md) (copy-paste implementation prompt for agents).

**Reference implementations (examples only, not production backends):**

| Example | Path | Relevance |
|--------|------|-----------|
| Our E-School | `altatheeb_mobile_app/examples/Our-E-School-master/Our-E-School-master/` | Multi-role login (parent / teacher / student), child switching, chat, posts, MVVM + Provider; historically Firebase-backed — **patterns to reuse**, backend replaced by Odoo. |
| SchoolMate | `altatheeb_mobile_app/examples/SchoolMate-App-main/SchoolMate-App-main/` | Student / teacher / **admin** areas in the sample app refer to **school UI personas**, not Odoo EMS back-office; use for navigation patterns (announcements, tasks, marks, chat) only. |

---

## 1. Goals and scope

### 1.1 Goals

- Single installable app (one bundle ID) with **role-aware** experience after authentication, or optional **flavour** builds per school branding (out of scope for MVP unless required).
- **Odoo EMS** remains the **system of record** for academics, fees, attendance, admissions, transport, and identity.
- **Web administration (mobile platform)** controls app users, **roles**, invites, mobile feature flags, minimum supported app versions, and push campaign **targeting** (execution may run on the mobile backend + FCM).
- **Reliable sync** between mobile clients and **mobile backend** (cursors, outbox). **EMS-related** consistency with Odoo is primarily **event-driven** via **webhooks** defined between the **dedicated Odoo 19 integration module** and the mobile backend; optional on-demand API on the module for bootstrap, reconciliation, and writes that cannot be expressed as a single webhook payload.

### 1.2 Out of scope (initial phases)

- **EMS administration on mobile:** no admission pipeline boards, document verification queues, fee structure design, accounting configuration, user/group management, module settings, or executive reporting UIs—all **Odoo web** only.
- Replacing Odoo accounting or HR payroll UIs for staff (mobile may surface **summary** data only where explicitly allowed for parents/students/teachers).
- Full LMS (online courses) unless added as a future EMS module.
- Real-time GPS fleet tracking UI beyond what `ics_ems_transport` exposes as data.

### 1.3 MVP scope (explicit)

| In scope (MVP) | Out of scope (MVP) |
|------------------|---------------------|
| Parent journey: login, children list, dashboard, invoices, results, documents, requests/forms, payments (per policy), FCM + deep links, Arabic/English RTL/LTR | Teacher/student/office app roles (same architecture later) |
| Mobile backend + admin web + webhook-driven EMS mirror | Full duplicate of Odoo EMS UI on web or mobile |
| Dedicated Odoo integration module: outbound webhooks + inbound APIs | Flutter calling Odoo JSON-RPC directly |

### 1.4 Success criteria (examples)

- Parents can complete daily tasks **without Odoo URLs** in the app binary.
- After an invoice or grade change in Odoo, the mobile user sees updated data within an agreed **SLA** once webhooks are delivered (or sees **stale/pending** state if Odoo/backend is unreachable).
- All EMS writes from the app are **auditable** and **idempotent** end-to-end (client → backend → Odoo).
- Security review: no Odoo credentials on devices; integration secrets only on servers.

---

## 2. Stakeholders and roles

| Role | Primary users | EMS alignment | Mobile intent |
|------|-----------------|---------------|-----------------|
| **Parent** | Guardians | `ics_ems_core` (parent–student links), `ics_ems_parent_portal`, fees, attendance, academic | Same capabilities as parent portal where safe: children list, attendance, grades, invoices, leave requests, announcements, messaging. |
| **Student** | Enrolled learners | `ics_ems_core`, academic, attendance, library (read) | Timetable (when available), tasks/homework, grades, attendance self-view, announcements, transport subscription view. |
| **Teacher** | Instructional staff | `ics_ems_core`, `ics_ems_academic`, `ics_ems_attendance`, HR where relevant | Mark attendance, enter grades, view class lists, leave approvals as per ACLs, announcements to classes. |
| **School office / reception** (optional mobile persona) | Office staff who are not “EMS admins” in product terms | `mail` / chatter, optional ticketing or “request” models | **Same feature family as the community app:** inbound/outbound **requests**, **chat** (or moderated threads), reading/sending **announcements**, simple **inbox**—**not** EMS configuration, admission workflow management, or registrar back-office screens. |

Odoo security groups described in `MODULES_OVERVIEW.md` (User → Teacher → Manager → Administrator) map to **server-side** enforcement; the app only **reflects** granted permissions.

---

## 3. Functional requirements by domain

Requirements are traced to EMS modules in this repo (`MODULES_OVERVIEW.md`, module manifests).

### 3.1 Identity and access

- **Primary:** login and tokens issued by the **mobile backend**; optional link/mapping to `res.users` / portal identity in Odoo via the **dedicated Odoo module** (product decision: same password as Odoo vs separate app password + federation).
- School-aware account and multi-tenant behaviour (multi-school): enforced in **backend + Odoo** rules.
- Session or **JWT** access to the mobile API; forced logout on password change, role change, or remote wipe from **mobile admin web**.
- Device registration (platform, app version, **FCM token**) stored in the **mobile backend**; backend may mirror tokens into Odoo (`ics.mobile.device`) **only if** you still want Odoo-side triggers to send pushes through Odoo—otherwise FCM can be fully backend-driven.

### 3.2 Parent

- View linked students and profile summary (`ics.parent` / `ics.student`).
- Attendance history and notifications for absences (`ics_ems_attendance`).
- Fee invoices, balance, payment status (`ics_ems_fees`); deep link to payment portal where applicable.
- Report cards / exam results as exposed by `ics_ems_academic` and portal rules.
- Leave request submission and tracking (`ics_ems_attendance` leave models).
- School announcements and optional teacher–parent messaging (align with `mail` / chatter policies).

### 3.3 Student

- Dashboard: today’s classes (when timetable exists in EMS), pending tasks, recent grades.
- Read-only attendance and exam results per school policy.
- Library loans and due dates (`ics_ems_library`) if exposed via API.

### 3.4 Teacher

- Class or subject roster for current academic year/term.
- Daily attendance capture with offline queue and conflict handling (`ics_ems_attendance`).
- Grade entry for assigned subjects/exams (`ics_ems_academic`).
- Publish announcements to scoped groups (class/grade/school).

### 3.5 School office (communications only — optional)

- **Included (examples):** unified or role-tagged **request** inbox (general enquiries, maintenance of contact details where policy allows), **chat** with parents/teachers/students per ACLs, **announcements** consumption and—if granted—publishing school-wide notices (content rules enforced server-side).
- **Excluded:** anything that constitutes **EMS administration**: managing admission applications as staff, editing fee structures, enrolling students, editing master data, running EMS reports, or changing security—staff use **Odoo** for that.

### 3.6 Cross-cutting

- **Notifications:** attendance, grade published, fee due, messages/requests — **FCM** is owned by the **mobile backend**; Odoo drives updates via **webhooks** to the backend, which updates the mirror and sends FCM (see architecture: webhook ↔ FCM mapping). Do not require Odoo to call FCM directly unless an explicit legacy exception is approved.
- **Offline:** cached read models on device; explicit **pending sync** for allowed writes; backend reconciles with Odoo.
- **Localization:** **Arabic and English from day one** (`intl` + ARB or equivalent); verify **RTL** and **LTR** layouts, mirrored icons, and input fields early in QA.

### 3.7 Payments (clarification)

- **In-app native wallet SDK** (e.g. Amazon Pay) is optional; **alternative** is hosted checkout: mobile backend returns a **payment URL** produced by Odoo’s payment acquirer flow—**no provider SDK in Flutter**, only WebView/browser. Legal review applies for **school fees** vs **physical store** goods under Apple/Google policies.
- Final payment state must be reflected in Odoo and propagated to the app via **webhook** or confirmed read after redirect.

---

## 4. Web administration (two planes)

### 4.1 Mobile platform web application (new / separated)

Used by **school IT or operations** (not EMS data entry clerks unless you grant access): **mobile app users**, **app roles** (parent / student / teacher / office), invitations, password reset flows for the app, audit logs, **feature flags**, **minimum app version**, maintenance banner, and optional **push audience** definitions.

- This application shares a database or API with the **mobile backend**; it does **not** replace Odoo for fee rules, grades, or admission workflows.

### 4.2 Odoo web (EMS + portal)

| Function | Where administered |
|----------|---------------------|
| School master data, fees, attendance, academics, admissions | Odoo EMS modules (`ics_ems_*`) |
| **Odoo** security groups / record rules for staff | Odoo Settings / EMS (`ics_ems_core`, `ics_ems_base`) |
| Parent portal content and templates | `ics_ems_parent_portal` |
| **Integration credentials** for the mobile backend to call Odoo | Dedicated **Odoo 19 integration module** (API keys, OAuth client, IP allowlist — design choice) |
| Optional: mirror of mobile devices in Odoo | `ics_ems_mobile_app` if you keep bi-directional sync with Odoo for push from Odoo events |

### 4.3 Operational workflows

- **Force upgrade / maintenance:** enforced by **mobile backend** (config from mobile admin web).
- **Broadcast announcement:** if sourced from Odoo, deliver updates to the mobile platform via **webhook** (preferred) or scheduled reconciliation — avoid requiring the Flutter app to pull Odoo directly.

---

## 5. Sync model (product view)

### 5.1 Mobile app ↔ mobile backend

- Normal **request/response** and **sync cursors** on the platform DB; **offline outbox** where needed.
- The mobile app **never** synchronises directly with Odoo.

### 5.2 EMS data: Odoo ↔ mobile backend (webhooks)

For **the same EMS-related features** (invoices, results, attendance snapshots, student–parent links, payment outcomes, …), **exchange of data is defined as webhooks** (and companion APIs where required):

| Direction | Purpose (examples) |
|-----------|---------------------|
| **Odoo → mobile backend** | Notify on `create` / `write` / state change on EMS models; payload carries event type, record ids, `write_date`/version; backend **fetches or applies** idempotently and updates its **local EMS mirror** / cache. |
| **Mobile backend → Odoo** | Parent/teacher actions that must persist in EMS (e.g. submit request, confirm payment): backend calls Odoo **integration module** API **or** posts to an **Odoo-exposed inbound webhook** URL — choose one standard per operation; must be **signed**, **idempotent**, and auditable. |

- **Conflict / truth:** Odoo remains **source of truth** for EMS invariants; the backend **reconciles** on webhook and on API errors; UI shows **last known good** from the platform when Odoo is temporarily unreachable, with clear **stale** / **pending sync** states where product requires it.

Detailed signing, retry, and event catalogue are in the architecture document.

---

## 6. Non-functional requirements

- **Security:** TLS only; no Odoo or integration secrets in the app binary; optional certificate pinning; rotate webhook signing secrets; rate-limit public endpoints.
- **Performance:** initial dashboard load within agreed SLA on typical mobile networks; paginated lists; bounded webhook processing latency on the backend.
- **Reliability:** webhook **retry and dead-letter** policy from Odoo when the mobile backend is down; **reconciliation jobs** on the backend to heal missed events.
- **Compliance:** minimise personal data on device; support account deletion / export workflows per school policy; audit logs on backend and Odoo integration module.
- **Store policies:** Google Play / Apple guidelines for in-app payments (fees vs merchandise); prefer hosted checkout when in doubt.

---

## 7. Implementation roadmap (phased delivery)

Phased plan for the **parent-first MVP** (Phases 2–6). **Teacher / student / office** roles reuse the same platform architecture later with extended RBAC and Odoo integration events. RBAC in Phase 2 must be **enforced on the mobile backend** and **re-validated in Odoo** for any EMS write.

### Phase 1 — Project setup

| Item | Detail |
|------|--------|
| **Architecture** | Flutter **Clean Architecture** or **MVVM** with clear layers: presentation, domain, data. |
| **Dependencies** | **Dio**, **Cubit** (`flutter_bloc`), **GoRouter**; local persistence: **Hive** or **shared_preferences** (Hive preferred for structured cache and outbox). |
| **Localization** | **Arabic and English from day one** (`intl` + ARB); early **RTL/LTR** QA on real devices. |
| **Themes** | **Light** and **Dark** `ThemeData` / `ColorScheme`; persist preference (system / light / dark per product); validate contrast on MVP screens in both themes. |

### Phase 2 — Authentication

| Item | Detail |
|------|--------|
| **UI** | **Login** and **Forgot password** (forgot flow defined with product: email link via backend, not raw Odoo in the app). |
| **Backend** | Auth against **mobile backend**; backend validates identity using **dedicated Odoo integration module** and/or platform user store linked to Odoo partner/user ids (design choice). |
| **Token storage** | **flutter_secure_storage** for access/refresh tokens; never store secrets in plain `shared_preferences`. |
| **RBAC (MVP)** | If `app_role` ≠ `parent`, block access to this parent app build with a clear message; **same rule enforced in Odoo** on every EMS mutation path. |

### Phase 3 — Core screens

| Area | Scope |
|------|--------|
| **Home** | Dashboard after child selection when multiple children exist. |
| **Invoices** | List, detail, payment state — data from **platform EMS mirror** fed by webhooks/API. |
| **Results** | Grades / report cards per school policy and mirrored Odoo academic data. |
| **Documents** | Upload and download via **mobile backend** (proxied to Odoo `ir.attachment` through integration module). |
| **Requests** | Complaints, requests, forms — persisted in Odoo as agreed; surfaced only through backend APIs. |

### Phase 4 — Payments

| Item | Detail |
|------|--------|
| **Amazon Pay (optional)** | Native SDK only if product/legal approves; otherwise **hosted checkout** URL from backend/Odoo. |
| **Flow** | Full **initiate → confirm** with explicit **success** and **failure** screens. |
| **Odoo** | Payment confirmation recorded on Odoo fee/accounting models; state changes **webhook** to mobile backend for UI sync. |

### Phase 5 — Notifications

| Item | Detail |
|------|--------|
| **FCM** | Configure Firebase Cloud Messaging; store device tokens on **mobile backend** (not required in Odoo). |
| **Handlers** | **Foreground**, **background**, and **terminated** handling; no lost taps on notification open. |
| **Deep linking** | Map each notification type to the correct screen via **GoRouter** and a stable server-defined payload schema. |

### Phase 6 — Store (if in product scope)

| Item | Detail |
|------|--------|
| **Catalog** | Product listing (source: Odoo `sale` / `product.template` or school-specific catalogue model). |
| **Cart** | Cart and checkout. |
| **Checkout** | Payment as in Phase 4 (Amazon Pay or regional alternative). |

### Phase 7 — Testing and polish

| Item | Detail |
|------|--------|
| **Unit tests** | Business logic in Cubits / use cases without UI. |
| **Integration tests** | Real or mocked **mobile backend**; contract tests against **Odoo integration module** on staging. |
| **UI** | Bilingual polish: spacing, directional icons, form fields for **RTL** and **LTR**. |

### Roadmap notes

- **Parent first:** Phases 2–6 target the **parent** persona; extend roles without changing the high-level topology (Flutter → backend → Odoo module).
- **App store compliance:** school **fee** payments may require **web checkout** instead of certain in-app flows—confirm with legal before shipping native wallet SDKs for fees only.

---

## 8. Traceability to repository modules

| EMS module | Mobile relevance |
|------------|------------------|
| `ics_ems_core` | Schools, years, grades, students, parents, teachers — core navigation and ACL scope. |
| `ics_ems_admission` | **Back-office and portal flows on web**; mobile does not target registrar/admission-officer EMS screens. Parents may see **status** via portal/mobile only if exposed as read-only data. |
| `ics_ems_fees` | Parent/student billing views. |
| `ics_ems_attendance` | Parent visibility; teacher capture; student self-view. |
| `ics_ems_academic` | Exams, results, report cards. |
| `ics_ems_transport` | Subscriptions and trip-related summaries. |
| `ics_ems_library` | Loans and catalogue search (API-dependent). |
| `ics_ems_parent_portal` | Parity target for parent-facing features and legal visibility rules. |
| `ics_ems_mobile_app` | **Optional** if Odoo still sends some pushes or stores devices; not required if FCM is **100% mobile backend**. |
| `ics_ems_api` | Reference for key-based patterns; **dedicated Odoo 19 integration module** is the preferred contract for the separated backend. |
| **Dedicated Odoo 19 module (new)** | **Single integration surface:** outbound **webhooks** to the mobile backend for EMS events, **inbound** authenticated endpoints (REST and/or inbound webhook) for writes and reconciliation; identity bridge and attachments as agreed. |

---

## 9. Decisions (locked for v1.7)

| # | Decision area | **Locked choice** | Rationale |
|---|---------------|-------------------|-----------|
| 1 | App composition | **Single app** with role-aware shell; flavour builds only if multi-school branding becomes a hard requirement | Lower maintenance cost; same backend for all roles |
| 2 | Authentication | **JWT** issued by mobile backend (HS256, access 15 min, refresh 30 days, rotated); federation to Odoo `res.users` via gateway `/auth/verify`; tokens in **flutter_secure_storage** only | Stateless backend, easy to revoke |
| 3 | Odoo module | **New addon `ics_ems_mobile_gateway`** in this repo (`altahtheeb-addons/`) | Co-located with EMS dependencies; single CI |
| 4 | Webhook catalogue | **v0 = 12 events** (see architecture §4.7.1); payload **minimal** (ids + indexed fields); **retry with exponential backoff** in Odoo | Bandwidth-efficient; backend pulls full snapshot only when needed |
| 5 | Chat (MVP) | **No in-app chat** in v1; show announcements + structured **requests** instead | Reduces moderation/legal load |
| 6 | Payments (school fees) | **Hosted checkout** URL returned by backend (Odoo payment acquirer); no native wallet SDK in v1 | App-store policy safety for fees |
| 7 | Store catalog | **Out of MVP**, feature flag `feature.store_enabled` off | Defer until merchandise pipeline is defined |

### Open items (post-MVP)

- Teacher / student / office shells — same architecture, extend RBAC in backend + Odoo gateway.
- Native wallet SDK (Amazon Pay / Stripe) for store flow if launched.
- In-app chat moderation policy and provider choice.

---

## 10. Doc-changes summary (v1.6 → v1.7)

- **Locked open decisions** §9 (single app, JWT, gateway addon name, hosted checkout, no in-app chat in v1, store deferred).
- **Architecture companion** updated to v2.2 with webhook event catalogue v0 (12 events) and full REST API inventory for both the mobile backend public surface and the Odoo gateway server-to-server surface.
- **Implementation prompt** v1.7: locked stack picks (FastAPI + React + Flutter + Odoo addon `ics_ems_mobile_gateway`), env-var contract, security model, first-sprint backlog, definition of done.

---

*Document version: 1.7 — ICS EMS addons in `altahtheeb-addons` (Odoo **19.0**). **Architecture:** autonomous mobile platform; **EMS** sync via **signed webhooks** + dedicated Odoo integration module `ics_ems_mobile_gateway`. Companion: [EMS_FLUTTER_MOBILE_ARCHITECTURE.md](./EMS_FLUTTER_MOBILE_ARCHITECTURE.md) (v2.2). Implementation prompt: [EMS_IMPLEMENTATION_MASTER_PROMPT.md](./EMS_IMPLEMENTATION_MASTER_PROMPT.md) (v1.7).*
