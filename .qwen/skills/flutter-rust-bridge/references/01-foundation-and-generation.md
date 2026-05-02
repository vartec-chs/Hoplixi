## Purpose

This skill helps AI agents work safely and predictably with a Flutter project
that uses `flutter_rust_bridge` to expose Rust code to Dart/Flutter.

Use this skill when the task involves:

- Rust functions, structs, enums, traits, streams, or errors exposed to Dart.
- `flutter_rust_bridge_codegen` generation.
- Files named `frb_generated.*`.
- `rust/src/api/**` or other bridge-facing Rust modules.
- Dart wrappers around generated Rust APIs.
- Native build failures after changing Rust code.
- Cross-platform Flutter + Rust integration.
- Security-sensitive Rust modules such as encryption, hashing, file processing,
  or key handling.

## Core rule

Do not manually edit generated files as the final solution.

Generated files must be changed by modifying the source API/configuration and
re-running the generator.

Treat the following as generated artifacts:

- `lib/src/rust/frb_generated.dart`
- `lib/src/rust/frb_generated.io.dart`
- `lib/src/rust/frb_generated.web.dart`
- `lib/src/rust/frb_generated/**`
- `rust/src/frb_generated.rs`
- `rust/src/frb_generated/**`
- Any file matching `frb_generated.*`
- `*.freezed.dart`
- `*.g.dart`

Temporary inspection of generated files is allowed for debugging, but do not
patch them as the real fix.

## Mental model

`flutter_rust_bridge` lets Dart call Rust as if Rust APIs were normal Dart APIs.
The bridge generates the glue code between Dart and Rust.

The correct workflow is:

1. Design or update the Rust API.
2. Keep bridge-facing Rust types clean and stable.
3. Run `flutter_rust_bridge_codegen generate`.
4. Update Dart-side usage if the generated API changed.
5. Validate with Flutter and Rust checks.

## Recommended project layout

Default FRB v2 projects usually look like this:

```text
lib/
  main.dart
  src/
    rust/
      frb_generated.dart
      frb_generated.io.dart
      frb_generated.web.dart
      api/**/*.dart

rust/
  Cargo.toml
  src/
    lib.rs
    api/
      mod.rs
      simple.rs
      ...
    frb_generated.rs
```

Recommended conventions:

- Put bridge-facing Rust API in `rust/src/api/**`.
- Put internal implementation outside `api` when possible, for example:

```text
rust/src/
  api/          # Thin public API exposed to Dart
  crypto/       # Internal implementation
  files/        # Internal implementation
  errors/       # Internal error types and mapping
  models/       # Internal shared models
```

- When adding a new Rust API file, also export it from `rust/src/api/mod.rs`:

```rust
pub mod vault_crypto;
pub mod file_crypto;
```

If the file is not added to `mod.rs`, Rust and FRB may behave as if it does not
exist.

## Code generation commands

Use the project's configured command if one exists, for example from `melos`,
`just`, `make`, `scripts`, or README.

Common command:

```bash
flutter_rust_bridge_codegen generate
```

Useful variants:

```bash
flutter_rust_bridge_codegen generate --watch
flutter_rust_bridge_codegen generate --verbose
flutter_rust_bridge_codegen generate --config-file flutter_rust_bridge.yaml
flutter_rust_bridge_codegen --help
flutter_rust_bridge_codegen generate --help
```

If the project has a config file, prefer it over long CLI arguments:

```bash
flutter_rust_bridge_codegen generate --config-file flutter_rust_bridge.yaml
```

Do not invent paths blindly. Inspect the repository first.

## When to regenerate

Regenerate FRB code after changing:

- A Rust function exposed to Dart.
- Function name, parameters, return type, async/sync mode, or visibility.
- Bridge-facing structs, enums, traits, type aliases, or errors.
- Files under `rust/src/api/**` that are part of the bridge input.
- FRB config such as Rust input, Dart output, Rust output, codec, web options,
  or headers.
- Generated Dart entrypoint naming or output directory.

Regeneration is usually not needed after changing:

- Pure Dart UI code.
- Flutter widgets, Riverpod providers, routes, themes.
- Rust internals that do not affect the public bridge-facing API.
- Comments or docs only.
- Tests only, unless they depend on generated API changes.

## Validation commands

After generation or Rust API changes, run the smallest useful validation set.

Preferred baseline:

```bash
flutter analyze
cargo check --manifest-path rust/Cargo.toml
```

If formatting is required:

```bash
dart format lib
cargo fmt --manifest-path rust/Cargo.toml
```

If tests exist and are relevant:

```bash
flutter test
cargo test --manifest-path rust/Cargo.toml
```

For dependency/build issues:

```bash
flutter pub get
cargo metadata --manifest-path rust/Cargo.toml
```

For generated-code issues:

```bash
flutter_rust_bridge_codegen generate --verbose
```

