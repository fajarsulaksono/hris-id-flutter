# Architecture & Development Roadmap (hris-id-flutter)

This document is the reference for the app's architecture and the development phases
after the initial scaffold. The current foundation status and backend prerequisites are
described up front so each phase has a clear contract with `hris-id-laravel`
(REST API `/api/v1`, Sanctum).

---

## Current Foundation Status

| Area | Status | Notes |
|---|---|---|
| Auth | ✅ Done | `AuthController` (Riverpod), login/logout/restore via Dio, token in `flutter_secure_storage` |
| Structure | ✅ Done | `core/`, `features/`, `shared/` per `docs/FLUTTER_MOBILE.md` |
| Navigation | ✅ Done | `HomeShell` with 5 tabs; other features still placeholders |
| Testing | ⚠️ Minimal | 1 widget test (login screen); no unit tests for repositories/controllers yet |
| API layer | ✅ Done | `dioProvider` + `AuthInterceptor` (Bearer, 401 cleanup) + `ApiException` mapping |
| Configuration | ✅ Done | `API_BASE_URL` via `--dart-define`, default `localhost:9100/api/v1` |

---

## Architecture

### Layered, feature-first folder layout

```
lib/
├── core/                    cross-cutting infrastructure (no feature logic)
│   ├── config/              ApiConfig (base URL via --dart-define)
│   ├── api/                 dioProvider, AuthInterceptor, ApiException
│   └── storage/             TokenStorage (flutter_secure_storage)
│
├── features/                one folder per business capability
│   └── <feature>/
│       ├── data/            models + repository (the only place calling the API)
│       ├── application/     Riverpod controllers/providers (state + business flow)
│       └── presentation/    screens & widgets (pure UI)
│
├── shared/                  reusable, non-domain helpers
│   ├── theme/               AppTheme
│   ├── widgets/             common widgets (e.g. FeaturePlaceholder)
│   └── utils/               formatting (e.g. rupiah())
│
├── app.dart                 MaterialApp root (ProviderScope in main.dart)
└── main.dart
```

### Request / data flow

```
Screen (ConsumerWidget)
   │ watch()
   ▼
Controller (Notifier / AsyncNotifier)      ← state + business rules
   │ read()
   ▼
Repository (features/<x>/data)             ← the only layer touching Dio
   │
   ▼
dioProvider (core/api)                     baseUrl + AuthInterceptor
   │
   ▼
REST API (hris-id-laravel /api/v1)
```

UI never interacts with `Dio` directly; state lives in controllers, and repositories
are the single boundary for network calls. `AuthInterceptor` is the only place that
attaches the `Authorization: Bearer` header.

### Key rules

- **Models are immutable** (plain `fromJson`/`toJson` matching the API Resource `data`
  wrapper). Consider `freezed` in Phase 6 when the model set stabilizes.
- **Error handling**: repositories throw `ApiException` (mapped from `DioException`);
  controllers catch it; UI renders the message via state/SnackBar — no raw exceptions
  leak into widgets.
- **Role-aware UI**: authorization mirrors the web `Security::can` using the *abilities*
  returned by `/auth/me`, never by hardcoding role names.
- **Network-only for MVP**: no local cache; re-evaluate offline/query caching in Phase 6.

### Backend contract this app relies on

- Success payloads follow the API Resource shape: `{"data": {...}}` for a single record,
  `{"data": [...], "links": ..., "meta": ...}` for lists.
- Pagination via `p` (page) / `ep` (entries per page); partial search via `q`.
- Authorization via Sanctum token abilities enforced by `CheckApiRole` (403 JSON).

---

## Backend Prerequisites (blocking, from `docs/FLUTTER_MOBILE.md` in hris-id-laravel)

Before Phases 2–4 can be fully implemented, the backend must provide:

1. **Mutation endpoints** for `attendances`, `leaves`, `overtimes` (`mutable: true` + rules in
   `app/Support/ApiModules.php`); the approval observer must also run on API-created records.
2. **Token expiry** (`config/sanctum.php`) + `auth/refresh`; automatic replacement on 401.
3. **Approval workflow** for leave/overtime (status `approved_by_id`/approval) — a prerequisite for
   Phase 3 and correlated with the High-priority item in the web `docs/RECOMMENDATIONS.md`.
4. **Push FCM**: a `device_tokens` table + registration endpoint.

> Contract check: make sure backend effort is prioritized in parallel with Phases 1–2.

---

## Priority Summary

| Priority | Phase | Summary |
|---|---|---|
| 🔴 High | 1 | Polish Auth & Profile (session restore, `me()`, biometrics) |
| 🔴 High | 2 | Attendance: clock-in/out & history (needs mutation endpoints) |
| 🟠 Medium | 3 | Leave & Overtime: requests + approval status |
| 🟠 Medium | 4 | Payslip: salary & component breakdown |
| 🟡 Later | 5 | In-app notifications & FCM push |
| 🟢 Release | 6 | Hardening: offline cache, security, testing/CI, flavors & store |

---

## Phase 1 — Full Auth & Profile

**Goal:** durable session, visible user identity, basic security in place.

- Restore the session transparently: if a token exists, validate it via `/auth/me`; on 401 → logout.
- Store the user data (`AuthUserResource`) returned by `/auth/me` in state; show name/role in the shell.
- Logout from all screens (not just Profile); exit button + token cleanup.
- Biometrics (optional): `local_auth` to unlock a short-lived session (`flutter_secure_storage` is ready).
- Role-aware menu: hide items whose ability is not granted (mirroring the web `Security::can`).

**Deliverables:** `AuthState` containing `user`; a `sessionController` provider; Profile screen showing
real data; widget tests for failed/successful login (mocked Dio); role-aware menu.

**Acceptance criteria:** valid login → token + user shown; wrong password → the
`Username atau password salah.` message; expired token → automatic return to login.

---

## Phase 2 — Attendance (Clock In/Out)

**Goal:** employees record their presence from their phone.

- **Backend**: enable `mutable` `attendances` (`employee_id` taken from the token, not the body).
- The Attendance screen shows a **Clock In / Clock Out** button (date & check time).
- One-month history (list) + today's summary (total hours, status).
- Validation: one record per day; prevent double clock-in via the backend response.
- Display error messages straight from `ApiException`.

**Deliverables:** `attendanceController` (Riverpod `AsyncNotifier`), `Attendance` model, clock-in/out
+ history screen, widget/unit tests with a mocked repository.

**Acceptance criteria:** clock-in → appears in history; second clock-out → server error shown;
no network (offline) → clear indicator, no crash.

---

## Phase 3 — Leave & Overtime (Self-Service + Status)

**Goal:** submit requests without having to go to the web.

- **Backend**: `mutable` `leaves`/`overtimes`; approval workflow (status & `approved_by`).
- Request form: type (annual/special leave; overtime), date, start–end time, notes.
- Provide date options from `Reason`/holidays (related API available).
- Request history with status: *Pending / Approved / Rejected*.
- Refetch the list when returning from the form (e.g. `ref.invalidate` after submit).

**Deliverables:** `leaveController`, `overtimeController`, `Leave`/`Overtime` models, form screen +
history, unit test for the submit cycle.

**Acceptance criteria:** a successful request → appears in history as Pending; auto-approved
overtime → status changes (auto refresh); client-side date validation (no past dates).

---

## Phase 4 — Payslip

**Goal:** employees view their digital payslip.

- **Backend**: ensure `payrolls` + `payroll-details` access is owner-scoped (`employee_id` from the
  token) and values are already decrypted (as done by the web Resource).
- Period list → detail with take-home pay + compensation/allowance-deduction breakdown.
- Rupiah formatting via `shared/utils/rupiah.dart`.
- **Policy**: never cache payroll payloads locally; render on a per-request basis only.

**Deliverables:** `payrollController`, `Payroll`/`PayrollDetail` models, list + detail screens,
formatting test.

**Acceptance criteria:** only the user's own periods appear; take-home pay and breakdown are
consistent; numbers formatted as `Rp5.000.000`.

---

## Phase 5 — Notifications

- In-app: a tab/page with the notification history (the server exposes the endpoint — item 4 in the
  backend prerequisites above).
- FCM push: register `device_token` on login, unregister on logout; existing email notifications gain
  a push channel without changing the email logic (web).
- Deep link: tapping a notification opens the related screen (payslip/leave).

**Deliverables:** notification provider, device register/unregister, history screen, tap handling.

**Acceptance criteria:** the user receives a push when overtime is approved; the device token is
registered once; tapping a push opens the relevant screen.

---

## Phase 6 — Hardening & Release

- **Offline/minimal-network behavior**: no crash without a connection; clear messages + retry.
- **Security**: `flutter_secure_storage` (done), never log tokens, keep back-end validation on the
  web, minify & obfuscate the release (`--obfuscate --split-debug-info`), certificates & iOS ATS.
- **Testing**: unit tests for repositories/controllers (mocked Dio), key widget tests, ≥ 60% coverage
  target; `flutter test` green in CI.
- **CI**: GitHub Actions (analyze, test, build debug APK); fvm used in the pipeline.
- **Build flavors** dev/staging/prod + `--dart-define` per environment (no constant editing).
- **Store**: signed release (Keystore), versioning, screenshots, release checklist.

**Acceptance criteria:** a release APK can be built from a clean check-out; the whole CI cycle is
green; release guidance is documented (optional `docs/RELEASING.md`).

---

## Conventions That Must Be Followed

- State management: **Riverpod**; data access through repositories in `features/<x>/data`.
- All Rupiah amounts via `rupiah()`; theming via `shared/theme`.
- Every feature has at least 1 unit test for its main flow; don't add bare `http` — always go through
  `dioProvider`.
- Update this document on structural changes.

---

## Estimates (relative)

| Phase | Effort (depends on the API contract) |
|---|---|
| 1 | 3–5 days |
| 2 | 4–6 days |
| 3 | 5–8 days |
| 4 | 3–5 days |
| 5 | 4–7 days |
| 6 | 5–8 days |

Estimates exclude backend time (prerequisites above) and assume the API contract is final.