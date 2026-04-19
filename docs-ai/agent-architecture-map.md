# Agent Architecture Map

Compact map of where things are located. Use this file as a lookup index, not as
a full technical spec.

## App Entry and Bootstrap

- `lib/main.dart`: app startup, env loading, logger/DI/window/tray init,
  `ProviderScope`
- `lib/app.dart`: root widget composition and app-level wrappers
- `lib/di_init.dart`: dependency registration via `getIt`
- `lib/setup_error_handling.dart`: global error handlers
- `lib/setup_tray.dart`: desktop tray setup
- `lib/flavors.dart`: flavor config

## Core Module (`lib/core/`)

- `logger/`: structured logging helpers (`logInfo`, `logWarning`, `logError`,
  ...)
- `constants/`: app constants (`MainConstants`)
- `app_paths.dart`: OS-specific directories
- `utils/`: toasts, UI/system helpers, result extensions, parsers
- `services/`: global services (`HiveBoxManager`, `LocalAuthService`)
- `providers/`: app-wide Riverpod providers
- `lifecycle/`: app lifecycle and auto-lock logic
- `app_prefs/`: typed preferences + secure policies
- `theme/`: theme providers and shared theme models

## Database Core (`lib/db_core/`)

- `main_store.dart`: Drift database host (schema + DAO wiring)
- `main_store_manager.dart`: store lifecycle orchestration
- `tables/`: Drift table definitions
- `dao/`: entity CRUD and query logic
- `services/`: database-related business logic
- `models/`: DB models, DTOs, and error types
- `provider/`: DB state/providers (`mainStoreProvider`, DAO providers)
- `migrations/`: versioned migrations runner and migration files
- `triggers/`: history and timestamp SQL triggers

## Feature Modules (`lib/features/`)

Main feature areas:

- `password_manager/`: dashboard, forms, managers, history, pickers, store
  settings
- `home/`: recent stores and quick actions
- `settings/`: app settings
- `setup/`: first-run setup
- `archive_storage/`: archive flows
- `cloud_sync/`: auth, OAuth apps, sync
- `logs_viewer/`: logs and crash reports
- `qr_scanner/`: QR flows
- `component_showcase/`: dev showcase screens

Common structure per feature:

- `models/`, `providers/`, `screens/` or `ui/`, `widgets/`, optional `services/`

## Shared UI and Watchers

- `lib/shared/ui/`: reusable standardized UI components
- `lib/shared/widgets/watchers/`: app-level side-effect wrappers (`tray`,
  `shortcut`, `lifecycle`)

## Routing

- `lib/routing/router.dart`: main router and redirect behavior
- `lib/routing/routes.dart`: route declarations
- `lib/routing/paths.dart`: route path constants
- `lib/routing/router_refresh_provider.dart`: router refresh notifier

## Local Packages (`packages/`)

- `card_scanner/`
- `cloud_storage_sdk/`
- `file_crypto/`
- `secure_clipboard_win/`

## Storage Unit Structure

```text
store_name/
|   store_manifest.json
|   attachments_manifest.json
|   store_name.hplxdb
|---attachments_decrypted/
|---attachments/
```

- `store_manifest.json`: store metadata, compatibility information, and key
  configuration (`keyConfig`)
- `attachments_manifest.json`: attachments sync metadata (revision/hash/list of
  attachment files)
- `*.hplxdb`: encrypted SQLite3 Multiple Ciphers database
- `attachments/`: encrypted attachments
- `attachments_decrypted/`: temporary decrypted files
