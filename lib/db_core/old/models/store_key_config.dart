import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/db_core/old/models/db_ciphers.dart';

part 'store_key_config.freezed.dart';
part 'store_key_config.g.dart';

@freezed
sealed class StoreKeyConfig with _$StoreKeyConfig {
  const factory StoreKeyConfig({
    /// Версия формата конфига.
    @Default(1) int version,

    /// Argon2-соль (Base64URL), уникальная для каждого хранилища.
    required String argon2Salt,

    /// Привязать ключ шифрования к текущему устройству через HKDF.
    ///
    /// Если `true`, открытие БД на другом устройстве потребует
    /// экспорта/импорта секрета устройства из [FlutterSecureStorage].
    @Default(false) bool useDeviceKey,

    /// Выбранный алгоритм шифрования SQLite3 Multiple Ciphers.
    ///
    /// Для legacy-конфигов может отсутствовать.
    DBCipher? cipher,
  }) = _StoreKeyConfig;

  const StoreKeyConfig._();

  factory StoreKeyConfig.fromJson(Map<String, dynamic> json) =>
      _$StoreKeyConfigFromJson(json);
}
