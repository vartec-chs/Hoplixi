import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Конфиг ключа хранилища — хранится в открытом виде рядом с файлом `.db`.
///
/// Содержит параметры деривации ключа, необходимые для открытия
/// зашифрованной базы данных SQLCipher. Соль должна быть доступна
/// ДО открытия БД, поэтому не может храниться внутри неё.
///
/// Файл: `<store_dir>/store_key.json`
///
/// Пример содержимого:
/// ```json
/// {
///   "version": 1,
///   "argon2Salt": "base64url-encoded-salt",
///   "useDeviceKey": false
/// }
/// ```
///
/// Угрозы:
/// - Раскрытие соли не критично: без пароля подобрать ключ через Argon2
///   с параметрами `memory=65536, iterations=3` практически невозможно.
/// - Файл **не содержит** пароля или производных ключей.
class StoreKeyConfig {
  static const String _fileName = 'store_key.json';
  static const int _currentVersion = 1;

  /// Версия формата конфига.
  final int version;

  /// Argon2-соль (Base64URL), уникальная для каждого хранилища.
  final String argon2Salt;

  /// Привязать ключ шифрования к текущему устройству через HKDF.
  ///
  /// Если `true`, открытие БД на другом устройстве потребует
  /// экспорта/импорта секрета устройства из [FlutterSecureStorage].
  final bool useDeviceKey;

  const StoreKeyConfig({
    this.version = _currentVersion,
    required this.argon2Salt,
    this.useDeviceKey = false,
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Сериализация
  // ─────────────────────────────────────────────────────────────────────────

  factory StoreKeyConfig.fromJson(Map<String, dynamic> json) => StoreKeyConfig(
    version: (json['version'] as num?)?.toInt() ?? _currentVersion,
    argon2Salt: json['argon2Salt'] as String,
    useDeviceKey: json['useDeviceKey'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'version': version,
    'argon2Salt': argon2Salt,
    'useDeviceKey': useDeviceKey,
  };

  StoreKeyConfig copyWith({
    int? version,
    String? argon2Salt,
    bool? useDeviceKey,
  }) => StoreKeyConfig(
    version: version ?? this.version,
    argon2Salt: argon2Salt ?? this.argon2Salt,
    useDeviceKey: useDeviceKey ?? this.useDeviceKey,
  );

  // ─────────────────────────────────────────────────────────────────────────
  // Файловые операции
  // ─────────────────────────────────────────────────────────────────────────

  /// Путь к файлу конфига для данной директории хранилища.
  static String configFilePath(String storageDir) =>
      p.join(storageDir, _fileName);

  /// Записать конфиг на диск в директорию [storageDir].
  Future<void> writeTo(String storageDir) async {
    final file = File(configFilePath(storageDir));
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(toJson()),
      flush: true,
    );
  }

  /// Прочитать конфиг из директории [storageDir].
  ///
  /// Возвращает `null` если файл отсутствует (старый формат без Argon2).
  static Future<StoreKeyConfig?> readFrom(String storageDir) async {
    final file = File(configFilePath(storageDir));
    if (!await file.exists()) return null;

    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return StoreKeyConfig.fromJson(json);
  }

  /// Удалить файл конфига из директории [storageDir].
  static Future<void> deleteFrom(String storageDir) async {
    final file = File(configFilePath(storageDir));
    if (await file.exists()) await file.delete();
  }
}
