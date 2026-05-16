import 'package:freezed_annotation/freezed_annotation.dart';

part 'filter_meta_dto.freezed.dart';
part 'filter_meta_dto.g.dart';

@freezed
sealed class CategoryInCardDto with _$CategoryInCardDto {
  const factory CategoryInCardDto({
    required String id,
    required String name,
    String? color,
    String? iconRefId,
  }) = _CategoryInCardDto;

  factory CategoryInCardDto.fromJson(Map<String, dynamic> json) =>
      _$CategoryInCardDtoFromJson(json);
}

@freezed
sealed class TagInCardDto with _$TagInCardDto {
  const factory TagInCardDto({
    required String id,
    required String name,
    String? color,
  }) = _TagInCardDto;

  factory TagInCardDto.fromJson(Map<String, dynamic> json) =>
      _$TagInCardDtoFromJson(json);
}

@freezed
sealed class VaultItemCardMetaDto with _$VaultItemCardMetaDto {
  const factory VaultItemCardMetaDto({
    CategoryInCardDto? category,
    @Default(<TagInCardDto>[]) List<TagInCardDto> tags,
  }) = _VaultItemCardMetaDto;

  factory VaultItemCardMetaDto.fromJson(Map<String, dynamic> json) =>
      _$VaultItemCardMetaDtoFromJson(json);
}

@Freezed(genericArgumentFactories: true)
sealed class FilteredCardDto<T> with _$FilteredCardDto<T> {
  const factory FilteredCardDto({
    required T card,
    required VaultItemCardMetaDto meta,
  }) = _FilteredCardDto<T>;
}


