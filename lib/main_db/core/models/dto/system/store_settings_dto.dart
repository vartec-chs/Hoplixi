import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../tables/system/store/store_settings.dart';

part 'store_settings_dto.freezed.dart';
part 'store_settings_dto.g.dart';

@freezed
sealed class StoreSettingDto with _$StoreSettingDto {
  const factory StoreSettingDto({
    required String key,
    required String value,
    @Default(StoreSettingValueType.string) StoreSettingValueType valueType,
    String? description,
    required DateTime createdAt,
    required DateTime modifiedAt,
  }) = _StoreSettingDto;

  factory StoreSettingDto.fromJson(Map<String, dynamic> json) =>
      _$StoreSettingDtoFromJson(json);
}

@freezed
sealed class StoreSettingsViewDto with _$StoreSettingsViewDto {
  const factory StoreSettingsViewDto({
    required List<StoreSettingDto> settings,
  }) = _StoreSettingsViewDto;

  factory StoreSettingsViewDto.fromJson(Map<String, dynamic> json) =>
      _$StoreSettingsViewDtoFromJson(json);
}
