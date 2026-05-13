import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/system/store/store_settings.dart';

part 'store_dto.freezed.dart';
part 'store_dto.g.dart';

@freezed
sealed class StoreMetaDto with _$StoreMetaDto {
  const factory StoreMetaDto({
    @Default(1) int singletonId,
    required String id,
    required String name,
    String? description,
    required String passwordHash,
    required String salt,
    required String attachmentKey,
    DateTime? createdAt,
    DateTime? modifiedAt,
    DateTime? lastOpenedAt,
  }) = _StoreMetaDto;

  factory StoreMetaDto.fromJson(Map<String, dynamic> json) =>
      _$StoreMetaDtoFromJson(json);
}

@freezed 
sealed class StoreSettingDto with _$StoreSettingDto {
  const factory StoreSettingDto({
    required String key,
    required String value,
    @Default(StoreSettingValueType.string)
    StoreSettingValueType valueType,
    String? description,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) = _StoreSettingDto;

  factory StoreSettingDto.fromJson(Map<String, dynamic> json) =>
      _$StoreSettingDtoFromJson(json);
}
