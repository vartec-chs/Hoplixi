## Dart integration rules

Generated FRB APIs should not be used everywhere directly if the project is
large.

Prefer a thin Dart adapter/repository/service layer:

```text
Flutter UI
  -> Riverpod Notifier / Use Case
    -> Dart Rust service adapter
      -> Generated FRB API
        -> Rust API
```

Benefits:

- Keeps generated API changes localized.
- Keeps UI independent from bridge details.
- Allows mocks/fakes in tests.
- Allows mapping Rust errors into app-level `AppError`.

Do not put UI logic into Rust bridge APIs.

Dart/Flutter should usually own:

- UI state.
- Riverpod providers.
- Navigation.
- Dialogs/prompts.
- Localization.
- Theme and platform UI.
- High-level app orchestration.

Rust should usually own:

- Crypto primitives.
- File encryption/decryption internals.
- CPU-heavy parsing/processing.
- Native library integration.
- Performance-sensitive algorithms.
- Strict validation of data formats it owns.

## Hoplixi-specific rules

For Hoplixi, Rust should be treated as a native/security/performance module, not
as the main app architecture layer.

Rules:

- Dart/Flutter remains responsible for UI, Riverpod state, routing, and app
  orchestration.
- Rust should expose small, explicit, service-like APIs.
- Rust APIs should return typed results/errors, not panic for expected failures.
- Do not pass master keys, vault keys, or decrypted secrets through unnecessary
  bridge layers.
- Do not log sensitive data on either Dart or Rust side.
- Keep file encryption streaming/chunked where possible.
- Keep DB lifecycle and Riverpod orchestration in Dart unless there is a strong
  reason to move a specific low-level operation to Rust.
- Do not make generated FRB files part of manual architecture decisions.
- If generated files are wrong, fix the Rust API/config and regenerate.

Suggested Hoplixi layering:

```text
lib/features/**                 # UI/features
lib/core/**                     # app-level services, errors, Riverpod orchestration
lib/native/**                   # Dart adapters around Rust bridge
lib/src/rust/**                 # generated FRB code
rust/src/api/**                 # bridge-facing Rust API
rust/src/crypto/**              # internal crypto implementation
rust/src/files/**               # internal file processing
rust/src/errors/**              # internal/bridge error mapping
```

## Testing and mocking rules

Test the layers separately when possible.

### Test Dart without real Rust

Generated FRB APIs route through the generated `RustLibApi` class. This class is
intentionally mockable and can be replaced during tests.

Use this when testing Dart services, repositories, Riverpod notifiers, UI logic,
or error mapping without running real Rust code.

Example with `mocktail` style syntax:

```dart
class MockRustLibApi extends Mock implements RustLibApi {}

Future<void> main() async {
  final mockApi = MockRustLibApi();
  await RustLib.init(api: mockApi);

  test('can mock Rust calls', () async {
    when(() => mockApi.simpleAdderTwinNormal(a: 1, b: 2))
        .thenAnswer((_) async => 123456789);

    final actualResult = await simpleAdderTwinNormal(a: 1, b: 2);

    expect(actualResult, equals(123456789));
    verify(() => mockApi.simpleAdderTwinNormal(a: 1, b: 2)).called(1);
  });
}
```

Rules:

- Prefer mocking the Dart adapter/service in high-level UI tests.
- Mock `RustLibApi` when specifically testing integration with generated FRB
  dispatch.
- Do not require real Rust for every Dart unit test.
- Keep generated API usage behind adapters to make mocking easier.

### Test Rust without Dart

Rust implementation should be testable as normal Rust code.

Use:

```bash
cargo test --manifest-path rust/Cargo.toml
```

Rules:

- Put business/security/performance logic in normal Rust modules, not only in
  bridge functions.
- Unit test Rust internals directly.
- Keep bridge API functions thin so they need fewer special tests.

### Test Dart and Rust together

Use normal Flutter/Dart testing techniques for integration tests that need real
Rust.

By default, Rust compilation and native library loading should be handled
automatically by the FRB project setup. Do not add manual test bootstrapping
unless the project actually requires it.

Recommended split:

```text
Rust unit tests       -> cargo test
Dart unit tests       -> mock Dart adapter or RustLibApi
Flutter widget tests  -> mock app-level native service
Integration tests     -> real RustLib.init() + real generated API
```

## Typical task workflows

### Add a new Rust function exposed to Dart

1. Add internal implementation in a non-generated Rust module.
2. Add a thin public function in `rust/src/api/**`.
3. Export the module from `rust/src/api/mod.rs` if needed.
4. Run `flutter_rust_bridge_codegen generate`.
5. Use the generated Dart API from a Dart adapter/service, not directly from UI.
6. Run `flutter analyze` and `cargo check`.

### Change an exposed Rust type

1. Check all Dart call sites using the generated type.
2. Update the Rust type.
3. Regenerate FRB code.
4. Update Dart adapters and tests.
5. Run analysis/checks.

### Fix generated-code compile errors

1. Do not patch generated files.
2. Read the generated error to identify the source Rust API/type/config issue.
3. Check whether all new Rust API modules are exported from `mod.rs`.
4. Check whether types are public where needed.
5. Check whether unsupported or overly complex types are exposed.
6. Simplify the bridge-facing API if needed.
7. Regenerate with verbose output.
8. Re-run Flutter/Rust checks.

### Debug missing Dart API after adding Rust code

Check:

- Is the Rust function `pub`?
- Is the file under the configured FRB Rust input?
- Is the module exported in `rust/src/api/mod.rs`?
- Did generation run successfully?
- Is Dart importing the generated API from the correct path?
- Is there a stale generated file or stale build cache?

Then run:

```bash
flutter_rust_bridge_codegen generate --verbose
flutter analyze
cargo check --manifest-path rust/Cargo.toml
```

### Debug native build failure

Check:

- Rust compilation errors first.
- Cargo features and target platform support.
- Android NDK/iOS/macOS/Linux/Windows toolchain availability.
- Whether the Rust crate compiles independently.
- Whether generated files are stale.

Commands:

```bash
cargo check --manifest-path rust/Cargo.toml
flutter clean
flutter pub get
flutter_rust_bridge_codegen generate
flutter run -v
```

Use `flutter clean` only when stale build artifacts are likely; do not use it as
the first solution for every issue.

