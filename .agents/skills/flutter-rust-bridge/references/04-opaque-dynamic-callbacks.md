## Opaque Rust objects and `RustAutoOpaque`

`flutter_rust_bridge` supports arbitrary Rust types by representing Rust-owned
objects as smart pointers/handles on the Dart side. This is often called
`RustAutoOpaque` or automatic arbitrary Rust types.

Use opaque types when the object:

- Cannot or should not be serialized across the bridge.
- Owns a native resource such as a file descriptor, temp directory, lock,
  channel, stream, or database handle.
- Contains large data that should stay in Rust.
- Contains sensitive data that should not be copied into Dart.
- Represents a stateful session, worker, reader, writer, parser, encryptor, or
  decryptor.

Example:

```rust
use flutter_rust_bridge::frb;

#[frb(opaque)]
pub struct MyTempDir {
    dir: tempdir::TempDir,
}

impl MyTempDir {
    pub fn new() -> Self {
        // ...
    }

    pub fn directory_path(&self) -> String {
        self.dir.path().to_string_lossy().to_string()
    }

    pub fn read_text(&self, filename: String) -> Result<String, FileError> {
        std::fs::read_to_string(self.dir.path().join(filename)).map_err(FileError::from)
    }
}
```

Dart usage is object-like:

```dart
final dir = await MyTempDir.newMyTempDir();
final path = await dir.directoryPath();
final text = await dir.readText(filename: 'a.txt');
```

### Opaque vs non-opaque

By default, FRB tries to infer whether a type should be opaque.

Use annotations when the desired behavior must be explicit:

```rust
#[frb(opaque)]
pub struct HeavyRustState {
    pub name: String,
    internal_cache: Vec<u8>,
}

#[frb(non_opaque)]
pub struct SmallDto {
    pub name: String,
}
```

Use `#[frb(opaque)]` when a type is encodable but you still want Rust ownership
because the data is heavy, sensitive, stateful, or mainly manipulated in Rust.

Non-opaque types are copied/transferred field-by-field and become normal Dart
classes. Opaque types stay Rust-owned and Dart holds a handle.

### Ownership and borrowing rules

Normal Rust ownership rules still apply:

```rust
pub fn consume(obj: MyType) {}
pub fn borrow(obj: &MyType) {}
pub fn mutable_borrow(obj: &mut MyType) {}
```

Meaning:

- `MyType` consumes/owns the object.
- `&MyType` borrows immutably.
- `&mut MyType` borrows mutably.

If Dart/Rust usage violates Rust's borrowing model, FRB should report a runtime
error instead of causing undefined behavior.

Rules:

- Do not design APIs that require overlapping mutable borrows.
- Keep mutable operations explicit and short-lived.
- Prefer methods on opaque structs for stateful behavior.
- For sensitive state, provide explicit close/dispose methods even if Rust has
  `Drop`.

### Dispose rules

Dart opaque objects usually have a `dispose()` method. Garbage collection can
eventually release the Rust object, but manual disposal is better for large or
scarce resources.

Call `dispose()` manually when the Rust object owns:

- Open files.
- Large buffers.
- Native handles.
- Temp directories.
- Long-running worker state.
- Cryptographic/session state that should be released promptly.

For small cheap opaque objects, relying on GC can be acceptable, but explicit
lifecycle is still preferred in app services.

Dart pattern:

```dart
final session = await NativeCryptoSession.newNativeCryptoSession();
try {
  await session.process();
} finally {
  session.dispose();
}
```

For Flutter/Riverpod, dispose opaque Rust resources from provider/notifier
disposal hooks when they are lifecycle-owned by that provider.

### Opaque properties and accessors

For public fields on opaque structs, FRB can generate getters/setters.

Example:

```rust
#[frb(opaque)]
pub struct MyOpaqueType {
    pub name: String,
    #[frb(ignore)]
    pub no_accessor: String,
    db: Database,
}
```

Dart may get generated accessors like:

```dart
final name = await object.name;
await object.setName('new name');
```

Rules:

- Prefer explicit methods over exposing many public mutable fields.
- Keep fields private if they represent invariants, resources, locks, or
  secrets.
- Use `#[frb(ignore)]` for public fields that should not have accessors.
- Use struct-level ignore controls if accessors should be disabled broadly.
- Do not expose secret fields as accessors.

For Hoplixi, avoid public accessors for key material, decrypted data, TOTP
secrets, private keys, recovery codes, or vault internals.

### Caveat: cloned accessor values

Be careful when accessing nested opaque fields through generated properties.
Some field reads may clone the field value, so mutation of a nested object may
not affect the original object in the way a Dart developer expects.

Problem pattern:

```rust
#[frb(opaque)]
pub struct A {
    pub b: B,
}

#[frb(opaque)]
pub struct B {
    pub c: i32,
}
```

Dart-like usage may be confusing:

```dart
a.b.c += 1;
print(a.b.c); // May be unchanged if `a.b` produced a cloned object
```

Preferred solution for shared nested opaque state:

```rust
use flutter_rust_bridge::RustAutoOpaque;

pub struct A {
    pub b: RustAutoOpaque<B>,
}
```

Rules:

- If a translatable or opaque struct contains an opaque field that must refer to
  the same underlying object across calls, consider `RustAutoOpaque<B>`.
- Avoid deep mutation through generated accessors when identity matters.
- Prefer explicit Rust methods like `a.increment_b_c()` when invariants or
  identity are important.
- If a type should just be copied, make it non-opaque with `#[frb(non_opaque)]`.

### Opaque inside translatable structs

If a normal translatable struct contains an opaque field and the same object
needs to be used multiple times, wrap it with `RustAutoOpaque<T>`.

Prefer:

```rust
use flutter_rust_bridge::RustAutoOpaque;

pub struct A {
    pub b: RustAutoOpaque<B>,
}
```

Instead of:

```rust
pub struct A {
    pub b: B,
}
```

This avoids accidentally consuming/moving the owned opaque object when shared
ownership is required.

### Working directly with `RustAutoOpaque<T>`

`RustAutoOpaque<T>` behaves roughly like shared ownership over locked Rust
state, conceptually similar to `Arc<RwLock<T>>`.

Example sketch:

```rust
use flutter_rust_bridge::RustAutoOpaqueNom;

fn example() {
    let opaque = RustAutoOpaqueNom::new(42);
    *opaque.try_write().unwrap() = 100;
    println!("{}", opaque.try_read().unwrap());
}
```

Typical access methods include variants such as:

- `try_read`
- `try_write`
- `read`
- `write`
- `blocking_read`
- `blocking_write`

Rules:

- Avoid holding locks across long-running operations.
- Do not hold a write lock while calling back into code that may re-enter the
  same object.
- Prefer `try_read`/`try_write` when you want to surface contention as an error.
- Map lock/contention errors into typed bridge errors.
- Avoid `unwrap()` in production bridge-facing code.

## Arbitrary Dart objects, manual opaque types, dynamic values, and callbacks

FRB also supports passing Dart-owned opaque objects into Rust, manually
controlling opaque Rust pointers, returning dynamic Dart values, and letting
Rust call Dart callbacks. Treat these features as powerful escape hatches, not
the default architecture.

### Automatic arbitrary Dart type: `DartOpaque`

`DartOpaque` is the mirror of automatic arbitrary Rust types. It lets Rust store
and return an opaque handle to a Dart object without understanding its
internals.

Use `DartOpaque` when Rust only needs to hold or pass back a Dart object, such
as a closure, token, or callback-like handle.

Rust example:

```rust
use flutter_rust_bridge::DartOpaque;

pub fn put_dart_opaque(a: DartOpaque) {
    // Store/pass the Dart object as opaque.
}

pub fn get_dart_opaque() -> DartOpaque {
    // Return an opaque Dart object back to Dart.
    todo!()
}
```

Dart usage sketch:

```dart
await putDartOpaque(() => '42');
final answer = await getDartOpaque() as String Function();
print(answer());
```

Rules:

- Use `DartOpaque` when Rust should not inspect the Dart value.
- Prefer typed FRB structs/enums/functions when Rust needs to understand the
  data.
- Do not use `DartOpaque` to hide poor data modeling.
- Be careful with lifecycle: a Dart object held by Rust may live longer than
  expected.
- Do not store Flutter widget/build-context objects in Rust.
- Do not store UI-only objects globally in Rust.
- For Hoplixi, do not store secret-bearing Dart objects in long-lived Rust
  globals.

Good uses:

- Dart callbacks passed into Rust.
- Opaque user data associated with a Rust operation.
- Callback context that Rust only passes back.

Bad uses:

- Normal request/response models.
- App state that should live in Riverpod.
- Domain objects that Rust needs to validate or transform.
- Anything requiring predictable serialization.

### Manual arbitrary Rust type: `RustOpaque<T>`

Usually, automatic arbitrary Rust types with `#[frb(opaque)]` or
`RustAutoOpaque<T>` are enough.

Use manual `RustOpaque<T>` only when you need lower-level control over the
opaque pointer representation.

Rust example:

```rust
use flutter_rust_bridge::RustOpaque;
use std::sync::{Mutex, RwLock};

pub struct ArbitraryData {
    // ...
}

pub fn use_opaque(a: RustOpaque<ArbitraryData>) {
    // ...
}

pub fn even_use_locks(
    b: RustOpaque<Mutex<ArbitraryData>>,
) -> RustOpaque<RwLock<ArbitraryData>> {
    // ...
    todo!()
}

pub enum AnEnumContainingOpaque {
    Hello(RustOpaque<ArbitraryData>),
    World(i32),
}
```

Dart usage sketch:

```dart
final opaque = await functionThatCreatesSomeOpaqueData();
await functionThatUsesSomeOpaqueData(opaque);
opaque.dispose();
```

Rules:

- Prefer `#[frb(opaque)]` first.
- Use `RustOpaque<T>` only when automatic opaque handling is insufficient.
- Keep ownership and disposal explicit.
- Avoid leaking manual opaque types through too many Dart layers.
- Wrap manual opaque objects in Dart services when used by app code.

### Trait objects behind opaque pointers

Trait objects can be placed behind opaque pointers when Rust needs dynamic
dispatch internally.

Example pattern:

```rust
use flutter_rust_bridge::{opaque_dyn, RustOpaque};
use std::fmt::Debug;
use std::panic::{RefUnwindSafe, UnwindSafe};

pub struct DebugWrapper(pub RustOpaque<Box<dyn Debug>>);

pub fn create_debug_wrapper() -> DebugWrapper {
    DebugWrapper(opaque_dyn!("foobar"))
}

pub struct DebugWrapper2(
    pub RustOpaque<Box<dyn Debug + Send + Sync + UnwindSafe + RefUnwindSafe>>,
);
```

Rules:

- Use trait-object opaque wrappers only for Rust-side polymorphism.
- Do not expose trait-object complexity to normal Dart app code.
- Provide clear Rust methods around the opaque object instead of making Dart
  understand the trait design.
- Ensure thread-safety bounds such as `Send`/`Sync` are present when the object
  can cross threads.

### Naming of manual opaque inner types

When `RustOpaque<T>` becomes a Dart type, FRB transforms `T` into a valid Dart
type name. Rust keywords like `dyn` or `'static` may be removed, and
non-alphanumeric characters may be ignored.

Rules:

- Do not rely on complex generated names for app architecture.
- Prefer wrapper structs with clear names when exposing manual opaque values.
- If the generated Dart type name is confusing, add a named Rust wrapper type.

Prefer:

```rust
pub struct VaultCryptoSessionHandle(
    pub RustOpaque<Box<dyn VaultCryptoSession + Send + Sync>>,
);
```

Instead of exposing a deeply nested `RustOpaque<Box<dyn ...>>` directly
everywhere.

### Dart `dynamic` and `DartDynamic`

Avoid `dynamic` as the default bridge design.

If a value can be one of several known shapes, prefer a Rust enum instead of
`DartDynamic`.

Avoid this weak model:

```rust
pub struct MyStruct {
    pub a: Option<u32>,
    pub b: Option<String>,
}
```

Prefer an enum:

```rust
pub enum MyEnum {
    U32(u32),
    String(String),
}

pub struct MyStruct {
    pub msg: String,
    pub data: MyEnum,
}
```

`DartDynamic` can be returned to Dart as an escape hatch for values that cannot
be modeled as fixed structs/enums.

Example:

```rust
use flutter_rust_bridge::{DartDynamic, IntoDart};

pub fn return_dynamic() -> DartDynamic {
    vec![
        ().into_dart(),
        0i32.into_dart(),
        "Hello there!".to_string().into_dart(),
    ]
    .into_dart()
}
```

Dart:

```dart
final dynamic values = await returnDynamic();
```

Rules:

- Prefer enums and typed structs over `DartDynamic`.
- Use `DartDynamic` only as an escape hatch.
- Do not use `DartDynamic` for secret-bearing or security-sensitive payloads.
- Do not use `DartDynamic` when stable validation or versioning matters.
- Remember that `DartDynamic` is for returning dynamic values; it is not a
  general parameter type.
- Structs that transitively include `DartDynamic` should not be used as input
  parameters.
- If Rust only needs to accept/return an opaque Dart object without inspecting
  it, prefer `DartOpaque`.

For Hoplixi, `DartDynamic` should almost never be used in crypto, vault, sync,
auth, or storage APIs. Use typed models and typed errors.

### Rust calls Dart callbacks

FRB can make Rust call Dart functions/closures. This is useful for callbacks,
progress hooks, event hooks, or custom Dart-side decisions.

Simple mental model:

```rust
pub async fn rust_function(dart_callback: impl Fn(String) -> DartFnFuture<String>) {
    let greeting = dart_callback("Tom".to_owned()).await;
    // greeting == "Hello, Tom!"
}
```

Dart:

```dart
await rustFunction(
  dartCallback: (name) => 'Hello, $name!',
);
```

Rules:

- Use callbacks only when Rust genuinely needs to call back into Dart.
- Prefer streams for progress/events when the data flow is one-way from Rust to
  Dart.
- Prefer request/response functions when Rust does not need interactive Dart
  decisions.
- Keep callbacks fast and predictable.
- Avoid callbacks that show UI directly from deep Rust workflows.
- Avoid re-entrant calls that can deadlock or fight locks.
- Do not hold Rust locks while awaiting a Dart callback.
- Map callback failures/cancellations into typed Rust/bridge errors.

Good callback uses:

- Asking Dart for a cancellation/decision hook in a controlled flow.
- Custom progress/event handling when streams are not suitable.
- Dart-provided transformation or validation that must remain on Dart side.

Bad callback uses:

- Replacing normal return values.
- Moving business orchestration into Rust.
- Calling Flutter UI/dialog APIs from low-level Rust callbacks.
- Deep callback chains that make lifecycle hard to reason about.

For Hoplixi, prefer Dart/Riverpod orchestration for prompts and user decisions.
Rust callbacks may be useful for controlled low-level hooks, but UI prompts
should not be triggered directly from Rust internals.

### Dart calls Rust

Dart calling Rust is the normal FRB direction.

Rust:

```rust
pub fn my_rust_function(a: String) -> String {
    a.repeat(2)
}
```

Dart:

```dart
final result = await myRustFunction(a: 'Hello');
```

Rules:

- Keep Dart-to-Rust calls behind app-level Dart adapters/services in large
  projects.
- Prefer typed request/response models for complex calls.
- Prefer async by default unless `#[frb(sync)]` is intentionally justified.
- Do not let widgets depend directly on low-level generated APIs.

