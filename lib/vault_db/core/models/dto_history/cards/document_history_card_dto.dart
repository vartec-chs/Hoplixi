import 'package:freezed_annotation/freezed_annotation.dart';
import 'vault_history_card_dto.dart';
import 'vault_snapshot_card_dto.dart';

part 'document_history_card_dto.freezed.dart';
part 'document_history_card_dto.g.dart';

@freezed
sealed class DocumentHistoryCardDto
    with _$DocumentHistoryCardDto
    implements VaultHistoryCardDto {
  const factory DocumentHistoryCardDto({
    required VaultSnapshotCardDto snapshot,
  }) = _DocumentHistoryCardDto;

  factory DocumentHistoryCardDto.fromJson(Map<String, dynamic> json) =>
      _$DocumentHistoryCardDtoFromJson(json);
}
