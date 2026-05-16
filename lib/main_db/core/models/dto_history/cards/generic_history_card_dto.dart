import 'package:freezed_annotation/freezed_annotation.dart';
import 'vault_history_card_dto.dart';
import 'vault_snapshot_card_dto.dart';

part 'generic_history_card_dto.freezed.dart';
part 'generic_history_card_dto.g.dart';

@freezed
sealed class GenericHistoryCardDto with _$GenericHistoryCardDto implements VaultHistoryCardDto {
  const factory GenericHistoryCardDto({
    required VaultSnapshotCardDto snapshot,
  }) = _GenericHistoryCardDto;

  factory GenericHistoryCardDto.fromJson(Map<String, dynamic> json) =>
      _$GenericHistoryCardDtoFromJson(json);
}
