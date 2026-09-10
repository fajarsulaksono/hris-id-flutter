# HRIS ID — Flutter

Mobile companion app for the HRIS web platform (`hris-id-laravel`): employee
self-service for attendance, leave/overtime, payslips, and notifications. It consumes
the Laravel REST API (Sanctum) at `/api/v1`.

## Prerequisites

- Flutter SDK via [fvm](https://fvm.app) (version pinned in `.fvmrc`, currently `stable`).

## Setup

```bash
fvm install       # install the Flutter version declared in .fvmrc
fvm use           # activate that version for this project
fvm flutter pub get
fvm flutter run
```

Override `API_BASE_URL` at build time (dev default is `http://localhost:9100/api/v1`):

```bash
fvm flutter run --dart-define=API_BASE_URL=https://hris.example.com/api/v1
```

## Project Structure

```
lib/
├── core/          Dio client, secure token storage, configuration, error mapping
├── features/      auth, dashboard, attendance, leave, overtime, payroll, profile
└── shared/        theme, widgets, formatting utilities
```

- State management: Riverpod (`flutter_riverpod`).
- Sanctum tokens are stored in `flutter_secure_storage` and attached automatically via an
  interceptor.
- The initial screen is driven by the session state (`AuthGate`): splash → login → home.

## Architecture & Roadmap

See [docs/ARCHITECTURE_AND_ROADMAP.md](docs/ARCHITECTURE_AND_ROADMAP.md) for the app
architecture and development phases, including the backend prerequisites required from
`hris-id-laravel`.