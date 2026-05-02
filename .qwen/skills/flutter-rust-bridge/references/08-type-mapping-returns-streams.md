## Type mapping and generated model rules

Prefer native `flutter_rust_bridge` type translation instead of manually
serializing values into `String` or `Vec<u8>`.

The bridge already supports many Rust types directly, so model the API with Rust
structs, enums, collections, options, and results whenever possible.

### Common Rust to Dart correspondence

Use this mapping as a practical reference when designing bridge-facing APIs:

| Rust                           | Dart                                         |
| ------------------------------ | -------------------------------------------- |
| `Vec<u8>` .. `Vec<u64>`        | `Uint8List` .. `Uint64List`                  |
| `Vec<i8>` .. `Vec<i64>`        | `Int8List` .. `Int64List`                    |
| `Vec<f32>`, `Vec<f64>`         | `Float32List`, `Float64List`                 |
| `Vec<T>`                       | `List<T>`                                    |
| `HashMap<K, V>`                | `Map<K, V>`                                  |
| `HashSet<T>`                   | `Set<T>`                                     |
| `[T; N]`                       | `List<T>`                                    |
| Rust named/tuple `struct`      | Dart class                                   |
| Rust simple enum               | Dart enum                                    |
| Rust enum with associated data | Dart sealed/freezed-style class              |
| `Option<T>`                    | `T?`                                         |
| `Result::Err` or `panic`       | Dart exception                               |
| `Box<T>`                       | `T`                                          |
| `i8`, `u8`, `usize`, etc.      | `int`                                        |
| `i128`, `u128`                 | `BigInt`                                     |
| `f32`, `f64`                   | `double`                                     |
| `bool`                         | `bool`                                       |
| `char`, `String`               | `String`                                     |
| `()`                           | `void`                                       |
| `type A = B`                   | Dart type alias                              |
| `(T, U, ...)`                  | Dart record/tuple-like representation        |
| comments                       | propagated to generated Dart where supported |

Raw identifiers on struct fields are supported, for example `r#type` becomes
`type` on the Dart side. Do not assume raw identifiers are supported everywhere,
especially for function arguments.

### Binary data rules

Use `Vec<u8>` when the value is binary data.

On the Dart side, this becomes `Uint8List`, which is usually what Flutter APIs
expect for bytes.

Good candidates:

- encrypted chunks;
- hashes;
- nonces;
- binary file fragments;
- compressed data;
- encoded public binary formats.

Avoid using `String` for arbitrary binary data. Use `String` only for text or
intentionally encoded values such as base64, hex, JSON, or user-visible text.

For large binary data, avoid passing the whole file through the bridge if
streaming/chunked processing is possible.

### `HashMap` and `HashSet`

`HashMap<K, V>` and `HashSet<T>` are supported and become `Map<K, V>` and
`Set<T>` in Dart.

Example:

```rust
use std::collections::{HashMap, HashSet};

pub fn accept_map(a: HashMap<String, Vec<u8>>) {}
pub fn accept_set(a: HashSet<String>) {}
```

Dart will see approximately:

```dart
Future<void> acceptMap({required Map<String, Uint8List> a});
Future<void> acceptSet({required Set<String> a});
```

Use maps/sets for real domain structures. Do not use `Map<String, dynamic>` as a
substitute for proper Rust structs or enums.

### UUID support

FRB can support the Rust `uuid` crate when the FRB `uuid` feature is enabled.

Typical mapping:

| Rust   | Dart                                 |
| ------ | ------------------------------------ |
| `Uuid` | `UuidValue` from Dart `uuid` package |

If using `Uuid`, ensure the Dart/Flutter project also depends on the Dart `uuid`
package in `pubspec.yaml`.

For `Vec<Uuid>`, FRB may optimize representation by concatenating UUID bytes
internally. Treat this as an implementation detail; keep the public API typed as
`Vec<Uuid>` / Dart UUID values.

For Hoplixi, UUID is a good fit for stable IDs such as vault item IDs,
attachment IDs, snapshot IDs, local entity IDs, and manifest object IDs. Avoid
converting UUIDs to plain strings unless needed for external formats, logs,
URLs, or storage compatibility.

### DateTime and chrono support

FRB can support the Rust `chrono` crate when the FRB `chrono` feature is
enabled.

Typical mapping:

| Rust                    | Dart                         |
| ----------------------- | ---------------------------- |
| `DateTime<Utc>`         | UTC `DateTime`               |
| `DateTime<Local>`       | local-device-time `DateTime` |
| `NaiveDateTime`         | `DateTime`, UTC assumed      |
| `Duration`              | `Duration`                   |
| `Option<NaiveDateTime>` | nullable `DateTime?`         |

Be careful with precision and timezone semantics:

- native platforms use microseconds;
- web platforms use milliseconds because of JavaScript date limitations;
- `DateTime<Local>` is translated into the local time of the device, which may
  not preserve the original sender's local timezone meaning.

For cross-device sync, cloud manifests, vault metadata, and audit/history
timestamps, prefer UTC timestamps with explicit semantics.

If exact timezone offset matters, model it explicitly, for example with a
timestamp plus an offset field.

For Hoplixi, prefer UTC for:

- `createdAt`;
- `updatedAt`;
- `deletedAt`;
- `syncedAt`;
- `expiresAt` when the expiration is absolute;
- manifest timestamps;
- history/event records.

### Struct rules

Normal Rust structs become Dart classes.

Prefer named structs for API request/response objects:

```rust
pub struct EncryptFileRequest {
    pub input_path: String,
    pub output_path: String,
    pub algorithm: String,
}

pub struct EncryptFileResponse {
    pub output_path: String,
    pub bytes_written: u64,
}
```

Tuple structs are supported, but generated Dart fields are named `field0`,
`field1`, etc. Use tuple structs only when the positional meaning is obvious,
such as small wrappers or mathematical values.

For public app APIs, prefer named fields over tuple structs because they are
more readable and safer to evolve.

### Recursive structs

Recursive fields are supported in common cases.

Example:

```rust
pub struct TreeNode {
    pub value: Vec<u8>,
    pub children: Vec<TreeNode>,
}
```

Use recursive structs carefully in app-facing APIs. Deep recursive data can be
expensive to transfer and can make generated models hard to use.

For large graphs, prefer IDs and explicit fetch/query APIs instead of
transferring the whole graph.

### Non-final fields

By default, generated Dart class fields are usually final/immutable.

Use `#[frb(non_final)]` on a struct field only when Dart-side mutation is truly
intended.

```rust
pub struct UserDraft {
    #[frb(non_final)]
    pub display_name: String,
}
```

Prefer immutable generated DTOs for domain data. Use Dart-side copy/update
patterns instead of mutating generated models across the app.

For Hoplixi, avoid `#[frb(non_final)]` for security-relevant fields such as
algorithm, KDF parameters, key IDs, item IDs, attachment IDs, revision numbers,
and timestamps used for conflict resolution.

### Struct and field renaming

Use `#[frb(name = "...")]` to customize Dart-side names when needed.

Example:

```rust
#[frb]
pub struct MyStruct {
    #[frb(name = "dartFieldName")]
    pub rust_field_name: Vec<u8>,
}
```

Use renaming to improve Dart ergonomics or avoid Dart keyword/name conflicts.

Do not use renaming to hide confusing Rust API design. If both sides are
internal to the same project, prefer clear names at the Rust level too.

### Dart metadata annotations

Use `dart_metadata` when generated Dart classes need metadata annotations.

Example:

```rust
#[frb(dart_metadata=("freezed", "immutable" import "package:meta/meta.dart" as meta))]
pub struct UserId {
    pub value: u32,
}
```

This can generate Dart annotations such as `@freezed` or imported metadata
annotations.

Use metadata sparingly. Generated bridge models should stay boring and
predictable.

### Freezed generated classes

Use `#[frb(dart_metadata=("freezed"))]` when a generated Dart class should be
Freezed-like.

This can be useful for DTOs that are widely used in Dart business logic.

Remember that `*.freezed.dart` remains generated. Never edit it manually.

For Hoplixi, Freezed-style generated models are most useful for stable DTOs and
error unions. Do not overuse Freezed metadata on opaque resource wrappers or
low-level performance-sensitive types.

### JSON serialization on generated classes

Use `#[frb(json_serializable)]` when the generated Dart class should have
`fromJson` and `toJson`.

This is useful when a generated type must also participate in Dart-side JSON
workflows.

Do not add JSON serialization by default. For internal Dart↔Rust calls, typed
FRB transfer is usually enough.

For Hoplixi:

- use `#[frb(json_serializable)]` for public import/export DTOs, manifests, or
  diagnostic-safe metadata when useful;
- avoid JSON serialization for secret-bearing objects unless the serialized
  format is explicitly designed, encrypted, authenticated, and reviewed;
- avoid accidental `toJson()` for keys, decrypted values, TOTP secrets, recovery
  codes, private keys, or sensitive vault contents.

### Unignore unused types

FRB may ignore structs/enums that are not referenced by recognized bridge
functions.

Use `#[frb(unignore)]` when a type must be generated even if it is not directly
referenced by an exposed function.

Use this deliberately. If a type is not referenced anywhere, first check whether
the API design is correct.

### Enum rules

Rust enums are supported.

Simple Rust enums become Dart enums:

```rust
pub enum Weekday {
    Monday,
    Tuesday,
}
```

Enums with associated data become Dart sealed/freezed-style classes.

```rust
pub enum OperationResult {
    Success { id: String },
    Failed { code: String, message: String },
    Cancelled,
}
```

Prefer Rust enums for domain variants instead of stringly-typed `kind` fields.

Good enum candidates:

- sync conflict state;
- crypto algorithm;
- item type;
- operation status;
- progress event;
- typed error code;
- import/export result variant.

Avoid `DartDynamic` or `Map<String, dynamic>` when a Rust enum can model the
shape precisely.

### Dart pattern matching for generated sealed classes

Dart 3 supports pattern matching on sealed classes.

When FRB generates Dart sealed class variants from Rust enums with data, prefer
exhaustive `switch` handling in Dart:

```dart
final text = switch (result) {
  OperationResult_Success(:final id) => 'Success: $id',
  OperationResult_Failed(:final code, :final message) => 'Failed: $code $message',
  OperationResult_Cancelled() => 'Cancelled',
};
```

Use exhaustive switches for security- and sync-critical flows so new Rust enum
variants force Dart-side review.

Avoid handling variants with broad fallback logic unless the fallback is
intentionally safe.

### Result and panic rules

FRB maps Rust `Result::Err` and Rust panics to Dart exceptions.

For expected failures, return typed `Result<T, E>` and model `E` as a structured
error.

Do not use `panic!` for expected app errors such as:

- invalid password;
- missing file;
- invalid manifest;
- unsupported version;
- permission denied;
- crypto authentication failure;
- user cancellation;
- sync conflict.

`panic!` is for programmer bugs or unrecoverable invariants.

For Hoplixi, expected Rust errors should be mapped into the app's Dart
error/result layer instead of leaking as generic exceptions throughout UI code.

### Type mapping checklist

When designing or reviewing a bridge-facing type, check:

- Can this be a typed Rust struct/enum instead of JSON or `dynamic`?
- Is binary data represented as `Vec<u8>` rather than text?
- Are timestamps UTC and explicit enough for sync?
- Are UUIDs represented as UUIDs rather than arbitrary strings when possible?
- Are large graphs/chunks avoided or streamed?
- Are enums used instead of stringly-typed `kind/status/type` fields?
- Are secret-bearing fields excluded from generated JSON/accessors?
- Is `#[frb(non_final)]` really needed?
- Is `#[frb(unignore)]` justified?
- Are generated sealed classes handled exhaustively in Dart?

## Return types, exceptions, and streams

### Return type rules

FRB supports several Rust return shapes:

```rust
pub fn direct() -> String { ... }
pub fn anyhow_result() -> anyhow::Result<String> { ... }
pub fn custom_result() -> Result<String, MyError> { ... }
```

On the Dart side:

- direct return types become normal Dart values, usually inside `Future<T>`
  unless the function is `#[frb(sync)]`;
- `anyhow::Result<T>` errors become Dart exceptions;
- `Result<T, CustomError>` errors become Dart exceptions whose type can be
  matched/caught in Dart;
- Rust `panic!` becomes a Dart `PanicException`.

Use direct return types only when failure is impossible or truly unrecoverable.

Use `Result<T, E>` for any operation that can fail because of user input,
filesystem state, crypto verification, invalid data, permissions, cancellation,
or external environment.

Prefer custom structured errors over `anyhow::Error` at the bridge boundary when
Dart needs to distinguish failure causes.

Good bridge-facing error style:

```rust
pub enum FileCryptoError {
    FileNotFound { path: String },
    InvalidHeader { reason: String },
    AuthenticationFailed,
    UnsupportedVersion { version: u32 },
}

pub fn decrypt_file(...) -> Result<DecryptResult, FileCryptoError> { ... }
```

Acceptable use of `anyhow::Result<T>`:

- prototypes;
- internal tools;
- operations where Dart only needs a generic failure message;
- stream `add_error`, because FRB currently accepts `anyhow::Error` there.

Avoid returning string-only errors when Dart needs typed handling.

### Panic rules

Do not use `panic!`, `unwrap()`, or `expect()` for expected failures that can be
triggered by users, files, sync state, cloud state, invalid passwords, corrupt
input, unsupported versions, or cancelled operations.

Bad:

```rust
pub fn open_vault(path: String) -> VaultSession {
    let bytes = std::fs::read(path).unwrap();
    ...
}
```

Better:

```rust
pub fn open_vault(path: String) -> Result<VaultSession, VaultOpenError> {
    let bytes = std::fs::read(path).map_err(VaultOpenError::from)?;
    ...
}
```

Panics are acceptable only for programmer bugs and impossible invariants, for
example an internal match branch that should be unreachable after prior
validation.

For Hoplixi, panic messages must never contain secrets, passwords, keys,
decrypted data, TOTP secrets, file contents, or full sensitive paths.

### Dart-side exception handling

Do not let generated FRB exceptions leak directly into UI widgets.

Recommended Dart layering:

```text
generated FRB API
  -> Dart Rust adapter/service
  -> app Result/AppError mapping
  -> Riverpod/use case/controller
  -> UI
```

The adapter should translate Rust exceptions into the app's normal error model,
for example `AppError.feature(...)` or a domain-specific result type.

Good Dart-side wrapper shape:

```dart
Future<ResultDart<DecryptResult, AppError>> decryptFile(...) async {
  try {
    final result = await rustApi.decryptFile(...);
    return Success(result);
  } on FileCryptoError catch (e, st) {
    return Failure(mapFileCryptoError(e, st));
  } on PanicException catch (e, st) {
    return Failure(mapRustPanic(e, st));
  } catch (e, st) {
    return Failure(mapUnknownRustError(e, st));
  }
}
```

### Stream / iterator APIs

Use FRB streams when Rust needs to return multiple values over time.

Good candidates:

- progress events for file encryption/decryption;
- import/export progress;
- long-running scan results;
- sync progress;
- native logs or diagnostics;
- chunk processing events;
- watch-like notifications from native code.

A Rust function can accept `frb_generated::StreamSink<T>` and become a Dart
`Stream<T>`:

```rust
use anyhow::Result;
use crate::frb_generated::StreamSink;

pub fn encrypt_file_with_progress(
    sink: StreamSink<FileCryptoProgress>,
    request: EncryptFileRequest,
) -> Result<()> {
    sink.add(FileCryptoProgress::Started);
    // ...
    sink.add(FileCryptoProgress::ChunkDone { bytes_done: 4096 });
    // ...
    sink.add(FileCryptoProgress::Finished);
    Ok(())
}
```

On Dart side, this is consumed as a normal `Stream<FileCryptoProgress>`.

Prefer typed stream events instead of raw strings:

```rust
pub enum FileCryptoProgress {
    Started,
    ChunkDone { bytes_done: u64, total_bytes: u64 },
    Finished { output_path: String },
}
```

Avoid:

```rust
sink.add("50%".to_owned());
```

unless it is truly human-only logging.

### Stream errors

Use `sink.add_error(anyhow::anyhow!(...))` to push an error event into a stream
when the stream itself should remain the communication channel.

Prefer modeling recoverable progress states as typed events instead of errors:

```rust
pub enum SyncEvent {
    Started,
    UploadingManifest,
    ConflictDetected { local_revision: u64, remote_revision: u64 },
    Finished,
}
```

Use stream errors for actual failures, not normal business states.

### Stream lifecycle and cancellation

FRB `StreamSink` can be stored and used after the Rust function returns. This is
powerful but dangerous if lifecycle is unclear.

When designing long-lived streams:

- define who owns the stream;
- define how it stops;
- provide a cancel/close function if the operation can run for a long time;
- avoid leaking thread handles, file handles, watchers, or secret buffers;
- do not keep stale sinks forever in global state;
- ensure errors and completion are observable from Dart.

For long-running Hoplixi operations, prefer an opaque operation handle plus a
stream:

```rust
#[frb(opaque)]
pub struct FileCryptoJob { ... }

pub fn start_file_encryption(
    sink: StreamSink<FileCryptoProgress>,
    request: EncryptFileRequest,
) -> Result<FileCryptoJob, FileCryptoError> { ... }

impl FileCryptoJob {
    pub fn cancel(&self) -> Result<(), FileCryptoError> { ... }
    pub fn dispose(&self) { ... }
}
```

Dart should cancel subscriptions and dispose job handles when the owning
screen/use case is disposed.

### Control whether Dart awaits stream creation

By default, a stream is usable immediately and the Rust function itself is not
awaited in the normal way.

Use `#[frb(stream_dart_await)]` when Dart must wait until Rust setup has
finished before receiving the `Stream`.

Use `#[frb(sync)]` for stream creation only if setup is tiny and cannot block
UI.

Do not use sync stream setup for filesystem scans, crypto initialization,
database opening, network setup, or anything that can block.

### StreamSink inside arbitrary types

`StreamSink<T>` may appear in structs/enums/vectors. Use this only when it
improves the API shape.

Do not hide callback-like behavior deeply inside large request objects unless it
is clear from the type name and documentation.

Good:

```rust
pub struct EncryptFileRequest {
    pub input_path: String,
    pub output_path: String,
    pub progress_sink: StreamSink<FileCryptoProgress>,
}
```

Often simpler:

```rust
pub fn encrypt_file(
    sink: StreamSink<FileCryptoProgress>,
    request: EncryptFileRequest,
) -> Result<()> { ... }
```

### Stream rules for Hoplixi

For Hoplixi, use streams for user-visible progress and domain events, not for
dumping sensitive internals.

Never stream:

- master keys;
- vault keys;
- password values;
- decrypted file chunks;
- TOTP secrets;
- private keys;
- full decrypted database records.

Safe stream payloads include:

- bytes processed;
- total bytes;
- item counts;
- operation phase;
- sanitized filenames if appropriate;
- typed error/status codes;
- non-sensitive operation IDs.

