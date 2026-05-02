## Rust API design rules

Prefer bridge APIs that are simple, stable, and service-like.

Good bridge-facing API:

```rust
pub async fn encrypt_file(input: EncryptFileRequest) -> Result<EncryptFileResponse, CryptoError> {
    crate::crypto::file_encryption::encrypt_file(input).await
}
```

Avoid exposing low-level internals directly:

```rust
// Avoid exposing too much implementation detail to Dart.
pub fn raw_aead_encrypt_internal_buffers(...)
```

Recommended exposed types:

- `struct`
- `enum`
- `String`
- `bool`
- integers and floats
- `Vec<T>`
- `Option<T>`
- `Result<T, E>`
- `async fn` for IO or long-running work
- Streams only when the task naturally emits progress/events

Avoid unless there is a clear reason:

- Huge deeply nested types.
- Generic-heavy public APIs.
- Exposing internal lifetime-heavy references.
- Exposing raw pointers or unsafe abstractions.
- Exposing secrets more widely than necessary.
- Bridge APIs that mirror every internal Rust function one-to-one.

## Async and performance rules

Use `async fn` for:

- File IO.
- Network IO.
- Long-running crypto operations.
- Compression/decompression.
- Database-like native operations.
- Anything that should not block the Flutter UI.

For CPU-heavy work:

- Keep the Flutter UI responsive.
- Prefer Rust-side threading or async-friendly design when appropriate.
- Avoid sending huge objects repeatedly over the bridge.
- Prefer chunked or streaming APIs for large files.
- Avoid unnecessary copies of large byte arrays.

For progress reporting:

- Prefer a stream/event API when the operation is long-running.
- Keep progress payloads small.
- Include enough data for UI state: bytes processed, total bytes if known,
  phase, and optional message.

Example progress model:

```rust
pub struct FileCryptoProgress {
    pub phase: String,
    pub processed_bytes: u64,
    pub total_bytes: Option<u64>,
}
```

## Dart sync vs async rules

FRB generates asynchronous Dart APIs by default.

Default behavior:

```rust
pub fn calculate_hash(input: String) -> String {
    // ...
}
```

Generated Dart usage:

```dart
final hash = await calculateHash(input: value);
```

Use the default asynchronous mode for most bridge functions, especially when the
operation can take noticeable time or touch IO.

Use default async mode for:

- File encryption/decryption.
- File IO.
- Network IO.
- Compression/decompression.
- Heavy hashing or KDF work.
- Large parsing/serialization.
- Any operation that may take more than a few milliseconds.
- Anything that should not block Flutter UI.

### `#[frb(sync)]`

Use `#[frb(sync)]` only for tiny, fast, deterministic functions where
synchronous Dart API is actually useful.

Example:

```rust
use flutter_rust_bridge::frb;

pub fn normal() {}

#[frb(sync)]
pub fn dart_counterpart_is_synchronous() {}
```

Dart:

```dart
await normal();
dartCounterpartIsSynchronous();
```

Good candidates for `#[frb(sync)]`:

- Small pure functions.
- Simple validators.
- Lightweight formatters.
- Tiny calculations.
- Fast metadata checks that do not touch disk.
- Functions needed from places where `await` is inconvenient, such as narrowly
  scoped build-time helper logic.

Do not use `#[frb(sync)]` for:

- File IO.
- Crypto over real payloads.
- KDFs such as Argon2id.
- Database work.
- Network work.
- Long loops.
- Large allocations.
- Anything that can freeze the UI.

Important: synchronous FRB calls block the Dart UI isolate while running. A slow
sync Rust function can cause visible Flutter jank/freezes.

### Do not move async FRB calls into another Dart isolate

A common mistake is to call Rust through FRB from another Dart isolate just
because the Rust function is expensive.

Do not do this by default.

FRB async calls are designed so Dart can call Rust from the main isolate without
blocking Flutter UI. Moving the call into a separate Dart isolate usually makes
the architecture harder without improving responsiveness.

Prefer:

```dart
final result = await rustService.encryptFile(request);
```

Avoid unnecessary isolate wrappers like:

```dart
// Usually unnecessary for FRB async calls.
final result = await Isolate.run(() => encryptFile(request));
```

Use a Dart isolate only when there is a separate Dart-side CPU-heavy workload,
not merely because the Rust function itself is heavy.

## Error handling rules

Do not use `panic!` for expected failures.

Use typed errors and convert internal errors into bridge-safe error models.

Expected failures include:

- Invalid password/key.
- Invalid file path.
- Missing file.
- Permission denied.
- Corrupted encrypted file.
- Authentication tag mismatch.
- Unsupported version.
- Canceled operation.
- Invalid input from Dart.

Recommended pattern:

```rust
pub async fn decrypt_file(req: DecryptFileRequest) -> Result<DecryptFileResponse, CryptoError> {
    crate::crypto::file_encryption::decrypt_file(req).await.map_err(CryptoError::from)
}
```

Error model should include:

- Stable machine-readable code.
- Human-readable message.
- Optional debug details for development.
- No secrets.
- No decrypted content.
- No raw keys.

Example:

```rust
pub enum CryptoErrorCode {
    InvalidKey,
    InvalidHeader,
    AuthenticationFailed,
    IoError,
    UnsupportedVersion,
    Unknown,
}

pub struct CryptoError {
    pub code: CryptoErrorCode,
    pub message: String,
    pub debug_message: Option<String>,
}
```

## Security rules

This is critical for password managers, vaults, encryption modules, and local
secret storage.

Never log:

- Master passwords.
- Derived keys.
- Vault keys.
- File encryption keys.
- Nonces if they are sensitive in context.
- Decrypted file content.
- Decrypted database content.
- TOTP/HOTP secrets.
- Recovery codes.
- Private keys.
- Full request/response objects that may contain secrets.

Avoid passing secrets across the bridge unless necessary.

Prefer:

- Passing handles/IDs instead of raw secrets when possible.
- Keeping key material inside the narrowest possible layer.
- Zeroizing sensitive buffers where practical.
- Explicit request/response models so sensitive fields are obvious.
- Redacted debug output.

For file encryption:

- Prefer streaming/chunked APIs for large files.
- Authenticate data, not just encrypt it.
- Validate headers/version/magic bytes before processing payloads.
- Treat authentication failure as a normal expected error.
- Do not partially trust decrypted data before authentication succeeds.

## Ergonomic Dart API: properties, constructors, and constants

FRB can generate more Dart-like APIs from Rust methods. Use these features to
improve ergonomics, but do not hide expensive or security-sensitive work behind
innocent-looking Dart getters, setters, or constructors.

### Properties with `#[frb(getter)]` and `#[frb(setter)]`

Use `#[frb(getter)]` and `#[frb(setter)]` to expose Rust methods as Dart
properties.

This is often best paired with `#[frb(sync)]`, because Dart property access is
normally expected to be immediate.

Example:

```rust
use flutter_rust_bridge::frb;

pub struct A {
    // ...
}

impl A {
    #[frb(sync, getter)]
    pub fn something(&self) -> String {
        // ...
    }

    #[frb(sync, setter)]
    pub fn something(&mut self, value: String) {
        // ...
    }
}
```

Generated Dart shape:

```dart
class A {
  String get something { /* calls Rust */ }
  set something(String value) { /* calls Rust */ }
}
```

Use getters for:

- Cheap metadata.
- Small immutable values.
- Derived values that are fast to compute.
- Non-sensitive public properties.

Avoid getters for:

- File IO.
- Crypto operations.
- Database queries.
- Large allocations or cloning large buffers.
- Secrets, decrypted values, vault keys, tokens, or TOTP seeds.
- Anything that can fail in a meaningful user-visible way.

Use setters only for simple state updates where property assignment is
semantically clear.

Avoid setters for:

- Operations with side effects such as saving files, writing databases, or
  uploading data.
- Security-sensitive changes such as replacing keys or credentials.
- Operations requiring validation, confirmation, audit logging, or progress
  reporting.

Prefer explicit methods for important mutations:

```rust
impl VaultSession {
    pub async fn rotate_key(&mut self, request: RotateKeyRequest) -> Result<RotateKeyResponse, VaultError> {
        // ...
    }
}
```

Instead of hiding it behind:

```rust
// Bad: looks like a harmless property assignment, but may be a critical operation.
#[frb(setter)]
pub fn master_key(&mut self, value: String) {
    // ...
}
```

### Constructors

When a Rust struct has a synchronous `new` method, FRB can expose it as the
default Dart constructor.

Example:

```rust
use flutter_rust_bridge::frb;

pub struct MyStruct {
    // ...
}

impl MyStruct {
    #[frb(sync)]
    pub fn new() -> Self {
        Self {
            // ...
        }
    }
}
```

Dart usage:

```dart
final value = MyStruct();
```

Only make `new` synchronous when construction is cheap and does not perform IO,
heavy computation, KDF work, or platform/resource initialization.

Other constructor-like Rust methods become Dart static methods. Their sync/async
behavior follows the Rust annotations/defaults.

Rust:

```rust
impl MyStruct {
    pub fn new_with_name(name: String) -> Self {
        // async Dart API by default
    }

    #[frb(sync)]
    pub fn new_from_pieces(a: String, b: i32, c: Vec<u8>) -> Self {
        // sync Dart API
    }

    pub async fn whatever_you_like(x: (String, String)) -> Self {
        // async Dart API
    }
}
```

Dart usage:

```dart
final a = await MyStruct.newWithName(name: 'demo');
final b = MyStruct.newFromPieces(a: 'x', b: 1, c: [1, 2, 3]);
final c = await MyStruct.whateverYouLike(x: ('a', 'b'));
```

Constructor rules:

- Use default Dart constructors only for cheap local initialization.
- Use async static constructor-like methods for operations that may block or
  fail.
- Prefer explicit names such as `open`, `load`, `createSession`, `fromFile`, or
  `fromEncryptedBytes` when work is non-trivial.
- For Hoplixi, opening a vault, deriving a key, loading encrypted files, or
  initializing native resources should not be hidden behind a sync Dart
  constructor.

### Constants

FRB can translate public Rust constants when constant parsing is enabled.

Enable it in `flutter_rust_bridge.yaml`:

```yaml
parse_const: true
```

Rust:

```rust
pub const CONST_INT: i32 = 42;
```

Generated Dart shape is a getter-like API, for example:

```dart
final value = constIntTwinNormal;
```

Use constants for stable public values such as:

- Version markers.
- Algorithm identifiers.
- Limits and defaults.
- Non-secret configuration constants.

Do not expose secrets, environment-dependent values, or mutable configuration as
Rust constants.

For Hoplixi, constants are reasonable for values like supported format versions,
minimum/maximum parameter bounds, or algorithm names. They are not appropriate
for salts, keys, tokens, paths containing user data, or runtime vault state.

## Initialization rules

### Prefer `#[frb(init)]` for Rust startup initialization

Use `#[frb(init)]` when Rust-side initialization should happen during
`RustLib.init()`.

Example:

```rust
use flutter_rust_bridge::frb;

#[frb(init)]
pub fn init_app() {
    // Configure panic hooks, logging, crypto providers, global registries, etc.
}
```

Rules:

- The init function must be inside the configured Rust input folder, otherwise
  FRB will ignore it.
- Keep init fast.
- Do not perform heavy IO in init unless startup explicitly requires it.
- Do not load/decrypt vault data in generic Rust init.
- Do not put user-specific state into global init unless the lifecycle is very
  clear.

Typical Dart startup:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  runApp(const App());
}
```

### Alternative manual initialization

If `#[frb(init)]` is not appropriate, call a normal Rust function after
`RustLib.init()`:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  await myRustInitLogic();
  runApp(const App());
}
```

This is useful when initialization depends on runtime configuration from Dart.

