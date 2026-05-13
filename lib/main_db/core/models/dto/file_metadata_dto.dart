import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/file/file_metadata.dart';

part 'file_metadata_dto.freezed.dart';
part 'file_metadata_dto.g.dart';

@freezed
sealed class FileMetadataDto with _$FileMetadataDto {
  const factory FileMetadataDto({
    String? id,
    required String fileName,
    String? fileExtension,
    String? filePath,
    required String mimeType,
    required int fileSize,
    String? sha256,
    @Default(FileAvailabilityStatus.available)
    FileAvailabilityStatus availabilityStatus,
    @Default(FileIntegrityStatus.unknown)
    FileIntegrityStatus integrityStatus,
    DateTime? missingDetectedAt,
    DateTime? deletedAt,
    DateTime? lastIntegrityCheckAt,
  }) = _FileMetadataDto;

  factory FileMetadataDto.fromJson(Map<String, dynamic> json) =>
      _$FileMetadataDtoFromJson(json);
}
