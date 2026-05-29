import 'package:freezed_annotation/freezed_annotation.dart';

part 'vault_item_tags_snapshot_dto.freezed.dart';
part 'vault_item_tags_snapshot_dto.g.dart';

/// Snapshot тегов элемента хранилища для истории.
@freezed
sealed class VaultItemTagsSnapshotDto with _$VaultItemTagsSnapshotDto {
  const factory VaultItemTagsSnapshotDto({
    required List<VaultItemTagSnapshotItemDto> tags,
  }) = _VaultItemTagsSnapshotDto;

  factory VaultItemTagsSnapshotDto.fromJson(Map<String, dynamic> json) =>
      _$VaultItemTagsSnapshotDtoFromJson(json);
}

/// Информация об отдельном теге в снимке истории.
@freezed
sealed class VaultItemTagSnapshotItemDto with _$VaultItemTagSnapshotItemDto {
  const factory VaultItemTagSnapshotItemDto({
    required String name,
    required int color,
  }) = _VaultItemTagSnapshotItemDto;

  factory VaultItemTagSnapshotItemDto.fromJson(Map<String, dynamic> json) =>
      _$VaultItemTagSnapshotItemDtoFromJson(json);
}
