# HRIS ID Mobile Release Guide

## Environments

The API endpoint is configured without editing source code:

```bash
fvm flutter run --dart-define=API_BASE_URL=https://dev.example.com/api/v1
fvm flutter build apk --release --dart-define=API_BASE_URL=https://staging.example.com/api/v1
fvm flutter build appbundle --release --dart-define=API_BASE_URL=https://hris.example.com/api/v1
```

Firebase native configuration must be installed for the target app before a release build:

- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

These files contain project-specific configuration and must not be committed until the team
has explicitly decided to manage them as public Firebase app configuration.

## Release checks

Run from a clean checkout:

```bash
fvm install
fvm flutter pub get
fvm flutter analyze
fvm flutter test --coverage
fvm flutter build appbundle --release \
  --obfuscate \
  --split-debug-info=build/symbols \
  --dart-define=API_BASE_URL=https://hris.example.com/api/v1
```

Keep `build/symbols` private. It is required to decode crash reports and must be stored in the
release artifact archive, not shipped with the application.

## Android signing

Configure a non-debug keystore in the Android Gradle signing configuration before publishing.
The repository intentionally does not contain keystore files, passwords, or signing keys.
Verify the final artifact with:

```bash
apksigner verify --verbose app-release.apk
```

## iOS signing

Configure the Apple team, bundle identifier, provisioning profile, and distribution certificate
in Xcode. Archive with the `Release` configuration and validate the archive before upload.

## Firebase and Laravel

Set the Laravel environment variable to a service-account JSON path outside the repository:

```env
FIREBASE_CREDENTIALS=/secure/path/firebase-service-account.json
```

Never commit the service-account JSON or private signing material. Register the device token after
login and verify a test notification from both overtime approval and payroll processing before
publishing.

## Store checklist

- [ ] Version and build number updated in `pubspec.yaml`.
- [ ] Production `API_BASE_URL` supplied with `--dart-define`.
- [ ] Firebase Android/iOS configuration installed.
- [ ] Release signing configured and verified.
- [ ] Obfuscation symbols archived securely.
- [ ] Login, attendance, leave, overtime, payslip, and notification smoke tests passed.
- [ ] Privacy policy and notification permission text reviewed.
- [ ] Android App Bundle or iOS archive uploaded to the appropriate store track.
