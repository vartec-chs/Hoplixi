import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/main_store/models/dto/base_card_dto.dart';
import 'package:hoplixi/main_store/models/dto/category_dto.dart';
import 'package:hoplixi/main_store/models/dto/tag_dto.dart';

part 'recovery_codes_dto.freezed.dart';
part 'recovery_codes_dto.g.dart';

@freezed
sealed class CreateRecoveryCodesDto with _$CreateRecoveryCodesDto {
  const factory CreateRecoveryCodesDto({
    required String name,
    required String codesBlob,
    int? codesCount,
    int? usedCount,
    String? perCodeStatus,
    DateTime? generatedAt,
    String? notes,
    bool? oneTime,
    String? displayHint,
    String? description,
    String? noteId,
    String? categoryId,
    List<String>? tagsIds,
  }) = _CreateRecoveryCodesDto;

  factory CreateRecoveryCodesDto.fromJson(Map<String, dynamic> json) =>
      _$CreateRecoveryCodesDtoFromJson(json);
}

@freezed
sealed class UpdateRecoveryCodesDto with _$UpdateRecoveryCodesDto {
  const factory UpdateRecoveryCodesDto({
    String? name,
    String? codesBlob,
    int? codesCount,
    int? usedCount,
    String? perCodeStatus,
    DateTime? generatedAt,
    String? notes,
    bool? oneTime,
    String? displayHint,
    String? description,
    String? noteId,
    String? categoryId,
    bool? isFavorite,
    bool? isArchived,
    bool? isPinned,
    List<String>? tagsIds,
  }) = _UpdateRecoveryCodesDto;

  factory UpdateRecoveryCodesDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateRecoveryCodesDtoFromJson(json);
}

@freezed
sealed class RecoveryCodesCardDto
    with _$RecoveryCodesCardDto
    implements BaseCardDto {
  const RecoveryCodesCardDto._();

  const factory RecoveryCodesCardDto({
    required String id,
    required String name,
    int? codesCount,
    int? codesUsedCount,
    bool? oneTime,
    DateTime? generatedAt,
    String? displayHint,
    String? description,
    CategoryInCardDto? category,
    List<TagInCardDto>? tags,
    required bool isFavorite,
    required bool isPinned,
    required bool isArchived,
    required bool isDeleted,
    required int usedCountMetric,
    required DateTime modifiedAt,
    required DateTime createdAt,
  }) = _RecoveryCodesCardDto;

  @override
  int get usedCount => usedCountMetric;

  factory RecoveryCodesCardDto.fromJson(Map<String, dynamic> json) =>
      _$RecoveryCodesCardDtoFromJson(json);
}
