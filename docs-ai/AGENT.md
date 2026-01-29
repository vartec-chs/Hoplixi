# Project Info

This project is named Hoplixi, a Flutter application designed to provide users
with a seamless experience. Hoplixi is a password manager app that helps users
securely store and manage their passwords.

## Target Platform

- Adnroid
- IOS
- MacOS
- Linux
- Windows

## Features

- Secure password storage
- User-friendly interface
- Cross-platform support

## Flutter Rules

- See [docs-ai/flutter-rules.md](flutter-rules.md) for the coding standards and
  best practices followed in this project.

## Technologies Used

- Flutter
- Dart
- SQLite
- SQLCipher
- Riverpod
- Freezed
- GoRouter
- Flutter Secure Storage
- Result Dart (result_dart package) for error handling use patterns.

## Error Handling and custom error types

- Always handle errors and display clear error messages in the UI or use
  `Toaster.error()`.

- See [docs-ai/error-handling.md](error-handling.md) for details on how errors
  are managed in the application and create custom error types.

## State Management

- Use Riverpod 3.0 and above for state management. Not use Deprecated providers.

- Not use code generation riverpod_generator with `@riverpod`

- See [docs-ai/state-management.md](state-management.md) for information on how
  state is managed using Riverpod. If there is not enough information, use mcp
  server `context7`.

## Features structure

- Each feature is organized in its own directory under `lib/features/`.
- Each feature contains its own models, providers, screens, widgets, and
  services.

## Freezed Usage

Freezed is used to:

1. Define immutable data models
2. Guarantee value equality
3. Create safe copyWith operations
4. Represent explicit domain and UI states (not logic)

Freezed is NOT used for:

- Business logic
- Providers
- Services

Freezed IS allowed for:

- Provider state models

### Domain Models

- All domain entities must be immutable
- Equality must be value-based, not reference-based
- copyWith must be safe and explicit

Use Freezed to enforce these guarantees.

## Freezed Rules

- Freezed models must be immutable
- No methods with side effects inside Freezed classes
- No async logic inside Freezed models
- No direct dependency on services or providers
- UI must not mutate Freezed models

## Why Freezed is Critical

- Prevents accidental mutation of sensitive data
- Makes state transitions explicit
- Eliminates hidden bugs caused by shared references
- Improves safety when handling encrypted data

## Core Module Structure

`lib/core/` provides foundational services and utilities:

### Logger (`core/logger/`)

Use logging functions everywhere instead of `print()`:

- `logError()` - Log errors with optional error object and stack trace
- `logWarning()` - Log warnings
- `logInfo()` - Log informational messages
- `logDebug()` - Log debug messages (disabled in production)
- `logTrace()` - Log trace messages for detailed execution flow
- `logFatal()` - Log fatal errors
- `logCrash()` - Write crash reports to file

All logs are buffered to JSONL files with session tracking. Crash reports are
stored separately with device info.

### Constants (`core/constants/main_constants.dart`)

Project-wide constants:

- `MainConstants.appName` - Application name
- `MainConstants.isProduction` - Production flag
- `MainConstants.defaultWindowSize` - Default window dimensions
- `MainConstants.databaseSchemaVersion` - Current DB schema version
- `MainConstants.dbExtension` - Database file extension (`.hplxdb`)

### App Paths (`core/app_paths.dart`)

OS-specific directory paths. Always use these methods instead of hardcoded
paths:

- `AppPaths.appLogsPath` - Logs directory
- `AppPaths.appCrashReportsPath` - Crash reports directory
- `AppPaths.exportStoragesPath` - Export directory

### Utils (`core/utils/`)

- **Toaster** (`toastification.dart`) - Use instead of `SnackBar`. Methods:
  `Toaster.success()`, `Toaster.error()`, `Toaster.warning()`, `Toaster.info()`,
  `Toaster.infoDebug()`, `Toaster.custom()`. All toasts support title,
  description, and auto-close duration.
- **WindowManager** - Manages native window frame and desktop window operations
- **ResultExtensions** - Extensions for `result_dart` pattern matching
- **ColorParser** - Color string parsing utilities
- **SystemUIUtils** - System UI customization helpers

### Services (`core/services/`)

Global services initialized via DI (`setupDI()`):

- **HiveBoxManager** - Manages encrypted Hive boxes with AES keys in secure
  storage. Use it to open boxes instead of `Hive.openBox()`.
- **LocalAuthService** - Biometric and local authentication

### Providers (`core/providers/`)

Global Riverpod providers for app-wide state.

### Lifecycle (`core/lifecycle/`)

- **AppLifecycleObserver** - Monitors app lifecycle states
  (resumed/paused/inactive/detached)
- **AppLifecycleProvider** - Riverpod provider for lifecycle state
- **AutoLockProvider** - Auto-lock functionality based on inactivity

### App Preferences (`core/app_preferences/`)

Unified storage service for SharedPreferences and FlutterSecureStorage:

- Use `AppKey` with `isProtected: false` for SharedPreferences
- Use `AppKey` with `isProtected: true` for FlutterSecureStorage
- `AppPreferenceKeys` - Predefined keys for app settings
- `AppStorageService` - Unified service for reading/writing preferences

### Theme (`core/theme/`)

- **ThemeProvider** - Theme state management (light/dark)
- **Colors** - App color constants and context-based color getters
- **ThemeSwitcher** - Animated theme switching widgets

## Shared UI Components

Use standardized UI components from `lib/shared/ui/`:

- **SmoothButton** - Use instead of regular buttons (`ElevatedButton`,
  `TextButton`, etc.). Provides consistent styling, sizes (small/medium/large),
  types (text/filled/tonal/outlined/dashed), and variants
  (normal/error/warning/info/success).
- **ModalSheetCloseButton** - Use for close buttons in `WoltModalSheet` dialogs.
- **NotificationCard** - Use for in-tree notifications
  (error/success/info/warning). Replaces ad-hoc container+icon patterns.
  Variants: `ErrorNotificationCard`, `SuccessNotificationCard`,
  `InfoNotificationCard`, `WarningNotificationCard`.
- **SliderButton** - Use for confirmation-style actions
  (confirm/delete/unlock/send). Supports async callbacks, loading state, and
  completion animations.
- **primaryInputDecoration** - Use for all `TextField` and `TextFormField`
  instances. Centralizes input styling, colors, paddings, and accessibility.
  Wrappers: `PrimaryTextField`, `PrimaryTextFormField`, `PasswordField`.
- **TypeChip** - Use for tag/category chips with consistent styling.
- **universal_modal.dart** - DO NOT USE. Prefer `WoltModalSheet` or native
  Flutter dialogs.

### WoltModalSheet

Use `WoltModalSheet` for adaptive modals and multi-page flows:

- **Responsive Design** - Automatically switches between dialog, side sheet, and
  bottom sheet based on screen size
- **Multi-Page Navigation** - Built-in support for multi-page modal flows with
  smooth transitions
- **Scrollable Content** - Handles large content with proper scrolling behavior
- **Custom Modal Types** - Supports bottomSheet, dialog, sideSheet, alertDialog,
  and custom types

See [docs-ai/wolt-modal-sheet.md](wolt-modal-sheet.md) for detailed usage
examples and API reference.

## Routing (`lib/routing/`)

Uses `go_router` with the following structure:

- **router.dart** - Main router configuration with `routerRefreshNotifier` and
  `RootOverlayObserver`. Desktop routes render inside `DesktopShell`. Redirects
  adjust window sizing via `WindowManager`.
- **routes.dart** - Route definitions and configurations
- **paths.dart** - Route path constants
- **router_refresh_provider.dart** - Provider for router refresh notifications

Navigation:

- Use `context.go('/path')` for direct navigation
- Use `context.push('/path')` for stack-based navigation
- Use path constants from `paths.dart` instead of hardcoded strings
- Desktop routes automatically wrap content in `DesktopShell` for consistent
  chrome (title bar, status bar)

## Main Store (`lib/main_store/`)

Manages SQLCipher-encrypted Drift database for password manager data:

### Core Files

- **main_store_manager.dart** - Wraps Drift + SQLCipher, returns
  `AsyncResult<StoreInfoDto, DatabaseError>`. Never throw exceptions, always
  propagate results.
- **main_store.dart** - Hosts tables, DAOs, and schema version. Bump
  `MainConstants.databaseSchemaVersion` and run `build_runner` after schema
  changes.

### Structure

- **dao/** - Data Access Objects for entities (passwords, notes, cards,
  documents, OTPs, files, categories, tags, icons). Each DAO provides CRUD
  operations. Use filter DAOs for complex queries.
- **models/** - Domain models, errors (`db_errors.dart`), database state
  (`db_state.dart`), and DTOs. Extend `DatabaseError` for new error types.
- **provider/** - Riverpod providers:
  - `mainStoreProvider` - Authoritative database state (`DatabaseState`). Update
    via notifier methods (`createStore`, `openStore`, `lockStore`,
    `closeStore`).
  - `daoProviders` - Access to DAOs
  - `dbHistoryProvider` - Database history management
  - `archiveProvider` - Archive functionality
- **services/** - Business logic:
  - `db_history_services.dart` - Records stores by path, drives tray/recent
    lists. Update via service to keep Hive consistent.
  - `archive_service.dart` - Archive/unarchive entities
  - `file_storage_service.dart` - File attachment storage
  - `document_storage_service.dart` - Document page storage
- **tables/** - Drift table definitions (passwords, notes, bank cards,
  documents, OTPs, files, categories, tags, icons, history tables). See
  `tables_schema.md` for full schema.
- **triggers/** - Database triggers for automatic history tracking and timestamp
  updates
- **repositories/** - Repository pattern implementations (if needed)

### Usage Rules

- Always use `AsyncResult<T, DatabaseError>` pattern
- Never use `Hive.openBox()` directly - use `HiveBoxManager`
- Update `mainStoreProvider` state through notifier methods only
- Schema changes require version bump + `build_runner`
- All database operations must go through DAOs or services
- History tracking happens automatically via triggers

## Features (`lib/features/`)

Each feature is self-contained with its own models, providers, screens, widgets,
and services:

### Main Features

- **password_manager/** - Core password manager functionality:
  - `create_store/` - Store creation flow
  - `open_store/` - Store opening flow
  - `lock_store/` - Store locking
  - `dashboard/` - Main dashboard with entity lists
  - `forms/` - Entity forms (password, note, bank card, document, OTP, file)
  - `history/` - Entity history tracking and viewing
  - `managers/` - Category, icon, and tag management
  - `pickers/` - Entity pickers for references
  - `store_settings/` - Store-specific settings
  - `migration/` - Data import from other sources

- **home/** - Home screen with recent databases and quick actions

- **settings/** - Application settings (theme, security, preferences)

- **setup/** - Initial app setup flow

- **archive_storage/** - Archive functionality for entities

- **cloud_sync/** - Cloud synchronization:
  - `auth/` - OAuth authentication
  - `oauth_apps/` - OAuth app management
  - `sync/` - Sync engine and UI

- **logs_viewer/** - Log viewer and crash report browser

- **qr_scanner/** - QR code scanning functionality

- **component_showcase/** - UI component examples and testing (dev only)

### Feature Structure Pattern

Each feature follows this structure:

```text
feature_name/
  models/          - Domain models and state classes
  providers/       - Riverpod providers and notifiers
  screens/         - Main screen widgets
  widgets/         - Reusable feature-specific widgets
  services/        - Business logic (optional)
  ui/              - Alternative to screens/ (used in some features)
```

## Root Files (`lib/`)

Core application files at the root level:

- **main.dart** - Application entry point. Blocks web, loads `.env`, initializes
  `AppLogger`, DI, `WindowManager`, and tray before running `App` inside
  `ProviderScope` with `LoggingProviderObserver`.
- **app.dart** - Root application widget with router, theme, and global
  configurations.
- **di_init.dart** - Dependency injection setup (`setupDI()`). Wires
  `PreferencesService`, `FlutterSecureStorage`, `HiveBoxManager`,
  `DatabaseHistoryService`. Fetch services through `getIt`.
- **setup_error_handling.dart** - Configures global error handlers
  (`runZonedGuarded`, `FlutterError.onError`, `PlatformDispatcher.onError`).
  Errors pass through `logError` + `Toaster`.
- **setup_tray.dart** - System tray initialization (desktop only). Binds menu
  keys to `AppTrayMenuItemKey`. Guard with `UniversalPlatform.isDesktop`.
- **global_key.dart** - Global navigator keys (`navigatorKey`,
  `dashboardNavigatorKey`). Used for navigation without context and in services.
- **flavors.dart** - Flavor configuration (dev/staging/prod).

## MCP Server

**For additional support and information, refer to the MCP server `context7`**

Use MCP server `context7` when:

- Flutter / Riverpod APIs are unclear
- Best practices are version-dependent
- There is missing information in docs-ai
