# Error Handling Guide — `result_dart: ^2.1.1` (Installed)

## Overview

This project uses the **`result_dart`** package to represent operation outcomes
explicitly instead of relying on thrown exceptions in the business layer. This
improves clarity of function contracts, simplifies testing, and enforces
predictable error propagation.

Key goals:

- Functions return an explicit result representing success or failure.
- Errors are first-class values and do not get lost in `try/catch` noise.
- Composable chains of operations short-circuit on failure.

---

## Important types and differences

`result_dart` exposes two main families of types. They differ by how many
generic parameters they accept.

### Full generic types (recommended when you want typed errors)

- `ResultDart<S, E>` — a result that carries a successful value of type `S` or a
  failure of type `E`.
- `AsyncResultDart<S, E>` — alias for `Future<ResultDart<S, E>>` used for async
  functions. Не нужно писать `Future<ResultDart<...>>` вручную, просто
  используйте `AsyncResultDart`.

These types should be used when you want explicit, typed error values (in this
project: `AppError`, for example `AppError.auth`, `AppError.validation`,
`AppError.network`).

### Short-hand types (single generic parameter)

- `Result<S>` — shorthand result type where only the success type `S` is
  declared; the failure type is the package default (commonly `Exception`).
- `AsyncResult<S>` — shorthand `Future<Result<S>>` for async operations where
  you don't need a custom error type.

Use the short forms when you don't need specialized error typing and prefer
brevity.

---

## Core operations

Common methods available on result values include (non-exhaustive):

- `map` — transform the success value (`S -> T`).
- `flatMap` — chain operations that themselves return `ResultDart`.
- `mapError` — transform the error value.
- `flatMapError` — chain on errors.
- `recover` — provide a fallback value on failure.
- `fold` — final branching: `(onSuccess, onFailure)`.
- `getOrElse` / `getOrNull` / `getOrThrow` — convenience accessors.

These operations let you compose flows without `try/catch` in the business
layer.

---

## Recommendations for agents and services

1. **Return `ResultDart` / `AsyncResultDart` from business-layer APIs.** Make
   success/failure explicit in the function signature.
2. **Prefer typed errors for domain logic.** In this project, default to
   `ResultDart<S, AppError>` / `AsyncResultDart<S, AppError>`.
3. **Leave `try/catch` to adapter layers** (network, platform interop) that
   convert exceptions to `Failure(AppError...)`.
4. **UI and state layers should use `fold`** or mapping helpers to convert
   results into `LoadedState` / `ErrorState` values.
5. **Centralize error enrichment and logging.** Use `mapError` in a single place
   to produce user-facing errors.
6. **Avoid `throw` inside business logic.** Convert thrown exceptions at the
   boundary to `Failure(AppError...)`.

---

## Examples (copy-paste ready)

### 1) Synchronous example — CPF validation using `ResultDart`

```dart
import 'dart:io';
import 'package:result_dart/result_dart.dart';

void main() {
  final result = getTerminalInput()
      .map(removeNonDigits) // String -> String
      .flatMap(parseDigits)  // String -> ResultDart<List<int>, ValidatorException>
      .map(validateCPF);    // List<int> -> bool

  print('CPF valid: ${result.isSuccess()}');
}

ResultDart<String, ValidatorException> getTerminalInput() {
  final text = stdin.readLineSync();
  if (text == null || text.isEmpty) {
    return Failure(ValidatorException('Incorrect input'));
  }
  return Success(text);
}

String removeNonDigits(String input) => input.replaceAll(RegExp(r'\D'), '');

ResultDart<List<int>, ValidatorException> parseDigits(String input) {
  if (input.isEmpty) return Failure(ValidatorException('Input is empty'));
  try {
    final list = input.split('').map(int.parse).toList();
    return Success(list);
  } catch (_) {
    return Failure(ValidatorException('Parse error'));
  }
}

bool validateCPF(List<int> digits) {
  // Simplified validation example — replace with domain rules.
  return digits.length == 11;
}

class ValidatorException implements Exception {
  final String message;
  const ValidatorException(this.message);
  @override String toString() => 'ValidatorException: $message';
}
```

> Notes:
>
> - This example uses `ResultDart<S, E>` so the error type is explicit
>   (`ValidatorException`).
> - If you prefer brevity and do not need a typed error, you could use
>   `Result<String>` and `Result<List<int>>`.

---

### 2) Asynchronous example — fetching products using `AsyncResultDart`

```dart
import 'package:dio/dio.dart';
import 'package:result_dart/result_dart.dart';

class Product {}

class ProductException implements Exception {
  final String message;
  ProductException(this.message);
  @override String toString() => 'ProductException: $message';
}

AsyncResultDart<List<Product>, ProductException> fetchProducts() async {
  try {
    final response = await Dio().get('/products');
    final products = Product.fromList(response.data); // implement this
    return Success(products);
  } on DioError catch (e) {
    return Failure(ProductException(e.message ?? 'Network error'));
  } catch (e) {
    return Failure(ProductException(e.toString()));
  }
}

Future<dynamic> loadProductsToState() async {
  final result = await fetchProducts();
  return result.fold(
    (products) => LoadedState(products),
    (failure) => ErrorState(failure),
  );
}
```

---

## Choosing which type to use

- Use `ResultDart<S, E>` / `AsyncResultDart<S, E>` when you want **explicit,
  typed** failure values that your code can pattern-match on.
- Use `Result<S>` / `AsyncResult<S>` when you prefer **concise signatures** and
  an unspecified/default error type is acceptable.

Common pattern: adapters convert raw exceptions into `AppError`; domain logic
exposes those error values via `ResultDart`.

---

## Useful patterns

- **Sequential composition (short-circuiting):**

```dart
final r = stepA()
    .flatMap((a) => stepB(a))
    .flatMap((b) => stepC(b));
```

- **Map errors to UI-friendly errors:**

```dart
final readable = result.mapError((e) => UiError.from(e));
```

- **Convert result to state:**

```dart
final state = await fetch().then((r) => r.fold((s) => LoadedState(s), (f) => ErrorState(f)));
```

---

## When to adopt `result_dart`

Adopt `result_dart` when you want:

- Clear, typed function contracts
- Predictable error propagation across layers
- Better unit-testability of failure cases
- To follow layered/clean architecture practices

---

## Links

- Package:
  [https://pub.dev/packages/result_dart](https://pub.dev/packages/result_dart)

---

**Guideline:** Avoid throwing from business logic; always return `Success(...)`
or `Failure(AppError...)`. This keeps control flow explicit and simplifies agent
behaviour when composing steps.

## Project error model (`AppError`)

Use the existing shared error model in `lib/core/errors/app_error.dart`. Prefer
`AppError` variants over introducing ad-hoc custom error classes.

`AppError.feature(...)` is intended for local errors that belong to a specific
feature and do not justify a new global domain in `AppError`. Use it when the
error:

- belongs to one or two related features only;
- should still reach UI, logs, snackbar/dialog flows, and JSON serialization in
  one consistent format;
- does not need a dedicated top-level `AppError` branch.

Keep the same typed-result flow for these errors as for the rest of the shared
error model.

```dart
ResultDart<User, AppError> validateInput(String username) {
  if (username.trim().isEmpty) {
    return Failure(
      AppError.validation(
        code: ValidationErrorCode.unknown,
        message: 'Username is required',
      ),
    );
  }

  return Success(User(username: username));
}

AsyncResultDart<FileData, AppError> loadFile(String path) async {
  try {
    final bytes = await readBytes(path);
    return Success(FileData(bytes));
  } catch (e, st) {
    return Failure(
      AppError.fileSystem(
        code: FileSystemErrorCode.unknown,
        message: 'Failed to read file',
        cause: e,
        stackTrace: st,
      ),
    );
  }
}
```
