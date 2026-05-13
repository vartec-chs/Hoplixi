import 'package:freezed_annotation/freezed_annotation.dart';

import '../../tables/file/file_metadata.dart';
import 'file_metadata_dto.dart';
import 'vault_item_base_dto.dart';

part 'file_dto.freezed.dart';
part 'file_dto.g.dart';

@freezed
sealed class FileDataDto with _$FileDataDto {
  const factory FileDataDto({
    String? metadataId,
  }) = _FileDataDto;

  factory FileDataDto.fromJson(Map<String, dynamic> json) =>
      _$FileDataDtoFromJson(json);
}

@freezed
sealed class FileCardDataDto with _$FileCardDataDto {
  const factory FileCardDataDto({
    String? metadataId,
  }) = _FileCardDataDto;

  factory FileCardDataDto.fromJson(Map<String, dynamic> json) =>
      _$FileCardDataDtoFromJson(json);
}

@freezed
sealed class CreateFileDto with _$CreateFileDto {
  const factory CreateFileDto({
    required VaultItemCreateDto item,
    required FileDataDto file,
  }) = _CreateFileDto;

  factory CreateFileDto.fromJson(Map<String, dynamic> json) =>
      _$CreateFileDtoFromJson(json);
}

@freezed
sealed class UpdateFileDto with _$UpdateFileDto {
  const factory UpdateFileDto({
    required VaultItemUpdateDto item,
    required FileDataDto file,
  }) = _UpdateFileDto;

  factory UpdateFileDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateFileDtoFromJson(json);
}

@freezed
sealed class FileViewDto with _$FileViewDto {
  const factory FileViewDto({
    required VaultItemViewDto item,
    required FileDataDto file,
  }) = _FileViewDto;

  factory FileViewDto.fromJson(Map<String, dynamic> json) =>
      _$FileViewDtoFromJson(json);
}

@freezed
sealed class FileCardDto with _$FileCardDto {
  const factory FileCardDto({
    required VaultItemCardDto item,
    required FileCardDataDto file,
  }) = _FileCardDto;

  factory FileCardDto.fromJson(Map<String, dynamic> json) =>
      _$FileCardDtoFromJson(json);
}
