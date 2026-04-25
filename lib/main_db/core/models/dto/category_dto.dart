import 'package:drift/drift.dart' as drift;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/main_db/core/models/dto/icon_ref_dto.dart';

part 'category_dto.freezed.dart';
part 'category_dto.g.dart';

/// DTO для создания новой категории
@freezed
sealed class CreateCategoryDto with _$CreateCategoryDto {
  const factory CreateCategoryDto({
    required String name,
    required String
    type, // 'notes', 'password', 'totp', 'bankCard', 'files', 'mixed'
    String? description,
    String? color,
    String? iconId,
    String? iconSource,
    String? iconValue,
    String? parentId,
  }) = _CreateCategoryDto;

  factory CreateCategoryDto.fromJson(Map<String, dynamic> json) =>
      _$CreateCategoryDtoFromJson(json);
}

/// DTO для получения полной информации о категории
@freezed
sealed class GetCategoryDto with _$GetCategoryDto {
  const factory GetCategoryDto({
    required String id,
    required String name,
    required String type,
    String? description,
    String? color,
    String? iconId,
    String? iconSource,
    String? iconValue,
    String? parentId,
    required int itemsCount,
    required DateTime createdAt,
    required DateTime modifiedAt,
  }) = _GetCategoryDto;

  factory GetCategoryDto.fromJson(Map<String, dynamic> json) =>
      _$GetCategoryDtoFromJson(json);
}

/// DTO для карточки категории (основная информация для отображения)
@freezed
sealed class CategoryCardDto with _$CategoryCardDto {
  const factory CategoryCardDto({
    required String id,
    required String name,
    required String type,
    String? color,
    String? iconId,
    String? iconSource,
    String? iconValue,
    String? parentId,
    required int itemsCount,
  }) = _CategoryCardDto;

  factory CategoryCardDto.fromJson(Map<String, dynamic> json) =>
      _$CategoryCardDtoFromJson(json);
}

@freezed
sealed class CategoryInCardDto with _$CategoryInCardDto {
  const factory CategoryInCardDto({
    required String id,
    required String name,
    required String type,
    String? color,
    String? iconId,
    String? iconSource,
    String? iconValue,
  }) = _CategoryInCardDto;

  factory CategoryInCardDto.fromJson(Map<String, dynamic> json) =>
      _$CategoryInCardDtoFromJson(json);
}

/// DTO для обновления категории.
///
/// [parentId] использует тип [Value] чтобы отличить
/// «поле не тронуто» ([Value.absent()]) от «сбросить в null» ([Value(null)]).
/// Не использует freezed т.к. [Value] несовместим с json_serializable.
class UpdateCategoryDto {
  const UpdateCategoryDto({
    this.name,
    this.description,
    this.color,
    this.iconId,
    this.iconSource,
    this.iconValue,
    this.parentId = const drift.Value.absent(),
  });

  final String? name;
  final String? description;
  final String? color;
  final String? iconId;
  final String? iconSource;
  final String? iconValue;

  /// Использует [Value] для семантики Drift:
  /// - [Value.absent()] — не обновлять поле
  /// - [Value(null)] — установить в NULL
  /// - [Value('id')] — установить значение
  final drift.Value<String?> parentId;

  UpdateCategoryDto copyWith({
    String? name,
    String? description,
    String? color,
    String? iconId,
    String? iconSource,
    String? iconValue,
    drift.Value<String?>? parentId,
  }) => UpdateCategoryDto(
    name: name ?? this.name,
    description: description ?? this.description,
    color: color ?? this.color,
    iconId: iconId ?? this.iconId,
    iconSource: iconSource ?? this.iconSource,
    iconValue: iconValue ?? this.iconValue,
    parentId: parentId ?? this.parentId,
  );
}

extension CategoryDtoIconRefX on GetCategoryDto {
  IconRefDto? get effectiveIconRef => IconRefDto.fromFields(
    iconSource: iconSource,
    iconValue: iconValue,
    legacyIconId: iconId,
  );
}

extension CategoryCardDtoIconRefX on CategoryCardDto {
  IconRefDto? get effectiveIconRef => IconRefDto.fromFields(
    iconSource: iconSource,
    iconValue: iconValue,
    legacyIconId: iconId,
  );
}

extension CategoryInCardDtoIconRefX on CategoryInCardDto {
  IconRefDto? get effectiveIconRef => IconRefDto.fromFields(
    iconSource: iconSource,
    iconValue: iconValue,
    legacyIconId: iconId,
  );
}
