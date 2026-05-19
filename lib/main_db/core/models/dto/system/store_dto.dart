import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/main_db/core/models/db_ciphers.dart';
import 'package:hoplixi/main_db/core/models/field_update.dart';

part 'store_dto.freezed.dart';
part 'store_dto.g.dart';

/// -------------------------
/// CREATE / OPEN / UPDATE
/// -------------------------

@freezed
sealed class CreateStoreDto with _$CreateStoreDto {
  const factory CreateStoreDto({
    required String name,
    required String password,
    required String path,
    required DBCipher cipher,
    String? description,
    @Default(false) bool saveMasterPassword,
    @Default(false) bool useDeviceKey,
    @Default(false) bool useKeyFile,
    String? keyFileId,
    String? keyFileHint,

    @JsonKey(includeFromJson: false, includeToJson: false)
    Uint8List? keyFileSecret,
  }) = _CreateStoreDto;

  factory CreateStoreDto.fromJson(Map<String, dynamic> json) =>
      _$CreateStoreDtoFromJson(json);
}

@freezed
sealed class OpenStoreDto with _$OpenStoreDto {
  const factory OpenStoreDto({
    required String password,
    required String path,
    @Default(false) bool saveMasterPassword,
    String? keyFileId,

    @JsonKey(includeFromJson: false, includeToJson: false)
    Uint8List? keyFileSecret,
  }) = _OpenStoreDto;

  factory OpenStoreDto.fromJson(Map<String, dynamic> json) =>
      _$OpenStoreDtoFromJson(json);
}

@freezed
sealed class PatchStoreDto with _$PatchStoreDto {
  const factory PatchStoreDto({
    required String id,
    @Default(FieldUpdate.keep()) FieldUpdate<String> name,
    @Default(FieldUpdate.keep()) FieldUpdate<String> description,
    @Default(FieldUpdate.keep()) FieldUpdate<String> password,
    @Default(FieldUpdate.keep()) FieldUpdate<bool> saveMasterPassword,
  }) = _PatchStoreDto;

}

