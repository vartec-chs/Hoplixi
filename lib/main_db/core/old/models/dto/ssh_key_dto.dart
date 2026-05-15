import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/main_db/core/old/models/dto/base_card_dto.dart';
import 'package:hoplixi/main_db/core/old/models/dto/category_dto.dart';
import 'package:hoplixi/main_db/core/old/models/dto/tag_dto.dart';

part 'ssh_key_dto.freezed.dart';
part 'ssh_key_dto.g.dart';

@freezed
sealed class CreateSshKeyDto with _$CreateSshKeyDto {
  const factory CreateSshKeyDto({
    required String name,
    required String publicKey,
    required String privateKey,
    String? keyType,
    int? keySize,
    String? passphraseHint,
    String? comment,
    String? fingerprint,
    String? createdBy,
    bool? addedToAgent,
    String? usage,
    String? publicKeyFileId,
    String? privateKeyFileId,
    String? metadata,
    String? description,
    String? noteId,
    String? categoryId,
    List<String>? tagsIds,
  }) = _CreateSshKeyDto;

  factory CreateSshKeyDto.fromJson(Map<String, dynamic> json) =>
      _$CreateSshKeyDtoFromJson(json);
}



@freezed
sealed class SshKeyCardDto with _$SshKeyCardDto implements BaseCardDto {
  const factory SshKeyCardDto({
    required String id,
    required String name,
    String? iconSource,
    String? iconValue,
    required String publicKey,
    String? keyType,
    int? keySize,
    String? comment,
    String? fingerprint,
    String? usage,
    required bool addedToAgent,
    String? description,
    CategoryInCardDto? category,
    List<TagInCardDto>? tags,
    required bool isFavorite,
    required bool isPinned,
    required bool isArchived,
    required bool isDeleted,
    required int usedCount,
    required DateTime modifiedAt,
    required DateTime createdAt,
  }) = _SshKeyCardDto;

  factory SshKeyCardDto.fromJson(Map<String, dynamic> json) =>
      _$SshKeyCardDtoFromJson(json);
}

