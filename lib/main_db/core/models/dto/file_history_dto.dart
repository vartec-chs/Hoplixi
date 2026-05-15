import 'package:freezed_annotation/freezed_annotation.dart';
import '../../tables/file/file_metadata.dart';
import '../../tables/file/file_metadata_history.dart';
import 'vault_history_dto.dart';

part 'file_history_dto.freezed.dart';
part 'file_history_dto.g.dart';

@freezed
sealed class FileHistoryDataDto with _$FileHistoryDataDto {
  const factory FileHistoryDataDto({
    String? metadataHistoryId,
  }) = _FileHistoryDataDto;

  factory FileHistoryDataDto.fromJson(Map<String, dynamic> json) =>
      _$FileHistoryDataDtoFromJson(json);
}

@freezed
sealed class FileMetadataHistoryDataDto with _$FileMetadataHistoryDataDto {
  const factory FileMetadataHistoryDataDto({
    String? historyId,
    required FileMetadataHistoryOwnerKind ownerKind,
    String? ownerId,
    String? metadataId,
    required String fileName,
    String? fileExtension,
    String? filePath,
    required String mimeType,
    required int fileSize,
    String? sha256,
    required FileAvailabilityStatus availabilityStatus,
    required FileIntegrityStatus integrityStatus,
    DateTime? missingDetectedAt,
    DateTime? deletedAt,
    DateTime? lastIntegrityCheckAt,
    required DateTime snapshotCreatedAt,
  }) = _FileMetadataHistoryDataDto;

  factory FileMetadataHistoryDataDto.fromJson(Map<String, dynamic> json) =>
      _$FileMetadataHistoryDataDtoFromJson(json);
}

@freezed
sealed class FileHistoryViewDto with _$FileHistoryViewDto {
  const factory FileHistoryViewDto({
    required VaultSnapshotHistoryDto snapshot,
    required FileHistoryDataDto file,
    FileMetadataHistoryDataDto? metadata,
  }) = _FileHistoryViewDto;

  factory FileHistoryViewDto.fromJson(Map<String, dynamic> json) =>
      _$FileHistoryViewDtoFromJson(json);
}
