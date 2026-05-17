import '../../../tables/file/file_metadata.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'vault_history_card_dto.dart';
import 'vault_snapshot_card_dto.dart';

part 'file_history_card_dto.freezed.dart';
part 'file_history_card_dto.g.dart';

@freezed
sealed class FileHistoryCardDataDto with _$FileHistoryCardDataDto {
  const factory FileHistoryCardDataDto({
    String? metadataId,
    String? metadataHistoryId,
    String? fileName,

    String? fileExtension,
    String? mimeType,
    int? fileSize,
    String? sha256,
    FileAvailabilityStatus? availabilityStatus,
    FileIntegrityStatus? integrityStatus,
    DateTime? missingDetectedAt,
    DateTime? deletedAt,
    DateTime? lastIntegrityCheckAt,
    DateTime? snapshotCreatedAt,
    @Default(false) bool hasFilePath,
  }) = _FileHistoryCardDataDto;

  factory FileHistoryCardDataDto.fromJson(Map<String, dynamic> json) =>
      _$FileHistoryCardDataDtoFromJson(json);
}

@freezed
sealed class FileHistoryCardDto
    with _$FileHistoryCardDto
    implements VaultHistoryCardDto {
  const factory FileHistoryCardDto({
    required VaultSnapshotCardDto snapshot,
    required FileHistoryCardDataDto file,
  }) = _FileHistoryCardDto;

  factory FileHistoryCardDto.fromJson(Map<String, dynamic> json) =>
      _$FileHistoryCardDtoFromJson(json);
}
