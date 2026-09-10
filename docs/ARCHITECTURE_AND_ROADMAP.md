# Architecture & Development Roadmap (hris-id-flutter)

This document is the reference for the app's architecture and the development phases
after the initial scaffold. The current foundation status and backend prerequisites are
described up front so each phase has a clear contract with `hris-id-laravel`
(REST API `/api/v1`, Sanctum).

---

## Current Foundation Status

| Area | Status | Notes |
|---|---|---|
| Auth | ✅ Done | login/logout/restore; session divalidasi via `/auth/me` (401 → logout); profil user tersimpan di state |
| Structure | ✅ Done | `core/`, `features/`, `shared/` per `docs/FLUTTER_MOBILE.md` |
| Navigation | ✅ Done | `HomeShell` dengan menu **role-aware** (ability dari `/auth/me`); 5 tab |
| Biometric lock | ✅ Done (Fase 1) | `local_auth` + preferensi di secure storage + `BiometricGateScreen` |
| Attendance (Clock In/Out) | ✅ Done (Fase 2) | `attendanceController` (`AsyncNotifier`), model `Attendance`, `AttendanceRepository`, layar check-in/out + ringkasan bulan; backend attendances kini `mutable` + self-service |
| Testing | ✅ Auth + Attendance + Leave + Overtime + Payslip + Notifications covered | 17 Flutter test plus Laravel notification/API coverage; hardening and release tests pending |
| API layer | ✅ Done | `dioProvider` + `AuthInterceptor` (Bearer, 401 cleanup) + `ApiException` mapping |
| Configuration | ✅ Done | `API_BASE_URL` via `--dart-define`, default `localhost:9100/api/v1`; Firebase/release secrets kept outside Git |

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
3. **Approval workflow** for leave/overtime (status `approved_by_id`/approval) ✅ implemented in the
  Laravel API — a prerequisite for Phase 3 and correlated with the High-priority item in the web
  `docs/RECOMMENDATIONS.md`.
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

- **Backend** ✅: `attendances` kini `mutable` + `self_service` (ability `view_my_attendance` /
  `manage_my_attendance` untuk EMPLOYEE); `employee_id` diambil dari token, bukan body; duplikat
  tanggal ditolak (422); indeks/show di-scope ke record sendiri kecuali HR (`view_attendance`).
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

- **Backend** ✅: `mutable` `leaves`/`overtimes`; approval workflow (status & `approved_by`).
- Request form ✅: leave reason, amount, date, overtime start–end time, and notes.
- Leave reason options ✅ loaded from the `Reason` API.
- Request history ✅ with status: *Pending / Approved / Rejected*.
- Refetch the list ✅ after a successful submit via the Riverpod controller.

**Deliverables:** ✅ `leaveController`, `overtimeController`, `Leave`/`Overtime` models, form screens,
history, and unit tests for the submit cycle.

**Acceptance criteria:** ✅ a successful request appears in history as Pending; auto-approved
overtime status is rendered from the API response; client-side date validation rejects past dates;
overtime validation rejects an end time that is not after the start time.

---

## Phase 4 — Payslip

**Goal:** employees view their digital payslip.

- **Backend** ✅: `payrolls` access is owner-scoped by `employee_id` from the token and values are
  already decrypted by the API Resource.
- Period list → detail ✅ with take-home pay and compensation/allowance-deduction breakdown.
- Rupiah formatting ✅ via `shared/utils/rupiah.dart`.
- **Policy** ✅: payroll payloads are never cached locally; they are fetched per request only.

**Deliverables:** ✅ `payrollController`, `Payroll`/`PayrollDetail` models, list + detail screens,
formatting test.

**Acceptance criteria:** ✅ only the user's own payrolls appear; take-home pay and breakdown are
consistent; numbers formatted as `Rp5.000.000`.

---

## Phase 5 — Notifications

- In-app ✅: notification history tab backed by `GET /api/v1/notifications`, with mark-as-read.
- FCM push ✅: register the device token after login/session restore, unregister on logout; existing
  overtime approval and payroll notifications retain email/database delivery and also use the FCM
  channel when Firebase credentials are configured.
- FCM payload ✅ includes notification type and related record ID for future deep-link routing.
- Deep link: payload contracts are ready (`type` + `related_id`); routing to payslip/leave detail is
  still pending because those detail routes need to be added to the Flutter navigator.

### Firebase setup required for production

- Flutter: configure the Android/iOS apps with Firebase Console files so `Firebase.initializeApp()`
  can resolve native options.
- Laravel: set `FIREBASE_CREDENTIALS` to a Firebase service-account JSON path. Never commit that file.
- Backend device endpoints: `POST /api/v1/auth/device` and `DELETE /api/v1/auth/device/{id}`.

**Deliverables:** ✅ notification provider, device register/unregister, history screen, and FCM
payload handling. Deep-link navigation and release Firebase credentials remain deployment work.

**Acceptance criteria:** ✅ device tokens are registered once per token; notification history is
available and markable as read; FCM sends overtime/payroll payloads when credentials are configured.
Deep-link screen navigation remains a follow-up item.

---

## Phase 6 — Hardening & Release

- **Offline/minimal-network behavior** ✅: no crash without a connection; feature screens expose
  clear messages and retry actions.
- **Security** ✅: `flutter_secure_storage`, no token logging, backend validation, Firebase/service
  account and signing secrets ignored; release command documents `--obfuscate` and symbols.
- **Testing**: controller/widget coverage exists for all implemented features; `flutter test` and
  coverage run in CI. Current line coverage is 45.51%; the ≥60% target and device-level tests remain
  release checks.
- **CI** ✅: GitHub Actions runs FVM setup, analyze, test with coverage, and debug APK build.
- **Build environments** ✅: dev/staging/prod endpoints use `--dart-define` without source edits;
  native store flavors remain optional deployment work.
- **Store**: release signing, versioning, screenshots, and checklist are documented in
  `docs/RELEASING.md`; signing credentials remain deployment-owned.

**Acceptance criteria:** ✅ clean-checkout CI can analyze, test, collect coverage, and build a debug
APK; release guidance is documented. Production APK/AAB signing and Firebase native files must be
provided by the release environment. Coverage still needs to reach the ≥60% target before calling
the hardening phase fully complete.

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