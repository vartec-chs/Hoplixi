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

- See [docs-ai/flutter-rules.md](docs-ai/flutter-rules.md) for the coding
  standards and best practices followed in this project.

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

## Important

- When writing code, the agent must strictly follow this project documentation
  and docs-ai\*. If information is missing or unclear, the agent must consult
  the MCP server instead of inventing solutions.

- The agent must never make assumptions about APIs, architecture, or behavior.
  If something is unknown, it must be explicitly verified or left unimplemented.

- User data security is a top priority:
  - Never log, expose, or store sensitive data in plain text
  - Never bypass encryption, secure storage, or authentication flows

- Code must prioritize:
  - readability
  - maintainability
  - explicitness over cleverness

- UI and UX decisions must:
  - follow existing shared UI components
  - maintain visual and behavioral consistency
  - avoid custom solutions when standardized components exist

- Performance considerations are mandatory:
  - avoid unnecessary rebuilds
  - avoid heavy synchronous work on the UI thread
  - prefer lazy loading and pagination where applicable

- One source of truth

## Best Practices

See [docs-ai/widget-patterns.md](docs-ai/widget-patterns.md) for optimized
widget patterns and responsive layout examples.

## Multi-Window and Logging

See [docs-ai/multi-window-architecture.md](docs-ai/multi-window-architecture.md)
for details on multi-window support and the corresponding logging strategy.

### Extension Methods

Use extension methods to reduce boilerplate and improve code readability:

```dart
extension ContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => MediaQuery.sizeOf(this);
}

// Usage
Widget build(BuildContext context) {
  return Text('Hello', style: context.textTheme.bodyLarge);
}
```

### Async/Await Pattern

Always use async/await instead of `.then()`. Use `result_dart` for error
handling:

```dart
// ❌ Bad
fetchData().then((data) => process(data)).catchError((error) => handle(error));

// ✅ Good
try {
  final data = await fetchData();
  process(data);
} catch (error) {
  handle(error);
}

// ✅ Best with result_dart
final result = await fetchData();
result.when(
  success: (data) => process(data),
  failure: (error) => handle(error),
);
```

### Minimize Rebuilds

- **Break widgets into smaller pieces** - Each widget should be small and
  focused
- **Use const constructors** - Mark immutable widgets with `const`
- **Use Consumer/Selector** - Watch only specific parts of state
- **Avoid logic in build()** - Move heavy calculations to providers

```dart
// ❌ Bad - Heavy logic in build()
Widget build(BuildContext context) {
  final data = heavyCalculation(); // Recalculates on every rebuild
  return Text(data);
}

// ✅ Good - Logic in provider
final dataProvider = Provider((ref) => heavyCalculation());

Widget build(BuildContext context, WidgetRef ref) {
  final data = ref.watch(dataProvider);
  return Text(data);
}

// ✅ Good - Const widgets
Widget build(BuildContext context) {
  return const Column(
    children: [
      Text('Static text'), // Won't rebuild
      MyStaticWidget(),
    ],
  );
}
```

### Widget Composition

Break large widgets into smaller, reusable components:

```dart
// ❌ Bad - Monolithic widget
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Title')),
      body: Column(
        children: [
          // 100+ lines of complex UI
        ],
      ),
    );
  }
}

// ✅ Good - Composed widgets
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _AppBar(),
      body: Column(
        children: [
          const _HeaderSection(),
          const _ContentSection(),
          const _FooterSection(),
        ],
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) => /* ... */;
}
```

### Selective Rebuilds with Consumer

Only rebuild widgets that need to react to state changes:

```dart
// ❌ Bad - Entire widget rebuilds
class CounterWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);
    return Column(
      children: [
        ExpensiveWidget(), // Rebuilds unnecessarily
        Text('Count: $count'),
      ],
    );
  }
}

// ✅ Good - Only Text rebuilds
class CounterWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ExpensiveWidget(), // Never rebuilds
        Consumer(
          builder: (context, ref, child) {
            final count = ref.watch(counterProvider);
            return Text('Count: $count');
          },
        ),
      ],
    );
  }
}

// ✅ Best - Use select for granular updates
class UserWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only rebuilds when name changes, not when other user fields change
    final name = ref.watch(userProvider.select((user) => user.name));
    return Text('Name: $name');
  }
}
```

## Error Handling and custom error types

- Always handle errors and display clear error messages in the UI or use
  `Toaster.error()`.

- See [docs-ai/error-handling.md](docs-ai/error-handling.md) for details on how
  errors are managed in the application and create custom error types.

## State Management

- Use Riverpod 3.0 and above for state management. Not use Deprecated providers.

- Not use code generation riverpod_generator with `@riverpod`

- See [docs-ai/state-management.md](docs-ai/state-management.md) for information
  on how state is managed using Riverpod. If there is not enough information,
  use mcp server `context7`.

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

See [docs-ai/wolt-modal-sheet.md](docs-ai/wolt-modal-sheet.md) for detailed
usage examples and API reference.

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

See [docs-ai/gorouter-navigation.md](docs-ai/gorouter-navigation.md) for
detailed navigation recipes and examples.

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
  wrappers. App tree is composed as:
  `ShortcutWatcher -> TrayWatcher -> AppLifecycleObserver -> ThemeProvider -> MaterialApp.router`.
- **di_init.dart** - Dependency injection setup (`setupDI()`). Wires
  `PreferencesService`, `FlutterSecureStorage`, `HiveBoxManager`,
  `DatabaseHistoryService`. Fetch services through `getIt`.
- **setup_error_handling.dart** - Configures global error handlers
  (`runZonedGuarded`, `FlutterError.onError`, `PlatformDispatcher.onError`).
  Errors pass through `logError` + `Toaster`.
- **setup_tray.dart** - System tray initialization (desktop only): icon,
  tooltip, and context menu config with `AppTrayMenuItemKey`. Runtime tray event
  handling lives in watcher layer.
- **global_key.dart** - Global navigator keys (`navigatorKey`,
  `dashboardNavigatorKey`). Used for navigation without context and in services.
- **flavors.dart** - Flavor configuration (dev/staging/prod).

## App Watchers (`lib/shared/widgets/watchers/`)

Global watcher wrappers for app-level side effects and keyboard/system events:

- **tray_watcher.dart** - Subscribes to `tray_manager` listener callbacks,
  handles tray icon/menu actions, and delegates window actions via
  `WindowManager`.
- **shortcut_watcher.dart** - Centralized global hotkeys using `Shortcuts` +
  `Actions`. Keep shortcut definitions in `_shortcuts` and handlers in
  `_actions` for extensibility. Current bindings include:
  - `Ctrl+Q` (Windows/Linux) and `Cmd+Q` (macOS): app exit
  - `Cmd+W` (macOS): close window
  - `Escape`: navigation pop via `GoRouter`
- **lifecycle/app_lifecycle_observer.dart** - App lifecycle observation wrapper
  used at the root widget level.

## Custom Packages (`packages/`)

Custom local packages developed for this project:

- **card_scanner/** - Credit card scanning functionality using device camera
- **cloud_storage_sdk/** - Unified SDK for cloud storage providers (Dropbox,
  Google Drive, OneDrive, Yandex Drive) with OAuth2 support
- **file_crypto/** - File encryption/decryption services using AES and other
  crypto algorithms
- **secure_clipboard_win/** - Secure clipboard operations for Windows platform

These packages are referenced in `pubspec.yaml` as path dependencies.

## Source Priority

1. This project documentation
2. docs-ai/\*
3. MCP server (Dart / Flutter)
4. General Flutter knowledge

## MCP Server

**For additional support and information, refer to the MCP server `context7`**

Use MCP server `context7` when:

- Flutter / Riverpod APIs are unclear
- Best practices are version-dependent
- There is missing information in docs-ai

## Dart & Flutter MCP Server

The MCP server provides authoritative, version-aware information about Dart,
Flutter, and related libraries.

Use MCP server when:

- APIs or behavior depend on framework version
- Flutter or Riverpod behavior is unclear
- Project docs do not cover the topic

Never override project rules with MCP suggestions.
