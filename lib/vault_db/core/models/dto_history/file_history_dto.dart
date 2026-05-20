import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/file/file_metadata.dart';
import '../../tables/file/file_metadata_history.dart';
import 'vault_snapshot_base_dto.dart';

part 'file_history_dto.freezed.dart';
part 'file_history_dto.g.dart';

@freezed
sealed class FileMetadataHistoryDto with _$FileMetadataHistoryDto {
  const factory FileMetadataHistoryDto({
    required String id,
    String? historyId,
    @Default(FileMetadataHistoryOwnerKind.fileItemHistory)
    FileMetadataHistoryOwnerKind ownerKind,
    String? ownerId,
    String? metadataId,
    required String fileName,
    String? fileExtension,
    String? filePath,
    required String mimeType,
    required int fileSize,
    String? sha256,
    @Default(FileAvailabilityStatus.available)
    FileAvailabilityStatus availabilityStatus,
    @Default(FileIntegrityStatus.unknown) FileIntegrityStatus integrityStatus,
    DateTime? missingDetectedAt,
    DateTime? deletedAt,
    DateTime? lastIntegrityCheckAt,
    required DateTime snapshotCreatedAt,
  }) = _FileMetadataHistoryDto;

  factory FileMetadataHistoryDto.fromJson(Map<String, dynamic> json) =>
      _$FileMetadataHistoryDtoFromJson(json);
}

@freezed
sealed class FileHistoryDataDto with _$FileHistoryDataDto {
  const factory FileHistoryDataDto({String? metadataHistoryId}) =
      _FileHistoryDataDto;

  factory FileHistoryDataDto.fromJson(Map<String, dynamic> json) =>
      _$FileHistoryDataDtoFromJson(json);
}

@freezed
sealed class FileHistoryViewDto with _$FileHistoryViewDto {
  const factory FileHistoryViewDto({
    required VaultSnapshotViewDto snapshot,
    required FileHistoryDataDto file,
    FileMetadataHistoryDto? metadata,
  }) = _FileHistoryViewDto;

  factory FileHistoryViewDto.fromJson(Map<String, dynamic> json) =>
      _$FileHistoryViewDtoFromJson(json);
}

@freezed
sealed class FileHistoryCardDataDto with _$FileHistoryCardDataDto {
  const factory FileHistoryCardDataDto({
    String? fileName,
    String? fileExtension,
    String? mimeType,
    int? fileSize,
    FileAvailabilityStatus? availabilityStatus,
  }) = _FileHistoryCardDataDto;

  factory FileHistoryCardDataDto.fromJson(Map<String, dynamic> json) =>
      _$FileHistoryCardDataDtoFromJson(json);
}

@freezed
sealed class FileHistoryCardDto with _$FileHistoryCardDto {
  const factory FileHistoryCardDto({
    required VaultSnapshotCardDto snapshot,
    required FileHistoryCardDataDto file,
  }) = _FileHistoryCardDto;

  factory FileHistoryCardDto.fromJson(Map<String, dynamic> json) =>
      _$FileHistoryCardDtoFromJson(json);
}
