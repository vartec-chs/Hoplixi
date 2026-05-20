import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/vault_db/core/models/field_update.dart';
import 'package:hoplixi/vault_db/core/tables/tables.dart';

part 'store_meta_dto.freezed.dart';
part 'store_meta_dto.g.dart';

@freezed
sealed class StoreMetaDto with _$StoreMetaDto {
  const factory StoreMetaDto({
    required String id,
    required String name,
    String? description,
    required String passwordHash,
    required String attachmentKey,
    required DateTime createdAt,
    required DateTime modifiedAt,
    required DateTime lastOpenedAt,
  }) = _StoreMetaDto;

  factory StoreMetaDto.fromJson(Map<String, dynamic> json) =>
      _$StoreMetaDtoFromJson(json);
}

@freezed
sealed class CreateStoreMetaDto with _$CreateStoreMetaDto {
  const factory CreateStoreMetaDto({
    required String name,
    String? description,
    required String passwordHash,
    required String attachmentKey,
    String? id,
  }) = _CreateStoreMetaDto;

  factory CreateStoreMetaDto.fromJson(Map<String, dynamic> json) =>
      _$CreateStoreMetaDtoFromJson(json);
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
  }) = _StoreInfoDto;

  factory StoreInfoDto.fromJson(Map<String, dynamic> json) =>
      _$StoreInfoDtoFromJson(json);
}

@freezed
sealed class PatchStoreMetaDto with _$PatchStoreMetaDto {
  const factory PatchStoreMetaDto({
    required String id,
    @Default(FieldUpdate.keep()) FieldUpdate<String> name,
    @Default(FieldUpdate.keep()) FieldUpdate<String> description,
    @Default(FieldUpdate.keep()) FieldUpdate<String> passwordHash,
    @Default(FieldUpdate.keep()) FieldUpdate<String> attachmentKey,
  }) = _PatchStoreMetaDto;
}
