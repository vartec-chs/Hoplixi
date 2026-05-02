## Custom encoders/decoders, zero-copy, and Rust-GUI utilities

### Custom encoders/decoders

`flutter_rust_bridge` can customize how a specific Rust type is converted to and
from a Dart type by using `#[frb(rust2dart(...))]` and `#[frb(dart2rust(...))]`.

Use this only when the normal FRB type mapping is not enough. Prefer ordinary
structs/enums, `Vec<u8>`, `String`, `Option<T>`, `Result<T, E>`, `HashMap`,
`HashSet`, opaque types, and generated Dart models first.

A custom codec is reasonable when:

- a Rust type has a well-known Dart counterpart with a better public API;
- an external package type must appear on the Dart side;
- a domain type has an existing canonical string/binary encoding;
- compatibility with an existing file, protocol, or API format is required.

Example pattern:

```rust
#[frb(rust2dart(
    dart_type = "FancyDartType",
    dart_code = "FancyDartType.letsParseIt({})"
))]
pub fn encode_fancy_type(raw: FancyRustType) -> String {
    // Convert Rust representation into a bridge-supported representation.
}

#[frb(dart2rust(
    dart_type = "FancyDartType",
    dart_code = "{}.letsEncodeIt()"
))]
pub fn decode_fancy_type(raw: String) -> FancyRustType {
    // Convert bridge-supported representation back into Rust type.
}
```

After that, bridge-facing functions can expose `FancyRustType`, while Dart sees
`FancyDartType`.

If the Dart conversion code needs imports, use `dart_preamble` in
`flutter_rust_bridge.yaml`. Keep these imports minimal and stable.

Avoid using custom codecs to hide unclear API design. If a normal typed FRB
model is readable and efficient enough, use it instead.

If encode/decode can fail, prefer designing a safe validated constructor or
explicit conversion method. Do not casually `unwrap()` conversion results unless
failure truly means a programmer bug or invariant violation. In
security-sensitive Hoplixi code, failed decoding should usually become a typed
error, not a panic.

### Zero-copy behavior

FRB avoids copies automatically when possible. In many common cases, especially
Rust-to-Dart transfer of byte vectors in asynchronous Dart mode or streams on
native platforms, `Vec<u8>` and related typed vectors can be transferred
efficiently as typed data.

Use this knowledge to design binary APIs cleanly:

- use `Vec<u8>` / `Uint8List` for binary payloads;
- use typed progress streams for long-running binary work;
- avoid repeatedly sending the same huge buffer over the bridge;
- prefer file paths, handles, opaque streaming objects, or chunked APIs for very
  large data.

Do not build manual base64, JSON-array, or string encodings for bytes unless
required by an external protocol. They are usually slower, larger, and less
clear than `Vec<u8>` / `Uint8List`.

For Hoplixi, zero-copy-friendly APIs are useful for encrypted bytes, file
chunks, hashes, nonces, salts, and signatures. However, do not expose decrypted
file contents or secret material broadly just because transfer is efficient.

### Rust-GUI-via-Flutter utilities

FRB has experimental utilities intended for “Rust as app core, Flutter as GUI”
designs, such as:

- `#[frb(ui_state)]` for state structs;
- `#[frb(ui_mutation)]` for methods that mutate state and notify Flutter UI.

Treat these as experimental and architecture-specific. They may be useful in a
Rust-first application where Flutter is mostly a UI shell. They are usually not
the default choice for a Flutter-first app with Riverpod, clean architecture,
and Dart-side orchestration.

For Hoplixi, prefer:

- Dart/Riverpod for UI state and orchestration;
- Rust for isolated native/security/performance modules;
- typed request/response APIs, streams, and opaque resource handles for
  communication.

Do not move the main application state machine, navigation decisions, prompts,
or Riverpod-like state into Rust merely because `ui_state`/`ui_mutation` exists.
Use these attributes only after an explicit architecture decision.

### Checklist for custom codecs and binary APIs

Before adding a custom encoder/decoder or low-level binary bridge API, verify:

- Native FRB type mapping is insufficient for this case.
- The Dart-side type is worth exposing directly.
- Required `dart_preamble` imports are stable and minimal.
- Decode failures have a clear error path.
- The API does not hide security-sensitive validation behind a fragile string
  conversion.
- Large binary payloads are not repeatedly copied without need.
- Secrets are not exposed simply because zero-copy makes transfer cheap.
- Experimental UI-state attributes are not being used as a shortcut around
  proper Flutter/Riverpod architecture.

