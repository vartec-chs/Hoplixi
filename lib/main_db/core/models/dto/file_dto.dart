import 'package:freezed_annotation/freezed_annotation.dart';
import '../../tables/file/file_metadata.dart';
import '../field_update.dart';
import 'vault_item_base_dto.dart';

part 'file_dto.freezed.dart';
part 'file_dto.g.dart';

@freezed
sealed class FileDataDto with _$FileDataDto {
  const factory FileDataDto({String? metadataId}) = _FileDataDto;

  factory FileDataDto.fromJson(Map<String, dynamic> json) =>
      _$FileDataDtoFromJson(json);
}

@freezed
sealed class FileMetadataDataDto with _$FileMetadataDataDto {
  const factory FileMetadataDataDto({
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
  }) = _FileMetadataDataDto;

  factory FileMetadataDataDto.fromJson(Map<String, dynamic> json) =>
      _$FileMetadataDataDtoFromJson(json);
}

@freezed
sealed class FileMetadataViewDto with _$FileMetadataViewDto {
  const factory FileMetadataViewDto({
    required String id,
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
  }) = _FileMetadataViewDto;

  factory FileMetadataViewDto.fromJson(Map<String, dynamic> json) =>
      _$FileMetadataViewDtoFromJson(json);
}

@freezed
sealed class FileCardDataDto with _$FileCardDataDto {
  const factory FileCardDataDto({
    String? metadataId,
    String? fileName,
    String? fileExtension,
    String? mimeType,
    int? fileSize,
    FileAvailabilityStatus? availabilityStatus,
    FileIntegrityStatus? integrityStatus,
    DateTime? missingDetectedAt,
    DateTime? deletedAt,
    DateTime? lastIntegrityCheckAt,
    required bool hasMetadata,
    required bool hasSha256,
  }) = _FileCardDataDto;

  factory FileCardDataDto.fromJson(Map<String, dynamic> json) =>
      _$FileCardDataDtoFromJson(json);
}

@freezed
sealed class CreateFileDto with _$CreateFileDto {
  const factory CreateFileDto({
    required VaultItemCreateDto item,
    @Default(FileDataDto()) FileDataDto file,
    FileMetadataDataDto? metadata,
    @Default([]) List<String> tagIds,
  }) = _CreateFileDto;

  factory CreateFileDto.fromJson(Map<String, dynamic> json) =>
      _$CreateFileDtoFromJson(json);
}

@freezed
sealed class FileViewDto with _$FileViewDto implements VaultEntityViewDto {
  const factory FileViewDto({
    required VaultItemViewDto item,
    required FileDataDto file,
    FileMetadataViewDto? metadata,
  }) = _FileViewDto;

  factory FileViewDto.fromJson(Map<String, dynamic> json) =>
      _$FileViewDtoFromJson(json);
}

@freezed
sealed class FileCardDto with _$FileCardDto implements VaultEntityCardDto {
  const factory FileCardDto({
    required VaultItemCardDto item,
    required FileCardDataDto file,
  }) = _FileCardDto;

  factory FileCardDto.fromJson(Map<String, dynamic> json) =>
      _$FileCardDtoFromJson(json);
}

@freezed
sealed class PatchFileDataDto with _$PatchFileDataDto {
  const factory PatchFileDataDto({
    @Default(FieldUpdate.keep()) FieldUpdate<String> metadataId,
  }) = _PatchFileDataDto;
}

@freezed
sealed class PatchFileMetadataDataDto with _$PatchFileMetadataDataDto {
  const factory PatchFileMetadataDataDto({
    @Default(FieldUpdate.keep()) FieldUpdate<String> fileName,
    @Default(FieldUpdate.keep()) FieldUpdate<String> fileExtension,
    @Default(FieldUpdate.keep()) FieldUpdate<String> filePath,
    @Default(FieldUpdate.keep()) FieldUpdate<String> mimeType,
    @Default(FieldUpdate.keep()) FieldUpdate<int> fileSize,
    @Default(FieldUpdate.keep()) FieldUpdate<String> sha256,
    @Default(FieldUpdate.keep())
    FieldUpdate<FileAvailabilityStatus> availabilityStatus,
    @Default(FieldUpdate.keep())
    FieldUpdate<FileIntegrityStatus> integrityStatus,
    @Default(FieldUpdate.keep()) FieldUpdate<DateTime> missingDetectedAt,
    @Default(FieldUpdate.keep()) FieldUpdate<DateTime> deletedAt,
    @Default(FieldUpdate.keep()) FieldUpdate<DateTime> lastIntegrityCheckAt,
  }) = _PatchFileMetadataDataDto;
}

@freezed
sealed class PatchFileDto with _$PatchFileDto {
  const factory PatchFileDto({
    required VaultItemPatchDto item,
    required PatchFileDataDto file,
    PatchFileMetadataDataDto? metadata,
    @Default(FieldUpdate.keep()) FieldUpdate<List<String>> tags,
  }) = _PatchFileDto;
}
