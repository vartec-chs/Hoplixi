import 'package:freezed_annotation/freezed_annotation.dart';
import 'vault_snapshot_card_dto.dart';

part 'vault_history_revision_detail_dto.freezed.dart';
part 'vault_history_revision_detail_dto.g.dart';

enum HistoryCompareTargetKind {
  newerRevision,
  currentLive,
  deletedState,
}

enum HistoryFieldChangeType {
  added,
  removed,
  changed,
}

@freezed
sealed class VaultHistoryFieldDiffDto with _$VaultHistoryFieldDiffDto {
  const factory VaultHistoryFieldDiffDto({
    required String fieldKey,
    required String label,
    Object? oldValue,
    Object? newValue,
    required HistoryFieldChangeType changeType,
    @Default(false) bool isSensitive,
  }) = _VaultHistoryFieldDiffDto;

  factory VaultHistoryFieldDiffDto.fromJson(Map<String, dynamic> json) =>
      _$VaultHistoryFieldDiffDtoFromJson(json);
}

@freezed
sealed class VaultHistoryRevisionDetailDto with _$VaultHistoryRevisionDetailDto {
  const factory VaultHistoryRevisionDetailDto({
    required VaultSnapshotCardDto selected,
    required HistoryCompareTargetKind compareTargetKind,

    @Default(<VaultHistoryFieldDiffDto>[])
    List<VaultHistoryFieldDiffDto> fieldDiffs,

    @Default(<VaultHistoryFieldDiffDto>[])
    List<VaultHistoryFieldDiffDto> customFieldDiffs,

    @Default(false) bool isRestorable,
    @Default(<String>[]) List<String> restoreWarnings,
  }) = _VaultHistoryRevisionDetailDto;

  factory VaultHistoryRevisionDetailDto.fromJson(Map<String, dynamic> json) =>
      _$VaultHistoryRevisionDetailDtoFromJson(json);
}
