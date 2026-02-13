import 'dart:isolate';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Derived key pair containing separate keys for encryption and authentication.
///
/// Using separate keys for AEAD and HMAC prevents potential cryptographic
/// weaknesses from key reuse across different primitives.
class DerivedKeyPair {
  /// Key for AEAD encryption (XChaCha20-Poly1305).
  final SecretKey encryptionKey;

  /// Key for HMAC authentication.
  final SecretKey hmacKey;

  /// Salt used for key derivation.
  final Uint8List salt;

  DerivedKeyPair({
    required this.encryptionKey,
    required this.hmacKey,
    required this.salt,
  });

  /// Securely clears the keys from memory.
  ///
  /// Note: In Dart, memory clearing is not guaranteed due to GC,
  /// but this provides best-effort cleanup.
  void destroy() {
    // SecretKey doesn't expose bytes for clearing,
    // but we document the intent for future implementations.
  }
}

/// Service for generating encryption keys using Argon2id.
///
/// Provides production-ready key derivation from passwords with secure defaults.
/// Derives separate keys for AEAD encryption and HMAC authentication to prevent
/// potential cryptographic weaknesses from key reuse.
abstract final class KeyDerivationService {
  /// Default salt length in bytes.
  static const int defaultSaltLength = 16;

  /// Key length in bytes (256 bits for XChaCha20-Poly1305).
  static const int keyLength = 32;

  /// Total derived key material length (encryption key + HMAC key).
  static const int totalKeyLength = 64;

  /// OWASP recommended minimum memory for Argon2id (19 MiB).
  static const int defaultMemory = 19 * 1024;

  /// Default parallelism (number of CPU cores to use).
  static const int defaultParallelism = 1;

  /// Default iterations (OWASP recommends 2 with 19 MiB memory).
  static const int defaultIterations = 2;

  /// Derives a key pair (encryption key + HMAC key) from a password.
  ///
  /// This is the recommended method for file encryption as it provides
  /// separate keys for AEAD and HMAC, preventing potential cryptographic
  /// weaknesses from key reuse.
  ///
  /// The expensive Argon2id calculation is performed in a separate Isolate
  /// to prevent blocking the main thread (UI freeze).
  ///
  /// Parameters:
  /// - [password]: The user's password.
  /// - [salt]: A unique salt. If null, a new random salt will be generated.
  /// - [memory]: Memory cost in KiB (default: 19456 KiB = 19 MiB).
  /// - [parallelism]: Degree of parallelism (default: 1).
  /// - [iterations]: Number of iterations (default: 2).
  ///
  /// Returns a [DerivedKeyPair] containing separate encryption and HMAC keys.
  static Future<DerivedKeyPair> deriveKeyPair({
    required String password,
    Uint8List? salt,
    int memory = defaultMemory,
    int parallelism = defaultParallelism,
    int iterations = defaultIterations,
  }) async {
    if (password.isEmpty) {
      throw ArgumentError.value(
        password,
        'password',
        'Password cannot be empty',
      );
    }

    // Generate random salt if not provided (must be done on main isolate for secure random)
    final effectiveSalt = salt ?? generateSecureRandomBytes(defaultSaltLength);

    // Offload heavy calculation to an Isolate
    final keyBytes = await Isolate.run(() async {
      final algorithm = Argon2id(
        memory: memory,
        parallelism: parallelism,
        iterations: iterations,
        hashLength: totalKeyLength, // 64 bytes: 32 for encryption + 32 for HMAC
      );

      final masterKey = await algorithm.deriveKeyFromPassword(
        password: password,
        nonce: effectiveSalt,
      );

      return await masterKey.extractBytes();
    });

    // Split: first 32 bytes for encryption, last 32 bytes for HMAC
    final encKeyBytes = Uint8List.fromList(keyBytes.sublist(0, keyLength));
    final hmacKeyBytes = Uint8List.fromList(
      keyBytes.sublist(keyLength, totalKeyLength),
    );

    return DerivedKeyPair(
      encryptionKey: SecretKey(encKeyBytes),
      hmacKey: SecretKey(hmacKeyBytes),
      salt: Uint8List.fromList(effectiveSalt),
    );
  }

  /// Derives a key pair from a password with a known salt.
  ///
  /// Use this for decryption when you have the salt from the encrypted file.
  static Future<DerivedKeyPair> deriveKeyPairWithSalt({
    required String password,
    required Uint8List salt,
    int memory = defaultMemory,
    int parallelism = defaultParallelism,
    int iterations = defaultIterations,
  }) async {
    if (salt.isEmpty) {
      throw ArgumentError.value(salt, 'salt', 'Salt cannot be empty');
    }
    return deriveKeyPair(
      password: password,
      salt: salt,
      memory: memory,
      parallelism: parallelism,
      iterations: iterations,
    );
  }

  /// Generates a cryptographic key from a password using Argon2id.
  ///
  /// This method derives a 256-bit key suitable for XChaCha20-Poly1305 encryption.
  ///
  /// @deprecated Use [deriveKeyPair] instead for separate encryption and HMAC keys.
  ///
  /// Parameters:
  /// - [password]: The user's password.
  /// - [salt]: A unique salt. Should be randomly generated and stored with the encrypted data.
  ///   If null, a new random salt will be generated.
  /// - [memory]: Memory cost in KiB (default: 19456 KiB = 19 MiB).
  /// - [parallelism]: Degree of parallelism (default: 1).
  /// - [iterations]: Number of iterations (default: 2).
  ///
  /// Returns a tuple of (derived key bytes, salt used).
  ///
  /// Example:
  /// ```dart
  /// final (keyBytes, salt) = await KeyDerivationService.deriveKey(
  ///   password: 'user-password',
  /// );
  /// // Store salt alongside encrypted data for decryption
  /// ```
  @Deprecated('Use deriveKeyPair instead for separate encryption and HMAC keys')
  static Future<(Uint8List keyBytes, Uint8List salt)> deriveKey({
    required String password,
    Uint8List? salt,
    int memory = defaultMemory,
    int parallelism = defaultParallelism,
    int iterations = defaultIterations,
  }) async {
    if (password.isEmpty) {
      throw ArgumentError.value(
        password,
        'password',
        'Password cannot be empty',
      );
    }

    // Generate random salt if not provided
    final effectiveSalt = salt ?? generateSecureRandomBytes(defaultSaltLength);

    final algorithm = Argon2id(
      memory: memory,
      parallelism: parallelism,
      iterations: iterations,
      hashLength: keyLength,
    );

    final secretKey = await algorithm.deriveKeyFromPassword(
      password: password,
      nonce: effectiveSalt,
    );

    final keyBytes = await secretKey.extractBytes();
    return (Uint8List.fromList(keyBytes), Uint8List.fromList(effectiveSalt));
  }

  /// Generates a SecretKey object from a password for direct use with encryption.
  ///
  /// @deprecated Use [deriveKeyPairWithSalt] instead for separate encryption and HMAC keys.
  ///
  /// Parameters:
  /// - [password]: The user's password.
  /// - [salt]: The salt used during key derivation.
  /// - [memory]: Memory cost in KiB.
  /// - [parallelism]: Degree of parallelism.
  /// - [iterations]: Number of iterations.
  ///
  /// Returns a [SecretKey] ready for encryption operations.
  static Future<SecretKey> deriveSecretKey({
    required String password,
    required Uint8List salt,
    int memory = defaultMemory,
    int parallelism = defaultParallelism,
    int iterations = defaultIterations,
  }) async {
    if (password.isEmpty) {
      throw ArgumentError.value(
        password,
        'password',
        'Password cannot be empty',
      );
    }

    if (salt.isEmpty) {
      throw ArgumentError.value(salt, 'salt', 'Salt cannot be empty');
    }

    final algorithm = Argon2id(
      memory: memory,
      parallelism: parallelism,
      iterations: iterations,
      hashLength: keyLength,
    );

    return algorithm.deriveKeyFromPassword(password: password, nonce: salt);
  }

  /// Creates a SecretKey from raw key bytes.
  ///
  /// Use this when you have already derived key bytes and need a SecretKey object.
  static SecretKey createSecretKeyFromBytes(Uint8List keyBytes) {
    if (keyBytes.length != keyLength) {
      throw ArgumentError.value(
        keyBytes.length,
        'keyBytes',
        'Key must be $keyLength bytes, got ${keyBytes.length}',
      );
    }
    return SecretKey(keyBytes);
  }

  /// Generates cryptographically secure random bytes.
  ///
  /// Uses the platform's secure random number generator.
  static Uint8List generateSecureRandomBytes(int length) {
    if (length <= 0) {
      throw ArgumentError.value(length, 'length', 'Length must be positive');
    }
    final random = SecureRandom.fast;
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return bytes;
  }

  /// Validates key derivation parameters.
  ///
  /// Returns a list of validation errors, empty if all parameters are valid.
  static List<String> validateParameters({
    required int memory,
    required int parallelism,
    required int iterations,
  }) {
    final errors = <String>[];

    if (memory < 8) {
      errors.add('Memory must be at least 8 KiB');
    }

    if (parallelism < 1) {
      errors.add('Parallelism must be at least 1');
    }

    if (iterations < 1) {
      errors.add('Iterations must be at least 1');
    }

    // OWASP recommendation check (warning, not error)
    if (memory < defaultMemory && iterations < 3) {
      errors.add(
        'Warning: For security, use at least 19 MiB memory or increase iterations',
      );
    }

    return errors;
  }
}
