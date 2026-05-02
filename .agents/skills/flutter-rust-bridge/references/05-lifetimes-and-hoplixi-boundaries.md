## Lifetimes and returned borrowed data

FRB can support returning types with Rust lifetimes, but this is an experimental
area and should be used carefully.

Enable it only when the project intentionally needs it:

```yaml
# flutter_rust_bridge.yaml
enable_lifetime: true
```

Rules:

- Treat lifetime support as experimental and potentially less stable than the
  rest of FRB.
- Prefer simpler ownership models when possible: owned values, `Arc`,
  `RustAutoOpaque<T>`, or cloned lightweight data.
- Use lifetime-returning APIs only when they significantly improve correctness
  or performance.
- Avoid exposing lifetime-heavy internals to normal Dart UI/service layers.
- Document lifecycle and borrowing expectations near the Rust API.

### Explicit lifetime syntax

FRB currently expects explicit lifetime syntax for returned types with
lifetimes.

Prefer explicit code like:

```rust
#[frb(opaque)]
pub struct Foo(String);

#[frb(opaque)]
pub struct Bar<'a> {
    foo: &'a Foo,
}

impl Foo {
    pub fn compute_bar<'a>(&'a self) -> Bar<'a> {
        Bar { foo: self }
    }
}

impl Bar<'_> {
    pub fn greet(&self) -> String {
        format!("Hello from {}", self.foo.0)
    }
}
```

Dart usage sketch:

```dart
final foo = Foo('value');
final bar = foo.computeBar();
final greeting = bar.greet();
```

Syntax rules:

- Specify lifetimes explicitly.
- Prefer a single named lifetime such as `'a` in exposed APIs.
- Avoid fancy lifetime elision in bridge-facing code.
- Keep lifetime-bearing public APIs small and easy to reason about.

Example transformation:

```rust
// Avoid in bridge-facing lifetime-returning APIs.
pub fn f(foo: &Foo) -> Bar { ... }

// Prefer explicit syntax.
pub fn f<'a>(foo: &'a Foo) -> Bar<'a> { ... }
```

### Dart object lifetime safety

When FRB returns a lifetime-bearing opaque object, Dart usually does not need to
keep the parent object manually alive. The returned object internally ensures
the Rust parent object remains valid long enough.

Rules:

- Do not add artificial Dart-side global references just to keep the parent
  alive unless the project has proven it is needed.
- Still dispose returned borrowed/derived objects manually when their borrow
  should end before the Dart GC runs.
- Be explicit when a later mutable borrow depends on disposing an earlier
  borrowed object.

### Returning references

Returning raw references such as `&'a Bar` is not the preferred exposed shape
and may not be supported directly in all scenarios.

Use a small wrapper struct instead:

```rust
pub struct BarReference<'a>(&'a Bar);

pub fn get_bar<'a>(foo: &'a Foo) -> BarReference<'a> {
    // ...
    todo!()
}
```

Rules:

- Prefer wrapper structs for returned references.
- Give wrappers meaningful names, not generic names like `Ref1`.
- Add methods on the wrapper when Dart needs behavior.
- Avoid making Dart understand a complex borrow graph.

### Runtime borrow conflicts in Dart

Rust prevents invalid borrow combinations at compile time. Dart cannot perform
the same static borrow analysis, so some borrow conflicts can become runtime
errors or waits.

Rust mental model:

```rust
let mut foo = Foo::new();
let bar = f(&foo);

// Cannot mutably borrow foo while bar still borrows it.
// function_that_mutably_borrow_foo(&mut foo);

drop(bar);
function_that_mutably_borrow_foo(&mut foo);
```

Equivalent Dart pattern:

```dart
final foo = Foo();
final bar = f(foo);

// Do not mutably borrow foo while bar is still alive.
// functionThatMutablyBorrowFoo(foo);

bar.dispose();
functionThatMutablyBorrowFoo(foo);
```

Rules:

- If you need to mutably borrow a parent object, dispose active borrowed
  child/reference objects first.
- Do not rely on Dart GC when the timing of ending a borrow matters.
- Prefer explicit `dispose()` in workflows with mutable follow-up operations.
- Keep borrowed objects scoped as tightly as possible.
- Avoid storing borrowed lifetime-bearing objects in long-lived Riverpod state
  unless the lifecycle is deliberately designed.

### Alternatives to lifetime-heavy bridge APIs

Before using lifetime support, consider simpler alternatives.

#### Proxy methods

Use methods on the owning opaque object instead of returning borrowed internals.

Prefer:

```rust
impl VaultSession {
    pub fn current_entry_title(&self, id: String) -> Result<String, VaultError> {
        // Access internal borrowed data inside Rust.
        todo!()
    }
}
```

Instead of returning a borrowed internal entry reference to Dart when Dart only
needs one field.

#### Shared ownership

Use shared ownership when a returned object should outlive the immediate borrow
scope.

```rust
use std::sync::Arc;

pub struct MyStruct {
    pub field: Arc<Another>,
}
```

For opaque fields exposed through FRB, consider:

```rust
use flutter_rust_bridge::RustAutoOpaque;

pub struct MyStruct {
    pub field: RustAutoOpaque<Another>,
}
```

#### Clone lightweight data

Clone when the cloned data is small and semantically a value.

Good clone candidates:

- Small strings.
- IDs.
- Metadata.
- Small DTOs.
- Configuration snapshots.

Bad clone candidates:

- Large buffers.
- Decrypted file contents.
- Secret keys.
- Native handles.
- Large index/cache/session state.

### Hoplixi lifetime rules

For Hoplixi, lifetime support should be rare.

Prefer:

- Owned request/response DTOs for vault metadata.
- `RustAutoOpaque<T>` for native session/handle/state objects.
- Streaming APIs for large files.
- Explicit methods on opaque session objects instead of returning borrowed
  internals.
- Cloned small metadata values when Dart only needs display/filtering data.

Avoid:

- Exposing borrowed references to decrypted secrets.
- Storing borrowed views into vault internals in Flutter/Riverpod state.
- Returning lifetime-bearing references from crypto/key-management APIs unless
  there is a very strong reason.
- Depending on Dart GC to release security-sensitive borrows.

## Opaque-object patterns for Hoplixi

Good opaque candidates in Hoplixi:

- Streaming file encryptor/decryptor.
- Native hashing/KDF session if it has internal state.
- Large parser/indexer state.
- Native file reader/writer handle.
- Temporary secure workspace handle.

Bad opaque candidates:

- Simple DTOs like `StoreInfoDto`.
- Small configuration objects.
- Error objects.
- Values that Flutter UI needs to freely display/copy/filter.

Security rules:

- Do not expose sensitive fields through generated accessors.
- Provide explicit `close`, `clear`, or `dispose` lifecycle for secret-owning
  objects.
- Avoid `Debug` output that includes sensitive internals.
- Keep opaque objects scoped to the feature/service that owns them.
- Do not store one global opaque object for the current vault unless lifecycle,
  locking, and multi-store behavior are fully designed.

