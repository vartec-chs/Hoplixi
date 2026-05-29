# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Read Order

Before working on any task, read in this order:

1. This file
2. `AGENTS.md` — non-negotiable project rules
3. `docs-ai/agent-task-router.md` — routes task types to specific docs
4. Task-specific docs from the router (e.g., `docs-ai/state-management.md`, `docs-ai/error-handling.md`)
5. Local `README.md` files in the folder being modified

## Commands

```bash
# Install dependencies
flutter pub get

# Run code generation (Freezed, Drift, JSON, slang)
dart run build_runner build --delete-conflicting-outputs
# or on Windows:
utils_bat/build_runner.bat

# Run app (use flavor)
flutter run --flavor dev
flutter run --flavor prod -d windows

# Tests
flutter test
flutter test test/path/to/specific_test.dart

# Lint and format
flutter analyze
dart format .
```

After modifying `rust/src/api/`, regenerate the Rust bridge:
```bash
flutter_rust_bridge_codegen generate
```

Release builds use `utils_bat/build_prod.bat` (interactive platform selector).

## Architecture

Hoplixi is a cross-platform encrypted vault (passwords, OTP, files, notes, etc.) built with Flutter + Rust.

**Core stack:** Flutter/Dart · Riverpod 3.x · Drift (SQLite3 Multiple Ciphers) · GoRouter · Freezed · slang (i18n) · result_dart · flutter_rust_bridge v2

### `lib/` layout

| Path | Purpose |
|---|---|
| `main.dart` | Entry point — env loading, DI, window/tray init, ProviderScope |
| `app.dart` | Root widget composition |
| `di_init.dart` | GetIt dependency registration |
| `core/` | Logger, constants, app_paths, services, Riverpod providers, theme, lifecycle/auto-lock, typed prefs |
| `vault_db/` | Drift DB host, tables, DAOs, migrations, models, repositories, services |
| `features/` | Feature modules: `password_manager`, `home`, `settings`, `cloud_sync`, `local_send`, `archive_storage`, `custom_icon_packs`, `logs_viewer`, `qr_scanner`, `setup`, `onboarding` |
| `routing/` | GoRouter config — `router.dart`, `routes.dart`, `paths.dart` |
| `shared/` | Reusable UI components, app-level side-effect watchers (tray, shortcut, lifecycle) |
| `rust/` | Dart-side of the flutter_rust_bridge generated bindings |
| `packages/` | Local packages: `card_scanner`, `secure_clipboard_win` |

### Vault storage unit

Each vault is a folder:
```
store_name/
  store_manifest.json          ← metadata, key config (cipher, salt, useDeviceKey)
  attachments_manifest.json    ← sync metadata (revision/hash/file list)
  store_name.hplxdb            ← encrypted SQLite3 database
  attachments/                 ← encrypted attachment files
  attachments_decrypted/       ← temporary decrypted files (may not exist)
```

### Database schema pattern (Table-Per-Type)

Vault entities split across two tables:
- `vault_items` — shared fields (id, type, title, tags, category, timestamps)
- `<entity>_items` — entity-specific fields (e.g., `password_items`, `otp_items`)

History uses `vault_item_history` + `<entity>_history`. Schema migrations live in `lib/vault_db/core/config/migrations/`, follow the runner in `docs-ai/db-migrations.md`.

### Flavors

Two flavors: `dev` (bundleId `com.hiplixi.app.dev`) and `prod` (`com.hiplixi.app`). Configured via `flavorizr.yaml`.

## Key Patterns

### State management — Riverpod 3.x (manual API, no codegen)

Do **not** use `@riverpod` annotation or legacy providers (`StateProvider`, `StateNotifierProvider`, `ChangeNotifierProvider`).

Canonical pattern for async CRUD:
```dart
final itemsProvider =
    AsyncNotifierProvider<ItemsNotifier, List<Item>>(ItemsNotifier.new);

class ItemsNotifier extends AsyncNotifier<List<Item>> {
  @override
  Future<List<Item>> build() async => ref.read(repoProvider).fetchAll();

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(ref.read(repoProvider).fetchAll);
  }
}
```

Use `autoDispose` for screen-scoped or family providers. Full guide: `docs-ai/state-management.md`.

### Error handling — result_dart

Business/domain layer must **never throw** — return `ResultDart<T, AppError>` or `AsyncResultDart<T, AppError>` instead. `try/catch` belongs only in adapter layers (network, platform interop).

```dart
AsyncResultDart<FileData, AppError> loadFile(String path) async {
  try {
    return Success(FileData(await readBytes(path)));
  } catch (e, st) {
    return Failure(AppError.fileSystem(
      code: FileSystemErrorCode.unknown,
      message: 'Failed to read file',
      cause: e,
      stackTrace: st,
    ));
  }
}
```

Use `AppError` from `lib/core/errors/app_error.dart`. For feature-local errors that don't warrant a new global domain, use `AppError.feature(...)`. Full guide: `docs-ai/error-handling.md`.

### Logging

Use project logger helpers, not `print()`:
```dart
final _log = loggerWithTag('MyService');
_log.info('opened vault');
```

### Localization (slang)

Translation sources are `.i18n.arb` files in `lib/l10n/<feature>/<subtype>/`. After editing, regenerate with build_runner. Access via `context.t.<namespace>.<key>`. Full guide: `docs-ai/localization.md`.

### Rust bridge

Rust API functions are defined in `rust/src/api/`. Dart bindings are auto-generated into `lib/rust/`. Call `RustLib.init()` in `main.dart` before any Rust API use. All Rust code must be cross-platform (no platform-specific crates without `cfg` guards). Full guide: `docs-ai/rust-integration.md`.

### Changelog

**Mandatory after every agent edit**: update `CHANGELOG.md` and group entries by module/feature.
