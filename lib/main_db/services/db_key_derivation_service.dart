import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hoplixi/core/logger/app_logger.dart';

/// Сервис деривации ключей для шифрования SQLite3 Multiple Ciphers базы данных.
///
/// Реализует версионированные схемы получения ключа:
///
/// ```
/// v1: legacy Argon2id(password) -> chained HKDF factors
/// v2: Argon2id(password) + factors -> HKDF-Extract -> HKDF-Expand(context)
/// ```
///
/// Полученный ключ передаётся в SQLite3 Multiple Ciphers через:
/// ```dart
/// rawDb.execute("PRAGMA key = \"x'<hexKey>'\";");
/// ```
///
/// ### Важно: salt хранится снаружи зашифрованной БД
///
/// Argon2-соль необходима для открытия БД, поэтому она сохраняется
/// в `store_manifest.json` (поле `keyConfig`, модель [StoreKeyConfig])
/// рядом с файлом `.db`.
/// Это стандартная практика для зашифрованных баз данных.
class DbKeyDerivationService {
  static const String _logTag = 'DbKeyDerivationService';

  // --- Параметры Argon2id ---
  /// Память: 2^16 = 65 536 KiB (≈ 64 МБ)
  static const int argon2Memory = 1 << 16;
  static const int argon2Iterations = 3;
  static const int argon2Parallelism = 1;
  static const int _keyLength = 32; // 256 бит
  static const int saltLength = 32; // 256 бит
  static const int legacyKdfVersion = 1;
  static const int currentKdfVersion = 2;

  // --- Хранилище ключа устройства ---
  static const String _deviceKeyStorageKey = 'hoplixi_db_device_secret_v1';
  static const int _deviceSecretLength = 32; // 256 бит

  // --- Info-строка для HKDF (контекст деривации) ---
  static const String _hkdfInfo = 'hoplixi-SQLite3 Multiple Ciphers-v1';
  static const String _keyFileHkdfInfo =
      'hoplixi-SQLite3 Multiple Ciphers-key-file-v1';
  static const String dbKeyContext = 'db';
  static const String filesKeyContext = 'files';
  static const String macKeyContext = 'mac';

  final FlutterSecureStorage _secureStorage;

  DbKeyDerivationService(this._secureStorage);

  // ─────────────────────────────────────────────────────────────────────────
  // Публичный API
  // ─────────────────────────────────────────────────────────────────────────

  /// Вычислить ключ шифрования для SQLite3 Multiple Ciphers PRAGMA.
  ///
  /// [password]     — мастер-пароль пользователя
  /// [salt]         — Argon2-соль (base64), уникальная для каждого хранилища.
  ///                  Хранится в `store_manifest.json` внутри [StoreKeyConfig].
  /// [useDeviceKey] — привязать ключ к устройству через HKDF.
  ///
  /// Возвращает строку в формате `x'<64-символьный hex>'`,
  /// готовую для подстановки в `PRAGMA key = "...";`
  Future<String> derivePragmaKey(
    String password,
    String salt, {
    bool useDeviceKey = false,
    Uint8List? keyFileSecret,
    int kdfVersion = currentKdfVersion,
  }) async {
    logInfo(
      'Deriving SQLite3 Multiple Ciphers PRAGMA key '
      '(kdfVersion=$kdfVersion, useDeviceKey=$useDeviceKey, '
      'useKeyFile=${keyFileSecret != null})',
      tag: _logTag,
    );

    final Uint8List finalKey;
    if (kdfVersion == legacyKdfVersion) {
      finalKey = await _deriveLegacyFinalKey(
        password: password,
        salt: salt,
        useDeviceKey: useDeviceKey,
        keyFileSecret: keyFileSecret,
      );
    } else if (kdfVersion == currentKdfVersion) {
      finalKey = await _deriveV2ContextKey(
        password: password,
        salt: salt,
        useDeviceKey: useDeviceKey,
        keyFileSecret: keyFileSecret,
        context: dbKeyContext,
      );
    } else {
      throw ArgumentError.value(
        kdfVersion,
        'kdfVersion',
        'Unsupported KDF version',
      );
    }

    final pragmaKey = "x'${_bytesToHex(finalKey)}'";
    logInfo('PRAGMA key derived successfully', tag: _logTag);
    return pragmaKey;
  }

  Future<Uint8List> deriveRootKey({
    required String password,
    required Uint8List vaultSalt,
    Uint8List? deviceSecret,
    Uint8List? keyFileSecret,
  }) async {
    _validateVaultSalt(vaultSalt);
    _validateOptionalSecret(deviceSecret, 'deviceSecret', exactLength: 32);
    _validateOptionalSecret(
      keyFileSecret,
      'keyFileSecret',
      minLength: 32,
      maxLength: 64,
    );

    final passwordKey = await _argon2DeriveBytes(password, vaultSalt);
    final ikm = _concat([
      passwordKey,
      ?deviceSecret,
      ?keyFileSecret,
    ]);

    return _hkdfExtract(salt: vaultSalt, ikm: ikm);
  }

  Future<Uint8List> deriveKey({
    required Uint8List rootKey,
    required String context,
    int length = _keyLength,
  }) async {
    if (rootKey.isEmpty) {
      throw ArgumentError.value(rootKey, 'rootKey', 'Root key is empty');
    }
    final normalizedContext = context.trim();
    if (normalizedContext.isEmpty) {
      throw ArgumentError.value(context, 'context', 'Context is empty');
    }
    if (length <= 0 || length > 255 * _keyLength) {
      throw ArgumentError.value(length, 'length', 'Invalid HKDF output length');
    }

    return _hkdfExpand(
      prk: rootKey,
      info: utf8.encode('hoplixi/$normalizedContext-key/v1'),
      length: length,
    );
  }

  Future<VaultDerivedKeys> deriveVaultKeys({
    required String password,
    required Uint8List vaultSalt,
    Uint8List? deviceSecret,
    Uint8List? keyFileSecret,
  }) async {
    final rootKey = await deriveRootKey(
      password: password,
      vaultSalt: vaultSalt,
      deviceSecret: deviceSecret,
      keyFileSecret: keyFileSecret,
    );

    return VaultDerivedKeys(
      dbKey: await deriveKey(rootKey: rootKey, context: dbKeyContext),
      fileKey: await deriveKey(rootKey: rootKey, context: filesKeyContext),
      macKey: await deriveKey(rootKey: rootKey, context: macKeyContext),
    );
  }

  Future<Uint8List> _deriveLegacyFinalKey({
    required String password,
    required String salt,
    required bool useDeviceKey,
    Uint8List? keyFileSecret,
  }) async {
    final masterKey = await _argon2Derive(password, salt);

    var finalKey = useDeviceKey
        ? await _hkdfDerive(masterKey, await _getOrCreateDeviceSecret())
        : masterKey;

    if (keyFileSecret != null) {
      finalKey = await _hkdfDerive(
        finalKey,
        keyFileSecret,
        info: _keyFileHkdfInfo,
      );
    }

    return finalKey;
  }

  Future<Uint8List> _deriveV2ContextKey({
    required String password,
    required String salt,
    required bool useDeviceKey,
    Uint8List? keyFileSecret,
    required String context,
  }) async {
    final vaultSalt = _decodeSalt(salt);
    final rootKey = await deriveRootKey(
      password: password,
      vaultSalt: vaultSalt,
      deviceSecret: useDeviceKey ? await _getOrCreateDeviceSecret() : null,
      keyFileSecret: keyFileSecret,
    );
    return deriveKey(rootKey: rootKey, context: context);
  }

  /// Получить или сгенерировать секрет устройства из защищённого хранилища.
  ///
  /// Секрет создаётся один раз при первом вызове и сохраняется в
  /// [FlutterSecureStorage] (Keychain / Keystore).
  Future<Uint8List> getOrCreateDeviceSecret() => _getOrCreateDeviceSecret();

  /// Проверить, существует ли секрет устройства в защищённом хранилище.
  Future<bool> hasDeviceSecret() async {
    final value = await _secureStorage.read(key: _deviceKeyStorageKey);
    return value != null;
  }

  /// Удалить секрет устройства из защищённого хранилища.
  ///
  /// ⚠️ После удаления все БД, открытые с [useDeviceKey]=true,
  /// станут недоступны без восстановления секрета!
  Future<void> deleteDeviceSecret() async {
    await _secureStorage.delete(key: _deviceKeyStorageKey);
    logInfo('Device secret deleted from secure storage', tag: _logTag);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Статические утилиты
  // ─────────────────────────────────────────────────────────────────────────

  /// Генерация новой Argon2-соли в виде Base64-строки.
  static String generateSalt() {
    return base64UrlEncode(generateSecureRandomBytes(saltLength));
  }

  /// Генерация криптографически безопасных случайных байт.
  static Uint8List generateSecureRandomBytes(int count) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(count, (_) => random.nextInt(256)),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Приватные методы
  // ─────────────────────────────────────────────────────────────────────────

  /// Argon2id деривация ключа.
  ///
  /// Вычисление выполняется в отдельном Isolate, чтобы не блокировать UI.
  Future<Uint8List> _argon2Derive(String password, String salt) async {
    return _argon2DeriveBytes(password, _decodeSalt(salt));
  }

  Future<Uint8List> _argon2DeriveBytes(
    String password,
    Uint8List saltBytes,
  ) async {
    final passwordBytes = utf8.encode(password);

    final keyBytes = await Isolate.run(() async {
      final argon2 = Argon2id(
        memory: argon2Memory,
        iterations: argon2Iterations,
        parallelism: argon2Parallelism,
        hashLength: _keyLength,
      );
      final secretKey = await argon2.deriveKey(
        secretKey: SecretKey(passwordBytes),
        nonce: saltBytes,
      );
      return Uint8List.fromList(await secretKey.extractBytes());
    });

    return keyBytes;
  }

  /// HKDF-SHA256 деривация финального ключа.
  ///
  /// masterKey → IKM (input key material)
  /// deviceSecret → HKDF salt (привязка к устройству)
  /// [_hkdfInfo] → контекст деривации
  Future<Uint8List> _hkdfDerive(
    Uint8List masterKey,
    Uint8List secret, {
    String info = _hkdfInfo,
  }) async {
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: _keyLength);

    final derived = await hkdf.deriveKey(
      secretKey: SecretKey(masterKey),
      nonce: secret,
      info: utf8.encode(info),
    );

    return Uint8List.fromList(await derived.extractBytes());
  }

  static Uint8List _decodeSalt(String salt) {
    return Uint8List.fromList(
      base64Decode(
        base64.normalize(salt.replaceAll('-', '+').replaceAll('_', '/')),
      ),
    );
  }

  static Uint8List _hkdfExtract({
    required Uint8List salt,
    required Uint8List ikm,
  }) {
    final hmac = crypto.Hmac(crypto.sha256, salt);
    return Uint8List.fromList(hmac.convert(ikm).bytes);
  }

  static Uint8List _hkdfExpand({
    required Uint8List prk,
    required List<int> info,
    required int length,
  }) {
    final output = <int>[];
    var previous = <int>[];
    var counter = 1;

    while (output.length < length) {
      final hmac = crypto.Hmac(crypto.sha256, prk);
      final input = <int>[...previous, ...info, counter];
      previous = hmac.convert(input).bytes;
      output.addAll(previous);
      counter++;
    }

    return Uint8List.fromList(output.take(length).toList(growable: false));
  }

  static Uint8List _concat(List<Uint8List> parts) {
    final length = parts.fold<int>(0, (sum, part) => sum + part.length);
    final result = Uint8List(length);
    var offset = 0;
    for (final part in parts) {
      result.setRange(offset, offset + part.length, part);
      offset += part.length;
    }
    return result;
  }

  static void _validateVaultSalt(Uint8List vaultSalt) {
    if (vaultSalt.length < 16) {
      throw ArgumentError.value(
        vaultSalt.length,
        'vaultSalt',
        'Vault salt must be at least 16 bytes',
      );
    }
  }

  static void _validateOptionalSecret(
    Uint8List? secret,
    String name, {
    int? exactLength,
    int? minLength,
    int? maxLength,
  }) {
    if (secret == null) {
      return;
    }
    if (exactLength != null && secret.length != exactLength) {
      throw ArgumentError.value(
        secret.length,
        name,
        '$name must be $exactLength bytes',
      );
    }
    if (minLength != null && secret.length < minLength) {
      throw ArgumentError.value(
        secret.length,
        name,
        '$name must be at least $minLength bytes',
      );
    }
    if (maxLength != null && secret.length > maxLength) {
      throw ArgumentError.value(
        secret.length,
        name,
        '$name must be at most $maxLength bytes',
      );
    }
  }

  /// Получить или создать секрет устройства.
  Future<Uint8List> _getOrCreateDeviceSecret() async {
    final stored = await _secureStorage.read(key: _deviceKeyStorageKey);

    if (stored != null) {
      logInfo('Using existing device secret from secure storage', tag: _logTag);
      return Uint8List.fromList(base64Decode(stored));
    }

    logInfo('Generating new device secret', tag: _logTag);
    final secret = generateSecureRandomBytes(_deviceSecretLength);
    await _secureStorage.write(
      key: _deviceKeyStorageKey,
      value: base64Encode(secret),
    );
    logInfo('Device secret saved to secure storage', tag: _logTag);
    return secret;
  }

  /// Преобразление байт в нижний hex.
  static String _bytesToHex(List<int> bytes) {
    final buffer = StringBuffer();
    for (final b in bytes) {
      buffer.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}

class VaultDerivedKeys {
  const VaultDerivedKeys({
    required this.dbKey,
    required this.fileKey,
    required this.macKey,
  });

  final Uint8List dbKey;
  final Uint8List fileKey;
  final Uint8List macKey;
}
