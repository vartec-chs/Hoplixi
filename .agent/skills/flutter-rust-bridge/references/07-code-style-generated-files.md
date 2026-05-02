## Code style rules

Rust:

- Prefer explicit request/response structs for complex functions.
- Keep bridge-facing APIs small.
- Keep implementation modules testable without Flutter.
- Use `cargo fmt`.
- Use `cargo clippy` if configured.
- Avoid `unwrap()` and `expect()` in production paths.
- Use `Result` for recoverable errors.

Dart:

- Do not spread generated API calls across UI widgets.
- Wrap generated API in app-level services/repositories.
- Map Rust errors into app-level errors.
- Keep Riverpod orchestration in Dart.
- Use `flutter analyze`.
- Do not edit generated Dart files.

## Safe generated-file policy

Allowed:

- Read generated files to understand errors.
- Delete generated files only when the build process will regenerate them and
  this is needed to remove stale output.
- Commit generated files if the project policy requires it.

Not allowed:

- Manually editing `frb_generated.*` as a fix.
- Manually editing `*.g.dart` or `*.freezed.dart` as a fix.
- Changing generated Dart signatures instead of changing Rust source API.
- Hiding generator problems by patching generated output.

