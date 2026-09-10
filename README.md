# HRIS ID — Flutter

Aplikasi mobile pendamping web HRIS (`hris-id-laravel`): self-service absensi, cuti/lembur,
payslip, dan notifikasi. Mengkonsumsi REST API Laravel (Sanctum) di `/api/v1`.

## Prasyarat

- Flutter SDK via [fvm](https://fvm.app) (versi dipatok di `.fvmrc`, saat ini `stable`).

## Setup

```bash
fvm install       # instal versi Flutter sesuai .fvmrc
fvm use           # aktifkan versi untuk project ini
fvm flutter pub get
fvm flutter run
```

Override `API_BASE_URL` saat build (dev default ke `http://localhost:9100/api/v1`):

```bash
fvm flutter run --dart-define=API_BASE_URL=https://hris.example.com/api/v1
```

## Struktur

```
lib/
├── core/          Dio client, token storage (secure), konfigurasi, error mapping
├── features/      auth, dashboard, attendance, leave, overtime, payroll, profile
└── shared/        tema, widget, util format
```

- State management: Riverpod (`flutter_riverpod`).
- Token Sanctum disimpan di `flutter_secure_storage`; otomatis dilampirkan via interceptor.
- Layar ditentukan oleh status sesi (`AuthGate`): splash → login → beranda.