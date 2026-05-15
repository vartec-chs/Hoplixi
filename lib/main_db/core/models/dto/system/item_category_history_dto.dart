import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../tables/system/categories.dart';

part 'item_category_history_dto.freezed.dart';
part 'item_category_history_dto.g.dart';

@freezed
sealed class ItemCategoryHistoryViewDto with _$ItemCategoryHistoryViewDto {
  const factory ItemCategoryHistoryViewDto({
    required String id,
    String? snapshotId,
    String? itemId,
    String? categoryId,
    required String name,
    String? description,
    String? iconRefId,
    required String color,
    required CategoryType type,
    String? parentId,
    DateTime? categoryCreatedAt,
    DateTime? categoryModifiedAt,
    required DateTime snapshotCreatedAt,
  }) = _ItemCategoryHistoryViewDto;

  factory ItemCategoryHistoryViewDto.fromJson(Map<String, dynamic> json) =>
      _$ItemCategoryHistoryViewDtoFromJson(json);
}

@freezed
sealed class ItemCategoryHistoryCardDto with _$ItemCategoryHistoryCardDto {
  const factory ItemCategoryHistoryCardDto({
    required String id,
    String? snapshotId,
    String? itemId,
    required String name,
    String? iconRefId,
    required String color,
    required CategoryType type,
    required DateTime snapshotCreatedAt,
  }) = _ItemCategoryHistoryCardDto;

  factory ItemCategoryHistoryCardDto.fromJson(Map<String, dynamic> json) =>
      _$ItemCategoryHistoryCardDtoFromJson(json);
}
