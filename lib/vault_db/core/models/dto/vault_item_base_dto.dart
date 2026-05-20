import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/vault_items/vault_items.dart';
import '../field_update.dart';

part 'vault_item_base_dto.freezed.dart';
part 'vault_item_base_dto.g.dart';

abstract interface class VaultEntityPatchDto {
  VaultItemPatchDto get item;
}

@freezed
sealed class VaultItemPatchDto
    with _$VaultItemPatchDto
    implements VaultEntityPatchDto {
  const factory VaultItemPatchDto({
    required String itemId,

    @Default(FieldUpdate.keep()) FieldUpdate<String> name,
    @Default(FieldUpdate.keep()) FieldUpdate<String> description,
    @Default(FieldUpdate.keep()) FieldUpdate<String> categoryId,
    @Default(FieldUpdate.keep()) FieldUpdate<String> iconRefId,

    @Default(FieldUpdate.keep()) FieldUpdate<bool> isFavorite,
    @Default(FieldUpdate.keep()) FieldUpdate<bool> isPinned,
  }) = _VaultItemPatchDto;

  const VaultItemPatchDto._();

  @override
  VaultItemPatchDto get item => this;
}

@freezed
sealed class VaultItemCreateDto with _$VaultItemCreateDto {
  const factory VaultItemCreateDto({
    required String name,
    String? description,
    String? categoryId,
    String? iconRefId,
    @Default(false) bool isFavorite,
    @Default(false) bool isPinned,
  }) = _VaultItemCreateDto;

  factory VaultItemCreateDto.fromJson(Map<String, dynamic> json) =>
      _$VaultItemCreateDtoFromJson(json);
}

abstract interface class VaultEntityViewDto {
  VaultItemViewDto get item;
}

@freezed
sealed class VaultItemViewDto
    with _$VaultItemViewDto
    implements VaultEntityViewDto {
  const factory VaultItemViewDto({
    required String itemId,
    required VaultItemType type,

    required String name,
    String? description,
    String? categoryId,
    String? iconRefId,

    @Default(0) int usedCount,

    @Default(false) bool isFavorite,
    @Default(false) bool isArchived,
    @Default(false) bool isPinned,
    @Default(false) bool isDeleted,

    required DateTime createdAt,
    required DateTime modifiedAt,

    DateTime? lastUsedAt,
    DateTime? archivedAt,
    DateTime? deletedAt,

    double? recentScore,
  }) = _VaultItemViewDto;

  const VaultItemViewDto._();

  @override
  VaultItemViewDto get item => this;

  factory VaultItemViewDto.fromJson(Map<String, dynamic> json) =>
      _$VaultItemViewDtoFromJson(json);
}

abstract interface class VaultEntityCardDto {
  VaultItemCardDto get item;
}

@freezed
sealed class VaultItemCardDto
    with _$VaultItemCardDto
    implements VaultEntityCardDto {
  const factory VaultItemCardDto({
    required String itemId,
    required VaultItemType type,

    required String name,
    String? description,
    String? categoryId,
    String? iconRefId,

    @Default(false) bool isFavorite,
    @Default(false) bool isArchived,
    @Default(false) bool isPinned,
    @Default(false) bool isDeleted,

    required DateTime createdAt,
    required DateTime modifiedAt,

    DateTime? lastUsedAt,
    DateTime? archivedAt,
    DateTime? deletedAt,

    double? recentScore,
  }) = _VaultItemCardDto;

  const VaultItemCardDto._();

  @override
  VaultItemCardDto get item => this;

  factory VaultItemCardDto.fromJson(Map<String, dynamic> json) =>
      _$VaultItemCardDtoFromJson(json);
}
