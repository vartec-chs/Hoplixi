import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/vault_items/vault_items.dart';
import '../field_update.dart';

part 'vault_item_base_dto.freezed.dart';
part 'vault_item_base_dto.g.dart';

@freezed
sealed class VaultItemPatchDto with _$VaultItemPatchDto {
  const factory VaultItemPatchDto({
    required String itemId,

    @Default(FieldUpdate.keep()) FieldUpdate<String> name,
    @Default(FieldUpdate.keep()) FieldUpdate<String> description,
    @Default(FieldUpdate.keep()) FieldUpdate<String> categoryId,
    @Default(FieldUpdate.keep()) FieldUpdate<String> iconRefId,

    @Default(FieldUpdate.keep()) FieldUpdate<bool> isFavorite,
    @Default(FieldUpdate.keep()) FieldUpdate<bool> isPinned,
  }) = _VaultItemPatchDto;
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

@freezed
sealed class VaultItemViewDto with _$VaultItemViewDto {
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

  factory VaultItemViewDto.fromJson(Map<String, dynamic> json) =>
      _$VaultItemViewDtoFromJson(json);
}

@freezed
sealed class VaultItemCardDto with _$VaultItemCardDto {
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

  factory VaultItemCardDto.fromJson(Map<String, dynamic> json) =>
      _$VaultItemCardDtoFromJson(json);
}
