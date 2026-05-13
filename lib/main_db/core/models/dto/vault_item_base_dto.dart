import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/vault_items/vault_items.dart';

part 'vault_item_base_dto.freezed.dart';
part 'vault_item_base_dto.g.dart';

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
sealed class VaultItemUpdateDto with _$VaultItemUpdateDto {
  const factory VaultItemUpdateDto({
    required String itemId,

    required String name,
    String? description,
    String? categoryId,
    String? iconRefId,

    @Default(false) bool isFavorite,
    @Default(false) bool isPinned,
  }) = _VaultItemUpdateDto;

  factory VaultItemUpdateDto.fromJson(Map<String, dynamic> json) =>
      _$VaultItemUpdateDtoFromJson(json);
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
