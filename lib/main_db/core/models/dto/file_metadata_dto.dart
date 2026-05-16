import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/file/file_metadata.dart';
import '../field_update.dart';

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
@freezed
sealed class PatchFileMetadataDto with _$PatchFileMetadataDto {
  const factory PatchFileMetadataDto({
    required String id,
    @Default(FieldUpdate.keep()) FieldUpdate<String> fileName,
    @Default(FieldUpdate.keep()) FieldUpdate<String> fileExtension,
    @Default(FieldUpdate.keep()) FieldUpdate<String> filePath,
    @Default(FieldUpdate.keep()) FieldUpdate<String> mimeType,
    @Default(FieldUpdate.keep()) FieldUpdate<int> fileSize,
    @Default(FieldUpdate.keep()) FieldUpdate<String> sha256,
    @Default(FieldUpdate.keep()) FieldUpdate<FileAvailabilityStatus> availabilityStatus,
    @Default(FieldUpdate.keep()) FieldUpdate<FileIntegrityStatus> integrityStatus,
    @Default(FieldUpdate.keep()) FieldUpdate<DateTime> missingDetectedAt,
    @Default(FieldUpdate.keep()) FieldUpdate<DateTime> deletedAt,
    @Default(FieldUpdate.keep()) FieldUpdate<DateTime> lastIntegrityCheckAt,
  }) = _PatchFileMetadataDto;
}


