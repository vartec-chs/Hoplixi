# Rust Integration Strategy

This document outlines the strategy for integrating Rust into the Hoplixi
application using `flutter_rust_bridge` v2.x. It details the setup,
cross-platform requirements, and best practices for leveraging Rust's ecosystem
within a Flutter environment.

## Overview

> **STATUS**: ✅ **Integrated**. The `flutter_rust_bridge` library is fully
> configured and ready for use. You can immediately start implementing Rust
> functions in `rust/src/api/` and calling them from Dart.

We use **`flutter_rust_bridge`** (version ^2.11.1) to bridge Dart and Rust. This
allows us to execute high-performance code, use system-level APIs, and leverage
the vast Rust crate ecosystem while maintaining a smooth Flutter UI.

## Key Principles

### 1. Cross-Platform Compatibility (Strict Requirement)

Since Hoplixi targets **Android, iOS, macOS, Windows, and Linux**, all Rust code
and dependencies **MUST** be cross-platform.

- **Do NOT** use platform-specific crates (e.g., `winapi`, `cocoa`) unless they
  are behind `cfg` attributes and have equivalents for all other supported
  platforms.
- **Prefer** standard library solutions (`std::fs`, `std::path`, `std::thread`)
  or well-maintained cross-platform crates (e.g., `tokio`, `serde`, `anyhow`).
- **Verify** dependencies on crates.io to ensure they support all target tier-1
  platforms.

### 2. Architecture & Code Generation

- **`rust/` directory**: Contains the standard Cargo project.
- **`rust/src/api/`**: This is the interface definition folder. All Rust
  functions intended to be called from Dart must be defined here.
- **Code Generation**: `flutter_rust_bridge_codegen` automatically generates:
  - `rust/src/frb_generated.rs` (Rust binding glue)
  - `lib/src/rust/**` (Dart binding glue)

### 3. Asynchronous by Default

- Most interactions between Flutter and Rust should be asynchronous to avoid
  blocking the UI thread.
- Use `async fn` in Rust, which maps to `Future` in Dart.
- For synchronous operations (only for very fast tasks), use
  `#[flutter_rust_bridge::frb(sync)]`.

## Setup & Workflow

### 1. Adding a New Rust Function

1. Create or modify a file in `rust/src/api/` (e.g., `rust/src/api/crypto.rs`).
2. Define a public Rust function.
3. Run code generation (usually handled by the build script or manually via
   `flutter_rust_bridge_codegen generate`).

Example (`rust/src/api/crypto.rs`):

```rust
use anyhow::Result;

pub fn hash_password(password: String) -> Result<String> {
    // Platform-agnostic implementation
    Ok(some_hashing_function(password))
}
```

### 2. Using in Dart

The generated Dart code handles the FFI bridge transparently.

```dart
import 'package:hoplixi/src/rust/api/crypto.dart';

Future<void> main() async {
  try {
    final hash = await hashPassword(password: "secret");
    print("Hashed: $hash");
  } catch (e) {
    print("Error: $e");
  }
}
```

## Recommended Crates

Use these vetted, cross-platform crates for common tasks:

- **Serialization**: `serde` + `serde_json`
- **Async Runtime**: `tokio`
- **Error Handling**: `anyhow`, `thiserror` (mapped to Dart exceptions)
- **Cryptography**: `ring`, `aes-gcm` (pure Rust implementations preferred for
  portability)
- **HTTP Client**: `reqwest` (ensure OpenSSL/TLS compatibility on Android/iOS)
- **Key-Value Store**: `sled` (if SQLCipher/Drift is insufficient for specific
  needs)

## Build & deployment

- Ensure that the Rust toolchain is installed and up-to-date (`rustup update`).
- Android builds require the NDK and appropriate targets
  (`aarch64-linux-android`, `armv7-linux-androideabi`, etc.).
- iOS/macOS builds require Xcode and strict signing configurations.

## Troubleshooting

- **FFI Errors**: Ensure `RustLib.init()` is called in `main.dart` before using
  any Rust functions.
- **Linker Errors**: Check `Cargo.toml` for correct
  `crate-type = ["cdylib", "staticlib"]`.
