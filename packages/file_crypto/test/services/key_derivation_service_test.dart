import 'package:file_crypto/services/key_derivation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('KeyDerivationService', () {
    test('deriveKeyPair generates keys with default parameters', () async {
      final keyPair = await KeyDerivationService.deriveKeyPair(
        password: 'test-password',
      );

      expect(keyPair.salt, isNotNull);
      expect(
        keyPair.salt.length,
        equals(KeyDerivationService.defaultSaltLength),
      );
      expect(keyPair.encryptionKey, isNotNull);
      expect(keyPair.hmacKey, isNotNull);
    });

    test('deriveKeyPair produces consistent keys with same salt', () async {
      final password = 'consistent-password';
      final salt = KeyDerivationService.generateSecureRandomBytes(16);

      final keyPair1 = await KeyDerivationService.deriveKeyPair(
        password: password,
        salt: salt,
      );

      final keyPair2 = await KeyDerivationService.deriveKeyPair(
        password: password,
        salt: salt,
      );

      final key1Bytes = await keyPair1.encryptionKey.extractBytes();
      final key2Bytes = await keyPair2.encryptionKey.extractBytes();

      final hmac1Bytes = await keyPair1.hmacKey.extractBytes();
      final hmac2Bytes = await keyPair2.hmacKey.extractBytes();

      expect(key1Bytes, equals(key2Bytes));
      expect(hmac1Bytes, equals(hmac2Bytes));
      expect(keyPair1.salt, equals(keyPair2.salt));
    });

    test('deriveKeyPair throws on empty password', () async {
      expect(
        () => KeyDerivationService.deriveKeyPair(password: ''),
        throwsArgumentError,
      );
    });

    test('validateParameters accepts valid parameters', () async {
      KeyDerivationService.validateParameters(
        memory: 19 * 1024,
        parallelism: 1,
        iterations: 2,
      );
      // Should not throw
    });

    test('validateParameters returns errors on invalid parameters', () {
      var errors = KeyDerivationService.validateParameters(
        memory: 0,
        parallelism: 1,
        iterations: 1,
      );
      expect(errors, isNotEmpty);
      expect(errors.any((e) => e.contains('Memory')), isTrue);

      errors = KeyDerivationService.validateParameters(
        memory: 19 * 1024,
        parallelism: 0,
        iterations: 1,
      );
      expect(errors, isNotEmpty);
      expect(errors.any((e) => e.contains('Parallelism')), isTrue);

      errors = KeyDerivationService.validateParameters(
        memory: 19 * 1024,
        parallelism: 1,
        iterations: 0,
      );
      expect(errors, isNotEmpty);
      expect(errors.any((e) => e.contains('Iterations')), isTrue);
    });

    test('generateSecureRandomBytes returns correct length', () {
      final bytes = KeyDerivationService.generateSecureRandomBytes(32);
      expect(bytes.length, equals(32));

      final bytes2 = KeyDerivationService.generateSecureRandomBytes(32);
      expect(bytes, isNot(equals(bytes2))); // Extremely unlikely to be equal
    });
  });
}
