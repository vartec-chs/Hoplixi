import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hoplixi/core/logger/app_logger.dart';

/// Сервис деривации ключей для шифрования SQLCipher базы данных.
///
/// Реализует двухэтапную схему получения ключа:
///
/// ```
/// masterKey = Argon2id(password, salt)          // всегда
/// finalKey  = HKDF(masterKey, device_secret)     // если useDeviceKey = true
/// ```
///
/// Полученный ключ передаётся в SQLCipher через:
/// ```dart
/// rawDb.execute("PRAGMA key = \"x'<hexKey>'\";");
/// ```
///
/// ### Важно: salt хранится снаружи зашифрованной БД
///
/// Argon2-соль необходима для открытия БД, поэтому она сохраняется
/// в открытом JSON-файле [StoreKeyConfig] рядом с файлом `.db`.
/// Это стандартная практика для зашифрованных баз данных.
class DbKeyDerivationService {
  static const String _logTag = 'DbKeyDerivationService';

  // --- Параметры Argon2id ---
  /// Память: 2^16 = 65 536 KiB (≈ 64 МБ)
  static const int argon2Memory = 1 << 16;
  static const int argon2Iterations = 3;
  static const int argon2Parallelism = 1;
  static const int _keyLength = 32; // 256 бит

  // --- Хранилище ключа устройства ---
  static const String _deviceKeyStorageKey = 'hoplixi_db_device_secret_v1';

  // --- Info-строка для HKDF (контекст деривации) ---
  static const String _hkdfInfo = 'hoplixi-sqlcipher-v1';

  final FlutterSecureStorage _secureStorage;

  DbKeyDerivationService(this._secureStorage);

  // ─────────────────────────────────────────────────────────────────────────
  // Публичный API
  // ─────────────────────────────────────────────────────────────────────────

  /// Вычислить ключ шифрования для SQLCipher PRAGMA.
  ///
  /// [password]     — мастер-пароль пользователя
  /// [salt]         — Argon2-соль (base64), уникальная для каждого хранилища.
  ///                  Хранится в [StoreKeyConfig] рядом с файлом БД.
  /// [useDeviceKey] — привязать ключ к устройству через HKDF.
  ///
  /// Возвращает строку в формате `x'<64-символьный hex>'`,
  /// готовую для подстановки в `PRAGMA key = "...";`
  Future<String> derivePragmaKey(
    String password,
    String salt, {
    bool useDeviceKey = false,
  }) async {
    logInfo(
      'Deriving SQLCipher PRAGMA key (useDeviceKey=$useDeviceKey)',
      tag: _logTag,
    );

    // Шаг 1: masterKey = Argon2id(password, salt)
    final masterKey = await _argon2Derive(password, salt);

    // Шаг 2 (опционально): finalKey = HKDF(masterKey, device_secret)
    final finalKey = useDeviceKey
        ? await _hkdfDerive(masterKey, await _getOrCreateDeviceSecret())
        : masterKey;

    final pragmaKey = "x'${_bytesToHex(finalKey)}'";
    logInfo('PRAGMA key derived successfully', tag: _logTag);
    return pragmaKey;
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
    return base64UrlEncode(generateSecureRandomBytes(32));
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
    final passwordBytes = utf8.encode(password);
    final saltBytes = base64Decode(
      // поддержка как обычного, так и URL-safe Base64
      base64.normalize(salt.replaceAll('-', '+').replaceAll('_', '/')),
    );

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
    Uint8List deviceSecret,
  ) async {
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: _keyLength);

    final derived = await hkdf.deriveKey(
      secretKey: SecretKey(masterKey),
      nonce: deviceSecret,
      info: utf8.encode(_hkdfInfo),
    );

    return Uint8List.fromList(await derived.extractBytes());
  }

  /// Получить или создать секрет устройства.
  Future<Uint8List> _getOrCreateDeviceSecret() async {
    final stored = await _secureStorage.read(key: _deviceKeyStorageKey);

    if (stored != null) {
      logInfo('Using existing device secret from secure storage', tag: _logTag);
      return Uint8List.fromList(base64Decode(stored));
    }

    logInfo('Generating new device secret', tag: _logTag);
    final secret = generateSecureRandomBytes(32);
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
