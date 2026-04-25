import 'package:freezed_annotation/freezed_annotation.dart';

import '../db_ciphers.dart';

part 'main_db_dto.freezed.dart';

/// DTO для создания нового хранилища
@freezed
sealed class CreateStoreDto with _$CreateStoreDto {
  const factory CreateStoreDto({
    required String name,
    required String path,
    required DBCipher cipher,
    String? description,
    @Default(false) bool saveMasterPassword,

    /// Привязать ключ шифрования к текущему устройству через HKDF.
    ///
    /// Если `true`, секрет устройства генерируется при создании
    /// и сохраняется в [FlutterSecureStorage]. При открытии БД на
    /// другом устройстве потребуется экспорт/импорт секрета.
    @Default(false) bool useDeviceKey,
  }) = _CreateStoreDto;
}

/// DTO для открытия существующего хранилища
@freezed
sealed class OpenStoreDto with _$OpenStoreDto {
  const factory OpenStoreDto({
    required String path,
    @Default(false) bool saveMasterPassword,
  }) = _OpenStoreDto;
}

/// DTO для изменения хранилища
@freezed
sealed class UpdateStoreDto with _$UpdateStoreDto {
  const factory UpdateStoreDto({
    String? name,
    String? description,
    bool? saveMasterPassword,
  }) = _UpdateStoreDto;
}

/// DTO для просмотра базовой информации о хранилище
@freezed
sealed class StoreInfoDto with _$StoreInfoDto {
  const factory StoreInfoDto({
    required String id,
    required String name,
    String? description,
    required DateTime createdAt,
    required DateTime modifiedAt,
    required DateTime lastOpenedAt,
    required String version,
  }) = _StoreInfoDto;
}
