## Low-level opaque safety model and inspection hooks

Most projects should treat `RustOpaque`, `RustAutoOpaque`, `DartOpaque`,
`Droppable`, `RustArc`, persistent handles, finalizers, and generated handler
internals as bridge infrastructure, not as normal application code.

Use this knowledge to reason about lifecycle and safety, but do not rewrite or
bypass FRB internals unless the task is explicitly about bridge internals.

### RustOpaque safety model

`RustOpaque` is based on the idea of transferring an owned/shared Rust resource
across the Dart/Rust boundary safely.

The rough model is:

- Rust owns the real value.
- The value is usually held through an `Arc`-like abstraction.
- Transferring the value between Rust and Dart uses raw pointer handoff
  internally.
- The bridge must pair each raw conversion correctly.
- Dart-side finalizers and explicit `dispose()` must release the resource once
  and exactly once.

Important implications:

- Do not manually encode/decode raw opaque pointers in application code.
- Do not store raw pointer integers in app state, database rows, JSON, logs, or
  preferences.
- Do not attempt to clone or free opaque pointers manually.
- Use the generated Dart opaque class and its `dispose()` method.
- Prefer normal `#[frb(opaque)]` / `RustAutoOpaque<T>` APIs over manual
  `RustOpaque<T>` unless low-level control is genuinely needed.

For application-level design, think of an opaque Rust object as a Dart handle to
a Rust-owned resource.

Good examples:

```rust
#[frb(opaque)]
pub struct StreamingEncryptor { /* file handles, buffers, state */ }

#[frb(opaque)]
pub struct NativeSearchIndex { /* large native index */ }
```

Bad examples:

```rust
#[frb(opaque)]
pub struct PasswordDto { /* small serializable data */ }

#[frb(opaque)]
pub struct AppErrorDto { /* should be a typed enum/struct */ }
```

### Dispose and finalizers

Dart-side GC can eventually release opaque resources, but GC timing is not
deterministic.

For opaque objects that own large, scarce, native, file, lock, temp directory,
or secret-bearing resources, prefer explicit lifecycle management:

```dart
final session = await VaultCryptoSession.open(...);
try {
  await session.doWork(...);
} finally {
  session.dispose();
}
```

Rules:

- Call `dispose()` manually for resources that should be released promptly.
- Do not rely only on GC for file handles, locks, temp dirs, large buffers, or
  secret-bearing state.
- After `dispose()`, treat the Dart object as unusable.
- Do not keep disposed opaque objects in Riverpod state, caches, streams, or UI
  controllers.
- Make ownership obvious in Dart wrappers/services.

### DartOpaque safety model

`DartOpaque` lets Rust hold an opaque Dart object, often a callback or closure.

Internally, this depends on Dart persistent handles and thread/isolate safety
restrictions. Application code should not depend on those internals directly.

Rules:

- Use `DartOpaque` only when Rust must hold an arbitrary Dart object without
  understanding its structure.
- Prefer typed callbacks, typed requests, typed events, or streams when
  possible.
- Do not store Flutter widgets, `BuildContext`, Riverpod `Ref`, controllers, or
  broad app state in Rust.
- Do not store secrets in Dart objects passed to Rust as opaque handles.
- Do not assume a Dart opaque object can be safely used from any Rust thread
  without following FRB callback rules.

Good uses:

- A short-lived callback token.
- A Dart closure passed into a Rust operation.
- A bridge-managed object used only by generated callback machinery.

Poor uses:

- Storing `BuildContext` inside Rust.
- Storing Riverpod providers inside Rust.
- Treating `DartOpaque` as a generic replacement for typed DTOs.

### RustArc, Droppable, and raw pointer internals

FRB internals include concepts similar to:

- `Droppable`: ensures a resource is released once and exactly once.
- `RustArc`: mirrors `std::sync::Arc` semantics on the Dart side.
- `RustOpaque`: wraps an `Arc`-backed Rust object for Dart usage.

Rules for agents:

- Do not modify these internals to fix application bugs.
- Do not bypass generated APIs to call raw pointer functions.
- Do not persist raw `encode()` outputs as durable identifiers.
- Do not compare opaque objects by raw pointer unless the API explicitly
  documents identity semantics.
- If an opaque lifecycle bug is suspected, first check app ownership/dispose
  logic, concurrent borrows, and generated-code version mismatch.

### Threading and isolate considerations

`DartOpaque` and callback internals are designed to preserve safety across
threads/isolate boundaries.

Application-level rules:

- Do not move Dart UI assumptions into Rust threads.
- Do not call Dart callbacks while holding Rust locks.
- Do not block Rust worker threads waiting for UI interactions unless the API is
  explicitly designed for that.
- Prefer `StreamSink<T>` for progress/events instead of ad-hoc global callback
  storage.
- Prefer request/response APIs for one-shot operations.

### Inspection, hooks, and aspect-oriented behavior

FRB allows inspection-style behavior around Dart-to-Rust calls.

On the Dart side, a custom handler can be passed during initialization:

```dart
await RustLib.init(handler: YourCustomHandler());
```

Use this for cross-cutting concerns such as:

- Debug logging of function start/end.
- Timing and performance measurements.
- Sanitized tracing.
- Crash diagnostics.
- Development-only instrumentation.

Rules:

- Do not log sensitive arguments or return values.
- Do not log passwords, master keys, vault keys, private keys, TOTP secrets,
  decrypted file chunks, decrypted records, or full manifests containing
  sensitive metadata.
- Prefer logging operation names, durations, sizes, counts, and sanitized error
  codes.
- Keep instrumentation separate from domain logic.
- Do not make application correctness depend on a debug handler.

Rust-side executor customization is an advanced feature. Use it only when there
is a clear need, such as custom scheduling, tracing, or execution policy. Do not
introduce a custom executor just to fix ordinary app architecture issues.

### Hoplixi-specific opaque safety rules

For Hoplixi, opaque objects are appropriate for native/security/performance
resources such as:

- Streaming file encryptors/decryptors.
- Native crypto sessions.
- Large temporary buffers.
- Search/indexing state.
- Native handles that should not be serialized.

Avoid opaque objects for:

- Password DTOs.
- Notes/cards/documents metadata.
- Sync manifests.
- Error DTOs.
- Small request/response models.
- Values that should be easy to test, serialize, diff, or persist.

Security rules:

- Do not expose secret-bearing fields as public opaque accessors.
- Provide explicit close/clear/dispose behavior for secret-bearing opaque
  resources.
- Keep decrypted data lifetime as short as possible.
- Prefer passing file paths/handles and streaming progress over returning large
  decrypted byte arrays.
- Never store opaque pointer values in the encrypted database or cloud
  manifests.

## Cancellable tasks and Rust logging

Use this section when implementing long-running Rust operations, cancellation,
progress reporting, or logging pipelines in Flutter + Rust applications.

### Cancellable tasks

Long-running Rust work should have an explicit cancellation strategy when the
user can leave the screen, close a vault, cancel an import/export, stop file
encryption, or replace the operation with a newer one.

Good candidates for cancellation:

- large file encryption/decryption;
- archive/import/export operations;
- expensive search/indexing;
- password/security audits over many records;
- long network/cloud sync helper work;
- any loop that may run long enough for the user to cancel it.

Cancellation should be cooperative. Rust code should periodically check a
cancellation flag/token at safe checkpoints and return a typed cancellation
error/result. Do not abruptly leave partially written files, half-updated
manifests, or inconsistent state.

Preferred approaches:

1. **Simple custom cancel token**
   - Use a small shared token object that can be signalled from one side and
     checked from the other.
   - Good for synchronous or mostly CPU-bound loops.
   - Keep the API explicit: create token, pass token to task, call cancel,
     dispose/cleanup token.

2. **Tokio `CancellationToken`**
   - Use when the Rust side is already async/Tokio-based.
   - Good for async loops, async IO, background workers, and select-style
     cancellation.

3. **Other cancellation crates**
   - Acceptable when they match the runtime and ownership model.
   - Do not introduce a cancellation crate just to avoid a simple
     `AtomicBool`-style token.

Design rules:

- Cancellation is not a panic. Return a typed
  `Cancelled`/`Aborted`/`OperationCancelled` error or a domain result.
- Cancellation must be idempotent. Calling cancel multiple times should be safe.
- Cancellation tokens should not contain business state.
- Cancellation should not leak keys, file handles, temp dirs, or partial
  decrypted data.
- Long loops should check cancellation regularly, but not on every single tiny
  instruction if that creates unnecessary overhead.
- If a task writes files, write to a temp file first and atomically commit only
  after success.
- If cancellation leaves resumable state, document exactly what can be resumed
  and what must be discarded.
- If cancellation is exposed to Dart, provide a Dart-side owner that
  cancels/disposes the token from `dispose`, provider cleanup, or operation
  replacement.

Example conceptual API:

```rust
#[frb(opaque)]
pub struct CancelToken {
    // e.g. Arc<AtomicBool> or tokio_util::sync::CancellationToken
}

impl CancelToken {
    #[frb(sync)]
    pub fn new() -> Self { /* ... */ }

    #[frb(sync)]
    pub fn cancel(&self) { /* ... */ }

    #[frb(sync)]
    pub fn is_cancelled(&self) -> bool { /* ... */ }
}

pub fn encrypt_large_file(
    input_path: String,
    output_path: String,
    cancel: &CancelToken,
    progress: StreamSink<EncryptProgress>,
) -> Result<EncryptResult, CryptoError> {
    // Check cancel at chunk boundaries.
    // Emit progress.
    // Cleanup temp output on cancellation/failure.
}
```

Dart ownership pattern:

```dart
final token = CancelToken();
try {
  final stream = encryptLargeFile(
    inputPath: inputPath,
    outputPath: outputPath,
    cancel: token,
  );
  // Listen to progress / await completion depending on API shape.
} finally {
  token.dispose();
}

// On user cancel:
token.cancel();
```

For Riverpod, keep cancellation ownership in a notifier/service responsible for
the operation lifecycle. Do not let widgets manually manage low-level Rust
cancellation tokens unless the widget is the actual operation owner.

### Cancellation and streams

Streams and cancellation often belong together. A long operation can expose
progress through `StreamSink<T>` and accept a cancellation token.

Rules:

- Stream completion should clearly mean the operation finished, failed, or was
  cancelled.
- Emit sanitized progress events only.
- Use typed progress enums/structs instead of string-only events.
- Do not emit decrypted content, keys, passwords, private keys, TOTP secrets, or
  raw vault records.
- If `sink.add_error(...)` is used for cancellation, map it on the Dart side
  into the app's cancellation/error model.
- Drop/close any stored `StreamSink` when it is no longer useful.

### Logging

Rust logging in a Flutter + FRB app should be centralized, sanitized, and
consistent with the Dart logging pipeline.

Default behavior:

- Projects created/integrated with FRB templates may call
  `flutter_rust_bridge::setup_default_user_utils()` and print logs to the
  console by default.
- This is fine for development, but production apps usually need explicit
  filtering, formatting, redaction, and routing.

Accepted approaches:

1. **Default FRB/platform logging**
   - Good for quick development and debugging.
   - Do not rely on it as the only production logging strategy for a
     security-sensitive app.

2. **Platform loggers**
   - Android: platform logger such as `android_logger`.
   - iOS/macOS: platform logger such as `oslog`.
   - Desktop: standard Rust logging/tracing subscribers, depending on the app
     architecture.

3. **Rust logs streamed to Dart**
   - Use standard Rust logging macros internally.
   - Forward sanitized log entries to Dart through a `StreamSink<LogEntry>`.
   - Dart can then send them into the same log pipeline as Flutter logs:
     console, file, diagnostics UI, bug report bundle, etc.

Example log entry model:

```rust
pub struct LogEntry {
    pub time_millis: i64,
    pub level: LogLevel,
    pub target: String,
    pub message: String,
}

pub enum LogLevel {
    Trace,
    Debug,
    Info,
    Warn,
    Error,
}

pub fn create_log_stream(sink: StreamSink<LogEntry>) -> Result<()> {
    // Register/store sink in a controlled logger component.
    // Avoid global mutable state unless guarded and intentionally designed.
    Ok(())
}
```

Logging rules:

- Never log passwords, master keys, vault keys, decrypted data, TOTP secrets,
  private keys, recovery codes, raw tokens, auth codes, OAuth access/refresh
  tokens, or full request/response bodies that may contain secrets.
- Prefer structured logs: level, target/tag, message, timestamp, optional
  sanitized context.
- Use redaction helpers before data crosses Rust → Dart logging streams.
- Keep logging infrastructure separate from business logic.
- Avoid unbounded log streams or unlimited in-memory log buffers.
- Logging must not block crypto/file/database critical paths.
- Debug/trace logs must be easy to disable in production.
- Do not make UI decisions from Rust logging callbacks.
- Do not use logs as the primary progress API; use typed streams for progress.

### Hoplixi-specific cancellation and logging rules

For Hoplixi:

- Long file encryption/decryption should be cancellable at chunk boundaries.
- Cancelled encryption/decryption should clean up temp files and not leave
  decrypted remnants.
- Cloud/snapshot helper tasks should be cancellable only at safe transaction
  boundaries.
- DB/vault state transitions should not be partially committed because of
  cancellation.
- Cancellation should be reflected as a domain outcome, not a crash.
- Rust logs should feed into the same sanitized app logging layer used by Dart.
- Rust logs must never include vault names if the user treats them as sensitive,
  full local paths when avoidable, decrypted filenames/content, secrets, or raw
  cloud tokens.
- Progress streams may include byte counts, percentages, phase names, and
  sanitized item counts.
- Progress streams must not include decrypted chunks or secret values.

## Review checklist

Before finishing a task involving FRB, verify:

- No generated files were manually patched.
- Rust API modules are exported correctly.
- Bridge-facing types are simple enough and intentional.
- Secrets are not logged or unnecessarily passed around.
- Expected errors use typed `Result<T, E>` values, not panics.
- Bridge-facing Rust errors are structured enough for Dart-side handling.
- Dart adapters map FRB exceptions into the app error/result layer before UI.
- Large files are handled with streaming/chunking where appropriate.
- Stream APIs use typed event enums/structs instead of raw strings where
  possible.
- Long-lived streams have cancellation, cleanup, and ownership rules.
- Sync Dart APIs use `#[frb(sync)]` only for tiny fast functions.
- Async FRB calls are not unnecessarily wrapped in Dart isolates.
- Rust initialization uses `#[frb(init)]` or explicit manual init intentionally.
- Stateful Rust uses `#[frb(opaque)]`, `RustAutoOpaque`, or carefully justified
  global state.
- JSON/Protobuf/manual serialization is used only when there is a concrete
  protocol/storage reason.
- `DartOpaque`, `RustOpaque`, `DartDynamic`, and Rust-to-Dart callbacks are used
  only when they are actually justified.
- Opaque objects have a clear lifecycle and `dispose()` strategy when they own
  large/native/secret resources.
- Rust callbacks do not hold locks while awaiting Dart code.
- Lifetime support is enabled only when intentionally needed and the exposed
  lifetime syntax is explicit.
- Borrowed/lifetime-bearing objects have a clear disposal strategy before
  mutable follow-up operations.
- Opaque public accessors do not expose secrets or fragile invariants.
- FRB getters/setters are used only for cheap, obvious, non-sensitive
  property-like operations.
- Sync constructors are used only for cheap local initialization; expensive
  creation uses explicit async methods.
- `parse_const: true` is used only when public Rust constants are intentionally
  part of the Dart API.
- Generated equality/hash behavior is intentional, especially for large,
  sensitive, or resource-like types.
- `#[frb(name = ...)]` is used only for clear Dart API ergonomics, not to hide
  confusing Rust names.
- `#[frb(default = ...)]` is used only for safe defaults; security-sensitive
  defaults come from reviewed config/policy objects.
- Custom encoders/decoders are used only when native FRB type mapping is
  insufficient.
- Decode/conversion failures have a safe typed error path where appropriate.
- Binary APIs use `Vec<u8>` / `Uint8List`, streams, chunks, paths, or opaque
  handles intentionally.
- Experimental `ui_state` / `ui_mutation` utilities are used only after an
  explicit architecture decision.
- Manual `RustOpaque` / `DartOpaque` usage is justified and not replacing normal
  typed models.
- Opaque resources that own files, native resources, large buffers, locks, or
  secrets have explicit `dispose()`/cleanup rules.
- Raw opaque pointer values are not persisted, logged, compared, or manually
  freed by app code.
- Custom handlers/executors are used only for instrumentation or clear execution
  policy, not domain logic.
- Long-running Rust operations have an explicit cancellation strategy when user
  cancellation or lifecycle disposal is possible.
- Cancellation returns a typed/domain result instead of panic or inconsistent
  partial state.
- Rust logging is sanitized, centralized, and does not expose secrets or
  decrypted data.
- Rust log streaming, if used, has bounded lifecycle and does not replace typed
  progress streams.
- Dart UI does not depend directly on low-level Rust internals.
- Code generation was run when required.
- `flutter analyze` and `cargo check` pass or any failures are clearly reported.

## Common anti-patterns

Avoid:

- Editing `frb_generated.dart` manually.
- Exposing every internal Rust function to Dart.
- Returning stringly typed errors for everything.
- Letting raw FRB exceptions leak directly into widgets.
- Logging full request objects that may contain secrets.
- Doing long CPU/file work synchronously on the UI path.
- Marking heavy functions as `#[frb(sync)]`.
- Wrapping FRB async calls in Dart isolates without a Dart-side CPU-heavy
  reason.
- Storing per-vault/per-user secrets in careless global Rust state.
- Sending huge byte arrays repeatedly over the bridge.
- Wrapping all FRB calls in JSON strings instead of using typed request/response
  models.
- Using JSON/Protobuf internally when FRB native type translation is sufficient.
- Exposing secret fields as generated opaque accessors.
- Forgetting to dispose opaque objects that own files, large buffers, temp dirs,
  or secret state.
- Mutating nested opaque fields through accessors when object identity matters.
- Using `DartDynamic` instead of proper enums/structs.
- Using `DartOpaque` to hide normal domain/request/response data.
- Holding Rust locks while awaiting Dart callbacks.
- Triggering Flutter UI prompts directly from low-level Rust callbacks.
- Using experimental lifetime support when owned values, `RustAutoOpaque`,
  shared ownership, proxy methods, or cloning would be simpler.
- Keeping lifetime-bearing borrowed objects alive in Dart/Riverpod state without
  an explicit lifecycle.
- Relying on Dart GC to end borrows before a mutable Rust operation.
- Hiding expensive IO, crypto, database work, or security-sensitive changes
  behind getters/setters.
- Making sync Dart constructors perform heavy work or resource initialization.
- Exposing secrets or runtime vault state as generated constants.
- Relying on generated equality/hash for large buffers, secrets, handles, or
  resource/session objects.
- Using `#[frb(name = ...)]` to paper over unclear API concepts.
- Scattering cryptographic/security defaults across many `#[frb(default = ...)]`
  parameters.
- Putting app orchestration or UI decisions inside Rust.
- Making Dart widgets call generated Rust APIs directly.
- Using `panic!`, `unwrap()`, or `expect()` for user-triggered failures.
- Using streams to emit secrets, decrypted chunks, private keys, or sensitive
  records.
- Creating long-lived streams without cancellation or cleanup.
- Running long Rust tasks without a cooperative cancellation path when
  user/lifecycle cancellation is expected.
- Treating cancellation as `panic!` or leaving partial files/manifests behind.
- Logging passwords, keys, tokens, decrypted data, raw vault records, or
  sensitive file paths from Rust.
- Using Rust log streams as a substitute for typed progress/event streams.
- Encoding binary data as base64/JSON arrays when `Vec<u8>` / `Uint8List` would
  work directly.
- Adding custom encoders/decoders to hide an unclear or unstable API.
- Using `unwrap()` in bridge conversion code for user-controlled or
  file/network-controlled data.
- Moving Flutter/Riverpod UI state into experimental Rust UI-state utilities
  without a deliberate Rust-first architecture.
- Persisting or logging raw opaque pointer values.
- Using manual `RustOpaque<T>` when `#[frb(opaque)]` / `RustAutoOpaque<T>` would
  be simpler and safer.
- Passing `BuildContext`, widgets, Riverpod `Ref`, or broad UI state into Rust
  as `DartOpaque`.
- Relying on Dart GC instead of explicit `dispose()` for scarce or
  secret-bearing Rust resources.
- Putting business logic into custom FRB handlers/executors.
- Logging sensitive arguments/return values from FRB inspection hooks.

## Final response behavior for AI agents

When completing an FRB task, report:

- What Rust/Dart source files were changed.
- Whether generation was needed and run.
- Whether generated files changed.
- What validation commands were run.
- Any remaining failures or assumptions.

Do not claim that generation or tests passed unless they were actually run.
