## Stateful Rust rules

Rust can hold state, but the lifecycle must be explicit and safe.

### Preferred: opaque Rust objects

Prefer automatic arbitrary Rust types with `#[frb(opaque)]` for stateful Rust
services/handles.

Use this when Dart should hold a handle to Rust-owned state without serializing
the internals across the bridge.

Example:

```rust
use flutter_rust_bridge::frb;

#[frb(opaque)]
pub struct NativeCryptoSession {
    // Internal state stays in Rust.
}

impl NativeCryptoSession {
    pub fn new() -> Self {
        Self {}
    }

    pub async fn close(&self) -> Result<(), CryptoError> {
        Ok(())
    }
}
```

Benefits:

- Avoids global variables.
- Keeps internal Rust state private.
- Avoids repeated serialization/deserialization.
- Gives Dart an explicit object/handle to manage.

Use opaque types for:

- Sessions.
- Long-lived native handles.
- Streaming encryptors/decryptors.
- Parsers with internal buffers.
- Caches with explicit lifecycle.

Security note: if an opaque object owns sensitive material, provide an explicit
close/drop/lifecycle strategy and avoid exposing debug output containing
secrets.

### Alternative: static/lazy global state

`lazy_static`, `OnceLock`, `LazyLock`, `Mutex`, `RwLock`, and similar Rust
global-state patterns can be used, but should be a deliberate choice.

Use global state only for:

- Process-wide immutable configuration.
- Logging/tracing setup.
- Global registries that are safe to share.
- Truly singleton native resources.

Avoid global state for:

- User vault secrets.
- Per-store keys.
- Current active database/vault unless lifecycle and concurrency are carefully
  designed.
- Anything that makes tests order-dependent.

### Alternative: copy state across the bridge

For very small state, it can be fine to copy data between Dart and Rust using
normal non-opaque structs.

Use this for:

- Small request/response models.
- Serializable settings.
- Stateless calculations.

Avoid copying large or sensitive state repeatedly.

## Dart API naming, equality, hash, and default parameters

FRB can customize generated Dart API details such as equality, hashing,
Dart-side names, and default parameter values. Use these features to make the
bridge API pleasant to consume, but avoid using them to hide unclear Rust API
design.

### Equality and `hashCode`

For generated non-Freezed Dart classes, the default behavior is usually
field-by-field equality and field-based `hashCode`.

For generated Freezed classes, equality and hashing follow Freezed behavior,
which is normally also field-by-field.

This is useful for DTO-like bridge models:

- Request models.
- Response models.
- Config models.
- Small immutable value objects.
- Error detail models.

If field-by-field equality is not correct or is too expensive, disable it on the
Rust type with:

```rust
use flutter_rust_bridge::frb;

#[frb(non_hash, non_eq)]
pub struct LargeNativeSummary {
    pub id: String,
    pub preview: Vec<u8>,
}
```

Use `#[frb(non_hash, non_eq)]` when:

- The struct contains large fields and equality would be expensive.
- Equality should be identity-based, not value-based.
- The type represents a handle/session/resource rather than a value.
- The generated equality could accidentally compare sensitive data.

For opaque/resource-like objects, prefer explicit identity fields or explicit
comparison methods instead of relying on generated field equality.

Avoid custom `operator ==` / `hashCode` through injected Dart code unless there
is a very strong reason. Custom injected Dart code is harder to review, harder
to regenerate safely, and easier to break across FRB upgrades.

### Custom Dart names with `#[frb(name = "...")]`

Use `#[frb(name = "...")]` when the Rust name is good Rust style but the Dart
API needs a different public name.

Example:

```rust
use flutter_rust_bridge::frb;

#[frb(name = "calculateVaultChecksum")]
pub fn calculate_vault_checksum(path: String) -> Result<String, ChecksumError> {
    // ...
}
```

Generated Dart shape:

```dart
final checksum = await calculateVaultChecksum(path: path);
```

Use renaming for:

- Avoiding awkward generated names.
- Preserving a stable Dart API while refactoring Rust internals.
- Avoiding conflicts with Dart keywords or existing APIs.
- Making abbreviations clear on the Dart side.

Avoid renaming when:

- It hides two different concepts behind the same Dart-like name.
- It makes Rust and Dart APIs difficult to trace during debugging.
- A proper Rust rename would be clearer.

Rule of thumb: prefer clear Rust names first; use `#[frb(name = ...)]` for API
ergonomics, not as a substitute for good naming.

### Default parameters with `#[frb(default = ...)]`

Use `#[frb(default = ...)]` to generate Dart default values for function or
constructor parameters.

For primitives, the value is written directly:

```rust
use flutter_rust_bridge::frb;

pub fn generate_password(
    #[frb(default = 24)] length: u32,
    #[frb(default = true)] include_symbols: bool,
) -> String {
    // ...
}
```

For enums or classes, the default is Dart code and must be valid in a constant
context:

```rust
use flutter_rust_bridge::frb;

pub enum Answer {
    Yes,
    No,
}

pub struct Point(pub f64, pub f64);

#[frb]
pub fn defaults(
    #[frb(default = "Answer.yes")] answer: Answer,
    #[frb(default = "const Point(field0: 2, field1: 3)")] point: Point,
) {
    // ...
}
```

Use default parameters for:

- Safe convenience defaults.
- Non-security-critical tuning knobs.
- UI-friendly helper functions.
- Backward-compatible optional parameters.

Avoid default parameters for:

- Cryptographic parameters where explicit choices matter.
- KDF cost parameters unless they come from a reviewed central policy.
- File paths, vault identifiers, or user-specific secrets.
- Anything where a silent default can cause data loss, weak security, or
  confusing behavior.

For Hoplixi, defaults are acceptable for harmless UX options, but security
defaults should usually be centralized in a named config/policy object rather
than scattered across bridge function parameters.

Good:

```rust
pub fn estimate_password_strength(
    password: String,
    #[frb(default = true)] check_common_patterns: bool,
) -> StrengthReport {
    // ...
}
```

Be careful:

```rust
// Risky if scattered everywhere; prefer a reviewed KdfPolicy or StoreKeyConfig.
pub fn derive_key(
    password: String,
    salt: Vec<u8>,
    #[frb(default = 3)] iterations: u32,
) -> Result<Vec<u8>, CryptoError> {
    // ...
}
```

### Generated API compatibility

When changing Dart-facing names, equality behavior, or defaults:

- Treat it as a public API change.
- Check call sites in Dart.
- Regenerate FRB output.
- Run `flutter analyze`.
- Update tests that depend on equality, map/set behavior, or omitted parameters.

## Serialization rules: FRB types vs JSON/Protobuf

Prefer native `flutter_rust_bridge` type translation over manual JSON/Protobuf
payloads.

FRB can translate many useful Rust/Dart types directly, so do not serialize
everything into `String` or `Vec<u8>` unless there is a concrete reason.

Prefer direct FRB types:

```rust
pub struct CreateVaultRequest {
    pub name: String,
    pub kdf_memory_kib: u32,
    pub use_device_key: bool,
}

pub struct CreateVaultResponse {
    pub store_uuid: String,
    pub created_at_ms: i64,
}

pub async fn create_vault(req: CreateVaultRequest) -> Result<CreateVaultResponse, VaultError> {
    // ...
}
```

Avoid using JSON as the default bridge protocol:

```rust
// Avoid as default style.
pub fn create_vault_json(payload: String) -> Result<String, VaultError> {
    // serde_json in/out
}
```

Use JSON, Protobuf, MessagePack, CBOR, or another manual serialization method
only when:

- You need compatibility with an existing protocol/file format.
- The payload already exists as serialized data.
- You are bridging a schema shared with other languages/services.
- You need to store or transmit the same binary/text payload outside FRB.
- You intentionally want an opaque boundary with a stable external wire format.

If using JSON manually:

```rust
pub fn f(a: String) -> Result<String, MyError> {
    let arg: MyInput = serde_json::from_str(&a).map_err(MyError::from)?;
    let result = MyOutput { value: 42 };
    serde_json::to_string(&result).map_err(MyError::from)
}
```

Dart:

```dart
final result = jsonDecode(await f(a: jsonEncode({'x': [100, 200], 'y': 'hello'})));
```

Rules for manual serialization:

- Validate input strictly on the Rust side.
- Return typed errors for parse/schema failures.
- Do not hide all errors behind generic `String` messages.
- Avoid double-serialization when FRB can translate the type directly.
- Avoid using JSON for secret-heavy payloads unless redaction and lifecycle are
  clear.
- Do not use JSON/Protobuf merely because it feels simpler for the agent.

For Hoplixi, prefer typed FRB request/response models for internal app calls.
Use manual serialization only for actual vault/file formats, import/export
formats, cloud manifests, or cross-version storage protocols.

