import 'package:freezed_annotation/freezed_annotation.dart';

part 'main_store_dto.freezed.dart';
part 'main_store_dto.g.dart';

/// DTO для создания нового хранилища
@freezed
sealed class CreateStoreDto with _$CreateStoreDto {
  const factory CreateStoreDto({
    required String name,
    required String password,
    required String path,
    String? description,
    @Default(false) bool saveMasterPassword,

    /// Привязать ключ шифрования к текущему устройству через HKDF.
    ///
    /// Если `true`, секрет устройства генерируется при создании
    /// и сохраняется в [FlutterSecureStorage]. При открытии БД на
    /// другом устройстве потребуется экспорт/импорт секрета.
    @Default(false) bool useDeviceKey,
  }) = _CreateStoreDto;

  factory CreateStoreDto.fromJson(Map<String, dynamic> json) =>
      _$CreateStoreDtoFromJson(json);
}

/// DTO для открытия существующего хранилища
@freezed
sealed class OpenStoreDto with _$OpenStoreDto {
  const factory OpenStoreDto({
    required String password,
    required String path,
    @Default(false) bool saveMasterPassword,
  }) = _OpenStoreDto;

  factory OpenStoreDto.fromJson(Map<String, dynamic> json) =>
      _$OpenStoreDtoFromJson(json);
}

/// DTO для изменения хранилища
@freezed
sealed class UpdateStoreDto with _$UpdateStoreDto {
  const factory UpdateStoreDto({
    String? name,
    String? description,
    String? password,
    bool? saveMasterPassword,
  }) = _UpdateStoreDto;

  factory UpdateStoreDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateStoreDtoFromJson(json);
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

  factory StoreInfoDto.fromJson(Map<String, dynamic> json) =>
      _$StoreInfoDtoFromJson(json);
}
