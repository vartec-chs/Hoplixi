import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../tables/vault_items/vault_events_history.dart';
import '../../../tables/vault_items/vault_items.dart';

part 'vault_history_timeline_item_dto.freezed.dart';
part 'vault_history_timeline_item_dto.g.dart';

@freezed
sealed class VaultHistoryTimelineItemDto with _$VaultHistoryTimelineItemDto {
  const factory VaultHistoryTimelineItemDto({
    required String historyId,
    required String itemId,
    required VaultItemType type,
    required VaultEventHistoryAction action,

    required String title,
    String? subtitle,

    required DateTime actionAt,

    @Default(0) int changedFieldsCount,
    @Default(<String>[]) List<String> changedFieldLabels,

    @Default(false) bool isRestorable,
    @Default(<String>[]) List<String> restoreWarnings,
  }) = _VaultHistoryTimelineItemDto;

  factory VaultHistoryTimelineItemDto.fromJson(Map<String, dynamic> json) =>
      _$VaultHistoryTimelineItemDtoFromJson(json);
}
