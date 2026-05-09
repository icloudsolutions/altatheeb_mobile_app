# Altatheeb Mobile App (Flutter)

Parent-persona MVP. The app talks **only** to the mobile backend
(`../mobile_backend/` under `altatheeb_mobile_app/`). It carries **no** Odoo URLs and **no** Odoo credentials.

## Stack (locked)

* **Clean Architecture**: `presentation / application / domain / data`
* **State** — `flutter_bloc` (Cubit)
* **Routing** — `go_router`
* **Networking** — `dio` (single base URL: `BACKEND_BASE_URL`)
* **Storage** — `flutter_secure_storage` (tokens), `hive` (preferences + cache),
  `shared_preferences` (light flags only)
* **Localisation** — `intl` + ARB (`l10n/app_en.arb`, `l10n/app_ar.arb`); RTL on
  Arabic from day one.
* **Themes** — `AppTheme.light()` / `AppTheme.dark()`, persisted via the
  `PreferencesCubit`.

## Folder layout

```
app/
├── lib/
│   ├── app/
│   │   ├── theme/app_theme.dart
│   │   ├── router/app_router.dart
│   │   └── localization/generated/app_localizations.dart  (regenerate via gen-l10n)
│   ├── core/
│   │   ├── config/env.dart            (BACKEND_BASE_URL via --dart-define)
│   │   ├── network/dio_client.dart    (Authorization + 401 refresh)
│   │   └── storage/secure_token_store.dart
│   └── features/
│       ├── auth/        (Cubit, repository, login screen)
│       ├── children/    (list + selector + home shell)
│       ├── invoices/    (parent-scoped invoice list + cards)
│       └── settings/    (theme + language toggles)
├── l10n/                (ARB sources)
├── test/                (theme + widget smoke tests)
├── pubspec.yaml
└── analysis_options.yaml
```

## Run

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs   # if you add codegen
flutter gen-l10n
flutter run --dart-define=BACKEND_BASE_URL=http://10.0.2.2:8000   # Android emulator
```

### Production / staging API (Wi‑Fi device)

After deploying with `../deploy/ems/` (see `../deploy/ems/README.md`), point the app at the public host and port (default **18080**, no path prefix):

```bash
flutter run -v --debug --dart-define=BACKEND_BASE_URL=http://167.99.242.212:18080
```

Or use `altatheeb_mobile_app/app/scripts/run_android_wifi_debug.ps1` (default backend URL is set to that host).

## Test

```bash
flutter test
```

`test/theme_smoke_test.dart` is the seed for required Light + Dark + RTL/LTR
golden checks.
